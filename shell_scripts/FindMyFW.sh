squeue -u $USER
clean_dir_later=$(pwd)

read -p "Type 'all' or Enter a job ID: " jobid

# Check if jobid is a number
if [[ "$jobid" =~ ^[0-9]+$ ]]; then
    echo $jobid
    scontrol show jobid $jobid > temp_$jobid.txt
    stdout_dir=$(grep "StdOut=" temp_$jobid.txt | cut -d'=' -f2)
    
    
    rm temp_$jobid.txt
    # Check if StdOut path was found
    if [[ -z "$stdout_dir" ]]; then
      echo "StdOut path not found in job information"
      exit 1
    fi
    base_dir=$(dirname "$stdout_dir")

    # Change directory to the extracted base directory

    cd "$base_dir" || { echo "Failed to change directory to $base_dir"; exit 1; }

    # Print the current directory to confirm
    echo "Changed directory to: $(pwd)"
    largest_dir=$(find $(pwd) -type d -name "launcher_*" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | sort -r | head -n 1)
    cd "launcher_$largest_dir" || { echo "Failed to change directory to $base_dir/launcher_$largest_dir";

        printf "%s\n" "-----------------------------------------------------------------------------"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |"
        printf "%s\n" "|           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |"
        printf "%s\n" "|           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |"
        printf "%s\n" "|           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |"
        printf "%s\n" "|           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "|     This slurm job probably doesn't have a FW_ID associated with it. It's   |"
        printf "%s\n" "|     probably safe to just scancel this job so you don't waste hours.        |"
        printf "%s\n" "|     You could also try going to the first directory that was printed        |"
        printf "%s\n" "|     out to maybe figure out what happened. Best of luck                     |"
        printf "%s\n" "|     I HOPE YOU KNOW WHAT YOU ARE DOING!                                     |"
        printf "%s\n" "|                                                                             |"
        printf "%s\n" "-----------------------------------------------------------------------------"
        exit 1;
    }

    echo "Changed directory to: $(pwd)"
    json_file="$(pwd)/FW.json"

    # Check if the JSON file exists
    if [ -f "$json_file" ]; then
        # Extract spec.MPID and fw_id from FW.json
        spec_mpid=$(jq -r '.spec.MPID' "$json_file")
        fw_id=$(jq -r '.fw_id' "$json_file")

        # Output the extracted values
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
else
    echo "Reading all job IDs..."
    squeue -u $USER > job_list.txt

    # Read job IDs from job_list.txt
    job_list="job_list.txt"

    # Check if the job list file exists
    if [[ ! -f "$job_list" ]]; then
        echo "Job list file not found!"
        exit 1
    fi

    # Read job IDs from the file and process each one
    while read -r line; do
        # Skip the header line
        if [[ "$line" =~ ^[[:space:]]*JOBID ]]; then
            continue
        fi

        # Extract job ID from the line
        job_id=$(echo $line | awk '{print $1}')

        # Skip empty lines
        if [[ -z "$job_id" ]]; then
            continue
        fi

        # Run the remainder of the code for each job ID
        echo "Processing job ID: $job_id"
        scontrol show jobid $job_id > temp_$job_id.txt

        # Place your remaining code here, for example:
        # Your remainder code
        # do_something_with temp_$job_id.txt

        # Extract the StdOut directory from the temporary file
        stdout_dir=$(grep "StdOut=" temp_$job_id.txt | cut -d'=' -f2)
        rm temp_$job_id.txt
        # Check if StdOut path was found
        if [[ -z "$stdout_dir" ]]; then
          echo "StdOut path not found in job information"
          exit 1
        fi
        base_dir=$(dirname "$stdout_dir")

        # Change directory to the extracted base directory

        cd "$base_dir" || { echo "Failed to change directory to $base_dir"; exit 1; }

        # Print the current directory to confirm
        echo "Changed directory to: $(pwd)"
        largest_dir=$(find $(pwd) -type d -name "launcher_*" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | sort -r | head -n 1)
        cd "launcher_$largest_dir" || { echo "Failed to change directory to $base_dir $largest_dir";
            printf "%s\n" "-----------------------------------------------------------------------------"
            printf "%s\n" "|                                                                             |"
            printf "%s\n" "|           W    W    AA    RRRRR   N    N  II  N    N   GGGG   !!!           |"
            printf "%s\n" "|           W    W   A  A   R    R  NN   N  II  NN   N  G    G  !!!           |"
            printf "%s\n" "|           W    W  A    A  R    R  N N  N  II  N N  N  G       !!!           |"
            printf "%s\n" "|           W WW W  AAAAAA  RRRRR   N  N N  II  N  N N  G  GGG   !            |"
            printf "%s\n" "|           WW  WW  A    A  R   R   N   NN  II  N   NN  G    G                |"
            printf "%s\n" "|           W    W  A    A  R    R  N    N  II  N    N   GGGG   !!!           |"
            printf "%s\n" "|                                                                             |"
            printf "%s\n" "|     This slurm job probably doesn't have a FW_ID associated with it. It's   |"
            printf "%s\n" "|     probably safe to just scancel this job so you don't waste hours.        |"
            printf "%s\n" "|     You could also try going to the first directory that was printed        |"
            printf "%s\n" "|     out to maybe figure out what happened. Best of luck                     |"
            printf "%s\n" "|     I HOPE YOU KNOW WHAT YOU ARE DOING!                                     |"
            printf "%s\n" "|                                                                             |"
            printf "%s\n" "-----------------------------------------------------------------------------"
            exit 1;
        }

        echo "Changed directory to: $(pwd)"
        json_file="$(pwd)/FW.json"

        # Check if the JSON file exists
        if [ -f "$json_file" ]; then
            # Extract spec.MPID and fw_id from FW.json
            spec_mpid=$(jq -r '.spec.MPID' "$json_file")
            fw_id=$(jq -r '.fw_id' "$json_file")

            # Output the extracted values
            echo "spec.MPID: $spec_mpid"
            echo "fw_id: $fw_id"
        else
            echo "FW.json not found in $largest_dir"
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
    done < "$job_list"
    cd $clean_dir_later
    rm job_list.txt
fi


