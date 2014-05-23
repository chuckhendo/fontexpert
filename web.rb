require 'sinatra'
require 'json'
require 'mongoid'
require_relative 'lib/PSD_Text'


set :public_folder, 'public'

Mongoid.load!("config/mongoid.yml")

# Separate session class/document for the stored PSD - probably not the best way to be doing this...
class Session
  include Mongoid::Document
  field :layer_data, type: Hash
end



get "/" do
	send_file File.join(settings.public_folder, 'index.html')
end

post "/api" do
	content_type :json

	file_name = 'tmp/' + params['file'][:filename]

	File.open(file_name, "w") do |f|
		f.write(params['file'][:tempfile].read)
	end

	all_psd = PSD_Text.new(file_name)

	render = all_psd.create_render
	return_hash = {
		image: "#{render}.png",
		id: render,
		layers: all_psd.get_text
	}

	session = Session.new

	session.layer_data = return_hash
	session.save!

	return return_hash.to_json
end

get '/renders/:render_file_name' do 
	send_file File.join("tmp/renders-#{params[:render_file_name]}")
end
