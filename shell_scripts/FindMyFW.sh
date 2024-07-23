#!/bin/bash

# Display current user jobs
squeue -u $USER
clean_dir_later=$(pwd)

# Prompt for job ID or "all"
read -p "Type 'all' or Enter a job ID: " jobid

# Function to process a single job ID
process_job_id() {
    local job_id=$1
    echo "Processing job ID: $job_id"
    scontrol show jobid $job_id > temp_$job_id.txt
    stdout_dir=$(grep "StdOut=" temp_$job_id.txt | cut -d'=' -f2)
    rm temp_$job_id.txt

    # Check if StdOut path was found
    if [[ -z "$stdout_dir" ]]; then
        echo "StdOut path not found in job information"
        return 1
    fi
    base_dir=$(dirname "$stdout_dir")

    # Change directory to the extracted base directory
    cd "$base_dir" || { echo "Failed to change directory to $base_dir"; return 1; }
    echo "Changed directory to: $(pwd)"

    largest_dir=$(find $(pwd) -type d -name "launcher_*" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | sort -r | head -n 1)
    if [[ -z "$largest_dir" ]]; then
        echo "No launcher_* directory found"
        return 1
    fi

    cd "launcher_$largest_dir" || {
        echo "Failed to change directory to $base_dir/launcher_$largest_dir"
        warning_message
        return 1
    }

    echo "Changed directory to: $(pwd)"
    json_file="$(pwd)/FW.json"

    if [ -f "$json_file" ]; then
        spec_mpid=$(jq -r '.spec.MPID' "$json_file")
        fw_id=$(jq -r '.fw_id' "$json_file")
        echo "spec.MPID: $spec_mpid"
        echo "fw_id: $fw_id"
    else
        echo "FW.json not found in launcher_$largest_dir"
        warning_message
    fi
}

# Function to display warning message
warning_message() {
    printf "%s\n" "-----------------------------------------------------------------------------"
    printf "%s\n" "|                                                                             |"
    printf "%s\n" "|           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |"
    printf "%s\n" "|           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |"
    printf "%s\n" "|           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |"
    printf "%s\n" "|           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |"
    printf "%s\n" "|           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |"
    printf "%s\n" "|           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |"
    printf "%s\n" "|                                                                             |"
    printf "%s\n" "|     This slurm job probably doesn't have a FW_ID associated with it.        |"
    printf "%s\n" "|     You can probably check the directory printed above to figure out        |"
    printf "%s\n" "|     what happened. Best of luck!                                            |"
    printf "%s\n" "|     I HOPE YOU KNOW WHAT YOU ARE DOING!                                     |"
    printf "%s\n" "|                                                                             |"
    printf "%s\n" "-----------------------------------------------------------------------------"
}

# Main logic
if [[ "$jobid" =~ ^[0-9]+$ ]]; then
    process_job_id $jobid
else
    echo "Reading all job IDs..."
    squeue -u $USER > job_list.txt

    if [[ ! -f "job_list.txt" ]]; then
        echo "Job list file not found!"
        exit 1
    fi

    while read -r line; do
        if [[ "$line" =~ ^[[:space:]]*JOBID ]]; then
            continue
        fi
        job_id=$(echo $line | awk '{print $1}')
        [[ -n "$job_id" ]] && process_job_id $job_id
    done < job_list.txt

fi
rm job_list.txt
cd $clean_dir_later
