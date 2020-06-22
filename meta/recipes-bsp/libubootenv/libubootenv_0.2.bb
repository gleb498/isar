# Copyright (c) 2019 Siemens AG
# Licensed under the Siemens Inner Source License, see LICENSE

DESCRIPTION = "swupdate utility for software updates"
HOMEPAGE= "https://github.com/sbabic/swupdate"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
SRC_URI = "gitsm://github.com/sbabic/libubootenv.git;branch=master;protocol=https"

SRCREV = "bf6ff631c0e38cede67268ceb8bf1383b5f8848e"

BUILD_DEB_DEPENDS = "cmake, zlib1g-dev"

SRC_URI += "file://debian"
TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "BUILD_DEB_DEPENDS DEFCONFIG DEBIAN_DEPENDS"


inherit dpkg

S = "${WORKDIR}/git"

do_prepare_build() {
        DEBDIR=${S}/debian
        install -d ${DEBDIR}
        cp -R ${WORKDIR}/debian ${S}
        deb_add_changelog
}
