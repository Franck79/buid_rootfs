##################################################
#                                                #
#           Small initramfs builder              #
#                                                #
##################################################

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.

#CROSS_COMPILE="/opt/nios_gcc/bin/nios2-linux-gnu-"
#ARCH=nios2

ifeq ($(V), 1)
Q=
QUIET=
else
Q ?=@
QUIET=-quiet
endif

all: clean build install

build:

	$(Q) echo
	$(Q) echo -e "\033[32m ***** Compiling busybox *****\033[0m"
	$(Q) echo

	$(Q) rm -f ./busybox/.config
	$(Q) sed -r "s#CONFIG_CROSS_COMPILER_PREFIX=#CONFIG_CROSS_COMPILER_PREFIX=\"${CROSS_COMPILE}\"#" <./busybox/config_nios> ./busybox/.config
	$(Q) make -C ./busybox ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE}
	$(Q) make -C ./busybox install

	$(Q) cp -Rfa _busybox/* _install/

	$(Q) echo
	$(Q) echo -e "\033[32m ***** Creating rootfs *****\033[0m"
	$(Q) echo

	$(Q) mkdir -p _install/dev
	$(Q) mkdir -p _install/sys
	$(Q) mkdir -p _install/lib
	$(Q) mkdir -p _install/etc
	$(Q) mkdir -p _install/var
	$(Q) mkdir -p _install/proc
	$(Q) mkdir -p _install/usr
	$(Q) mkdir -p _install/bin
	$(Q) mkdir -p _install/etc/init.d
	$(Q) mkdir -p _install/etc/rc.d
	$(Q) mkdir -p _install/tmp
	$(Q) chmod -f 776 _install/tmp
	$(Q) chmod -f o+t _install/tmp

	$(Q) mkdir -p _install/root
	$(Q) chmod -f 700 _install/root

# Device nodes creation
	$(Q) sudo mknod -m 600 _install/dev/console c 5 1
	$(Q) sudo mknod -m 666 _install/dev/null c 1 3
	$(Q) sudo mknod -m 600 _install/dev/systty c 4 0
	$(Q) sudo mknod -m 600 _install/dev/tty1 c 4 1
	$(Q) sudo mknod -m 600 _install/dev/tty2 c 4 2
	$(Q) sudo mknod -m 600 _install/dev/tty3 c 4 3
	$(Q) sudo mknod -m 600 _install/dev/tty4 c 4 4
	$(Q) sudo mknod -m 600 _install/dev/ram b 1 1

# Busybox sticky bit
	$(Q) sudo chmod -f u+s _install/bin/busybox

	$(Q) mkdir -p _install/etc/init.d
	$(Q) mkdir -p _install/etc/rc.d

#cp -Rfa _fs/etc/inittab _install/etc/inittab
	$(Q) cp -Rfa _fs/etc/* _install/etc/
	$(Q) cp -Rfa _fs/bin/* _install/bin/
	$(Q) cp -Rfa _fs/lib/* _install/lib/

# Ajout du script /init
	$(Q) ln -s bin/busybox _install/init

	$(Q) sudo chown root:root -Rf _install/*

install:
	$(Q) (cd _install && sudo find . | sudo cpio -H newc -o > /tmp/initramfs.cpio)
	$(Q) echo
	$(Q) echo -e "\033[32m ***** Finished *****\033[0m"
	$(Q) echo
	$(Q) echo
	$(Q) echo -e "\033[34m --> initramfs in /tmp/initramfs.cpio\033[0m"
	$(Q) echo
clean:
	$(Q) sudo rm -Rf _install/*
	$(Q) sudo rm -Rf _busybox/*
	$(Q) rm -f /tmp/initramfs.cpio

distclean: clean
	$(Q) make -C ./busybox clean
