#!/bin/bash

# ==============================================================================
# wasta-multidesktop: wasta-multidesktop-postinst.sh
#
# This script is automatically run by the postinst configure step on
#   installation of wasta-multidesktop-setup.  It can be manually re-run, but is
#   only intended to be run at package installation.
#
# 2015-06-18 rik: initial script
# 2016-11-14 rik: enabling wasta-multidesktop systemd service
# 2017-03-18 rik: disabling wasta-logout systemd service: we now use
#   wasta-login lightdm script to record user session and retrieve it to
#   compare session to previous session and sync if any change.
# 2017-12-20 rik: adding wasta-linux theming items (previously was at the
#   wasta-core level).
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to ensure running as root
# ------------------------------------------------------------------------------
#   No fancy "double click" here because normal user should never need to run
if [ $(id -u) -ne 0 ]
then
	echo
	echo "You must run this script with sudo." >&2
	echo "Exiting...."
	sleep 5s
	exit 1
fi

# ------------------------------------------------------------------------------
# Main Processing
# ------------------------------------------------------------------------------


#WASTA_SYSTEMD=$(systemctl is-enabled wasta-logout || true);

#if [ "$WASTA_SYSTEMD" == "enabled" ];
#then
#    echo
#    echo "*** DISabling wasta-logout systemd service"
#    echo
#    # check status this way: journalctl | grep wasta-logout
#    systemctl disable wasta-logout || true
#fi

# ------------------------------------------------------------------------------
# lightdm adjustments
# ------------------------------------------------------------------------------
# NOT doing here, but if needed, change following file:
# /etc/X11/default-display-manager

# ------------------------------------------------------------------------------
# set wasta-logo as Plymouth Theme
# ------------------------------------------------------------------------------
# only do if wasta-logo not current default.plymouth
# below will return *something* if wasta-logo found in default.plymouth
#   '|| true; needed so won't return error=1 if nothing found
WASTA_PLY_THEME=$(cat /etc/alternatives/default.plymouth | \
    grep ImageDir=/usr/share/plymouth/themes/wasta-logo || true;)
# if variable is still "", then need to set default.plymouth
if [ -z "$WASTA_PLY_THEME" ];
then
    echo
    echo "*** Setting Plymouth Theme to wasta-logo"
    echo
    # add wasta-logo to default.plymouth theme list
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
        /usr/share/plymouth/themes/wasta-logo/wasta-logo.plymouth 100

    # set wasta-logo as default.plymouth
    update-alternatives --set default.plymouth \
        /usr/share/plymouth/themes/wasta-logo/wasta-logo.plymouth

    # update
    update-initramfs -u
    
    # update grub (to get rid of purple grub boot screen)
    update-grub
else
    echo
    echo "*** Plymouth Theme already set to wasta-logo.  No update needed."
    echo
fi

WASTA_PLY_TEXT=$(cat /etc/alternatives/text.plymouth | \
    grep title=Wasta-Linux || true;)
# if variable is still "", then need to set text.plymouth
if [ -z "$WASTA_PLY_TEXT" ];
then
    echo
    echo "*** Setting Plymouth TEXT Theme to wasta-text"
    echo

    # add wasta-text to text.plymouth theme list
    update-alternatives --install /usr/share/plymouth/themes/text.plymouth text.plymouth \
        /usr/share/plymouth/themes/wasta-text/wasta-text.plymouth 100

    # set wasta-text as text.plymouth
    update-alternatives --set text.plymouth \
        /usr/share/plymouth/themes/wasta-text/wasta-text.plymouth

    # update
    update-initramfs -u
else
    echo
    echo "*** Plymouth TEXT Theme already set to wasta-text.  No update needed."
    echo
fi

# ------------------------------------------------------------------------------
# Dconf / Gsettings Default Value adjustments
# ------------------------------------------------------------------------------
# Values in /usr/share/glib-2.0/schemas/z_11_wasta-multidesktop.gschema.override
#   will override Ubuntu defaults.
# Below command compiles them to be the defaults
echo
echo "*** wasta-multidesktop: updating dconf / gsettings default values"
echo

# MAIN System schemas: we have placed our override file in this directory
# Sending any "error" to null (if key not found don't want to worry user)
glib-compile-schemas /usr/share/glib-2.0/schemas/ # > /dev/null 2>&1 || true;

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Finished with wasta-multidesktop-postinst.sh"
echo

exit 0
