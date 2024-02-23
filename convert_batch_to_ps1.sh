#!/bin/bash

# Check if a file name is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <batch_file>"
    exit 1
fi

# Input batch file
batch_file="$1"

# Output PowerShell file
ps_file="${batch_file%.*}.ps1"
echo -n > "$ps_file"

# Process each line of the batch file
while IFS='' read -r line || [[ -n "$line" ]]; do
    # Remove carriage return from the line
    line=$(echo "$line" | tr -d '\r')
    if [[ $line =~ ^REM || $line =~ ^:: ]]; then
        # Convert to PowerShell comment, preserving leading whitespace for alignment
        echo "#${line#??}" >> "$ps_file"
    elif [[ $line =~ ^set ]]; then
        # Convert set directives to PowerShell variable assignments
        var_name=$(echo "$line" | sed -n 's/^set \([^=]*\)=.*/\1/p')
        var_value=$(echo "$line" | sed -n 's/^set [^=]*=\(.*\)/\1/p')
        # Ensure proper PowerShell syntax for variable assignment
        echo "\$$var_name = \"$var_value\"" >> "$ps_file"
    elif [ -z "$line" ]; then
        # Preserve empty lines without affecting variable values
        echo "" >> "$ps_file"
    fi
done < "$batch_file"

echo "Conversion complete. Output file: $ps_file"
