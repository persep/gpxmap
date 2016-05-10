class AddAttachmentGpxToTracks < ActiveRecord::Migration
  def self.up
    change_table :tracks do |t|
      t.attachment :gpx
    end
  end

  def self.down
    remove_attachment :tracks, :gpx
  end
end
