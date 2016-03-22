class AddColumnFolderIdOnTalks < ActiveRecord::Migration
  def change
    add_column :talks, :folder_id, :string, null: true;
  end
end
