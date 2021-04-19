platform "sles-12-x86_64" do |plat|
  # If we're using a new enough Vanagon that has this method, use it
  if defined?(plat.inherit_from_default)
    plat.inherit_from_default
    packages = %w(git)
    plat.provision_with("zypper -n install -y #{packages.join(' ')}")
  # Otherwise, fall back to the old way
  else
    plat.servicedir "/usr/lib/systemd/system"
    plat.defaultdir "/etc/sysconfig"
    plat.servicetype "systemd"

    plat.add_build_repository "http://pl-build-tools.delivery.puppetlabs.net/yum/pl-build-tools-release-#{plat.get_os_name}-#{plat.get_os_version}.noarch.rpm"
    plat.provision_with "zypper -n --no-gpg-checks install -y aaa_base autoconf automake rsync gcc make rpm-build git"
    plat.install_build_dependencies_with "zypper -n --no-gpg-checks install -y"
    plat.vmpooler_template "sles-12-x86_64"
  end
end
