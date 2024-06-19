require 'love.image'
local running = true
while running do
    local imagePath = love.thread.getChannel("imageDecoderQueue"):pop()
    if imagePath then --Check if there are any tasks left
        love.thread.getChannel("imageDecoderOutput"):push({imagePath,love.image.newImageData(imagePath .. ".png")}) --Maybe change .png to be passed directly
    else
        running = false
    end
end