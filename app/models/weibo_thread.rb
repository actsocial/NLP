# -*- coding: utf-8 -*-
class WeiboThread < ActiveRecord::Base
  establish_connection YAML::load(File.open('config/database.yml'))['mvpdatabase']
  self.table_name = "threads"
end