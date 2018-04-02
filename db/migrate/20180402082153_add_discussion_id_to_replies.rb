class AddDiscussionIdToReplies < ActiveRecord::Migration[5.1]
  def change
    add_column :replies, :discussin_id, :integer
  end
end
