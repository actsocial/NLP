#encoding:utf-8
class Modules < ActiveRecord::Base
  self.table_name = "modules"
  establish_connection YAML::load(File.open('config/database.yml'))['mvpdatabase']
end