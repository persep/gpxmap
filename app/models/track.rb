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

	before_save :parse_file #This callback executes the parser function every time we upload a file.

	private
  		def clean_paperclip_errors
    		errors.delete(:gpx_file_name)
	  	end

	  	def parse_file
	  		tempfile = gpx.queued_for_write[:original]
	  		doc = Nokogiri::XML(tempfile)
	  		parse_xml(doc)
	  	end

	  	def parse_xml(doc)
	  		doc.root.elements.each do |node|
	  			parse_tracks(node)
	  		end
	  	end

	  	def parse_tracks(node)
	  		if node.node_name.eql? 'trk'
	  			node.elements.each do |node|
	  				parse_track_segments(node)
	  			end
    		end
    	end

    	def parse_track_segments(node)
    		if node.node_name.eql? 'trkseg'
    			tmp_segment = Tracksegment.new
    			node.elements.each do |node|
    				parse_points(node,tmp_segment)
    			end
    			self.tracksegments << tmp_segment
    		end
  		end

  		def parse_points(node,tmp_segment)
  			if node.node_name.eql? 'trkpt'
  				tmp_point = Point.new
  				tmp_point.latitude = node.attr("lat")
  				tmp_point.longitude = node.attr("lon")
  				node.elements.each do |node|
  					tmp_point.name = node.text.to_s if node.name.eql? 'name'
  					tmp_point.elevation = node.text.to_s if node.name.eql? 'ele'
  					tmp_point.description = node.text.to_s if node.name.eql? 'desc'
  					tmp_point.point_created_at = node.text.to_s if node.name.eql? 'time'
  				end
  				tmp_segment.points << tmp_point
  			end
  		end
end
