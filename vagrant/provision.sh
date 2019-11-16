pkg update
pkg install -y neovim xterm zsh

mv /tmp/thinjail.sh /usr/local/bin/thinjail
mv /tmp/clonejail.sh /usr/local/bin/clonejail
mv /tmp/jail.conf /etc/

chmod a+x /usr/local/bin/thinjail
chmod a+x /usr/local/bin/clonejail

# Initializes the base template and skeleton for future thin jails
thinjail init

# These create the thin jail directories and fstab files
thinjail create foo
thinjail create bar

# Create the jails
jail -c foo
jail -c bar



# Initializes the base template for future clone jails
clonejail init

# These create the clone jail directories
clonejail create baz
clonejail create qux

# Create the jails
jail -c baz
jail -c qux
