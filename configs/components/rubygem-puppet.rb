component "rubygem-puppet" do |pkg, settings, platform|
  pkg.version "6.4.0"
  pkg.md5sum "b3f9716c9c8889f95c66b33bb7445f63"
  #instance_eval File.read('configs/components/_base-rubygem.rb')
  pkg.environment "GEM_HOME", settings[:gem_home]
  gemname = pkg.get_name.gsub('rubygem-', '')
  pkg.url "http://builds.delivery.puppetlabs.net/puppet/6.4.0/artifacts/puppet-6.4.0.gem"
  pkg.mirror "#{settings[:buildsources_url]}/#{gemname}-#{pkg.get_version}.gem"

  pkg.install do
    "#{settings[:gem_install]} #{gemname}-#{pkg.get_version}.gem"
  end
end
