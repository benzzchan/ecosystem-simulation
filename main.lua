local love = require("love")

local mobs = {}
local foods = {}
local predators = {}
local season = {"Summer", "Winter", "Autumn", "Spring"}
local globalTimer = 0
local seasonTimer = 0
local turnOn = false
local moveTimer = 0.5
local moveInterval = 4
local maxMobs = 50
local maxFoods = 100
local maxPredators = 10
local seasonActual = "None"
local seasonTime = 60
local indexSeason = 1
local speedMultiplier = 1
local acelearateDt
local maxSpeedMultiplier = 5
local backgroundMusic = love.audio.newSource("sound/backgroundMusic.mp3", "stream")
local seasonChangeSound = love.audio.newSource("sound/seasonChangeSound.mp3", "static")
local mobReproductionSound = love.audio.newSource("sound/mobReproductionSound.mp3", "static")
local eatPredatorSound = love.audio.newSource("sound/eatPredatorSound.mp3", "static")
local clearSound = love.audio.newSource("sound/clearSound.mp3", "static")

local baseWidth, baseHeight = 800, 600
local scaleX, scaleY

local function createFood(x, y)
    local newFood = {
        size = 10,
        x = x or math.random(20, baseWidth - 20),
        y = y or math.random(20, baseHeight - 20),
    }
    table.insert(foods, newFood)
end

local function createPredator(x, y)
    local newPredator = {
        size = 15,
        x = x or math.random(50, baseWidth - 50),
        y = y or math.random(50, baseHeight - 50),
        speed = 0,
        dirX = 0,
        dirY = 0,
        energy = 15,
        health = 10,
        detectionRadius = math.random(100, 120),
        color = {1, 0.2, 0.2},
        timerLife = 0,
        maxTimeLive = math.random(200, 260)
    }
    table.insert(predators, newPredator)
end

local function createMob(x, y)
    local newMob = {
        size = 20,
        x = x or math.random(50, baseWidth - 50),
        y = y or math.random(50, baseHeight - 50),
        speed = 0,
        dirX = 0,
        dirY = 0,
        energy = 15,
        health = 10,
        foodsEaten = 0,
        detectionRadius = math.random(100, 180),
        color = {math.random(), math.random(), math.random()},
        timerLife = 0,
        maxTimeLive = math.random(100, 180)
    }
    table.insert(mobs, newMob)
end

local function findNearestFood(mob)
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

local function findNearestPredator(mob)
    local nearestPredator = nil
    local minDistance = mob.detectionRadius
    
    for i, predator in ipairs(predators) do
        local distance = math.sqrt((predator.x - mob.x)^2 + (predator.y - mob.y)^2)
        if distance < minDistance then
            minDistance = distance
            nearestPredator = predator
        end
    end
    
    return nearestPredator
end

local function findNearestMob(predator)
    local nearestMob = nil
    local minDistance = predator.detectionRadius
    
    for i, mob in ipairs(mobs) do
        local distance = math.sqrt((predator.x - mob.x)^2 + (predator.y - mob.y)^2)
        if distance < minDistance then
            minDistance = distance
            nearestMob = mob
        end
    end
    
    return nearestMob
end

local function changeSeason()
    seasonActual = season[indexSeason]

    if seasonTimer > seasonTime then
        seasonTimer = 0
        indexSeason = indexSeason + 1
        if indexSeason > #season then
            indexSeason = 1
        end
        seasonActual = season[indexSeason]
        love.audio.play(seasonChangeSound)
    end

    if seasonActual == "Summer" then
        if math.random() < 1 and #foods < maxFoods then
            createFood()
        end
    elseif seasonActual == "Autumn" then
        if math.random() < 0.2 and #foods < maxFoods then
            createFood()
        end
    elseif seasonActual == "Spring" then
        if math.random() < 0.5 and #foods < maxFoods then
            createFood()
        end
    elseif seasonActual == "Winter" then
        if math.random() < 0.05 and #foods < maxFoods then
            createFood()
        end
    end
end

local function moveTowardsFood(mob, food)
    local dx = food.x - mob.x
    local dy = food.y - mob.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance > 0 then
        mob.dirX = dx / distance
        mob.dirY = dy / distance
    end
end

local function fleeFromPredator(mob, predator)
    local dx = mob.x - predator.x
    local dy = mob.y - predator.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance > 0 then
        mob.dirX = dx / distance
        mob.dirY = dy / distance
    end
end

local function moveTowardsMob(predator, mob)
    local dx = mob.x - predator.x
    local dy = mob.y - predator.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance > 0 then
        predator.dirX = dx / distance
        predator.dirY = dy / distance
    end
end

