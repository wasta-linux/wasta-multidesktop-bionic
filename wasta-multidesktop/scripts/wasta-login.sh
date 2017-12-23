#!/bin/bash

# ==============================================================================
# Wasta-Linux Login Script
#
#   This script is intended to run at login from lightdm.  It makes desktop
#       environment specific adjustments (for Cinnamon / XFCE / Gnome-Shell
#       compatiblity)
#
#   NOTES:
#       - wmctrl needed to check if cinnamon running, because env variables
#           $GDMSESSION, $DESKTOP_SESSION not set when this script run by the
#           'session-setup-script' trigger in /etc/lightdm/lightdm.conf.d/* files
#       - logname is not set, but $CURR_USER does match current logged in user when
#           this script is executed by the 'session-setup-script' trigger in
#           /etc/lightdm/lightdm.conf.d/* files
#       - Appending '|| true;' to end of each call, because don't want to return
#           error if item not found (in case some items uninstalled).  the 'true'
#           will always return 0 from these commands.
#
#   2015-02-20 rik: initial script for 14.04
#   2015-06-18 rik: adding xfce processing
#   2015-06-29 rik: adding pavucontrol for xfce only
#   2015-08-04 rik: correcting "NoDisplay" to "Hidden" for autostart items
#       for xfce login
#   2016-02-21 rik: modifying for 16.04 with Ubuntu Unity base
#   2016-03-09 rik: adding nemo/nautilus defaults.list toggling
#   2016-03-16 rik: wasta-logout.sh now sets defaults to nautilus each time,
#       adjusting processing based on this. (setting to nautilus on logout is
#       the only way I have been able to NOT have Unity get hung at login...
#       other techniques for re-starting Nautilus / Unity / etc. all break
#       Unity).
#   2016-04-27 rik: nemo-compare-preferences.desktop handling based on desktop
#   2016-10-01 rik: for all sessions make sure nemo and nautilus don't show
#       hidden files and for nemo don't show 'location-entry' (n/a for nautilus)
#   2016-10-19 rik: make sure nemo autostart is disabled.
#   2016-11-15 rik: adding debug login, also grabbing user and session from
#       lightdm log (instead of getting session from wmctrl)
#   2017-03-18 rik: writing user session to log so can retrieve on next login
#       to sync settings if session has changed (this was formerly done by a
#       wasta-logout systemd script which was difficult to work with).
#   2017-03-18 rik: this script is no longer triggered by 'at' so user login
#       won't complete until after this script completes.
#
# ==============================================================================

CURR_USER=$(grep -a "User .* authorized" /var/log/lightdm/lightdm.log | \
    tail -1 | sed 's@.*User \(.*\) authorized@\1@')
CURR_SESSION=$(grep -a "Greeter requests session" /var/log/lightdm/lightdm.log | \
    tail -1 | sed 's@.*Greeter requests session \(.*\)@\1@')

mkdir -p /var/log/wasta-multidesktop
LOGFILE=/var/log/wasta-multidesktop/wasta-login.txt
PREV_SESSION_FILE=/var/log/wasta-multidesktop/$CURR_USER-prev-session
PREV_SESSION=$(cat $PREV_SESSION_FILE)
DEBUG_FILE=/var/log/wasta-multidesktop/wasta-login-debug

if [ -e $DEBUG_FILE ];
then
    DEBUG=$(cat $DEBUG_FILE)
    if [ "$DEBUG" != "YES" ];
    then
        DEBUG=""
    fi
else
    # create empty $DEBUG_FILE
    touch $DEBUG_FILE
fi

WASTA_CORE_DIR=/usr/share/wasta-core

if [ $DEBUG ];
then
    echo | tee -a $LOGFILE
    echo "$(date) starting wasta-login" | tee -a $LOGFILE
    echo "current user: $CURR_USER" | tee -a $LOGFILE
    echo "current session: $CURR_SESSION" | tee -a $LOGFILE
    echo "PREV session for user: $PREV_SESSION" | tee -a $LOGFILE
    if [ -x /usr/bin/nemo ];
    then
        echo "TOP NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop desktop-layout')" | tee -a $LOGFILE
    fi
    echo "NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
fi

if ! [ $CURR_USER ];
then
    if [ $DEBUG ];
    then
        echo "EXITING... no user found" | tee -a $LOGFILE
    fi
    exit 0
fi

if ! [ $CURR_SESSION ];
then
    if [ $DEBUG ];
    then
        echo "EXITING... no session found" | tee -a $LOGFILE
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# Store current backgrounds
# ------------------------------------------------------------------------------
if [ -x /usr/bin/cinnamon ];
then
    CINNAMON_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.cinnamon.desktop.background picture-uri' || true;)
