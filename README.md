This little scipt can distribute terminal jobs over cores and manage the maximum number of jobs that are running in parallel.

- Jobs are read from a text file (one job per line). 
- The maximum number of jobs to be run simultaneously needs to be specified.

**OPTIONS:**
   -c <filename>          Text file with commands (one per line)
   -d <directory>         Log file directory
   -p <number of cores>   Number of processors (cores) to be used

**EXAMPLE:**
/para -c /Volumes/Data/joblist.txt -d /Volumes/Data/Project -p 10/