local function moveHungryMobs(mob)
    if mob.energy <= 5 then
        mob.speed = 100
    elseif mob.energy then
        mob.speed = math.random(40, 80)
    end
end

local function moveHungryPredators(predator)
    if predator.energy <= 3 then
        predator.speed = 80
    else
        predator.speed = math.random(40, 60)
    end
end

local function collision(mob, food)
    local distance = math.sqrt((mob.x - food.x)^2 + (mob.y - food.y)^2)
    return distance < (mob.size + food.size)
end

local function predatorMobCollision(predator, mob)
    local distance = math.sqrt((predator.x - mob.x)^2 + (predator.y - mob.y)^2)
    return distance < (predator.size + mob.size) * 0.8
end

local function avoidEdges(entity, margin)
    local screenWidth = baseWidth
    local screenHeight = baseHeight

    if entity.x - entity.size < margin then
        entity.dirX = math.abs(entity.dirX)
    elseif entity.x + entity.size > screenWidth - margin then
        entity.dirX = -math.abs(entity.dirX)
    end

    if entity.y - entity.size < margin then
        entity.dirY = math.abs(entity.dirY)
    elseif entity.y + entity.size > screenHeight - margin then
        entity.dirY = -math.abs(entity.dirY)
    end
end

local function mobAging(entities)
    for i = #entities, 1, -1 do
        local entity = entities[i]
        if entity.timerLife > entity.maxTimeLive then
            table.remove(entities, i)
        end
    end
end

local function removeMob(index)
    table.remove(mobs, index)
end

local function removeFood(index)
    table.remove(foods, index)
end

local function removePredator(index)
    table.remove(predators, index)
end

local function mobCollision(m1, m2)
    local distance = math.sqrt((m1.x - m2.x)^2 + (m1.y - m2.y)^2)
    return distance < (m1.size + m2.size) * 0.8
end

local function reproductionMobs(seuil)
    for i=1,#mobs do 
        local mob1 = mobs[i]
        for j=i+1, #mobs do
            local mob2 = mobs[j]
            if mobCollision(mob1, mob2) and (mob1.energy >= seuil and mob2.energy >= seuil) then
                local x = (mob1.x + mob2.x) / 2
                local y = (mob1.y + mob2.y) / 2

                local baby = {
                    size = 20,
                    x = x,
                    y = y,
                    speed = math.random(15, 25),
                    dirX = 0,
                    dirY = 0,
                    energy = 15,
                    health = 10,
                    foodsEaten = 0,
                    detectionRadius = 70,
                    color = {
                        (mob1.color[1] + mob2.color[1]) / 2,
                        (mob1.color[2] + mob2.color[2]) / 2,
                        (mob1.color[3] + mob2.color[3]) / 2
                    },
                    timerLife = 0,
                    maxTimeLive = math.random(260, 300)
                }
                
                table.insert(mobs, baby)

                mob1.energy = mob1.energy - seuil
                mob2.energy = mob2.energy - seuil

                love.audio.play(mobReproductionSound)
            end
        end
    end
end

local function borderLimit(entity)
    if entity.x - entity.size < 0 then
        entity.x = entity.size
    end
    if entity.x + entity.size > baseWidth then
        entity.x = baseWidth - entity.size
    end
    if entity.y - entity.size < 0 then
        entity.y = entity.size
    end
    if entity.y + entity.size > baseHeight then
        entity.y = baseHeight - entity.size
    end
end

function love.load()

    math.randomseed(os.time())
    love.window.setMode(baseWidth, baseHeight, {resizable=true})
    for i = 1, 5 do
        createMob()
    end
    for i = 1, 10 do
        createFood()
    end
    for i = 1, 2 do
        createPredator()
    end
    local w, h = love.graphics.getDimensions()
    scaleX, scaleY = w / baseWidth, h / baseHeight
end

function love.resize(w, h)
    scaleX, scaleY = w / baseWidth, h / baseHeight
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
    elseif key == "m" then
        if #predators < maxPredators then
            createPredator()
        end
    elseif key == "c" then
        mobs = {}
        foods = {}
        predators = {}
        love.audio.play(clearSound)
    elseif key == "f11" then
        local isFullScreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullScreen)
        local w, h = love.graphics.getDimensions()
        love.resize(w, h)
    elseif key == "v" then
        speedMultiplier = speedMultiplier + 1
        if speedMultiplier > maxSpeedMultiplier then
            speedMultiplier = 1
        end
    end
end

