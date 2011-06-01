# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/gnome2-canvas/gnome2-canvas-1.002.ebuild,v 1.13 2008/04/20 15:41:56 drac Exp $

DESCRIPTION="MythTV NUV 2 MKV converter"
#SRC_URI="http://web.aanet.com.au/~auric/files/mythnuv2mkv.sh"
HOMEPAGE="http://web.aanet.com.au/~auric/"
SLOT="0"
LICENSE="GPL-3"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND=""

src_install() {
    insinto /usr/share/mythtv/contrib/
    doins ${FILESDIR}/mythnuv2mkv.sh
}
