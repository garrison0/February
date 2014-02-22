require "object"
require "utility"

BoundingAggregate = Object:new({class = "BoundingAggregate"})

	function BoundingAggregate:new(aggregate)
		local boundingAggregate = Object:new(aggregate or {})
		setmetatable(aggregate, self)
		self.__index = self
		return boundingAggregate
	end

BoundingSphere = Object:new({class = "BoundingSphere"})

	function BoundingSphere:new(center, radius)
		local sphere = Object:new({center = center or Vector:new(0,0),
								   radius = radius or 0})
		setmetatable(sphere,self)
		self.__index = self
		return sphere
	end

	--[[ translation
		x must be either a BoundingSphere, Vector, or number
		y must be either a BoundingSphere, Vector, or number
		one and only one of x and y must be a BoundingSphere
	--]]
	function BoundingSphere.__add(x, y)
		local x_isSphere = x.class == "BoundingSphere"
		local y_isSphere = y.class == "BoundingSphere"
		if x_isSphere and y_isSphere then
		elseif x_isSphere then
			local v = Vector:new(0,0)
			v = v + y
			return BoundingSphere:new(x.center + v, x.radius)
		elseif y_isSphere then
			local v = Vector:new(0,0)
			v = v + x
			return BoundingSphere:new(y.center + v, y.radius)
		end
	end

	function BoundingSphere.__sub(x, y)
		local x_isSphere = x.class == "BoundingSphere"
		local y_isSphere = y.class == "BoundingSphere"
		if x_isSphere and y_isSphere then
		elseif x_isSphere then
			local v = Vector:new(0,0)
			v = v + y
			return BoundingSphere:new(x.center - v, x.radius)
		elseif y_isSphere then
			local v = Vector:new(0,0)
			v = v + x
			return BoundingSphere:new(y.center - v, y.radius)
		end
	end

BoundingTriangle = Object:new({class = "BoundingTriangle"})
	
	function BoundingTriangle:new(p1, p2, p3)
		local triangle = Object:new({p1 = p1 or Vector:new(0,0),
									p2 = p2 or Vector:new(0,0),
									p3 = p3 or Vector:new(0,0)})
		setmetatable(triangle, self)
		self.__index = self
		return triangle
	end

	-- TO DO: translation functions

Game = Object:new({class = "Game"})

	function Game:new(initial_state, width, height, fullscreen)

		love.window.setMode(width, height, {fullscreen = fullscreen or false})
		local game = {width = width or 0, height = height or 0, 
					stateNotLoaded = true, fullscreen = fullscreen or false}
		game.state = initial_state or "level1"
		setmetatable(game, self)
		self.__index = self
		return game

	end

	function Game:resizeWindow(w, h)

		self.width = w
		self.height = h
		love.window.setMode(w, h)

	end

	function Game:setState(state)

		self.gamestate = state

	end

	function Game:update()


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

