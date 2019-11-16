# Default settings (modify if necessary)
release="12.0-RELEASE"
arch="amd64"
jail_dir="/usr/local/jails"
zroot_dir="zroot/jails"
template_dir="$jail_dir/templates/$release-clone"
zroot_template_dir="$zroot_dir/templates/$release-clone"


init () {
  # Create jail and template volumes
  zfs create -o mountpoint=$jail_dir $zroot_dir
  zfs create -p $zroot_template_dir

  # Fetch base and ports
  for set in base ports; do
    fetch https://ftp.freebsd.org/pub/FreeBSD/releases/$arch/$release/$set.txz -o /tmp
    tar xvf /tmp/$set.txz -C $template_dir
  done

  # Copy DNS and time config from host
  cp /etc/resolv.conf $template_dir/etc/resolv.conf
  cp /etc/localtime $template_dir/etc/localtime

  # Update template
  freebsd-update -b $template_dir -f $template_dir/etc/freebsd-update.conf fetch install
  portsnap -p $template_dir/usr/ports auto

  # Create a snapshot (useful for rolling back for future updates)
  zfs snapshot $zroot_template_dir@patched
}


create () {
  # Clone the skeleton directory
  zfs clone $zroot_template_dir@patched $zroot_dir/$1
}


main () {
  case $1 in
    "init") init;;
    "create") create $2;;
    *) cat <<EOF
Usage:

  clonejail [command] [args...]

Command:

  init - Initializes the setup for thin jails
  create [jail name] - Create a jail

EOF
  esac
}


main "$@"
