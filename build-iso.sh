#!/bin/bash
#
# Info: Build RHV-H ISO after modifications are made
# Author: Jason Woods <jwoods@redhat.com>, Steffen Froemer <steffen@redhat.com>
# Created: 2018-12-14
# Updated: 2021-07-23
# This script has no warranty implied or otherwise.
#
# 2021-07-23  sfroemer  added prep- and usage-function, cleanup
# 2021-07-19  sfroemer  updated iso_name function to properly grab LABEL
# 2019-02-11  jwoods    added function update_efiboot and call to it
# 2019-02-12  jwoods    added function update_from_mods if ISO_MODDIR exists
# 2019-02-14  jwoods    changed variables to start with ISO_
# 2019-02-14  jwoods    added code to read $0.rc file, remove .sh in .rc file name

# Path to working directory
ISO_BASEDIR="/tmp/RHVH-custom"
# filename of created RHV-H custom image
ISO_OUT="RHVH-4.4-custom.x86_64.iso"

# Path to the downloaded RHVH image from access.redhat.com (optional)
# If not configured, the path can be transmitted during preparation process
ISO_IN=""

# these can be left auto-configured, or changed as desired
ISO_SOURCEDIR="${ISO_BASEDIR}/SOURCE"
ISO_BUILDDIR="${ISO_BASEDIR}/BUILD"
ISO_MNTDIR="${ISO_BASEDIR}/temp-mnt"
ISO_MODDIR="${ISO_BASEDIR}/modifications"
ISO_OUTFILE="${ISO_BASEDIR}/${ISO_OUT}"

# string to use when outputting a note
ISO_NOTE="#-# "

# if exists and is readable, source .rc file for variables
ISO_RCFILE="$(echo "$0" | sed 's/\.sh$//;').rc"

# name of this program
ISO_PROGNAME="$(basename "${0}")"



function iso_name () {
  # this needs work
  grep "LABEL=" "${ISO_BUILDDIR}/isolinux/isolinux.cfg" | head -n1 | \
    sed -e 's/^.*:LABEL=\(.*\):.*$/\1/;s/\\x20/ /'
}

function update_from_mods () {
  echo "${ISO_NOTE}Updating ISO files from '${ISO_MODDIR}'..."
  pushd "${ISO_MODDIR}" >/dev/null || {
    echo "  ERROR: unable to change to '${ISO_MODDIR}'"
    return
  }
  find . -type f -exec cp -v "{}" "${ISO_BUILDDIR}/{}" \;
  popd >/dev/null
}

function update_efiboot () {
  echo "${ISO_NOTE}Updating EFIBOOT image ..."
  [ ! -d "${ISO_MNTDIR}" ] && mkdir -p "${ISO_MNTDIR}"
  mount "${ISO_BUILDDIR}/images/efiboot.img" "${ISO_MNTDIR}" && {
   cp "${ISO_BUILDDIR}/EFI/BOOT/grub.cfg" "${ISO_MNTDIR}/EFI/BOOT/grub.cfg"
  } || {
    echo "  ERROR: unable to mount efiboot.img"
  }
  sleep 1
  umount "${ISO_MNTDIR}" && echo "  SUCCESS"
}

function iso_build () {
  # build ISO from files
  ISO_NAME="$(iso_name)"
  cd "${ISO_BASEDIR}"
  # update ISO files from modifications directory files
  update_from_mods
  # update efiboot image, redirect any errors to stdout
  update_efiboot
  echo "${ISO_NOTE}Generating ISO image ..."
  genisoimage \
    -follow-links \
    -o "${ISO_OUTFILE}" -joliet-long -b "isolinux/isolinux.bin" \
    -c "isolinux/boot.cat" -no-emul-boot -boot-load-size 4 \
    -boot-info-table -eltorito-alt-boot \
    -e "images/efiboot.img" -no-emul-boot -R -J -v -T \
    -input-charset utf-8 \
    -V "${ISO_NAME}" -A "${ISO_NAME}" \
    "${ISO_BUILDDIR}"
  if [ $? = 0 ] ; then
    echo "${ISO_NOTE}Making ISO UEFI bootable ..."
    isohybrid -uefi "${ISO_OUTFILE}"
    echo "  EXIT: $?"
    echo "${ISO_NOTE}Adding MD5 to ISO ..."
    implantisomd5 "${ISO_OUTFILE}"
    echo "  EXIT: $?"
  else
    echo
    echo "  ERROR: failed to build ISO."
    echo
  fi
}

function iso_prep () {
  # prep files for building ISO
  echo "${ISO_NOTE}Setup prerequisites to customize ISO"
  echo "${ISO_NOTE}Mounting and copying content from  RHV-H ISO to source directory"
  [ ! -d "${ISO_MNTDIR}" ] && mkdir -p ${ISO_MNTDIR}
  [ ! -d "${ISO_BUILDDIR}" ] && mkdir -p ${ISO_BUILDDIR}
  [ ! -d "${ISO_MODDIR}" ] && mkdir -p ${ISO_MODDIR}
  [ -z "${ISO_IN}" ] && {
    echo "  ERROR: Please provide path to RHV-H image."
    exit 1
  }
  mount ${ISO_IN} ${ISO_MNTDIR} >/dev/null 2>&1 && {
    cp -avr ${ISO_MNTDIR}/* ${ISO_BUILDDIR}/
  } || {
    echo "  ERROR: unable to mount ${ISO_IN}"
    exit 1
  }
  umount "${ISO_MNTDIR}" && echo "  SUCCESS"
}

function usage () {
  # print small usage documentation
  echo "This script must be run with super-user privileges." 
  echo "Usage: ${ISO_PROGNAME} [-bh] [-p rhv.iso]" 
  echo "  -b         build RHV-H custom ISO"
  echo "  -h         display help"
  echo "  -p rhv.iso prepare the environment to customize ISO"
  echo "             before building"
  exit 1
}

function main () {
  # report if using a .rc file
  if [ -r "${ISO_RCFILE}" ] ; then
    echo "${ISO_NOTE}Used ISO_RCFILE='${ISO_RCFILE}'"
    source "${ISO_RCFILE}"
  fi

  case "$(echo "${1}" | sed 's/^-*//;')" in
  prep|PREP|p|P)
    # default to prep ISO build files
    [[ -n "${2}" ]] && ISO_IN="$(dirname $2)/$(basename $2)"
    iso_prep
    ;;
  build|BUILD|b|B)
    # default to build ISO
    iso_build
    ;;
  h|help|*)
    # call help function
    usage
    ;;
  esac
}

main $@ 2>&1 | tee build.out