#!/bin/bash

# Example function to simulate some work
example_function() {
    sleep 10  # Replace this with the actual function logic
}
spinner() {
    local delay=0.1
    local spinstr='|/-\'
    local temp

    printf "Sleeping for 50 seconds: "
    for i in $(seq 1 500); do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b"
    done
}
# Function to show blinking dot while the main function runs
blink_dot() {
    echo -n "Processing: "
    while kill -0 $1 2>/dev/null; do
        echo -n "."
        sleep 1
        echo -ne "\b \b"  # Erase the dot
        sleep 1
    done
}

# Call the example function in the background
example_function &
FUNC_PID=$!

# Show blinking dot until the example function completes
blink_dot $FUNC_PID

# Wait for the function to ensure it completes
wait $FUNC_PID

# Print Hello after the function completes
echo -e "\nHello!"
