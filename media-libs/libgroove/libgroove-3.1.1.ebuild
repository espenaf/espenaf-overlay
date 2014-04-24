EAPI=5

inherit base cmake-utils multilib

DESCRIPTION="Audio dispatching library. Generic sink-based interface. Provides decoding, encoding, resampling, and gain adjustment."
HOMEPAGE="https://github.com/superjoe30/libgroove"
SRC_URI="https://github.com/superjoe30/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"

RDEPEND="app-arch/bzip2
        dev-lang/yasm
        dev-util/cmake
        media-libs/libsdl2
        media-sound/lame
        sys-libs/zlib
	media-libs/chromaprint
        "

DEPEND="${RDEPEND}"

src_configure() {
        # Use internal build of libav
        local mycmakeargs=(
                "-DLIBAV_AVCODEC_LIBRARY="
                "-DLIBAV_AVFILTER_LIBRARY="
                "-DLIBAV_AVFORMAT_LIBRARY="
                "-DLIBAV_AVUTIL_LIBRARY="
		"-DEBUR128_IS_BUNDLED="
        )

        cmake-utils_src_configure
}


