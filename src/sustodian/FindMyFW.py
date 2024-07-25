import os
import subprocess
import re
import json
import sys

RED = '\033[0;31m'
CYAN = '\033[0;36m'
ORANGE = '\033[0;33m'
NC = '\033[0m'  # No Color

def run_command(command):
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        print(f"{RED}Command failed: {command}\n{result.stderr}{NC}")
        sys.exit(1)
    return result.stdout.strip()

def get_stdout_dir(job_id):
    output = run_command(f"scontrol show jobid {job_id}")
    match = re.search(r"StdOut=(\S+)", output)
    if match:
        stdout_dir = match.group(1)
    else:
        print(f"{RED}StdOut path not found in job information{NC}")
        sys.exit(1)
    return stdout_dir

def process_single_job(jobid):
    stdout_dir = get_stdout_dir(jobid)
    base_dir = os.path.dirname(stdout_dir)
    os.chdir(base_dir)
#    process_directory(base_dir)
    dir_rapidfire(base_dir)

def process_all_jobs():
    user = os.getenv('USER')
    job_list = run_command(f"squeue --states=R -u {user}")
    job_lines = job_list.splitlines()[1:]  # Skip the header line
    if not job_lines:
        print(f"{RED}No jobs found!{NC}")
        sys.exit(1)
    
    for line in job_lines:
        job_id = line.split()[0]
        print(f"{ORANGE}Processing job ID: {CYAN}{job_id}{NC}")
        process_single_job(job_id)

def load_json(file_path):
    with open(file_path) as f:
        return json.load(f)

def dir_singleshot(base_dir):
    # Skipping directory change
    json_file = os.path.join(base_dir, "FW.json")

    if os.path.isfile(json_file):
        data = load_json(json_file)
        spec_mpid = data.get('spec', {}).get('MPID')
        fw_id = data.get('fw_id')

        if spec_mpid:
            print(f"spec.MPID: {spec_mpid}")
        if fw_id:
            print(f"fw_id: {fw_id}")
    else:
        print_warning(base_dir)

def dir_rapidfire(base_dir):
    os.chdir(base_dir)
    launcher_dirs = [d for d in os.listdir('.') if os.path.isdir(d) and d.startswith("launcher_")]
    if not launcher_dirs:
        try:
            dir_singleshot(base_dir)
        except:
            print(f"{RED}No launcher directories found in {base_dir}{NC}")
        return 1

    largest_dir = sorted(launcher_dirs, reverse=True)[0]
    launcher_path = os.path.join(base_dir, largest_dir)
    os.chdir(launcher_path)
    print(launcher_path)
    json_file = os.path.join(launcher_path, "FW.json")
    if os.path.isfile(json_file):
        data = load_json(json_file)
        spec_mpid = data.get('spec', {}).get('MPID')
        fw_id = data.get('fw_id')

        print(f"spec.MPID: {spec_mpid}")
        print(f"fw_id: {fw_id}")
    else:
        print_warning(launcher_path)
        return dir_singleshot(base_dir)

def print_warning(base_dir):
    warning_message = f"""
    {"-" * 77}
    |                                                                             |
    |           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |
    |           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |
    |           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |
    |           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |
    |           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |
    |           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |
    |                                                                             |
    |     This slurm job probably doesn't have an FW_ID associated with it.       |
    |     something probably went wrong. You can probably check the directory     |
    |     above to maybe figure out what happened. Best of luck                   |
    |                    Also why are you using singleshot                        |
    |                                                                             |
    {"-" * 77}
    """
    print(warning_message)

def main():
    user = os.getenv('USER')
    print(run_command(f"squeue --states=R -u {user}"))
    current_dir = os.getcwd()
    
    jobid = input("Type [all] or Enter a job ID: ").strip()

    if jobid.lower() == 'all':
        process_all_jobs()
    elif re.match(r'^\d+$', jobid):
        process_single_job(jobid)
    else:
        print(f"{RED}Invalid input. Please type a valid job ID or 'all'.{NC}")
        sys.exit(1)

    os.chdir(current_dir)

if __name__ == "__main__":
    main()

