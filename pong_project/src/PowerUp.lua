--[[
    GD50
    Breakout Remake

    -- Power Up CLass --

    Author: Joe Lee

    Represents a ball which will bounce back and forth between the sides
    of the world space, the player's paddle, and the bricks laid out above
    the paddle. The ball can have a skin, which is chosen at random, just
    for visual variety.

    The power up is randomly generated and generates two more balls which
    function exactly like the ball the user starts with. Once the user 
    proceeds to either VictoryState or GameOverState the number of balls
    will be reset. The player shoud only lose life when all three balls 
    are terminated.

    Powerups are not slotted into a random brick before the game starts,
    and are instead spawned immediately after the ball makes a collision
    with some block when the num collisions condition has been met.
]]

PowerUp = Class{}

function PowerUp:init()
    -- Set the required collisions before spawning a powerup
    self.requiredCollisions = math.random(6, 13)
    -- x and y coordinates will be updated to the bricks coordinates
    self.x = 0
    self.y = 0
    self.width = 6
    self.height = 6
    self.active = false
    self.speed = 0
    
    -- A type 0 powerup adds two balls
    -- A type 1 powerup is the key powerup
    self.type = 0
end

-- Function to determine what powerup is being spawned
function PowerUp:change(self)
    -- Determine type
    if math.random(3) == 3 then -- spawn key powerups about a quarter of the time
        self.type = 1
        -- make key powerups a little larger so they're easier to obtain
        self.width = 7.5
        self.height = 7.5
    else
        self.type = 0
    end
    
    -- Determine speed
    if type == 0 then
        self.speed = math.random(1, 1.5)
    else
        -- Key powerup will be much slower giving the user a better chance of obtaining
        self.speed = math.random(0.75, 1)
    end
end

function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

-- The ball should be travelling downward at a constant speed until it goes
-- below the screen from there it will terminate
function PowerUp:update(dt)
    -- The powerup should travel at a constant velocity
    self.y = self.y + self.speed
    
    if self.y > VIRTUAL_HEIGHT then
        self.active = false
    end
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gPowerupFrames is a table of quads mapping to each individual powerup skin
    -- in the texture
    if self.type == 0 then
        love.graphics.draw(gTextures['main'], gFrames['powerup'][2], self.x, self.y)
    else
        love.graphics.draw(gTextures['main'], gFrames['powerup'][10], self.x, self.y)
    end

end