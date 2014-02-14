require "object"
require "utility"
require "objects"
require "physics"

--[[
TO DO:
1. scrolling background

2. physics collision
	-- HEY YOU! READ THIS!
	For some reason Circle VS. Triangle WORKS... but... 
	it only returns true when the circle's center is within the triangle
	i.e. the "edge" detection is broken...

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

8. have the laser follow the mouse (post-spawning) with a rotational velocity instead of this awkward 1 to 1
			-- also need a laser energy to make it less ridiculous

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
	shmupgame = Game:new("menu", 800, 700)

	-- load menu stuff

	start_button = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)

end

function love.update(dt)

	-- main menu
	if (shmupgame.state == "menu") then

		click = Bullet:new(mouse_pressed_pos)

		if (detect(start_button, click)) then
			shmupgame.stateNotLoaded = true
			shmupgame.state = "level1"
			start_button = nil
		end

	end

	-- level 1
	if (shmupgame.state == "level1") and (shmupgame.stateNotLoaded == true) then
		-- player
		player = Player:new(Vector:new(350, 350), Vector:new(300, 250))
		player.bulletLevel = 1

		powerups = {}
		enemies = {}
		-- enemies
		for i = 1,7 do
			x_iter = 95 * i
			y_iter = -200 + 20 * i
			enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 100))
			table.insert(enemies, enemy)
		end

		for i = 1,12 do
			x_iter = 100 + 30*i
			y_iter = -100 + i
			enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 70))
			table.insert(enemies, enemy)
		end

		-- boss
		boss = Boss:new(Vector:new(100, 50), Vector:new(0,0), 600, 200, 2500)

		shmupgame.stateNotLoaded = false
	end

	if shmupgame.state == "level1" then
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

					if(math.random(1, 10) == 1) then
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
			-- check for collisions with player
			v:update(dt)
			if detect(v, player) then
				table.remove(enemies, i)
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
	end

end