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
        ulos_serial_console=*)
            serial_console=${x#ulos_serial_console=}
        ;;
        ulos_tty_console=*)
            tty_console=${x#ulos_tty_console=}
        ;;
    esac
done

# Set console outputs
serial_console=${serial_console:-/dev/ttyS0}
tty_console=${tty_console:-/dev/tty0}


if [[ "$run_script_src" == "" ]] ; then
    echo "NO run_task specified. Nothing to do" | tee $tty_console $serial_console
    exit 0
fi

# Fail pipes
set -o pipefail

# We have here some task to run
if [[ "$run_before_src" != "" ]] ; then
    echo "Found BEFORE task ($run_before_src)" | tee $tty_console $serial_console
    
    if wget -q -O $before_task_file $run_before_src ; then
        echo "BEFORE task retrieved successfully"
        chmod +x $before_task_file
		echo "BEFORE task is executing" | tee $tty_console $serial_console
        if $before_task_file 2>&1 | tee $before_task_file.log $tty_console $serial_console ; then
            echo "[32mBEFORE task ended successfully[0m" | tee $tty_console $serial_console
        else
            echo "[31mBEFORE task failed with code $?[0m" | tee $tty_console $serial_console >&2
            echo "More information can be found in $before_task_file.log" | tee $tty_console $serial_console >&2
			echo "Content of the log:" >&2
			cat $before_task_file.log >&2
            exit 1
        fi
    else
        echo "[31mUnable to get BEFORE task from source $run_script_src[0m" | tee $tty_console $serial_console >&2
        exit 1
    fi
fi

if [[ "$run_script_src" != "" ]] ; then
    echo "Found MAIN task ($run_script_src)" | tee $tty_console $serial_console
    
    if wget -q -O $task_file $run_script_src ; then
        echo "MAIN task retrieved successfully"
        chmod +x $task_file
		echo "MAIN task is executing" | tee $tty_console $serial_console
        if $task_file 2>&1 | tee $task_file.log $tty_console $serial_console ; then
            echo "[32mMAIN task ended successfully[0m" | tee $tty_console $serial_console
        else
            echo "[31mMAIN task failed with code $?[0m" | tee $tty_console $serial_console >&2
            echo "More information can be found in $task_file.log" | tee $tty_console $serial_console >&2
			echo "Content of the log:" >&2
			cat $task_file.log >&2
            exit 1
        fi
    else
        echo "[31mUnable to get MAIN task from source[0m" | tee $tty_console $serial_console >&2
        exit 1
    fi
fi

