Slider = Class{}

function Slider:init(x,y,width,height,func,rgb1,rgb2,percentage,trap,func2,default,visible)
    self.width = width
    self.height = height

    self.func = func
    self.rgb1 = rgb1 or {0.3,0.3,0.3}
    self.rgb2 = rgb2 or {1,1,1}
    self.percentage = percentage
    self.func2 = func2
    if trap ~= nil then 
        self.trap3 = trap
        self.trap1 = trap - 0.03
        self.trap2 = trap + 0.03
    else 
        self.trap1 = 0
        self.trap2 = 0
        self.trap3 = 0
    end
    self.trap3 = (self.trap1 + self.trap2) / 2
    self.diameterToCircle = 3
    self.radiusToCircle = self.diameterToCircle / 2
    self:updatePosition(x,y)
    if default == nil then self.default = true else self.default = default end
    if visible == nil then self.visible = true else self.visible = visible end
end

function Slider:updatePosition(x,y)
    if x == 'centre' then
        self.x = VIRTUALWIDTH / 2 - self.width / 2
    else
        self.x = x 
    end
    if y == 'centre' then
        self.y = VIRTUALHEIGHT / 2 - self.height / 2
    else
        self.y = y 
    end
    self.clickableX = self.x - self.height * self.radiusToCircle
    self.clickableY = self.y + self.height / 2 - self.height * self.radiusToCircle
    self.heldTime = 0.5
    if mouseTouching == self and not love.mouse.isVisible() then
        repositionMouse(self)
    end
end

function Slider:keyreleased(key)
    if mouseTouching == self or (self.default and mouseTouching == false) or self.default then
        if key == 'left' or key == 'right' or key  == 'dpleft' or key == 'dpright' then
            self:updateSlider()
        end
    end
end

function Slider:update(dt)
    if self.visible then
        if mouseX > self.clickableX and mouseX < self.clickableX + self.width + self.height * self.diameterToCircle and mouseY > self.clickableY and mouseY < self.clickableY + self.height * self.diameterToCircle then
            mouseTouching = self
            if mouseDown and love.mouse.isVisible() and mouseTrapped == false and mouseLastX > self.clickableX and mouseLastX < self.clickableX + self.width + self.height * self.diameterToCircle and mouseLastY > self.clickableY and mouseLastY < self.clickableY + self.height * self.diameterToCircle and not touchLocked then
                self.clicked = true
                mouseTrapped = self
            end
        end
        if self.clicked == true then    
            if mouseDown and love.mouse.isVisible() then
                self:updatePercentage((mouseLastX - self.x) / self.width,true)
            else
                self.clicked = false
                if self.func2 ~= nil then
                    self.func2()
                end
            end
        end
    end
end

function Slider:update2(dt)
    if mouseTouching == self or (self.default and mouseTouching == false) then
        self:checkKeysDown(dt,'left','right')
    end
    if self.default then
        self:checkKeysDown(dt,'dpleft','dpright')
    end
end

function Slider:checkKeysDown(dt,left,right)
    if (love.keyboard.wasDown(left) or love.keyboard.wasDown(right)) then
        if not (love.keyboard.wasDown(left) and love.keyboard.wasDown(right)) then
            self.heldTime = self.heldTime + dt
            if love.keyboard.wasDown(left) then
                self:updatePercentage(self.percentage - (dt*self.heldTime^3)/4,false)
            end
            if love.keyboard.wasDown(right) then
                self:updatePercentage(self.percentage + (dt*self.heldTime^3)/4,false)
            end
        else
            self:updateSlider()
        end
        if love.mouse.isVisible() == false and left == 'left' then
            repositionMouse(self)
        end
    end
end

function Slider:updateSlider()
    self.heldTime = 0.5
    if self.func2 ~= nil then
        self.func2()
    end
end
function Slider:updatePercentage(percentage,trap)
    self.percentage = percentage
    if self.percentage < 0.001 then self.percentage = 0.001 
    elseif self.percentage > 1 then self.percentage = 1
    elseif self.percentage > self.trap1 and self.percentage < self.trap2 and trap == true then self.percentage = self.trap3 end
    self.func(self.percentage)
end

function Slider:render()
    if self.visible then
        love.graphics.setColor(self.rgb1)
        love.graphics.rectangle('fill',self.x,self.y,self.width,self.height,5)
        if (mouseTouching == self and not touchLocked) or mouseTrapped == self then
            love.graphics.setColor(66/255,169/255,229/255)
        else
            love.graphics.setColor(self.rgb2)
        end
        love.graphics.rectangle('fill',self.x,self.y,self.width*self.percentage,self.height,5)
        love.graphics.circle('fill',(self.x + (self.width*self.percentage)),(self.y + self.height / 2),self.height*self.radiusToCircle)
        love.graphics.setColor(1,1,1)
    end
end