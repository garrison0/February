require "object"
require "physics"
tween = require "tween"

-- generic moving enemy
Enemy = Object:new({class = "Enemy"})

	function Enemy:new(pos, vel, pathingType, minDepth, maxDepth, turningDirection)
		local enemy = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			pathingType = pathingType or "standard", amplitude = 200, 
			health = 5, life = 12, width = 32, height = 32
		})

		-- graphics
		enemy.image = love.graphics.newImage("/graphics/genericShip.png")

		-- special parameters for this pathing type
		if pathingType == "z-shape" then

			enemy.minDepth = minDepth
			enemy.maxDepth = maxDepth
			enemy.turningDirection = turningDirection
			enemy.pathingPhase = 0

		end

		-- PARTICLE SYSTEM : ROCKET FIRE
		local particleImage = love.graphics.newImage("/graphics/fireSmoke.png")
		local p = love.graphics.newParticleSystem(particleImage, 255)
		p:setEmissionRate(120)
		p:setParticleLifetime(.25)
		p:setDirection(-math.pi/2)
		p:setSpread(.15)
		p:setSpeed(50)
		p:setRadialAcceleration(10)
		p:setTangentialAcceleration(0)
		p:setSizes(.15, .01)
		p:setSizeVariation(.3)
		p:setRotation(0)
		p:setSpin(0)
		p:setSpinVariation(0)
		p:setColors({255, 210, 87, 220}, {237, 238, 230, 10})
		p:stop()
		enemy.rocketParticles = p

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

		-- update particle system
		self.rocketParticles:update(dt)
		self.rocketParticles:start()

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

				if self.pos.y >= self.minDepth then

					self.pathingPhase = 1
					-- update velocity according to turn direction
					if self.turningDirection == "left" then

						self.vel = Vector:new(-self.vel.x, self.vel.y)

					end
				end
			end

			if self.pathingPhase == 1 then


				self.pos = self.pos + self.vel * dt

				if self.pos.y >= self.maxDepth then

					self.pathingPhase = 2

				end
			end

			if self.pathingPhase == 2 then

				self.vel = Vector:new(0, self.vel.y)
				self.pathingType = "standard"

			end
		end
	end

	function Enemy:draw()

		-- particles
		love.graphics.draw(self.rocketParticles, self.pos.x + 14, self.pos.y)
		-- ship
		love.graphics.draw(self.image, self.pos.x, self.pos.y)

	end

