class CreatePriors < ActiveRecord::Migration
  def change
    create_table :priors do |t|
      t.string :tag_id
      t.float :prior

      t.timestamps
    end
  end
end
