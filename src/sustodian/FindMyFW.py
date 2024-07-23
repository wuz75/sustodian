import os
import subprocess
import json
import paramiko
import getpass

# Function to execute shell commands and return the output

def execute_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"Command failed: {command}\n{result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        print(e)
        ssh_login(command)
        return None

def ssh_login(command):
    hostname = input("Enter the hostname without your username: ")
    username = input("Enter the username: ")
    password = getpass.getpass('Enter password: ')

    #os.system(f"ssh {username}@{hostname}")

    # Create an SSH client
    ssh = paramiko.SSHClient()

    # Automatically add the server's host key (for the first time)
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        # Connect to the server
        ssh.connect(hostname, username=username, password=password)

        # Run the 'scontrol' command
        stdin, stdout, stderr = ssh.exec_command(command)
        # Capture the output and errors
        output = stdout.read().decode('utf-8')
        errors = stderr.read().decode('utf-8')
        if errors:
            raise Exception(f"Command failed: {command}\n{errors}")
        return output.strip()

        # Print the output of the command
        
        
    finally:
        # Close the SSH connection
        ssh.close()
        
    


def get_fwid(jobid):

    # Get job information and save to a temporary file
    job_info = execute_command(f"scontrol show jobid {jobid}")

    # Extract the StdOut directory from the job information
    stdout_dir = ""
    for line in job_info.splitlines():
        if "StdOut=" in line:
            stdout_dir = line.split("=", 1)[1]
            break

    # Check if StdOut path was found
    if not stdout_dir:
        print("StdOut path not found in job information")
        exit(1)

    base_dir = os.path.dirname(stdout_dir)

    # Change directory to the extracted base directory
    try:
        os.chdir(base_dir)
    except OSError:
        print(f"Failed to change directory to {base_dir}")
        exit(1)

    # Print the current directory to confirm
    print(f"Changed directory to: {os.getcwd()}")

    # Find the largest directory with the pattern "launcher_*"
    launch_dirs = subprocess.check_output(f"find {os.getcwd()} -type d -name 'launcher_*'", shell=True).decode().splitlines()
    largest_dir = max(launch_dirs, key=lambda d: d.split('_')[-1])

    try:
        os.chdir(largest_dir)
    except OSError:
        print(f"Failed to change directory to {largest_dir}")
        exit(1)

    print(f"Changed directory to: {os.getcwd()}")

    json_file = os.path.join(os.getcwd(), "FW.json")

    # Check if the JSON file exists
    if os.path.isfile(json_file):
        with open(json_file, 'r') as f:
            data = json.load(f)
        spec_mpid = data.get('spec', {}).get('MPID', 'N/A')
        fw_id = data.get('fw_id', 'N/A')

        # Output the extracted values
        print(f"spec.MPID: {spec_mpid}")
        print(f"fw_id: {fw_id}")
    else:
        print(f"FW.json not found in {largest_dir}")
        
        return fw_id

