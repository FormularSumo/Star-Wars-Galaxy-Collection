GameState = Class{__includes = BaseState}

function GameState:init()
    P1deck = {}
    P2deck = {}
    self.images = {}
    self.imagesInfo = {}
    self.gamespeed = 1
    self.Nextcards = {
        [0] = 18,
        [1] = 19,
        [2] = 20,
        [3] = 21,
        [4] = 22,
        [5] = 23,
    }
    self.currentRows = {
        [0] = 0,
        [1] = 1,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 5,
    }
    self.initialRows = {
        [0] = 0,
        [1] = 1,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 5,
    }
    self.rowsMoved = {
        [0] = false,
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
    }

    self.P1length = 0
    for k, pair in pairs(P1deckCards) do
        if k > self.P1length then
            self.P1length = k
        end
    end
    self.P2length = P2deckCards('max')

    for i=0,math.min(18,math.max(self.P1length,self.P2length)) do
        if P1deckCards[i] then
            P1deck[i] = Card(P1deckCards[i],1,i,-1 - math.floor((i)/6),self.images,self.imagesInfo)
        end
        if P2deckCards(i) then
            P2deck[i] = Card(P2deckCards(i),2,i,12 + math.floor((i)/6),self.images,self.imagesInfo)
        end
    end
    for k, pair in pairs(self.imagesInfo) do
        love.thread.getChannel("imageDecoderQueue"):push(k) --It's unnecessary to check here if images have already been pushed, as this is the first time they any are pushed
        pair[2] = true --Mark image as pushed
    end
    for i = 1,#imageDecoderThreads do
        imageDecoderThreads[i]:start()
    end
    self.P1angle = math.rad(210)
    self.P2angle = math.rad(150)
    self.next = next
end

function GameState:enter(Background)
    if love.filesystem.getInfo('Backgrounds/' .. Background[1] .. '.jpg') then
        background = love.graphics.newImage('Backgrounds/' .. Background[1] .. '.jpg')
    else
        background = love.graphics.newImage('Backgrounds/' .. Background[1] .. '.png')
    end

    songs[0] = love.audio.newSource('Music/' .. Background[5],'stream')

    if Background[2] == nil then r = 0 else r = Background[2] end
    if Background[3] == nil then g = 0 else g = Background[3] end
    if Background[4] == nil then b = 0 else b = Background[4] end
    gui[1] = Button(pause,'Pause',font100,nil,1591,0,r,g,b) -- 35 pixels from right as font100:getWidth('Pause') = 294
    gui[2] = Slider(1591,130,300,16,function(percentage) self.gamespeed = percentage * 4 end,0.3,0.3,0.3,r,g,b,0.25,0.25)
    gui['SpeedLabel'] = Text('Speed',font80,'centre',410,r,g,b,false)
    gui[3] = Slider('centre',570,300,16,function(percentage) love.audio.setVolume(percentage) Settings['volume_level'] = percentage end,0.3,0.3,0.3,r,g,b,Settings['volume_level'],0.5,function() binser.writeFile('Settings.txt',Settings) end,false,false)
    gui['VolumeLabel'] = Text('Volume',font80,'centre',600,r,g,b,false)
    gui[4] = Button(function() gStateMachine:change('HomeState') end,'Main Menu',font80,nil,'centre',1080-220-font80:getHeight('Main Menu'),r,g,b,nil,false)

    self.timer = 0 --All levels have a 1 second delay before spawing characters
    self.moveAimTimer = self.timer
    self.attackTimer = self.timer - 0.9
    love.timer.step()
end

function GameState:Move()
    self:RowsRemaining(P1deck)
    self:RowsRemaining(P2deck)
    if self.P1rowsRemaining == 1 and self.P2rowsRemaining == 1 then
        if not self.P1rows[3] and self.P2rows[3] then
            if self.P1rows[3] then
                self:MoveUp(P1deck,3)
            end
            if self.P2rows[3] then
                self:MoveUp(P2deck,3)
            end
        end
        if (self.P1rows[2] or self.P1rows[3]) and (self.P2rows[2] or self.P2rows[3]) then
            return
        end 
    end
   
    self.rows = self.P1rows
    self.enemyRows = self.P2rows
    self.rowsRemaining = self.P2rowsRemaining
    self:Move2(P1deck)
    self.rows = self.P2rows
    self.enemyRows = self.P1rows
    self.rowsRemaining = self.P1rowsRemaining
    self:Move2(P2deck)
