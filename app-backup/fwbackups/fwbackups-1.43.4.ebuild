# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header:

inherit eutils

DESCRIPTION="fwbackups is a feature-rich user backup program"
HOMEPAGE="http://www.diffingo.com/oss/fwbackups"
SRC_URI="http://downloads.diffingo.com/${PN}/${PN}-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPEND="virtual/cron
	dev-lang/python
	dev-python/pycrypto
	dev-python/paramiko
	dev-python/pygtk
	dev-python/notify-python"

src_compile() {
        econf || die "configure failed"
        emake || die "make failed"
}

src_install () {
	emake DESTDIR="${D}" install || die "install failed"
}


