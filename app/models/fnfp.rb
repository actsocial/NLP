class Fnfp < ActiveRecord::Base
  attr_accessible :flag, :post_id, :tag_id, :value
  belongs_to :post
end
