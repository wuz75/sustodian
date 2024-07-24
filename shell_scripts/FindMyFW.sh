#!/bin/bash
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color
#squeue -u $USER
squeue --states=R -u $USER
clean_dir_later=$(pwd)

read -p "Type [all] or Enter a job ID: " jobid

dir_getter() {
    if [[ "$jobid" =~ ^[0-9]+$ ]]; then
        echo "Processing job ID: $jobid"
        scontrol show jobid $jobid > temp_$jobid.txt
        stdout_dir=$(grep "StdOut=" temp_$jobid.txt | cut -d'=' -f2)
        rm temp_$jobid.txt
        
        # Check if StdOut path was found
        if [[ -z "$stdout_dir" ]]; then
            echo -e "${RED}StdOut path not found in job information${NC}"
            exit 1
        fi
        
        base_dir=$(dirname "$stdout_dir")
        dir_rapidfire;


    else
        echo -e "${CYAN}Reading all job IDs...${NC}"
        squeue --states=R -u $USER > job_list.txt

        # Check if the job list file exists
        if [[ ! -f "job_list.txt" ]]; then
            echo -e "${RED}Job list file not found!${NC}"
            exit 1
        fi

        while read -r line; do
            # Skip the header line
            if [[ "$line" =~ ^[[:space:]]*JOBID ]]; then
                continue
            fi

            # Extract job ID from the line
            job_id=$(echo $line | awk '{print $1}')

            echo -e "${ORANGE}Processing job ID: ${CYAN}$job_id${NC}"
            scontrol show jobid $job_id > temp_$job_id.txt

            # Extract the StdOut directory from the temporary file
            stdout_dir=$(grep "StdOut=" temp_$job_id.txt | cut -d'=' -f2)
            rm temp_$job_id.txt

            # Check if StdOut path was found
            if [[ -z "$stdout_dir" ]]; then
                echo -e "${RED}StdOut path not found in job information${NC}"
                exit 1
            fi

            base_dir=$(dirname "$stdout_dir")
            dir_rapidfire;
#            if ! dir_rapidfire; then
#                dir_singleshot
#            fi

        done < "job_list.txt"

        cd $clean_dir_later
        rm job_list.txt
    fi
}

dir_singleshot() {
#    cd "$base_dir" || { echo -e "${RED}Failed to change directory to ${ORANGE}$base_dir${NC}"; exit 1; }
#    echo "Changed directory to: $(pwd)"
    json_file="$(pwd)/FW.json"

 
 if [ -f "$json_file" ]; then
        spec_mpid=$(jq -r '.spec.MPID' "$json_file")
        fw_id=$(jq -r '.fw_id' "$json_file")

#        echo "spec.MPID: $spec_mpid"
#        echo "fw_id: $fw_id"
        
        
        
    else
        echo "FW.json not found in $base_dir"
        printf "%s\n" "-----------------------------------------------------------------------------"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |"
        printf "%s\n" "|           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |"
        printf "%s\n" "|           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |"
        printf "%s\n" "|           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |"
        printf "%s\n" "|           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|     This slurm job probably doesn't have an FW_ID associated with it.       |"
        printf "%s\n" "|     something probably went wrong. You can probably check the directory     |"
        printf "%s\n" "|     above to maybe figure out what happened. Best of luck                   |"
        printf "%s\n" "|                    Also why are you using singleshot                        |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "-----------------------------------------------------------------------------"
    fi
}

dir_rapidfire() {
#    echo $base_dir
    cd "$base_dir" || { echo -e "${RED}Failed to change directory to ${CYAN}$base_dir${NC}"; exit 1; }

#    echo "Changed directory to: $(pwd)"
    largest_dir=$(find "$(pwd)" -type d -name "launcher_*" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | sort -r | head -n 1)

    if [[ -z "$largest_dir" ]]; then
        echo -e "${RED}No launcher directories found in $base_dir${NC}"
        return 1
    fi

    cd "launcher_$largest_dir" || { dir_singleshot
        echo -e "${ORANGE}perhaps you are using singleshot (consider using rapidfire) but alas I will still help${NC}"
    }

    echo "You are currently in: $(pwd)"
    json_file="$(pwd)/FW.json"

    if [ -f "$json_file" ]; then
        spec_mpid=$(jq -r '.spec.MPID' "$json_file")
        fw_id=$(jq -r '.fw_id' "$json_file")

        echo "spec.MPID: $spec_mpid"
        echo "fw_id: $fw_id"
    else
        echo "FW.json not found in launcher_$largest_dir"
        printf "%s\n" "-----------------------------------------------------------------------------"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |"
        printf "%s\n" "|           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |"
        printf "%s\n" "|           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |"
        printf "%s\n" "|           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |"
        printf "%s\n" "|           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|     This slurm job probably doesn't have an FW_ID associated with it. This  |"
        printf "%s\n" "|     means that the job either hasn't started running yet or something       |"
        printf "%s\n" "|     else went wrong. You can probably check the directory printed           |"
        printf "%s\n" "|     above to maybe figure out what happened. Best of luck                   |"
        printf "%s\n" "|     I HOPE YOU KNOW WHAT YOU ARE DOING!                                     |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "-----------------------------------------------------------------------------"
    fi
}

dir_getter;