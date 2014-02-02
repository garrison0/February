require "object"
require "utility"

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

Player = Object:new({class = "Player"})

	function Player:new(pos, vel)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = 0, width = 64, height = 64,
			bulletLevel = 1, a = 0, s = 0, d = 0, w = 0
		})
		setmetatable(player,self)
		self.__index = self
		return player
	end

	function Player:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingSphere:new(v,30)
	end

	-- TODO: Move Player-Member functions in here

Enemy = Object:new({class = "Enemy"})

	function Enemy:new(pos, vel)
		local enemy = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			amplitude = 200, width = 32, height = 32
		})
		setmetatable(enemy,self)
		self.__index = self
		return enemy
	end

	function Enemy:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingSphere:new(v,15)
	end

	-- TODO: Move Enemy-Member functions in here

Bullet = Object:new({class = "Bullet"})

	function Bullet:new(pos, vel, life, damage)
		local bullet = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			life = life or 0, damage = damage or 0, width = 8, height = 8
		})
		setmetatable(bullet,self)
		self.__index = self
		return bullet
	end

	function Bullet:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingSphere:new(v,4)
	end

	-- TODO: Move Bullet-Member functions in here