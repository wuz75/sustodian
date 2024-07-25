![Sustodian](https://github.com/wuz75/sustodian/blob/main/sus.png)

# Sustodian
when your high throughput codes just aren't (slurm edition)

There are two separate functionalities in Sustodian: CheckIncar and FindMyFW. Both functionalities have parallel versions in Python and Shell Scripts. You can use either.

## Recommended Aliases in ./bashrc:

### Alias for PYTHON
alias pysjob='python /path_to_file/FindMyFW.py'
alias pycincar='python /path_to_file/CheckIncar.py'

### Alias for SHELL SCRIPTS
alias sjob='/path_to_file/FindMyFW.sh'
alias checkincar='/path_to_file/CheckIncar.sh'

## CheckIncar
CheckIncar is for those who use VASP and Custodian (not to be confused with Sustodian). It is most useful to see which INCAR tags have been changed by custodian. It also now prints out the associated error in a easy to read manner.

#### How to use:
Go to the directory for your VASP calculation. Type 'checkincar' or 'pycincar' (shell vs python respectively) to easily see what tags custodian changed. CheckIncar is used when you have one or more error.#.tar.gz files.

#### How it works
It will go through each error.#.tar.gz folder and print out the INCAR tag changes and the associated custodian (error) handler. It now also works for completed jobs and unzips INCAR.gz and custodian.json.gz files safely.

## FindMyFW
FindMyFW is for those who use a Slurm Job Scheduler and the Fireworks package. It helps you find the firework associated with any of your running jobs. It also helps find JobIDs that are empty (i.e not running any Fireworks).

#### How to use:
From any directory, type 'sjob' or 'pysjob' (shell vs python respectively). A prompt will allow you to enter a single JobID number which will return the directory of the job as well as the associated FireworksID (fw_id). You can also type "all" and it will return the directories and fw_id of JobIDs with status Running or "R". 

#### How it works
It just does 
