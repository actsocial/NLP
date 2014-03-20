class Precise < ActiveRecord::Base
  attr_accessible :false_negative, :false_positive, :precise, :recall, :tag_id, :true_negative, :true_positive, :test_volume
end
