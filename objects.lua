require "object"
require "utility"
require "physics"
require "enemies"
require "player"

Game = Object:new({class = "Game"})

	function Game:new(initial_state, width, height, fullscreen)

		if fullscreen then
			love.window.setFullscreen(true)
			width, height = love.window.getDimensions()
		end
		love.window.setMode(width, height, {fullscreen = fullscreen or false})
		local game = {width = width or 0, height = height or 0, 
					 stateNotLoaded = true, triggerNotLoaded = true, 
					 fullscreen = fullscreen or false, playerLives = 3,
					 title = "SHMUP"}

		game.state = initial_state or "level1"

		-- entity table
		game.entities = {}
		-- trigger table; {name : true, name : false, str : bool}
		game.levelTriggers = {}
		-- level data (counting time in a trigger for periodic spawns, etc)
		game.levelData = {}

		-- UI stuff. Don't mind me ^^'
		game.livesGraphic = love.graphics.newImage("/graphics/1up2.png")
		game.playerGraphic = love.graphics.newImage("/graphics/shipMiddle.png")

		-- ENEMY EXPLOSION PARTICLES
		-- FIRE/SMOKE
		local particleImage = love.graphics.newImage("/graphics/fireSmoke.png")
		local p = love.graphics.newParticleSystem(particleImage, 255)
		p:setEmissionRate(0)
		p:setParticleLifetime(.5)
		p:setSpread(2*math.pi)
		p:setSpeed(50, 0)
		p:setRadialAcceleration(0, 30)
		p:setTangentialAcceleration(0, 10)
		p:setSizes(.01, .5)
		p:setSizeVariation(.8)
		p:setRotation(0, 2*math.pi)
		p:setSpin(0, 3, 5)
		p:setColors({245, 239, 51, 120}, {21, 21, 21, 121})
		p:start()	
		game.smallExplosionFireSmoke = p

		-- FLASH
		local particleImage = love.graphics.newImage("/graphics/flash.png")
		local p = love.graphics.newParticleSystem(particleImage, 255)
		p:setEmissionRate(0)
		p:setParticleLifetime(.15)
		p:setSpread(2*math.pi)
		p:setSpeed(0)
		p:setRadialAcceleration(5)
		p:setTangentialAcceleration(0)
		p:setSizes(.01, .9, 0)
		p:setRotation(0, 2*math.pi)
		p:setSizeVariation(1)
		p:setColors({255, 252, 179, 110}, {255, 252, 179, 0})
		p:start()
		game.smallExplosionFlash = p

		setmetatable(game, self)
		self.__index = self
		return game

	end

	function Game:resizeWindow(w, h)

		self.width = w
		self.height = h
		love.window.setMode(w, h)

	end

	function Game:update(dt)

		-- update particles
		self.smallExplosionFlash:update(dt)
		self.smallExplosionFireSmoke:update(dt)

		-- keep track of mouse pos for various reasons.
		self.mousePos = Vector:new(love.mouse.getX(), love.mouse.getY())

		-- outside of level architecture 
		if self.state == "menu" and self.stateNotLoaded == true then

			-- remove all left-over entities
			self.entities = {}

			-- load initial menu things
			self.startButton = MenuButton:new("START GAME", Vector:new(100, 200), 400, 100)		
			self.mouseClick = Bullet:new(Vector:new(0, 0), Vector:new(0, 0), 99999)

			-- set up the level triggers
			self.levelTriggers = {startTrigger = true}
			self.stateNotLoaded = false

		elseif self.state == "level1" and self.stateNotLoaded == true then

			-- remove left-over entities
			self.entities = {}

			-- load initial level 1 things
			local player = Player:new(Vector:new(350, 350))
			game.player = player
			game.playerLives = 3
			table.insert(self.entities, player)

			-- set up the level triggers
			self.levelTriggers = {wave1 = true}
			self.stateNotLoaded = false

		elseif self.state == "test" and self.stateNotLoaded == true then
			
			-- Test things here!
			local player = Player:new(Vector:new(350, 350))
			game.player = player
			table.insert(self.entities, player)

			self.stateNotLoaded = false

		elseif self.state == "AITest" and self.stateNotLoaded == true then

			--local player = Player:new(Vector:new(350, 350))
			--game.player = player
			--table.insert(self.entities, player)
			for i = 1,14 do
				local pos = Vector:new(math.random(50, self.width-50), math.random(50, self.height-50))
				local vel = Vector:new(math.random(-150, 150), math.random(-150, 150))
				if i % 14 == 0 then
					enemy = SteeringEnemy:new(4, 10, pos, vel, 5, 250, 0, "wander")
				else
					enemy = SteeringEnemy:new(7, 5, pos, vel, 4, 275, 0, "flock")
				end
				table.insert(self.entities, enemy)
			end

			self.stateNotLoaded = false

		end

		-- in-level architecture
		for k, v in pairs(self.levelTriggers) do

			-- trigger is on
			if v == true then
				if self.triggerNotLoaded == true then

					-- trigger needs loaded
					self:loadTrigger(k)
					self.triggerNotLoaded = false

				else

					-- check to move on / else continue with trigger actions, etc
					self:checkTrigger(k, dt)
				end
			end
		end
	end

	-- loads associated entities, data
	function Game:loadTrigger(trigger)

		-- menu triggers
		if self.state == "menu" then

			-- if trigger == "optionsMenu", etc

		end

		-- level 1 triggers
		if self.state == "level1" then

			if trigger == "wave1" then

				halfWidth = game.width / 2
				-- spawn enemies
				for i = 1, 7 do
					x_iter = 95 * i
					y_iter = math.random(-1500, -300)
					enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 300))
					enemy.life = 15
					table.insert(self.entities, enemy)
				end

				-- spawn turrets
				pos = Vector:new(125, -200)
				targetPos = Vector:new(pos.x, pos.y + 750)
				turret = Turret:new(pos, targetPos, 50, .4, 1, 100, "tank", 45)
				table.insert(self.entities, turret)	

				pos = Vector:new(350, -722)
				targetPos = Vector:new(pos.x, pos.y + 1000)
				turret = Turret:new(pos, targetPos, 50, .4, 1, 100, "tank", 45)
				table.insert(self.entities, turret)		

				pos = Vector:new(625, -400)
				targetPos = Vector:new(pos.x, pos.y + 800)
				turret = Turret:new(pos, targetPos, 50, .4, 1, 100, "tank", 45)
				table.insert(self.entities, turret)			

			end

			if trigger == "wave2" then

				-- spawn enemies
				for i = 1,8 do
					y_iter = -500 + 50 * i

					enemy = Enemy:new(Vector:new(game.width / 4, y_iter), Vector:new(150, 250),
									 "z-shape", 100, 500, "right")

					table.insert(self.entities, enemy)
				end

				for i = 1,8 do
					y_iter = -500 + 50 * i

					enemy = Enemy:new(Vector:new(3 * game.width / 4, y_iter), Vector:new(150, 250),
									 "z-shape", 100, 500, "left")

					table.insert(self.entities, enemy)
				end

				for i = 1,8 do
					y_iter = -1250 + 50 * i

					if(i % 2 == 0) then
						turningDirection = "right"
					else
						turningDirection = "left"
					end

					enemy = Enemy:new(Vector:new(game.width / 2, y_iter), Vector:new(100, 250), "z-shape",
									 100, 600, turningDirection)

					table.insert(self.entities, enemy)
				end

				-- mean, scarey turrets
				local turret = Turret:new(Vector:new(400, -100), Vector:new(400, 200), 50, .8, 2, 200, "tank", 39)
				table.insert(self.entities, turret)
				local turret = Turret:new(Vector:new(75, -400), Vector:new(250, 450), 50, .8, 2, 200, "tank", 45)
				table.insert(self.entities, turret)
				local turret = Turret:new(Vector:new(600, -700), Vector:new(520, 350), 50, .8, 2, 200, "tank", 48)
				table.insert(self.entities, turret)

			end

			if trigger == "boss" then

				-- to delay his spawning
				self.levelData.delayTime = 3

			end

			if trigger == "levelEnd" then

				-- flag + time for how long the explosion animation will last
				self.levelData.delayTime = 4
				self.levelData.explosionDelay = .3
				
			end
		end
	end

	-- decides whether trigger conditions are complete
	function Game:checkTrigger(trigger, dt)

		-- menu triggers
		if self.state == "menu" then

			if trigger == "startTrigger" then
				-- meh, clearly a hack here.
				if detect(self.mouseClick, self.startButton) then
					self.state = "level1"
					self.stateNotLoaded = true
					self.triggerNotLoaded = true
				end
			end
		end

		-- level 1 triggers
		if self.state == "level1" then

			-- UHHHHHHHHHHHHHHH
			if self.levelData.spawningDelay == nil then
				self.levelData.spawningDelay = 12
			end

			self.levelData.spawningDelay = self.levelData.spawningDelay - dt
			if self.levelData.spawningDelay < 0 then

				if trigger ~= "boss" then
					x_seed = math.random(250, self.width - 350)
					for i = 1,5 do 

						x_iter = x_seed - (40 * i)
						if i == 2 then
							y_iter = -500 - 45
						elseif i == 1 then
							y_iter = -500 - 90
						else
							y_iter = -500 - ((i % 3) * 45)
						end
						enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 300))
						enemy.life = 15
						table.insert(self.entities, enemy)

					end 
				end
				self.levelData.spawningDelay = 8

			end

			-- "wave" triggers -- spawn enemies and wait till they're dead.
			if string.sub(trigger, 1, 4) == "wave" then

				-- hm... have to gather all current enemies.. didn't expect dis
				enemies = {}
				for k, v in pairs(self.entities) do
					if v.class == "Enemy" or v.class == "Turret" then
						table.insert(enemies, v)
					end
				end

				-- condition
				if (enemies[1] == nil) then

					waveNumber = tonumber(string.sub(trigger, 5, 5))
					if waveNumber == 2 then

						self.levelTriggers["boss"] = true
						self.levelTriggers[trigger] = false
						self.triggerNotLoaded = true

					else

						waveNumber = waveNumber + 1
						nextTrigger = "wave" .. waveNumber
						self.levelTriggers[trigger] = false
						self.levelTriggers[nextTrigger] = true
						self.triggerNotLoaded = true
						
					end
				end
			end

			if trigger == "boss" then

				-- trigger still needs delayed
				if self.levelData.delayTime ~= nil then

					if self.levelData.delayTime > 0 then

						self.levelData.delayTime = self.levelData.delayTime - dt

					elseif self.levelData.delayTime < 0 then

						-- spawn boss
						boss = Boss:new(Vector:new(100, -150), Vector:new(100, 25), Vector:new(50,0), 600, 150, 5000, .05, game.player)
						table.insert(self.entities, boss)

						self.levelData.delayTime = nil

					end
				end

				if self.levelData.delayTime == nil then
					boss = {}
					for k,v in pairs(self.entities) do
						if v.class == "Boss" then
							table.insert(boss, v) 
						end
					end
					if boss[1] == nil then

						self.title = "SHMUP -- OH AND.. YOU WON."
						self.state = "menu"
						self.stateNotLoaded = true
						self.triggerNotLoaded = true

					end
				end
			end

			if trigger == "levelEnd" then

				-- if detect(self.mouseClick, self.startButton) then
				-- 	self.state = "level1"
				-- 	self.stateNotLoaded = true
				-- 	self.triggerNotLoaded = true
				-- end

			end
		end
	end

	function Game:resolveCollision(a, b)

		-- weapons vs. X
		if(a.class == "Bullet") then

			-- who shot it? {player, enemy}
			if a.owner == "player" then
				-- hit a default enemy
				if b.class == "Enemy" then
					-- result
					b.health = b.health - a.damage
					a.isDead_ = true
					
				end

				-- hit a 'turret' type
				if b.class == "Turret" then 
					-- result
					attackedSound = love.audio.newSource("/audio/enemyHit.wav")
					attackedSound:setPitch(.5)
					attackedSound:setVolume(.6)
					attackedSound:play()
					b.health = b.health - a.damage
					b.gotHitTimer = 0
					a.isDead_ = true
				end

				-- hit boss 1
				if b.class == "Boss" then
					-- result
					b.health = b.health - a.damage
					a.isDead_ = true
				end
			end

			if a.owner == "enemy" then

				-- hit the player
				if b.class == "Player" then
					-- mark the player to die
					if not b.invul_ then
						b.isDead_ = true
					end
					a.isDead_ = true
				end
			end
		end

		if(a.class == "Laser") then

			if b.class == "Enemy" or b.class == "Turret" or b.class == "Boss" then

				b.health = b.health - a.damage

			end

		end

		-- player vs. X
		if(a.class == "Player") then

			-- vs. boss, enemy, etc.
			if(b.class == "Enemy") or (b.class == "Boss") or (b.class == "Turret") then
				-- mark player to die
				if not a.invul_ then
					a.isDead_ = true
				end
			end
			-- powerups
			if(b.class == "PowerUp") then
				b.isDead_ = true
				if a.bulletLevel < 2 then a.bulletLevel = a.bulletLevel + 1 end
			end
		end
	end

	-- used to player death sounds, animations, spawn items, etc.
	function Game:resolveDeath(entity)

		local pos = entity.pos
		if entity.class == "Enemy" then
			local smlExplosion = love.audio.newSource("/audio/smallExplosion.wav", "static")
			smlExplosion:setPitch(2.2)
			smlExplosion:setVolume(.4)
			local snappyPart = love.audio.newSource("/audio/snappyExplosion.wav", "static")
			snappyPart:setPitch(.7)
			snappyPart:setVolume(.1)
			snappyPart:play()
			smlExplosion:play()
			pos = pos + 16
			self:explode("small", pos) 
		elseif entity.class == "Turret" then
			local smlExplosion = love.audio.newSource("/audio/smallExplosion.wav", "static")
			smlExplosion:setPitch(1.3)
			smlExplosion:setVolume(.4)
			smlExplosion:play() 

			self:explode("small", pos)
			if math.random(1, 4) == 1 then 
				powerup = PowerUp:new(entity.pos, 10)
				table.insert(self.entities, powerup)
			end

		elseif entity.class == "Player" then
			pos = pos + 16
			local smlExplosion = love.audio.newSource("/audio/smallExplosion.wav", "static")
			smlExplosion:setPitch(.4)
			smlExplosion:setVolume(.9)
			smlExplosion:play() 

			self:explode("small", pos)
		elseif entity.class == "Boss" then

		end

	end

	-- explosionType : string, pos : Vector
	function Game:explode(explosionType, pos)

		if explosionType == "small" then
			self.smallExplosionFlash:setPosition(pos.x, pos.y)
			self.smallExplosionFireSmoke:setPosition(pos.x, pos.y)
			self.smallExplosionFireSmoke:emit(21)
			self.smallExplosionFlash:emit(30)
		end

	end

