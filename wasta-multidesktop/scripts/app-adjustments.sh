#!/bin/bash

# ==============================================================================
# wasta-core: app-adjustments.sh
#
# 2015-10-25 rik: initial script - pulled from other scripts
# 2015-11-06 rik: making gdebi default for deb files
#   - chromium app launcher processing
#   - gpaste, gcolor2 icon changes to use others available in Moka icon theme
# 2015-11-10 rik: ubiquity apt-setup: commenting out replace of sources.list:
#     we want to just go with what live-cd has, as often minor countries mirror
#     not very good: instead stick to main repo, user can later change if they
#     want.
#   - casper: added fix here instead of in postinst
# 2015-11-11 rik: removing ubiquity tweak: problem was with PinguyBuilder and
#     is now fixed in wasta-remastersys
#   - remove PinguyBuilder processing, add wasta-remastersys processing
# 2015-11-13 rik: fixing syntax of variables for wasta-remastersys.conf
# 2015-11-21 rik: updating wasta-remastersys.conf location
# 2016-04-27 rik: goldendict config updates (for http to https) and comment fix
#   - artha: removing tweaks (no longer installed in Wasta-Linux by default)
#   - wasta-remastersys: fixing splash screen background location
#   - defaults.list syntax corrections (do all at once instead of looping)
# 2016-05-04 rik: goldendict point to correct hunspell dictionary location
#   - webbrowser-app: hiding (brought in by unity-tweak-tool)
#   - meld: changing to 'Utility' so no 'Development' category by default
# 2016-05-09 rik: reverting gcolor2, gnome-search-tool icons as humanity
#   doesn't support gpick and catfish, so then would be empty (I had previously
#   put in these manually into hicolor, but then will prevent install of gpick
#   or catfish!)
# 2016-05-10 rik: moving to gcolor3, so taking out gcolor2 icon fix
# 2016-07-19 rik: adding xfce compatibility
#  - hiding ubuntu-amazon-default
#  - classicmenu-indicator: only show in unity
# 2016-08-22 rik: org.gnome.font-viewer: won't launch in 16.04 unless comment
#   out DBus line from desktop file.  Fixed for yakkety, not sure if will
#   backport to xenial.
# 2016-09-14 rik: adding wesay to "Education" category (removing from "Office")
# 2016-09-30 rik: removing chromium-app-launcher customization: Google has
#   deprecated it.
# 2016-10-07 rik: ubiquity: set to not show if found
# 2017-03-15 rik: simple-scan set to launch with XDG_CURRENT_DESKTOP=Unity
# 2017-11-29 rik: initial bionic release
# 2018-01-19 rik: shortening wasta-remastersys CUSTOMISO label
# 2018-03-02 rik: setting wasta-remastersys SLIDESHOW variable
# 2018-03-26 rik: hiding apps from main menu:
#   - chmsee, xchm
#   - flash-player-properties
#   - htop
#   - uxterm, xterm
# 2018-04-03 rik: hiding openjdk-9-policytool
#   - hiding org.gnome.font-viewer and org.gnome.FontViewer only if
#   org.gnome.FontManager is found
# 2018-05-23 rik: shorten GIMP name, capitalize bookletimposer
#   - correcting Arc scrollbar adjustment
# 2018-08-31 rik: removing wasta-remastersys.conf adjustments: only want as
#   part of wasta-core so not reset each login.
# 2018-09-03 rik: For 18.04 goldendict (and maybe other qt5 apps) need launched
#   with 'dbus-launch' prepended to the 'Exec=' statement in order for the
#   appindicator system tray icon to show
# 2019-01-08 rik: disabling wasta-ibus script for now since there have been some
#     issues with ibus user settings getting corrupted.
#   - adding items to XFCE Settings Manager
# 2019-01-23 rik: hiding texdoctk (installed by Paratext)
# 2019-01-30 rik: skypeforlinux - appindicator compatiblity by setting desktop
#   to "Unity"
# 2019-02-06 rik: if wasta-xfce found add XFCE to nemo-autostart
#   - gnome-online-accounts: add to xfce settings (prefer cinnamon over gnome)
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
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: app-adjustments.sh"
echo

# Setup Diretory for later reference
DIR=/usr/share/wasta-multidesktop

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
else
    AUTO=""
fi

# ------------------------------------------------------------------------------
# FIRST: Gnome Application Menu Cleanup
# ------------------------------------------------------------------------------
# 2017-11-29 rik: **** NEEDED FOR BIONIC? ****
# backup gnome-applications.menu first (don't do time check: always static original to keep
# if ! [ -e /etc/xdg/menus/gnome-applications.menu.save ];
# then
#     cp /etc/xdg/menus/gnome-applications.menu \
#        /etc/xdg/menus/gnome-applications.menu.save
# fi

# Delete 'Sundry' Category:
#   items here are duplicated in Accessories or System Tools so clean up to
#   just use those 2 categories: why do we want another category??
# Keeping for reference in case need to modify xml in the future:
#       xmlstarlet ed --inplace --delete '/Menu/Menu[Name="Sundry"]' \
#           /etc/xdg/menus/gnome-applications.menu

