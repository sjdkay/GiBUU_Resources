#!/bin/bash

# Validate number input arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: RunGiBUU.sh <job_card_path> <num_runs>" >&2
    exit 1
fi

Base_Job_Card_Path="$1"
Num_Runs="$2"

# Ensure job card exists
if [ ! -f "$Base_Job_Card_Path" ]; then
    echo "Error: Job card file path '$Base_Job_Card_Path' not found." >&2
    exit 1
fi

# Ensure num_runs is a positive integer
if ! [[ "$Num_Runs" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Number of runs must be a positive integer." >&2
    exit 1
fi

# Get absolute path and filename of provided job card
Base_Job_Card_ABS_Path="$(realpath "$Base_Job_Card_Path")"
Base_Job_Card_Filename="$(basename "$Base_Job_Card_ABS_Path")"
Base_Job_Card_Basename="${Base_Job_Card_Filename%.job}" # Strip .job from end of filename

# Get directory this script is being executed from
GiBUU_Dir="$(pwd)"
# Get end of current directory, should be "testRun"
Current_Dir_Name="$(basename "$GiBUU_Dir")"

# Enforce running from testRun dir
if [ "$Current_Dir_Name" != "testRun" ]; then
    echo "Error: Script must be executed from 'testRun' directory within GiBUU install. Current directory: '$CurrentDirName'" >&2
    exit 1
fi

echo "Running ${Num_Runs} versions of $Base_Job_Card_Filename. Output will be stored in individual directories for each file under Output/"

for (( RunIndex=1; RunIndex<=Num_Runs; RunIndex++ )); do
    Output_Dir="$GiBUU_Dir/Output/${Base_Job_Card_Basename}_${RunIndex}"
    mkdir -p "$Output_Dir"
    cd "$Output_Dir"
    cp "$Base_Job_Card_ABS_Path" "$Output_Dir/$Base_Job_Card_Filename"
    Random_Seed="$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"
    sed -i -E "s/^([[:space:]]*SEED=)[0-9]+/\1${Random_Seed}/" "$Output_Dir/$Base_Job_Card_Filename"
    # Make a log file
    # Define log filename using DD_MM_YYYY date format and run number
    Current_Date="$(date +%d_%m_%Y)"
    Log_File="${Output_Dir}/${Base_Job_Card_Basename}_Run_${RunIndex}_${Current_Date}.log"
    echo "Executed on: ${Current_Date}" > $Log_File
    echo "" >> $Log_File
    echo "" >> $Log_File
    echo "SEED = ${Random_Seed}" >> $Log_File
    echo "" >> $Log_File
    echo "" >> $Log_File
    "$GiBUU_Dir/GiBUU.x" < "$Output_Dir/$Base_Job_Card_Filename" >> $Log_File 2>&1
    sleep 1
    Output_Filename="$Output_Dir/Output_${Base_Job_Card_Basename}_${RunIndex}.root"
    if [ -f "$Output_Dir/EventOutput.Pert.00000001.root" ]; then
        mv "$Output_Dir/EventOutput.Pert.00000001.root" "$Output_Filename"
    else
        echo "Warning: '$Output_Dir/EventOutput.Pert.00000001.root' not found after run $RunIndex." >&2
    fi
    # Return to starting directory for next iteration
    echo "Finished run: $RunIndex"
    cd "$GiBUU_Dir"
done

echo""
echo""
echo "Finished all $Num_Runs runs!"

exit 0
