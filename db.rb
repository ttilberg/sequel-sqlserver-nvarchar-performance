require_relative 'db/config'
require 'sequel'

DB = Sequel.connect DB_CONFIG, timeout: 60 * 10
