class Track < ActiveRecord::Base
	has_attached_file :gpx,validate_media_type: false

	validates_attachment_file_name :gpx, matches: /gpx\Z/
end
