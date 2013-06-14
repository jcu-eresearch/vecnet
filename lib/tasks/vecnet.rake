#
# Tasks copied from to CurateND
#

namespace :vecnet do
  namespace :app do
    desc "Raise an error unless the RAILS_ENV is development"
    task :development_environment_only do
      raise "This task is limited to the development environment" unless Rails.env == 'development'
    end

    desc "Raise an error if the RAILS_ENV is production"
    task :restrict_from_production do
      raise "This task is restricted from the production environment" if Rails.env == 'production'
    end
  end

  namespace :db do
    def pg_dump_file_path
      File.expand_path("#{Rails.root}/tmp/production_data.sql")
    end
    desc "Load data from the production database into the current environment"
    task :sync => :environment do
      Rake::Task['app:restrict_from_production'].invoke
      Rake::Task['db:download_pg_dump'].invoke
      if Rails.env == 'development'
        Rake::Task['db:optimze_pg_dump_for_sqlite'].invoke
        Rake::Task['db:recreate_with_dump'].invoke
      else
        `PGPASSWORD=#{current_db['password']} pg_restore --verbose --clean --no-acl --no-owner -h #{current_db['host']} -U #{current_db['username']} -d #{current_db['database']} #{sql_dump}`
      end

    end
    desc 'download the pg_dump content into tmp/dump.sql'
    task :download_pg_dump do
      config = Rails.application.config.database_configuration

      abort "Missing production database config" if config['dlvecnet'].blank?

      dev_config = config['development']
      prod_config = config['dlvecnet']
      abort "Development db is not sqlite3" unless dev_config['adapter'] =~ /sqlite3/
      abort "Production db is not postgresql" unless prod_config['adapter'] =~ /postgresql/
      abort "Missing ssh host" if prod_config['ssh_host'].blank?
      abort "Missing database name" if prod_config['database'].blank?

      # remove the old one
      if File.exists?(pg_dump_file_path)
        File.delete(pg_dump_file_path)
      end

      cmd = "ssh -C "
      cmd << "#{prod_config['ssh_user']}@" if prod_config['ssh_user'].present?
      cmd << "#{prod_config['ssh_host']} "
      cmd << "PGPASSWORD=#{prod_config['password']} "
      cmd << "pg_dump --data-only --inserts "
      cmd << "--username=#{prod_config['username']} #{prod_config['database']} > "
      cmd << pg_dump_file_path
      puts "Exceute #{cmd}"
      system `#{cmd}`
    end

    desc 'remove unused statements and optimze sql for SQLite'
    task :optimze_pg_dump_for_sqlite do
      result = []
      lines = File.readlines(pg_dump_file_path)
      @version = 0
      lines.each do | line |
        next if line =~ /SELECT pg_catalog.setval/ # sequence value's
        next if line =~ /SET / # postgres specific config

        if line =~ /INSERT INTO schema_migrations/
          @version = line.match(/INSERT INTO schema_migrations VALUES \('([\d]*)/)[1]
          puts("Version: #{@version}")
        end

        # replace true and false for 't' and 'f'
        line.gsub!("true","'t'")
        line.gsub!("false","'f'")
        result << line
      end

      File.open(pg_dump_file_path, "w") do |f|
        # Add BEGIN and END so we add it to 1 transaction. Increase speed!
        f.puts("BEGIN;")
        result.each{|line| f.puts(line) unless line.blank?}
        f.puts("END;")
      end
    end

    desc 'backup development.sqlite3 and create a new one with the dumped data'
    task :recreate_with_dump do
      # sqlite so backup
      database = Rails.configuration.database_configuration['development']['database']
      database_path = File.expand_path("#{Rails.root}/#{database}")
      # remove old backup
      if File.exists?(database_path + '.backup')
        File.delete(database_path + '.backup')
      end
      # copy current for backup
      FileUtils.cp database_path, database_path + '.backup' if File.exists?(database_path)

      # dropping and re-creating db
      ENV['VERSION'] = @version
      Rake::Task['db:drop'].invoke
      Rake::Task["db:migrate"].invoke

      puts "migrated to version: #{@version}"
      puts "importing..."
      # remove migration info
      system `sqlite3 #{database_path} "delete from schema_migrations;"`
      # import dump.sql
      system `sqlite3 #{database_path} ".read #{pg_dump_file_path}"`

      puts "DONE!"
      puts "NOTE: you're now migrated to version #{@version}. Please run db:migrate to apply newer migrations"
    end

  end
  # don't define the ci stuff in production...since rspec is not available
  if defined?(RSpec)
    namespace :jetty do
      JETTY_URL = 'https://github.com/ndlib/hydra-jetty/archive/xacml-updates-for-curate.zip'
      JETTY_ZIP = File.join 'tmp', JETTY_URL.split('/').last
      JETTY_DIR = 'jetty'

      desc "download the jetty zip file"
      task :download do
        puts "Downloading jetty..."
        # system "cp -rf /Users/jfriesen/Repositories/hydra-jetty #{Rails.root.join(JETTY_DIR)}"
        system "curl -L #{JETTY_URL} -o #{JETTY_ZIP}"
        abort "Unable to download jetty from #{JETTY_URL}" unless $?.success?
      end

      task :unzip do
        # Rake::Task["jetty:download"].invoke unless File.exists? JETTY_ZIP
        puts "Unpacking jetty..."
        tmp_save_dir = File.join 'tmp', 'jetty_generator'
        system "unzip -d #{tmp_save_dir} -qo #{JETTY_ZIP}"
        abort "Unable to unzip #{JETTY_ZIP} into tmp_save_dir/" unless $?.success?

        expanded_dir = Dir[File.join(tmp_save_dir, "hydra-jetty-*")].first
        system "mv #{expanded_dir} #{JETTY_DIR}"
        abort "Unable to move #{expanded_dir} into #{JETTY_DIR}/" unless $?.success?
      end

      task :clean do
        system "rm -rf #{JETTY_DIR}"
      end

      task :configure_solr do
        cp('solr_conf/solr.xml', File.join(JETTY_DIR, 'solr/development-core'), verbose: true)
        cp('solr_conf/solr.xml', File.join(JETTY_DIR, 'solr/test-core/'), verbose: true)
        FileList['solr_conf/conf/*'].each do |f|
          cp("#{f}", File.join(JETTY_DIR, 'solr/development-core/conf/'), :verbose => true)
          cp("#{f}", File.join(JETTY_DIR, 'solr/test-core/conf/'), :verbose => true)
        end
      end

      task :configure_fedora do
        cp('fedora_conf/conf/development/fedora.fcfg', File.join(JETTY_DIR, 'fedora/default/server/config/'), verbose: true)
        cp('fedora_conf/conf/test/fedora.fcfg', File.join(JETTY_DIR, 'fedora/test/server/config/'), verbose: true)
      end

    end

    desc 'Run specs on travis'
    task :travis do
      ENV['RAILS_ENV'] = 'ci'
      Rails.env = 'ci'
      Rake::Task['environment'].invoke
      Rake::Task['vecnet:jetty:download'].invoke
      Rake::Task['vecnet:jetty:clean'].invoke
      Rake::Task['vecnet:jetty:unzip'].invoke
      Rake::Task['vecnet:jetty:configure_solr'].invoke
      Rake::Task['vecnet:jetty:configure_fedora'].invoke

      jetty_params = Jettywrapper.load_config
      error = Jettywrapper.wrap(jetty_params) do
        ENV['COVERAGE'] = 'true'
        Rake::Task['vecnet:ci'].invoke
      end
      raise "test failures: #{error}" if error
    end


    desc "Execute Continuous Integration build (docs, tests with coverage)"
    task :ci do
      ENV['RAILS_ENV'] = 'ci'
      Rails.env = 'ci'
      Rake::Task['environment'].invoke
      #Rake::Task["hyhead:doc"].invoke
      #Rake::Task["jetty:config"].invoke
      #Rake::Task["db:drop"].invoke
      #Rake::Task["db:create"].invoke
      Rake::Task['db:schema:load'].invoke

      Rake::Task['vecnet:ci_spec'].invoke
      # I don't think we have any cucumber tests ATM
      #Rake::Task['cucumber'].invoke
    end

    RSpec::Core::RakeTask.new(:ci_spec) do |t|
      t.pattern = "./spec/**/*_spec.rb"
      t.rspec_opts = ['--tag ~js:true']
    end
  end

end