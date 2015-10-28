class AddValueToFpContents < ActiveRecord::Migration
  def change
  	add_column :fp_contents, :value, :float
  	add_column :fn_contents, :value, :float
  end
end
