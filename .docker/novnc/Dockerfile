FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg dbus-x11 xfce4 xfce4-terminal \
    tigervnc-standalone-server tigervnc-common novnc websockify \
    fonts-liberation fonts-dejavu-core sudo \
    libxcb-cursor0 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
    libxcb-xfixes0 libxcb-sync1 libxcb-xkb1 libxkbcommon-x11-0 \
    libx11-xcb1 libxrender1 libxi6 libxtst6 libxrandr2 libxcomposite1 \
    libxcursor1 libxdamage1 libxfixes3 libxss1 libxext6 libx11-6 \
    libglib2.0-0 libnss3 libasound2t64 libegl1 libgl1 libglx0 \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
       | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && chmod 0644 /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash browser \
    && mkdir -p /config /home/browser/.vnc \
    && chown -R browser:browser /config /home/browser

COPY start-desktop.sh /usr/local/bin/start-desktop
COPY install-soulseekqt.sh /usr/local/bin/install-soulseekqt
COPY soulseekqt.desktop /usr/share/applications/soulseekqt.desktop
RUN chmod 0755 /usr/local/bin/start-desktop /usr/local/bin/install-soulseekqt \
    && chmod 0644 /usr/share/applications/soulseekqt.desktop

EXPOSE 6080
ENTRYPOINT ["/usr/local/bin/start-desktop"]
