This single scipt can distribute terminal jobs over cores and manage the maximum number of jobs that are running in parallel.

** How to run **
- Jobs are read from a text file (one job per line). 
- The maximum number of jobs to be run simultaneously needs to be specified.


** Flags **
-   -c <filename>          Text file with commands (one per line)
-   -d <directory>         Log file directory
-   -p <number of cores>   Number of processors (cores) to be used
-   -k                     Kill switch to terminate all running jobs


** Features **
- Jobs will be terminated on first error via 'bash -e'.
- Job standard output and error are recorded to a log file, one per job, that is stored in a user defined folder. Proces ID, exit status and run time are also recoreded.
- After all jobs have finished an overview report will be created in the log folder that shows the exit status and the runtime per job.
- Jobs that failed to run are printed to the terminal after para has finished to run.


** Platforms **
This script has been tested on OSX and Debian.


**EXAMPLE:**

*para -c /Volumes/Data/joblist.txt -d /Volumes/Data/Project -p 10*


**SCREENSHOT:**

![Screenshot](Screenshot.png?raw=true "Example")