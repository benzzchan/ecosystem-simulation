local mobs = {
    size = 30,
    x = love.graphics.getWidth() / 2 - 30,
    y = love.graphics.getHeight() / 2 - 30,
    speed = 25, -- Réduit pour que ça soit plus doux
    dirX = 0,
    dirY = 0
}

local turnOn = false
local moveTimer = 0
local moveInterval = 0.5 -- Change de direction toutes les 1 seconde

function love.load()
    math.randomseed(os.time())
end

function love.keypressed(key)
    if key == "p" then
        turnOn = not turnOn
    end
    if key == "escape" then
        love.event.quit()
    end
end

function love.update(dt)
    if turnOn then
        moveTimer = moveTimer + dt

        if moveTimer >= moveInterval then
            moveTimer = 0
            local direction = math.random(8)
            if direction == 1 then -- droite
                mobs.dirX, mobs.dirY = 1, 0
            elseif direction == 2 then -- gauche
                mobs.dirX, mobs.dirY = -1, 0
            elseif direction == 3 then -- bas
                mobs.dirX, mobs.dirY = 0, 1
            elseif direction == 4 then -- haut
                mobs.dirX, mobs.dirY = 0, -1
            elseif direction == 5 then
                mobs.dirX, mobs.dirY = -1, -1
            elseif direction == 6 then
                mobs.dirX, mobs.dirY = 1, -1
            elseif direction == 7 then
                mobs.dirX, mobs.dirY = -1,  1
            elseif direction == 8 then
                mobs.dirX, mobs.dirY = 1, 1
            end
        end

        -- Mouvement fluide
        mobs.x = mobs.x + mobs.dirX * mobs.speed * dt
        mobs.y = mobs.y + mobs.dirY * mobs.speed * dt
    end

    borderLimit()
end

function borderLimit()
    if mobs.x - mobs.size < 0 then
        mobs.x = mobs.size
    end
    if mobs.x + mobs.size > love.graphics.getWidth() then
        mobs.x = love.graphics.getWidth() - mobs.size
    end
    if mobs.y - mobs.size < 0 then
        mobs.y = mobs.size
    end
    if mobs.y + mobs.size > love.graphics.getHeight() then
        mobs.y = love.graphics.getHeight() - mobs.size
    end
end

function love.draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", mobs.x, mobs.y, mobs.size)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("posX : "..math.floor(mobs.x), 1, 1)
    love.graphics.print("posY : "..math.floor(mobs.y), 1, 20)
end
