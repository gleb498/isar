# This software is a part of ISAR.
# Copyright (C) 2019-2020 Siemens AG
#
# This class allows to generate images for vmware and virtualbox
#

inherit buildchroot
inherit wic-img
IMAGER_BUILD_DEPS += "virtual-machine-template"
IMAGER_INSTALL += "qemu-utils gawk uuid-runtime virtual-machine-template"
export OVA_NAME ?= "${IMAGE_FULLNAME}"
export OVA_MEMORY ?= "8192"
export OVA_NUMBER_OF_CPU ?= "4"
export OVA_VRAM ?= "64"
export OVA_FIRMWARE ?= "efi"
export OVA_ACPI ?= "true"
export OVA_3D_ACCEL ?= "false"
export OVA_CLIPBOARD ?= "bidirectional"
SOURCE_IMAGE_FILE ?= "${IMAGE_FULLNAME}.wic.img"
OVA_SHA_ALG ?= "1"
VIRTUAL_MACHINE_IMAGE_TYPE ?= "vmdk"
export VIRTUAL_MACHINE_IMAGE_FILE ?= "${IMAGE_FULLNAME}-disk001.${VIRTUAL_MACHINE_IMAGE_TYPE}"
VIRTUAL_MACHINE_DISK ?= "${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE}"
# for virtualbox this needs to be monolithicSparse
# for vmware this needs to be streamOptimized
#VMDK_SUBFORMAT ?= "streamOptimized"
export VMDK_SUBFORMAT ?= "monolithicSparse"
def set_convert_options(d):
   format = d.getVar("VIRTUAL_MACHINE_IMAGE_TYPE")
   if format == "vmdk":
      return "-o subformat=%s" % d.getVar("VMDK_SUBFORMAT")
   else:
      return ""


CONVERSION_OPTIONS = "${@set_convert_options(d)}"

do_convert_wic() {
   rm -f '${DEPLOY_DIR_IMAGE}/${VIRTUAL_MACHINE_IMAGE_FILE}'
   image_do_mounts
   bbnote "Creating ${VIRTUAL_MACHINE_IMAGE_FILE} from ${WIC_IMAGE_FILE}"
   sudo -E  chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
   /usr/bin/qemu-img convert -f raw -O ${VIRTUAL_MACHINE_IMAGE_TYPE} ${CONVERSION_OPTIONS} \
       '${PP_DEPLOY}/${SOURCE_IMAGE_FILE}' '${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE}'
}

addtask convert_wic before do_build after do_wic_image do_copy_boot_files do_install_imager_deps do_transform_template

# Generate random MAC addresses just as VirtualBox does, the format is
# their assigned prefix for the first 3 bytes followed by 3 random bytes.
VBOX_MAC_PREFIX = "080027"
macgen() {
    hexdump -n3 -e "\"${VBOX_MAC_PREFIX}%06X\n\"" /dev/urandom
}
get_disksize() {
    image_do_mounts
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
        qemu-img info -f vmdk "${VIRTUAL_MACHINE_DISK}" | gawk 'match($0, /^virtual size:.*\(([0-9]+) bytes\)/, a) {print a[1]}'
}
do_create_ova() {
    if [ ! ${VIRTUAL_MACHINE_IMAGE_TYPE} = "vmdk" ]; then
        exit 0
    fi
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ova'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ovf'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.mf'
    export PRIMARY_MAC=$(macgen)
    export SECONDARY_MAC=$(macgen)
    export DISK_NAME=$(basename -s .vmdk ${VIRTUAL_MACHINE_DISK})
    export DISK_SIZE_BYTES=$(get_disksize)
    export LAST_CHANGE=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
    export OVA_FIRMWARE_VIRTUALBOX=$(echo ${OVA_FIRMWARE} | tr '[a-z]' '[A-Z]')
    image_do_mounts
    sudo -Es chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} <<'EOSUDO'
        export DISK_UUID=$(uuidgen)
        export VM_UUID=$(uuidgen)
        # create ovf
        cat /usr/share/virtual-machine-template/virtual-machine-template.ovf.tmpl | envsubst > ${PP_DEPLOY}/${OVA_NAME}.ovf
        tar -H ustar -cvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.ovf

        # virtual box needs here a manifest file vmware does not want to accept the format
        if [ "${VMDK_SUBFORMAT}" = "monolithicSparse" ]; then
            echo "SHA${OVA_SHA_ALG}(${VIRTUAL_MACHINE_IMAGE_FILE})= $(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE} | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
            echo "SHA${OVA_SHA_ALG}(${OVA_NAME}.ovf)= $(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${OVA_NAME}.ovf | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
            tar -H ustar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.mf
        fi
        tar -H ustar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${VIRTUAL_MACHINE_IMAGE_FILE}
EOSUDO
}

addtask do_create_ova after do_convert_wic before do_deploy
