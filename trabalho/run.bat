@REM Compilação e execução do programa TRABALHO.ASM. Mapa de memoria gerado em TRABALHO.MAP
masm TRABALHO.ASM /C
link TRABALHO.OBJ /EXE:TRABALHO.EXE
TRABALHO.EXE -i teste.in -o teste.out -v 127