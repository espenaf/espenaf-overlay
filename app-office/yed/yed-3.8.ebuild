EAPI="2"

inherit eutils java-pkg-2

DESCRIPTION="Diagram editor written in Java"
HOMEPAGE="www.yworks.com/products/yed/"
SRC_URI="http://www.yworks.com/products/yed/demo/yEd-${PV}.zip"

LICENSE="yed"
SLOT="0"
KEYWORDS="~x86 ~sparc ~ppc amd64 ppc64"
IUSE=""

RDEPEND=">=virtual/jre-1.6
        ${COMMON_DEP}"

DEPEND=">=virtual/jdk-1.6
        ${COMMON_DEP}"

S=${WORKDIR}/${P}

src_install() {
        cd "${S}"
	java-pkg_dojar ${PN}.jar

	java-pkg_dolauncher ${PN} --jar ${PN}.jar\
		-into "/usr"
}

