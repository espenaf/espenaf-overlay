# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

MY_P="concordance-${PV}"

DESCRIPTION="Library for programming the Logitech Harmony universal remote; part
of the concordance project"
HOMEPAGE="http://www.phildev.net/concordance/"
SRC_URI="mirror://sourceforge/concordance/${MY_P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="dev-libs/libusb"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}/${PN}"

src_compile() {
	econf || die "configure failed"
	emake DESTDIR="${D}" || die "make failed"
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ../Changelog ../LICENSE README
}

