#!/bin/bash
#
## Update script for Raspbian/Armbian
#
###
# Updated on 20230123 1310PDT
###
PIKVMREPO="https://kvmnerds.com/REPO/NEW"               # known working versions location for raspbian/armbian
KVMDCACHE="/var/cache/kvmd"
PKGINFO="${KVMDCACHE}/packages.txt"
REPOFILE="/tmp/pikvmrepo.html"; /bin/rm -f $REPOFILE

get-packages() {
  printf "\n-> Getting newest Pi-KVM packages from ${PIKVMREPO}\n\n"
  mkdir -p ${KVMDCACHE}; cd ${KVMDCACHE}
  wget ${PIKVMREPO} -O ${PKGINFO} 2> /dev/null

  # Download each of the pertinent packages for Rpi4, webterm, and the main service
  for pkg in `egrep 'kvmd|ustreamer' ${PKGINFO} | grep -v sig | cut -d'>' -f3 | cut -d'"' -f2 | egrep -i "kvmd-[0-9]\.|${INSTALLED_PLATFORM}|ustreamer"`
  do
    rm -f ${KVMDCACHE}/$pkg*
    wget ${PIKVMREPO}/$pkg -O ${KVMDCACHE}/$pkg 2> /dev/null
    ls -l $pkg
  done
} # end get-packages function

save-configs() {
  printf "\n-> Saving config files\n"
  # Save passwd files used by PiKVM
  cp /etc/kvmd/htpasswd /etc/kvmd/htpasswd.save
  cp /etc/kvmd/ipmipasswd /etc/kvmd/ipmipasswd.save
  cp /etc/kvmd/vncpasswd /etc/kvmd/vncpasswd.save

  # Save webUI name and overrides
  cp /etc/kvmd/meta.yaml /etc/kvmd/meta.yaml.save
  cp /etc/kvmd/override.yaml /etc/kvmd/override.yaml.save
  cp /etc/kvmd/web.css /etc/kvmd/web.css.save

  # Save Janus configs
  #cp /etc/kvmd/janus/janus.cfg /etc/kvmd/janus/janus.cfg.save

  # Save sudoers.d/99_kvmd
  cp /etc/sudoers.d/99_kvmd /etc/sudoers.d/99_kvmd.save

  # Save mouse settings (in case you changed move freq to 10ms from 100ms)
  cp /usr/share/kvmd/web/share/js/kvm/mouse.js /usr/share/kvmd/web/share/js/kvm/mouse.js.save
} # end save-configs

restore-configs() {
  printf "\n-> Restoring config files\n"
  # Restore passwd files used by PiKVM
  cp /etc/kvmd/htpasswd.save /etc/kvmd/htpasswd
  cp /etc/kvmd/ipmipasswd.save /etc/kvmd/ipmipasswd
  cp /etc/kvmd/vncpasswd.save /etc/kvmd/vncpasswd

  # Restore webUI name and overrides
  cp /etc/kvmd/meta.yaml.save /etc/kvmd/meta.yaml
  cp /etc/kvmd/override.yaml.save /etc/kvmd/override.yaml
  cp /etc/kvmd/web.css.save /etc/kvmd/web.css

  # Restore Janus configs
  #cp /etc/kvmd/janus/janus.cfg.save /etc/kvmd/janus/janus.cfg

  # Restore sudoers.d/99_kvmd
  cp /etc/sudoers.d/99_kvmd.save /etc/sudoers.d/99_kvmd

  # Restore mouse settings (in case you changed move freq to 10ms from 100ms)
  cp /usr/share/kvmd/web/share/js/kvm/mouse.js.save /usr/share/kvmd/web/share/js/kvm/mouse.js
} # end restore-configs

