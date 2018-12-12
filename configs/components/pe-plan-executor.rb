component "pe-plan-executor" do |pkg, settings, platform|
  pkg.environment "GEM_HOME", settings[:gem_home]
  pkg.environment "PATH", "#{settings[:bindir]}:$$PATH"
  pkg.load_from_json('configs/components/bolt.json')
  pkg.build_requires 'puppet-agent'

  pkg.build do
    ["#{settings[:gem_build]} bolt.gemspec"]
  end

  pkg.install do
    ["#{settings[:gem_install]} bolt-*.gem"]
  end

  pkg.install_file('config/plan_config.rb', "#{settings[:prefix]}/config/plan_config.rb")

  case platform.servicetype
  when "systemd"
    pkg.add_source("file://resources/systemd/pe-plan-executor.service", sum: "4e9dcef15e682ff8a014d9f302da918a")
    pkg.add_source("file://resources/systemd/pe-plan-executor.logrotate", sum: "32955ab713783650a515ec96ecbab51a")
    pkg.install_service "../pe-plan-executor.service"
    pkg.install_configfile "../pe-plan-executor.logrotate", "/etc/logrotate.d/pe-plan-executor"
  when "sysv"
    if platform.is_rpm?
      pkg.add_source("file://resources/redhat/pe-plan-executor.init", sum: "30901f70cea4e979fb6cc928cb05090a")
      pkg.add_source("file://resources/redhat/pe-plan-executor.sysconfig", sum: "b9ceca7286d4b82f677abd3584a2ee5e")
      pkg.add_source("file://resources/redhat/pe-plan-executor.logrotate", sum: "70de9b844fcb4384e20067ae2ce2fba5")
      pkg.install_service "../pe-plan-executor.init", "../pe-plan-executor.sysconfig"
      pkg.install_configfile "../pe-plan-executor.logrotate", "/etc/logrotate.d/pe-plan-executor"
    else
      fail "This OS is not supported. See https://puppet.com/docs/pe/latest/supported_operating_systems.html#puppet-master-platforms for supported platforms"
    end
  else
    fail "need to know where to put service files"
  end

  pkg.add_postinstall_action ["install", "upgrade"], [
    "/bin/chown -R #{settings[:pe_bolt_user]}:#{settings[:pe_bolt_user]} #{settings[:homedir]}",
    "/bin/chown -R #{settings[:pe_bolt_user]}:#{settings[:pe_bolt_user]} #{settings[:plan_sysconfdir]}",
    "/bin/chown -R #{settings[:pe_bolt_user]}:#{settings[:pe_bolt_user]} #{settings[:plan_logdir]}",
    "/bin/chown -R #{settings[:pe_bolt_user]}:#{settings[:pe_bolt_user]} #{settings[:plan_rundir]}"
  ]
  pkg.add_postinstall_action ["install"], [
    "systemctl daemon-reload"
  ]
end
