local mobs = {}
local foods = {}
local globalTimer = 0
local turnOn = false
local moveTimer = 0
local moveInterval = 4
local maxMobs = 10
local maxFoods = 20

function createFood(x, y)
    local newFood = {
        size = 10,
        x = x or math.random(20, love.graphics.getWidth() - 20),
        y = y or math.random(20, love.graphics.getHeight() - 20),
    }
    table.insert(foods, newFood)
end

function createMob(x, y)
    local newMob = {
        size = 20,
        x = x or math.random(50, love.graphics.getWidth() - 50),
        y = y or math.random(50, love.graphics.getHeight() - 50),
        speed = math.random(15, 25),
        dirX = 0,
        dirY = 0,
        energy = 10,
        detectionRadius = 70,
        color = {math.random(), math.random(), math.random()}
    }
    table.insert(mobs, newMob)
end

function findNearestFood(mob)
    local nearestFood = nil
    local minDistance = mob.detectionRadius
    
    for i, food in ipairs(foods) do
        local distance = math.sqrt((mob.x - food.x)^2 + (mob.y - food.y)^2)
        if distance < minDistance then
            minDistance = distance
            nearestFood = food
        end
    end
    
    return nearestFood
end

function moveTowardsFood(mob, food)
    local dx = food.x - mob.x
    local dy = food.y - mob.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance > 0 then
        mob.dirX = dx / distance
        mob.dirY = dy / distance
    end
end

function collision(mob, food)
    local distance = math.sqrt((mob.x - food.x)^2 + (mob.y - food.y)^2)
    return distance < (mob.size + food.size)
end

function removeMob(index)
    table.remove(mobs, index)
end

function removeFood(index)
    table.remove(foods, index)
end

function love.load()
    math.randomseed(os.time())
    for i = 1, 5 do
        createMob()
    end
    for i = 1, 10 do
        createFood()
    end
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
        globalTimer = globalTimer + dt
        moveTimer = moveTimer + dt

        for i = #mobs, 1, -1 do
            local mob = mobs[i]
            
            if mob.energy <= 0 then
                removeMob(i)
            else
                local nearestFood = findNearestFood(mob)
                
                if nearestFood then
                    moveTowardsFood(mob, nearestFood)
                else
                    if moveTimer >= moveInterval then
                        local direction = math.random(8)
                        mob.energy = mob.energy - 1
                        
                        if direction == 1 then
                            mob.dirX, mob.dirY = 1, 0
                        elseif direction == 2 then
                            mob.dirX, mob.dirY = -1, 0
                        elseif direction == 3 then
                            mob.dirX, mob.dirY = 0, 1
                        elseif direction == 4 then
                            mob.dirX, mob.dirY = 0, -1
                        elseif direction == 5 then
                            mob.dirX, mob.dirY = -1, -1
                        elseif direction == 6 then
                            mob.dirX, mob.dirY = 1, -1
                        elseif direction == 7 then
                            mob.dirX, mob.dirY = -1, 1
                        elseif direction == 8 then
                            mob.dirX, mob.dirY = 1, 1
                        end
                    end
                end

                mob.x = mob.x + mob.dirX * mob.speed * dt
                mob.y = mob.y + mob.dirY * mob.speed * dt
                
                borderLimit(mob)

                for j = #foods, 1, -1 do
                    if collision(mob, foods[j]) then
                        mob.energy = mob.energy + 5
                        removeFood(j)
                    end
                end
            end
        end
        
        if moveTimer >= moveInterval then
            moveTimer = 0
        end

        if math.random() < 0.005 and #foods < maxFoods then
            createFood()
        end
    end
end

function borderLimit(mob)
    if mob.x - mob.size < 0 then
        mob.x = mob.size
    end
    if mob.x + mob.size > love.graphics.getWidth() then
        mob.x = love.graphics.getWidth() - mob.size
    end
    if mob.y - mob.size < 0 then
        mob.y = mob.size
    end
    if mob.y + mob.size > love.graphics.getHeight() then
        mob.y = love.graphics.getHeight() - mob.size
    end
end

function love.draw()
    for i, food in ipairs(foods) do
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", food.x, food.y, food.size)
    end

    for i, mob in ipairs(mobs) do
        love.graphics.setColor(mob.color[1], mob.color[2], mob.color[3])
        love.graphics.circle("fill", mob.x, mob.y, mob.size)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Population : "..#mobs, 10, 10)
    love.graphics.print("Nourriture : "..#foods, 10, 30)
    love.graphics.print("Time: "..math.floor(globalTimer), 10, 50)
end