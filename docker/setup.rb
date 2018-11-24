require 'fileutils'
require 'erb'

Dir.chdir(File.expand_path("../", __dir__))

system('erb docker-database.yml.erb > config/database.yml')