-- AI-based enemy
-- for info: http://www.red3d.com/cwr/steer/gdc99/
SteeringEnemy = Object:new({class = "SteeringEnemy"})

	function SteeringEnemy:new(mass, radius, pos, vel, max_force, max_speed, orientation, behaviorType, target)
			
		enemy = Object:new({mass = mass, pos = pos, vel = vel, max_force = max_force,
							radius = radius, max_speed = max_speed, orientation = orientation,
							behaviorType = behaviorType or "seek", target = target or Vector:new(400, 400)})
		self.__index = self
		setmetatable(enemy, self)
		if behaviorType == "wandering" then enemy.initializeSteering = true end
		return enemy

	end

	function SteeringEnemy:update(dt)

		-- keep it on screen
		self.pos.x = self.pos.x % game.width
		self.pos.y = self.pos.y % game.height

		-- determine steering force
		-- fixed target point
		if self.behaviorType == "seek" then

			desired_velocity = (self.target - self.pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		if self.behaviorType == "flee" then

			desired_velocity = (self.pos - self.target):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		-- NOTE: these two assume you pass in a target object, not a position.
		-- dynamic target; entity
		if self.behaviorType == "pursuit" then

			target_pos = self.target.pos
			desired_velocity = (target_pos - self.pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		if self.behaviorType == "evade" then

			target_pos = self.target.pos
			desired_velocity = (self.pos - target_pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		-- fixed target
		if self.behaviorType == "arrival" then

			offset = self.target - self.pos
			distance = offset:norm()
			slowing_distance = 110
			ramped_speed = self.max_speed * (distance / slowing_distance)
			clipped_speed = math.min(ramped_speed, self.max_speed)
			desired_velocity = (clipped_speed / distance) * offset
			self.steering = desired_velocity - self.vel

		end

		-- no target
		if self.behaviorType == "flock" then

			-- find members of a local neighborhood
			self.neighbors = {}
			neighborhood_distance = 100
			for i, v in ipairs(enemies) do

				distance_between = (v.pos - self.pos):norm()
				if distance_between <= neighborhood_distance then

					table.insert(self.neighbors, v)

				end
			end

			--[[ 
				seperation behavior: maintain a distance apart from others
						1. find the distance between each object in the neighborhood
						2. normalize and weigh it by 1 / r
						3. sum together all of the repulsive forces
						4. the steering force = the sum of all repulsive forces
			]]
			seperation_steering = 0
			for i, v in ipairs(self.neighbors) do

				repulsive_force = self.pos - v.pos
				distance = repulsive_force:norm()
				repulsive_force = repulsive_force:normalize()

				-- account for divide by zero error
				if distance == 0 then distance = .001 end

				repulsive_force = repulsive_force * (1 / distance)^2
				seperation_steering = seperation_steering + repulsive_force

			end

			--[[ 
				cohesion behavior: keep the flock together
						1. find average position in the neighborhood
						2. steer in the direction of that position
			]]
			total_position = Vector:new(0,0)
			count = 0
			for i, v in ipairs(self.neighbors) do

				count = count + 1
				total_position = total_position + v.pos

			end
			-- "gravity center" of the neighborhood
			average_position = total_position * (1 / count)
			cohesion_steering = self.pos - average_position

			--[[ 
				alignment behavior: steer the flock in the same direction
						1. find average (desired) velocity 
						2. steering in the diection of that velocity
			]]
			total_velocity = 0
			count = 0 
			for i, v in ipairs(self.neighbors) do

				count = count + 1
				total_velocity = total_velocity + v.vel

			end
			desired_velocity = total_velocity * (1 / count)
			alignment_steering = desired_velocity - self.vel

			-- normalize three behaviors, scale by weighting factors, then combine.
			alignment_steering = alignment_steering:normalize()
			seperation_steering = seperation_steering:normalize()
			cohesion_steering = cohesion_steering:normalize()

			self.steering = 40*(.5 * alignment_steering + .1 * seperation_steering + .4 * cohesion_steering)

		end

		-- random steering
		if self.behaviorType == "wandering" then

			-- steering movement is constrained to the perimeter of a circle 
			-- in front of the vehicle
			circleRadius = 75
			velNorm = self.vel:normalize()
			circleCenter = self.pos + velNorm * 25 + velNorm * circleRadius
			maximumOffset = math.pi / 1000
			if self.initializeSteering == true then
				self.posOnCircle = Vector:new(circleRadius, 0)
				self.initializeSteering = false
			else
				offset = math.random(-maximumOffset, maximumOffset)
				self.posOnCircle = self.posOnCircle:rotate(offset)
			end
			posInWorld = circleCenter + self.posOnCircle
			self.steering = posInWorld - self.pos

		end

		-- avoid spherical obstacles
		if self.behaviorType == "obstacleAvoidance" then

			MAX_AHEAD = 200
			vecAhead = self.pos + (self.vel:normalize() * MAX_AHEAD)
			perpVec = (self.vel:normalize()):rotate(math.pi / 2)
			leftSide = {self.pos - perpVec * 16, vecAhead - perpVec * 16}
			rightSide = {self.pos + perpVec * 16, vecAhead + perpVec * 16}
			obstaclesInLine = {}
			for i, v in ipairs(obstacles) do

				if CirclevsLine(v:collision(), leftSide) then
					table.insert(obstaclesInLine, v)
				end
				if CirclevsLine(v:collision(), rightSide) then
					table.insert(obstaclesInLine, v)
				end

			end

			if obstaclesInLine[1] ~= nil then
				prioritizedObstacle = obstaclesInLine[1]
				shortestDist = (obstaclesInLine[1].pos - self.pos):norm()
				for i, v in ipairs(obstaclesInLine) do

					distance = (v.pos - self.pos):norm()
					if distance < shortestDist then
						shortestDist = distance
						prioritizedObstacle = v
					end

				end

				-- found primary obstacle to avoid, now find steering force.
				steering = self.pos - prioritizedObstacle.pos
				self.steering = (steering * perpVec) * perpVec 
			else
				self.steering = Vector:new(0, 0)
			end
		end

		-- truncate the steering force by max force
		if self.steering:norm() > self.max_force then
			self.steering = self.steering:normalize() * self.max_force
		end

		-- determine acceleration
		self.acc = self.steering * (1 / self.mass)

		-- truncate velocity by max speed
		self.vel = self.vel + self.acc
		self.vel = self.vel * 1.001

		if self.vel:norm() > self.max_speed then
			self.vel = self.vel:normalize() * self.max_speed
		end

		-- update position
		self.pos = self.pos + self.vel * dt

		-- update orientation (which way is it facing?)
		self.orientation = self.vel:angle()

	end

	function SteeringEnemy:collision()

		--return BoundingAggregate:new({BoundingSphere:new(self.pos, self.radius)})
		return BoundingAggregate:new({})

	end

	function SteeringEnemy:draw()

		p1 = self.pos
		velNorm = self.vel:normalize() 
		velPerp = velNorm:rotate(math.pi / 2)
		backEnd = (p1 - velNorm * 32)
		p2 = backEnd + velPerp * 16
		p3 = backEnd - velPerp * 16
		love.graphics.polygon("line", self.pos.x, self.pos.y, p2.x, p2.y, p3.x, p3.y)

		if self.behaviorType == "obstacleAvoidance" then

			local vecAhead = self.pos + (self.vel:normalize() * MAX_AHEAD)
			perpVec = (self.vel:normalize()):rotate(math.pi / 2)
			leftSide = {self.pos - perpVec * 16, vecAhead - perpVec * 16}
			rightSide = {self.pos + perpVec * 16, vecAhead + perpVec * 16}
			love.graphics.line(leftSide[2].x, leftSide[2].y, rightSide[2].x, rightSide[2].y)
			love.graphics.line(leftSide[1].x, leftSide[1].y, leftSide[2].x, leftSide[2].y)
			love.graphics.line(rightSide[1].x, rightSide[1].y, rightSide[2].x, rightSide[2].y)

		end

		-- if self.behaviorType == "wandering" then
		-- 	-- draw circle
		-- 	circleCenter = p1 + velNorm * 25 + velNorm * circleRadius
		-- 	love.graphics.circle("line", circleCenter.x, circleCenter.y, circleRadius)
		-- 	-- draw position on the circle
		-- 	love.graphics.circle("fill", posInWorld.x, posInWorld.y, 5)
		-- end
		-- draw the target
		--if self.target.class == "Vector" then
		--	love.graphics.circle("fill", self.target.x, self.target.y, 5, 100)
		--else
		--	love.graphics.circle("fill", self.target.pos.x, self.target.pos.y, 5, 100)
		--end
		
		-- draw the velocity vec
		love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.vel.x / 5, self.pos.y + self.vel.y / 5)
		-- draw steering force
		love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.steering.x * 10, self.pos.y + self.steering.y * 10)

	end

-- Move and Shoot enemy
Turret = Object:new({class = "Turret"})

	function Turret:new(pos, targetPos, velScalar, fireDelay, bulletLevel, health, turretType, tweenLength)
		turret = Object:new({pos = pos, targetPos = targetPos or Vector:new(0,0),
				  velScalar = velScalar or 50, turretType = turretType or "tank",
				  fireDelay = fireDelay or 1, fireRate = fireDelay or 1, 
				  bulletLevel = bulletLevel or 1, health = health or 100, life = life or 20,
				  isTweened = false, tweenLength = tweenLength or 50})
		if turret.turretType == "tank" then
			-- "tank" specific parameters
			turret.width = 56
			turret.height = 46
			turret.image = love.graphics.newImage("/graphics/turretTank.png")
			turret.turretImage = love.graphics.newImage("/graphics/tankTurret.png")
			local direction = (turret.targetPos - turret.pos)
			turret.direction = direction:normalize()
			turret.turretEnd = turret.pos + turret.direction * 46

			-- for tweening... it works, ok?
			turret.posTweenTable = {x = pos.x, y = pos.y}
			turret.targetTweenTable = {x = targetPos.x, y = targetPos.y}

			-- FLASH BANG
			local particleImage = love.graphics.newImage("/graphics/particle.png")
			local p = love.graphics.newParticleSystem(particleImage, 255)
			local emitRate = 1 / turret.fireRate
			p:setEmissionRate(emitRate)
			p:setParticleLifetime(.03)
			p:setSizes(3.2)
			p:setSizeVariation(0)
			p:setRotation(0)
			p:setColors({255, 255, 255, 210}, {255, 240, 240, 10})
			p:stop()
			turret.flashBangParticle = p
		end
		self.__index = self
		setmetatable(turret, self)
		return turret
	end

	function Turret:update(dt)

		-- for i,v in pairs(game.entities) do
		-- 	if v.class == "Bullet" then print(v.pos) end
		-- end

		if not self.isTweened then
			-- POSITION TWEEN
			tween(self.tweenLength, self.posTweenTable,
					  self.targetTweenTable, "inOutQuad")
			self.isTweened = true
		end

		--self.direction = (turret.targetPos - turret.pos):normalize()

		self.pos.x = self.posTweenTable.x
		self.pos.y = self.posTweenTable.y

		self.flashBangParticle:update(dt)
		self.flashBangParticle:start()

		-- update the position tweening
		tween.update(dt)

		self.fireDelay = self.fireDelay - dt

		if self.fireDelay <= 0 then

			-- fire at the player depending upon bulletLevel
			player_middle = Vector:new(game.player.pos.x + game.player.width / 2, game.player.pos.y + game.player.height / 2)
			turret_middle = Vector:new(self.pos.x + self.width/2, self.pos.y + self.height/2)
			turret_to_player = (player_middle - turret_middle)
			turret_to_player = turret_to_player:normalize()
			turret_to_player.y = turret_to_player.y * -1

			self:shoot(turret_to_player)

		end
	end

	function Turret:shoot(direction)

		bulletPosition = self.turretEnd

		if self.bulletLevel == 1 then

			velocity = direction * 200
			bullet = Bullet:new(bulletPosition, velocity, 10, 10, "enemy")
			table.insert(game.entities, bullet)

		end
		
		if self.bulletLevel == 2 then

			-- lua has the most pain in the ass standard lib. random i've ever fucking witnessed
			math.randomseed(os.time())
			math.random(); math.random(); math.random()

			for i = 1, 7 do

				spread = .1
				if math.random(0, 1) == 1 then 
					angle = math.random() * spread
				else
					angle = math.random() * -spread
				end

				velocity = direction * math.random(175, 200)
				bulletVelocity = velocity:rotate(angle)
				local bullet = Bullet:new(bulletPosition + math.random(-1, 1), bulletVelocity + math.random(-1, 1), 10, 10, "enemy")
				table.insert(game.entities, bullet)

			end
		end

		self.fireDelay = self.fireRate

	end

	function Turret:collision()

		local vecPerp = self.direction:rotate(math.pi / 2)
		p1 = self.pos - (self.direction * (self.height / 2)) + (vecPerp * (self.width / 2))
		p2 = self.pos - (self.direction * (self.height / 2)) - (vecPerp * (self.width / 2))
		p3 = self.pos + (self.direction * (self.height / 2)) + (vecPerp * (self.width / 2))
		p4 = self.pos + (self.direction * (self.height / 2)) - (vecPerp * (self.width / 2))
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p4), BoundingTriangle:new(p1, p3, p4)})

	end

	function Turret:draw()

		-- flash bang
		love.graphics.draw(self.flashBangParticle, self.turretEnd.x, self.turretEnd.y)

		-- draw the tank
		tankAngle = self.direction:angle()
		love.graphics.draw(self.image, self.pos.x, self.pos.y, tankAngle, 1, 1, self.width/2, self.height/2)

		-- draw the gun
		player_middle = Vector:new(game.player.pos.x + game.player.width / 2, game.player.pos.y + game.player.height / 2)
		turret_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
		turret_to_player = (player_middle - turret_middle)
		turret_to_player = (turret_to_player * (1/turret_to_player:norm()))

		turretAngle = turret_to_player:angle()
		self.turretEnd = self.pos + turret_to_player * 46
		love.graphics.draw(self.turretImage, self.pos.x, self.pos.y, turretAngle, 1, 1, 8, 8)

	end

