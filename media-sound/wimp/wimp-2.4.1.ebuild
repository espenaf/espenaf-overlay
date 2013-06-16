# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

MY_P="Wimp-${PV}.air"
DESCRIPTION="The Adobe Air based Streaming Client for the Telenor Wimp Service, the NO version."
HOMEPAGE="http://wimp.aspiro.com/"
SRC_URI="http://wimp.aspiro.com/wweb/resources/wimp_files/NO_35/release/$MY_P"
LICENSE="WiMP"
SLOT="0"
IUSE=""
KEYWORDS="x86 amd64"
DEPEND="=dev-util/adobe-air-sdk-bin-2.6"

src_unpack() {
	unzip -q "${DISTDIR}/$MY_P"
}

src_install() {
	sed -i 's/application\/3.5/application\/2.6/g' META-INF/AIR/application.xml
	insinto "/opt/airapps/wimp"
	doins -r *
	local exe=${PN}
	local icon=${exe}.png
	newicon "${WORKDIR}/wimpIcon.png" ${icon}
	dodir /usr/bin
	cat > "${D}/usr/bin/${exe}" <<-EOF
#!/bin/sh
/opt/bin/adl -nodebug /opt/airapps/wimp/META-INF/AIR/application.xml /opt/airapps/wimp/
EOF
	fperms 755 /usr/bin/${exe}
	make_desktop_entry ${exe} "WiMP" /opt/airapps/wimp/wimpIcon.png "AudioVideo;Player"
}

