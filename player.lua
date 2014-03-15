require "object"

Player = Object:new({class = "Player"})

	function Player:new(pos, invul_)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = .2, 
			width = 32, height = 32, bulletLevel = 1, bullets = {},
			laserOn = false, laserEnergy = 100000,
			a = 0, s = 0, d = 0, w = 0,
			isMovingX = false, isMovingY = false,
			isChargingLaser = false, chargeLength = 1.5,
			currentCharge = 0, isDead_ = false,
			invul_ = invul_ or false, invulTime = 3, currentInvul = 0,
		})
		-- PARTICLE SYSTEM : ROCKET FIRE
		local particleImage = love.graphics.newImage("/graphics/fireSmoke.png")
		local p = love.graphics.newParticleSystem(particleImage, 255)
		p:setEmissionRate(100)
		p:setParticleLifetime(.25)
		p:setDirection(math.pi/2)
		p:setSpread(.2)
		p:setSpeed(50)
		p:setRadialAcceleration(10)
		p:setTangentialAcceleration(0)
		p:setSizes(.11, .01)
		p:setSizeVariation(.4)
		p:setRotation(0)
		p:setSpin(0)
		p:setSpinVariation(0)
		p:setColors({245, 239, 51, 180}, {237, 218, 200, 5})
		p:stop()
		player.leftRocketParticles = p
		player.rightRocketParticles = p

		-- PARTICLE SYSTEM : FLASH BANG
		local particleImage = love.graphics.newImage("/graphics/particle.png")
		local p = love.graphics.newParticleSystem(particleImage, 255)
		local emitRate = 1 / player.fire_delay
		p:setEmissionRate(emitRate)
		p:setParticleLifetime(1 / 30)
		p:setSizes(2.5)
		p:setSizeVariation(0)
		p:setColors({255, 247, 247, 140}, {255, 240, 240, 10})
		p:stop()
		player.flashBangParticle = p

		-- ANIMATION
		player.animation = {}
		player.animation.middle = love.graphics.newImage("/graphics/shipMiddle.png")
		player.animation.left1 = love.graphics.newImage("/graphics/shipLeft1.png")
		player.animation.left2 = love.graphics.newImage("/graphics/shipLeft2.png")
		player.animation.right1 = love.graphics.newImage("/graphics/shipRight1.png")
		player.animation.right2 = love.graphics.newImage("/graphics/shipRight2.png")
		player.animation.delayTime = 0
		player.frame = 1
		player.image = player.animation.middle

		-- AUDIO
		player.shootSound = love.audio.newSource("/audio/playerShot.wav", "static")
		player.shootSound:setVolume(1)

		setmetatable(player, self)
		self.__index = self
		return player
	end

	function Player:collision()
		local p1 = Vector:new(self.pos.x + 14, self.pos.y + 11)
		local p2 = Vector:new(self.pos.x + 18, self.pos.y + 11)
		local p3 = Vector:new(self.pos.x + 18, self.pos.y + 18)
		local p4 = Vector:new(self.pos.x + 14, self.pos.y + 18)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3), BoundingTriangle:new(p1, p4, p3)})
	end

	function Player:draw()

		-- FRAME 1 = MIDDLE POSITION : animation.middle
		-- FRAME 2 = FIRST LEFT ROLL : animation.left1
		-- FRAME 3 = FIRST RIGHT ROLL: animation.right1
		-- FRAME 4 = SECOND RIGHT ROLL:animation.right2
		-- FRAME 5 = SECOND LEFT ROLL: animation.left2
		if self.invul_ then
			love.graphics.setColor(255, 255, 255, 140)
		else
			-- draw rocket/flashBang
			if self.frame == 1 then
				rightOffset = 24
				leftOffset = 6
			elseif self.frame == 2 or self.frame == 3 then
				rightOffset = 22
				leftOffset = 8
			elseif self.frame == 4 or self.frame == 5 then
				rightOffset = 20
				leftOffset = 10
			end

			love.graphics.draw(self.flashBangParticle, self.pos.x + 15, self.pos.y - 8)
			love.graphics.draw(self.rightRocketParticles, self.pos.x + rightOffset, self.pos.y + self.height)
			love.graphics.draw(self.leftRocketParticles, self.pos.x + leftOffset, self.pos.y + self.height)
		end
		love.graphics.draw(self.image, self.pos.x, self.pos.y)
		love.graphics.setColor(255, 255, 255, 255)

	end

	function Player:update(dt)

		-- update particle systems
		self.leftRocketParticles:start()
		self.leftRocketParticles:update(dt) 
		self.rightRocketParticles:start()
		self.rightRocketParticles:update(dt) 
		self.flashBangParticle:update(dt)
		if self.shooting then self.flashBangParticle:start() else self.flashBangParticle:stop() end

		-- update animation
		if self.isMovingX then
			-- rolling right?
			if self.isMovingRight then
				self:animate(dt, "right")
			end
			-- rolling left?
			if self.isMovingLeft then
				self:animate(dt, "left")
			end
			-- idling? -- move back to middle
			if not (self.isMovingLeft or self.isMovingRight) then
				self:animate(dt, "idle")
			end
		end

		if self.a == 1 then 
			self.isMovingRight = false
			self.isMovingLeft = true
		else
			self.isMovingLeft = false
		end


		if self.d == 1 then 
			self.isMovingLeft = false
			self.isMovingRight = true
		else
			self.isMovingRight = false
		end

		-- update flag (used in laser)
		if self.a ~= 0 or self.d ~= 0 or self.s ~= 0 or self.w ~= 0 then 
			self.isMoving = true; self.isMovingX = true; self.isMovingY = true else self.isMoving = false 
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
			if self.shooting and not self.invul_ then
				self:shoot()
			end
		end

		-- build up charge
		if self.isChargingLaser then

			self.currentCharge = self.currentCharge + dt
			self.shooting = false

		end

		if self.currentCharge >= self.chargeLength and self.laserOn == false then

				ship_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
				ship_to_mouse = (game.mousePos - ship_middle)
				ship_to_mouse = ship_to_mouse:normalize()

				spawn_pos = ship_middle + Vector:new(0, -32) 

				laser = Laser:new(spawn_pos, 425, 1, "player")
				table.insert(game.entities, laser)

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

	-- direction : rolling left or right? determined in update
	function Player:animate(dt, direction)

		local MIDDLE_TO_LEFT = .12
		local MIDDLE_TO_RIGHT = .12
		local LEFT_TO_MIDDLE = .1
		local RIGHT_TO_MIDDLE = .1
		local LEFT_TO_LEFT2 = .1
		local RIGHT_TO_RIGHT2 = .1
		local RIGHT2_TO_RIGHT = .1
		local LEFT2_TO_LEFT = .1
		local function moveOn(player, time)
			if player.animation.delayTime > time then
				player.animation.delayTime = 0
				return true
			end
		end

		-- To delay frame changes.
		self.animation.delayTime = self.animation.delayTime + dt

		-- FRAME 1 = MIDDLE POSITION : animation.middle
		-- FRAME 2 = FIRST LEFT ROLL : animation.left1
		-- FRAME 3 = FIRST RIGHT ROLL: animation.right1
		-- FRAME 4 = SECOND RIGHT ROLL:animation.right2
		-- FRAME 5 = SECOND LEFT ROLL: animation.left2

		-- MIDDLE POSITION -> FIRST LEFT ROLL
		if self.frame == 1 and direction == "left" then
			if moveOn(self, MIDDLE_TO_LEFT) then
				self.frame = 2
				self.image = self.animation.left1
			end
		end

		-- MIDDLE POSITION -> FIRST RIGHT ROLL
		if self.frame == 1 and direction == "right" then
			if moveOn(self, MIDDLE_TO_RIGHT) then
				print(self.animation.delayTime)
				self.frame = 3
				self.image = self.animation.right1
			end
		end

		-- FIRST LEFT ROLL -> MIDDLE POSITION
		if self.frame == 2 and (direction == "right" or direction == "idle") then 
			if moveOn(self, LEFT_TO_MIDDLE) then
				self.frame = 1
				self.image = self.animation.middle
			end
		end 

		-- FIRST LEFT ROLL -> SECOND LEFT ROLL
		if self.frame == 2 and direction == "left" then
			if moveOn(self, LEFT_TO_LEFT2) then
				self.frame = 5
				self.image = self.animation.left2
			end
		end

		-- SECOND LEFT ROLL -> FIRST LEFT ROLL
		if self.frame == 5 and (direction == "right" or direction == "idle") then
			if moveOn(self, LEFT2_TO_LEFT) then
				self.frame = 2
				self.image = self.animation.left1
			end
		end

		-- FIRST RIGHT ROLL -> MIDDLE POSITION
		if self.frame == 3 and (direction == "left" or direction == "idle") then
			if moveOn(self, RIGHT_TO_MIDDLE) then
				self.frame = 1
				self.image = self.animation.middle
			end
		end

		-- FIRST RIGHT ROLL -> SECOND RIGHT ROLL 
		if self.frame == 3 and direction == "right" then
			if moveOn(self, RIGHT_TO_RIGHT2) then
				self.frame = 4
				self.image = self.animation.right2
			end
		end

		-- SECOND RIGHT ROLL -> FIRST RIGHT ROLL
		if self.frame == 4 and (direction == "left" or direction == "idle") then
			if moveOn(self, RIGHT2_TO_RIGHT) then
				self.frame = 3
				self.image = self.animation.right1
			end
		end
	end

	function Player:shoot()
		-- audio
		self.shootSound:rewind()
		self.shootSound:play()

		-- level 1
		if (self.bulletLevel == 1) then
			bullet = Bullet:new(Vector:new(self.pos.x + self.width/2 - 8, self.pos.y - 8), 
										Vector:new(0, 750), 1, 16, "player", "double")

			self.fire_delay = .2
			table.insert(game.entities, bullet)
		end

		-- level 2
		if (self.bulletLevel == 2) then
			local firstX = self.pos.x + (self.width/2 - 3) - 4 
			local secondX = self.pos.x + (self.width/2 - 3) + 4
			bullet = Bullet:new(Vector:new(self.pos.x + self.width/2 - 8, self.pos.y - 8), 
										Vector:new(0, 750), 1, 16, "player", "double")

			bullet3 = Bullet:new(Vector:new(firstX - 4, self.pos.y), 
										Vector:new(-150,700), 1, 6, "player")

			bullet4 = Bullet:new(Vector:new(secondX + 4, self.pos.y), 
										Vector:new(150,700), 1, 6, "player")

			self.fire_delay = .15
			table.insert(game.entities, bullet)
			table.insert(game.entities, bullet3)
			table.insert(game.entities, bullet4)
		end
	end

	function Player:shootLaser()

		if self.laserEnergy > 0 then

			self.isChargingLaser = true

		end
	end