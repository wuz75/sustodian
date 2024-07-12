import os
import sys
import tarfile
import tempfile
from difflib import unified_diff

# Define color codes
RED = '\033[0;31m'
CYAN = '\033[0;36m'
ORANGE = '\033[0;33m'
NC = '\033[0m'  # No Color

def print_color(text, color):
    print(f"{color}{text}{NC}")

def read_sorted_file(filepath):
    with open(filepath, 'r') as file:
        lines = file.readlines()
    return sorted(lines)

def main():
    # Check if exactly one argument is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py <path to INCAR file>")
        sys.exit(1)

    # Assign the provided INCAR file path to a variable
    incar_file = sys.argv[1]

    # Check if the provided INCAR file exists
    if not os.path.isfile(incar_file):
        print(f"Error: INCAR file '{incar_file}' does not exist.")
        sys.exit(1)

    # Find all error.number.tar.gz files
    error_files = [f for f in os.listdir('.') if f.startswith('error.') and f.endswith('.tar.gz')]
    if not error_files:
        print("Error: No error.number.tar.gz files found.")
        sys.exit(1)

    # Loop through each error tar file
    for error_file in error_files:
        print_color(f"Processing {error_file}...", RED)

        # Create a temporary directory for extraction
        with tempfile.TemporaryDirectory() as tmp_dir:
            # Extract the INCAR file from the current error tar file
            try:
                with tarfile.open(error_file, 'r:gz') as tar:
                    tar.extract('INCAR', path=tmp_dir)
            except (KeyError, tarfile.TarError) as e:
                print(f"Error: INCAR file not found in '{error_file}' or extraction failed.")
                continue

            extracted_incar = os.path.join(tmp_dir, 'INCAR')
            if not os.path.isfile(extracted_incar):
                print(f"Error: INCAR file not found in '{error_file}'.")
                continue

            # Read and sort the lines from both INCAR files
            incar_lines = read_sorted_file(incar_file)
            extracted_incar_lines = read_sorted_file(extracted_incar)

            # Compare the two INCAR files and output the unique lines
            unique_to_error_file = set(extracted_incar_lines) - set(incar_lines)
            unique_to_current_incar = set(incar_lines) - set(extracted_incar_lines)

            print_color(f"Lines unique to {error_file} INCAR file:", RED)
            print_color(''.join(unique_to_error_file), ORANGE)

            print_color("Lines unique to the Current INCAR file:", CYAN)
            print_color(''.join(unique_to_current_incar), ORANGE)

        print("Done processing {}.".format(error_file))
        print("--------------------------------------")

    print("All comparisons complete.")

if __name__ == "__main__":
    main()
