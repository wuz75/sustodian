squeue -u $USER
read -p "Enter job ID: " jobid
scontrol show jobid $jobid > temp.txt

# Extract the StdOut directory from the temporary file
stdout_dir=$(grep "StdOut=" temp.txt | cut -d'=' -f2)
rm temp.txt
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
cd "launcher_$largest_dir" || { echo "Failed to change directory to $base_dir $largest_dir"; exit 1; }
echo "Changed directory to: $(pwd)"
json_file="$(pwd)/FW.json"

# Check if the JSON file exists
if [ -f "$json_file" ]; then
    # Extract spec.MPID and fw_id from FW.json
    # you can add your own specs here to parse whatever you want
    spec_mpid=$(jq -r '.spec.MPID' "$json_file")
    fw_id=$(jq -r '.fw_id' "$json_file")

    # Output the extracted values
    echo "spec.MPID: $spec_mpid"
    echo "fw_id: $fw_id"
else
    echo "FW.json not found in $largest_dir"
fi