MenuButton = Object:new({class = "MenuButton"})

	function MenuButton:new(text, pos, width, height)

		local button = Object:new({text = text or "", pos = pos or Vector:new(0,0),
								   width = width or 0, height = height or 0})
		setmetatable(button, self)
		self.__index = self
		return button

	end

	function MenuButton:draw()

		-- the box
		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height) 
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p3.x, p3.y, p4.x, p4.y, p2.x, p2.y)

		-- the text
		love.graphics.print(self.text, self.pos.x + 50, self.pos.y + 50)

	end

	function MenuButton:collision()

		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		T1 = BoundingTriangle:new(p1, p2, p4)
		T2 = BoundingTriangle:new(p1, p3, p4)
		return BoundingAggregate:new({T1, T2})

	end


CircleObstacle = Object:new({class = "CircleObstacle"})

	function CircleObstacle:new(pos, radius)

		local circle = Object:new({pos = pos or Vector:new(0, 0), radius = radius})
		setmetatable(circle, self)
		self.__index = self
		return circle

	end

	function CircleObstacle:collision()

		return BoundingSphere:new(self.pos, self.radius)

	end

	function CircleObstacle:draw()

		love.graphics.circle("line", self.pos.x, self.pos.y, self.radius)

	end

	function CircleObstacle:update()

	end

