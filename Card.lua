Card = Class{__includes = BaseState}

function Card:init(card,team,number,column,images,imagesInfo)
    self.team = team
    self.number = number

    self.stats = Characters[card[1]]
    self.level = card[2] or 1
    self.evolution = card[3] or 0

    local imagePath;
    if self.stats['filename'] then
        imagePath = 'Characters/' .. self.stats['filename'] .. '/' .. self.stats['filename']
    else
        imagePath = 'Characters/' .. card[1] .. '/' .. card[1]
    end

    if images[imagePath] then
        self:init2(images[imagePath])
    else
        if imagesInfo[imagePath] then
            table.insert(imagesInfo[imagePath][1],self)
        else
            imagesInfo[imagePath] = {{self}, false}
        end
    end

    self.width,self.height = 115,173 --Shouldn't really be hardcoded, but no cards have been loaded at this point so there's not much alternative
    self.health = 1000
    self.modifier = ((self.level + (60 - self.level) / 1.7) / 60) * (1 - ((4 - self.evolution) * 0.1))
    self.meleeOffense = self.stats['meleeOffense'] * (self.modifier)
    if self.stats['rangedOffense'] then
        self.rangedOffense = self.stats['rangedOffense'] * (self.modifier)
    else
        self.rangedOffense = self.meleeOffense
    end
    self.defense = self.stats['defense'] * (self.modifier)
    self.evade = self.stats['evade']
    self.range = self.stats['range']
    self.meleeOffenseStat = (self.meleeOffense/800)^4/2
    self.rangedOffenseStat = (self.rangedOffense/800)^4

    if self.stats['projectile1'] then
        self.projectileManager = ProjectileManager(self.stats, self.team, self.width, self.height, images, imagesInfo)
        if self.projectileManager.projectileCount > 1 then
            self.rangedOffense = self.rangedOffense / (self.projectileManager.projectileCount^0.2)
        end
    end
    if self.stats['weapon1'] then
        self.weaponManager = WeaponManager(self.stats, self.team, self.width, self.height, self, images, imagesInfo)
    end

    self.meleeProjectile = self.weaponManager == nil and (self.stats['projectile1'] == 'Lightning' or self.stats['projectile1'] == 'Force Blast' or self.stats['projectile1'] == 'Force Drain')

    self.possibleTargets = {}
    self.targets = {}
    if self.team == 1 then
        self.enemyDeck = P2deck
    else
        self.enemyDeck = P1deck
    end

    self.column = column
    self.row = self.number % 6

    if self.team == 1 then
        self.targetX = ((VIRTUALWIDTH / 12) * self.column) + 22 - 20
    else
        self.targetX = ((VIRTUALWIDTH / 12) * self.column) + 22 + 20
    end

    self.x = self.targetX
    self.targetY = ((VIRTUALHEIGHT / 6) * self.row + (self.height / 48))
    self.y = self.targetY
end

function Card:init2(image)
    self.image = image
end

function Card:distance(target)
    return math.abs(self.column - target.column) + math.abs(self.row - target.row)
end

function Card:move()
    if self.team == 1 then
        self.targetX = self.targetX + 160
        self.column = self.column + 1
    else
        self.targetX = self.targetX - 160
        self.column = self.column - 1
    end
end

function Card:move2()
    if self.team == 1 then
        if P1deck[self.number-6] == nil and self.number - 6 >= 0 then
            P1deck[self.number-6] = P1deck[self.number]
            P1deck[self.number] = nil
            self.number = self.number - 6
            self.targetX = self.targetX + 160
            self.column = self.column + 1
        end
    elseif P2deck[self.number-6] == nil and self.number - 6 >= 0 then
        P2deck[self.number-6] = P2deck[self.number]
        P2deck[self.number] = nil
        self.number = self.number - 6
        self.targetX = self.targetX - 160
        self.column = self.column - 1
    end
end


function Card:aim()
    self.meleeAttack = false
    if (self.column == 5 or self.column == 6) and self.enemyDeck[self.number] ~= nil and (self.enemyDeck[self.number].column == 6 or self.enemyDeck[self.number].column == 5) then
        self.targets[1] = self.number
        if self.meleeProjectile then
            self.projectileManager:fireall(self,self.enemyDeck[self.targets[1]])
        end
        self.meleeAttack = true
    elseif (self.column == 5 or self.column == 6) and (self.range == 1 or self.meleeOffenseStat > self.rangedOffenseStat) and (self.enemyDeck[self.number-1] ~= nil and (self.enemyDeck[self.number-1].column == 6 or self.enemyDeck[self.number-1].column == 5) or (self.enemyDeck[self.number+1] ~= nil and (self.enemyDeck[self.number+1].column == 6 or self.enemyDeck[self.number+1].column == 6))) then
        if self.enemyDeck[self.number-1] ~= nil then
            self.targets[1] = self.number-1
        elseif self.enemyDeck[self.number+1] ~= nil then 
            self.targets[1] = self.number+1
        end
        if self.meleeProjectile then
            self.projectileManager:fireall(self,self.enemyDeck[self.targets[1]])
        end
        self.meleeAttack = true
    elseif self.range > 1 then
        self.targets[1] = self:target(self.range)
        if self.projectileManager then
            if self.targets[1] then
                self.projectileManager.projectiles[1]:fire(self,self.enemyDeck[self.targets[1]])
            end
            for k, pair in pairs(self.projectileManager.projectiles) do
                if k > 1 then
                    self.targets[k] = self:target(pair.range)
                    if self.targets[k] then
                        pair:fire(self,self.enemyDeck[self.targets[k]])
                    end
                end
            end
        end
    end
    if self.weaponManager then
        self.weaponManager.show = self.meleeAttack
    end
end

