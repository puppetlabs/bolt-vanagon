platform "el-6-x86_64" do |plat|
  # If we're using a new enough Vanagon that has this method, use it
  if defined?(plat.inherit_from_default)
    plat.inherit_from_default
    packages = %w(git)
    plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
    # Otherwise, fall back to the old way
  else
    plat.servicedir "/etc/rc.d/init.d"
    plat.defaultdir "/etc/sysconfig"
    plat.servicetype "sysv"

    plat.add_build_repository "http://pl-build-tools.delivery.puppetlabs.net/yum/pl-build-tools-release-#{plat.get_os_name}-#{plat.get_os_version}.noarch.rpm"
    plat.provision_with "rpm --import http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs"
    plat.provision_with "yum install --assumeyes autoconf automake createrepo rsync gcc make rpmdevtools rpm-libs yum-utilsi autogen git"
    plat.install_build_dependencies_with "yum install --assumeyes"
    plat.vmpooler_template "redhat-6-x86_64"
  end
end
