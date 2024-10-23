cd Dados
head -n 1 arquivocompleto.csv | tr ';' '\n' > filtro.txt

arquivo_selecionado="arquivofinal3tri2021.csv"
counter=1

while read -r line 
do
    echo "$counter) $line"
    let counter=$counter+1
done < filtro.txt

read input
OLD_IFS=$IFS  # Armazenar o valor original do IFS
IFS=';'  # Definir IFS para separar por ponto e vírgula

# Ler as linhas do arquivo selecionado, ignorando o cabeçalho
tail -n +2 "$arquivo_selecionado" | head -n 20 | while read -r line; do
    # Usar cut para pegar a coluna selecionada
    echo "$line" | cut -d';' -f"$input"
done > valores.txt  # Redirecionar a saída para valores.txt

# Restaurar o valor original do IFS
IFS=$OLD_IFS

# Exibir os valores únicos na coluna selecionada
counter=1
echo "Valores únicos na coluna selecionada:"
sort valores.txt | uniq | while read -r valor; do
    echo "$counter) $valor"
    let counter=$counter+1
done