end

function GameState:RowsRemaining(deck)
    self.rowsRemaining = 0
    self.rows = {
        [0] = false,
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false
    }

    for k, pair in pairs(deck) do
        if self.rows[pair.row] == false then
            self.rows[pair.row] = true
            self.rowsRemaining = self.rowsRemaining + 1
            if self.rowsRemaining == 6 then break end
        end
    end

    if deck == P1deck then
        self.P1rows = self.rows
        self.P1rowsRemaining = self.rowsRemaining
    else
        self.P2rows = self.rows
        self.P2rowsRemaining = self.rowsRemaining
    end
end

function GameState:Move2(deck)
    self.rowsMoved = {
        [0] = false,
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
    }
    if self.rows[0] == false and self.rows[1] == false and self.rows[5] == true then
        self:MoveUp(deck,2)
        self:MoveUp(deck,3)
        self:MoveUp(deck,4)
        self:MoveUp(deck,5)
    elseif self.rows[4] == false and self.rows[5] == false and self.rows[0] == true then
        self:MoveDown(deck,3)
        self:MoveDown(deck,2)
        self:MoveDown(deck,1)
        self:MoveDown(deck,0)
    else
        if self.rows[2] == false then
            if (self.rows[0] == false and self.rows[5] == true) or (self.rows[1] == false and self.rows[4] == true) or ((self.rowsRemaining == 1 and self.enemyRows[2]) and (self.rows[5] or not self.rows[0] and self.rows[4])) then
                self:MoveUp(deck,3)
                self:MoveUp(deck,4)
                self:MoveUp(deck,5)
            else
                self:MoveDown(deck,1)
                self:MoveDown(deck,0)
            end
        end
        if self.rows[1] == false then 
            self:MoveDown(deck,0)
        end
        if self.rows[3] == false then
            if (self.rows[5] == false and self.rows[0] == true) or (self.rows[4] == false and self.rows[1] == true) or (self.rowsRemaining == 1 and self.enemyRows[3])  then
                self:MoveDown(deck,2)
                self:MoveDown(deck,1)
                self:MoveDown(deck,0)
            else
                self:MoveUp(deck,4)
                self:MoveUp(deck,5)
            end
        end
        if self.rows[4] == false then
            self:MoveUp(deck,5)
        end
    end
end

function GameState:MoveDown(deck,row)
    if not self.rowsMoved[row] then
        self.rowsMoved[row] = true
        if deck == P1deck then
            if not self.P1rows[row] then return end
        else
            if not self.P2rows[row] then return end
            self.currentRows[self.initialRows[row]] = self.currentRows[self.initialRows[row]] + 1

            self.initialRows[row+1] = self.initialRows[row]
            self.initialRows[row] = nil
        end
        for k, pair in pairs(deck) do
            if deck[k].row == row then
                deck[k].number = deck[k].number + 1
                deck[k].targetY = deck[k].targetY + 180
                deck[k].row = row + 1
                deck[k+1] = deck[k]
                deck[k] = nil
            end
        end
    end
end

function GameState:MoveUp(deck,row)
    if not self.rowsMoved[row] then
        self.rowsMoved[row] = true
        if deck == P1deck then
            if not self.P1rows[row] then return end
        else
            if not self.P2rows[row] then return end
            self.currentRows[self.initialRows[row]] = self.currentRows[self.initialRows[row]] - 1

            self.initialRows[row-1] = self.initialRows[row]
            self.initialRows[row] = nil
        end 
        for k, pair in pairs(deck) do
            if deck[k].row == row then
                deck[k].number = deck[k].number - 1
                deck[k].targetY = deck[k].targetY - 180
                deck[k].row = row - 1
                deck[k-1] = deck[k]
                deck[k] = nil
            end
        end
    end
