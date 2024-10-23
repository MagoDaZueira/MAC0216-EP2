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

###################### FUNÇÕES ######################

adicionar_filtro_coluna() {
    cd Dados
    arquivo_selecionado="arquivocompleto.csv"

    # Create an array directly from the CSV header (first line)
    OLD_IFS=$IFS  # Store the original value of IFS
    IFS=';' read -r -a colunas < <(head -n 1 arquivocompleto.csv)

    # Display the options using 'select'
    echo "Escolha uma opção de coluna para o filtro:"
    select coluna in "${colunas[@]}"; do
        if [[ -n "$coluna" ]]; then
            coluna_selecionada="$coluna"
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done

    # Now we use $REPLY as the column number selected by the user

    # Restore the original IFS value
    IFS=$OLD_IFS
    # Read the lines from the selected file, ignoring the header
    tail -n +2 "$arquivo_selecionado" | head -n 20 | while read -r line; do
        # Use cut to extract the selected column
        echo "$line" | cut -d';' -f"$REPLY"
    done > valores.txt  # Redirect the output to valores.txt


    # Display the unique values in the selected column
    counter=1
    mapfile -t options < <(sort valores.txt | uniq)

    echo ""
    # Display the options for unique values
    if [[ "${#vector[@]}" -le 1 && "${options[@]}" = "" ]]; then
        echo "Essa coluna não tem valores. Tente novamente."
        adicionar_filtro_coluna
        return

    else
        echo "Escolha uma opção de valor para ${coluna_selecionada}:"
        select option in "${options[@]}"; do
            if [[ -n "$option" ]]; then
                filtros+=$option
                echo "+++ Adicionado filtro: Canal = ${option}"
                echo "+++ Arquivo atual: ${arquivo_selecionado}"
                echo "+++ Filtros atuais:"
                # Iterar sobre filtros
                # Contar reclamações
                echo $sep
                break
            else
                echo "Valor inválido. Tente novamente."
            fi
        done
    fi
}


menu_principal() {
    echo "Escolha uma opção de operação:"
    select operacao in "${operacoes[@]}"; do
        if [[ -n "$operacao" ]]; then
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done
}

#####################################################

arquivo_selecionado="arquivocompleto.csv"
operacoes=(
            "selecionar_arquivo"
            "adicionar_filtro_coluna"
            "limpar_filtros_colunas"
            "mostrar_duracao_media_reclamacao"
            "mostrar_ranking_reclamacoes"
            "mostrar_reclamacoes"
            "sair"
)
operacao_selecionada="selecionar_arquivo"
sep="+++++++++++++++++++++++++++++++++++++++"
filtros=()

if [ $# != 0 ]; then
    mkdir Dados

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
fi

while true; do
    menu_principal
    if [ "$operacao" = "sair" ]; then
        echo "Fim do programa"
        echo $sep
        break
    fi
    
    $operacao

    echo ""
done

exit 0
