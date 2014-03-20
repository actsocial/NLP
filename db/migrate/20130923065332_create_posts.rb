class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
    	t.text :content
    	t.boolean :is_test

      t.timestamps
    end
  end
end
