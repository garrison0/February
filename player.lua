require "object"
require "objects"

Player = Object:new({class = "Player"})

	function Player:new(pos, vel)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = 0, 
			width = 32, height = 32, bulletLevel = 1, bullets = {},
			laserOn = false, laserEnergy = 100000,
			a = 0, s = 0, d = 0, w = 0,
			isMovingX = false, isMovingY = false,
			isChargingLaser = false, chargeLength = 3,
			currentCharge = 0
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

		-- update flag (used in laser)
		if self.a ~= 0 or self.s ~= 0 or self.d ~= 0 or self.w ~= 0 then 
			self.isMovingY = true; self.isMovingX = true else self.isMoving = false 
		end

		-- keep it on screen
		if self.pos.x + self.width >= shmupgame.width then
			self.pos.x = shmupgame.width - self.width
			self.isMovingX = false
		end
		if self.pos.x <= 0 then
			self.pos.x = 0
			self.isMovingX = false
		end
		if self.pos.y + self.height >= shmupgame.height then
			self.pos.y = shmupgame.height - self.height
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

		-- build up charge
		if self.isChargingLaser then

			self.currentCharge = self.currentCharge + dt
			self.shooting = false

		end

		if self.currentCharge >= self.chargeLength and player.laserOn == false then

				ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
				ship_to_mouse = (mouse_pos - ship_middle)
				ship_to_mouse = (ship_to_mouse * (1/ship_to_mouse:norm()))

				--spawn_pos = ship_middle + (ship_to_mouse * 32)
				--end_pos = spawn_pos + (ship_to_mouse * 225)
				spawn_pos = ship_middle + Vector:new(0, -32) 
				end_pos = spawn_pos + Vector:new(0, -225) 

				laser = Laser:new(spawn_pos, end_pos, 1, 5)

				self.laser = laser
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
			bullet = Bullet:new(Vector:new(player.pos.x + player.width/2, player.pos.y), 
										   Vector:new(0,1000), 1, 10)

			player.fire_delay = .2
			table.insert(player.bullets, bullet)
		end

		-- level 2
		if (player.bulletLevel == 2) then
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8)

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8)

			player.fire_delay = .2
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
		end

		-- level 3
		if (player.bulletLevel == 3) then
			bullet = Bullet:new(Vector:new(player.pos.x + 3 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8)

			bullet2 = Bullet:new(Vector:new(player.pos.x + 1 * player.width/4, player.pos.y), 
										Vector:new(0,1000), 1, 8)

			bullet3 = Bullet:new(Vector:new(player.pos.x + player.width, player.pos.y), 
										Vector:new(200,800), 1, 5)

			bullet4 = Bullet:new(Vector:new(player.pos.x, player.pos.y), 
										Vector:new(-200,800), 1, 5)

			player.fire_delay = .1
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
			table.insert(player.bullets, bullet3)
			table.insert(player.bullets, bullet4)
		end
	end

	function Player:shootLaser(mouse_pos)

		if self.laserEnergy > 0 then

			self.isChargingLaser = true

		end
	end