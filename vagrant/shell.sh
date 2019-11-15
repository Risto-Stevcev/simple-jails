cp /tmp/.zshrc /root/
cp /tmp/.zshrc /home/vagrant/
chown vagrant /home/vagrant/.zshrc
chsh -s /usr/local/bin/zsh root
chsh -s /usr/local/bin/zsh vagrant

export TERM=xterm
