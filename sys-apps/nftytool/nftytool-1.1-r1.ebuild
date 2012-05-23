# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header:

inherit eutils

DESCRIPTION="Infinity USB and Infinity USB Phoenix tool"
HOMEPAGE="http://www.infinityusb.com/"
#Original source, using instead pmcenery ppa which fixes build issues
#SRC_URI="http://www.wbe.se/files/nftytool-1.1.tar.gz"
SRC_URI="https://launchpad.net/~pmcenery/+archive/ppa/+files/nftytool_1.1%7Edfsg.orig.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPENDS="virtual/libusb"
S=${WORKDIR}/nftytool-1.1~dfsg.orig

src_unpack() {
        unpack ${A}

        cd ${S}

        epatch ${FILESDIR}/001-fpic.patch
        epatch ${FILESDIR}/002-paths.patch
}

src_install() {
	dobin nftytool
	dodir /etc/nftytool
	insinto /etc/nftytool
	doins nftytool.conf
	dodir /usr/share/nftytool/plugins
	insinto /usr/share/nftytool/plugins
	doins plugins/*.so
	insinto /etc/udev/rules.d
	doins ${FILESDIR}/99-nftytool.rules
        dodoc README TODO INSTALL
}
