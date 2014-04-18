class CreatePostFeatures < ActiveRecord::Migration
  def change
    create_table :post_features do |t|
      t.integer :post_id
      t.string :feature
      t.integer :occurrence

      t.timestamps
    end
  end
end
