# This software is a part of ISAR.
#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw


SRC_URI += "file://virtual-machine-template.ovf.tmpl"

do_install() {
    TARGET=${D}/usr/share/virtual-machine-template
    install -m 0755 -d ${TARGET}
    install -m 0740 ${WORKDIR}/virtual-machine-template.ovf.tmpl \
        ${TARGET}/virtual-machine-template.ovf.tmpl
}
