#!/bin/bash
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color
echo "--------------------------------------"
# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path to INCAR file>"
  exit 1
fi

# Assign the provided INCAR file path to a variable
INCAR_FILE="$1"

# Check if the provided INCAR file exists
if [ ! -f "$INCAR_FILE" ]; then
  echo "Error: INCAR file '$INCAR_FILE' does not exist."
  exit 1
fi

# Find all error.number.tar.gz files
ERROR_FILES=$(ls error.*.tar.gz 2>/dev/null)
if [ -z "$ERROR_FILES" ]; then
  echo "Error: No error.number.tar.gz files found."
  exit 1
fi

# Loop through each error tar file
for ERROR_FILE in $ERROR_FILES; do
  echo -e "${RED}Processing $ERROR_FILE...${NC}"

  # Create a temporary directory for extraction
  TMP_DIR=$(mktemp -d) || { echo "Error: Failed to create temporary directory."; exit 1; }

  # Extract the INCAR file from the current error tar file
  tar -xzf "$ERROR_FILE" -C "$TMP_DIR" INCAR

  # Check if the INCAR file was successfully extracted
  EXTRACTED_INCAR="$TMP_DIR/INCAR"
  if [ ! -f "$EXTRACTED_INCAR" ]; then
    echo "Error: INCAR file not found in '$ERROR_FILE'."
    rm -rf "$TMP_DIR"
    continue
  fi

  # Compare the two INCAR files and output the unique lines
#  echo "Comparing with $INCAR_FILE..."

#!/bin/bash

# Define color codes


# Print echo statements in cyan
  echo -e "${RED}Lines unique to $ERROR_FILE INCAR file:${NC}"
# Print command output in orange (bold yellow)
  echo -e "${ORANGE}$(comm -13 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"

# Print echo statements in cyan
  echo -e "${CYAN}Lines unique to the Current INCAR file:${NC}"
# Print command output in orange (bold yellow)
  echo -e "${ORANGE}$(comm -23 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"




  # Clean up temporary directory
  rm -rf "$TMP_DIR"
  echo "Done processing $ERROR_FILE."
  echo "--------------------------------------"
done

echo "All comparisons complete."
