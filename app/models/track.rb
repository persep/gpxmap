class Track < ActiveRecord::Base
	has_many :tracksegments, :dependent => :destroy
	has_many :points, :through => :tracksegments
	
	#Disable content type spoofing
	has_attached_file :gpx,validate_media_type: false 

	# Required a content_type validation, 
	# a file_name validation, 
	# or to explicitly state that they're not going to have either.
	
	validates :name, presence: true
	validates :gpx, presence: true
	validates_attachment_file_name :gpx, matches: /gpx\Z/ #

	# This is because paperclip duplicates error messages with the file_name validator 
	# or any other validator See: https://github.com/thoughtbot/paperclip/pull/1554
	after_validation :clean_paperclip_errors

	before_save :parse_file

	private
  		def clean_paperclip_errors
    		errors.delete(:gpx_file_name)
	  	end
end
