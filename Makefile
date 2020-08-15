ifndef DESTDIR
override DESTDIR = .
endif

SHELL              = /bin/sh
LC_ALL             = en_US.UTF-8
debian_codename    = buster
debian_mirror      = http://ftp.cz.debian.org/debian
work_dir           = build/$(debian_codename)
install_dest       = $(DESTDIR)
system_packages    = debootstrap squashfs-tools git
env_packages       = wget curl ca-certificates locales mdadm nfs-common binutils console-setup lvm2 parted dump openssh-server openssh-client rsync openipmi sudo linux-image-amd64 initramfs-tools squashfs-tools
env_enable_units   = ulos-executor.service ulos-access.service
image_path_name    = $(DESTDIR)/debian-$(debian_codename).img
firmware_path      = linux-firmware

all: prepare_env

prepare_env: install_packages apply_src $(env_enable_units) kernel_firmware kernel remove_unwanted $(image_path_name)

$(image_path_name): remove_unwanted
	mksquashfs $(work_dir) $(image_path_name)

kernel: kernel_firmware
	$(info ***** Building initrd image for $(kernel_version) *****)
	$(eval kernel_version := $(shell chroot $(work_dir) dpkg -s linux-image-amd64 | sed -n -r 's/^Depends: linux-image-(.*)/\1/p'))
	cp -rf src/* $(work_dir)/
	chroot $(work_dir) update-initramfs -v -c -k $(kernel_version)
	cp -rf $(work_dir)/boot/initrd.img-$(kernel_version) $(install_dest)/$(destination_initrd)
	cp -rf $(work_dir)/boot/vmlinuz-$(kernel_version) $(install_dest)/$(destination_kernel)

kernel_firmware: apply_src
	cp -rfp $(firmware_path)/bnx* $(work_dir)/lib/firmware/

$(env_enable_units): install_packages
	@echo "Enable systemd unit $(@)"
	chroot $(work_dir) systemctl enable $@

remove_unwanted: apply_src
	rm -rf $(work_dir)/boot/*
	rm -rf $(work_dir)/vmlinuz*
	rm -rf $(work_dir)/initrd*
	rm -rf $(work_dir)/var/cache/apt/*
	rm -rf $(work_dir)/var/lib/apt/*
	rm -rf $(work_dir)/var/cache/debconf/*
	rm -rf $(work_dir)/usr/share/doc/*
	rm -rf $(work_dir)/usr/share/locale/*

apply_src: install_packages
	cp -rf ./src/* $(work_dir)/

install_packages: $(work_dir)
	chroot $(work_dir) apt-get update
	chroot $(work_dir) /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y $(env_packages)"
	echo "en_US.UTF-8 UTF-8" > $(work_dir)/etc/locale-gen
	chroot $(work_dir) locale-gen en_US.UTF-8 
	chroot $(work_dir) adduser --ingroup sudo --disabled-password --quiet --gecos "" debian
	chroot $(work_dir) sed -i '/^%sudo/s/ALL$$/NOPASSWD: ALL/' /etc/sudoers
	
# Deploy builded kernels
deploy: $(env_dir)/boot/initrd.img-$(kernel)
	echo "Deploying $(kernel) to $(destination)"
	cp -rfp $(env_dir)/boot/vmlinuz-$(kernel) $(destination)/$(destination_kernel)
	cp -rfp $(env_dir)/boot/initrd.img-$(kernel) $(destination)/$(destination_initrd)
	chmod +rx $(destination)/$(destination_kernel) $(destination)/$(destination_initrd)

$(work_dir): /usr/sbin/debootstrap
	mkdir -p `dirname $(work_dir)`
	debootstrap $(debian_codename) $(work_dir) $(debian_mirror)

# Install dependencies
/usr/sbin/debootstrap:
	apt-get update && apt-get install -y $(system_packages)

# Clean builded initrd
clean:
	rm -rf $(image_path_name)
	rm -rf $(install_dest)/initrd*
	rm -rf $(install_dest)/vmlinuz*

# Clean all build data
distclean: clean
	rm -rf $(work_dir)

bash:
	chroot $(work_dir) /bin/bash