function love.update(dt)
    acelearateDt = dt * speedMultiplier

    if turnOn then
        love.audio.play(backgroundMusic)
        seasonTimer = seasonTimer + acelearateDt
        globalTimer = globalTimer + acelearateDt
        moveTimer = moveTimer + acelearateDt

        for i = #mobs, 1, -1 do
            local mob = mobs[i]
            mob.timerLife = mob.timerLife + acelearateDt
            moveHungryMobs(mob)
            
            if mob.energy <= 0 or mob.health <= 0 then
                removeMob(i)
            else
                local nearestPredator = findNearestPredator(mob)
                
                if nearestPredator then
                    fleeFromPredator(mob, nearestPredator)
                    mob.speed = 60
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
                end

                mob.x = mob.x + mob.dirX * mob.speed * acelearateDt
                mob.y = mob.y + mob.dirY * mob.speed * acelearateDt
                
                borderLimit(mob)

                for j = #foods, 1, -1 do
                    if collision(mob, foods[j]) then
                        mob.energy = mob.energy + 5
                        mob.foodsEaten = mob.foodsEaten + 1
                        if mob.foodsEaten >= 2 then
                            mob.health = mob.health + 1
                            mob.foodsEaten = 0
                        end
                        removeFood(j)
                    end
                end
            end
        end

        for i = #predators, 1, -1 do
            local predator = predators[i]
            predator.timerLife = predator.timerLife + acelearateDt
            moveHungryPredators(predator)
            
            if predator.energy <= 0 or predator.health <= 0 then
                removePredator(i)
            else
                local nearestMob = findNearestMob(predator)
                
                if nearestMob then
                    moveTowardsMob(predator, nearestMob)
                else
                    avoidEdges(predator, 40)
                    if moveTimer >= moveInterval then
                        local direction = math.random(8)
                        predator.energy = predator.energy - 1
                        
                        if direction == 1 then
                            predator.dirX, predator.dirY = 1, 0
                        elseif direction == 2 then
                            predator.dirX, predator.dirY = -1, 0
                        elseif direction == 3 then
                            predator.dirX, predator.dirY = 0, 1
                        elseif direction == 4 then
                            predator.dirX, predator.dirY = 0, -1
                        elseif direction == 5 then
                            predator.dirX, predator.dirY = -1, -1
                        elseif direction == 6 then
                            predator.dirX, predator.dirY = 1, -1
                        elseif direction == 7 then
                            predator.dirX, predator.dirY = -1, 1
                        elseif direction == 8 then
                            predator.dirX, predator.dirY = 1, 1
                        end
                    end
                end

                predator.x = predator.x + predator.dirX * predator.speed * acelearateDt
                predator.y = predator.y + predator.dirY * predator.speed * acelearateDt
                
                borderLimit(predator)

                for j = #mobs, 1, -1 do
                    if predatorMobCollision(predator, mobs[j]) then
                        mobs[j].health = mobs[j].health - 3
                        if mobs[j].health <= 0 then
                            predator.energy = predator.energy + 8
                            love.audio.play(eatPredatorSound)
                            removeMob(j)
                        end
                    end
                end
            end
        end
        
        if moveTimer >= moveInterval then
            moveTimer = 0
        end
        
        mobAging(mobs)
        mobAging(predators)
        changeSeason()
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.scale(scaleX or 1, scaleY or 1)

    for i, food in ipairs(foods) do
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", food.x, food.y, food.size)
    end

    for i, mob in ipairs(mobs) do
        love.graphics.setColor(mob.color[1], mob.color[2], mob.color[3])
        love.graphics.circle("fill", mob.x, mob.y, mob.size)
    end

    for i, predator in ipairs(predators) do
        love.graphics.setColor(predator.color[1], predator.color[2], predator.color[3])
        love.graphics.rectangle("fill", predator.x - predator.size, predator.y - predator.size, predator.size * 2, predator.size * 2)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Population : "..#mobs, 10, 10)
    love.graphics.print("Nourriture : "..#foods, 10, 30)
    love.graphics.print("Predateurs : "..#predators, 10, 50)
    love.graphics.print("Time: "..math.floor(globalTimer), 10, 70)
    love.graphics.print("Controls:", 10, 100)
    love.graphics.print("P: Play/Pause", 10, 120)
    love.graphics.print("SPACE: Spawn mob", 10, 140)
    love.graphics.print("F: Spawn food", 10, 160)
    love.graphics.print("M: Spawn predator", 10, 180)
    love.graphics.print("C: Clear all", 10, 200)
    love.graphics.print("ESC: Quit", 10, 220)
    love.graphics.print("TimeSeason: "..math.floor(seasonTimer), 10, 240)
    love.graphics.print("Season: "..seasonActual, 10, 260)
    love.graphics.print("V : Simulation acceleration "..speedMultiplier, 10, 280)
    
    love.graphics.pop()
end