end

function GameState:pause()
    if paused == true then
        gui[1]:updateText('Play','centre',220,font80)
        gui[2]:updatePosition('centre',380)
        if not winner then
            gui[4]:updateText('Main Menu','centre',1080-220-font80:getHeight('Main Menu'))
        end
        gui[2].default = false
        gui[3].default = true
        gui[4].visible = true
        gui['SpeedLabel'].visible = true
        gui[3].visible = true
        gui['VolumeLabel'].visible = true
    else
        gui[1]:updateText('Pause',1591,0,font100)
        gui[2]:updatePosition('1591',130,1591,0)
        gui[4]:updateText('Main Menu',35,20)
        gui[2].default = true
        gui[3].default = false
        if not winner then
            gui[4].visible = false
        end
        gui['SpeedLabel'].visible = false
        gui[3].visible = false
        gui['VolumeLabel'].visible = false
    end
end

function GameState:back()
    if not winner then
        pause()
    else
        gStateMachine:change('HomeState')
    end
end

function GameState:keypressed(key,isrepeat)
    if not isrepeat then
        if key == 'm' then
            gui[3].percentage = love.audio.getVolume()
        elseif gui[2] then
            if key == 'pageup' then 
                gui[2]:updatePercentage(gui[2].percentage * 2,false)
            elseif key == 'pagedown' then
                gui[2]:updatePercentage(gui[2].percentage / 2,false)
            end
        end
    end
    if key == 'space' then
        pause()
    end
end