fi
GNOME_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.gnome.desktop.background picture-uri' || true;)
LIGHTDM_BACKGROUND=$(su "$CURR_USER" -c 'dbus-launch gsettings get x.dm.slick-greeter background' || true;)
if [ $DEBUG ];
then
    if [ -x /usr/bin/cinnamon ];
    then
        echo "cinnamon bg: $CINNAMON_BACKGROUND" | tee -a $LOGFILE
    fi
    echo "gnome bg: $GNOME_BACKGROUND" | tee -a $LOGFILE
    echo "lightdm bg: $LIGHTDM_BACKGROUND" | tee -a $LOGFILE
fi

# ------------------------------------------------------------------------------
# ALL Session Fixes
# ------------------------------------------------------------------------------

# SYSTEM level fixes:
# - we want app-adjustments to run every login to ensure that any updated
#   apps don't revert the settings.
# - Triggering with at so this login script is not delayed as
#   app-adjustments can run asynchronously.
echo "$WASTA_CORE_DIR/scripts/app-adjustments.sh $*" | at now || true;

# USER level fixes:
# Ensure Nautilus not showing hidden files (power users may be annoyed)
su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.nautilus.preferences show-hidden-files false' || true;

if [ -x /usr/bin/nemo ];
then
    # Ensure Nemo not showing hidden files (power users may be annoyed)
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-hidden-files false' || true;

    # Ensure Nemo not showing "location entry" (text entry), but rather "breadcrumbs"
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.preferences show-location-entry false' || true;

    # Ensure Nemo sorting by name
    su "$CURR_USER" -c "dbus-launch gsettings set org.nemo.preferences default-sort-order 'name'" || true;

    # Ensure Nemo sidebar showing
    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.window-state start-with-sidebar true' || true;

    # Ensure Nemo sidebar set to 'places'
    su "$CURR_USER" -c "dbus-launch gsettings set org.nemo.window-state side-pane-view 'places'" || true;



    # make sure Nemo autostart disabled (we start it ourselves)
    # if [ -e /etc/xdg/autostart/nemo-autostart.desktop ]
    # then
    #     desktop-file-edit --set-key=NoDisplay --set-value=true \
    #         /usr/share/applications/nemo-autostart.desktop || true;
    # fi
    # stop nemo if running (we'll start later)
#    if [ "$(pidof nemo-desktop)" ];
#    then
#        if [ $DEBUG ];
#        then
#            echo "nemo-desktop is running: $(pidof nemo-desktop)" | tee -a $LOGFILE
#        fi
#       ****18.04: commenting out to see if necessary - nemo-desktop now manages the desktop
#       killall nemo-desktop | tee -a $LOGFILE
#    fi
fi

# --------------------------------------------------------------------------
# SYNC to PREV_SESSION if different
# --------------------------------------------------------------------------
# previously I only triggered if current and prev sessions were different
# but I will always apply the changes in case it didn't succeed before.
if [ "$PREV_SESSION" == "cinnamon" ];
then
    # apply Cinnamon settings to GNOME
    if [ $DEBUG ];
    then
        echo "Previous Session Cinnamon: Sync TO GNOME" | tee -a $LOGFILE
    fi
    # sync Cinnamon background to GNOME background
    su "$CURR_USER" -c "dbus-launch gsettings set org.gnome.desktop.background picture-uri $CINNAMON_BACKGROUND" || true;
    # sync Cinnmaon background to Slick-Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $CINNAMON_BACKGROUND | sed 's@file://@@')
    su "$CURR_USER" -c "dbus-launch gsettings set x.dm.slick-greeter background $LIGHTDM_BACKGROUND" || true;
else
    if [ -x /usr/bin/cinnamon ];
    then
        # apply GNOME settings to Cinnamon
        if [ $DEBUG ];
        then
            echo "Previous Session NOT Cinnamon: Sync TO Cinnamon" | tee -a $LOGFILE
        fi
        # sync GNOME background to Cinnamon background
        su "$CURR_USER" -c "dbus-launch gsettings set org.cinnamon.desktop.background picture-uri $GNOME_BACKGROUND" || true;
    fi
    # sync GNOME background to Slick Greeter LightDM background
    LIGHTDM_BACKGROUND=$(echo $GNOME_BACKGROUND | sed 's@file://@@')
    # set LIGHTDM background
    su "$CURR_USER" -c "dbus-launch gsettings set x.dm.slick-greeter background $LIGHTDM_BACKGROUND" || true;
fi

# ------------------------------------------------------------------------------
# Processing based on session
# ------------------------------------------------------------------------------

