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

	-- set state to access test
	game.state = "test"

end

function love.update(dt)
	if game.isPaused then return end

	-- update the game (triggers, level, etc)
	game:update(dt)

	if game.player ~= nil then
		-- player checks
		if game.player.laserOn or game.player.isChargingLaser then
			game.player.vel = Vector:new(50, 50)
		else
			game.player.vel = Vector:new(300, 250)
		end

		if game.player.isDead_ then
			game.player.laserOn = false
			game.player.currentCharge = 0
			if game.player.laser ~= nil then game.player.laser.isDead_ = true end
			game.playerLives = game.playerLives - 1
			if game.playerLives <= 0 then
				game.playerLives = 0
				-- GAME OVER HERE.. NOT IMPLEMENTED YET
				game.gameOver_ = true
			end
			local player = Player:new(Vector:new(350, 350), Vector:new(300, 250), true)
			game.player = player
			table.insert(game.entities, game.player)
		end
	end

	-- update entities
	for i, v in ipairs(game.entities) do
		--[[
		-- single-entity based updates
		--]]
		v:update(dt)

		-- got a healthbar? is it dead? 
		if v.health ~= nil then
			if v.health < 0 then
				game:resolveDeath(v)
				table.remove(game.entities, i)
			end
		end

		-- marked dead for whatever reason?
		if v.isDead_ then 
			-- for effects, sound, etc.
			game:resolveDeath(v)
			table.remove(game.entities, i) 
		end

		-- life/time/ ran out?
		if v.life ~= nil then
			if v.life <= 0 then
				table.remove(game.entities, i)
			end
		end

		for j, k in ipairs(game.entities) do
			--[[--
			-- multi-entity based updates
			--]]
			if detect(v, k) then
				game:resolveCollision(v, k)
			end
		end
	end
end

-- input
function love.keypressed(key)

	if not(game.state == "menu") and not(game.state == "pause") then
		game.player[key] = 1 -- Set key flag pressed
		print(key .. " " .. game.player[key])
	end

	if key == "return" then
		game.isPaused = not game.isPaused
	end
end

function love.keyreleased(key)

	if not(game.state == "menu") and not(game.state == "pause") then
		game.player[key] = 0 -- Set key flag released
		print(key .. " " .. game.player[key])
	end
end

function love.mousepressed(x, y, button)
	
	if button == 'l' then
		if not(game.state == "menu") and not(game.state == "pause") then
			game.player.shooting = true
		end

		if game.state == "menu" then
			-- this seems lazy, but it works.
			if game.mouseClick ~= nil then game.mouseClick.pos = Vector:new(x, y) end
		end
	end

	if button == 'r' then
		if not(game.state == "menu") and not(game.state == "pause") then
			game.player:shootLaser()
		end

	end
end

function love.mousereleased(x, y, button)

	if button == 'l' then
		if not(game.state == "menu") and not(game.state == "pause") then
			game.player.shooting = false
		end
	end

	if button == 'r' then
		if not(game.state == "menu") and not(game.state == "pause") then
			game.player.laserOn = false
			game.player.isChargingLaser = false
			game.player.currentCharge = 0
			if game.player.laser ~= nil then game.player.laser.isDead_ = true end
		end
	end
end

-- screen focus
function love.focus(f) 
	game.isPaused = not f 
end

function love.draw()

	if game.state == "menu" then

		love.graphics.print("SHMUP", 100, 50)
		game.startButton:draw()

	end

	-- draw entities
	for i, v in ipairs(game.entities) do

		v:draw()

	end

	if (string.sub(game.state, 1, 5) == "level" or game.state == "test") and game.stateNotLoaded == false then
	    -- UI
	    fps = love.timer.getFPS()
	    -- lives
	    love.graphics.draw(game.livesGraphic, 45, 25, 0, 1, .9, 12, 12)
	    local count = game.playerLives
	    local x_iter = 15
	    if count ~= nil then
		    for i = 1, count do
		    	love.graphics.draw(game.playerGraphic, x_iter, 40, 0, .65, .65, 0, 0)
		    	x_iter = x_iter + 25
		    end
		end
	    love.graphics.print("Laser Energy: " .. game.player.laserEnergy, 25, game.height - 25)
	    love.graphics.print("fps: " .. fps, game.width - 75, 25)
	end

end