Bullet = Object:new({class = "Bullet"})

	function Bullet:new(pos, vel, life, damage, owner, bulletType)

		local bullet = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			life = life or 0, damage = damage or 0,
			owner = owner or "player", isDead_ = false,
			bulletType = bulletType or "single"
		})

		if bullet.owner == "enemy" then
			bullet.image = love.graphics.newImage("/graphics/redbullet.png")
			bullet.width = 8
			bullet.height = 8
		elseif bullet.owner == "player" then
			if bullet.bulletType == "single" then
				bullet.image = love.graphics.newImage("/graphics/playerbullet.png")
				bullet.width = 6 
				bullet.height = 12
			elseif bullet.bulletType == "double" then
				bullet.image = love.graphics.newImage("/graphics/playerDoubleBullet.png")
				bullet.width = 16
				bullet.height = 12
			end
		end

		setmetatable(bullet,self)
		self.__index = self
		return bullet

	end

	function Bullet:draw()

		love.graphics.draw(self.image, self.pos.x, self.pos.y)

	end

	function Bullet:collision()

		if self.owner == "enemy" then
			local v = Vector:new(self.pos.x + self.width/2, 
								 self.pos.y + self.height/2)
			return BoundingAggregate:new({BoundingSphere:new(v,4)})
		elseif self.owner == "player" then
			local p1 = self.pos
			local p2 = Vector:new(self.pos.x + self.width, self.pos.y)
			local p3 = Vector:new(self.pos.x, self.pos.y + self.height)
			local p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
			return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p4), BoundingTriangle:new(p2, p3, p4)})
		end

	end

	function Bullet:update(dt)

		self.life = self.life - dt;
		self.pos.y = self.pos.y - self.vel.y * dt
		self.pos.x = self.pos.x + self.vel.x * dt

		-- too far off screen? go away!
		if self.pos.x > game.width + 25 or self.pos.x < -25 or self.pos.y > game.height + 25 or self.pos.y < -25 then
			self.isDead_ = true
		end 

	end

