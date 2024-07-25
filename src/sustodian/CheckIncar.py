import os
import sys
import glob
import subprocess
import shutil
import json
import tempfile

# Color codes
RED = '\033[0;31m'
CYAN = '\033[0;36m'
ORANGE = '\033[0;33m'
NC = '\033[0m'  # No Color

def echo(message):
    print(message)

def echo_error(message):
      print(f"{RED}Error: {message}{NC}")

def echo_info(message):
    print(f"{CYAN}{message}{NC}")

def echo_warning(message):
    print(f"{ORANGE}{message}{NC}")

def check_and_uncompress(file, gz_file, unzipped_var):
    if not os.path.exists(file):
        if os.path.exists(gz_file):
            echo(f"File '{file}' does not exist.")
            echo(f"Found compressed file '{gz_file}'. Uncompressing...")
            with open(file, 'wb') as f_out:
                subprocess.run(['gunzip', '-c', gz_file], stdout=f_out, check=True)
            globals()[unzipped_var] = True
        else:
            echo_error(f"Neither '{file}' nor '{gz_file}' exist.")
            sys.exit(1)

def compare_incar_files(file1, file2):
    if file1.endswith('.tar.gz') and file2.endswith('.tar.gz'):
        with tempfile.TemporaryDirectory() as tmp_dir1, tempfile.TemporaryDirectory() as tmp_dir2:
            subprocess.run(['tar', '-xzf', file1, '-C', tmp_dir1, 'INCAR'], check=True)
            subprocess.run(['tar', '-xzf', file2, '-C', tmp_dir2, 'INCAR'], check=True)

            extracted_incar1 = os.path.join(tmp_dir1, 'INCAR')
            extracted_incar2 = os.path.join(tmp_dir2, 'INCAR')

            if not os.path.exists(extracted_incar1):
                echo_error(f"INCAR file not found in '{file1}'.")
                return
            if not os.path.exists(extracted_incar2):
                echo_error(f"INCAR file not found in '{file2}'.")
                return

            with open(extracted_incar1, 'r') as f1, open(extracted_incar2, 'r') as f2:
                lines1 = sorted(f1.readlines())
                lines2 = sorted(f2.readlines())
    else:
        with tempfile.TemporaryDirectory() as tmp_dir:
            if file1.endswith('.tar.gz'):
                tar_file, incar_file = file1, file2
            elif file2.endswith('.tar.gz'):
                tar_file, incar_file = file2, file1
            else:
                echo_error(f"One file should be a .tar.gz file")
                return
            
            subprocess.run(['tar', '-xzf', tar_file, '-C', tmp_dir, 'INCAR'], check=True)
            extracted_incar = os.path.join(tmp_dir, 'INCAR')

            if not os.path.exists(extracted_incar):
                echo_error(f"INCAR file not found in '{tar_file}'.")
                return

            with open(extracted_incar, 'r') as f1, open(incar_file, 'r') as f2:
                lines1 = sorted(f1.readlines())
                lines2 = sorted(f2.readlines())

    unique_to_file1 = set(lines1) - set(lines2)
    unique_to_file2 = set(lines2) - set(lines1)

    echo_info(f"Lines unique to {file1} INCAR file:")
    for line in unique_to_file1:
        echo_warning(line.strip())
    echo("\n")

    if file2=="./INCAR":
        file2="Current"
        
    echo_info(f"Lines unique to {file2} INCAR file:")
    for line in unique_to_file2:
        echo_warning(line.strip())
    echo("\n")

# Main script logic
if __name__ == "__main__":
    if len(sys.argv) != 2:
        echo_error("Usage: <script_name> <path to INCAR file>")
        sys.exit(1)

    incar_file = sys.argv[1]
    incar_gz_file = f"{incar_file}.gz"
    custodian_file = "custodian.json"
    custodian_gz_file = f"{custodian_file}.gz"
    
    # Initial variables
    incar_unzipped = False
    custodian_unzipped = False
    
    error_files = sorted(glob.glob('error.*.tar.gz'))
    if not error_files:
        echo_error("No error.number.tar.gz files found.")
        sys.exit(1)

    # Check and uncompress INCAR file
    check_and_uncompress(incar_file, incar_gz_file, 'incar_unzipped')

    # Check and uncompress custodian.json file
    check_and_uncompress(custodian_file, custodian_gz_file, 'custodian_unzipped')
    echo("\n\n")
    with open(custodian_file, 'r') as f:
        custodian_data = json.load(f)
    
    custodian_errors = [error for item in custodian_data for correction in item['corrections'] for error in correction['errors']]
    
    error_index = 0
    prev_file = ""

    for i, error_file in enumerate(error_files):
        if prev_file and len(error_files) > 1:
            echo(f"Here's what changed between {RED}{prev_file}{NC} and {RED}{error_file}{NC}...")
            if error_index < len(custodian_errors):
                echo(f"Custodian error in {RED}{prev_file}{NC}: {ORANGE}{custodian_errors[error_index]}{NC}")
                error_index += 1
            compare_incar_files(prev_file, error_file)
            echo_info("--------------------------------------")
        prev_file = error_file

    if len(error_files) > 1 and prev_file:
        echo(f"Here's what changed between {RED}{prev_file}{NC} and the current {CYAN}INCAR file{NC}...")
        last_error_index = len(custodian_errors) - 1
        if last_error_index >= 0:
            echo(f"Custodian Error in {RED}{prev_file}{NC}: {ORANGE}{custodian_errors[last_error_index]}{NC}")

        compare_incar_files(prev_file, incar_file)

    if len(error_files) == 1:
        first_error_file = error_files[0]
        echo(f"Here's what changed between {RED}{first_error_file}{NC} and the current {CYAN}INCAR{NC} file...")
        echo(f"Custodian Error in {RED}{prev_file}{NC}: {ORANGE}{custodian_errors[0]}{NC}")
        compare_incar_files(first_error_file, incar_file)

    # Comparison between the first error file and current INCAR file before deleting files
    first_error_file = error_files[0]
    echo(f"Here's what changed between {RED}{first_error_file}{NC} and the current {CYAN}INCAR file{NC} (before file deletion)...")
    compare_incar_files(first_error_file, incar_file)
    
    if incar_unzipped:
        os.remove(incar_file)
        echo_info(f"Deleted uncompressed '{incar_file}' as '{incar_gz_file}' existed originally.")

    if custodian_unzipped:
        os.remove(custodian_file)
        echo_info(f"Deleted uncompressed '{custodian_file}' as '{custodian_gz_file}' existed originally.")

    echo("All comparisons complete. Best of luck o7")
    echo("\n\n")
