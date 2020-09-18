task :env do
  require_relative 'db/config'
  require 'sequel'
end

namespace :db do
  desc 'Wait for SQL Server to be available. Helpful for CI and docker-compose'
  task can_login: :env do
    puts "Waiting for SQL Server to be available."
    attempts = 0
    begin
      Sequel.connect(MASTER_DB_CONFIG) { puts "Ready." }

    rescue Sequel::DatabaseConnectionError => e
      if e.message =~ /unavailable.*exist/i
        attempts += 1
        raise if attempts == 10
        sleep 2
        retry
      end
    end
  end

  desc "Create DB"
  task :create => [:env, :can_login] do
    Sequel.connect(MASTER_DB_CONFIG) do |db|
      db.execute <<~SQL
        CREATE DATABASE example_db
      SQL
      puts "Created `example_db` DB"

    rescue TinyTds::Error => e
      raise e unless e.message =~ /already exists/
      puts "DB `example_db` already existed."
    end
  end

  desc "Drop DB"
  task :drop => [:env, :can_login] do
    Sequel.connect(MASTER_DB_CONFIG) do |db|
      db.execute <<~SQL
        DROP DATABASE example_db
      SQL
      puts "Dropped `example_db` DB"

    rescue TinyTds::Error => e
      raise e unless e.message =~ /it does not exist/
      puts "DB `example_db` does not exist."
    end
  end

  desc "Run migrations"
  task :migrate => [:create] do
    require_relative 'db'
    Sequel.extension :migration
    v = Sequel::Migrator.run(DB, "db/migrations")
    puts "Migrated `example_db` to #{v}"
  end

  desc "Benchmark"
  task :benchmark => [:migrate] do
    require 'benchmark'
    require_relative 'db'

    n = 10
    Benchmark.bmbm do |x|
      x.report("where name = N'12345' (unicode)") do
        n.times do
          DB.execute("select name from things where name = N'12345'")
        end
      end

      x.report("where name = '12345' (not unicode)") do
        n.times do
          DB.execute("select name from things where name = '12345'")
        end
      end

      x.report("Sequel .where uses N'' strings by default") do
        # Set the setting anyway to ensure it's on, given that one report turns it off.
        DB.mssql_unicode_strings = true
        n.times do
          DB[:things].where(name: '12345').all
        end
      end

      x.report("Sequel .where without N'' strings") do
        DB.mssql_unicode_strings = false
        n.times do
          DB[:things].where(name: '12345').all
        end
      end

      x.report("Sequel .where without N'' via dataset method") do
        # Set the setting back to default, given that one report turns it off.
        DB.mssql_unicode_strings = true
        n.times do
          DB[:things].where(name: '12345').with_mssql_unicode_strings(false).all
        end
      end      
    end
  end
end
