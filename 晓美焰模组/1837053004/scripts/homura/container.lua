local OffsetQueue = Class(function(self, data, offset)
	self.data = data
	self.offset = offset or 0
end)

function OffsetQueue:__index(i)
	if type(i) == "number" then
		i = i + self.offset
		if i > #self.data then
			i = i - #self.data
		end
		return self.data[i]
	end
	error()
end

return {
	OffsetQueue = OffsetQueue,
}