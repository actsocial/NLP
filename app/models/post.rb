class Post < ActiveRecord::Base
  has_many :post_tag
  has_many :post_feature
end
