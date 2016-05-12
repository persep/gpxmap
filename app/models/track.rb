class Track < ActiveRecord::Base
	has_many :tracksegments, :dependent => :destroy
	has_many :points, :through => :tracksegments
	
	#Disable content type spoofing
	has_attached_file :gpx,validate_media_type: false 

	# Required a content_type validation, 
	# a file_name validation, 
	# or to explicitly state that they're not going to have either.
	validates_attachment_file_name :gpx, matches: /gpx\Z/ #
	validates :name, presence: true
	validates :gpx, presence: true
end
