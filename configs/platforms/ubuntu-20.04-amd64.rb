platform "ubuntu-20.04-amd64" do |plat|
  plat.inherit_from_default
  packages = %w(git)
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.provision_with "curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash; apt install rbenv -y; rbenv install 3.1.6; rbenv global 3.1.6; source ~/.bashrc"
end
