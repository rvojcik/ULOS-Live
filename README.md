# ULOS-Live
Universal Live(sport) Operating System - ULOS. Live netboot OS based on Linux Debian.

Small OS which can boot from PXE (netboot) and do some automated tasks. Tasks can be passed to os via Kernel CMDLINE.
OS boots from network, download tasks / scripts and execute them via SystemD Unit.

Root password or SSH keys can be also provided via CMDLINE during boot.

# Why ?
Originaly we developed this for deploying servers to production environment in Livesport. We learn a lot from it. 
You can use it with Foreman to deploy your images. Now it's used for various maintenance tasks or tests for HW or Virtualization. 

It can be also used for disk-less systems to provide dynamic live infrastructure which can change in a minute.

# It's Free and Open
Used as you wish, for learning or for your tasks. We publish it under GPL v3.

# Contribution
If you have any interesting idea how to extend the functionality of it, we are accepting pull requests 

# Examples
Working examples can be found in examples directory




