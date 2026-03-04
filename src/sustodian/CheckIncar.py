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
NC = '\033[0m'

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

def extract_incar_from_tar(tar_file, tmp_dir):
    """
    Extract INCAR from a tar.gz file regardless of where it's stored inside.
    Handles paths like: INCAR, error.1/INCAR, /absolute/path/INCAR, etc.
    Returns the path to the extracted INCAR file, or None if not found.
    """
    # List all files in the archive
    result = subprocess.run(
        ['tar', '-tzf', tar_file],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        echo_error(f"Could not list contents of '{tar_file}'.")
        return None

    # Find any entry ending with 'INCAR'
    incar_entry = next(
        (line.strip() for line in result.stdout.splitlines()
         if line.strip().endswith('INCAR')),
        None
    )
    if not incar_entry:
        echo_error(f"INCAR file not found in '{tar_file}'.")
        return None

    # Extract that specific entry, stripping leading path components so it
    # always lands as tmp_dir/INCAR
    subprocess.run(
        ['tar', '-xzf', tar_file, '-C', tmp_dir,
         '--strip-components', str(incar_entry.count('/')),
         incar_entry],
        check=True
    )

    extracted_path = os.path.join(tmp_dir, 'INCAR')
    return extracted_path if os.path.exists(extracted_path) else None

def compare_incar_files(file1, file2, cwd):
    """
    Compare INCAR files from two sources. Each source can be a .tar.gz
    archive or a plain INCAR file.
    """
    def get_lines(file, tmp_dir):
        if file.endswith('.tar.gz'):
            incar_path = extract_incar_from_tar(file, tmp_dir)
            if not incar_path:
                return None
        else:
            incar_path = file
        with open(incar_path, 'r') as f:
            return sorted(f.readlines())

    with tempfile.TemporaryDirectory() as tmp_dir1, \
         tempfile.TemporaryDirectory() as tmp_dir2:

        lines1 = get_lines(file1, tmp_dir1)
        lines2 = get_lines(file2, tmp_dir2)

        if lines1 is None or lines2 is None:
            return

    unique_to_file1 = set(lines1) - set(lines2)
    unique_to_file2 = set(lines2) - set(lines1)

    label1 = file1
    label2 = "Current" if file2 == "./INCAR" else file2

    echo_info(f"Lines unique to {label1} INCAR file:")
    for line in sorted(unique_to_file1):
        echo_warning(line.strip())
    echo("\n")

    echo_info(f"Lines unique to {label2} INCAR file:")
    for line in sorted(unique_to_file2):
        echo_warning(line.strip())
    echo("\n")


if __name__ == "__main__":
    current_dir = os.getcwd()

    if len(sys.argv) != 2:
        echo_error("Usage: <script_name> <path to INCAR file>")
        sys.exit(1)

    incar_file = sys.argv[1]
    incar_gz_file = f"{incar_file}.gz"
    custodian_file = "custodian.json"
    custodian_gz_file = f"{custodian_file}.gz"

    incar_unzipped = False
    custodian_unzipped = False

    error_files = sorted(glob.glob('error.*.tar.gz'))
    if not error_files:
        echo_error("No error.number.tar.gz files found.")
        sys.exit(1)

    check_and_uncompress(incar_file, incar_gz_file, 'incar_unzipped')
    check_and_uncompress(custodian_file, custodian_gz_file, 'custodian_unzipped')
    echo("\n\n")

    with open(custodian_file, 'r') as f:
        custodian_data = json.load(f)

    custodian_errors = [
        error
        for item in custodian_data
        for correction in item['corrections']
        for error in correction['errors']
    ]

    # Compare consecutive error archives
    for i, error_file in enumerate(error_files[1:], start=1):
        prev_file = error_files[i - 1]
        echo(f"Here's what changed between {RED}{prev_file}{NC} and {RED}{error_file}{NC}...")
        if i - 1 < len(custodian_errors):
            echo(f"Custodian error in {RED}{prev_file}{NC}: {ORANGE}{custodian_errors[i - 1]}{NC}")
        compare_incar_files(prev_file, error_file, current_dir)
        echo_info("--------------------------------------")

    # Compare last error archive against current INCAR
    last_error_file = error_files[-1]
    echo(f"Here's what changed between {RED}{last_error_file}{NC} and the current {CYAN}INCAR file{NC}...")
    if custodian_errors:
        echo(f"Custodian error in {RED}{last_error_file}{NC}: {ORANGE}{custodian_errors[-1]}{NC}")
    compare_incar_files(last_error_file, incar_file, current_dir)
    echo_info("--------------------------------------")

    # Always show first error archive vs current INCAR as an overall summary
    if len(error_files) > 1:
        echo(f"Here's the overall change: {RED}{error_files[0]}{NC} vs current {CYAN}INCAR file{NC}...")
        compare_incar_files(error_files[0], incar_file, current_dir)

    if incar_unzipped:
        os.remove(incar_file)
        echo_info(f"Deleted uncompressed '{incar_file}' as '{incar_gz_file}' existed originally.")

    if custodian_unzipped:
        os.remove(custodian_file)
        echo_info(f"Deleted uncompressed '{custodian_file}' as '{custodian_gz_file}' existed originally.")

    echo("All comparisons complete. Best of luck o7")
    echo("\n\n")