Player = Object:new({class = "Player"})

	function Player:new(pos, vel)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = 0, 
			width = 32, height = 32, bulletLevel = 1, bullets = {},
			laserOn = false, laserEnergy = 100000,
			a = 0, s = 0, d = 0, w = 0
		})
		setmetatable(player,self)
		self.__index = self
		return player
	end

	function Player:collision()
		local p1 = Vector:new(player.pos.x + 14, player.pos.y + 11)
		local p2 = Vector:new(player.pos.x + 18, player.pos.y + 11)
		local p3 = Vector:new(player.pos.x + 18, player.pos.y + 18)
		local p4 = Vector:new(player.pos.x + 14, player.pos.y + 18)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3), BoundingTriangle:new(p1, p4, p3)})
	end

	function Player:update(dt)
		-- player
		-- keep it on screen
		if self.pos.x + self.width >= shmupgame.width then
			self.pos.x = shmupgame.width - self.width
		end
		if self.pos.x <= 0 then
			self.pos.x = 0
		end
		if self.pos.y + self.height >= shmupgame.height then
			self.pos.y = shmupgame.height - self.height
		end
		if self.pos.y <= 0 then
			self.pos.y = 0
		end

		self.pos.x = self.pos.x - self.vel.x * dt * self.a
									  + self.vel.x * dt * self.d
		self.pos.y = self.pos.y + self.vel.y * dt * self.s
									  - self.vel.y * dt * self.w

		-- delay
		self.fire_delay = self.fire_delay - dt

		-- deplete laser energy
		if (self.laserOn) then

			self.laserEnergy = self.laserEnergy - (100 * dt)
			if self.laserEnergy <= 0 then

				self.laserOn = false

			end
		end
	end

	function Player:shoot()
		-- level 1
		if (player.bulletLevel == 1) then
			bullet = Bullet:new(Vector:new(player.pos.x + player.width/2, player.pos.y), 
										   Vector:new(0,1000), 1, 10)

			player.fire_delay = .3
			table.insert(player.bullets, bullet)
		end

		-- level 2
		if (player.bulletLevel == 2) then
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 10)

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 10)

			player.fire_delay = .2
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
		end

		-- level 3
		if (player.bulletLevel == 3) then
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 10)

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 10)

			bullet3 = Bullet:new(Vector:new(player.pos.x + player.width, player.pos.y), 
										Vector:new(200,800), 1, 10)

			bullet4 = Bullet:new(Vector:new(player.pos.x, player.pos.y), 
										Vector:new(-200,800), 1, 10)

			player.fire_delay = .1
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
			table.insert(player.bullets, bullet3)
			table.insert(player.bullets, bullet4)
		end
	end

	function Player:shootLaser(mouse_pos)

		if self.laserEnergy > 0 then
			ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
			ship_to_mouse = (mouse_pos - ship_middle)
			ship_to_mouse = (ship_to_mouse * (1/ship_to_mouse:norm()))

			spawn_pos = ship_middle + (ship_to_mouse * 32)
			end_pos = spawn_pos + (ship_to_mouse * 225)
			laser = Laser:new(spawn_pos, end_pos, 1, 5)

			player.laser = laser
			player.laserOn = true
		end
	end

Enemy = Object:new({class = "Enemy"})

	function Enemy:new(pos, vel, pathingType, minDepth, maxDepth, turningDirection)
		local enemy = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			pathingType = pathingType or "standard", amplitude = 200, 
			health = 5, life = 12, width = 32, height = 32
		})

		-- special parameters for this pathing type
		if pathingType == "z-shape" then

			enemy.minDepth = minDepth
			enemy.maxDepth = maxDepth
			enemy.turningDirection = turningDirection
			enemy.pathingPhase = 0

		end

		setmetatable(enemy,self)
		self.__index = self
		return enemy
	end

	function Enemy:collision()

		local p1 = self.pos
		local p2 = Vector:new(self.pos.x + 32, self.pos.y)
		local p3 = Vector:new(self.pos.x + 16, self.pos.y + 32)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3)})

	end

	function Enemy:update(dt)

		-- update life
		self.life = self.life - dt

		if self.pathingType == "standard" then

			self.pos = self.pos + self.vel * dt

		end

		-- moves like a wave
		if self.pathingType == "wave" then

			self.pos.x = self.pos.x + math.sin(self.pos.y / 10) * self.amplitude * dt
			self.pos.y = self.pos.y + self.vel.y * dt

		end

		-- z-shape
		if self.pathingType == "z-shape" then

			if self.pathingPhase == 0 then

				self.pos.y = self.pos.y + self.vel.y * dt

				if self.pos.y >= self.maxDepth then

					self.pathingPhase = 1
					-- update velocity according to turn direction
					if self.turningDirection == "right" then

						self.vel = Vector:new(self.vel.x, -self.vel.y)

					elseif self.turningDirection == "left" then

						self.vel = -1 * self.vel

					end
				end
			end

			if self.pathingPhase == 1 then


				self.pos = self.pos + self.vel * dt

				if self.pos.y <= self.minDepth then

					self.pathingPhase = 2

				end
			end

			if self.pathingPhase == 2 then

				self.vel = Vector:new(0, -self.vel.y)
				self.pathingType = "standard"

			end
		end
	end

	function Enemy:draw()

		love.graphics.polygon("line", {self.pos.x, self.pos.y, self.pos.x + 32, self.pos.y, self.pos.x + 16, self.pos.y + 32})

	end

