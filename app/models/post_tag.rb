class PostTag < ActiveRecord::Base
  attr_accessible :post_id, :tag_id, :value
  belongs_to :post
end
