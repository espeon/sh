FROM archlinux:base-devel

RUN echo '[multilib]' >> /etc/pacman.conf && \
    echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf

USER root

# update to latest
RUN pacman -Syu --noconfirm

# install needed packages
RUN pacman -Sy --noconfirm --needed git base-devel zsh

# add default user
RUN /usr/sbin/groupadd --system sudo && \
    /usr/sbin/useradd -m --groups sudo nat && \
    passwd -d nat && \
    chmod +w /home/nat && \
    /usr/sbin/sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers && \
    /usr/sbin/echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&\
    /usr/sbin/echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# install yay
RUN git clone https://aur.archlinux.org/yay-bin.git;\
    chmod -R 777 yay-bin;
RUN  cd yay-bin && sudo -u nobody makepkg -s
RUN cd /yay-bin/pkg/yay-bin/usr/bin && install yay /usr/bin/yay

# install other packages using yay
RUN yay -Sy --noconfirm --needed \
    neovim \
    git \
    nano

# switch users (we don't need to install as root anymore)
USER nat

RUN sudo chmod -R +777 /home/nat

# oh my zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# PL10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# asdf (for node etc version management)
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf && \
    cd ~/.asdf && \
    git checkout -d "$(git describe --abbrev=0 --tags)" && \
    sed -i 's/plugins=\(.*\)/plugins=\(git asdf archlinux\)/' ~/.zshrc

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443


SHELL [ "/bin/zsh", "-c" ]
ENTRYPOINT [ "/bin/zsh", "-l" ]