Projectile = Class{__includes = BaseState}

function Projectile:init(team,xoffset,yoffset,range,imageName)
    self.team = team
    self.xoffset = xoffset
    self.yoffset = yoffset
    self.range = range

    self.inverse = imageName == 'Force Drain'
end

function Projectile:init2(image)
    self.image = image
    self.width,self.height = self.image:getDimensions()

    if self.team == 1 then
        self.xoffset = self.xoffset / 2 - self.width / 2
        self.yoffset = self.yoffset / 2 - self.height / 2
    else
        self.xoffset = self.xoffset / 2 + self.width / 2
        self.yoffset = self.yoffset / 2 + self.height / 2
    end
end

function Projectile:fire(card,card2)
    if self.image then --Otherwise in theory it could crash if image decoding hasn't finished yet (would have to be extremely slow hardware)
        self.show = true
        if self.inverse then
            self.x = card2.x + self.xoffset
            self.finalX = card.targetX + self.xoffset
            self.y = card2.y + self.yoffset
            self.finalY = card.targetY + self.yoffset
        else
            self.x = card.x + self.xoffset
            self.finalX = card2.targetX + self.xoffset
            self.y = card.y + self.yoffset
            self.finalY = card2.targetY + self.yoffset
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
    if self.show and self.image then
        self.x = self.x + (self.xDistance * dt) / 0.9
        self.y = self.y + (self.yDistance * dt) / 0.9
    end
end

function Projectile:render()
    if self.show and self.xDistance then --Checking if self.xDistance here instead of self.image means that if somehow Projectile:fire wasn't run because the image wasn't loaded, a projectile with no destination/movement won't be shown (rather non will)
        love.graphics.draw(self.image,self.x,self.y,self.angle)
    end
end