# get rid of gnome-applications.menu hard-coded category settings
#   (let desktops do that!!!)
# sed -i -e "\@<Filename>@d" /etc/xdg/menus/gnome-applications.menu

# ------------------------------------------------------------------------------
# SECOND: Clean up individual applications that are in bad places
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# arc-theme
# ------------------------------------------------------------------------------
if [ -e /usr/share/themes/Arc ];
then
    # scrollbars: "one page at a time" when clicking: GTK 2
    # NOTE: GTK 3 setting in postinst since no risk of being overwritten
    sed -i -e 's@\(gtk-primary-button-warps-slider\).*@\1 = 0@' \
        /usr/share/themes/Arc/gtk-2.0/gtkrc \
        /usr/share/themes/Arc-Dark/gtk-2.0/gtkrc \
        /usr/share/themes/Arc-Darker/gtk-2.0/gtkrc

    # add whiskermenu compatibility (Arc-Darker and Arc-Dark only)
    # first delete:
    sed -i -e '\@gtk-whiskermenu-wasta@d' \
        /usr/share/themes/Arc-Dark/gtk-3.0/gtk.css \
        /usr/share/themes/Arc-Darker/gtk-3.0/gtk.css

    # then add:
    sed -i -e "$ a @import url(\"$DIR/resources/gtk-whiskermenu-wasta.css\");" \
        /usr/share/themes/Arc-Dark/gtk-3.0/gtk.css \
        /usr/share/themes/Arc-Darker/gtk-3.0/gtk.css

    # make Arc themes compatible with xfce4-windowck-plugin (not sure why
    #   the .svg is not recognized by the code, but adding the .png solves it)
    if ! [ -e "/usr/share/themes/Arc/unity/close_focused_normal.png" ];
    then
        ln -s /usr/share/themes/Arc/unity/close_focused_normal.svg \
            /usr/share/themes/Arc/unity/close_focused_normal.png
    fi

    if ! [ -e "/usr/share/themes/Arc-Dark/unity/close_focused_normal.png" ];
    then
        ln -s /usr/share/themes/Arc-Dark/unity/close_focused_normal.svg \
            /usr/share/themes/Arc-Dark/unity/close_focused_normal.png
    fi

    if ! [ -e "/usr/share/themes/Arc-Darker/unity/close_focused_normal.png" ];
    then
        ln -s /usr/share/themes/Arc-Darker/unity/close_focused_normal.svg \
            /usr/share/themes/Arc-Darker/unity/close_focused_normal.png
    fi

# 2017-12 rik: for 18.04 below is making the scrollbar box really fat so disabling
#    # scrollbars: "add arrow at top":
#    sed -i -e 's@\(-GtkScrollbar-has-backward-stepper.*\) false@\1 true@' \
#        /usr/share/themes/Arc/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc/gtk-3.0/gtk-dark.css \
#        /usr/share/themes/Arc-Dark/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc-Darker/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc-Darker/gtk-3.0/gtk-dark.css

#    # scrollbars: "add arrow at bottom":
#    sed -i -e 's@\(-GtkScrollbar-has-forward-stepper.*\) false@\1 true@' \
#        /usr/share/themes/Arc/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc/gtk-3.0/gtk-dark.css \
#        /usr/share/themes/Arc-Dark/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc-Darker/gtk-3.0/gtk.css \
#        /usr/share/themes/Arc-Darker/gtk-3.0/gtk-dark.css
fi

#-GtkScrollbar-has-backward-stepper: 1;
#-GtkScrollbar-has-forward-stepper: 1;

# ------------------------------------------------------------------------------
# baobab
# ------------------------------------------------------------------------------
# Add to "Accessories" category (by removing from X-GNOME-Utilities)
if [ -e /usr/share/applications/org.gnome.baobab.desktop ];
then
    desktop-file-edit ---remove-category=X-GNOME-Utilities \
        /usr/share/applications/org.gnome.baobab.desktop
fi

# ------------------------------------------------------------------------------
# bookletimposer
# ------------------------------------------------------------------------------
if [ -x /usr/bin/bookletimposer ];
then
    # Capitalize Name
    #   sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-name="Booklet Imposer" \
        /usr/share/applications/bookletimposer.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# checkbox-converged
