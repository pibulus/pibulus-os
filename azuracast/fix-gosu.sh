#!/bin/bash
# Replace broken gosu (Go binary, hangs on kernel 6.12 arm64) with setpriv wrapper
cat > /usr/sbin/gosu << 'SCRIPT'
#!/bin/bash
user="$1"
shift
uid=$(id -u "$user" 2>/dev/null)
gid=$(id -g "$user" 2>/dev/null)
if [ -z "$uid" ]; then
    echo "gosu wrapper: unknown user $user" >&2
    exit 1
fi
exec setpriv --reuid="$uid" --regid="$gid" --init-groups "$@"
SCRIPT
chmod +x /usr/sbin/gosu
echo 'gosu replaced with setpriv wrapper'
exec /usr/local/bin/my_init --no-main-command
