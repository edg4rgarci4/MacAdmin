#!/bin/sh
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   ZoomInstall.sh -- Installs or updates Zoom
#
# SYNOPSIS
#   sudo ZoomInstall.sh
#
####################################################################################################
#
# HISTORY
#
#   Version: 1.1sa
#   Updated by mw for use at SA 10/12/20
#   via https://www.jamf.com/jamf-nation/discussions/29561/script-to-install-update-zoom
#
#   1.1 - Shannon Johnson, 27.9.2019
#   Updated for new zoom numbering scheme
#   Fixed the repeated plist modifications
# 
#   1.0 - Shannon Johnson, 28.9.2018
#   (Adapted from the FirefoxInstall.sh script by Joe Farage, 18.03.2015)
#
####################################################################################################
# Script to download and install Zoom.
# Only works on Intel systems.

# choose language (en-US, fr, de)
lang=""
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 1 AND, IF SO, ASSIGN TO "lang"
if [ "$4" != "" ] && [ "$lang" == "" ]; then
    lang=$4
else 
    lang="en-US"
fi

#Variables
pkgfile="ZoomInstallerIT.pkg"
plistfile="us.zoom.config.plist"
ZoomLog="/Library/Logs/zoomusinstall.log"
zoom_test=`ps aux | grep zoom.us | grep -v grep`
#checks if the cpthost process is running; if so, a meeting is active on the device
meeting_test=`ps aux | grep cpthost | grep -v grep`

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    ## Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion | sed 's/[.]/_/g' )

    ## Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    # Get the latest version of Reader available from Zoom page.
    latestver=`/usr/bin/curl -s -A "$userAgent" https://zoom.us/download | grep 'ZoomInstallerIT.pkg' | awk -F'/' '{print $3}'`

    # Get the version number of the currently-installed Zoom, if any.
    if [ -e "/Applications/zoom.us.app" ]; then
    currentinstalledver=`/usr/bin/defaults read /Applications/zoom.us.app/Contents/Info CFBundleVersion | sed -e 's/0 //g' -e 's/(//g' -e 's/)//g'`
        if [ ${latestver} = ${currentinstalledver} ]; then
            echo "Zoom is up-to-date. Exiting."
            exit 0
        fi
    else
        currentinstalledver="none"
        echo "Zoom is not installed..."
    fi

    url="https://zoom.us/client/${latestver}/ZoomInstallerIT.pkg"

    # Compare the two versions, if they are different or Zoom is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${latestver}" ]; then

        # Construct the plist file for preferences
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>LastLoginType</key>
            <true/>
            <key>appendcallernameforroomsystem</key>
            <true/>
            <key>enablestartmeetingwithroomsystem</key>
            <true/>
            <key>ZAutoUpdate</key>
            <true/>
            <key>setwebdomain</key>
            <string>$CustomZoomDomain</string>
            <key>enableembedbrowserforsso</key>
            <true/>
            <key>ZSSOHost</key>
            <string>$SSODomain</string>
            <key>ZAutoSSOLogin</key>
            <true/>
            <key>PackageRecommend</key>
            <dict>
                <key>EnableRemindMeetingTime</key>
                <true/>
                <key>ZAutoFullScreenWhenViewShare</key>
                <false/>
            </dict>
        </dict>
        </plist>" > /tmp/${plistfile}

        # Download and install new version
        /bin/echo "Installed Zoom version: ${currentinstalledver}"
        /bin/echo "Current Zoom version: ${latestver}"
        /bin/echo "Downloading current version..."
        /usr/bin/curl -sLo /tmp/${pkgfile} ${url}
        /bin/echo "Installing Zoom ${latestver}..."
        /usr/sbin/installer -allowUntrusted -pkg /tmp/${pkgfile} -target /

        /bin/sleep 20
        /bin/echo "Deleting Zoom installer..."
        /bin/rm /tmp/${pkgfile}

        #double check to see if the new version got updated
        newlyinstalledver=`/usr/bin/defaults read /Applications/zoom.us.app/Contents/Info CFBundleVersion`
    if [ "${latestver}" = "${newlyinstalledver}" ]; then
        /bin/echo "SUCCESS: Zoom has been updated to version ${newlyinstalledver}"
        # /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Zoom Installed" -description "Zoom has been updated." &
    else
        if [[ "$meeting_test" != "" ]] ; then
            /bin/echo "Zoom update failed to apply because the user is currently in a meeting..."
            /bin/echo "Zoom will prompt user to restart the app to apply update. Exiting..."
            exit 0
        elif [[ "$meeting_test" == "" ]] && [[ "$zoom_test" != "" ]] ; then
            /bin/echo "Zoom update failed to apply because Zoom is currently open..."
            /bin/echo "Zoom will prompt user to restart the app to apply update. Exiting..."
            exit 0
        else
            /bin/echo "ERROR: Zoom update unsuccessful, version remains at ${currentinstalledver}."
            /bin/echo "Printing Zoom install log..."
            /usr/bin/tail -n 30 "$ZoomLog"
            exit 1
        fi
    fi

    # If Zoom is up to date already, just log it and exit.
    else
        /bin/echo "Zoom is already up to date, running ${currentinstalledver}."
    fi
else
    /bin/echo "ERROR: This script is for Intel Macs only."
fi
exit 0
