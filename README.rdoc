== README

Uses:
ruby-2.3.1
rails 4.2.6 (the latest)

How to build the application:

http://larsgebhardt.de/parse-xml-with-ruby-on-rails-paperclip-and-nokogiri/
http://mark.kreyman.com/138/ruby/how-to-upload-and-display-csv-file-of-unknown-data-structure/
http://larsgebhardt.de/using-google-maps-api-with-ruby-on-rails/

$ mkdir gpxmap
$ cd gpxmap
$ git init
$ rvm use 2.3.1@gpxmap --create --ruby-version
$ git add .
$ git commit -m 'Add gemset and ruby version'
$ gem install bundle
$ gem install rails
$ rails new .
$ git add .
$ git commit -m 'Create rails proyect'

Add to Gemfile:
	gem 'paperclip'
	gem 'bootstrap-sass'
	gem 'bootstrap-sass-extras'
	gem 'nokogiri'

$ bundle install
$ git add .

Add to app/assets/stylesheets/application.scss:
	@import "bootstrap-sprockets";
	@import "bootstrap";

	Delete:
		*= require_tree .
 		*= require_self

$ mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss

Add to app/assets/javascripts/application.js:

	//= require bootstrap-sprockets

$ git add -A
$ git commit -m 'Setup bootstrap'

$ rails g scaffold Track name:string
$ git add .
$ git commit -m 'Scaffold Track model'

$ rails generate paperclip track gpx
$ git add .
$ git commit -m 'generate paperclip attachment'

Add app/models/tracks.rb
	has_attached_file :gpx,validate_media_type: false
	validates_attachment_file_name :gpx, matches: /gpx\Z/

$ git add .
$ git commit -m 'Add attachment to track model'
$ rake db:migrate

$ rails g model Tracksegment track:references
$ git add .
$ git commit -m 'Add Tracksegment model'

$ rails g model Point tracksegment:references name:string latitude:float \
longitude:float elevation:float description:string point_created_at:datetime
$ git add .
$ git commit -m 'Add Point model'

$ rake db:migrate

$ rails g bootstrap:install
$ git add .
$ git commit -m 'Generate bootstrap locale'

$ rails g bootstrap:themed Tracks -f
$ git add .
$ git commit -m 'Generate bootstrap scaffold view'

Add app/models/track.rb
	has_many :tracksegments, :dependent => :destroy
	has_many :points, :through => :tracksegments

Add app/models/tracksegment.rb
	has_many :points, :dependent => :destroy

$ git add .
$ git commit -m 'Add associations to track and tracksegment'

Add app/controllers/tracks_controller.rb
	def track_params
      params.require(:track).permit(:name, :gpx)
    end

$ git add .
$ git commit -m 'Add gpx attachment to trust param'

Add in app/stylesheets/application.scss
	@import 'scaffolds';

$ git add .
$ git commit -m 'Add scaffolds css'

Add in app/views/layouts/application.html.erb
	<div class="container">
		<%= yield %>
	</div>
$ git add .
$ git commit -m 'Add bootstrap container class'

Add to views/tracks/_form.html.erb:
	<%= form_for @track, html: { class: 'form-horizontal' } do |f| %>
	  <% if @track.errors.any? %>
	    <div id="error_explanation">
	        <h2><%= pluralize(@track.errors.count, "error") %> prohibited from being saved:</h2>
	        <ul>
	          <% @track.errors.full_messages.each do |msg| %>
	          <li><%= msg %></li>
	          <% end %>
	        </ul>
	    </div>
	  <% end %>
	  
	  <div class="form-group">
	    <%= f.label :name, class: 'control-label col-md-2' %>
	    <div class="col-md-10">
	      <%= f.text_field :name, class: 'text_field form-control' %>
	    </div>
	  </div>
	  <div class="form-group">
	    <%= f.label :gpx, class: 'control-label col-md-2' %>
	    <div class="col-md-10">
	      <%= f.file_field :gpx %>
	    </div>
	  </div>
	  
	    <div class="form-group">
	    <div class='col-md-offset-2 col-md-10'>
	      <%= f.submit nil, class: 'btn btn-primary' %>
	      <%= link_to t('.cancel', default: t("helpers.links.cancel")),
	                  tracks_path, class: 'btn btn-default' %>
	    </div>
	  </div>
	<% end %>

$ git add .
$ git commit -m 'Add form fields'

Add to app/models/track.rb
	#Disable content type spoofing
	has_attached_file :gpx,validate_media_type: false 

	# Required a content_type validation, 
	# a file_name validation, 
	# or to explicitly state that they're not going to have either.
	validates_attachment_file_name :gpx, matches: /gpx\Z/ #
	validates :name, presence: true
	validates :gpx, presence: true

$ git add .
$ git commit -m 'Add form validations'

Add to app/models/track.rb
	# This is because paperclip duplicates error messages with the file_name validator 
	# or any other validator See: https://github.com/thoughtbot/paperclip/pull/1554
	after_validation :clean_paperclip_errors

  	def clean_paperclip_errors
    	errors.delete(:gpx_file_name)
  	end

