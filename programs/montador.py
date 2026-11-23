"""Montador: traduz programs/asm/<nome>.asm para programs/mif/<nome>.mif.

Uso:
    python programs/montador.py programs/asm/programa_completo.asm
    python programs/montador.py programs/asm/*.asm

Sintaxe do .asm (formatos e opcodes: docs/especificacao/03-formato-instrucoes.md):
    ; comentario ate o fim da linha
    rotulo:                       ; rotulo na propria linha ou antes da instrucao
    ADD  Ri, Rj, Rk               ; tambem SUB, AND, OR, SLT
    ADDI Ri, Rj, imm              ; tambem LD, ST
    BEQ  Ri, Rj, alvo             ; tambem BNE
    JMP  alvo
    .word valor                   ; dado cru (16 bits) nesta posicao

    imm:  numero de -32 a +31 (decimal ou 0x..).
    alvo de BEQ/BNE: rotulo (o montador calcula imm = alvo - (endereco + 1))
                     ou numero, usado direto como imediato.
    alvo de JMP: rotulo ou endereco absoluto (0 a 4095).

O .mif sai com DEPTH=4096 e o resto da memoria em 0 (= ADD R0,R0,R0, que nao
faz nada).
"""

import re
import sys
from pathlib import Path

DEPTH = 4096

OPCODES = {
    "ADD": 0b0000, "SUB": 0b0001, "AND": 0b0010, "OR": 0b0011, "SLT": 0b0100,
    "ADDI": 0b0101, "LD": 0b0110, "ST": 0b0111,
    "BEQ": 0b1000, "BNE": 0b1001, "JMP": 0b1010,
}
TIPO_R = {"ADD", "SUB", "AND", "OR", "SLT"}
TIPO_I = {"ADDI", "LD", "ST"}
DESVIO = {"BEQ", "BNE"}


class ErroMontagem(Exception):
    pass


def numero(texto):
    try:
        return int(texto, 0)
    except ValueError:
        raise ErroMontagem(f"numero invalido: {texto!r}")


def registrador(texto):
    m = re.fullmatch(r"[Rr]([0-7])", texto)
    if not m:
        raise ErroMontagem(f"registrador invalido: {texto!r} (use R0 a R7)")
    return int(m.group(1))


def imediato(valor):
    if not -32 <= valor <= 31:
        raise ErroMontagem(f"imediato {valor} fora de -32..31")
    return valor & 0x3F


def ler(caminho):
    """Primeira passada: separa rotulos e instrucoes, com o endereco de cada."""
    rotulos, instrucoes = {}, []
    for n, linha in enumerate(Path(caminho).read_text(encoding="utf-8").splitlines(), 1):
        linha = linha.split(";", 1)[0].strip()
        while True:
            m = re.match(r"([A-Za-z_]\w*)\s*:\s*(.*)", linha)
            if not m:
                break
            if m.group(1) in rotulos:
                raise ErroMontagem(f"linha {n}: rotulo repetido {m.group(1)!r}")
            rotulos[m.group(1)] = len(instrucoes)
            linha = m.group(2)
        if linha:
            instrucoes.append((n, linha))
    if len(instrucoes) > DEPTH:
        raise ErroMontagem(f"programa com {len(instrucoes)} palavras, maximo {DEPTH}")
    return rotulos, instrucoes


def alvo(texto, rotulos):
    return rotulos[texto] if texto in rotulos else None


def montar_linha(endereco, linha, rotulos):
    partes = linha.split(None, 1)
    mnem = partes[0].upper()
    args = [a.strip() for a in partes[1].split(",")] if len(partes) > 1 else []

    def espera(qtd):
        if len(args) != qtd:
            raise ErroMontagem(f"{mnem} espera {qtd} operando(s), veio {len(args)}")

    if mnem == ".WORD":
        espera(1)
        return numero(args[0]) & 0xFFFF
    if mnem not in OPCODES:
        raise ErroMontagem(f"instrucao desconhecida: {partes[0]!r}")
    op = OPCODES[mnem] << 12

    if mnem in TIPO_R:
        espera(3)
        ri, rj, rk = (registrador(a) for a in args)
        return op | ri << 9 | rj << 6 | rk << 3
    if mnem in TIPO_I:
        espera(3)
        return op | registrador(args[0]) << 9 | registrador(args[1]) << 6 | imediato(numero(args[2]))
    if mnem in DESVIO:
        espera(3)
        destino = alvo(args[2], rotulos)
        imm = destino - (endereco + 1) if destino is not None else numero(args[2])
        return op | registrador(args[0]) << 9 | registrador(args[1]) << 6 | imediato(imm)
    # JMP
    espera(1)
    destino = alvo(args[0], rotulos)
    end = destino if destino is not None else numero(args[0])
    if not 0 <= end < DEPTH:
        raise ErroMontagem(f"endereco de JMP {end} fora de 0..{DEPTH - 1}")
    return op | end


def montar(caminho_asm):
    rotulos, instrucoes = ler(caminho_asm)
    palavras = []
    for endereco, (n, linha) in enumerate(instrucoes):
        try:
            palavras.append((montar_linha(endereco, linha, rotulos), linha))
        except ErroMontagem as e:
            raise ErroMontagem(f"{caminho_asm}, linha {n}: {e}") from None
    return palavras


def escrever_mif(palavras, caminho_mif, origem):
    linhas = [
        f"-- Gerado por programs/montador.py a partir de {origem}. Nao edite a mao.",
        f"WIDTH=16;",
        f"DEPTH={DEPTH};",
        "ADDRESS_RADIX=DEC;",
        "DATA_RADIX=HEX;",
        "",
        "CONTENT BEGIN",
    ]
    for endereco, (palavra, texto) in enumerate(palavras):
        linhas.append(f"    {endereco:<4} : {palavra:04X};  -- {texto}")
    if len(palavras) < DEPTH:
        linhas.append(f"    [{len(palavras)}..{DEPTH - 1}] : 0000;")
    linhas.append("END;")
    Path(caminho_mif).write_text("\n".join(linhas) + "\n", encoding="ascii", newline="\n")


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    raiz = Path(__file__).resolve().parent
    for arg in argv:
        asm = Path(arg)
        mif = raiz / "mif" / (asm.stem + ".mif")
        try:
            palavras = montar(asm)
        except (ErroMontagem, OSError) as e:
            print(f"ERRO: {e}", file=sys.stderr)
            return 1
        escrever_mif(palavras, mif, f"programs/asm/{asm.name}")
        print(f"{asm.name} -> mif/{mif.name} ({len(palavras)} palavras)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
