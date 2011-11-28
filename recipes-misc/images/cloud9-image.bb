# Image with cloud9 ide and hw tools installed

require ti-hw-bringup-image.bb

FATPAYLOAD = "${datadir}/beaglebone-getting-started/*"

IMAGE_INSTALL += " \
	cloud9 \
	task-sdk-target \
	vim vim-vimrc \
	procps \
	beaglebone-tester \
	screen minicom \
	git \
	beaglebone-getting-started bonescript \
	led-config \
	opencv-dev \
	cronie-systemd ntpdate \
	nano \
	minicom \
	hicolor-icon-theme \
	gateone \
	tar \
	gdb gdbserver \
	nodejs-dev \
"

ROOTFS_beaglebone = "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext4"
IMAGE_FSTYPES_beaglebone= "ext4"

export IMAGE_BASENAME = "Cloud9-IDE"
