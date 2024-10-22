arquivo_selecionado="arquivocompleto.csv"
counter=1

for i in $(ls Dados); do
    echo "$counter) $i"
    let counter=$counter+1
done

read input

let counter=1
for i in $(ls Dados); do
    if [[ $counter -eq $input ]]; then
        arquivo_selecionado="$i"
    fi
    let counter=$counter+1
done

echo $arquivo_selecionado
