# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header:

EAPI="5"
inherit eutils python

DESCRIPTION="fwbackups is a feature-rich user backup program"
HOMEPAGE="http://www.diffingo.com/oss/fwbackups"
SRC_URI="http://downloads.diffingo.com/${PN}/${PN}-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND="virtual/cron
	dev-lang/python:2.7
	dev-python/pycrypto
	dev-python/paramiko
	dev-python/pygtk
	dev-python/notify-python"

pkg_setup() {
    python_set_active_version 2
    python_pkg_setup
}

src_prepare() {
    python_convert_shebangs -r 2 .
}

