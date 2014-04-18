class CreatePostTags < ActiveRecord::Migration
  def change
    create_table :post_tags do |t|
      t.integer :post_id
      t.string :tag_id
      t.integer :value

      t.timestamps
    end
  end
end
