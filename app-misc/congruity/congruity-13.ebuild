# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION=""
HOMEPAGE="http://sourceforge.net/projects/congruity/"
SRC_URI="mirror://sourceforge/congruity/${P}.tar.bz2"

LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="dev-libs/libconcord dev-lang/python"
RDEPEND="${DEPEND}"

src_compile() {
	sed -i "s/\/usr\/local/\/usr/g" ${S}/Makefile
}

src_install() {
	 emake DESTDIR=${D} UPDATE_DESKTOP_DB="" install || die "install failed"
}

