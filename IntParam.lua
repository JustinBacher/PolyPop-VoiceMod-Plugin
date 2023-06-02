Instance.properties = properties({
    {name="Value", type="Int", onUpdate="onParamUpdate"},
})

function Instance:initParam(name, info)
	self.name = name
	self.properties:find("Value"):setRange(info.minValue, info.maxValue)
	self.properties:find("Value"):setDefaultValue(info.default)
    self.properties.Value = info.value
    getUI():setUIProperty({{obj=self, expand=true}})
end

function Instance:onParamUpdate()
    self:getParent():onParamUpdate(self, self.properties.Value)
end