function GameState:update(dt)
    if paused == false and not winner then
        dt = dt * self.gamespeed
        self.timer = self.timer + dt
        if self.timer >= 7.4 then self.timer = self.timer - 1 end
        self.moveAimTimer = self.moveAimTimer + dt
        self.attackTimer = self.attackTimer + dt

        for k, pair in pairs(P1deck) do
            pair:update(dt)
        end
        for k, pair in pairs(P2deck) do
            pair:update(dt)
        end

        if self.timer > 6.4 then
            if self.timer < 6.9 then
                if self.P1angle < math.rad(270) then
                    self.P1angle = self.P1angle + dt * 2
                end
                if self.P2angle > math.rad(90) then
                    self.P2angle = self.P2angle - dt * 2
                end
            elseif self.timer < 7.4 then
                if self.P1angle > math.rad(210) then
                    self.P1angle = self.P1angle - dt * 2
                end
                if self.P2angle < math.rad(150) then
                    self.P2angle = self.P2angle + dt * 2
                end
            end
        end

        if self.moveAimTimer >= 1 then
            self.moveAimTimer = self.moveAimTimer - 1
            for i = 1, love.thread.getChannel("imageDecoderOutput"):getCount() do
                local result = love.thread.getChannel("imageDecoderOutput"):pop()
                self.images[result[1]] = love.graphics.newImage(result[2])
                self.imagesInfo[result[1]][2] = true
                for i=1,#self.imagesInfo[result[1]][1] do
                    self.imagesInfo[result[1]][1][i]:init2(self.images[result[1]])
                end
                self.imagesInfo[result[1]] = nil
            end

            if self.timer < 7 then --Because moveAimTimer is created after timer, 7 seconds into a battle this will always be false
                for k, pair in pairs(P1deck) do
                    pair:move()
                end
                for k, pair in pairs(P2deck) do
                    pair:move()
                end
                
                if self.timer > 3 and self.P2length > self.timer * 6 then
                    for i=0,5 do
                        if P2deckCards(self.Nextcards[i]) then
                            P2deck[self.Nextcards[i]] = Card(P2deckCards(self.Nextcards[i]),2,self.Nextcards[i],12,self.images,self.imagesInfo)
                            self.Nextcards[i] = self.Nextcards[i] + 6
                        end
                    end
                    for k, pair in pairs(self.imagesInfo) do
                        if pair[2] == false then
                            love.thread.getChannel("imageDecoderQueue"):push(k)
                            pair[2] = true --Mark image as pushed
                        end
                    end
                    for i = 1,#imageDecoderThreads do
                        imageDecoderThreads[i]:start()
                    end
                end

            else
                if self.P2length > 42 then
                    for i=0,5 do
                        if not P2deck[42+self.currentRows[i]] and P2deckCards(self.Nextcards[i]) ~= nil then
                            P2deck[42+self.currentRows[i]] = Card(P2deckCards(self.Nextcards[i]),2,42+self.currentRows[i],13,self.images,self.imagesInfo)
                            self.Nextcards[i] = self.Nextcards[i] + 6
                        end
                    end
                    for k, pair in pairs(self.imagesInfo) do
                        if pair[2] == false then
                            love.thread.getChannel("imageDecoderQueue"):push(k)
                            pair[2] = true --Mark image as pushed
                        end
                    end
                    for i = 1,#imageDecoderThreads do
                        imageDecoderThreads[i]:start()
                    end
                end

                for k, pair in pairs(P1deck) do
                    pair:move2()
                end 
                for k, pair in pairs(P2deck) do
                    pair:move2()
                end
            end

            if self.timer > 3 then
                self:Move()
            end

            for k, pair in pairs(P1deck) do
                pair:aim()
            end
            for k, pair in pairs(P2deck) do
                pair:aim()
            end
        end

        if self.attackTimer >= 1 then
            self.attackTimer = self.attackTimer - 1

            for k, pair in pairs(P1deck) do
                pair.dodge = 0
                pair.attacksTaken = 0
            end
            for k, pair in pairs(P2deck) do
                pair.dodge = 0
                pair.attacksTaken = 0
            end

            for k, pair in pairs(P1deck) do
                pair:attack()
            end
            for k, pair in pairs(P2deck) do
                pair:attack()
            end

            for k, pair in pairs(P1deck) do
                if pair.health <= 0 then
                    P1deck[k] = nil
                end
            end
            for k, pair in pairs(P2deck) do
                if pair.health <= 0 then
                    P2deck[k] = nil
                end
            end
            
            if not self.next(P1deck) then
                P1deck = nil
            end
            if not self.next(P2deck) then
                P2deck = nil
            end
            if P1deck == nil or P2deck == nil then
                if P1deck == nil and P2deck == nil then 
                    winner = 'Draw'
                elseif P1deck == nil then
                    winner = 'P2'
                elseif P2deck == nil then
                    winner = 'P1'
                end
                gui[4].visible = true
                gui[4]:updateText('Main Menu',35,20)
                if mouseTouching == gui[1] and not love.mouse.isVisible() then repositionMouse(gui[4]) end
                gui[1] = gui[4]
                for k, pair in pairs(gui) do
                    if k ~= 1 then
                        gui[k] = nil
                    end
                end
                self.images = nil
                self.imagesInfo = nil
                collectgarbage()
            end
        end
    end
end

function GameState:renderBackground()
    if P1deck ~= nil then
        for k, pair in pairs(P1deck) do
            pair:render()
        end
    end
    if P2deck ~= nil then
        for k, pair in pairs(P2deck) do
            pair:render()
        end
    end

    if self.timer > 6.4 then
        if P1deck ~= nil then
            for k, pair in pairs(P1deck) do
                if pair.weaponManager ~= nil then
                    pair.weaponManager:render(self.P1angle)
                end
            end
        end
        if P2deck ~= nil then
            for k, pair in pairs(P2deck) do
                if pair.weaponManager ~= nil then
                    pair.weaponManager:render(self.P2angle)
                end
            end
        end
    end

    if P1deck ~= nil then
        for k, pair in pairs(P1deck) do
            if pair.projectileManager ~= nil then
                pair.projectileManager:render()
            end
        end
    end
    if P2deck ~= nil then
        for k, pair in pairs(P2deck) do
            if pair.projectileManager ~= nil then
                pair.projectileManager:render()
            end
        end
    end
end

function GameState:renderForeground()
    if winner then 
        love.graphics.print({{r,g,b},'Winner: ' .. winner},35,110)
    end
end

function GameState:exit()
    P1deck = nil
    P2deck = nil
    winner = nil
    P2deckCards = nil
end