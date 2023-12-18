#!/bin/bash

# Check if the input file exists
if [ ! -f "commands.txt" ]; then
    echo "Input file not found!"
    exit 1
fi

# Input file containing commands
input_file="commands.txt"
# echo "$input_file"

# Output file for commands and their outputs
output_file="$(hostname -s)_$(hostname -i)_$(date +'%Y%m%d%H%M').txt"

# Empty the output file
# > "$output_file"

# Read the input file line by line
while IFS= read -r line
do
    # Ignore lines starting with # and empty lines
    if [[ "$line" != \#* ]] && [[ -n "$line" ]]; then
        # Write the command to the output file
        echo "Command: $line" >> "$output_file"
        echo >> "$output_file"
        # Execute the command and append its output to the output file
        eval "$line" >> "$output_file" 2>&1
        # Add an ---- line to the output file
        echo "--------------------------------------------------------------------" >> "$output_file"
        # Add an empty line to the output file
        echo >> "$output_file"
    fi
done < "$input_file"
