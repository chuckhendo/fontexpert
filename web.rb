require 'sinatra'

set :public_folder, 'public'

get "/" do
  send_file File.join(settings.public_folder, 'index.html')
end

post "/api" do

  File.open('public/uploads/' + params['upload'][:filename], "w") do |f|
    f.write(params['upload'][:tempfile].read)
  end
  return "The file was successfully uploaded!"

end