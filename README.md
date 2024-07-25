![Sustodian](https://github.com/wuz75/sustodian/blob/main/sus.png)

# Sustodian
when your high throughput codes just aren't (slurm edition)

There are two separate functionalities in Sustodian: CheckIncar and FindMyFW. Both functionalities have parallel versions in Python and Shell Scripts. You can use either.

## Installation
git clone this repo to any directory


## Recommended Aliases in ./bashrc:

### Alias for PYTHON
alias pysjob='python /your_installation_directory/sustodian/src/sustodian/FindMyFW.py'
alias pycincar='python /your_installation_directory/sustodian/src/sustodian/CheckIncar.py'

### Alias for SHELL SCRIPTS
alias sjob='/your_installation_directory/sustodian/shell_scripts/FindMyFW.sh'
alias checkincar='/your_installation_directory/sustodian/shell_scripts/CheckIncar.sh'

## FindMyFW (for Slurm and Fireworks users)
FindMyFW is for those who use a Slurm Job Scheduler and the Fireworks package. It helps you find the firework associated with any of your running jobs. It also helps find JobIDs that are empty (i.e not running any Fireworks).

#### How to use:
From any directory, type 'sjob' or 'pysjob' (shell vs python respectively). A prompt will allow you to enter a single JobID number which will return the directory of the job as well as the associated FireworksID (fw_id). You can also type "all" and it will return the directories and fw_id of JobIDs with status Running or "R". FindMyFW works for both rapidfire and singleshot launch methods, however rapidfire is recommended in most cases.

#### How it works
It parses data from the command "scontrol show job <jobid>" and parses your directory. It then looks for the most recent "launcher_" directory and looks inside for FW.json.

## CheckIncar (for VASP and Custodian users)
CheckIncar is for those who use VASP and Custodian (not to be confused with Sustodian). It is most useful to see which INCAR tags have been changed by custodian. It also now prints out the associated error in a easy to read manner.

#### How to use:
Go to the directory for your VASP calculation. Type 'checkincar' or 'pycincar' (shell vs python respectively) to easily see what tags custodian changed. CheckIncar is used when you have one or more error.#.tar.gz files.

#### How it works
It will go through each error.#.tar.gz folder and print out the INCAR tag changes and the associated custodian (error) handler. It now also works for completed jobs and unzips INCAR.gz and custodian.json.gz files safely.

