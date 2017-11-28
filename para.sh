#!/bin/bash

# Vincent Koppelmans
# 2017-11-28
# PARA v2.0

# Argument = -h help -c command_list -p active_processors

usage()
{
cat << EOF
$(tput setaf 4)$(tput bold)
- This script runs jobs in parallel on a multi-core machine. 
- Jobs are read from a text file (one job per line). 
- The maximum number of consecutive jobs to be run needs to be specified.$(tput sgr0)

OPTIONS:
   $(tput setaf 5)-h$(tput sgr0)                     Show this ($(tput setaf 5)$(tput bold)h$(tput sgr0))elp menu
   $(tput setaf 5)-c <filename>$(tput sgr0)          Text file with ($(tput setaf 5)$(tput bold)c$(tput sgr0))ommands (one per line)
   $(tput setaf 5)-d <directory>$(tput sgr0)         Log file ($(tput setaf 5)$(tput bold)d$(tput sgr0))irectory
   $(tput setaf 5)-p <number of cores>$(tput sgr0)   Number of ($(tput setaf 5)$(tput bold)p$(tput sgr0))rocessors (cores) to be used

EXAMPLE:
$(tput setaf 3)$(tput bold)para -c /Volumes/Data/joblist.txt -d /Volumes/Data/Project -p 10$(tput sgr0)

EOF
}

FILE=
PROCESSOR=
while getopts “hc:p:d:f” OPTION
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
         ?)
             usage
             exit
             ;;
     esac
done

# Check if all arguments have been specified
if [[ -z "${FILE}" ]] || [[ -z "${PROCESSOR}" ]] || [[ -z "${DIRECTORY}" ]]
then
     usage
     exit 1
fi


# Go to script folder and create log file folder
cd ${DIRECTORY}
mkdir -p ${DIRECTORY}/para_output

# Count number of jobs and set first job to number 0
NJOBS=$(awk 'NF' ${FILE} | wc -l | sed 's/\ //g')
JOB_NUM=0

# Announce the start of the batch with date
echo $'\n\n'$(tput sgr0)$(tput bold)"Start batch at `date`"$(tput sgr0)


# Loop over all jobs
while read command; do

    # Test how many jobs there are running in the background of the current shell
    # If this is greater or equal then the number specified by the user,
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
    # >>> RUN COMMAND >>> PUT IN BACKGROUND >>> REDIRECT STD ERROR+OUTPUT TO LOG
    bash -c "${command}" >> ${LOG} 2>&1 &
    # Print the proces ID to the log file
    echo "PID=$!" >> ${LOG}

done < <(awk 'NF' "${FILE}")


# Wait until all jobs (background processes) have finished
wait

# Announce that all jobs have finished
echo $(tput bold)"All jobs finished on `date`"$(tput sgr0)$'\n\n'

exit

