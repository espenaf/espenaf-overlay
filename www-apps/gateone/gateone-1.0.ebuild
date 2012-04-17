# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=3
inherit distutils python

PYTHON_DEPEND="2:2.6"
S="${WORKDIR}/GateOne"

DESCRIPTION="HTML5-powered terminal emulator and SSH client"
SRC_URI="https://github.com/downloads/liftoff/GateOne/${PN}-${PV}.tar.gz"
HOMEPAGE="https://github.com/liftoff/GateOne"
SLOT="0"

KEYWORDS="~amd64 ~x86"
LICENSE="AGPL-3"
IUSE=""
DEPEND="dev-lang/python
	>=www-servers/tornado-2.2"
RDEPEND="${DEPEND}"


src_install() {
        distutils_src_install
        doinitd ${FILESDIR}/gateone
        doconfd ${FILESDIR}/conf/gateone
}
