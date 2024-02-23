#!/bin/bash

# Help message
if [[ "$1" == "--help" ]]; then
    echo "Usage: lsoct"
    echo "Displays files and directories with octal permissions and colors them based on type and status."
    exit 0
fi

for file in * .*; do
    if [ "$file" = "." ] || [ "$file" = ".." ]; then
        continue
    fi

    # Extract the parts of ls -ld output
    full_info=$(ls -ld "$file")
    permissions=$(echo "$full_info" | awk '{print $1}')
    links=$(echo "$full_info" | awk '{print $2}')
    owner=$(echo "$full_info" | awk '{print $3}')
    group=$(echo "$full_info" | awk '{print $4}')
    size=$(echo "$full_info" | awk '{print $5}')
    month=$(echo "$full_info" | awk '{print $6}')
    day=$(echo "$full_info" | awk '{print $7}')
    time=$(echo "$full_info" | awk '{print $8}')

    # Get numeric permissions
    perm=$(stat -c '%a' "$file")

    # Determine color for the permission number
    if [[ "$perm" == "777" ]]; then
        perm_color="\033[91m"  # Red for 777 permissions
    elif [[ "$permissions" == *x* ]]; then
        perm_color="\033[32m"  # Green for executable permissions
    else
        perm_color="\033[0m"   # Default color
    fi

    # Determine color for the filename based on file type and hidden status
    if [[ -d "$file" && "$file" == .* ]]; then
        color="\033[94m"  # Different shade of blue for hidden directories
    elif [[ -d "$file" ]]; then
        color="\033[34m"  # Blue for directories
    elif [[ "$file" == .* ]]; then
        color="\033[90m"  # Grey for hidden files
    else
        color="\033[0m"   # Default color for other files
    fi

    # Print with formatting for alignment
    printf "%s %3s %s %s %6s %s %2s %5s %b%s %b%s %s\n" "$permissions" "$links" "$owner" "$group" "$size" "$month" "$day" "$time" "$perm_color" "$perm" "$color" "$file"
    # Reset color
    echo -en "\033[0m"
done

