# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/text-wrapper/text-wrapper-1.01.ebuild,v 1.8 2008/11/18 15:53:24 tove Exp $

inherit perl-module

DESCRIPTION="mythvideo-scanner"
SRC_URI="http://mythvideo-scanner.googlecode.com/files/${PN}.${PV}.tar.gz"
HOMEPAGE="http://code.google.com/p/mythvideo-scanner/"

SLOT="0"
LICENSE="GPL-3"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

RDEPEND="dev-lang/perl"
DEPEND="dev-lang/perl
	dev-perl/Text-Levenshtein
	>=media-plugins/mythvideo-0.24"

DEST=/usr/share/${PN}

src_unpack() {
	unpack ${A}
	cd "${S}"
        epatch ${FILESDIR}/blacklist_bdmn.patch
}

src_install() {
	cd ${WORKDIR}/${PN}
	dobin mythvideo-scanner.pl mythvideo-cleaner.pl mythvideo-prune.pl
	dodir ${DEST}/grabbers ${DEST}/modules
	insinto ${DEST}/grabbers
	doins grabbers/*
	insinto ${DEST}/modules
	doins modules/*
        dodoc README
}
