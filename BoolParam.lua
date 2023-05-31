Instance.properties = properties({
    {name="Prop", type="Bool", onUpdate="onParamUpdate"},
})

function Instance:onParamUpdate(value)
    self:getParent()onParamUpdate(self, value)
end