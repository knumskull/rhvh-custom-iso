
# Building a Custom Boot ISO for Red Hat Virtualization Hypervisor
This repo provides a script to automate the customization and build process of a custom RHV-H ISO.
The work is based on the [Blog Article - Building a Custom Boot ISO for Red Hat Virtualization Hypervisor](https://www.redhat.com/en/blog/building-custom-boot-iso-red-hat-virtualization-hypervisor) by [Marc Skinner](https://www.redhat.com/en/authors/marc-skinner)


# Using the script
The script has a builtin __usage__ function, which shows the basic usage of that script.
Note the script should be executed with super-user privileges.

~~~
$ ./build-iso.sh -h
This script must be run with super-user privileges.
Usage: build-iso.sh [-bh] [-p rhv.iso]
  -b         build RHV-H custom ISO
  -h         display help
  -p rhv.iso prepare the environment to customize ISO
             before building
~~~

## Prerequisites

### Install all required packages
Please make sure, you have pre-installed the following packages on your build-system.
* `syslinux` - Simple kernel loader which boots from a FAT filesystem
* `isomd5sum` - Utilities for working with md5sum implanted in ISO images
* `genisoimage` - Creates an image of an ISO9660 file-system


### Download the RHV-H image from Red Hat
The images can be downloaded from [access.redhat.com](https://access.redhat.com/products/red-hat-virtualization#getstarted)

### Setup variables
* configure the `build-iso.rc` file to setup necessary variables

~~~
# Path to working directory
ISO_BASEDIR="/tmp/RHVH-custom"
# filename of created RHV-H custom image
ISO_OUT="RHVH-4.4-custom.x86_64.iso"
~~~

## Start the preparation process
This process will Copy the content from RHV image into a working directory, which will be used for modifications and build.

~~~
$ sudo ./build-iso.sh -p ~/Downloads/RHVH-4.4-20201117.0-RHVH-x86_64-dvd1.iso
~~~

## Perform your customization
All file in `modification` directory will be included into the image.

To customize the `ks.cfg` it needs to be copied to `modifications`-directory.

~~~
$ cp ks.cfg /tmp/RHVH-custom/modifications
~~~

## Run the build process
To start the build process, execute the following command.

~~~
# sudo ./build-iso.sh BUILD
~~~

This will create the ISO in the directory `ISO_BASEDIR` you've configured in `build-iso.rc`

# Disclaimer
There is no warranty on success by using these scripts. You will use these scripts on your own risk.