require 'sinatra'
require 'psd'
require 'json'
require 'securerandom'
require_relative 'lib/PSD_Text'


set :public_folder, 'public'

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

	return {
		image: all_psd.create_render,
		layers: all_psd.get_text
	}.to_json


end

get '/renders/:render_file_name' do 
	send_file File.join("tmp/renders-#{params[:render_file_name]}")
end
