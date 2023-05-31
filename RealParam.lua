Instance.properties = properties({
    {name="Prop", type="Real", onUpdate="onParamUpdate"},
})

function Instance:onParamUpdate(value)
    self:getParent()onParamUpdate(self, value)
end