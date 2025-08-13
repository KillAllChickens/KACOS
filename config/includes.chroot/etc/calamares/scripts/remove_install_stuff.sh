#!/bin/bash

rm -rf /etc/calamares*
rm -rf /usr/share/calamares
rm -rf /usr/lib/calamares
rm -rf /usr/share/plasma/plasma-welcome/



# For every user with a /home directory
for dir in /home/*; do
    [ -d "$dir" ] || continue
    rm -f "$dir/Desktop/calamares.desktop"
    rm -f "$dir/.config/plasma-welcomerc"
    #rm -f "$dir/.config/autostart/set-kac-wallpaper.desktop"
    rm -f "$dir/.local/share/kac-style-set"
    rm -f "$dir/"*.log
done

# Ensure new users dont get the files in skel
rm -f /etc/skel/Desktop/calamares.desktop
rm -f /etc/skel/.config/plasma-welcomerc
rm -rf /etc/skel/.config/autostart/

