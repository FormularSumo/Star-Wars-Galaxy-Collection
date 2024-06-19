DeckeditState = Class{__includes = BaseState}

function DeckeditState:init()
    P1deck = {}
    self.images = {}
    self.imagesInfo = {}
    self:loadCards(false)
    self.cardsOnDisplay = {}
    self.page = 0
    self.cardsOnDisplayAreBlank = false
    self.subState = 'deck'
    self:reloadDeck()

    for k, pair in pairs(self.imagesInfo) do
        love.thread.getChannel("imageDecoderQueue"):push(k)
    end
    self:loadRemainingImages()
    for i = 1,#imageDecoderThreads do
        imageDecoderThreads[i]:start()
    end

    background = love.graphics.newImage('Backgrounds/Death Star Control Room.jpg')
    gui[1] = Button(function() gStateMachine:change('HomeState','music','music') end,'Main Menu',font80,nil,'centre',20)
    gui[2] = Button(function() self:resetDeck('strongest') end,'Auto',font80,nil,'centre',200)
    gui[3] = Button(function() self:resetDeck('blank') end,'Clear',font80,nil,'centre',380)
    gui['RemoveCard'] = RemoveCard()
    gui[22] = Button(function() self:updateCardsOnDisplay('left') end,nil,nil,'Left Arrow','centre left',1030,nil,nil,nil,nil,nil,true)
    gui[23] = Button(function() self:updateCardsOnDisplay('right') end,nil,nil,'Right Arrow','centre right',1030,nil,nil,nil,nil,nil,true)
end


function DeckeditState:loadCards(reload) --Initial card loading and sorting
    P1cards = {}
    local count = 0

    self.P1deckList = {}
    for k, pair in pairs(P1deckCards) do --Create list of cards already in deck
        self.P1deckList[pair[1]] = true
    end

    if sandbox then
        for k, pair in pairs(Characters) do
            if not self.P1deckList[k] then --Prevent cards already in deck also existing in inventory
                count = count + 1
                P1cards[count] = {k,60,4}
            end
        end
    else
        for k, pair in pairs(binser.readFile('Player 1 cards.txt')) do
            count = count + 1
            P1cards[count] = pair
        end
    end

    local compare = compareCharacterStrength
    local cards = P1cards
    table.sort(cards,compare)
    local Temporary = {}
    for k, pair in pairs(cards) do
        Temporary[k-1] = pair
    end
    P1cards = Temporary
    if reload ~= false then
        self:updateCardsOnDisplay()
    end
end

function DeckeditState:reloadDeck() --Using the deck layout that's already been defined, create and store each of these cards in the relevant tables
    local P1column = 2
    local rowCorrectment = 0
    P1strength = 0
    
    for i=0,17,1 do
        if i % 6 == 0 and i ~= 0 then
            P1column = 2 - i / 6 
            rowCorrectment = i
        end
        row = i - rowCorrectment
        if P1deckCards[i] ~= nil then
            if P1deckCards[i][1] ~= nil then
                P1deck[i] = CardEditor(P1deckCards[i][1],row,P1column,i,P1deckCards[i][2],P1deckCards[i][3],true,self.images,self.imagesInfo)
                P1strength = P1strength + characterStrength({P1deckCards[i][1],P1deckCards[i][2],P1deckCards[i][3]})
            else
                P1deck[i] = CardEditor(P1deckCards[i],row,P1column,i,1,0,true,self.images,self.imagesInfo)
                P1strength = P1strength + characterStrength(P1deckCards[i])
            end
        else
            P1deck[i] = CardEditor('Blank',row,P1column,i,nil,nil,true,self.images,self.imagesInfo)
        end
    end
    self:updateCardsOnDisplay()
end

