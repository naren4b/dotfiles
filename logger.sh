#!/bin/bash

declare -r SCRIPT_NAME="$(basename "$0")"

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define log file
LOG_FILE="${SCRIPT_NAME}.log"

# Log function
function log {
  declare -r LVL="$1"
  declare -r MSG="$2"
  declare -r TS=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Determine color based on log level
  case "$LVL" in
    INFO)
      COLOR="$BLUE"
      ;;
    SUCCESS)
      COLOR="$GREEN"
      ;;
    WARNING)
      COLOR="$YELLOW"
      ;;
    ERROR)
      COLOR="$RED"
      ;;
    *)
      COLOR="$NC"
      ;;
  esac
  
  # Log to console with color
  echo -e "${COLOR}${TS} [$LVL] [$SCRIPT_NAME] $MSG${NC}"
  
  # Log to file without color
  echo "$TS [$LVL] [$SCRIPT_NAME] $MSG" >> "$LOG_FILE"
}

# Example usage
SCRIPT_NAME="example_script"

log INFO "This is an info message."
log SUCCESS "This is a success message."
log WARNING "This is a warning message."
log ERROR "This is an error message."
