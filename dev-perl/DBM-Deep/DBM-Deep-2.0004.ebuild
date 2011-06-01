# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/text-wrapper/text-wrapper-1.01.ebuild,v 1.8 2008/11/18 15:53:24 tove Exp $

inherit perl-module

MY_P=DBM-Deep-${PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="The Perl DBM::Deep Module"
SRC_URI="mirror://cpan/authors/id/S/SP/SPROUT/${MY_P}.tar.gz"
HOMEPAGE="http://search.cpan.org/~sprout/"

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

RDEPEND="dev-lang/perl"
DEPEND=">=dev-perl/Test-Exception-0.27
>=dev-perl/IO-stringy-2.110
dev-perl/Test-Warn
dev-perl/Test-Deep
virtual/perl-Module-Build"


