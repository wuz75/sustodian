![Sustodian](https://github.com/wuz75/sustodian/blob/main/sus.png)

# Sustodian
when your high throughput codes just aren't (slurm edition)

VASP USERS
Use CheckIncar.sh when you have one or multiple error.1.tar.gz files
It will go through each tar.gz folder and compare the INCAR tags to your most current INCAR file

Using Fireworks with Slurm
Use FindMyFW.sh when you have a slurm JobID and want to find out which firework it is running
Run FindMyFW.sh, then type in the jobid and you will get the FW_ID, spec.MPID and the directory its running in


when you set up these files
you can chmod +x thefile.sh to give it permissions
then add it to an alias
