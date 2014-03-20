class CreateFpContents < ActiveRecord::Migration
  def change
    create_table :fp_contents do |t|
      t.string :tag_id
      t.integer :fp_count
      t.text :content

      t.timestamps
    end
  end
end
