# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header:

inherit eutils

IUSE="fullheaders"

DESCRIPTION="Minimal SMTP client"
HOMEPAGE="http://www.engelschall.com/sw/smtpclient/"
SRC_URI="mirror://gentoo/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

#DEPEND="virtual/glibc"

src_unpack() {
        unpack ${A}

        cd ${S}

        use fullheaders && epatch ${FILESDIR}/fullheaders.patch

}

src_compile() {

        econf || die "configure failed"

        emake || die "parallel make failed"

}

src_install () {

        dobin smtpclient

        doman smtpclient.1

}


