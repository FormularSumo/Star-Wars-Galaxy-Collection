Weapon = Class{__includes = BaseState}

function Weapon:init(number,team,xoffset,yoffset,card,imageName)
    self.number = number
    self.team = team
    self.xoffset = xoffset
    self.yoffset = yoffset
    self.card = card

    self.double = imageName == 'Inquisitor Lightsaber' or imageName == 'Double Red Lightsaber' or imageName == 'Double Blue Lightsaber' or imageName == 'Double Green Lightsaber' or imageName == 'Double Yellow Lightsaber' or imageName == 'Double Purple Lightsaber' or imageName == 'Electrostaff' or imageName == 'Staff' or imageName == 'Kallus\' Bo-Rifle' or imageName == 'Bo-Rifle' or imageName == 'Phasma\'s Spear' or imageName == 'War Sword' or imageName == 'Chirrut\'s Staff'
    self.short = imageName == 'Dagger of Mortis' or imageName == 'Lightning' or imageName == 'Knife' or imageName == 'Flamethrower' or imageName == 'Truncheon' or imageName == 'Embo\'s Shield' or imageName == 'Tool 1' or imageName == 'Tool 2' or imageName == 'Kyuzo Petar' or imageName == 'Vine' or imageName == 'Sword' or imageName == 'Vibrosword' or imageName == 'Riot Control Baton' or imageName == 'Z6 Riot Control Baton' or imageName == 'Cane' or imageName == 'Shock Prod' or imageName == 'Fusioncutter' or imageName == 'Axe' or imageName == 'Spear'
    if imageName == 'Riot Control Shield' or imageName == 'Embo\'s Shield' then
        self.static = true
        self.shield = true
    else
        self.static = imageName == 'Lightning' or imageName == 'Flamethrower' or imageName == 'Shock Prod' or imageName == 'Riot Control Shield'
        self.shield = false
    end
end

function Weapon:init2(image)
    self.image = image
    self.width,self.height = self.image:getDimensions()
    if self.double or self.shield then self.yoriginoffset = self.height/2 end

    --Modify X/Y offset based on whether short and/or static
    if self.shield then
        self.xoffset = self.xoffset * 0.95
        self.yoffset = self.yoffset * 0.4
    elseif not self.short then
        self.xoffset = self.xoffset * 0.35
        self.yoffset = self.yoffset * 0.7
    else   
        if self.short and self.static then
            self.xoffset = self.xoffset + self.width / 2
        else
            self.xoffset = self.xoffset * 0.65
        end
        if not self.static then
            self.yoffset = self.yoffset * 0.6
        else
            self.yoffset = self.yoffset * 0.5 - self.height / 2
        end
        if not self.xoffset then self.xoffset = 0 end
        if not self.yoffset then self.yoffset = 0 end
    end

    --Modify X/Y offset based on what number weapon is
    if self.double then
        self.xoffset = self.xoffset + self.height / 4
        self.yoffset = self.yoffset - self.height / 5
        if self.number ~= 1 then
            self.xoffset = self.xoffset + 30
            self.yoffset = self.yoffset - 20
        end
    elseif self.number ~= 1 and not self.shield then
        self.yoffset = self.yoffset - (self.number-1) * 20
        if self.number % 2 == 0 then
            if not self.short then self.xoffset = self.xoffset + 40 else self.xoffset = self.xoffset + 30 end        
        end
    end

    --Flip weapon if on team 2
    if self.team == 2 then
        self.scalefactorx = -1
        self.xoffset = (115 - self.xoffset) --115 card width, mirrors for team 2 cards
    else
        self.scalefactorx = 1
    end
end

function Weapon:render(angle)
    if self.image then
        if self.static then
            love.graphics.draw(self.image,self.card.x+self.xoffset,self.card.y+self.yoffset,0,self.scalefactorx,1,self.width/2,self.yoriginoffset)
        else
            love.graphics.draw(self.image,self.card.x+self.xoffset,self.card.y+self.yoffset,angle,self.scalefactorx,1,self.width/2,self.yoriginoffset)
        end
    end
end