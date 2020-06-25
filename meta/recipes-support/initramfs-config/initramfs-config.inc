# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT
inherit dpkg-raw
inherit template
DESCRIPTION = "Recipe to set the initramfs configuration and generate a new ramfs"

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"

SRC_URI = "file://postinst.tmpl \
           file://postrm.tmpl \
           file://control.tmpl \
          "

INITRAMFS_MODULES ?= "most"
INITRAMFS_BUSYBOX ?= "auto"
INITRAMFS_COMPRESS ?= "gzip"
INITRAMFS_KEYMAP ?= "n"
INITRAMFS_NET_DEVICE ?= ""
INITRAMFS_NFSROOT ?= "auto"
INITRAMFS_RUNSIZE ?= "10%"
INITRAMFS_ROOT ?= ""
INITRAMFS_MODULE_LIST ?= ""
CREATE_NEW_INITRAMFS ?= "n"
KERNEL_PACKAGE = "${@ ("linux-image-" + d.getVar("KERNEL_NAME", True)) if d.getVar("KERNEL_NAME", True) else ""}"
DEBIAN_DEPENDS += ", ${KERNEL_PACKAGE}"
TEMPLATE_FILES = "postinst.tmpl control.tmpl postrm.tmpl"
TEMPLATE_VARS += "INITRAMFS_MODULES INITRAMFS_BUSYBOX INITRAMFS_COMPRESS \
                  INITRAMFS_KEYMAP INITRAMFS_NET_DEVICE INITRAMFS_NFSROOT \
                  INITRAMFS_RUNSIZE INITRAMFS_ROOT INITRAMFS_MODULE_LIST \
                  CREATE_NEW_INITRAMFS DEBIAN_DEPENDS PN"
