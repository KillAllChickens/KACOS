#!/bin/bash

plymouth-set-default-theme --rebuild-initrd kac

for dir in /home/*; do
	[ -d "$dir" ] || continue
	mv "$dir/Desktop/.brave-browser.desktop" "$dir/Desktop/brave-browser.desktop"
done


install -Dm644 "/usr/share/plymouth/themes/kac/kac.bg.png" "/usr/share/grub/themes/kacos-background.png"

# Set GRUB background
sed -i 's|^#*GRUB_BACKGROUND=.*|GRUB_BACKGROUND="/usr/share/grub/themes/kacos-background.png"|' /etc/default/grub

# Update grub config
grub-mkconfig -o /boot/grub/grub.cfg

