#!/bin/bash

plymouth-set-default-theme --rebuild-initrd kac

for dir in /home/*; do
	[ -d "$dir" ] || continue
	mv "$dir/Desktop/.brave-browser.desktop" "$dir/Desktop/brave-browser.desktop"
done

# UPDATE BOOTLOADER

bg_path="/usr/share/grub/themes/KACOS/background.png"
grub_file="/etc/default/grub"

# If GRUB_BACKGROUND line exists, replace it, else append it
if grep -q '^GRUB_BACKGROUND=' "$grub_file"; then
    sed -i "s|^GRUB_BACKGROUND=.*|GRUB_BACKGROUND=\"$bg_path\"|" "$grub_file"
else
    echo "GRUB_BACKGROUND=\"$bg_path\"" | tee -a "$grub_file" > /dev/null
fi

# Update GRUB config
update-grub

# Update SDDM

sddm_file="/etc/sddm.conf"

if grep -q '^Current=' "$sddm_file"; then
    sed -i "s|^Current=.*|Current=KACOS|" "$sddm_file"
else
    if ! grep -q '^\[Theme\]' "$sddm_file"; then
        echo "[Theme]" | sudo tee -a "$sddm_file" > /dev/null
    fi
    echo "Current=KACOS" | sudo tee -a "$sddm_file" > /dev/null
fi

