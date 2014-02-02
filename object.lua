--[[
	____Metamethods____________________________________________________________
	__add(x, y)		__unm(x)		__index(t, k) or __index[k]
	__sub(x, y)		__concat(x, y)	__newindex(t, k, v)
	__mul(x, y)		__eq(x, y)		__metatable
	__div(x, y)		__lt(x, y)		__tostring(t)
	__mod(x, y)		__le(x, y)		__call(...)
	___________________________________________________________________________

	____Interface Methods______________________________________________________
	class
	[ String holding the name of the object ]
	collision or collision()
	[ Return a BoundingSphere or ref to a BoundingSphere table ]
	___________________________________________________________________________
--]]

Object = {class = "Object"}

	function Object:new(o)
		local object = o or {}
		setmetatable(object,self)
		self.__index = self
		return object
	end