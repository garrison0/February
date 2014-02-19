require "object"
require "utility"
require "objects"
require "physics"

--[[
TO DO:
1. scrolling background

3. bleeps and bloops

4. particle effects for enemy/player deaths
	
5. send events to the shmupgame object to handle
		-- e.g. enemyDied(position, type)
					-- within:
						-- if(type == "normal") then
								roll for item drops
								play that animation and death sound... etc
	basically try to stop the nonsense level-based spaghetti code that's going on.

6. refactor -- further divide objects into "game" and "weapons" etc.
			-- make the shmupgame object hold the entities tables (powerups, enemies, bosses(?))

7. some boss AI

9. a "turret" enemy -- one that stops and shoots at the player's position,
					flying away (effectively dying but no score) after t time passes

10. a "charger" enemy -- a bigger one that gradually moves down and shoots a set pattern
						 -- basically a meat shield, perhaps it can have a ground tank variation that scoots around

11. a small, homing enemy -- like the scourge

12. UI

--]]

function love.load()

	Test_Vector()
	Physics_Tests()

	-- shmupgame
	shmupgame = Game:new("menu", 800, 700, false)

	-- load menu stuff

	start_button = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)

	-- lol hi, flags.
	wave1_On = false
	wave2_On = false
	wave3_On = false
	boss_dead = false

end

function love.update(dt)

	-- main menu
	if (shmupgame.state == "menu") then

		click = Bullet:new(mouse_pressed_pos)

		if (detect(start_button, click)) then
			shmupgame.stateNotLoaded = true
			shmupgame.state = "level1"
			wave1_On = true
			start_button = nil
		end

	end

	-- level 1
	if (shmupgame.state == "level1") and (shmupgame.stateNotLoaded == true) then

		-- load pre-level stuff
		player = Player:new(Vector:new(350, 350), Vector:new(300, 250))
		player.bulletLevel = 1

		powerups = {}
		enemies = {}

	end

	if shmupgame.state == "level1" then

		-- the 'loading' part; don't want to load twice.
		if wave1_On == true and shmupgame.stateNotLoaded == true then

			-- spawn enemies
			for i = 1,7 do
				x_iter = 95 * i
				enemy = Enemy:new(Vector:new(x_iter, 0), Vector:new(0, 300))
				enemy.life = 5
				table.insert(enemies, enemy)
			end
			shmupgame.stateNotLoaded = false

		end

		-- the check whether to move on or not. 
		if wave1_On == true and shmupgame.stateNotLoaded == false then

			if enemies[1] == nil then

				wave1_On = false
				wave2_On = true
				shmupgame.stateNotLoaded = true

			end

		end

		-- loading part
		if wave2_On == true and shmupgame.stateNotLoaded == true then

			-- spawn enemies
			for i = 1,8 do
				y_iter = -500 + 50 * i

				enemy = Enemy:new(Vector:new(shmupgame.width / 4, y_iter), Vector:new(150, 250),
								 "z-shape", 100, 500, "right")

				table.insert(enemies, enemy)
			end
			for i = 1,8 do
				y_iter = -500 + 50 * i

				enemy = Enemy:new(Vector:new(3 * shmupgame.width / 4, y_iter), Vector:new(150, 250),
								 "z-shape", 100, 500, "left")

				table.insert(enemies, enemy)
			end
			for i = 1,8 do
				y_iter = -1250 + 50 * i

				if(i % 2 == 0) then
					turningDirection = "right"
				else
					turningDirection = "left"
				end

				enemy = Enemy:new(Vector:new(shmupgame.width / 2, y_iter), Vector:new(100, 250), "z-shape",
								 100, 600, turningDirection)

				table.insert(enemies, enemy)
			end
			shmupgame.stateNotLoaded = false

		end


		-- the check whether to move on or not. 
		if wave2_On == true and shmupgame.stateNotLoaded == false then

			if enemies[1] == nil then

				wave2_On = false
				wave3_On = true
				shmupgame.stateNotLoaded = true

			end

		end

		-- loading part
		if wave3_On == true and shmupgame.stateNotLoaded == true then

			-- spawn boss
			boss = Boss:new(Vector:new(100, 50), Vector:new(0,0), 600, 200, 2500)

			shmupgame.stateNotLoaded = false

		end


		-- the check whether to move on or not. 
		if wave3_On == true and shmupgame.stateNotLoaded == false then

			if boss == nil then

				wave3_On = false
				boss_dead = true
				shmupgame.stateNotLoaded = true

			end

		end

		if boss_dead == true and shmupgame.stateNotLoaded == true then

			-- CONGRATS screen + button to go back to main menu
			mouse_pressed_pos = Vector:new(0, 0)
			start_button = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)
			shmupgame.state = "menu"

		end

		-- update the player
		player:update(dt)

		-- update laser
		if player.laserOn then
			mouse_pos = Vector:new(love.mouse.getX(), love.mouse.getY())
			player.laser:update(dt, mouse_pos)

			-- because i don't know fuck you i don't feel like fixing that bug
			-- it's now a design decision!
			player.vel = Vector:new(0, 0)

			-- check for oollision with enemies
			for i, v in ipairs(enemies) do
				if detect(v, player.laser) then

					if(math.random(1, 15) == 1) then
						powerup = PowerUp:new(v.pos, 25)
						table.insert(powerups, powerup)
					end

					table.remove(enemies, i)
					
				end
			end

			-- check for collision with boss
			if (boss ~= nil) then
				if detect(boss, player.laser) then
					boss.health = boss.health - player.laser.damage
				end
			end
		else 

			player.vel = Vector:new(300, 250)

		end

		-- shoot bullets
		if (player.shooting) and player.fire_delay <= 0 then
			player.shoot()
		end

		-- update bullets
		for i, v in ipairs(player.bullets) do
			v:update(dt)

			if v.life <= 0 then
				table.remove(player.bullets,i)
			end
		end

		-- update boss
		if (boss ~= nil) then 
			boss:update(dt)

			if boss.health <= 0 then
				boss = nil
			end
		end

		-- update powerups
		for i, v in ipairs(powerups) do
			-- update
			v:update(dt)

			-- check for player collisions.
			if detect(v, player) then
				table.remove(powerups, i)

				-- upgrade bullet level
				if(player.bulletLevel < 3) then
					player.bulletLevel = player.bulletLevel + 1
				end
			end
		end

		-- update the enemies
		for i, v in ipairs(enemies) do

			v:update(dt)
			if v.life <= 0 then
				table.remove(enemies, i)
			end

			-- collide against player
			if detect(v, player) then
				-- lol back to the menu. temporary.
				mouse_pressed_pos = Vector:new(0, 0)
				start_button = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)
				shmupgame.state = "menu"
			end
		end
		
		for i, v in ipairs(player.bullets) do
			for j, k in ipairs(enemies) do
				-- check collision between bullets and enemies
				if detect(v,k) then
					if(math.random(1, 10) == 1) then
						powerup = PowerUp:new(k.pos, 25)
						table.insert(powerups, powerup)
					end
					table.remove(enemies, j)
					table.remove(player.bullets, i)
				end
			end
			-- bullets and boss
			if (boss ~= nil) then
				if detect(v, boss) then
					table.remove(player.bullets, i)
					boss.health = boss.health - 5
				end
			end
		end
	end
