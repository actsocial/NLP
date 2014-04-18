class PostFeature < ActiveRecord::Base
  attr_accessible :feature, :occurrence, :post_id
  belongs_to :post
end
