#
# Create an image that can by written onto a SD card using dd.
#
# External variables needed:
#   ${ROOTFS} - the rootfs image to incorporate

inherit image

# Add the fstypes we need
IMAGE_FSTYPES += "sdimg"

# Ensure required utilities are present
IMAGE_DEPENDS_sdimg = "dosfstools-native mtools-native parted-native"

# Default to 3.4GiB images
SDIMG_SIZE ?= "3400"

# Boot partition volume id
BOOTDD_VOLUME_ID_beaglebone = "BEAGLE_BONE"
BOOTDD_VOLUME_ID ?= "${MACHINE}"

# Addional space for boot partition
BOOTDD_EXTRA_SPACE ?= "16384"

# Files and/or directories to be copied into the vfat partition
FATPAYLOAD ?= ""

IMAGE_CMD_sdimg () {
	TMP=${WORKDIR}/tmp
	SDIMG=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.sdimg

	# Prepare boot filesystem
	install -d $TMP/boot

	echo "Copying bootloaders into the boot partition"
	if [ -e ${IMAGE_ROOTFS}/boot/MLO ] ; then
		cp -v ${IMAGE_ROOTFS}/boot/MLO $TMP/boot
	else
		cp -v ${DEPLOY_DIR_IMAGE}/MLO $TMP/boot
	fi

	# Check for u-boot SPL
	if [ -e ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.img ] ; then
		suffix=img
	else
		suffix=bin
	fi

	if [ -e ${IMAGE_ROOTFS}/boot/u-boot.$suffix ] ; then
		cp -v ${IMAGE_ROOTFS}/boot/u-boot.$suffix $TMP/boot || true
	else
		cp -v ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.$suffix $TMP/boot/u-boot.$suffix
	fi

	if [ -e ${IMAGE_ROOTFS}/boot/uImage ]; then
		cp -v ${IMAGE_ROOTFS}/boot/uImage $TMP/boot || true
	else
		cp -v ${DEPLOY_DIR_IMAGE}/uImage-${MACHINE}.bin $TMP/boot/uImage
	fi

	cp -v ${IMAGE_ROOTFS}/boot/uEnv.txt $TMP/boot || true
	cp -v ${IMAGE_ROOTFS}/boot/user.txt $TMP/boot || true

	# Copy ubi used by flashing scripts
	if [ -e  ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubi ] ; then
		echo "Copying UBIFS image to file system"
		cp ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubi ${IMAGE_ROOTFS}/boot/fs.ubi
	fi

	if [ -n ${FATPAYLOAD} ] ; then
		echo "Copying payload into VFAT"
		for entry in ${FATPAYLOAD} ; do
				# add the || true to stop aborting on vfat issues like not supporting .~lock files
				cp -av ${IMAGE_ROOTFS}$entry $TMP/boot || true
		done
	fi

	dd if=/dev/zero of=${SDIMG} bs=$(expr 1000 \* 1000) count=${SDIMG_SIZE}

	# Create the boot filesystem
	BOOT_OFFSET=32256
	BOOT_BLOCKS=$(du --apparent-size -ks $TMP/boot | cut -f 1)
	BOOT_SIZE=$(expr $BOOT_BLOCKS + ${BOOTDD_EXTRA_SPACE})
	mkfs.vfat -n ${BOOTDD_VOLUME_ID} -S 512 -C $TMP/boot.img $BOOT_SIZE
	mcopy -i $TMP/boot.img -s $TMP/boot/* ::/

	# Create partition table
	END1=$(expr $BOOT_SIZE \* 1024)
	END2=$(expr $END1 + 512)
	parted -s ${SDIMG} mklabel msdos
	parted -s ${SDIMG} mkpart primary fat16 ${BOOT_OFFSET}B ${END1}B
	parted -s ${SDIMG} mkpart primary ext3 ${END2}B 100%
	parted -s ${SDIMG} set 1 boot on
	parted ${SDIMG} print

	OFFSET1=$(expr $BOOT_OFFSET / 512)
	OFFSET2=$(expr $END2 / 512)
	dd if=$TMP/boot.img of=${SDIMG} conv=notrunc seek=$OFFSET1 bs=512
	dd if=${ROOTFS} of=${SDIMG} conv=notrunc seek=$OFFSET2 bs=512

	cd ${DEPLOY_DIR_IMAGE}
	ln -sf ${IMAGE_NAME}.sdimg ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.sdimg
}
