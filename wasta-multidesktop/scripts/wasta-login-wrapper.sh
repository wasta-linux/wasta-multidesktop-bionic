#!/bin/bash

# ==============================================================================
# Wasta-Linux Login Wrapper Script
#
#   This wrapper is needed because a sleep is required in the real login script
#       in order to give time for the window manager to be fully loaded.  This
#       wrapper allows normal login process to continue since it will finish
#       immediately due to "&".  Real login script will sleep at beginning.
#
#   2013-12-21 rik: initial script
#   2016-11-07 rik: updating to use "at" to call "real script", otherwise
#       in newer releases the login process waits for completion.
#   2017-03-18 riK: removing "at" trigger, so this script won't complete until
#       after wasta-login completes, but this is good to not create confusion.
#
# ==============================================================================

#if ! [ -e /var/spool/cron/atjobs/.SEQ ]; then
#  /bin/bash -c "/usr/share/wasta-multidesktop/scripts/wasta-login.sh $*" &
#else
#  echo "/usr/share/wasta-multidesktop/scripts/wasta-login.sh $*" | at now
#fi

# rik: removing 'at' triggering since we don't need wasta-login to wait
#   anymore and when it is triggered asynchronously it causes some confusion
#   So, this wrapper isn't really needed anymore but am keeping for now.
# 2017-12-23 rik: executing with root to ensure runs correctly: have been
#   having some trouble otherwise with the session not starting due to some
#   sort of dbus error.  Below seems to work so will keep for now until we
#   understand better what the negative is.  POSSIBLE problem from before
#   was that I was executing with /bin/bash and I wonder if that started the
#   user session causing conflicts or something??? again unclear for now....
su root -c "/usr/share/wasta-multidesktop/scripts/wasta-login.sh $* || true;"

exit 0