-- First Boss
Boss = Object:new({class = "Boss"})

	function Boss:new(pos, posTarget, vel, width, height, health, fireDelay, target)

		local boss = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			posTarget = posTarget or Vector:new(50, 50),
			health = health or 0, width = width or 0, height = height or 0,
			fireRate = fireDelay or .5, fireDelay = fireDelay or .5,
			phase = 1, target = target
		})
		setmetatable(boss, self)
		self.__index = self
		return boss

	end

	function Boss:update(dt)

		-- approached the position yet? (introduces the boss normally)
		if not self.reachedTarget then
			if (self.posTarget - self.pos):norm() > 5 then

				-- travel towards it
				local vel = (self.posTarget - self.pos):normalize()
				local VEL_SCALAR = 75
				local vel = vel * VEL_SCALAR
				self.pos = self.pos + vel * dt

			else
				self.reachedTarget = true
			end
		else
			self.target = game.player
			
			self.pos = self.pos + self.vel * dt

			if self.pos.x + self.width > game.width - 10 or self.pos.x < 10 then
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

					player_middle = Vector:new(self.target.pos.x + self.target.width / 2, self.target.pos.y + self.target.height / 2)

					-- add self.target velocities to be cheeky 
					local vel = Vector:new(self.target.vel.x, self.target.vel.y)
					variance = (4 * math.random(0, 400) / math.sqrt(vel:norm()))

					player_middle.x = player_middle.x + variance *((vel.x * dt * -self.target.a)
													  + (vel.x * dt * self.target.d))
													  + math.random(-25, 25)

					player_middle.y = player_middle.y + variance *((vel.y * dt * -self.target.w)
													  + (vel.y * dt * self.target.s))
													  + math.random(-25, 25)

					gun_to_player = (player_middle - points[i])
					gun_to_player = (gun_to_player * (1 / gun_to_player:norm()))

					velocity = gun_to_player * 400
					velocity.y = -1 * velocity.y

					bullet = Bullet:new(points[i], velocity, 10, 10, "enemy")
					table.insert(game.entities, bullet)

				end

				self.fireDelay = self.fireRate

			end
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

