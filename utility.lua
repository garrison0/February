require "object"

Vector = Object:new({class = "Vector"})

function Vector:new(x, y)
	local vector = Object:new({x = x or 0, y = y or 0})
	setmetatable(vector,self)
	self.__index = self
	return vector
end

function Vector.__add(a, b)
	local ax, ay, bx, by
	
	if type(a) == "number" then
		ax = a; ay = a
	else
		ax = a.x; ay = a.y
	end

	if type(b) == "number" then
		bx = b; by = b
	else
		bx = b.x; by = b.y	
	end
	
	return Vector:new(ax + bx, ay + by)
end

function Vector.__sub(a, b)
	local ax, ay, bx, by
	
	if type(a) == "number" then
		ax = a; ay = a
	else
		ax = a.x; ay = a.y
	end

	if type(b) == "number" then
		bx = b; by = b
	else
		bx = b.x; by = b.y	
	end
	
	return Vector:new(ax - bx, ay - by)
end

function Vector.__mul(a, b)
	local ax, ay, bx, by
	
	if type(a) == "number" then
		ax = a; ay = a
	else
		ax = a.x; ay = a.y
	end

	if type(b) == "number" then
		bx = b; by = b
	else
		bx = b.x; by = b.y	
	end

	if type(a) == "number" or type(b) == "number" then
		return Vector:new(ax*bx, ay*by)
	else
		return ax*bx + ay*by
	end
end

function Vector.__unm(a)
	return Vector:new(-a.x, -a.y)
end

function Vector.__eq(a, b)
	if a.x == b.x and a.y == b.y then
		return true
	else
		return false
	end
end

function Vector.__newindex(t, k, v)
	error("Cannot add members to Vector table or instances")
end

function Vector.__tostring(v)
	return "(" .. v.x .. "," .. v.y .. ")"
end

function Vector:norm()
	return math.sqrt(self.x*self.x + self.y*self.y)
end

function Vector:angle()
	return math.atan2(self.y,self.x)
end

function Vector:normalize()
	return self * (1 / self:norm())
end

function Vector:rotate(theta)
	return Vector:new(self.x*math.cos(theta) - self.y*math.sin(theta),
					  self.x*math.sin(theta) + self.y*math.cos(theta))
end

function Test_Vector()
	local zero = Vector:new(0,0)
	local one = Vector:new(1,1)
	local a = Vector:new(1,0)
	local b = Vector:new(0,1)

	local c = a
	assert(c == a and a == c)
	assert(c ~= b and b ~= c)

	c = a + b
	assert(c == one and one == c)
	c = b + a
	assert(c == one and one == c)
	c = a - a
	assert(c == zero and zero == c)
	c = -(-a)
	assert(c == a)
	c = (a + b) + b
	d = a + (b + b)
	assert(c == d)

	c = zero + 1
	assert(c == one)
	c = 1 + zero
	assert(c == one)
	c = one - 1
	assert(c == zero)
	c = 1 - one
	assert(c == zero)

	local t = Vector:new(2,0)
	local v = Vector:new(0,2)
	local two = Vector:new(2,2)

	c = 2*a
	assert(c == t)
	c = a*2
	assert(c == t)
	c = one*2
	assert(c == two)

	num = a*b
	assert(num == 0)
	num = one*two
	assert(num == 4)

	c = Vector:new(3,4)
	assert(c:norm() == 5)

	c = Vector:new(1,1)
	assert(c:angle()*180/math.pi == 45)

	if pcall(function () local c = Vector:new(); c.z = 1; end) then
		assert(false)
	end

	c = one:normalize()
	assert(c == Vector:new(1 / math.sqrt(2), 1 / math.sqrt(2)))
end