# ------------------------------------------------------------------------------
# hide if found
if [ -e /usr/share/applications/checkbox-converged.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/checkbox-converged.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# chmsee, xchm
# ------------------------------------------------------------------------------
# hide if found: added by bloom (?)
if [ -e /usr/share/applications/chmsee.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/chmsee.desktop
fi

if [ -e /usr/share/applications/xchm.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xchm.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# cinnamon
# ------------------------------------------------------------------------------
if [ -x /usr/bin/cinnamon ];
then
    # --------------------------------------------------------------------------
    # cinnamon backgrounds cleanup
    # --------------------------------------------------------------------------
    # Cinnammon Backgrounds Settings Panel groups by the last element of the
    #   xml config files, eg. adwaita.xml will show as "Adwaita".  Problem is
    #   all of the Ubuntu background xml files are named wily-wallpapers.xml,
    #   xenial-wallpapers.xml, etc.  That means they ALL have the name "wallpapers"
    #   in the Settings Panel.  Rename adding series name at end to make more clear.
    rename -v -f -e 's@([a-zA-Z0-9]*)-wallpapers.xml@$1-wallpapers-$1.xml@' \
        /usr/share/gnome-background-properties/*wallpapers.xml
    rename -v -f -e 's@([a-zA-Z0-9]*)-backgrounds.xml@$1-backgrounds-$1.xml@' \
        /usr/share/gnome-background-properties/*backgrounds.xml

    # cinnamon 3.0+ won't look at gnome-background-properties so
    #   symlinking if not found
    if ! [ -e /usr/share/cinnamon-background-properties ];
    then
        ln -s /usr/share/gnome-background-properties \
            /usr/share/cinnamon-background-properties
    fi

    # Cinnamon panel: get rid of "Remove 'applet'" from right click
    #   Below will remove text "Remove 'applet'" and will replace this._uuid with "wasta"
    #   and this.instance_id with "wasta" (needed to set something or cinnamon crashes)
    # remove display text

    # backup applet.js
    if ! [ -e /usr/share/cinnamon/js/ui/applet.js.save ];
    then
        cp /usr/share/cinnamon/js/ui/applet.js \
            /usr/share/cinnamon/js/ui/applet.js.save
    fi

    sed -i -e "s@Remove \'\%s\'@@" \
        /usr/share/cinnamon/js/ui/applet.js

    sed -i -e 's@\(.*removeAppletFromPanel(\).*\()\;\)@\1"wasta", "wasta"\2@' \
        /usr/share/cinnamon/js/ui/applet.js

    # --------------------------------------------------------------------------
    # IF iBus then add to Cinnamon Settings
    # --------------------------------------------------------------------------
    if [ -e /usr/share/applications/ibus-setup.desktop ];
    then
        # ibus-setup: first remove: 
        sed -i -e '\@ibus-setup@d' \
            /usr/share/cinnamon/cinnamon-settings/cinnamon-settings.py

        # ibus-setup: add (need first element to be system-config-printer since
        # want ibus in the "STANDALONE_MODULES" section)
        sed -i -e \
    'N;s@\(Keywords for filter.*\)\n\(.*system-config-printer\)@\1\n    [_("Keyboard Input Methods"),        "ibus-setup",                   "ibus-setup",         "hardware",       _("ibus, kmfl, keyman, keyboard, input, language")],\n\2@' \
            /usr/share/cinnamon/cinnamon-settings/cinnamon-settings.py
    fi

    # --------------------------------------------------------------------------
    # Cinnamon Applet Tweaks: core shipping with cinnamon only:
    #   applets added by wasta-cinnamon-layout are adjusted there
    # --------------------------------------------------------------------------

    # applet: calendar@cinnamon.org
    JSON_FILE=/usr/share/cinnamon/applets/calendar@cinnamon.org/settings-schema.json
    echo
    echo "*** Updating JSON_FILE: $JSON_FILE"
    echo
    # updates:
    # - use-custom-format: custom panel clock format
    # - custom-format: set to "%l:%M %p"
    # - note: jq can't do "sed -i" inplace update, so need to re-create file, then
    #     update ownership (in case run as root)
    NEW_FILE=$(jq '.["use-custom-format"].default=true | .["custom-format"].default="%l:%M %p"' \
        < $JSON_FILE)
    echo "$NEW_FILE" > $JSON_FILE

    # applet: menu@cinnamon.org
    JSON_FILE=/usr/share/cinnamon/applets/menu@cinnamon.org/settings-schema.json
    echo
    echo "*** Updating JSON_FILE: $JSON_FILE"
    echo
    # updates:
    # - don't show category icons
    # - note: jq can't do "sed -i" inplace update, so need to re-create file, then
    # update ownership (in case run as root)
    NEW_FILE=$(jq '.["show-category-icons"].default=false' \
        < $JSON_FILE)
    echo "$NEW_FILE" > $JSON_FILE

    # applet: panel-launchers@cinnamon.org
    JSON_FILE=/usr/share/cinnamon/applets/panel-launchers@cinnamon.org/settings-schema.json
    echo
    echo "*** Updating JSON_FILE: $JSON_FILE"
    echo
    # updates:
    # - set default launchers
    # - note: jq can't do "sed -i" inplace update, so need to re-create file, then
    # update ownership (in case run as root)
    NEW_FILE=$(jq '.["launcherList"].default=["firefox.desktop", "nemo.desktop", "libreoffice-writer.desktop", "wasta-backup.desktop", "wasta-resources.desktop"]' \
        < $JSON_FILE)
    echo "$NEW_FILE" > $JSON_FILE

    # applet: user@cinnamon.org
    echo
    echo "*** Setting user@cinnamon.org icon to 'system-devices-panel'"
    echo
    # reason for change is because this menu has more than just user info: it
    # also enables shutdown, etc.
    sed -i -e "s@this.set_applet_icon_symbolic_name(\"avatar-default\")@this.set_applet_icon_name(\"system-devices-panel\")@" \
        /usr/share/cinnamon/applets/user@cinnamon.org/applet.js
fi

# ------------------------------------------------------------------------------
# cinnamon-settings-users
# ------------------------------------------------------------------------------
# remove from xfce (now use gnome-system-tools users.desktop)
if [ -e /usr/share/applications/cinnamon-settings-users.desktop ];
then
    desktop-file-edit --remove-only-show-in=XFCE \
        /usr/share/applications/cinnamon-settings-users.desktop
fi

# ------------------------------------------------------------------------------
# clamtk-gnome
# ------------------------------------------------------------------------------
# hide if found since clamtk already in main menu
if [ -e /usr/share/applications/clamtk-gnome.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/clamtk-gnome.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# classicmenu-indicator
# ------------------------------------------------------------------------------
#classicmenu-indicator: only show in unity
if [ -x /usr/bin/classicmenu-indicator ];
then
    desktop-file-edit --add-only-show-in=Unity \
        /usr/share/applications/classicmenu-indicator.desktop
fi

# ------------------------------------------------------------------------------
# evince (pdf viewer)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/evince.desktop ];
then
    # remove from "Graphics": already in "Office"
    desktop-file-edit --remove-category=Graphics \
        /usr/share/applications/evince.desktop
fi

# ------------------------------------------------------------------------------
# file-roller
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/file-roller.desktop ];
then
    # hide from menu: only needed on nemo/nautilus right click
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/file-roller.desktop
fi

# ------------------------------------------------------------------------------
# flash-player-properties (Adobe Flash)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/flash-player-properties.desktop ];
then
    # hide from menu
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/flash-player-properties.desktop
fi

# ------------------------------------------------------------------------------
# font-manager
# ------------------------------------------------------------------------------
# change to "Utility" ("Accessories"): default is "Graphics"
if [ -e /usr/share/applications/font-manager.desktop ];
then
    desktop-file-edit --add-category=Utility \
        /usr/share/applications/font-manager.desktop

    desktop-file-edit --remove-category=Graphics \
        /usr/share/applications/font-manager.desktop
fi

# ------------------------------------------------------------------------------
# gimp
# ------------------------------------------------------------------------------
if [ -x /usr/bin/gimp ];
then
    # add "Advanced" to comment
    desktop-file-edit --set-comment="Advanced image and photo editor" \
        /usr/share/applications/gimp.desktop

    # default name is TOO LONG
    desktop-file-edit --set-name="GIMP Image Editor" \
        /usr/share/applications/gimp.desktop
fi

# ------------------------------------------------------------------------------
# goldendict
# ------------------------------------------------------------------------------
if [ -x /usr/bin/goldendict ];
then
    # for all users, correct http to https for wikipedia and wiktionary sources
    #   (suppress errors if no user has initialized goldendict)
    sed -i -e "s@http://\(.*\).wikipedia.org@https://\1.wikipedia.org@" \
        /home/*/.goldendict/config >/dev/null 2>&1
    sed -i -e "s@http://\(.*\).wiktionary.org@https://\1.wiktionary.org@" \
        /home/*/.goldendict/config >/dev/null 2>&1

    # for all users, correct hunspell dictionary path
    #   (suppress errors if no user has initialized goldendict)
    sed -i -e 's@\(hunspell dictionariesPath\).*@\1="/usr/share/hunspell"/>@' \
        /home/*/.goldendict/config >/dev/null 2>&1

    # fix comment
    desktop-file-edit --set-comment="Dictionary / Thesaurus tool" \
        /usr/share/applications/goldendict.desktop

    # 18.04: goldendict (qt5) plus cinnamon plus app indicator will not show
    # the tray icon.  Need to add dbus-launch to the launcher and then it will
    # show.  See: https://github.com/linuxmint/Cinnamon/issues/6143
    sed -i -e 's@^Exec=goldendict@Exec=dbus-launch goldendict@' \
        /usr/share/applications/goldendict.desktop
fi

# ------------------------------------------------------------------------------
# gnome-font-viewer
# ------------------------------------------------------------------------------
# hide because font-manager better.  User will only need
#   gnome-font-viewer when double-clicking a font file.  Font-Manager installed
#   by app-installs.sh
#
# bionic: there are org.gnome.font-viewer AND org.gnome.FontViewer? hide BOTH
if [ -e /usr/share/applications/org.gnome.font-viewer.desktop ] && [ -e /usr/share/applications/org.gnome.FontManager.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/org.gnome.font-viewer.desktop
fi

if [ -e /usr/share/applications/org.gnome.FontViewer.desktop ] && [ -e /usr/share/applications/org.gnome.FontManager.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/org.gnome.FontViewer.desktop
fi

# ****BIONIC not needed???****
# rik: 16.04 issue launching gnome-font-viewer: see this report:
# http://askubuntu.com/questions/804639/font-viewer-not-running-in-ubuntu-16-04
# "solution" is to comment out DBus line.  This should be fixed in future
# versions but not sure if it will get backported to xenial or not
#if [ -e /usr/share/applications/org.gnome.font-viewer.desktop ];
#then
#    sed -i -e 's@^\(DBus\)@#\1@' \
#        /usr/share/applications/org.gnome.font-viewer.desktop
#fi

# ------------------------------------------------------------------------------
# gnome-language-selector
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/gnome-language-selector.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/gnome-language-selector.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/gnome-language-selector.desktop

    desktop-file-edit --add-category=X-XFCE-PersonalSettings \
        /usr/share/applications/gnome-language-selector.desktop
fi

# ------------------------------------------------------------------------------
# gnome-online-accounts
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager

if [ -e /usr/share/applications/cinnamon-online-accounts-panel.desktop ];
then
    # prefer cinnamon online dialog if available
    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/cinnamon-online-accounts-panel.desktop

    desktop-file-edit --add-category=Settings \
        /usr/share/applications/cinnamon-online-accounts-panel.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/cinnamon-online-accounts-panel.desktop

    desktop-file-edit --add-category=X-XFCE-PersonalSettings \
        /usr/share/applications/cinnamon-online-accounts-panel.desktop

    # make sure gnome-online-accounts-panel is not showing since use cinnamon
    if [ -e /usr/share/applications/gnome-online-accounts-panel.desktop ];
    then
        desktop-file-edit --remove-only-show-in=XFCE \
            /usr/share/applications/gnome-online-accounts-panel.desktop
    fi
elif [ -e /usr/share/applications/gnome-online-accounts-panel.desktop ];
then
    # cinnamon online accounts not available so use gnome instead
    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/gnome-online-accounts-panel.desktop

    desktop-file-edit --add-category=Settings \
        /usr/share/applications/gnome-online-accounts-panel.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/gnome-online-accounts-panel.desktop

    desktop-file-edit --add-category=X-XFCE-PersonalSettings \
        /usr/share/applications/gnome-online-accounts-panel.desktop
fi

# ------------------------------------------------------------------------------
# gnome-power-statistics
# ------------------------------------------------------------------------------
# always show
if [ -e /usr/share/applications/gnome-power-statistics.desktop ];
then
    desktop-file-edit --remove-key=OnlyShowIn \
        /usr/share/applications/gnome-power-statistics.desktop
fi

# ------------------------------------------------------------------------------
# gnome-screenshot
# ------------------------------------------------------------------------------
# ****BIONIC not needed????****
# Add to "Accessories" category (by removing from X-GNOME-Utilities)
#if [ -e /usr/share/applications/org.gnome.Screenshot.desktop ];
#then
#    desktop-file-edit ---remove-category=X-GNOME-Utilities \
#        /usr/share/applications/org.gnome.Screenshot.desktop
#fi

# ------------------------------------------------------------------------------
# gnome-search-tool
# ------------------------------------------------------------------------------
# add keyword "find" to comments for main menu search help
if [ -e /usr/share/applications/gnome-search-tool.desktop ];
then
    desktop-file-edit --set-comment="Find or Locate documents and folders on this computer by name or content" \
        /usr/share/applications/gnome-search-tool.desktop
fi

# ------------------------------------------------------------------------------
# htop
# ------------------------------------------------------------------------------
# we want command-line only
if [ -e /usr/share/applications/htop.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/htop.desktop
fi

# ------------------------------------------------------------------------------
# ibus-setup
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/ibus-setup.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/ibus-setup.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/ibus-setup.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/ibus-setup.desktop
fi

# ------------------------------------------------------------------------------
# image-magick
# ------------------------------------------------------------------------------
# we want command-line only
if [ -e /usr/share/applications/display-im6.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/display-im6.desktop
fi

if [ -e /usr/share/applications/display-im6.q16.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/display-im6.q16.desktop
fi

# ------------------------------------------------------------------------------
# input-method
# ------------------------------------------------------------------------------
# ****BIONIC NOT disabling for now.. want to have way that user won't need ibus
# hide if found (we use ibus as default input method)
#if [ -e /usr/share/applications/im-config.desktop ];
#then
#    desktop-file-edit --set-key=NoDisplay --set-value=true \
#        /usr/share/applications/im-config.desktop
#fi

# ------------------------------------------------------------------------------
# libreoffice-math
# ------------------------------------------------------------------------------
# remove from 'science and education' to reduce number of categories
if [ -e /usr/share/applications/libreoffice-math.desktop ];
then
    desktop-file-edit ---remove-category=Science \
        /usr/share/applications/libreoffice-math.desktop

    desktop-file-edit ---remove-category=Education \
        /usr/share/applications/libreoffice-math.desktop
fi

# ------------------------------------------------------------------------------
# meld
# ------------------------------------------------------------------------------
# change to "Utility" ("Accessories"): default is "Development" (only item
#   in that category, so we are trying to not have "Programming" by default)
if [ -e /usr/share/applications/meld.desktop ];
then
    desktop-file-edit --add-category=Utility \
        /usr/share/applications/meld.desktop

    desktop-file-edit --remove-category=Development \
        /usr/share/applications/meld.desktop
fi

# ------------------------------------------------------------------------------
# menulibre
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/menulibre.desktop ];
then
    # send output to null since warnings from OnlyShowIn key
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/menulibre.desktop >/dev/null 2>&1 || true;

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/menulibre.desktop >/dev/null 2>&1 || true;

    desktop-file-edit --add-category=X-XFCE-PersonalSettings \
        /usr/share/applications/menulibre.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# modem-manager-gui
# ------------------------------------------------------------------------------
# change "Categories" to "Utility" ("Accessories"): default is "System

if [ -e /usr/share/applications/modem-manager-gui.desktop ];
then
    desktop-file-edit --add-category=Network \
        /usr/share/applications/modem-manager-gui.desktop

    desktop-file-edit --remove-category=System \
        /usr/share/applications/modem-manager-gui.desktop

    # show in all desktops
    desktop-file-edit --remove-key=OnlyShowIn \
        /usr/share/applications/modem-manager-gui.desktop
    
    # modify comment so easier to find on search
    desktop-file-edit --set-comment="3G USB Modem Manager" \
        /usr/share/applications/modem-manager-gui.desktop
fi

# ------------------------------------------------------------------------------
# mugshot
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/mugshot.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/mugshot.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/mugshot.desktop

    desktop-file-edit --add-category=X-XFCE-PersonalSettings \
        /usr/share/applications/mugshot.desktop
fi

# ------------------------------------------------------------------------------
# nemo
# ------------------------------------------------------------------------------
if [ -x /usr/bin/nemo ];
then
    # Allow nemo as a helper for evince
    if [ -x /usr/bin/evince ];
    then
        # delete 'wasta' lines (will re-create below)
        sed -i -e '\@wasta@d' /etc/apparmor.d/usr.bin.evince

        sed -i -e 's@\(/usr/bin/nautilus Cx -> sanitized_helper.*\)@\1\n  /usr/bin/nemo Cx -> sanitized_helper,     # wasta: Cinnamon/Nemo@' \
            /etc/apparmor.d/usr.bin.evince
    fi

    if [ -e /usr/share/wasta-xfce ];
    then
        # only for wasta-xfce allow XFCE to trigger nemo-autostart
        desktop-file-edit --add-only-show-in=XFCE \
            /usr/share/applications/nemo-autostart.desktop
    else
        # if no wasta-xfce don't allow XFCE to trigger nemo-autostart
        desktop-file-edit --remove-only-show-in=XFCE \
            /usr/share/applications/nemo-autostart.desktop
    fi
fi

# ------------------------------------------------------------------------------
# network
# ------------------------------------------------------------------------------
# Installed by gnome-system-tools (for XFCE) but don't need this one, even
#   though has one nice feature allowing user to change system name with a GUI
if [ -e /usr/share/applications/users.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/network.desktop || true;
fi

# ------------------------------------------------------------------------------
# nm-connection-editor
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/nm-connection-editor.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/nm-connection-editor.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/nm-connection-editor.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/nm-connection-editor.desktop
fi

# ------------------------------------------------------------------------------
# onboard (on-screen keyboard)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/onboard.desktop ];
then
    # remove from "Accessibility" (only 2 items there): already in "Utility"
    desktop-file-edit --remove-category=Accessibility \
        /usr/share/applications/onboard.desktop
fi

# ------------------------------------------------------------------------------
# OpenJDK Policy Tool
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/openjdk-7-policytool.desktop ];
then
    # Hide GUI from start menu
    # Send output to /dev/null since there are warnings generated
    #   by the comment fields
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/openjdk-7-policytool.desktop  >/dev/null 2>&1 || true;
fi

if [ -e /usr/share/applications/openjdk-8-policytool.desktop ];
then
    # Hide GUI from start menu
    # Send output to /dev/null since there are warnings generated
    #   by the comment fields
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/openjdk-8-policytool.desktop  >/dev/null 2>&1 || true;
fi

if [ -e /usr/share/applications/openjdk-9-policytool.desktop ];
then
    # Hide GUI from start menu
    # Send output to /dev/null since there are warnings generated
    #   by the comment fields
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/openjdk-9-policytool.desktop  >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# orca (screen reader)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/orca.desktop ];
then
    # remove from "Accessibility" (only 2 items there): already in "Utility"
    desktop-file-edit --remove-category=Accessibility \
        /usr/share/applications/orca.desktop
fi

# ------------------------------------------------------------------------------
# PulseAudio Control
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/pavucontrol.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/pavucontrol.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/pavucontrol.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/pavucontrol.desktop
fi

# ------------------------------------------------------------------------------
# skypeforlinux
# ------------------------------------------------------------------------------
# appindicator compatibility
if [ -e /usr/share/applications/skypeforlinux.desktop ];
then
    desktop-file-edit --set-key=Exec --set-value='sh -c "env XDG_CURRENT_DESKTOP=Unity /usr/bin/skypeforlinux %U"' \
        /usr/share/applications/skypeforlinux.desktop> /dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# slick-greeter
# ------------------------------------------------------------------------------
# setup badges for wl defaults
if [ -L /usr/share/slick-greeter/badges/cinnmaon2d.svg ];
then
    unlink /usr/share/slick-greeter/badges/cinnamon2d.svg
fi

if [ -e /usr/share/slick-greeter/badges/cinnamon.svg ];
then
    mv /usr/share/slick-greeter/badges/cinnamon.svg /usr/share/slick-greeter/badges/cinnamon2d.svg
fi

if [ -e /usr/share/slick-greeter/badges ];
then
    cp $DIR/resources/wl-round-22.png /usr/share/slick-greeter/badges/cinnamon.png
fi

# ------------------------------------------------------------------------------
# simple-scan
# ------------------------------------------------------------------------------
# Disable csd
if [ -e /usr/share/applications/simple-scan.desktop ];
then
    desktop-file-edit --set-key=Exec --set-value='sh -c "env XDG_CURRENT_DESKTOP=Unity simple-scan"' \
        /usr/share/applications/simple-scan.desktop > /dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# software-properties-drivers
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/software-properties-drivers.desktop ];
then
    #rik: no trailing space after HardwareSettings so remove and re-add
    #     otherwise additional added categories will have an error
    desktop-file-edit --remove-category=HardwareSettings \
        /usr/share/applications/software-properties-drivers.desktop

    desktop-file-edit --add-category=HardwareSettings \
        /usr/share/applications/software-properties-drivers.desktop

    desktop-file-edit --add-category=Settings \
        /usr/share/applications/software-properties-drivers.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/software-properties-drivers.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/software-properties-drivers.desktop
fi

# ------------------------------------------------------------------------------
# software-properties-gnome,gtk
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/software-properties-gnome.desktop ];
then
    # rename to "Software Settings" or else get confused with "Software Updates"
    desktop-file-edit --set-name="Software Settings" \
        /usr/share/applications/software-properties-gnome.desktop

    # add to XFCE Settings Manager
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/software-properties-gtk.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/software-properties-gtk.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/software-properties-gtk.desktop
fi

if [ -e /usr/share/applications/software-properties-gtk.desktop ];
then
    # rename to "Software Settings" or else get confused with "Software Updates"
    desktop-file-edit --set-name="Software Settings" \
        /usr/share/applications/software-properties-gtk.desktop

    # add to XFCE Settings Manager
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/software-properties-gtk.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/software-properties-gtk.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/software-properties-gtk.desktop
fi

# ------------------------------------------------------------------------------
# system-config-printer
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/system-config-printer.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/system-config-printer.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/system-config-printer.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/system-config-printer.desktop
fi

# ------------------------------------------------------------------------------
# texdoctk
# ------------------------------------------------------------------------------
# hide if found (Paratext installs but don't want to clutter menu)
if [ -e /usr/share/applications/texdoctk.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/texdoctk.desktop
fi

# ------------------------------------------------------------------------------
# time (from gnome-system-tools)
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/time.desktop ];
then
    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/time.desktop

    desktop-file-edit --add-category=Settings \
        /usr/share/applications/time.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/time.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/time.desktop
fi

# ------------------------------------------------------------------------------
# ubiquity
# ------------------------------------------------------------------------------
if [ -e /usr/share/ubiquity/localechooser-apply ];
then
    # ET is hard-coded to 'am' language, regardless of what user chose
    #   remove this override: Amharic is not wanted as hardcoded language
    #   Most Ethiopians will use English
    sed -i -e '\@deflang=am@d' /usr/share/ubiquity/localechooser-apply
fi

# always hide (this comes from ubiquity-frontend-gtk, which we want installed
#   so it doesn't have to be downloaded by wasta-remastersys)
if [ -e /usr/share/applications/ubiquity.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (invalid use of "'" in Exec line)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/ubiquity.desktop > /dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# unity-lens-photos
# ------------------------------------------------------------------------------
#unity-lens-photos: only show in unity
if [ -e /usr/share/applications/unity-lens-photos.desktop ];
then
    desktop-file-edit --add-only-show-in=Unity \
        /usr/share/applications/unity-lens-photos.desktop
fi

# ------------------------------------------------------------------------------
# ubuntu-amazon-default
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/ubuntu-amazon-default.desktop ];
then
    # hide from main menu
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/ubuntu-amazon-default.desktop
fi

# ------------------------------------------------------------------------------
# update-manager
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/update-manager.desktop ];
then
    desktop-file-edit --add-category=Settings \
        /usr/share/applications/update-manager.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/update-manager.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/update-manager.desktop
fi

# ------------------------------------------------------------------------------
# users (from gnome-system-tools)
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/users.desktop ];
then
    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/users.desktop

    desktop-file-edit --add-category=Settings \
        /usr/share/applications/users.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/users.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/users.desktop
fi

# ------------------------------------------------------------------------------
# uxterm, xterm
# ------------------------------------------------------------------------------
# pulled in by bloom(??)
if [ -e /usr/share/applications/debian-uxterm.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/debian-uxterm.desktop
fi

if [ -e /usr/share/applications/debian-xterm.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/debian-xterm.desktop
fi

# ------------------------------------------------------------------------------
# vim
# ------------------------------------------------------------------------------
# always hide
if [ -e /usr/share/applications/vim.desktop ];
then
    # hide from main menu (terminal only)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/vim.desktop
fi

# ------------------------------------------------------------------------------
# wasta-ibus
# ------------------------------------------------------------------------------
# 2019-01-08 rik: disabling for now since have been some issues with ibus
#   user settings getting corrupted.
#if [ -e /usr/share/wasta-ibus ];
#then
#    # Ensure xkb keyboards in ibus keyboard list
#    echo
#    echo "*** Calling ibus-xkb-adjustments.sh script"
#    echo
#    bash /usr/share/wasta-ibus/scripts/ibus-xkb-adjustments.sh
#fi

# ------------------------------------------------------------------------------
# web2py
# ------------------------------------------------------------------------------
# hide if found (Paratext installs but don't want to clutter menu)
if [ -e /usr/share/applications/web2py.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/web2py.desktop
fi

# ------------------------------------------------------------------------------
# webbrowser-app
# ------------------------------------------------------------------------------
# hide if found (unity-tweak-tool installs it)
if [ -e /usr/share/applications/webbrowser-app.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/webbrowser-app.desktop
fi

# ------------------------------------------------------------------------------
# wesay
# ------------------------------------------------------------------------------
# change to "Education": default is "Office" (other SIL apps all to Education)
if [ -e /usr/share/applications/sil-wesay.desktop ];
then
    desktop-file-edit --add-category=Education \
        /usr/share/applications/sil-wesay.desktop

    desktop-file-edit --remove-category=Office \
        /usr/share/applications/sil-wesay.desktop
fi

if [ -e /usr/share/applications/sil-wesay-config.desktop ];
then
    desktop-file-edit --add-category=Education \
        /usr/share/applications/sil-wesay-config.desktop

    desktop-file-edit --remove-category=Office \
        /usr/share/applications/sil-wesay-config.desktop
fi

# ------------------------------------------------------------------------------
# xdiagnose
# ------------------------------------------------------------------------------
# hide if found
if [ -e /usr/share/applications/xdiagnose.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xdiagnose.desktop
fi

# ------------------------------------------------------------------------------
# xfce-settings-manager
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/xfce-settings-manager.desktop ];
then
    # Change comment so found by "system, control, panel"
    desktop-file-edit --set-comment="Graphical System Control Panel for Xfce 4" \
        /usr/share/applications/xfce-settings-manager.desktop
fi

# ------------------------------------------------------------------------------
# xfce4-appfinder
# ------------------------------------------------------------------------------
# hide from all desktops even from xfce (only used via shortcut)
if [ -e /usr/share/applications/xfce4-appfinder.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xfce4-appfinder.desktop
fi

# ------------------------------------------------------------------------------
# xfce4-power-manager-settings
# ------------------------------------------------------------------------------
# Only show in xfce
if [ -e /usr/share/applications/xfce4-power-manager-settings.desktop ];
then
    desktop-file-edit --remove-key=NotShowIn \
        /usr/share/applications/xfce4-power-manager-settings.desktop

    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/xfce4-power-manager-settings.desktop
fi

# ------------------------------------------------------------------------------
# xfce4-settings-editor
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/xfce4-settings-editor.desktop ];
then
    # Add to "Settings" category
    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/xfce4-settings-editor.desktop 
fi

# ------------------------------------------------------------------------------
# xfce4-screenshooter
# ------------------------------------------------------------------------------
# hide all desktops even from xfce (use gnome instead)
if [ -e /usr/share/applications/xfce4-screenshooter.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xfce4-screenshooter.desktop
fi

# ------------------------------------------------------------------------------
# zim
# ------------------------------------------------------------------------------
if [ -x /usr/bin/zim ];
then
    # TODO:if no current .config/zim then copy it from /etc/skel
    # this is needed to enable trayicon plugin by default
    if ! [ -d /etc/skel/.config/zim ];
    then
        mkdir -p /etc/skel/.config/zim
        cp -r $DIR/resources/skel/.config/zim /etc/skel/.config
    fi
fi

# ------------------------------------------------------------------------------
# Default Application Fixes: ??? better command to do this ???
# ------------------------------------------------------------------------------

echo
echo "*** Adjusting default applications"
echo

# preferred way to set defaults is with xdg-mime (but its 'man' says that the
#   default function shouldn't be used as root?)

# rik: to find "filetype" for file: xdg-mime query filetype <filename>

sed -i \
    -e 's@\(audio.*\)=.*@\1=vlc.desktop@' \
    -e 's@\(video.*\)=.*@\1=vlc.desktop@' \
    -e 's@totem.desktop@vlc.desktop@' \
    -e 's@\(text/plain\)=.*@\1=org.gnome.gedit.desktop@' \
    -e 's@\(application/x-deb\)=.*@\1=gdebi.desktop@' \
    -e 's@\(application/x-debian-package\)=.*@\1=gdebi.desktop@' \
    -e 's@\(text/xml\)=.*@\1=org.gnome.gedit.desktop@' \
    -e '$a application/x-extension-htm=firefox.desktop' \
    -e '$a application/x-font-ttf=org.gnome.font-viewer.desktop' \
    -e '$a application/x-shellscript=org.gnome.gedit.desktop' \
    -e '\@application/x-extension-htm=@d' \
    -e '\@application/x-font-ttf=@d' \
    -e '\@application/x-shellscript=@d' \
    /etc/gnome/defaults.list \
    /usr/share/applications/defaults.list

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Script Exit: app-adjustments.sh"
echo

exit 0
