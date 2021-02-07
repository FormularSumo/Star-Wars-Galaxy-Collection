HomeState = Class{__includes = BaseState}

function HomeState:init()
    videos['Starry Sky'] = love.graphics.newVideo('Videos/Starry Sky.ogv')
    songs[0] = love.audio.newSource('Music/Imperial March piano only.oga','stream')
    songs[1] = love.audio.newSource('Music/Imperial March duet.mp3','stream')

    videos['Starry Sky']:play()
    songs[0]:play()
    queue_length = 1
    
    gui['Deck Editor'] = Button('open_deck_editor', 'Deck Editor',font80,nil,'centre',50)
    gui['Battle 1'] = Button('battle1','Battle 1',font80,nil,'centre',200)
    gui['Prebuilt Deck'] = Button('prebuilt_deck','Create a pre-built deck',font50,nil,50,120)
    gui['Toggle pause on loose focus'] = Button('toggle_pause_on_loose_focus', 'Pause on losing Window focus: ' .. tostring(pause_on_loose_focus),font50,nil,'centre',800)
end

function HomeState:update()
    testForBackgroundImageLoop(videos['Starry Sky'],0)
end

function HomeState:render()
    love.graphics.draw(videos['Starry Sky'],0,0)
end

function HomeState:exit()
    exit_state()
end