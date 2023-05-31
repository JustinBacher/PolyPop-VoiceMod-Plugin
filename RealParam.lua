Instance.properties = properties({
    {name="Value", type="Real", onUpdate="onParamUpdate"},
})

function Instance:onParamUpdate()
    self:getParent()onParamUpdate(self, self.properties.Value)
end