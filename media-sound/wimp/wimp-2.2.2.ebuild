# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="The Adobe Air based Streaming Client for the Telenor Wimp Service, the NO version."
HOMEPAGE="http://wimp.aspiro.com/"
SRC_URI="http://wimp.aspiro.com/wweb/resources/wimp_files/NO_35/release/Wimp-${PV}.air"
LICENSE="WiMP"
SLOT="0"
IUSE=""
KEYWORDS="x86 amd64"
DEPEND="=dev-util/adobe-air-sdk-bin-2*"

# Nothing needs to be unpacked
src_unpack() {
	echo ''
}

src_install() {
	insinto "/opt/airapps/wimp"
	doins ${DISTDIR}/Wimp-${PV}.air
	doins ${FILESDIR}/wimpIcon.png
	local exe=${PN}
	local icon=${exe}.png
	newicon "${FILESDIR}/wimpIcon.png" ${icon}
	dodir /usr/bin
	cat > "${D}/usr/bin/${exe}" <<-EOF
#!/bin/sh
/opt/bin/airstart /opt/airapps/wimp/Wimp-${PV}.air
EOF
	fperms 755 /usr/bin/${exe}
	make_desktop_entry ${exe} "WiMP" /opt/airapps/wimp/wimpIcon.png "AudioVideo;Player"
}

