#!/bin/bash
#
# This script is attended to run after boot
# It recognize several boot parameters around
# authorization and access
#

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

exitcode=0

# Parse command line options
for x in $(cat /proc/cmdline); do
    case $x in
        sshkey_src=*)
            sshkey_src=${x#sshkey_src=}
        ;;
        root_pass=*)
            root_pass=${x#root_pass=}
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

echo "ULOS: Setting up access" | tee $tty_console $serial_console

if [[ "$sshkey_src" == "" ]] && [[ "$root_pass" == "" ]]; then
    echo "NO ssh_key specified. Nothing to do"
    exit $exitcode
fi

if [[ "$root_pass" != "" ]]; then
    # Change root password to one provided in kernel boot option
    echo "Changing root password"
    echo -e "$root_pass\n$root_pass" | passwd root || { echo "Unable to change root password" >&2 ; let exitcode++ ; }
fi

if [[ "$sshkey_src" != "" ]]; then
    tmpfile=$(mktemp)

    if wget -q -O $tmpfile $sshkey_src ; then
        # Add ssh key to root
        echo "Adding sshkey to root authorized_keys"
        mkdir -p /root/.ssh
        chmod 0700 /root/.ssh
        cat $tmpfile >> /root/.ssh/authorized_keys
        # Add ssh key to debian user if existed
        if [ -d /home/debian ]; then
            echo "Adding sshkey to debian authorized_keys"
            mkdir -p /home/debian/.ssh
            chmod 0700 /home/debian/.ssh
            cat $tmpfile >> /home/debian/.ssh/authorized_keys
        fi
    else
        echo "Unable to download sshkey from $sshkey_src" >&2
        let exitcode++
        exit $exitcode
    fi
fi

exit $exitcode
