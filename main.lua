require "object"
require "utility"
require "objects"
require "physics"
require "player"
require "enemies"


--[[
TO DO:
1. scrolling background

3. bleeps and bloops

4. particle effects for enemy/player deaths
	
5. some type of event handling (observer design pattern?)

6. refactor -- further divide objects into "game" and "weapons" etc.
			-- make the game object hold the entities tables (powerups, enemies, bosses(?))

10. a "charger" enemy -- a bigger one that gradually moves down and shoots a set pattern
						 -- basically a meat shield, perhaps it can have a ground tank variation that scoots around

11. a small, homing enemy -- like the scourge

12. UI

--]]

function love.load()

	Test_Vector()
	Physics_Tests()

	-- game
	game = Game:new("menu", 800, 700, false)

	-- load menu stuff

	start_button = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)

	-- lol hi, flags.
	wave1_On = false
	wave2_On = false
	wave3_On = false
	boss_dead = false

end

function love.update(dt)

	-- update the game (triggers, level, etc)
	game:update(dt)

	-- update entities
	for i, v in ipairs(game.entities) do
		--[[
		-- single-entity based updates
		--]]
		v:update(dt)

		-- got a healthbar? is it dead? 
		if v.health ~= nil then
			if v.health < 0 then
				table.remove(game.entities, i)
			end
		end

		-- life/time/ ran out?
		if v.life ~= nil then
			if v.life <= 0 then
				table.remove(game.entities, i)
			end
		end

		if (v.class == "Player") then
			if player.laserOn == true then
				player.vel = Vector:new(50, 50)
			else
				player.vel = Vector:new(300, 250)
			end
		end

		for j, k in ipairs(game.entities) do
			--[[--
			-- multi-enemy based updates
			--]]
			if detect(v, k) then
				game:resolveCollision(v, k)
			end
		end
	end

	-- 	-- to test things
	-- 	if test_wave == true and game.stateNotLoaded == true then

	-- 		-- spawn a few seeking enemies
	-- 		-- for i = 1, 10 do

	-- 		-- 	if i % 10 == 0 then 
	-- 		-- 		-- this guy goes "fuck the poliss" and makes it interesting
	-- 		-- 		wanderer = SteeringEnemy:new(5, 10, Vector:new(math.random(50, 700), math.random(50, 600)), Vector:new(math.random(-200, 200), math.random(-200, 200)),
	-- 		-- 							   4, 500, 0, "wandering")
	-- 		-- 		table.insert(enemies, wanderer)
	-- 		-- 	end
	-- 		-- 	flocker = SteeringEnemy:new(5, 10, Vector:new(math.random(50, 700), math.random(50, 600)), Vector:new(math.random(-200, 200), math.random(-200, 200)),
	-- 		-- 							   4, 400, 0, "flock")
	-- 		-- 	table.insert(enemies, flocker)

	-- 		-- end
	-- 		bossTwo = BossTwo:new(Vector:new(400, 250), 200, 0, Vector:new(150, 150))
	-- 		table.insert(enemies, bossTwo)

	-- 		-- make some obstacles
	-- 		-- obstacleOne = CircleObstacle:new(Vector:new(0, 0), 100)
	-- 		-- obstacleTwo = CircleObstacle:new(Vector:new(game.width, 0), 100)
	-- 		-- obstacleThree = CircleObstacle:new(Vector:new(game.width, game.height), 120)
	-- 		-- obstacleFour = CircleObstacle:new(Vector:new(0, game.height), 100)
	-- 		-- obstacleFive = CircleObstacle:new(Vector:new(215, 245), 100)
	-- 		-- obstacleSix = CircleObstacle:new(Vector:new(500, 500), 130)
	-- 		-- obstacleSeven = CircleObstacle:new(Vector:new(570, 210), 60)
	-- 		-- obstacleEight = CircleObstacle:new(Vector:new(375, 100), 70)
	-- 		-- obstacleNine = CircleObstacle:new(Vector:new(720, 495), 30)
	-- 		-- obstacleTen = CircleObstacle:new(Vector:new(750, 220), 30)
	-- 		-- obstacle11 = CircleObstacle:new(Vector:new(190, 480), 40)
	-- 		-- obstacle12 = CircleObstacle:new(Vector:new(190, 590), 20)

	-- 		-- table.insert(obstacles, obstacleOne)
	-- 		-- table.insert(obstacles, obstacleTwo)
	-- 		-- table.insert(obstacles, obstacleThree)
	-- 		-- table.insert(obstacles, obstacleFour)
	-- 		-- table.insert(obstacles, obstacleFive)
	-- 		-- table.insert(obstacles, obstacleSix)
	-- 		-- table.insert(obstacles, obstacleSeven)
	-- 		-- table.insert(obstacles, obstacleEight)
	-- 		-- table.insert(obstacles, obstacleNine)
	-- 		-- table.insert(obstacles, obstacleTen)
	-- 		-- table.insert(obstacles, obstacle11)
	-- 		-- table.insert(obstacles, obstacle12)

	-- 		-- -- the avoiding AI
	-- 		-- avoider = SteeringEnemy:new(5, 10, Vector:new(400, 500), Vector:new(math.random(-200, 200), math.random(-200, 200)),
	-- 		--  							   8, 400, 0, "obstacleAvoidance")

	-- 		-- table.insert(enemies, avoider)
	-- 		game.stateNotLoaded = false

	-- 	end
	--end
