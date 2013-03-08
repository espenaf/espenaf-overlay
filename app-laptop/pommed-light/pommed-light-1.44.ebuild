# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-laptop/pommed/pommed-1.39.ebuild,v 1.7 2012/09/09 16:23:29 josejx Exp $

EAPI="5"

inherit eutils toolchain-funcs linux-info

DESCRIPTION="Manage special features such as screen and keyboard backlight on Apple MacBook Pro/PowerBook"
HOMEPAGE="https://github.com/bytbox/pommed-light"
SRC_URI="https://github.com/bytbox/pommed-light/archive/v${PV}lw.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

COMMON_DEPEND="media-libs/alsa-lib
	x86? ( sys-apps/pciutils )
	amd64? (  sys-apps/pciutils )
	dev-libs/confuse
	sys-libs/zlib
	media-libs/audiofile"

DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig"
RDEPEND="${COMMON_DEPEND}
	media-sound/alsa-utils
	virtual/eject
	!app-laptop/pommed"

S="${S}lw"

pkg_setup() {
	if ! use ppc; then
		linux-info_pkg_setup

		CONFIG_CHECK="~DMIID"
		check_extra_config
	fi
}

src_install() {
	insinto /etc
	if use x86 || use amd64; then
		newins pommed.conf.mactel pommed.conf
	elif use ppc; then
		newins pommed.conf.pmac pommed.conf
	fi

	insinto /usr/share/pommed
	doins pommed/data/*.wav

	dobin pommed/pommed

	newinitd "${FILESDIR}"/pommed.rc pommed

	dodoc AUTHORS ChangeLog README.md TODO
}