if [ "$CURR_SESSION" == "cinnamon" ];
then
    # ==========================================================================
    # ACTIVE SESSION: CINNAMON
    # ==========================================================================
    if [ $DEBUG ];
    then
        echo "processing based on CINNAMON session" | tee -a $LOGFILE
    fi

    # Nautilus may be active: kill (will not error if not found)
    if [ "$(pidof nautilus-desktop)" ];
    then
        if [ $DEBUG ];
        then
            echo "nautilus running (TOP) and needs killed: $(pidof nautilus-desktop)" | tee -a $LOGFILE
        fi
        killall nautilus-desktop | tee -a $LOGFILE
    fi

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    # SHOW CINNAMON items

    if [ -e /usr/share/applications/cinnamon-settings-startup.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/cinnamon-settings-startup.desktop || true;
    fi

    if [ -x /usr/bin/nemo ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo.desktop || true;

        # allow nemo to draw the desktop
        su "$CURR_USER" -c "dbus-launch gsettings set org.nemo.desktop desktop-layout 'true::false'" || true;

        # Ensure Nemo default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nemo.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nemo.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list || true;

        if ! [ "$(pidof nemo-desktop)" ];
        then
            if [ $DEBUG ];
            then
                echo "nemo not started: attempting to start" | tee -a $LOGFILE
            fi
            # Ensure Nemo Started
            su "$CURR_USER" -c 'dbus-launch nemo-desktop &' || true;
        fi
    fi

    if [ -e /usr/share/applications/nemo-compare-preferences.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nemo-compare-preferences.desktop || true;
    fi

    # --------------------------------------------------------------------------
    # Ubuntu/GNOME Settings
    # --------------------------------------------------------------------------
    # HIDE Ubuntu/GNOME items
    if [ -e /usr/share/applications/alacarte.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/alacarte.desktop || true
    fi

    # Gnome Applications
    if [ -e /usr/share/applications/gnome-session-properties.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-session-properties.desktop || true;
    fi

    if [ -e /usr/share/applications/gnome-tweak-tool.desktop ];
    then
         desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/gnome-tweak-tool.desktop || true;
    fi

    if [ -e /usr/share/applications/nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nautilus.desktop || true;

        # Nautilus may be active: kill (will not error if not found)
        if [ "$(pidof nautilus-desktop)" ];
        then
            if [ $DEBUG ];
            then
                echo "nautilus running (MID) and needs killed: $(pidof nautilus-desktop)" | tee -a $LOGFILE
            fi
            killall nautilus-desktop | tee -a $LOGFILE
        fi

        # Prevent Nautilus from drawing the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false' || true;
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false' || true;
    fi

    if [ -e /usr/share/applications/org.gnome.Nautilus.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/org.gnome.Nautilus.desktop || true;

        # Prevent Nautilus from drawing the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false' || true;
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false' || true;
    fi

    if [ -e /usr/share/applications/nautilus-compare-preferences.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nautilus-compare-preferences.desktop || true;
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

    if [ $DEBUG ];
    then
        if [ -x /usr/bin/nemo ];
        then
            echo "end cinnamon detected - NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop desktop-layout')" | tee -a $LOGFILE
        fi
        echo "end cinnamon detected - NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
        echo "end cinnamon detected - NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
    fi

# ****BIONIC NOT SURE IF NEEDED
    #again trying to set nemo to draw....
#    su "$CURR_USER" -c 'dbus-launch gsettings set org.nemo.desktop show-desktop-icons true'
#    su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons false'
#    su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background false'

#    ****BIONIC NOT SURE IF NEEDED
#    if [ $DEBUG ];
#    then
#        echo "after nemo draw desk again NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop show-desktop-icons')" | tee -a $LOGFILE
#        echo "after nemo draw desk again NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
#        echo "after nemo draw desk again NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
#    fi

elif [ "$CURR_SESSION" == "ubuntu" ] || [ "$CURR_SESSION" == "ubuntu-xorg" ] || [ "$CURR_SESSION" == "gnome" ];
then
    # ==========================================================================
    # ACTIVE SESSION: UBUNTU / GNOME (sorry, no XFCE, KDE, or MATE support yet)
    # ==========================================================================

    if [ $DEBUG ];
    then
        echo "processing based on UBUNTU / GNOME session" | tee -a $LOGFILE
    fi

    # --------------------------------------------------------------------------
    # CINNAMON Settings
    # --------------------------------------------------------------------------
    if [ -x /usr/bin/nemo ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo.desktop || true;

        # ****BIONIC: don't think necessary (nemo-desktop now handles desktop)
        # prevent nemo from drawing the desktop
        # su "$CURR_USER" -c "dbus-launch gsettings set org.nemo.desktop desktop-layout 'true::false'"

        # Nemo may be active: kill (will not error if not found)
        if [ "$(pidof nemo-desktop)" ];
        then
            if [ $DEBUG ];
            then
                echo "nemo-desktop running (MID) and needs killed: $(pidof nemo-desktop)" | tee -a $LOGFILE
            fi
            killall nemo-desktop | tee -a $LOGFILE
        fi
    fi

    if [ -e /usr/share/applications/nemo-compare-preferences.desktop ];
    then
        desktop-file-edit --set-key=NoDisplay --set-value=true \
            /usr/share/applications/nemo-compare-preferences.desktop || true;
    fi
    # --------------------------------------------------------------------------
    # Ubuntu/GNOME Settings
    # --------------------------------------------------------------------------
    # SHOW GNOME Items
    if [ -e /usr/share/applications/alacarte.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/alacarte.desktop || true;
    fi

    # Gnome Applications
    if [ -e /usr/share/applications/gnome-session-properties.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/gnome-session-properties.desktop || true;
    fi

    if [ -e /usr/share/applications/gnome-tweak-tool.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/gnome-tweak-tool.desktop || true;
    fi

    if [ -e /usr/share/applications/nautilus.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nautilus.desktop || true;

        # Allow Nautilus to draw the desktop
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background show-desktop-icons true' || true;
        su "$CURR_USER" -c 'dbus-launch gsettings set org.gnome.desktop.background draw-background true' || true;

        # Ensure Nautilus default folder handler
        sed -i \
            -e 's@\(inode/directory\)=.*@\1=nautilus-folder-handler.desktop@' \
            -e 's@\(application/x-gnome-saved-search\)=.*@\1=nautilus-folder-handler.desktop@' \
            /etc/gnome/defaults.list \
            /usr/share/applications/defaults.list || true;

        # Ensure Nautilus Started
        if ! [ "$(pidof nautilus-desktop)" ];
        then
            if [ $DEBUG ];
            then
                echo "nautilus not started: attempting to start" | tee -a $LOGFILE
            fi
            su "$CURR_USER" -c 'dbus-launch nautilus-desktop &' || true;
        fi
    fi

    if [ -e /usr/share/applications/nautilus-compare-preferences.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/nautilus-compare-preferences.desktop || true;
    fi

    if [ -e /usr/share/applications/software-properties-gnome.desktop ];
    then
        desktop-file-edit --remove-key=NoDisplay \
            /usr/share/applications/software-properties-gnome.desktop || true;
    fi

else
    if [ $DEBUG ];
    then
        echo "desktop session not supported" | tee -a $LOGFILE
    fi

fi


# ------------------------------------------------------------------------------
# SET PREV Session file for user
# ------------------------------------------------------------------------------
echo $CURR_SESSION > $PREV_SESSION_FILE

# ------------------------------------------------------------------------------
# FINISHED
# ------------------------------------------------------------------------------
if [ $DEBUG ];
then
    if [ -x /usr/bin/nemo ];
    then
        if [ "$(pidof nemo-desktop)" ];
        then
            echo "END: nemo IS running!" | tee -a $LOGFILE
        else
            echo "END: nemo NOT running!" | tee -a $LOGFILE
        fi
    fi

    if [ "$(pidof nautilus-desktop)" ];
    then
        echo "END: nautilus-desktop IS running!" | tee -a $LOGFILE
    else
        echo "END: nautilus-desktop NOT running!" | tee -a $LOGFILE
    fi
    echo "final settings:" | tee -a $LOGFILE
    if [ -x /usr/bin/cinnamon ];
    then
        CINNAMON_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.cinnamon.desktop.background picture-uri')
        echo "cinnamon bg NEW: $CINNAMON_BACKGROUND_NEW" | tee -a $LOGFILE
    fi
    GNOME_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get org.gnome.desktop.background picture-uri')
    LIGHTDM_BACKGROUND_NEW=$(su "$CURR_USER" -c 'dbus-launch gsettings get x.dm.slick-greeter background')
    echo "gnome bg NEW: $GNOME_BACKGROUND_NEW" | tee -a $LOGFILE
    echo "lightdm bg NEW: $LIGHTDM_BACKGROUND_NEW" | tee -a $LOGFILE
    if [ -x /usr/bin/nemo ];
    then
        echo "NEMO show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.nemo.desktop desktop-layout')" | tee -a $LOGFILE
    fi
    echo "NAUTILUS show desktop icons: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background show-desktop-icons')" | tee -a $LOGFILE
    echo "NAUTILUS draw background: $(su $CURR_USER -c 'dbus-launch gsettings get org.gnome.desktop.background draw-background')" | tee -a $LOGFILE
    echo "$(date) exiting wasta-login" | tee -a $LOGFILE
fi

exit 0
