require "activerecord-import/base"
 
ActiveRecord::Import.require_adapter('mysql2')

class PostTag < ActiveRecord::Base
  self.table_name = "posts_tags"
end
