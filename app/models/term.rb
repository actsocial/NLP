class Term < ActiveRecord::Base
	attr_accessible :count, :word, :post_id, :post_time
end
