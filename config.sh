export VER=3.5;
export PIKVMREPO="https://files.pikvm.org/repos/arch/rpi4"
export KVMDFILE="kvmd-4.46-1-any.pkg.tar.xz" # Last version to support Python 3.12
export KVMDCACHE="/var/cache/kvmd"
export PKGINFO="${KVMDCACHE}/packages.txt"
export APP_PATH=$(readlink -f $(dirname $0))
export LOGFILE="${KVMDCACHE}/installer.log"; 
export FALLBACK_VER=4.46