local love = require("love")

local mobs = {}
local foods = {}
local season = {"Summer", "Winter", "Autumn", "Spring"}
local globalTimer = 0
local seasonTimer = 0
local turnOn = false
local moveTimer = 0.5
local moveInterval = 4
local maxMobs = 50
local maxFoods = 30
local seasonActual = "None"
local seasonTime = 10
local indexSeason = 1

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

function changeSeason()
    function changeSeason()
        seasonActual = season[indexSeason]
    
        if seasonTimer > seasonTime then
            seasonTimer = 0
            indexSeason = indexSeason + 1
            if indexSeason > #season then
                indexSeason = 1
            end
            seasonActual = season[indexSeason]
        end
    
        if seasonActual == "Summer" then
            if math.random() < 0.03 and #foods < maxFoods then
                createFood()
            end
        elseif seasonActual == "Autumn" then
            if math.random() < 0.01 and #foods < maxFoods then
                createFood()
            end
        elseif seasonActual == "Spring" then
            if math.random() < 0.005 and #foods < maxFoods then
                createFood()
            end
        elseif seasonActual == "Winter" then
            if math.random() < 0.001 and #foods < maxFoods then
                createFood()
            end
        end
    end
    
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

function moveHungryMobs(mobs)
    if mobs.energy <= 5 then
        mobs.speed = 50
    elseif mobs.energy then
        mobs.speed = math.random(15, 25)
    end
end

function collision(mob, food)
    local distance = math.sqrt((mob.x - food.x)^2 + (mob.y - food.y)^2)
    return distance < (mob.size + food.size)
end

function avoidEdges(mob, margin)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if mob.x - mob.size < margin then
        mob.dirX = math.abs(mob.dirX)
    elseif mob.x + mob.size > screenWidth - margin then
        mob.dirX = -math.abs(mob.dirX)
    end

    if mob.y - mob.size < margin then
        mob.dirY = math.abs(mob.dirY)
    elseif mob.y + mob.size > screenHeight - margin then
        mob.dirY = -math.abs(mob.dirY)
    end
end

function removeMob(index)
    table.remove(mobs, index)
end

function removeFood(index)
    table.remove(foods, index)
end

function mobCollision(m1, m2)
    local distance = math.sqrt((m1.x - m2.x)^2 + (m1.y - m2.y)^2)
    return distance < (m1.size + m2.size) * 0.8
end

function reproductionMobs(seuil)
    for i=1,#mobs do 
        local mob1 = mobs[i]
        for j=i+1, #mobs do
            local mob2 = mobs[j]
            if mobCollision(mob1, mob2) and (mob1.energy >= seuil and mob2.energy >= seuil) then
                local x = (mob1.x + mob2.y) / 2
                local y = (mob2.x + mob2.y) / 2

                local baby = {
                    size = 20,
                    x = x,
                    y = y,
                    speed = math.random(15, 25),
                    dirX = 0,
                    dirY = 0,
                    energy = 10,
                    detectionRadius = 70,
                    color = {
                        (mob1.color[1] + mob2.color[1]) / 2,
                        (mob1.color[2] + mob2.color[2]) / 2,
                        (mob1.color[3] + mob2.color[3]) / 2
                    }
                }
                
                table.insert(mobs, baby)

                mob1.energy = mob1.energy - seuil
                mob2.energy = mob2.energy - seuil
            end
        end
    end
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
    elseif key == "escape" then
        love.event.quit()
    elseif key == "space" then
        if #mobs < maxMobs then
            createMob()
        end
    elseif key == "f" then
        if #foods < maxFoods then
            createFood()
        end
    elseif key == "c" then
        mobs = {}
        foods = {}
    end
end

function love.update(dt)
    if turnOn then
        seasonTimer = seasonTimer + dt
        globalTimer = globalTimer + dt
        moveTimer = moveTimer + dt

        for i = #mobs, 1, -1 do
            local mob = mobs[i]

            moveHungryMobs(mob)
            
            if mob.energy <= 0 then
                removeMob(i)
            else
                local nearestFood = findNearestFood(mob)
                
                if nearestFood then
                    moveTowardsFood(mob, nearestFood)
                else
                    avoidEdges(mob, 40)
                    reproductionMobs(20)
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
        
        changeSeason()

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
    love.graphics.print("Controls:", 10, 80)
    love.graphics.print("P: Play/Pause", 10, 100)
    love.graphics.print("SPACE: Spawn mob", 10, 120)
    love.graphics.print("F: Spawn food", 10, 140)
    love.graphics.print("C: Clear all", 10, 160)
    love.graphics.print("ESC: Quit", 10, 180)
    love.graphics.print("TimeSeason: "..math.floor(seasonTimer), 10, 200)
    love.graphics.print("Season: "..seasonActual, 10, 220)
end