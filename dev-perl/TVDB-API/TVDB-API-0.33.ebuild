# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/text-wrapper/text-wrapper-1.01.ebuild,v 1.8 2008/11/18 15:53:24 tove Exp $

inherit perl-module

MY_P=TVDB-API-${PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="The Perl TVDB::API Module"
SRC_URI="mirror://cpan/authors/id/B/BE/BEHANW/${MY_P}.tar.gz"
HOMEPAGE="http://search.cpan.org/~behanw/"

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

RDEPEND="dev-lang/perl"
DEPEND="dev-perl/Debug-Simple
dev-perl/DBM-Deep
virtual/perl-Module-Build"
