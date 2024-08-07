#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-A] [-n <name>]"
    exit 1
}

# Check for at least one argument
if [ $# -eq 0 ]; then
    kubectl get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.namespace}{"\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |sort | uniq -c | awk '{print $2, $3, $4}' | tr "," " done"
    exit 0
fi

while getopts "An:" opt; do
    case $opt in
        A)
      kubectl get pods -A -o jsonpath='{range .items[*]}{"\n"}{.metadata.namespace}{"\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |sort | uniq -c | awk '{print $2, $3, $4}' | tr "," " done"
            ;;
        n)
            name="$OPTARG"
      kubectl get pods -n $name -o jsonpath='{range .items[*]}{"\n"}{.metadata.namespace}{"\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |sort | uniq -c | awk '{print $2, $3, $4}' | tr "," " done"
            ;;
        *)
            echo "Invalid format "
            exit 1
            ;;
    esac
done
