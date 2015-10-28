class AddValueToFnfp < ActiveRecord::Migration
  def change
  	  	add_column :fnfps, :value, :float
  end
end
