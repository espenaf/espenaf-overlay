# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit webapp depend.php

DESCRIPTION="Web-based storage application where all your data is under your own control"
HOMEPAGE="http://owncloud.org"
SRC_URI="http://owncloud.org/releases/${P}.tar.bz2"

LICENSE="AGPL-3"
KEYWORDS="~amd64 ~x86"
IUSE="curl sqlite mysql"
RDEPEND="dev-lang/php[json,xmlwriter,zip,sqlite?,curl?,mysql?]"

need_httpd_cgi
need_php_httpd

S="${WORKDIR}/${PN}"
DOCFILES="README COPYING-README"

pkg_setup() {
	webapp_pkg_setup

	local php_flags="json xmlwriter zip $(usev curl) $(usev sqlite)"

	if ! PHPCHECKNODIE="yes" require_php_with_use ${php_flags} || \
			! PHPCHECKNODIE="yes" require_php_with_any_use "mysql sqlite" ; then
		die "Re-install ${PHP_PKG} with ${php_flags} and either mysql or sqlite"
	fi
}

src_install() {
	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"
	doins -r {*,.*}
	dodir "${MY_HTDOCSDIR}"/data
	webapp_serverowned "${MY_HTDOCSDIR}"/data
	webapp_serverowned "${MY_HTDOCSDIR}"/config
	webapp_configfile "${MY_HTDOCSDIR}"/.htaccess

	webapp_src_install
}

