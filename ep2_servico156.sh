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

selecionar_arquivo() {
    cd Dados

    echo ""

    # Zera filtros
    filtros=()
    linhas_invalidas=()
    valores_filtrados=()

    # Cria um vetor com os nomes de arquivos no diretório Dados
    mapfile -t arquivos < <(ls)

    # Usuário seleciona um dos arquivos disponíveis
    echo "Escolha uma opção de arquivo:"
    select arquivo in "${arquivos[@]}"; do
        if [[ -n "$arquivo" ]]; then
            arquivo_selecionado=$arquivo
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done
    
    # Calcula linhas de reclamações do arquivo
    num_linhas=$(wc -l < $arquivo_selecionado)
    ((num_linhas--))
    num_reclamacoes=$num_linhas

    # Imprime informações relevantes
    echo "+++ Arquivo atual: ${arquivo_selecionado}"
    echo "+++ Número de reclamações: ${num_linhas}"
    echo $sep

    cd ..
}

adicionar_filtro_coluna() {
    cd Dados

    echo ""

    # Cria um array com os nomes das colunas (primeira linha do arquivo)
    OLD_IFS=$IFS  # Guarda o valor original do IFS
    IFS=';' read -r -a colunas < <(head -n 1 arquivocompleto.csv)

    # Exibe opções de colunas
    echo "Escolha uma opção de coluna para o filtro:"
    select coluna in "${colunas[@]}"; do
        if [[ -n "$coluna" ]]; then
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done

    IFS=$OLD_IFS  # Restaura o valor original do IFS

    # Define o número da coluna selecionada
    coluna_numero=$REPLY

    # Cria um arquivo com os valores da coluna selecionada, ignorando linhas inválidas
    if [ ${#valores_filtrados[@]} -eq 0 ]; then
        tail -n +2 "$arquivo_selecionado" | cut -d';' -f $coluna_numero | sort -f | uniq | grep -v "^$" > valores.txt
    else
        tail -n +2 "$arquivo_selecionado" > copia.txt
        for line in "${valores_filtrados[@]}"; do
            grep "$line" copia.txt > temp.txt
            cp temp.txt copia.txt
        done
        cut -d';' -f $coluna_numero copia.txt | sort -f | uniq | grep -v "^$" > valores.txt
        [ -f "temp.txt" ] && rm "temp.txt"
    fi
    mapfile -t options < valores.txt 
    rm valores.txt
    echo ""

    # Caso em que nenhum valor foi encontrado na coluna
    if [[ "${#options[@]}" -le 1 && "${options[0]}" = "" ]]; then
        echo "Essa coluna não tem valores. Tente novamente."
        cd ..
        adicionar_filtro_coluna
        return
    else
        # Exibe opções de filtros, com base nos valores guardados
        echo "Escolha uma opção de valor para ${coluna}:"
        select option in "${options[@]}"; do
            if [[ -n "$option" ]]; then
                # Adiciona o filtro escolhido
                valores_filtrados+=("${option}")
                filtros+=("${coluna} = ${option}")
                echo "+++ Adicionado filtro: ${coluna} = ${option}"

                # Imprime outras informações relevantes
                echo "+++ Arquivo atual: ${arquivo_selecionado}"
                print_filtros

                # Calcula o número de reclamações válidas
                #local tamanho_vetor=${#linhas_invalidas[@]}
                #num_reclamacoes=$((num_linhas - tamanho_vetor))

                tail -n +2 "$arquivo_selecionado" > copia.txt
                for line in "${valores_filtrados[@]}"; do
                    grep "$line" copia.txt > temp.txt
                    cp temp.txt copia.txt
                done
                cut -d';' -f $coluna_numero copia.txt > /dev/null
                [ -f "temp.txt" ] && rm "temp.txt"

                num_reclamacoes=$(wc -l < copia.txt | tr -d ' ')
                rm copia.txt
                echo "+++ Número de reclamações: ${num_reclamacoes}"
                echo $sep
                break
            else
                echo "Valor inválido. Tente novamente."
            fi
        done
    fi

    cd ..
}


limpar_filtros_colunas() {
    cd Dados
    # Zera os filtros (todas linhas são válidas)
    filtros=()
    linhas_invalidas=()
    valores_filtrados=()
    
    num_reclamacoes=$(wc -l < "$arquivo_selecionado")

    # Imprime informações relevantes
    echo "+++ Filtros removidos"
    echo "+++ Arquivo atual: ${arquivo_selecionado}"
    echo "+++ Número de reclamações: ${num_reclamacoes}"
    echo $sep
    cd ..
}


mostrar_reclamacoes() {
    cd Dados

    # Lê o arquivo e imprime apenas linhas válidas
    if [ -n "${valores_filtrados[*]}" ]; then
        tail -n +2 "$arquivo_selecionado" > copia.txt
        for line in "${valores_filtrados[@]}"; do
            grep "$line" copia.txt > temp.txt
            cp temp.txt copia.txt
        done
        cat copia.txt
        [ -f "temp.txt" ] && rm "temp.txt"
        num_reclamacoes=$(wc -l < copia.txt)
        rm copia.txt
    else
        cat "$arquivo_selecionado"
        num_reclamacoes=$(wc -l < "$arquivo_selecionado")
    fi

    # Imprime informações relevantes
    echo "+++ Arquivo atual: $arquivo_selecionado"
    print_filtros
    echo "+++ Número de reclamações: $num_reclamacoes"
    echo $sep

    cd ..
}


print_filtros() {
    # Mostra os filtros aplicados no momento
    total_filtros=${#filtros[@]}
    local counter=1
    echo "+++ Filtros atuais:"
    for filtro in "${filtros[@]}"; do
        if [[ "$counter" -ne "$total_filtros" ]]; then
            echo -n "$filtro | "
        else
            echo "$filtro"
        fi
        ((counter++))
    done
} 


filtrar_linhas() {
    # Itera sobre o arquivo e marca as linhas que não contêm o valor do filtro como inválidas
    linhas_invalidas=()  # Reinicializa o array de linhas inválidas
    local counter=1
    valores_filtrados=()
    # Lê o arquivo, começando a partir da segunda linha para ignorar o cabeçalho
    while IFS= read -r line; do
        # Verifica se a linha já está marcada como inválida
        if [[ -z "${linhas_invalidas[$counter]}" ]]; then
            # Extrai a coluna escolhida e verifica se contém o valor de `option`
            valor_coluna=$(echo "$line" | cut -d ';' -f "$coluna_numero")
            if [[ "$valor_coluna" != "$option" ]]; then
                # Marca a linha como inválida, armazenando seu índice
                linhas_invalidas[$counter]=1
            fi
        fi
        ((counter++))
    done < <(tail -n +2 "$arquivo_selecionado")
}

menu_principal() {
    # Mostra as opções gerais de operações do bot
    echo "Escolha uma opção de operação:"
    select operacao in "${operacoes[@]}"; do
        if [[ -n "$operacao" ]]; then
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done
}

mostrar_duracao_media_reclamacao() {
    cd Dados

    local soma_das_duracoes=0

    # Filtra e prepara o arquivo com as colunas 1 e 13
    if [ -n "${valores_filtrados[*]}" ]; then
        tail -n +2 "$arquivo_selecionado" > copia.txt
        for line in "${valores_filtrados[@]}"; do
            grep "$line" copia.txt > temp.txt
            cp temp.txt copia.txt
        done
        cut -d';' -f $coluna_numero copia.txt > /dev/null
        [ -f "temp.txt" ] && rm "temp.txt"
        cut -d";" -f 1,13 copia.txt > colunas_data.txt
        rm copia.txt
    else
        cut -d";" -f 1,13 "$arquivo_selecionado" > colunas_data.txt
    fi

    # Conta o número de reclamações (linhas)
    num_reclamacoes=$(wc -l < colunas_data.txt)

    # Verifica se há linhas para processar
    if [ "$num_reclamacoes" -eq 0 ]; then
        echo "+++ Nenhuma reclamação encontrada."
        echo "$sep"
        cd ..
        return
    fi

    # Calcula a soma das durações em segundos
    while IFS=';' read -r data1 data2; do
        diff=$(bc <<< "$(date -d "$data2" +%s) - $(date -d "$data1" +%s)")
        soma_das_duracoes=$(bc <<< "$soma_das_duracoes + $diff")
    done < colunas_data.txt

    # Cálculo da média em dias
    duracao_media=$(bc <<< "scale=0; $soma_das_duracoes / ($num_reclamacoes * 86400)")

    echo "+++ Duração média da reclamação: $duracao_media dias"
    echo "$sep"
    rm colunas_data.txt
    cd ..
}


mostrar_ranking_reclamacoes() {
    cd Dados

    echo ""

    OLD_IFS=$IFS  # Salva o valor original do IFS
    local counter=1

    # Lê a primeira linha do CSV e armazena os nomes das colunas em um array
    IFS=';' read -r -a colunas < <(head -n 1 $arquivo_selecionado)

    # Exibe as opções de colunas
    echo "Escolha uma opção de coluna para o filtro:"
    select coluna in "${colunas[@]}"; do
        if [[ -n "$coluna" ]]; then
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done

    IFS=$OLD_IFS  # Restaura o valor original do IFS
    coluna_numero=$((REPLY))

    # Obtém os 5 valores mais frequentes na coluna selecionada, removendo a primeira linha (cabeçalho)
    # Substitua $REPLY pelo número da coluna selecionada
    echo "+++ $coluna com mais reclamações:"
    cp "$arquivo_selecionado" copia.txt

    if [ -n "${valores_filtrados[*]}" ]; then
        regex=$(IFS=\|; echo "${valores_filtrados[*]}")

        grep -E "$regex" "$arquivo_selecionado" | cut -d";" -f $coluna_numero | sort -u > valores.txt

        mapfile -t valores < valores.txt
    

        grep -E "$regex" "$arquivo_selecionado" | cut -d";" -f $coluna_numero > ranking.txt
    else
        cut -d";" -f $coluna_numero "$arquivo_selecionado" > ranking.txt
    fi

    declare -A contagem

    # Iterando sobre o array
    for valor in "${valores[@]}"; do
        # Contando o número de linhas que contêm o valor
        num_linhas=$(grep -c "$valor" "ranking.txt")
        # Armazenando a contagem
        contagem["$valor"]=$num_linhas
    done

    for valor in "${!contagem[@]}"; do
        echo "$valor: ${contagem[$valor]}"
    done | sort -u -t: -k2 -nr | head -n 5

    
    echo $sep


    # Imprime o ranking na formatação correta
    #while IFS= read -r line; do
     #   echo "   $line"
    #done < ranking.txt

    # Remove os arquivos temporários
    rm ranking.txt
    rm copia.txt
    rm valores.txt


    echo "$sep"
    cd ..

}

#####################################################

##################### VARIÁVEIS #####################

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

num_linhas=0
num_reclamacoes=0

filtros=()
linhas_invalidas=()
valores_filtrados=()


#####################################################

####################### MAIN ########################

# Frase de introdução do programa
echo $sep
echo "Este programa mostra estatísticas do"
echo "Serviço 156 da Prefeitura de São Paulo"
echo $sep

# Caso da execução com argumento
if [ $# != 0 ]; then

    # Erro em que o arquivo dado como parâmetro não existe
    if [ ! -e "$1" ]; then
        echo "ERRO: O arquivo $1 não existe."
        exit 1
    fi

    mkdir Dados  # Diretório que armazenará os csv

    # Baixa de cada uma das URLs do arquivo dado como parâmetro
    while read -r line
    do
        wget -nv $line -P ./Dados
    done < $1

    cd Dados
    # Converte de ISO-8859-1 para UTF-8
    for i in $( ls ); do
        iconv -f ISO-8859-1 -t UTF8 "$i" > "$i".utf-8
        mv "$i".utf-8 "$i"
    done

    cabecalho=false
    for arquivo in $(ls); do
        if [ "$cabecalho" = false ]; then
            # Escreve a linha inicial uma única vez
            head -n 1 "$arquivo" >> "arquivocompleto.csv"
            cabecalho=true
        fi
        # Concatena os arquivos num mesmo arquivo final
        tail -n +2 "$arquivo" >> "arquivocompleto.csv"
    done

    cd ..
fi

# Caso de erro em que o bot vai rodar sem que haja um diretório de dados
if [ ! -d "Dados" ]; then
    echo "ERRO: Não há dados baixados."
    echo "Para baixar os dados antes de gerar as estatísticas, use:"
    echo "  ./ep2_servico156.sh <nome do arquivo com URLs de dados do Serviço 156>"
    exit 1
fi

# Calcula a quantidade de linhas do arquivo selecionado inicial
num_linhas=$(wc -l < "./Dados/${arquivo_selecionado}")
((num_linhas--))
num_reclamacoes=$num_linhas
echo ""

# Loop principal do bot, executado até o usuário selecionar "sair"
while true; do
    menu_principal
    if [ "$operacao" = "sair" ]; then
        echo "Fim do programa"
        echo $sep
        break
    fi
    
    # Executa a operação escolhida (uma das funções da seção anterior)
    $operacao

    echo ""
done

exit 0
