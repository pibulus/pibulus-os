#!/bin/bash
# 🆔 QUICK CAT CLUB - IDENTITY SWAPPER
# Changes the domain and name system-wide.

NEW_DOMAIN=$1
[ -z "$NEW_DOMAIN" ] && echo "Usage: set_identity.sh newdomain.lol" && exit 1

OLD_DOMAIN="quickcat.club"

echo "Changing identity from $OLD_DOMAIN to $NEW_DOMAIN..."

# Update HTML
sudo sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" /media/pibulus/passport/www/html/index.html

# Update Nginx (if applicable)
# Update Field Manual
sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" ~/pibulus-os/FIELD_MANUAL.md

echo "✅ Done. Remember to update your Cloudflare / DNS settings!"
