DB_CONFIG = {
  adapter: 'tinytds',
  user: 'sa',
  password: 'Great-Password',
  host: ENV['DB_HOST'] || 'localhost',
  database: 'example_db'
}

MASTER_DB_CONFIG = DB_CONFIG.merge(database: 'master')
