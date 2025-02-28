FROM mcr.microsoft.com/devcontainers/base:jammy

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    tini \
    dbus-user-session \
    gnome-keyring \
    libsecret-1-0 \
    libsecret-tools \
    fzf

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --tag 1.40.0 --to /usr/local/bin

COPY --chown=vscode:vscode --chmod=755 unlock-keyring.sh /home/vscode/.local/bin/

RUN echo '[ -f "$HOME/.dbusenv" ] && . "$HOME/.dbusenv"' >> /home/vscode/.profile
RUN echo '[ -f "$HOME/.dbusenv" ] && . "$HOME/.dbusenv"' >> /home/vscode/.bashrc

# More info: https://code.visualstudio.com/remote/advancedcontainers/start-processes
COPY --chmod=755 docker-entrypoint.sh /

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
CMD [ "sleep", "infinity" ]
