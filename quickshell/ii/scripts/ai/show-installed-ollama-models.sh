#!/usr/bin/env bash

# Use timeout to prevent hanging if ollama is stuck
# Get the list, skip the header, and extract the first column (model names)
model_names=$(timeout 5s ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

# Build a JSON array
json_array="["
for name in $model_names; do
    json_array+="\"$name\","
done

# Remove trailing comma and close the array
json_array="${json_array%,}]"

# Output the JSON array
echo "$json_array"
