FROM scummvm-web:latest

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends scummvm \
    && ln -sf /usr/games/scummvm /usr/local/bin/scummvm \
    && sed -i 's/readQueryVariable('\''scale'\'', false)/readQueryVariable('\''scale'\'', true)/' /usr/share/novnc/index.html \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