end

-- input
function love.keypressed(key)

	if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
		player[key] = 1 -- Set key flag pressed
		print(key .. " " .. player[key])
	end
end

function love.keyreleased(key)

	if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
		player[key] = 0 -- Set key flag released
		print(key .. " " .. player[key])
	end
end

function love.mousepressed(x, y, button)
	
	mouse_pressed_pos = Vector:new(x, y)

	if button == 'l' then
		if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
			player.shooting = true
		end
	end

	if button == 'r' then
		if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
			mouse_pos = Vector:new(love.mouse.getX(), love.mouse.getY())
			player:shootLaser(mouse_pos)
		end
	end
end

function love.mousereleased(x, y, button)

	if button == 'l' then
		if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
			player.shooting = false
		end
	end

	if button == 'r' then
		if not(shmupgame.state == "menu") and not(shmupgame.state == "pause") then
			player.laserOn = false
		end
	end
end

function love.draw()

	if shmupgame.state == "menu" then

		love.graphics.print("SHMUP GAEM XDDD", 100, 50)
		start_button:draw()

	end

	if shmupgame.state == "level1" and shmupgame.stateNotLoaded == false then
		-- draw player
	    love.graphics.polygon("line", {player.pos.x, player.pos.y + 32, player.pos.x + 8, player.pos.y, player.pos.x + 12, player.pos.y + 10,
	    							   player.pos.x + 14, player.pos.y + 11, player.pos.x + 16, player.pos.y + 6, player.pos.x + 18, player.pos.y + 11,
	    							   player.pos.x + 20, player.pos.y + 10, player.pos.x + 24, player.pos.y + 0, player.pos.x + 32, player.pos.y + 32,
	    							   player.pos.x + 20, player.pos.y + 18, player.pos.x + 18, player.pos.y + 18, player.pos.x + 16, player.pos.y + 24,
	    							   player.pos.x + 14, player.pos.y + 18, player.pos.x + 12, player.pos.y + 18, player.pos.x, player.pos.y + 32, player.pos.x, player.pos.y + 8})

	    -- drawing the hitbox
	    local p1 = Vector:new(player.pos.x + 14, player.pos.y + 11)
		local p2 = Vector:new(player.pos.x + 18, player.pos.y + 11)
		local p3 = Vector:new(player.pos.x + 18, player.pos.y + 18)
		local p4 = Vector:new(player.pos.x + 14, player.pos.y + 18)
		love.graphics.polygon("fill", {p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y})

	    -- draw bullets
	    for i, v in ipairs(player.bullets) do
	    	love.graphics.circle("line", v.pos.x, v.pos.y, 4, 10)
	    end

	    -- draw the laser 
	    if(player.laserOn) then
	    	player.laser:draw()
	    end

	    -- draw enemies
	    for i, v in ipairs(enemies) do
	    	love.graphics.polygon("line", {v.pos.x, v.pos.y, v.pos.x + 32, v.pos.y, v.pos.x + 16, v.pos.y + 32})
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
	    love.graphics.print("Score: " .. tostring(1), shmupgame.width - 125, 25)
	end

end