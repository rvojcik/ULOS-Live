#!/bin/bash
#
# This script is attended to run after boot
# It recognize several boot parameters
#

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

before_task_file=/tmp/before-task.run
task_file=/tmp/task.run

# Parse command line options
for x in $(cat /proc/cmdline); do
    case $x in
        run_task=*)
            run_script_src=${x#run_task=}
        ;;
        before_task=*)
            run_before_src=${x#before_task=}
        ;;
    esac
done


if [[ "$run_script_src" == "" ]] ; then
    echo "NO run_task specified. Nothing to do"
    exit 0
fi

# We have here some task to run
if [[ "$run_before_src" != "" ]] ; then
    echo "Found BEFORE task ($run_before_src)"
    
    if wget -q -O $before_task_file $run_before_src ; then
        echo "BEFORE task retrieved successfully"
        chmod +x $before_task_file
		echo "BEFORE task is executing" | tee /dev/console
        if $before_task_file &> $before_task_file.log ; then
            echo "BEFORE task ended successfully" | tee /dev/console
        else
            echo "BEFORE task failed with code $?" | tee /dev/console >&2
            echo "More information can be found in $before_task_file.log" >&2
			echo "Content of the log:" >&2
			cat $before_task_file.log >&2
            exit 1
        fi
    else
        echo "Unable to get BEFORE task from source $run_script_src" | tee /dev/console >&2
        exit 1
    fi
fi

if [[ "$run_script_src" != "" ]] ; then
    echo "Found MAIN task"
    
    if wget -q -O $task_file $run_script_src ; then
        echo "MAIN task retrieved successfully"
        chmod +x $task_file
		echo "MAIN task is executing" | tee /dev/console
        if $task_file &> $task_file.log ; then
            echo "MAIN task ended successfully" | tee /dev/console
        else
            echo "MAIN task failed with code $?" | tee /dev/console >&2
            echo "More information can be found in $task_file.log" >&2
			echo "Content of the log:" >&2
			cat $task_file.log >&2
            exit 1
        fi
    else
        echo "Unable to get MAIN task from source" | tee /dev/console >&2
        exit 1
    fi
fi

