#!/bin/bash
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

echo -e "\n\n"
INCAR_UNZIPPED=0
CUSTODIAN_UNZIPPED=0

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path to INCAR file>"
  exit 1
fi

# Find all error.number.tar.gz files and sort them
mapfile -t ERROR_FILES < <(ls error.*.tar.gz 2>/dev/null | sort -V)
if [ ${#ERROR_FILES[@]} -eq 0 ]; then
  echo "Error: No error.number.tar.gz files found."
  exit 1
fi

INCAR_FILE="$1"
INCAR_GZ_FILE="${INCAR_FILE}.gz"
CUSTODIAN_FILE="custodian.json"
CUSTODIAN_GZ_FILE="${CUSTODIAN_FILE}.gz"

# Function to check if a file exists or its .gz version, and uncompress if necessary
check_and_uncompress() {
  local file="$1"
  local gz_file="${file}.gz"
  local unzipped_var="$2"
  
  if [ ! -f "$file" ]; then
    if [ -f "$gz_file" ]; then
      echo "File '$file' does not exist."
      echo "Found compressed file '$gz_file'. Uncompressing..."
      gunzip -c "$gz_file" > "$file"
      if [ $? -ne 0 ]; then
        echo "Error: Failed to uncompress '$gz_file'."
        exit 1
      fi
      echo "Successfully uncompressed '$gz_file'."
      eval "$unzipped_var=1"
    else
      echo "Error: Neither '$file' nor '$gz_file' exist."
      exit 1
    fi
  fi
}

# Check and uncompress INCAR file
check_and_uncompress "$INCAR_FILE" INCAR_UNZIPPED

# Check and uncompress custodian.json file
check_and_uncompress "$CUSTODIAN_FILE" CUSTODIAN_UNZIPPED
echo -e "\n\n"

# Your additional script logic goes here...

# Extract errors from custodian.json and store them in an array
mapfile -t custodian_errors < <(jq -r '.[].corrections[].errors[]' custodian.json)

# Function to extract and compare two INCAR files
compare_incar_files() {
  FILE1=$1
  FILE2=$2
  TMP_DIR1=$(mktemp -d) || { echo "Error: Failed to create temporary directory."; exit 1; }
  TMP_DIR2=$(mktemp -d) || { echo "Error: Failed to create temporary directory."; exit 1; }

  tar -xzf "$FILE1" -C "$TMP_DIR1" INCAR
  tar -xzf "$FILE2" -C "$TMP_DIR2" INCAR

  EXTRACTED_INCAR1="$TMP_DIR1/INCAR"
  EXTRACTED_INCAR2="$TMP_DIR2/INCAR"

  if [ ! -f "$EXTRACTED_INCAR1" ]; then
    echo "Error: INCAR file not found in '$FILE1'."
    rm -rf "$TMP_DIR1" "$TMP_DIR2"
    return
  fi
  if [ ! -f "$EXTRACTED_INCAR2" ]; then
    echo "Error: INCAR file not found in '$FILE2'."
    rm -rf "$TMP_DIR1" "$TMP_DIR2"
    return
  fi
  
  echo -e "${RED}Lines unique to $FILE1 INCAR file:${NC}"
  echo -e "${ORANGE}$(comm -23 <(sort "$EXTRACTED_INCAR1") <(sort "$EXTRACTED_INCAR2"))${NC}"
  
  echo -e "${CYAN}Lines unique to $FILE2 INCAR file:${NC}"
  echo -e "${ORANGE}$(comm -13 <(sort "$EXTRACTED_INCAR1") <(sort "$EXTRACTED_INCAR2"))${NC}"
  
  rm -rf "$TMP_DIR1" "$TMP_DIR2"
}

# Maintain a counter for errors
ERROR_INDEX=0

# Loop through the sorted error files and perform pairwise comparisons
PREV_FILE=""
for i in ${!ERROR_FILES[@]}; do
  ERROR_FILE=${ERROR_FILES[$i]}
  
  if [[ -n "$PREV_FILE" ]] && [ ${#ERROR_FILES[@]} -gt 1 ]; then  # Secondary clause added to avoid pairwise comparisons if there's only one file
    echo -e "${NC}Here's what changed between ${RED}$PREV_FILE${NC} and ${RED}$ERROR_FILE${NC}..."
    
    # Print the corresponding error if available
    if [[ ERROR_INDEX -lt ${#custodian_errors[@]} ]]; then
      echo -e "${CYAN}Custodian error in ${RED}$PREV_FILE${NC}: ${ORANGE}${custodian_errors[ERROR_INDEX]}${NC}"
      ERROR_INDEX=$((ERROR_INDEX + 1))
    fi
    
    compare_incar_files "$PREV_FILE" "$ERROR_FILE"
    echo "--------------------------------------"
  fi
  PREV_FILE="$ERROR_FILE"
done

# Compare the highest numbered error file with the current INCAR file
if [ ${#ERROR_FILES[@]} -gt 1 ]; then
    if [[ -n "$PREV_FILE" ]]; then
      echo -e "${NC}Here's what changed between ${RED}$PREV_FILE${NC} and the current ${CYAN}INCAR file${NC}..."

      # Print the last error in the custodian errors array
      LAST_ERROR_INDEX=$(( ${#custodian_errors[@]} - 1 ))
      if [[ LAST_ERROR_INDEX -ge 0 ]]; then
        echo -e "${CYAN}Custodian Error in ${RED}$PREV_FILE${NC}: ${ORANGE}${custodian_errors[LAST_ERROR_INDEX]}${NC}"
      fi

      TMP_DIR=$(mktemp -d) || { echo "Error: Failed to create temporary directory."; exit 1; }
      tar -xzf "$PREV_FILE" -C "$TMP_DIR" INCAR
      EXTRACTED_INCAR="$TMP_DIR/INCAR"

      if [ ! -f "$EXTRACTED_INCAR" ]; then
        echo "Error: INCAR file not found in '$PREV_FILE'."
        rm -rf "$TMP_DIR"
        exit 1
      fi

      echo -e "${RED}Lines unique to $PREV_FILE INCAR file:${NC}"
      echo -e "${ORANGE}$(comm -13 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"

      echo -e "${CYAN}Lines unique to the Current INCAR file:${NC}"
      echo -e "${ORANGE}$(comm -23 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"
      rm -rf "$TMP_DIR"
    fi
fi

# Prevent the additional comparison only if there is more than one error file
if [ ${#ERROR_FILES[@]} -eq 1 ]; then
  FIRST_ERROR_FILE="${ERROR_FILES[0]}"
  echo -e "${RED}Here's what changed between $FIRST_ERROR_FILE and the current INCAR file...${NC}"

  TMP_DIR=$(mktemp -d) || { echo "Error: Failed to create temporary directory."; exit 1; }
  tar -xzf "$FIRST_ERROR_FILE" -C "$TMP_DIR" INCAR
  EXTRACTED_INCAR="$TMP_DIR/INCAR"

  if [ ! -f "$EXTRACTED_INCAR" ]; then
    echo "Error: INCAR file not found in '$FIRST_ERROR_FILE'."
    rm -rf "$TMP_DIR"
  else
    echo -e "${RED}Lines unique to $FIRST_ERROR_FILE INCAR file:${NC}"
    echo -e "${ORANGE}$(comm -13 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"

    echo -e "${CYAN}Lines unique to the Current INCAR file:${NC}"
    echo -e "${ORANGE}$(comm -23 <(sort "$INCAR_FILE") <(sort "$EXTRACTED_INCAR"))${NC}"
    rm -rf "$TMP_DIR"
  fi
fi

if [ "$INCAR_UNZIPPED" -eq 1 ]; then
  rm "$INCAR_FILE"
  echo "Deleted uncompressed '$INCAR_FILE' as '$INCAR_GZ_FILE' existed originally."
fi

if [ "$CUSTODIAN_UNZIPPED" -eq 1 ]; then
  rm "$CUSTODIAN_FILE"
  echo "Deleted uncompressed '$CUSTODIAN_FILE' as '$CUSTODIAN_GZ_FILE' existed originally."
fi

echo "All comparisons complete. Best of luck o7"

echo -e "\n\n"
