# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3
inherit eutils multilib python

DESCRIPTION="Disper-indicator is an UI for the display switch utility disper"
HOMEPAGE="https://launchpad.net/~nmellegard/"
SRC_URI="https://launchpad.net/~nmellegard/+archive/disper-indicator-ppa/+files/disper-indicator_${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="dev-lang/python
	media-video/disper"
RDEPEND="${DEPEND}"

S="${WORKDIR}"/${PN}
instdir="/usr/share/${PN}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/makefile_sed.diff
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	dodoc README
}
