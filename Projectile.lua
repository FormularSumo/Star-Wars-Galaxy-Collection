Projectile = Class{__includes = BaseState}

function Projectile:init(team,xoffset,yoffset,range,imageName,imagePath)
    self.team = team
    self.xoffset = xoffset
    self.yoffset = yoffset
    self.range = range
    self.imagePath = imagePath

    self.inverse = imageName == 'Force Drain'
end

function Projectile:init2(imageSpriteBatch)
    self.imageSpriteIndex = imageSpriteBatch:add(0,0,0,0,0)
    self.width,self.height = imageSpriteBatch:getTexture():getDimensions()
    
    if self.team == 1 then
        self.xoffset = self.xoffset / 2 - self.width / 2
        self.yoffset = self.yoffset / 2 - self.height / 2
    else
        self.xoffset = self.xoffset / 2 + self.width / 2
        self.yoffset = self.yoffset / 2 + self.height / 2
    end
end

function Projectile:fire(card,card2)
    if self.imageSpriteIndex then --Otherwise in theory it could crash if image decoding hasn't finished yet (would have to be extremely slow hardware)
        self.show = true
        local xRandom = (love.math.random()-0.5) * 50
        local yRandom = (love.math.random()-0.5) * 75
        if self.inverse then
            self.x = card2.x + self.xoffset
            self.finalX = card.targetX + self.xoffset + xRandom
            self.y = card2.y + self.yoffset
            self.finalY = card.targetY + self.yoffset + yRandom
        else
            self.x = card.x + self.xoffset
            self.finalX = card2.targetX + self.xoffset + xRandom
            self.y = card.y + self.yoffset
            self.finalY = card2.targetY + self.yoffset + yRandom
        end

        if (self.team == 1 and not self.inverse) or (self.team == 2 and self.inverse) then
            self.finalX = self.finalX - 20
        else
            self.finalX = self.finalX + 20
        end

        self.xDistance = tonumber(self.finalX-self.x)
        self.yDistance = tonumber(self.finalY-self.y)
        self.angle = math.atan(self.yDistance/self.xDistance)
        if self.team == 2 then self.angle = self.angle + math.rad(180) end
    end
end

function Projectile:update(dt)
    if self.show and self.imageSpriteIndex then
        self.x = self.x + (self.xDistance * dt) / 0.9
        self.y = self.y + (self.yDistance * dt) / 0.9
    end
end

function Projectile:hideProjectile(graphics)
    if self.imageSpriteIndex then
        self.show = false
        graphics[self.imagePath]:set(self.imageSpriteIndex,0,0,0,0,0)
    end
end

function Projectile:render(graphics)
    if self.show and self.xDistance then --Checking if self.xDistance means that if somehow Projectile:fire wasn't run because the image wasn't loaded, a projectile with no destination/movement won't be shown (rather non will)
        graphics[self.imagePath]:set(self.imageSpriteIndex,self.x,self.y,self.angle)
    end
end