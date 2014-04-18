class AddColumnToContents < ActiveRecord::Migration
  def change
  	add_column :fp_contents, :test_volume, :integer
  	add_column :fn_contents, :test_volume, :integer
  	add_column :precises, :test_volume, :integer
  end
end
