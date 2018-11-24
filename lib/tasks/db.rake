namespace :db do
  namespace :ridgepole do
    desc "Run ridgepole --apply"
    task :apply, [:rails_env] => :environment do |t, args|
      Dir.chdir Rails.root
      rails_env = args.rails_env || Rails.env
      puts "rails_env=#{rails_env}"
      res, st = Open3.capture2e("ridgepole --env #{rails_env} --dump-with-default-fk-name --config config/database.yml --apply -f db/Schemafile")
      puts res

      raise "Ridgepole apply error" unless st.success?
    end
  end
end
