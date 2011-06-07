# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"
inherit eutils multilib python

MY_PN="libmtdev"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Disper is an on-the-fly display switch utility"
HOMEPAGE="http://willem.engen.nl/projects/disper/"
SRC_URI="http://bitmath.org/code/mtdev/mtdev-${PV}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}"/mtdev-${PV}

src_configure() {
	cd $S
        econf
}

src_install() {
        emake DESTDIR="${D}" install || die "Install failed"
#        doman ${PN}.1
#        dodoc README TODO
}

