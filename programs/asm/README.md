# programs/asm

Pseudo-assembly legível dos programas de teste (um arquivo por instrução + um programa combinado), por exemplo:

```
; teste_add.asm
ADDI R1, R0, 5
ADDI R2, R0, 3
ADD  R3, R1, R2   ; R3 deve ficar 8
```

Cada arquivo aqui deve ter um `.mif` correspondente em `programs/mif/` com o mesmo nome. Não edite o `.mif` diretamente — gere/atualize a partir do `.asm` para não perder a rastreabilidade (DRY: uma única fonte de verdade por programa de teste).