Laser = Object:new({class = "Laser"})

	function Laser:new(spawn_pos, length, damage, owner)

		local laser = Object:new({
			spawn_pos = spawn_pos or Vector:new(0, 0), 
			length = length or 225,
			damage = damage or 0,
			angle = 0, goal_angle = 0, rot_vel = math.pi / 1200,
			owner = owner or "player"
		})

		-- find angle
		ship_middle = Vector:new(game.player.pos.x + game.player.width / 2, game.player.pos.y + game.player.height / 2)
		vec_A = (spawn_pos - ship_middle)
		laser.angle = math.atan2(vec_A.y, vec_A.x)
		if laser.angle < 0 then laser.angle = laser.angle + math.pi * 2 end

		laser.end_pos = ship_middle + (laser.spawn_pos):normalize() * laser.length

		-- for later use
		clockwise_angle = 0
		counterclockwise_angle = 0

		setmetatable(laser, self)
		self.__index = self
		return laser

	end

	function Laser:collision()

		-- this is a hack.
		arbitrary_vec = Vector:new(1,1)
		local p1 = self.spawn_pos - arbitrary_vec
		local p2 = self.spawn_pos + arbitrary_vec
		local p3 = self.end_pos - arbitrary_vec
		local p4 = self.end_pos + arbitrary_vec
		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p2, p1)
		return BoundingAggregate:new({T1, T2})

	end

	function Laser:update(dt)

		-- update position if the ship is moving
		if game.player.isMovingX then

			self.spawn_pos.x = self.spawn_pos.x - game.player.vel.x * dt * game.player.a
									  + game.player.vel.x * dt * game.player.d
			self.end_pos.x = self.end_pos.x + game.player.vel.x * dt * game.player.a
									  - game.player.vel.x * dt * game.player.d
		end

		if game.player.isMovingY then
			
			self.spawn_pos.y = self.spawn_pos.y + game.player.vel.y * dt * game.player.s
									  - game.player.vel.y * dt * game.player.w
			self.end_pos.y = self.end_pos.y + game.player.vel.y * dt * game.player.s
									  - game.player.vel.y * dt * game.player.w

		end

		-- calculate new vector based on mouse position
		ship_middle = Vector:new(game.player.pos.x + game.player.width / 2, game.player.pos.y + game.player.height / 2)
		ship_to_mouse = (game.mousePos - ship_middle)

		vec_A = ship_to_mouse

		self.goal_angle = math.atan2(vec_A.y, vec_A.x)

		-- keep it in the range [0, 2pi); 
		-- note that since (0,0) is top left, positive rotation is clockwise.
		if self.goal_angle < 0 then self.goal_angle = self.goal_angle + math.pi * 2 end

		-- find the counterclockwise and clockwise angles if we need to rotate
		if self.angle < (self.goal_angle - self.rot_vel) or self.angle > (self.goal_angle + self.rot_vel) then

			if self.angle > self.goal_angle then

				counterclockwise_angle = self.angle - self.goal_angle
				clockwise_angle = 2*math.pi - self.angle + self.goal_angle

			elseif self.goal_angle > self.angle then

				clockwise_angle = self.goal_angle - self.angle
				counterclockwise_angle = 2*math.pi - self.goal_angle + self.angle
			
			end
		end

		--print("clck: " .. tostring(clockwise_angle) .. " cc: " .. tostring(counterclockwise_angle) .. " angle: " .. tostring(self.angle))
		
		-- determine if we need to rotate
		if self.angle < (self.goal_angle - 2*self.rot_vel) or self.angle > (self.goal_angle + 2*self.rot_vel) then

			-- determine which angle is smallest rotate in
			if clockwise_angle < (counterclockwise_angle) then

				-- rotate counterclockwise
				self.angle = self.angle + self.rot_vel

				-- keep it in the range (0, 2pi]
				self.angle = self.angle % (2*math.pi)

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(self.rot_vel)
				spawn_pos = spawn_pos:normalize()
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * self.length)

			end

			if counterclockwise_angle < (clockwise_angle) then

				-- rotate clockwise
				self.angle = self.angle - self.rot_vel

				-- keep it in range (0, 2pi]
				if self.angle <= 0 then self.angle = 2*math.pi + self.angle end

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(- self.rot_vel)
				spawn_pos = spawn_pos:normalize()
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * self.length)

			end
		end
	end

	function Laser:draw()

		local p1 = self.spawn_pos
		local p2 = self.end_pos
		love.graphics.line(p1.x, p1.y, p2.x, p2.y)

	end

