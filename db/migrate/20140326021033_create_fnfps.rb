class CreateFnfps < ActiveRecord::Migration
  def change
    create_table :fnfps do |t|
      t.integer :post_id
      t.string :tag_id
      t.string :flag

      t.timestamps
    end
  end
end
