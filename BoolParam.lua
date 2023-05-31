Instance.properties = properties({
    {name="Prop", type="Bool", onUpdate="onParamUpdate"},
})

function Instance:onParamUpdate()
    self:getParent()onParamUpdate(self, self.properties.Value)
end