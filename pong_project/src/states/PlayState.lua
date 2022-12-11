--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.ball2 = params.ball2
    self.ball3 = params.ball3
    self.level = params.level

    -- A variable used to determine the number of points gained without
    -- losing a heart so we can modify the width of the paddle depending
    -- on the players performance
    self.consecutive = 0
    
    -- init new powerup
    self.powerUp = PowerUp()

    -- counts the number of balls
    self.balls = 1

    self.recoverPoints = 5000

 -- counts number of collisions for power up determination
    self.collisions = 0

    -- determines whether or not the player has the key powerup
    self.key = false

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

-- Since there are multiple balls, and copy and pasting the action-code for self.ball2 and 3
-- is not good practice, we make a function which takes whatever ball as a parameter
-- projectile = self.ball
    function collision(projectile)
        if projectile:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            projectile.y = self.paddle.y - 8
            projectile.dy = -projectile.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if projectile.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                projectile.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - projectile.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif projectile.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                projectile.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - projectile.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    -- only let active balls interract with bricks
    if self.ball.active then
        self.ball:update(dt)
        collision(self.ball)
    end
    if self.ball2.active then
        self.ball2:update(dt)
        collision(self.ball2)
    end
    if self.ball3.active then
        self.ball3:update(dt)
        collision(self.ball3)
    end

    function brickDetection(projectile)
        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and projectile:collides(brick) then

                -- check if number of collisions meets requirements
                self.collisions = self.collisions + 1
                if self.collisions == self.powerUp.requiredCollisions then
                    -- reset the collisions so another powerup can spawn
                    self.collisions = 0
                    -- randomise powerup
                    self.powerUp:change(self.powerUp)
                    -- set the coordinates of the powerUp
                    self.powerUp.x = brick.x + 10
                    self.powerUp.y = brick.y
                    self.powerUp.active = true
                end
                
                if (brick.keyType and self.key) or brick.keyType == false then
                     -- add to score
                    self.score = math.floor(self.score + (brick.tier * 200 + brick.color * 25))
                    self.consecutive = self.consecutive + (brick.tier * 200 + brick.color * 25)
                    -- code to modify size given consecutive points 
                    if self.consecutive > 1200 then
                        if self.paddle.size > 1 then
                            self.paddle.size = self.paddle.size - 1
                            self.paddle.width = self.paddle.width / 2
                            self.consecutive = 0
                    end
                end
            end
               
                -- trigger the brick's hit function, which removes it from play
                brick:hit(self.key)

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if projectile.x + 2 < brick.x and projectile.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    projectile.dx = -projectile.dx
                    projectile.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif projectile.x + 6 > brick.x + brick.width and projectile.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    projectile.dx = -projectile.dx
                    projectile.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif projectile.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    projectile.dy = -projectile.dy
                    projectile.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    projectile.dy = -projectile.dy
                    projectile.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(projectile.dy) < 150 then
                    projectile.dy = projectile.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
            --  If there is an active powerup check for any collisions 
        end
    end

    -- Check if any of the balls has collided with the bricks
    if self.ball.active then
        brickDetection(self.ball)
    end
    if self.ball2.active then
        brickDetection(self.ball2)
    end
    if self.ball3.active then
        brickDetection(self.ball3)
    end
    
    if self.powerUp.active == true then
        if self.powerUp:collides(self.paddle) then
            gSounds['powerup']:play()
            -- This means the powerup has been used
            self.powerUp.active = false

            -- Code for extra balls powerup
            if self.powerUp.type == 0 then
                self.balls = self.balls + (3-self.balls)
            
                -- Code to activate powerup
                --[[
                    we need to add two balls
                    we can only lose one life if ALL balls are lost
                    we'll keep a maximum number of 3 balls for now
                ]]
    
                -- Initialise position of balls and their random velocity
                -- provided they are not already active
                if self.ball2.active == false then
                    self.ball2.x = (self.paddle.x + (self.paddle.width / 2) - 4) - 4
                    self.ball2.y = self.paddle.y - 8
                    self.ball2.dx = math.random(-200, 200)
                    self.ball2.dy = math.random(-50, -60)
                end
                if self.ball3.active == false then
                    self.ball3.x = (self.paddle.x + (self.paddle.width / 2) - 4) + 4
                    self.ball3.y = self.paddle.y - 8
                    self.ball3.dx = math.random(-200, 200)
                    self.ball3.dy = math.random(-50, -60)
                end
     
                -- Generate another two instances of balls
                self.ball2.active = true
                self.ball3.active = true
    
                -- If the user activates the power up when the powerup balls are active
                -- activate the first ball
                if self.ball2.active and self.ball3.active and self.ball.active == false then
                    self.ball.active = true 
                    self.ball.x = self.paddle.x + (self.paddle.width / 2) - 4
                    self.ball.y = self.paddle.y - 8
                    self.ball.dx = math.random(-200, 200)
                    self.ball.dy = math.random(-50, -60)
                end
            -- Code to key powerup
            else
                self.key = true
            end
            
            
                        
            -- Select fixed position and upward random velocity of balls
        else
            self.powerUp:update(dt)
        end
        
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    function checkInactive(projectile)
        if projectile.y >= VIRTUAL_HEIGHT then
            projectile.active = false
            self.balls = self.balls - 1
            if self.balls == 0 then
                self.consecutive = 0
                self.health = self.health - 1
                self.paddle.size = self.paddle.size + 1
                self.paddle.width = self.paddle.width * 2
                gSounds['hurt']:play()
            end
        end
    end

    if self.ball.active then
        checkInactive(self.ball)
    end
    if self.ball2.active then
        checkInactive(self.ball2)
    end
    if self.ball3.active then
        checkInactive(self.ball3)
    end

    if self.balls > 0 then
    elseif self.health == 0 then
        gStateMachine:change('game-over', {
            score = self.score,
            highScores = self.highScores
        })
    else
        gStateMachine:change('serve', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score, 
            highScores = self.highScores,
            level = self.level,
            recoverPoints = self.recoverPoints
        })
    end
    
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render(self.key)
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()
    if self.ball2.active then
        self.ball2:render()
    end
    if self.ball3.active then
        self.ball3:render()
    end
    
    if self.powerUp.active == true then
        self.powerUp:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end