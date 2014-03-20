class CreateFnContents < ActiveRecord::Migration
  def change
    create_table :fn_contents do |t|
      t.string :tag_id
      t.integer :fn_count
      t.text :content

      t.timestamps
    end
  end
end
