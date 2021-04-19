platform "debian-10-amd64" do |plat|
  # If we're using a new enough Vanagon that has this method, use it
  if defined?(plat.inherit_from_default)
    plat.inherit_from_default
    packages = %w(git)
    plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  # Otherwise, fall back to the old way
  else
    plat.servicedir "/lib/systemd/system"
    plat.defaultdir "/etc/default"
    plat.servicetype "systemd"
    plat.codename "buster"
    packages = %w[build-essential devscripts make quilt pkg-config debhelper rsync fakeroot libssl-dev ruby-full rubygems git]
    plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
    plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends --force-yes "
    plat.vmpooler_template "debian-10-x86_64"
  end
end
