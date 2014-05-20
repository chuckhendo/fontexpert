require 'sinatra'
require 'psd'
require 'json'
require 'securerandom'


set :public_folder, 'public'

get "/" do
	send_file File.join(settings.public_folder, 'index.html')
end

post "/api" do

	file_name = 'tmp/' + params['file'][:filename]

	File.open(file_name, "w") do |f|
		f.write(params['file'][:tempfile].read)
	end

	render_file_name = SecureRandom.urlsafe_base64(30) + '.png'

	psd = PSD.new(file_name)

	psd.parse!

	psdinfo = psd.tree.descendant_layers

	returnArray = {
		"image" => render_file_name,
		"layers" => []
	}

	psdinfo.each do |item|
		if item.type && item.type.engine_data

			data = item.type.engine_data
			text = data.EngineDict.Editor.Text
			runLengths = data.EngineDict.StyleRun.RunLengthArray
			styleRuns = data.EngineDict.StyleRun.RunArray
			fonts = data.ResourceDict.FontSet
			prevRunLength = 0
			runs = []
			runLengths.each_with_index { |runLength, index|

				run = { 
					"text" => text[prevRunLength..prevRunLength + runLength - 1].strip,
					"font-family" => fonts[styleRuns[index].StyleSheet.StyleSheetData.Font].Name,
					"color" => colorToHex(styleRuns[index].StyleSheet.StyleSheetData.FillColor.Values),
					"font-size" => "#{styleRuns[index].StyleSheet.StyleSheetData.FontSize.to_int}px"
				}

				runs.push(run)


				prevRunLength += runLength
			}

			returnItem = {
				"width" => item.layer.width, 
				"height" => item.layer.height, 
				"top" => item.layer.top, 
				"left" => item.layer.left,
				"text" => runs
			}


			returnArray["layers"].push(returnItem)

		end
	end


	psd.image.save_as_png('tmp/renders/' + render_file_name)

	content_type :json
	return returnArray.to_json

end

get '/renders/:render_file_name' do 
	send_file File.join("tmp/renders/#{params[:render_file_name]}")
end


def colorToHex(color)
	hex = ''
	color[1..3].each do |part|
		num = part * 256
		colorHex = "%x" % num
		hex = hex + colorHex 
	end
	return "##{hex}"
end