function Card:target(range)
    for k, pair in pairs(self.possibleTargets) do
        self.possibleTargets[k] = nil
    end
    self.totalProbability = 0
    for k, pair in pairs(self.enemyDeck) do
        distance = self:distance(pair)
        if distance <= range then
            self.possibleTargets[k] = self.totalProbability + range/distance
            self.totalProbability = self.totalProbability + range/distance
        end
    end

    if self.totalProbability > 0 then
        self.rangedAttackRoll = love.math.random() * self.totalProbability
        for k, pair in pairs(self.possibleTargets) do
            if self.rangedAttackRoll < self.possibleTargets[k] then
                return k
            end
        end
    end
end

function Card:attack()
    for k, pair in pairs(self.targets) do
        self:attack2(pair)
        self.targets[k] = nil
    end
    if self.projectileManager then self.projectileManager:hide() end
end

function Card:attack2(target)
    self.attackRoll = love.math.random(100) / 100
    self.enemyDeck[target].attacksTaken = self.enemyDeck[target].attacksTaken + 1
    if self.attackRoll > self.enemyDeck[target].evade then
        if self.meleeAttack then self.offense = self.meleeOffense else self.offense = self.rangedOffense end
        if self.offense < self.enemyDeck[target].defense then
            self.damage = 0
        else
            self.damage = ((self.offense - self.enemyDeck[target].defense) / 800) ^ 3
        end
        self.defenceDown = (self.offense / 100) * (self.offense / self.enemyDeck[target].defense) ^ 3
        if self.projectileManager and self.projectileManager.projectileCount > 1 then
            self.defenceDown = self.defenceDown / (self.projectileManager.projectileCount^0.2)
        end
        if target ~= self.number and self.range == 1 then 
            self.damage = self.damage / 2 
            self.defenceDown = self.defenceDown / 2 
        end
        self.enemyDeck[target].health = self.enemyDeck[target].health - (self.damage + 1)
        if self.enemyDeck[target].defense > 0 then
            self.enemyDeck[target].defense = self.enemyDeck[target].defense - self.defenceDown
            if self.enemyDeck[target].defense < 0 then self.enemyDeck[target].defense = 0 end
        else
            self.enemyDeck[target].defense = 0
        end
    else
        self.enemyDeck[target].dodge = self.enemyDeck[target].dodge + 1
    end
end

function Card:update(dt)
    if self.projectileManager then
        self.projectileManager:update(dt)
    end

    if self.targetX > self.x then
        self.x = self.x + dt * 500
        if self.x > self.targetX then self.x = self.targetX end
    elseif self.targetX < self.x then
        self.x = self.x - dt * 500
        if self.x < self.targetX then self.x = self.targetX end
    end

    if self.targetY > self.y then
        self.y = self.y + dt * 500
        if self.y > self.targetY then self.y = self.targetY end
    elseif self.targetY < self.y then
        self.y = self.y - dt * 500
        if self.y < self.targetY then self.y = self.targetY end
    end
end

function Card:render()
    if self.image then --In theory this could cause cards not to render but it'd have to be on a very very slow system for this to happen
        love.graphics.draw(self.image,self.x,self.y,0,1,sx)
        if self.evolution == 4 and evolutionMaxImage then --In theory on a very slow system/very quickly changing state this might not have loaded yet
            love.graphics.draw(evolutionMaxImage,self.x+self.width-evolutionMaxImage:getWidth()-4,self.y+4)
        elseif self.evolution > 0 and evolutionImage then
            love.graphics.draw(evolutionImage,self.x+115-5,self.y+3,math.rad(90))
            if self.evolution > 1 then
                love.graphics.draw(evolutionImage,self.x+115-6-evolutionImage:getHeight(),self.y+3,math.rad(90))
                if self.evolution > 2 then
                    love.graphics.draw(evolutionImage,self.x+115-7-evolutionImage:getHeight()*2,self.y+3,math.rad(90))
                end
            end
        end
                
        if self.health < 1000 then
            love.graphics.setColor(0.3,0.3,0.3)
            love.graphics.rectangle('fill',self.x-2,self.y-4,self.width+4,10,5,5)
            if self.dodge == 0 then
                love.graphics.setColor(1,0.82,0)
            else
                self.colour = self.dodge / self.attacksTaken
                self.colour = self.colour + (1-self.colour) / 2 --Proportionally increases brightness of self.colour so it's between 0.5 and 1 rather than 0 and 1 
                love.graphics.setColor(self.colour,self.colour,self.colour)
            end
            love.graphics.rectangle('fill',self.x-2,self.y-4,(self.width+4)/(1000/self.health),10,5,5)
            love.graphics.setColor(1,1,1)
        end
    end

    -- if self.number == 15 and self.team == 2 then
    --     if self.possibleTargets ~= nil then
    --         y = 100
    --         for k, pair in pairs(self.possibleTargets) do
    --             y = y + 100
    --             love.graphics.print(tostring(k) .. ' ' .. tostring(pair),0,y)
    --             love.graphics.print(self.rangedAttackRoll,800,100)
    --             love.graphics.print(self.totalProbability,0,100)
    --         end
    --     end
    --     love.graphics.print(self.stats,0,0)
    -- end

    -- if self.number == 2 and if self.team == 2 then
    --     love.graphics.print(self.attacksTaken)
    --     love.graphics.print(self.defense,0,100)
    -- end
    --     love.graphics.print(self.damage)
    --     love.graphics.print(self.defenceDown,0,100)
    --     love.graphics.print(self.defense,0,200)
    -- elseif self.team == 2 then
    --     love.graphics.print(self.damage,1600)
    --     love.graphics.print(self.defenceDown,1600,100)
    --     love.graphics.print(self.defense,1600,200)
    -- end       
    -- end
end