end

-- input
function love.keypressed(key)

	if not(game.state == "menu") and not(game.state == "pause") then
		player[key] = 1 -- Set key flag pressed
		print(key .. " " .. player[key])
	end
end

function love.keyreleased(key)

	if not(game.state == "menu") and not(game.state == "pause") then
		player[key] = 0 -- Set key flag released
		print(key .. " " .. player[key])
	end
end

function love.mousepressed(x, y, button)
	
	if button == 'l' then
		if not(game.state == "menu") and not(game.state == "pause") then
			player.shooting = true
		end
	end

	if button == 'r' then
		if not(game.state == "menu") and not(game.state == "pause") then
			local mouse_pos = Vector:new(love.mouse.getX(), love.mouse.getY())
			player:shootLaser(mouse_pos)
		end
		
		-- this seems lazy, but it works.
		game.mousePressedPos = Vector:new(x, y)
		game.entities.click = Bullet:new(game.mousePressedPos)

	end
end

function love.mousereleased(x, y, button)

	if button == 'l' then
		if not(game.state == "menu") and not(game.state == "pause") then
			player.shooting = false
		end
	end

	if button == 'r' then
		if not(game.state == "menu") and not(game.state == "pause") then
			player.laserOn = false
			player.isChargingLaser = false
			player.currentCharge = 0
		end
	end
end

function love.draw()

	if game.state == "menu" then

		love.graphics.print("SHMUP GAEM XDDD", 100, 50)
		start_button:draw()

	end

	if game.state == "level1" and game.stateNotLoaded == false then
		-- draw player
	    love.graphics.polygon("line", {player.pos.x, player.pos.y + 32, player.pos.x + 8, player.pos.y, player.pos.x + 12, player.pos.y + 10,
	    							   player.pos.x + 14, player.pos.y + 11, player.pos.x + 16, player.pos.y + 6, player.pos.x + 18, player.pos.y + 11,
	    							   player.pos.x + 20, player.pos.y + 10, player.pos.x + 24, player.pos.y + 0, player.pos.x + 32, player.pos.y + 32,
	    							   player.pos.x + 20, player.pos.y + 18, player.pos.x + 18, player.pos.y + 18, player.pos.x + 16, player.pos.y + 24,
	    							   player.pos.x + 14, player.pos.y + 18, player.pos.x + 12, player.pos.y + 18, player.pos.x, player.pos.y + 32, player.pos.x, player.pos.y + 8})

	    -- draw circular obstacles (TEST)
	    for i, v in ipairs(obstacles) do
	    	v:draw()
	    end

	    -- draw bullets
	    for i, v in ipairs(player.bullets) do
	    	love.graphics.circle("line", v.pos.x, v.pos.y, 4, 10)
	    end

	    -- draw enemy bullets
	    for i, v in ipairs(game.enemyBullets) do
	    	love.graphics.circle("fill", v.pos.x, v.pos.y, 4, 10)
	    end

	    -- draw the laser 
	    if(player.laserOn) then
	    	player.laser:draw()
	    end

	    -- draw enemies
	    for i, v in ipairs(enemies) do
	    	v:draw()
	    end

	    -- draw powerups
	    for i, v in ipairs(powerups) do
	    	v:draw()
	    end

	    -- draw boss
	    if(boss ~= nil) then
	    	boss:draw()
	    end

	    -- UI
	    love.graphics.print("Lives: " .. "lol someone should put lives in", 25, 25)
	    love.graphics.print("Laser Energy: " .. player.laserEnergy, 25, 50)
	    love.graphics.print("Current charge: " .. player.currentCharge, 25, 75)
	    love.graphics.print("Score: " .. tostring(1), game.width - 125, 25)
	end

end