-- TO BE DETERMINED.. Springy/Rotationy Thing
BossTwo = Object:new({class = "BossTwo"})

	function BossTwo:new(pos, radius, angle, vel, rotVel, rotAcc, health, fireDelay)
		
		local boss = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			radius = radius or 0, rotVel = rotVel or 10, rotAcc = rotAcc or 1,
			fireRate = fireDelay or .5, fireDelay = fireDelay or .5,
			health = health or 5, angle = angle or 0,
		})

		ballEnd = (Vector:new(1, 0)):rotate(angle)
		ballEnd = ballEnd * radius
		ballEnd = ballEnd + pos
		boss.springBall = SpringBall:new(ballEnd, ballEnd, .1)

		setmetatable(boss, self)
		self.__index = self
		return boss

	end

	function BossTwo:update(dt)

		-- keep it on screen
		if self.pos.x + 25 >= game.width then
			self.vel.x = self.vel.x * -1
			self.pos.x = game.width - 25
		end
		if self.pos.x - 25 <= 0 then
			self.vel.x = self.vel.x * -1
			self.pos.x = 25
		end
		if self.pos.y + 25 >= game.height then
			self.pos.y = game.height - 25
			self.vel.y = self.vel.y * -1
		end
		if self.pos.y - 25 <= 0 then
			self.vel.y = self.vel.y * -1
			self.pos.y = 25
		end

		-- determine where to steer avoiding both the player and the wall

		-- spring-like wind-up for the arm (F = -k * x)
		self.rotAcc =  - .4 * self.angle

		-- update body, arm
		self.pos = self.pos + self.vel * dt
		self.rotVel = self.rotVel + self.rotAcc * dt
		self.angle = self.angle + self.rotVel * dt
		
		-- update tether ball-like thing
		ballEnd = (Vector:new(1, 0)):rotate(self.angle)
		ballEnd = ballEnd * self.radius
		ballEnd = ballEnd + self.pos
		self.springBall.equilibriumPos = ballEnd
		self.springBall:update(dt)

		-- truncate the velocity
		velocity = (self.springBall.vel):norm()
		maxVel = 3500
		if velocity > maxVel then
			direction = (self.springBall.vel):normalize()
			newVel = direction * maxVel
			self.springBall.vel = newVel
		end
	end

	function BossTwo:draw()

		-- draw rotational center
		love.graphics.circle("fill", self.pos.x, self.pos.y, 25)

		-- draw line to ball
		ballEnd = (Vector:new(1, 0)):rotate(self.angle)
		ballEnd = ballEnd * self.radius
		ballEnd = ballEnd + self.pos
		love.graphics.line(self.pos.x, self.pos.y, ballEnd.x, ballEnd.y)

		-- draw the ball on the end
		love.graphics.circle("line", ballEnd.x, ballEnd.y, 5)

		-- draw the Springball
		self.springBall:draw()

	end

	function BossTwo:collision()

		return BoundingAggregate:new({})

	end