$ git add .
$ git commit -m 'Remove duplicate paperclip errors'

Add to app/models/track.rb
make private method

private	
	def clean_paperclip_errors
    	errors.delete(:gpx_file_name)
  	end

Add callback 
	before_save :parse_file

Add private methods 
		def parse_file
	  		tempfile = gpx.queued_for_write[:original]
	  		byebug
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

Add app/views/tracks/show.html.erb

<table class="table table-striped">
    <thead>
      <tr>
        <th>ID</th>
        <th>Point No.</th>
        <th>Latitude</th>
        <th>Longitude</th>
        <th>Elevation</th>
        <th>Description</th>
        <th>Time</th>
      </tr>
    </thead>
    <tbody>
      <% @track.points.each do |point| %>
        <tr>
          <td><%= point.id %></td>
          <td><%= point.name %></td>
          <td><%= point.latitude %></td>
          <td><%= point.longitude %></td>
          <td><%= point.elevation %></td>
          <td><%= point.description %></td>
          <td><%= point.point_created_at %></td>
        </tr>
      <% end %>
    </tbody>
  </table>

Add in config/routes.rb:
	root 'tracks#index'

Add to Gemfile:
	gem 'polylines'

$ bundle install

Add to models/point.rb:
  def latlng
  	[self.latitude,self.longitude]
  end

Add to models/track.rb:

	def polyline_points
		self.points.map(:latlng)
	end
	
	def polyline
		Polylines::Encoder.encode_points(self.polyline_points)
	end

Add controller/tracks_controller.rb

def show
    @track = Track.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      #format.json { render :json => @track}
      format.json {
        render :json => @track.to_json(:methods => [:polyline],:only => [:name])
      }
    end
  end

  Add in helpers/tracks_helper.rb

  module TracksHelper
	def google_api_url
		"http://maps.googleapis.com/maps/api/js"
	end

	def google_api_access
		"#{google_api_url}?key=#{google_maps_api_key}&libraries=geometry&sensor=false"
	end

	def google_maps_api
		content_tag(:script,:type => "text/javascript",:src => google_api_access) do
		end
	end
end

Create file view/layouts/tracks.html.erb

<!DOCTYPE html>
<html>
<head>
  <title>Gpxmap 2</title>
  <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= google_maps_api %>
  <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
  <%= csrf_meta_tags %>
</head>
<body>

<div class="container">
	<%= yield %>
</div>
</body>
</html>

In app/assets/javascripts/tracks.coffee

gm_init = ->
	gm_center = new google.maps.LatLng(54, 12)
	gm_map_type = google.maps.MapTypeId.ROADMAP
	map_options = {center: gm_center, zoom: 8, mapTypeId: gm_map_type}
	new google.maps.Map(@map_canvas,map_options);
$ ->
	map = gm_init()

Added some bottom margin to views/tracks/show.html.erb
	<div id="map_canvas" style="height: 600px; margin-bottom: 20px"></div>

Add to views/tracks/index.html.erb

	<%= link_to track_path(track), class: 'btn btn-xs', title: "#{ t('.show', default: t('helpers.links.show')) }", 'data-no-turbolink':  true do %

So that the page loas the GM js to display the map

$ git add .
$ git commit -m 'Solution for turbolinks js not loading'

Add to helpers/tracks_helper.rb
	def track_id_to_js(id)
		content_tag(:script, :type => "text/javascript") do
			"var js_track_id = "+id.to_s;
		end
	end

Add views/layouts/application.html.erb
	
	<%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= google_maps_api %>
  <%= track_id_to_js(@track.id) if @track %>

Add assets/javascript/tracks.coffee

load_track = (id,map) ->
  callback = (data) -> display_on_map(data,map)
  $.get '/tracks/'+id+'.json', {}, callback, 'json'

display_on_map = (data,map) ->
  decoded_path = google.maps.geometry.encoding.decodePath(data.polyline)
  path_options = { path: decoded_path, strokeColor: "#FF0000",strokeOpacity: 0.5, strokeWeight: 5}
  track_path = new google.maps.Polyline(path_options)
  track_path.setMap(map)
  map.fitBounds(calc_bounds(track_path));

calc_bounds = (track_path) ->
  b = new google.maps.LatLngBounds()
  gm_path = track_path.getPath()
  path_length = gm_path.getLength()
  i = [0,(path_length/3).toFixed(0),(path_length/3).toFixed(0)*2]
  b.extend(gm_path.getAt(i[0]))
  b.extend(gm_path.getAt(i[1]))
  b.extend(gm_path.getAt(i[2])

$ ->
  map = gm_init()
  load_track(js_track_id,map

$ git add .
$ git commit -m 'Add track display'

Removed api key assets/helpers/tracks_helper.rb and changed google maps url to version 3

def google_api_access
		"#{google_api_url}?v=3.exp&libraries=geometry"
	end

$ git add .
$ git commit -m 'Remove v2 api for google maps'