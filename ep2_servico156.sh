##################################################################
# MAC0216 - Técnicas de Programação I (2024)
# EP2 - Programação em Bash
#
# Nome do(a) aluno(a) 1: Otávio Garcia Capobianco
# NUSP 1: 15482671
#
# Nome do(a) aluno(a) 2: João Victor Fernandes de Sousa
# NUSP 2: 15495651
##################################################################

#!/bin/bash

if [ $# != 0 ]; then
    while read -r line
    do
        wget -nv $line -P ./Dados
    done < $1

    cd Dados
    for i in $( ls ); do
        iconv -f ISO-8859-1 -t UTF8 "$i" > "$i".utf-8
        mv "$i".utf-8 "$i"
    done
    for i in $( ls ); do
        cat "$i" >> "arquivocompleto.csv"
    done
    cd ..

    exit 0
fi