Turret = Object:new({class = "Turret"})

	function Turret:new(pos, targetPos, velScalar, fireDelay, bulletLevel, health, width, height)
		turret = Object:new({pos = pos, targetPos = targetPos or Vector:new(0,0),
				  velScalar = velScalar or 50,
				  fireDelay = fireDelay or 1, fireRate = fireDelay or 1, 
				  width = width or 32, height = height or 32,
				  bulletLevel = bulletLevel or 1, health = health or 100, life = life or 20})
		self.__index = self
		setmetatable(turret, self)
		return turret
	end

	function Turret:update(dt)

		-- update the position
		if self.targetPos - self.pos ~= Vector:new(0, 0) then

			-- find velocity direction, multiply by velocity scalar.
			direction = (self.targetPos - self.pos)
			direction = direction * (1 / direction:norm())
			velocity = direction * self.velScalar

			self.pos = self.pos + velocity * dt

		end

		self.fireDelay = self.fireDelay - dt

		if self.fireDelay <= 0 then

			-- fire at the player depending upon bulletLevel
			player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
			turret_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
			turret_to_player = (player_middle - turret_middle)
			turret_to_player = (turret_to_player * (1/turret_to_player:norm()))

			velocity = turret_to_player * 200
			velocity.y = velocity.y * -1

			if self.bulletLevel == 1 then

				bullet = Bullet:new(turret_middle + turret_to_player * 50, velocity, 10, 10)
				table.insert(shmupgame.enemyBullets, bullet)

			end

			if self.bulletLevel == 9 then

				velocity = velocity:rotate(-math.pi / 2)
				variance = math.random(-1, 1)

				for i = 1, 11 do

					velocity = velocity:rotate(math.pi / (variance + 11))
					bullet = Bullet:new(turret_middle + turret_to_player * 50, velocity, 10, 10)
					table.insert(shmupgame.enemyBullets, bullet)

				end
			end

			self.fireDelay = self.fireRate
		end
	end

	function Turret:collision()

		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3), BoundingTriangle:new(p2, p3, p4)})

	end

	function Turret:draw()

		-- draw the box
		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p3.x, p3.y)

		-- draw the gun
		player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
		turret_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
		turret_to_player = (player_middle - turret_middle)
		turret_to_player = (turret_to_player * (1/turret_to_player:norm()))

		endpos = turret_middle + (turret_to_player * 50)
		love.graphics.line(turret_middle.x, turret_middle.y, endpos.x, endpos.y)

	end

Boss = Object:new({class = "Boss"})

	function Boss:new(pos, vel, width, height, health, fireDelay)

		local boss = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			health = health or 0, width = width or 0, height = height or 0,
			fireRate = fireDelay or .5, fireDelay = fireDelay or .5
		})
		setmetatable(boss, self)
		self.__index = self
		return boss

	end

	function Boss:update(dt)

		self.pos = self.pos + self.vel * dt

		if self.pos.x + self.width > shmupgame.width - 50 or self.pos.x < 50 then
			self.vel.x = self.vel.x * -1
		end


		self.fireDelay = self.fireDelay - dt

		self.pos = self.pos + self.vel * dt

		-- gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height + 25)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height + 25)
		points = {p7, p8}

		if self.fireDelay <= 0 then

			for i = 1, 2 do

				player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
				gun_to_player = (player_middle - points[i])
				gun_to_player = (gun_to_player * (1 / gun_to_player:norm()))

				velocity = gun_to_player * 300
				velocity.y = -1 * velocity.y

				bullet = Bullet:new(points[i], velocity, 10, 10)
				table.insert(shmupgame.enemyBullets, bullet)

			end

			self.fireDelay = self.fireRate

		end
	end

	function Boss:collision()

		-- shape of a long hexagon
		local p1 = Vector:new(self.pos.x, self.pos.y + self.height / 2)
		local p2 = Vector:new(self.pos.x + self.width / 8, self.pos.y)
		local p3 = Vector:new(self.pos.x + self.width / 8, self.pos.y + self.height)
		
		local p4 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y)
		local p5 = Vector:new(self.pos.x + self.width, self.pos.y + self.height / 2)
		local p6 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y + self.height)

		-- additional gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height)

		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p5, p6)
		T3 = BoundingTriangle:new(p2, p4, p3)
		T4 = BoundingTriangle:new(p3, p6, p4)
		T5 = BoundingTriangle:new(Vector:new(p7.x + 10, p7.y), Vector:new(p7.x, p7.y + 25),
								  Vector:new(p7.x - 10, p7.y))
		T6 = BoundingTriangle:new(Vector:new(p8.x + 10, p8.y), Vector:new(p8.x, p8.y + 25),
								  Vector:new(p8.x - 10, p8.y))

		return BoundingAggregate:new({T1, T2, T3, T4, T5, T6})

	end

	function Boss:draw()

		-- main shape
		local p1 = Vector:new(self.pos.x, self.pos.y + self.height / 2)
		local p2 = Vector:new(self.pos.x + self.width / 8, self.pos.y)
		local p3 = Vector:new(self.pos.x + self.width / 8, self.pos.y + self.height)
		
		local p4 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y)
		local p5 = Vector:new(self.pos.x + self.width, self.pos.y + self.height / 2)
		local p6 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y + self.height)

		-- additional gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height)

		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p5.x, p5.y, p6.x, p6.y, 
									  p7.x + 10, p7.y, p7.x, p7.y + 25, p7.x - 10, p7.y, 
									  p8.x + 10, p8.y, p8.x, p8.y + 25, p8.x - 10, p8.y,
									  p3.x, p3.y)

	end

