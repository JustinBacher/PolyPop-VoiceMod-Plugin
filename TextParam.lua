Instance.properties = properties({
    {name="Value", type="Text", onUpdate="onParamUpdate"},
})

function Instance:initParam(name, info)
	self.name = name
	self.properties.Value = info.value
end

function Instance:onParamUpdate()
    self:getParent():onParamUpdate(self, self.properties.Value)
end