component "rubygem-puppet-resource_api" do |pkg, settings, platform|
  pkg.version "1.8.0"
  pkg.md5sum "f5f8d8414c27f6f015b70f12a0c27fe83878bbac346746d82c27858acf7378f5"
  instance_eval File.read('configs/components/_base-rubygem.rb')
end
