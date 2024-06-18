#!/bin/bash
# Written by @srepac (c) 2024
# This script will compile the correct libgpiod version based on python version installed
# 
function downgrade() {
  # ----------------------
  # libgpiod to run v1.6.3
  # ----------------------
  set -x
  apt install -y autoconf-archive libtool dh-autoreconf

  cd /tmp
  wget https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/snapshot/libgpiod-1.6.3.tar.gz -O libgpiod-1.6.3.tar.gz 2> /dev/null
  tar xfz libgpiod-1.6.3.tar.gz
  cd libgpiod-1.6.3

  ### this works with python3.10
  ./autogen.sh --enable-tools=yes --prefix=/usr

  make
  make install
  set +x
} # end function downgrade


function upgrade() {
  # --------------------
  # libgpiod to run v2.1
  # --------------------
  set -x
  apt install -y autoconf-archive libtool dh-autoreconf

  cd /tmp
  wget https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/snapshot/libgpiod-2.1.tar.gz -O libgpiod-2.1.tar.gz 2> /dev/null
  tar xfz libgpiod-2.1.tar.gz
  cd libgpiod-2.1

  ./autogen.sh --enable-tools=yes --enable-bindings-python=yes --prefix=/usr
  make -j$( nproc --all )
  make install
  set +x

  gpioinfo -v | head -1
} # end function upgrade 


### MAIN STARTS HERE
_PYTHONVER=$( python -V | awk '{print $NF}' )
echo "Python $_PYTHONVER"

_libgpiodver=$( gpioinfo -v | head -1 | awk '{print $NF}' )
case $_libgpiodver in
  v1.*) 
	### if python version is 3.11, then upgrade to 2.1 else leave it alone
	case $_PYTHONVER in 

	  3.1[1-9]*)  # 3.11 and higher
	    echo "Found libgpiod $_libgpiodver.  Upgrading to v2.1  Please wait..."
	    upgrade
	    ;;

	  3.10*|3.[987]*)
	    echo "Found libgpiod $_libgpiodver.  Nothing to do" 
	    ;;

	esac
	;;

  v2.*) 
  	### if python version is 3.10 or older, then downgrade to 1.6.3 else leave it at 2.1 for python 3.11
	case $_PYTHONVER in 

	  3.10*|*3.[987]*)
	    echo "Found libgpiod $_libgpiodver.  Downgrading to v1.6.3  Please wait..."
	    downgrade
	    ;;

	  3.1[1-9]*)  # 3.11 and higher
	    echo "Found libgpiod $_libgpiodver.  Nothing to do"
	    ;;

	esac
	;;

  *) 
	echo "Undefined function."; exit 1
     	;;
esac
