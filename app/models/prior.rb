class Prior < ActiveRecord::Base
  attr_accessible :prior, :tag_id
  belongs_to :tag
end
