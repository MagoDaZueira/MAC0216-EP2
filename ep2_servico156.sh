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

    # Cria um vetor com os nomes de arquivos no diretório Dados
    mapfile -t arquivos < <(ls)

    echo ""

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
    echo "+++ Número de reclamações:${num_linhas}"
    echo $sep

    cd ..
}

adicionar_filtro_coluna() {
    cd Dados

    # Cria um array com os nomes das colunas (1a linha)
    OLD_IFS=$IFS  # Guarda o valor original do IFS
    IFS=';' read -r -a colunas < <(head -n 1 arquivocompleto.csv)

    # Mostra opções de colunas
    echo "Escolha uma opção de coluna para o filtro:"
    select coluna in "${colunas[@]}"; do
        if [[ -n "$coluna" ]]; then
            break
        else
            echo "Valor inválido. Tente novamente."
        fi
    done

    IFS=$OLD_IFS  # Restaura o valor original do IFS

    # Cria um arquivo com os valores da coluna selecionada
    # Head tem que ser removido, mas demora muito sem
    local counter=1
    tail -n +2 "$arquivo_selecionado" | head -n 20 | while read -r line; do
        if [[ -z "${linhas_invalidas[$counter]}" ]]; then
            echo "$line" | cut -d';' -f"$REPLY"
        fi
        ((counter++))
    done > valores.txt

    # Cria array com os valores distintos e ordenados
    mapfile -t options < <(sort valores.txt | uniq)

    # Arquivo temporário é removido
    rm valores.txt
    echo ""

    # Caso em que nenhum valor foi encontrado na coluna
    if [[ "${#options[@]}" -le 1 && "${options[@]}" = "" ]]; then
        echo "Essa coluna não tem valores. Tente novamente."
        cd ..
        adicionar_filtro_coluna
        return

    else
        # Mostra opções de filtros, com base nos valores guardados
        echo "Escolha uma opção de valor para ${coluna}:"
        select option in "${options[@]}"; do
            if [[ -n "$option" ]]; then
                # Cria o filtro escolhido
                filtrar_linhas
                filtros+=("${coluna} = ${option}")
                echo "+++ Adicionado filtro: Canal = ${option}"

                # Imprime outras informações relevantes
                echo "+++ Arquivo atual: ${arquivo_selecionado}"
                print_filtros

                # Calcula o número de reclamações válidas
                local tamanho_vetor=${#linhas_invalidas[@]}
                num_reclamacoes=$((num_linhas-tamanho_vetor))

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
    # Zera os filtros (todas linhas são válidas)
    filtros=()
    linhas_invalidas=()
    num_reclamacoes=$num_linhas

    # Print de informações relevantes
    echo "+++ Filtros removidos"
    echo "+++ Arquivo atual: ${arquivo_selecionado}"
    echo "+++ Número de reclamações: ${num_linhas}"
    echo $sep
}


mostrar_reclamacoes() {
    cd Dados
    local counter=1

    # Itera sobre o arquivo, imprimindo cada linha
    while IFS= read -r line; do
        if [[ -z "${linhas_invalidas[$counter]}" ]]; then
            echo $line
        fi
        ((counter++))
    done < <(tail -n +2 "$arquivo_selecionado")

    # Imprime informações relevantes
    echo "+++ Arquivo atual: ${arquivo_selecionado}"
    print_filtros
    echo "+++ Número de reclamações: ${num_reclamacoes}"
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
    local counter=1
    # Itera sobre as linhas do arquivo para filtrá-las
    while IFS= read -r line; do
        if [[ -z "${linhas_invalidas[$counter]}" ]]; then
            # Verifica se a opção selecionada não pertence à linha atual
            if [[ "$line" != *"$option"* ]]; then
                # Usa o "índice" da linha como forma de invalidá-la
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
    local counter=1
    local soma_das_duracoes=0

    # Leitura linha a linha do arquivo
    while IFS= read -r line; do
        # Realiza a operação se é uma linha válida
        if [[ -z "${linhas_invalidas[$counter]}" ]]; then
            # Os valores das duas colunas são armazenados
            local coluna_abertura=$(echo "$line" | cut -d ';' -f 1)
            local coluna_parecer=$(echo "$line" | cut -d ';' -f 13)
            # E as somas das durações vão sendo somadas
            soma_das_duracoes=$(bc <<< "scale=2; $soma_das_duracoes + ($(date -d "$coluna_parecer" +%s) - $(date -d "$coluna_abertura" +%s))/86400")
        fi
        ((counter++))
    done < <(tail -n +2 "$arquivo_selecionado")
    # Cálculo da média
    duracao_media=$(bc <<< "scale=0; $soma_das_duracoes / $num_reclamacoes")

    echo "+++ Duração média da reclamação: $duracao_media dias"
    echo "$sep"

    cd ..
}

mostrar_ranking_reclamacoes() {
    cd Dados
    OLD_IFS=$IFS  # Salva o valor original do IFS
    local counter=1

    # Lê a primeira linha do CSV e armazena os nomes das colunas em um array
    IFS=';' read -r -a colunas < <(head -n 1 arquivocompleto.csv)

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
    echo "+++ Temas com mais reclamações:"

    tail -n +2 "$arquivo_selecionado" | while read -r line; do
        # Ignora a linha se estiver no array `linhas_invalidas`
        if [[ -z "${linhas_invalidas[$counter]}" && -n "$line" ]]; then
            # Extrai a coluna escolhida e adiciona aos resultados
            echo "$line" | cut -d';' -f $coluna_numero
        fi
        ((counter++))
    done | sort | uniq -c | sort -nr | head -5

    echo "+++++++++++++++++++++++++++++++++++++++"
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

    # Concatena as linhas arquivos num mesmo arquivo final
    for arquivo in $( ls ); do
        cat "$arquivo" >> "arquivocompleto.csv"
    done
    cd ..
fi

# Caso de erro em que o bot vai rodar sem que haja um diretório de dados
if [ ! -d "Dados" ]; then
    echo "ERRO: Não há dados baixados."
    echo "Para baixar os dados antes de gerar as estatísticas, use:"
    echo "  ./ep2_servico156.sh <nome do arquivo com URLs de dados do Serviço 156>"
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