set-ownership() {
  printf "\n-> Setting ownership of /etc/kvmd/*passwd files\n"
  # set proper ownership of password files
  cd /etc/kvmd
  chown kvmd:kvmd htpasswd
  chown kvmd-ipmi:kvmd-ipmi ipmipasswd
  chown kvmd-vnc:kvmd-vnc vncpasswd

  echo ; ls -l /etc/kvmd/*passwd
} # end set-ownership

perform-update() {
  printf "\n-> Perform kvmd update function\n"
  CURRENTVER=$( pikvm-info | grep kvmd-platform | awk '{print $1}' )

  # get latest released kvmd and kvmd-platform versions from REPO
  KVMDMAJOR=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'>' -f3 | cut -d'"' -f2 | grep 'kvmd-[0-9]' | cut -d'-' -f2 | cut -d'.' -f1 | uniq )
  KVMDMINOR=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'>' -f3 | cut -d'"' -f2 | grep 'kvmd-[0-9]' | cut -d'-' -f2 | sed 's/^[0-9]\.//g' | sort -nr | head -1 )
  KVMDVER="$KVMDMAJOR.$KVMDMINOR"
  KVMDFILE=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'>' -f3 | cut -d'"' -f2 | grep 'kvmd-[0-9]' | grep $KVMDVER )

  KVMDPLATFORMFILE=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'>' -f3 | cut -d'"' -f2 | grep 'kvmd-platform' | grep $INSTALLED_PLATFORM | grep $KVMDVER )

  PYTHONVER=$( /usr/bin/python3 -V | cut -d' ' -f2 | cut -d'.' -f1,2 )
  case $PYTHONVER in
    "3.7"|"3.9") PYTHON=3.9; KVMDVER=3.47 ;;
    "3.10") PYTHON=3.10 ;;
    *) echo "Unsupported python version $PYTHONVER.  Exiting"; exit 1;;
  esac

  if [[ "$CURRENTVER" == "$KVMDVER" ]]; then
    printf "\n  -> Update not required.  Version installed is ${CURRENTVER} and REPO version is ${KVMDVER}.\n"

  else
    printf "\n  -> Performing update to version [ ${KVMDVER} ] now.\n"

    # Install new version of kvmd and kvmd-platform
    printf "
    cd /
    tar xfJ $KVMDCACHE/$KVMDFILE
    tar xfJ $KVMDCACHE/$KVMDPLATFORMFILE

    rm $PYTHONPACKAGES/kvmd*egg-info
    ln -s /usr/lib/python${PYTHON}/site-packages/kvmd*egg* $PYTHONPACKAGES

    echo Updated pikvm to kvmd-platform-$INSTALLED_PLATFORM-$KVMDVER on $( date ) >> $KVMDCACHE/installed_ver.txt
    "

    cd /; tar xfJ $KVMDCACHE/$KVMDFILE 2> /dev/null
    tar xfJ $KVMDCACHE/$KVMDPLATFORMFILE 2> /dev/null
    rm $PYTHONPACKAGES/kvmd*egg-info 2> /dev/null
    ln -s /usr/lib/python${PYTHON}/site-packages/kvmd*egg* $PYTHONPACKAGES 2> /dev/null
    echo "Updated pikvm to kvmd-platform-$INSTALLED_PLATFORM-$KVMDVER on $( date )" >> $KVMDCACHE/installed_ver.txt
  fi
} # end perform-update

get-installed-platform() {
  INSTALLED_PLATFORM=$( grep platform $KVMDCACHE/installed_ver.txt | awk '{print $4}' | cut -d'-' -f3,4,5 | uniq )
  printf "\nINSTALLED_PLATFORM:  $INSTALLED_PLATFORM\n"
} #

build-ustreamer() {
  printf "\n\n-> Building ustreamer\n\n"
  # Install packages needed for building ustreamer source
  echo "apt install -y build-essential libevent-dev libjpeg-dev libbsd-dev libraspberrypi-dev libgpiod-dev"
  apt install -y build-essential libevent-dev libjpeg-dev libbsd-dev libraspberrypi-dev libgpiod-dev > /dev/null

  # Download ustreamer source and build it
  cd /tmp
  git clone --depth=1 https://github.com/pikvm/ustreamer
  cd ustreamer/

  make WITH_SYSTEMD=1 WITH_GPIO=1 WITH_SETPROCTITLE=1
  make install
  # kvmd service is looking for /usr/bin/ustreamer
  cp -f /usr/local/bin/ustreamer /usr/local/bin/ustreamer-dump /usr/bin/
} # end build-ustreamer

update-ustreamer() {
  printf "\n-> Perform ustreamer update function\n"
  INSTALLEDVER=$( ustreamer -v )
  USTREAMMINOR=$( echo $INSTALLEDVER | cut -d'.' -f2 )
  REPOMINOR=$( echo $REPOVER | cut -d'.' -f2 )
  echo
  ls -l $KVMDCACHE/ustreamer*
  echo "ustreamer version:       $INSTALLEDVER"
  echo "Repo ustreamer version:  $REPOVER"
  if [[ "$USTREAMMINOR" != "$REPOMINOR" ]]; then
    if [ $USTREAMMINOR -gt $REPOMINOR ]; then
      printf "\nInstalled version is higher than repo version.  Nothing to do.\n"
    else
      build-ustreamer
      echo "Updated ustreamer to $REPOVER on $( date )" >> $KVMDCACHE/installed_ver.txt
    fi
  fi
} # end update-ustreamer

update-logo() {
  sed -i -e 's|class="svg-gray"|class="svg-color"|g' /usr/share/kvmd/web/index.html
  sed -i -e 's|class="svg-gray" src="\.\.|class="svg-color" src="\.\.|g' /usr/share/kvmd/web/kvm/index.html

  ### download opikvm-logo.svg and then overwrite logo.svg
  wget -O /usr/share/kvmd/web/share/svg/opikvm-logo.svg https://kvmnerds.com/RPiKVM/opikvm-logo.svg > /dev/null 2> /dev/null
  cd /usr/share/kvmd/web/share/svg
  cp logo.svg logo.svg.old
  cp opikvm-logo.svg logo.svg
  cd
}

pip3-pkgs() {
  printf "\n-> Python dependencies for 2FA function\n"
  set -x
  ### pyotp and qrcode is required for 3.196 and higher (for use with 2FA)
  pip3 install pyotp qrcode
  chmod go+r /etc/kvmd/totp.secret
  chown kvmd:kvmd /etc/kvmd/totp.secret
  set +x
}

### MAIN STARTS HERE ###
REPOVER=$(ls -ltr $KVMDCACHE/ustreamer* | awk -F\/ '{print $NF}' | cut -d'-' -f2 | tail -1)
PYTHONPACKAGES=$( ls -ld /usr/lib/python3*/dist-packages | awk '{print $NF}' | tail -1 )

printf "\n-> Stopping kvmd service.\n"; systemctl stop kvmd

get-installed-platform
save-configs
get-packages
perform-update
update-ustreamer
set-ownership
restore-configs
update-logo
pip3-pkgs

### add ms unit of measure to Polling rate in webui ###
sed -i -e 's/ interval:/ interval (ms):/g' /usr/share/kvmd/web/kvm/index.html

printf "\n-> Restarting kvmd service.\n"; systemctl daemon-reload; systemctl restart kvmd
printf "\nPlease point browser to https://$(hostname) for confirmation.\n"
