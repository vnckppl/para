#!/bin/bash

# Vincent Koppelmans

usage()
{
cat << EOF
$(tput setaf 4)$(tput bold)
- This script runs jobs in parallel on a multi-core machine. 
- Jobs are read from a text file (one job per line). 
- The maximum number of jobs to be run simultaneously needs to be specified.$(tput sgr0)

OPTIONS:
   $(tput setaf 5)-h$(tput sgr0)                     Show this ($(tput setaf 5)$(tput bold)h$(tput sgr0))elp menu
   $(tput setaf 5)-c <filename>$(tput sgr0)          Text file with ($(tput setaf 5)$(tput bold)c$(tput sgr0))ommands (one per line)
   $(tput setaf 5)-d <directory>$(tput sgr0)         Log file ($(tput setaf 5)$(tput bold)d$(tput sgr0))irectory
   $(tput setaf 5)-p <number of cores>$(tput sgr0)   Number of ($(tput setaf 5)$(tput bold)p$(tput sgr0))rocessors (cores) to be used
   $(tput setaf 5)-k$(tput sgr0)                     ($(tput setaf 5)$(tput bold)K$(tput sgr0))ill jobs invoked by para   

EXAMPLE:
- Running jobs:
  $(tput bold)para -c /Volumes/Data/joblist.txt -d /Volumes/Data/Project -p 10$(tput sgr0)

- Killing jobs:
  First quit para if it has not already finished (ctrl-c). Then run:
  $(tput bold)para -k -d <directory>$(tput sgr0)
  ...where <directory> should point to the same folder as the one used 
  when invoking para initially.


EOF
}

FILE=
PROCESSOR=
while getopts "hc:d:p:k" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         c)
             FILE=$OPTARG
             ;;
         d)
             DIRECTORY=$OPTARG
             ;;
         p)
             PROCESSOR=$OPTARG
             ;;
         k)
             KILL=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

# Check if all arguments have been specified
Tall=$(( ${#FILE} * ${#PROCESSOR} * ${#DIRECTORY} * ${#KILL} ))
Trun=$(( ${#FILE} * ${#PROCESSOR} * ${#DIRECTORY} ))
Tkil=$(( ${#DIRECTORY} * ${#KILL} ))

if [[ "${Tall}" -gt 0 ]]; then echo "Too many arguments specified"; usage ; exit 1; fi



# When all parameters for a para run have been set:
if [[ "${Trun}" -gt 0 ]]; then

    # Go to script folder and create log file folder
    cd ${DIRECTORY}
    mkdir -p ${DIRECTORY}/para_output
    
    # Count number of jobs and set first job to number 0
    NJOBS=$(awk 'NF' ${FILE} | wc -l | sed 's/\ //g')
    JOB_NUM=0
    
    # Announce the start of the batch with date
    echo $'\n\n'$(tput sgr0)$(tput bold)"Start batch on `date`"$(tput sgr0)
    
    
    # Loop over all jobs
    while read command; do

        # Test how many jobs there are running in the background of the current shell
        # If this is greater or equal than the number specified by the user,
        # then sleep for 30 seconds.
        while [ $(jobs | wc -l) -ge ${PROCESSOR} ] ; do
            sleep 30
        done
        
        # ... when there are fewer jobs running than specified by the user,
        # start jobs:
        
        # First push some info to the shell
        # Continue the job number
        let JOB_NUM++
        # Create unique ID for log file: DMY_HMS_RandomNumber_ScriptFileName
        ID=$(date +"%Y%m%d_%H%M%S")_$((10000 + RANDOM % 99999))_$(echo ${command} | awk -F" " '{ print $NF }' | xargs basename | sed 's/\.sh//g')
        LOG="${DIRECTORY}/para_output/${ID}.txt"
        # Zero pad job number
        JOB_NUMp=$(echo 0000${JOB_NUM} | tail -c $((${#NJOBS}+1)))
        # Echo the job number, when the job is started, and the command
        echo $(tput setaf 6)"${JOB_NUMp}/${NJOBS}"$(tput setaf 2) $(date +%d\ %b\ %Y) @ $(date +%H:%M)$(tput sgr0) "- ${command}"
        # Print command to log file
        echo "${command}" >> ${LOG}
        # Run command and then save exit status; redirect all output to the log; run everything in background
        # if command is already prepended by 'bash'; then
        if [ "$(echo "${command}" | awk '{ print $1 }' | grep -w bash)" ]; then
            (time(bash -c "${command/bash/bash -e}"; echo "exit=$?")) >> ${LOG} 2>&1 &
        else \
            (time(bash -e "${command}"; echo "exit=$?")) >> ${LOG} 2>&1 &
        fi
        # Print the process ID to the log file
        echo "PID=$!" >> ${LOG}
        
    done < <(cat "${FILE}")


    # Wait until all jobs (background processes) have finished
    wait

    # Announce that all jobs have finished
    echo $(tput bold)"All jobs finished on `date`"$(tput sgr0)$'\n\n'

    
    # Create exit status and runtime report
    report="${DIRECTORY}/para_output/jobStatus.csv"
    echo "Job,Runtime,ExitStatus" > "${report}"
    logs=$(find ${DIRECTORY}/para_output -iname "*.txt")
    for log in $(echo "${logs}"); do

        # Get process name, runtime, and exit status
        pNM=$(sed -n 1p "${log}")
        rtm=$(cat "${log}" | tail -3 | grep real | awk '{ print $2 }')
        ext=$(cat "${log}" | tail -5 | grep exit= | cut -d= -f2)
        
        # Write  to file
        echo "${pNM},${rtm},${ext}" >> "${report}"

    done
        
    # Display jobs that failed if more than 1 failed
    SUMCOL=$(cat "${report}" | awk -F, '{ SUM += $2} END { print SUM }')
    if [ "${SUMCOL}" -gt 0 ]; then
        echo "$(tput setaf 1)The following job(s) failed:$(tput sgr0)"
        cat "${report}" | grep -v ",0$" | column -t | sed -e 's/,/ (exit status /g' -e 's/$/)/g'
        echo
    fi
        


# When all parameters for the kill switch have been set:
elif [[ "${Tkil}" -gt 0 ]]; then

    # Test if para_output folder exists, if not exit
    if [ ! -d "${DIRECTORY}/para_output" ]; then
        echo "Wrong directory: directory does not contain a para log folder (para_output)."
        usage; exit 1;
    fi
    
    # Get all process ID numbers
    logs=$(find ${DIRECTORY}/para_output -iname "*.txt")
    for log in $(echo "${logs}"); do

        # Get process name and PID
        pNM=$(sed -n 1p "${log}")
        pID=$(sed -n 2p "${log}" | cut -d= -f2)
        
        # Test if PID is running, if so, kill
        if [ -n "$(ps -p ${pID} -o pid=)" ]; then
            echo "kill PID $(tput setaf 1)${pID}$(tput sgr0)"$'\t'"${pNM}"
            kill ${pID}
        fi

    done

else echo "Not enough arguments specified"; usage ; exit 1; fi
    
exit

