class CreatePrecises < ActiveRecord::Migration
  def change
    create_table :precises do |t|
      t.string :tag_id
      t.float :precise
      t.float :recall
      t.float :true_positive
      t.float :false_positive
      t.float :true_negative
      t.float :false_negative

      t.timestamps
    end
  end
end