Bullet = Object:new({class = "Bullet"})

	function Bullet:new(pos, vel, life, damage)

		local bullet = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			life = life or 0, damage = damage or 0, width = 4, height = 4
		})
		setmetatable(bullet,self)
		self.__index = self
		return bullet

	end

	function Bullet:collision()

		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingAggregate:new({BoundingSphere:new(v,2)})

	end

	function Bullet:update(dt)

		self.life = self.life - dt;
		self.pos.y = self.pos.y - self.vel.y * dt
		self.pos.x = self.pos.x + (self.vel.x or 0) * dt

	end

Laser = Object:new({class = "Laser"})

	function Laser:new(spawn_pos, end_pos, damage)

		local laser = Object:new({
			spawn_pos = spawn_pos or Vector:new(0, 0), 
			end_pos = end_pos or Vector:new(0, 0),
			damage = damage or 0,
			angle = 0, goal_angle = 0, rot_vel = math.pi / 1200
		})

		-- find angle from x axis
		ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)

		vec_A = end_pos - ship_middle
		
		laser.angle = math.atan2(vec_A.y, vec_A.x)
		if laser.angle < 0 then laser.angle = laser.angle + math.pi * 2 end

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

	function Laser:update(dt, mouse_pos)

		-- calculate new vector based on mouse position
		ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
		ship_to_mouse = (mouse_pos - ship_middle)

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
		if self.angle < (self.goal_angle - self.rot_vel) or self.angle > (self.goal_angle + self.rot_vel) then

			-- determine which angle is smallest rotate in
			if clockwise_angle < (counterclockwise_angle) then

				-- rotate counterclockwise
				self.angle = self.angle + self.rot_vel

				-- keep it in the range (0, 2pi]
				self.angle = self.angle % (2*math.pi)

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(self.rot_vel)
				spawn_pos = spawn_pos * (1 / spawn_pos:norm())
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * 258)

			end

			if counterclockwise_angle < (clockwise_angle) then

				-- rotate clockwise
				self.angle = self.angle - self.rot_vel

				-- keep it in range (0, 2pi]
				if self.angle <= 0 then self.angle = 2*math.pi + self.angle end

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(- self.rot_vel)
				spawn_pos = spawn_pos * (1 / spawn_pos:norm())
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * 258)

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
							  lifetime = lifetime or 0,
							  width = 25, height = 25})
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

		local p1 = self.pos 
		local p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		local p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		local p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p3.x, p3.y)

	end

	function PowerUp:update(dt)

		self.pos = self.pos + self.vel * dt
		self.lifetime = self.lifetime - dt

	end

Bomb = Object:new({class = "Bomb"})

Shield = Object:new({class = "Shield"})
