require "object"

Player = Object:new({class = "Player"})

	function Player:new(pos, vel, invul_)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = 0, 
			width = 32, height = 32, bulletLevel = 1, bullets = {},
			laserOn = false, laserEnergy = 100000,
			a = 0, s = 0, d = 0, w = 0,
			isMovingX = false, isMovingY = false,
			isChargingLaser = false, chargeLength = 1.5,
			currentCharge = 0, isDead_ = false,
			invul_ = invul_ or false, invulTime = 3, currentInvul = 0
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

	function Player:draw()
		love.graphics.polygon("line", {self.pos.x, self.pos.y + 32, self.pos.x + 8, self.pos.y, self.pos.x + 12, self.pos.y + 10,
	    							   self.pos.x + 14, self.pos.y + 11, self.pos.x + 16, self.pos.y + 6, self.pos.x + 18, self.pos.y + 11,
	    							   self.pos.x + 20, self.pos.y + 10, self.pos.x + 24, self.pos.y + 0, self.pos.x + 32, self.pos.y + 32,
	    							   self.pos.x + 20, self.pos.y + 18, self.pos.x + 18, self.pos.y + 18, self.pos.x + 16, self.pos.y + 24,
	    							   self.pos.x + 14, self.pos.y + 18, self.pos.x + 12, self.pos.y + 18, self.pos.x, self.pos.y + 32, self.pos.x, self.pos.y + 8})
	end

	function Player:update(dt)

		-- update flag (used in laser)
		if self.a ~= 0 or self.s ~= 0 or self.d ~= 0 or self.w ~= 0 then 
			self.isMovingY = true; self.isMovingX = true else self.isMoving = false 
		end

		-- invulnerability (spawning)
		if self.invul_ then
			self.currentInvul = self.currentInvul + dt
			if self.currentInvul > self.invulTime then
				self.invul_ = false
			end
		end

		-- keep it on screen
		if self.pos.x + self.width >= game.width then
			self.pos.x = game.width - self.width
			self.isMovingX = false
		end
		if self.pos.x <= 0 then
			self.pos.x = 0
			self.isMovingX = false
		end
		if self.pos.y + self.height >= game.height then
			self.pos.y = game.height - self.height
			self.isMovingY = false
		end
		if self.pos.y <= 0 then
			self.pos.y = 0
			self.isMovingY = false
		end

		self.pos.x = self.pos.x - self.vel.x * dt * self.a
									  + self.vel.x * dt * self.d
		self.pos.y = self.pos.y + self.vel.y * dt * self.s
									  - self.vel.y * dt * self.w

		-- delay for regular shooting
		self.fire_delay = self.fire_delay - dt

		-- shoot?
		if self.fire_delay <= 0 then
			if self.shooting then
				self:shoot()
			end
		end

		-- build up charge
		if self.isChargingLaser then

			self.currentCharge = self.currentCharge + dt
			self.shooting = false

		end

		if self.currentCharge >= self.chargeLength and player.laserOn == false then

				ship_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
				ship_to_mouse = (game.mousePos - ship_middle)
				ship_to_mouse = ship_to_mouse:normalize()

				spawn_pos = ship_middle + Vector:new(0, -32) 

				laser = Laser:new(spawn_pos, 225, 1, 5)

				self.laser = laser
				table.insert(game.entities, self.laser)
				self.laserOn = true

		end

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
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8, "player")

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8, "player")

			player.fire_delay = .2
			table.insert(game.entities, bullet)
			table.insert(game.entities, bullet2)
		end

		-- level 2
		if (player.bulletLevel == 2) then
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8, "player")

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8, "player")

			bullet3 = Bullet:new(Vector:new(player.pos.x + player.width, player.pos.y), 
										Vector:new(200,800), 1, 5, "player")

			bullet4 = Bullet:new(Vector:new(player.pos.x, player.pos.y), 
										Vector:new(-200,800), 1, 5, "player")

			player.fire_delay = .1
			table.insert(game.entities, bullet)
			table.insert(game.entities, bullet2)
			table.insert(game.entities, bullet3)
			table.insert(game.entities, bullet4)
		end
	end

	function Player:shootLaser(mouse_pos)

		if self.laserEnergy > 0 then

			self.isChargingLaser = true

		end
	end