function DeckeditState:updateCardsOnDisplay(direction,visible) --Replace the cards which are currently displayed in the inventory with new ones
    if not (direction == 'left' and self.page == 0) and not (direction == 'right' and self.page > math.ceil((#P1cards+1)/18) - 2) then
        if direction == 'right' then
            self.page = self.page + 1
        elseif direction == 'left' then
            self.page = self.page - 1
        elseif type(direction) == "number" then
            self.page = direction
        end

        self.cardsOnDisplay = {}
        local column = 9
        local rowCorrectment = 0
        self.cardsOnDisplayAreBlank = true

        for i=0,17,1 do
            if i % 6 == 0 and i ~= 0 then
                column = 9 + i / 6
                rowCorrectment = i
            end
            row = i - rowCorrectment
            y = i+(self.page*18)
            if P1cards[y] ~= nil then
                self.cardsOnDisplay[i] = CardEditor(P1cards[y][1],row,column,y,P1cards[y][2],P1cards[y][3],false,self.images,self.imagesInfo)
                self.cardsOnDisplayAreBlank = false
            else
                self.cardsOnDisplay[i] = CardEditor('Blank',row,column,y,nil,nil,false,self.images,self.imagesInfo)
            end
        end

        if not visible then
            self:updateGui()
        end
    else
        return false
    end
end

function DeckeditState:loadRemainingImages()
    local P1cardsOnDisplayList = {}
    for k, pair in pairs(self.cardsOnDisplay) do
        P1cardsOnDisplayList[pair.name] = true
    end

    if sandbox == true then
        for k, pair in pairs(Characters) do
            if not self.P1deckList[k] and not P1cardsOnDisplayList[k] then
                if pair['filename'] then
                    love.thread.getChannel("imageDecoderQueue"):push('Characters/' .. pair['filename'] .. '/' .. pair['filename'])
                else
                    love.thread.getChannel("imageDecoderQueue"):push('Characters/' .. k .. '/' .. k)
                end
            end
        end
    else
        local decodeQueue = {} --As these images don't need pushing to objects later, it's simpler just to create a separate queue to check there's no duplicates and then queue those
        for k, pair in pairs(P1cards) do
            if not self.P1deckList[pair[1]] and not P1cardsOnDisplayList[pair[1]] then --Make sure that the images hasn't already been queued to load by the card objects that have been created
                local imagePath;
                if Characters[pair[1]]['filename'] then
                    imagePath = 'Characters/' .. Characters[pair[1]]['filename'] .. '/' .. Characters[pair[1]]['filename']
                else
                    imagePath = 'Characters/' .. pair[1] .. '/' .. pair[1]
                end

                if not decodeQueue[imagePath] then --If image hasn't already been added to the decode queue, add it
                    decodeQueue[imagePath] = true
                end
            end
        end
        for k, pair in pairs(decodeQueue) do
            love.thread.getChannel("imageDecoderQueue"):push(k)
        end
    end
    if not self.imagesInfo['Graphics/Blank Card'] then
        love.thread.getChannel("imageDecoderQueue"):push('Graphics/Blank Card')
    end
    love.thread.getChannel("imageDecoderQueue"):push('Graphics/Evolution Big')
    love.thread.getChannel("imageDecoderQueue"):push('Graphics/Evolution Max Big')
end

function DeckeditState:resetDeck(deck) --Resets deck editor using one of the pre-defined buttons
    local count = 0
    local sortedCharacters = {}
 
    for k, pair in pairs(P1deckCards) do
        if pair ~= 'Blank' then
            count = count + 1
            sortedCharacters[count] = pair
        end
    end
    for k, pair in pairs(P1cards) do
        count = count + 1
        sortedCharacters[count] = pair
    end

    P1deckCards = {}
    P1cards = {}

    table.sort(sortedCharacters,compareCharacterStrength)

    if deck == 'strongest' then
        for k, pair in ipairs(sortedCharacters) do
            if k-1 < 18 then
                P1deckEdit(k-1,pair, true)
            else
                P1cards[k-19] = pair
            end
        end
    elseif deck == 'blank' then
        for i = 0,18 do
            P1deckEdit(i,nil,true)
        end
        for k, pair in ipairs(sortedCharacters) do
            P1cards[k-1] = pair
        end
    end
    binser.writeFile('Player 1 deck.txt',P1deckCards)

    if not sandbox then
        binser.writeFile('Player 1 cards.txt',P1cards)
    end
    self:reloadDeck()
end

function DeckeditState:updateGui() --Update GUI with cards so that they display+update correctly
    for k, v in pairs(P1deck) do
        if k < 6 then
            gui[k+16] = v
        elseif k < 12 then
            gui[k+4] = v
        else
            gui[k-8] = v
        end
    end
    for k, v in pairs(self.cardsOnDisplay) do
        gui[k+24] = v
    end
    collectgarbage()
end

function DeckeditState:updateCardViewer(direction) --Updates which card is selected in the Card Viewer, and changes the inventory page if necessary
    if gui['CardViewer'].statsUpdated then --If stats have been updated while the viewer is open, save them
        gui['CardViewer']:saveStats()
        gui['CardViewer'].statsUpdated = false
    end
    if self.cardDisplayedInDeck then
        if direction == 'right' then
            if self.cardDisplayedNumber == 17 then
                self.cardDisplayedNumber = 6
            elseif self.cardDisplayedNumber == 11 then
                self.cardDisplayedNumber = 0
            elseif self.cardDisplayedNumber == 5 then
                self.cardDisplayedNumber = 12
            else
                self.cardDisplayedNumber = self.cardDisplayedNumber + 1
            end
        elseif direction == 'left' then
            if self.cardDisplayedNumber == 6 then
                self.cardDisplayedNumber = 17
            elseif self.cardDisplayedNumber == 0 then
                self.cardDisplayedNumber = 11
            elseif self.cardDisplayedNumber == 12 then
                self.cardDisplayedNumber = 5
            else
                self.cardDisplayedNumber = self.cardDisplayedNumber -1
            end
        end
        if P1deck[self.cardDisplayedNumber].imagePath == nil then
            self:updateCardViewer(direction)
        else
            P1deck[self.cardDisplayedNumber]:CardViewer()
        end
    else
        if direction == 'right' then
            if self.cardDisplayedNumber == 17 then
                if self:updateCardsOnDisplay('right',true) == false then
                    self:updateCardsOnDisplay(0,true)
                end
                self.cardsOnDisplay[0]:CardViewer()
            else
                if self.cardsOnDisplay[self.cardDisplayedNumber+1].imagePath ~= nil then
                    self.cardsOnDisplay[self.cardDisplayedNumber+1]:CardViewer()
                else
                    self:updateCardsOnDisplay(0,true)
                    self.cardsOnDisplay[0]:CardViewer()
                end
            end
        else
            if self.cardDisplayedNumber == 0 then
                if self:updateCardsOnDisplay('left',true) == false then
                    self:updateCardsOnDisplay(math.ceil((#P1cards+1)/18) - 1,true)
                    self.cardsOnDisplay[#P1cards-self.page*18]:CardViewer()
                else
                    self.cardsOnDisplay[17]:CardViewer()
                end
            else
                self.cardsOnDisplay[self.cardDisplayedNumber-1]:CardViewer()
            end
        end
    end
end

function DeckeditState:enterStats(name,imagePath,level,evolution,inDeck,number)
    self.subState = 'info'
    self.gui = gui
    gui = {}
    gui[2] = Button(function() gStateMachine:back() end,nil,font80,'X',1800,120)
    if sandbox then
        gui[7] = Button(function() self:updateCardViewer('left') end,nil,nil,'Left Arrow',58,1029,nil,nil,nil,nil,nil,true)
        gui[8] = Button(function() self:updateCardViewer('right') end,nil,nil,'Right Arrow',1920-58,1029,nil,nil,nil,nil,nil,true)
    else
        gui[3] = Button(function() self:updateCardViewer('left') end,nil,nil,'Left Arrow',58,1029,nil,nil,nil,nil,nil,true)
        gui[4] = Button(function() self:updateCardViewer('right') end,nil,nil,'Right Arrow',1920-58,1029,nil,nil,nil,nil,nil,true)
    end
end

function DeckeditState:exitStats()
    if gui['CardViewer'].statsUpdated then
        gui['CardViewer']:saveStats()
    end
    self.subState = 'deck'
    for k, pair in pairs(gui) do
        gui[k] = nil
    end
    gui = self.gui
    self.gui = nil
    self:updateGui()
end

function DeckeditState:back()
    if self.subState == 'deck' then
        gStateMachine:change('HomeState','music','music')
    else
        self:exitStats()
    end
end

function DeckeditState:keypressed(key)
    if key == 'right' or key == 'left' or key == 'dpright' or key == 'dpleft' then
        if love.mouse.isVisible() or key == 'dpright' or key == 'dpleft' then
            if key == 'right' or key == 'dpright' then
                if self.subState == 'deck' then
                    self:updateCardsOnDisplay('right')
                else
                    self:updateCardViewer('right')
                end
            else
                if self.subState == 'deck' then
                    self:updateCardsOnDisplay('left')
                else
                    self:updateCardViewer('left')
                end
            end
        elseif key == 'right' or key == 'left' then
            if self.subState == 'deck' then
                for k, v in ipairs(gui) do
                    if v == mouseTouching then
                        if key == 'right' then
                            if k == 1 then
                                repositionMouse(24)
                            elseif k == 2 then
                                repositionMouse(25)
                            elseif k == 3 then
                                repositionMouse(26)   
                            elseif k == 16 then
                                repositionMouse(1)
                            elseif k == 17 then
                                repositionMouse(2)
                            elseif k == 18 then
                                repositionMouse(3)
                            elseif (k < 20 and k > 16) or (k == 20 and gui['RemoveCard'].visible == false) then
                                repositionMouse(k+8)
                            elseif k == 20 then
                                repositionMouse(gui['RemoveCard'])
                            elseif k == 21 then
                                repositionMouse(22)
                            elseif k == 22 then
                                repositionMouse(23)
                            elseif k == 23 then
                                repositionMouse(29)
                            elseif gui[k+6] then
                                repositionMouse(k+6)
                            else
                                repositionMouse(mouseTouching.row+4)
                            end
                        end
                        if key == 'left' then
                            if k == 1 then
                                repositionMouse(16)
                            elseif k == 2 then
                                repositionMouse(17)
                            elseif k == 3 then
                                repositionMouse(18)
                            elseif k == 24 then
                                repositionMouse(1)
                            elseif k == 25 then
                                repositionMouse(2)
                            elseif k == 26 then
                                repositionMouse(3)
                            elseif (k < 28 and k > 24) or (k == 28 and gui['RemoveCard'].visible == false) then
                                repositionMouse(k-8) 
                            elseif k == 28 then
                                repositionMouse(gui['RemoveCard'])
                            elseif k == 29 then
                                repositionMouse(23)
                            elseif k == 23 then
                                repositionMouse(22)
                            elseif k == 22 then
                                repositionMouse(21)
                            elseif gui[k-6] and k - 6 ~= 1 then
                                repositionMouse(k-6)
                            else
                                repositionMouse(mouseTouching.row+24+12)
                            end
                        end
                        return
                    end
                end
                if mouseTouching == gui['RemoveCard'] then
                    if key == 'left' then
                        repositionMouse(20)
                    elseif key == 'right' then
                        repositionMouse(28)
                    end
                end
            else    
                for k, v in ipairs(gui) do
                    if v == mouseTouching then
                        if key == 'right' and k == 2 then
                            repositionMouse(3)
                        elseif key == 'left' and k == 3 then
                            repositionMouse(2)
                        end
                    end
                end
            end
        end
    end
end

function DeckeditState:update()
    if self.subState == 'deck' then
        self.left = 22
        self.right = 23
    elseif gui['CardViewer'].mode == 'stats' and sandbox then
        self.left = 7
        self.right = 8
    else
        self.left = 3
        self.right = 4
    end
    if love.mouse.isVisible() then
        mouseLocked = false
        if keyHoldtimer ~= 0 then
            if love.keyboard.wasDown('right') and lastPressed == 'right' then
                gui[self.right].scaling = 1.05
            end
            if love.keyboard.wasDown('left') and lastPressed == 'left' then
                gui[self.left].scaling = 1.05
            end
        end
    end
    if keyHoldTimer ~= 0 then
        if love.keyboard.wasDown('dpright') and lastPressed == 'dpright' then
            gui[self.right].scaling = 1.05
        end
        if love.keyboard.wasDown('dpleft') and lastPressed == 'dpleft' then
            gui[self.left].scaling = 1.05
        end
    end

    for i = 1, love.thread.getChannel("imageDecoderOutput"):getCount() do
        local result = love.thread.getChannel("imageDecoderOutput"):pop()
        self.images[result[1]] = love.graphics.newImage(result[2])
        if self.imagesInfo[result[1]] then --Check that this image needs pushing to an object, eg not if queued in loadRemainingImages
            for i=1,#self.imagesInfo[result[1]] do
                self.imagesInfo[result[1]][i]:init2(self.images[result[1]]) --Update the image attribute for all objects that use this image
            end
            self.imagesInfo[result[1]] = nil
        end   
    end
end

function DeckeditState:renderBackground()
    if self.subState == 'info' then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle('fill',50,50,1820,980,20)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle('line',50,50,1820,980,20)
        love.graphics.rectangle('line',51,51,1818,978,20)
        love.graphics.rectangle('line',52,52,1816,976,20)
        love.graphics.setColor(1,1,1,1)
    end
end

function DeckeditState:renderForeground()
    if self.subState == 'deck' then
        love.graphics.setColor(0,0,0,0.4)
        love.graphics.rectangle('fill',VIRTUALWIDTH/2-font50SW:getWidth('Formation strength: ' .. math.floor(P1strength+0.5))/2-20,890,font50SW:getWidth('Formation strength: ' .. math.floor(P1strength+0.5))+40,69,20)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print('Formation strength: ' .. tostring(math.floor(P1strength+0.5)),font50SW,VIRTUALWIDTH/2-font50SW:getWidth('Formation strength: ' .. math.floor(P1strength+0.5))/2,900)
    end
end

function DeckeditState:exit()
    P1deck = nil
    P1cards = nil
    P1strength = nil
end