# System configs tracked for disaster recovery
# These live at various /etc/ paths on the Pi.
# After reflash, copy them back to their original locations.

# fstab → /etc/fstab
# fstrim-override.conf → /etc/systemd/system/fstrim.service.d/override.conf  
# cloudflared/ → /etc/cloudflared/
# systemd/ → /etc/systemd/system/
# crontab.txt → crontab -l (restore with: crontab crontab.txt)
# bashrc-custom.sh → append to ~/.bashrc
