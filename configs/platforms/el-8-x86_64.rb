platform "el-8-x86_64" do |plat|
  # If we're using a new enough Vanagon that has this method, use it
  if defined?(plat.inherit_from_default)
    plat.inherit_from_default
    packages = %w(git)
    plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
    # Otherwise, fall back to the old way
  else
    plat.servicedir "/usr/lib/systemd/system"
    plat.defaultdir "/etc/sysconfig"
    plat.servicetype "systemd"

    plat.provision_with "rpm --import http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs"
    plat.provision_with "yum install --assumeyes autoconf automake rsync gcc createrepo make rpmdevtools rpm-libs yum-utils rpm-sign libtool git"
    plat.install_build_dependencies_with "yum install --assumeyes"
    plat.vmpooler_template "redhat-8-x86_64"
  end
end
