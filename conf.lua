function love.conf(t)
    -- folder that app data is stored in
    t.identity = 'Galaxy Collection'

    -- app window title
    t.window.title = 'Galaxy Collection'

    --initialise window
    t.window.width = 0
    t.window.height = 0
    t.window.fullscreen = true
    t.window.resizable = true
    t.window.vsync = 1

    --Disable unused modules
    t.accelerometerjoystick = false
    t.modules.physics = false
end