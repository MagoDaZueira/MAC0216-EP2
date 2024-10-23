cd Dados
arquivo_selecionado="arquivocompleto.csv"

# Create an array directly from the CSV header (first line)
OLD_IFS=$IFS  # Store the original value of IFS
IFS=';' read -r -a columns < <(head -n 1 arquivocompleto.csv)

# Display the options using 'select'
echo "Select a column:"
select column in "${columns[@]}"; do
    if [[ -n "$column" ]]; then
        echo "You selected column $REPLY: $column"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Now we use $REPLY as the column number selected by the user
IFS=';'  # Set IFS to semicolon

# Restore the original IFS value
IFS=$OLD_IFS
# Read the lines from the selected file, ignoring the header
tail -n +2 "$arquivo_selecionado" | head -n 20 | while read -r line; do
    # Use cut to extract the selected column
    echo "$line" | cut -d';' -f"$REPLY"
done > valores.txt  # Redirect the output to valores.txt


# Display the unique values in the selected column
counter=1
echo "Unique values in the selected column:"
mapfile -t options < <(sort valores.txt | uniq)

# Display the options for unique values
echo "Select a value:"
select option in "${options[@]}"; do
    if [[ -n "$option" ]]; then
        echo "You selected option $REPLY: $option"
        selected_value="$option"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done
