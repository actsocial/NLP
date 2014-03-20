class CreateLikelihoods < ActiveRecord::Migration
  def change
    create_table :likelihoods do |t|
      t.string :tag_id
      t.string :feature
      t.float :likelihood

      t.timestamps
    end
  end
end