PowerUp = Object:new({class = "PowerUp"})

	function PowerUp:new(pos, lifetime)

		powerup = Object:new({pos = pos or Vector:new(0,0),
							  vel = Vector:new(0, 75),
							  CONST_VEL = Vector:new(0, 10),
							  lifetime = lifetime or 0,
							  width = 25, height = 25,
							  time = 0})
		powerup.image = love.graphics.newImage("/graphics/powerup1.png")
		setmetatable(powerup, self)
		self.__index = self
		return powerup

	end

	function PowerUp:collision()

		local p1 = self.pos 
		local p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		local p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		
		local p4 = self.pos
		local p5 = Vector:new(self.pos.x, self.pos.y + self.height)
		local p6 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p5, p6)
		return BoundingAggregate:new({T1, T2})

	end

	function PowerUp:draw()

		love.graphics.draw(self.image, self.pos.x, self.pos.y)
		
	end

	function PowerUp:update(dt)

		-- lissajous curve :-)
		self.time = self.time + dt
		local a = 2
		local b = 1 
		local v = self.vel
		local k = self.vel
		local X_AMP = 50
		local Y_AMP = 50

		local x = X_AMP * math.sin(a * self.time)
		local y = Y_AMP * math.sin(b * self.time)

		self.vel.x = x
		self.vel.y = y

		self.pos = Vector:new(self.pos.x + self.vel.x * dt, self.pos.y + self.vel.y * dt)
		self.pos = self.pos + self.CONST_VEL * dt
		self.lifetime = self.lifetime - dt

	end

SpringBall = Object:new({class = "SpringBall"})

	function SpringBall:new(pos, equilibriumPos, k)

		spring = Object:new({pos = pos,
							 equilibriumPos = equilibriumPos or pos,
							 vel = Vector:new(0, 0), acc = Vector:new(0, 0),
							 k = k or .25})
		setmetatable(spring, self)
		self.__index = self
		return spring

	end

	function SpringBall:collision()

		return BoundingAggregate:new({})

	end

	function SpringBall:draw()

		-- draw the line from the equilibrium pos to the current position (tether)
		love.graphics.line(self.equilibriumPos.x, self.equilibriumPos.y, self.pos.x, self.pos.y)

		-- draw the ball
		love.graphics.circle("fill", self.pos.x, self.pos.y, 5)

	end

	function SpringBall:update(dt)

		-- find velocity based on Hooke's Law
		displacement = (self.pos - self.equilibriumPos)
		self.acc = (- self.k * displacement)

		self.vel = self.vel + self.acc
		self.pos = self.pos + self.vel * dt

	end

Bomb = Object:new({class = "Bomb"})

Shield = Object:new({class = "Shield"})
