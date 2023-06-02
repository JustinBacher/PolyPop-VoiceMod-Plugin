Instance.properties = properties({
    {name="Value", type="Bool", onUpdate="onParamUpdate"},
})

function Instance:initParam(name, info)
	self.name = name
	self.properties.Value = info.value
	getUI():setUIProperty({{obj=self, expand=true}})
end

function Instance:onParamUpdate()
    self:getParent():onParamUpdate(self, self.properties.Value)
end