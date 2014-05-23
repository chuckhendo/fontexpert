# encoding: utf-8


require 'psd'
require 'json'
require 'securerandom'



class PSD_Text
	def initialize(file_name)
		@psd = PSD.new(file_name)
		@psd.parse!
		@psd_tree = @psd.tree
	end
	
	def create_render
		# create tmp directory if it doesn't already exist
		Dir.mkdir 'tmp' unless File.directory?('tmp')
		
		# generate a random filename for our render, and save it to disk
		render_file_name = SecureRandom.urlsafe_base64(30)
		@psd.image.save_as_png("tmp/renders-#{render_file_name}.png")
		return render_file_name
	end
	
	def get_text
		text_layers = []
		
		parse_layer(@psd_tree) { |layer| text_layers << layer }

		return text_layers
		
	end
	
private
	def parse_layer(layer, &block)
		# If this layer is a group of layers and is visible, recall this function with each child
		if layer.has_children? && (layer.root? || layer.visible)
			layer.children.each do |sublayer|
				parse_layer(sublayer, &block)
			end
		# If this layer is visible and has text, return the layer data
		elsif layer.type && layer.type.engine_data && layer.visible
			text_data = layer.type.engine_data

			text = text_data.EngineDict.Editor.Text
			
			runLengths = text_data.EngineDict.StyleRun.RunLengthArray
			styleRuns = text_data.EngineDict.StyleRun.RunArray
			fonts = text_data.ResourceDict.FontSet
			prevRunLength = 0
			runs = []
			runLengths.each_with_index { |runLength, index|

				run = { 
					"text" => text[prevRunLength..prevRunLength + runLength - 1],
					"font_info" => {
						"font-family" => fonts[styleRuns[index].StyleSheet.StyleSheetData.Font].Name,
						"color" => color_to_hex(styleRuns[index].StyleSheet.StyleSheetData.FillColor.Values),
						"font-size" => "#{styleRuns[index].StyleSheet.StyleSheetData.FontSize.to_int}px"
					}
				}


				if runs.length > 0 && runs[-1].has_key?("font_info") && run["font_info"] != runs[-1]["font_info"]
					runs.push(run)
					runs[-1]["text"].strip!
				elsif runs.length == 0
					runs.push(run)
				else 
					runs[-1]["text"] += run["text"]
				end

				prevRunLength += runLength
			}

			layer_data = {
				"width" => layer.width, 
				"height" => layer.height, 
				"top" => layer.top, 
				"left" => layer.left,
				"name" => layer.name,
				"text" => runs
			}
		
			block.call(layer_data)

		end
	end
	
	def color_to_hex(color)
		hex = ''
		color[1..3].each do |part|
			num = part * 256
			colorHex = "%x" % num
			hex = hex + colorHex 
		end
		return "##{hex}"
	end
end

