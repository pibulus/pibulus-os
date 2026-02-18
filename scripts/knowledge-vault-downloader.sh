#!/bin/bash
# 🧠 PIBULUS Knowledge Vault Autonomous Downloader
# Downloads the complete offline knowledge archive

set -e

# Config
VAULT_ROOT="/media/pibulus/passport/Knowledge-Vault"
DOWNLOAD_DIR="/media/pibulus/passport/Knowledge-Vault/.downloads"
LOG_FILE="$VAULT_ROOT/download-log.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Create folder structure
mkdir -p "$VAULT_ROOT"/{Practical,Esoteric,Music,Culture,Security}
mkdir -p "$DOWNLOAD_DIR"

log "🧠 PIBULUS Knowledge Vault Downloader v1.0"
log "📂 Vault: $VAULT_ROOT"
log ""

# Aria2 config for speed
cat > ~/.aria2/aria2.conf << EOF
max-concurrent-downloads=3
max-connection-per-server=16
split=16
min-split-size=1M
continue=true
dir=$DOWNLOAD_DIR
log=$VAULT_ROOT/aria2.log
EOF

# Download functions
download_zim() {
    local url=$1
    local dest=$2
    local name=$(basename "$url")
    
    log "📥 Downloading: $name"
    aria2c -x 16 -s 16 "$url" -d "$dest" -o "$name"
    log "✅ Complete: $name"
}

download_torrent() {
    local url=$1
    local dest=$2
    local name=$(basename "$url" .torrent)
    
    log "🌱 Torrenting: $name"
    cd "$dest"
    wget -q "$url" -O "$name.torrent"
    transmission-cli "$name.torrent" -w "$dest" &
    log "🌱 Started: $name (background)"
}

download_ia() {
    local collection=$1
    local dest=$2
    
    log "📚 Archive.org: $collection"
    cd "$dest"
    ~/.local/bin/ia download "$collection" --no-directories
    log "✅ Complete: $collection"
}

# Main download queue
main() {
    log "=== PRACTICAL KNOWLEDGE ==="
    
    # Wikipedia (torrent - fastest)
    download_zim "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi_2025-01.zim" "$VAULT_ROOT/Practical"
    
    log ""
    log "=== MUSIC & GUITAR ==="
    
    # Guitar collections
    download_ia "guitar-lesson-books-videos" "$VAULT_ROOT/Music"
    download_ia "guitar-chords-and-tabs" "$VAULT_ROOT/Music"
    
    log ""
    log "=== ESOTERIC & OCCULT ==="
    
    # 45GB Occult torrent
    download_ia "everythingelse_20200402" "$VAULT_ROOT/Esoteric"
    
    log ""
    log "=== CULTURE & MEDIA ==="
    
    # Sci-fi collection
    download_ia "10.000.-sci-fi.and.-fantasy.-ebooks-torrent-leech" "$VAULT_ROOT/Culture"
    
    log ""
    log "🎉 Download queue complete!"
    log "📊 Check progress: tmux attach -t knowledge-vault"
}

# Run in tmux session
if [ -z "$TMUX" ]; then
    tmux new-session -d -s knowledge-vault "$0"
    log "🚀 Downloads started in tmux session 'knowledge-vault'"
    log "📊 Monitor: tmux attach -t knowledge-vault"
else
    main
fi
