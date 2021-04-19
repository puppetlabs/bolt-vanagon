platform "osx-10.14-x86_64" do |plat|
  # If we're using a new enough Vanagon that has this method, use it
  if defined?(plat.inherit_from_default)
    plat.inherit_from_default
  # Otherwise, fall back to the old way
  else
    plat.servicetype 'launchd'
    plat.servicedir '/Library/LaunchDaemons'
    plat.codename "mojave"

    plat.provision_with 'export HOMEBREW_NO_EMOJI=true'
    plat.provision_with 'export HOMEBREW_VERBOSE=true'

    plat.provision_with 'sudo dscl . -create /Users/test'
    plat.provision_with 'sudo dscl . -create /Users/test UserShell /bin/bash'
    plat.provision_with 'sudo dscl . -create /Users/test UniqueID 1001'
    plat.provision_with 'sudo dscl . -create /Users/test PrimaryGroupID 1000'
    plat.provision_with 'sudo dscl . -create /Users/test NFSHomeDirectory /Users/test'
    plat.provision_with 'sudo dscl . -passwd /Users/test password'
    plat.provision_with 'sudo dscl . -merge /Groups/admin GroupMembership test'
    plat.provision_with 'echo "test ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/username'
    plat.provision_with 'mkdir -p /etc/homebrew'
    plat.provision_with 'cd /etc/homebrew'
    plat.provision_with 'su test -c \'echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"\''
    plat.provision_with 'sudo chown -R test:admin /Users/test/Library/'
    plat.vmpooler_template "osx-1014-x86_64"
    plat.output_dir File.join("apple", "10.14", "PC1", "x86_64")
  end
end
