# Default settings (modify if necessary)
release="12.0-RELEASE"
arch="amd64"
jail_dir="/usr/local/jails"
zroot_dir="zroot/jails"
template_dir="$jail_dir/templates/$release"
zroot_template_dir="$zroot_dir/templates/$release"
skeleton_dir="$jail_dir/templates/skeleton-$release"
zroot_skeleton_dir="$zroot_dir/templates/skeleton-$release"


init () {
  # Create jail and template volumes
  zfs create -o mountpoint=$jail_dir $zroot_dir
  zfs create -p $zroot_template_dir
  zfs create -p $zroot_skeleton_dir

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

  # Create a snapshot (useful for rolling back for future updates)
  zfs snapshot $zroot_template_dir@patched

  # Clear the immutable flag so that the directory can be moved
  chflags -R noschg $template_dir/var

  # Move the read/write files that the thin jail will be based on
  mkdir -p $skeleton_dir/usr/ports/distfiles $skeleton_dir/home $skeleton_dir/portsbuild
  mv $template_dir/etc $skeleton_dir/etc
  mv $template_dir/usr/local $skeleton_dir/usr/local
  mv $template_dir/tmp $skeleton_dir/tmp
  mv $template_dir/var $skeleton_dir/var
  mv $template_dir/root $skeleton_dir/root

  # The thin jail will get mounted in this skeleton/ directory in the fstab file.
  # This will create symlinks with relative paths that will point corretly to the skeleton dir
  cd $template_dir
  mkdir skeleton
  ln -s skeleton/etc etc
  ln -s skeleton/home home
  ln -s skeleton/root root
  ln -s ../skeleton/usr/local usr/local
  ln -s ../../skeleton/usr/ports/distfiles usr/ports/distfiles
  ln -s skeleton/tmp tmp
  ln -s skeleton/var var

  # Set the work directory to the r/w skeleton directory so that ports can be built
  echo "WRKDIRPREFIX?=  /skeleton/portbuild" >> $skeleton_dir/etc/make.conf

  # Create a snapshot of the skeleton directory which will be cloned by new jails
  zfs snapshot $zroot_skeleton_dir@skeleton
}


create () {
  # Make sure to the fstab file in the jail.conf like so:
  # mount.fstab = "/usr/local/jails/$name.fstab";

  # Clone the skeleton directory
  zfs clone $zroot_skeleton_dir@skeleton $zroot_dir/$1

  # Generate an fstab for the jail
  (cat << EOF
$template_dir   $jail_dir/$1/             nullfs ro      0 0
$skeleton_dir   $jail_dir/$1/skeleton     nullfs rw      0 0
EOF
  ) > $jail_dir/$1.fstab
}


update () {
  # Update the system and ports
  freebsd-update -b $template_dir fetch install
  portsnap -p $template_dir/usr/ports auto
}


main () {
  case $1 in
    "init") init;;
    "create") create $2;;
    "update") update;;
    *) cat <<EOF
Usage:

  thinjail [command] [args...]

Command:

  init - Initializes the setup for thin jails
  create [jail name] - Create a jail
  update - Updates the system and ports for all thin jails

EOF
  esac
}


main "$@"
