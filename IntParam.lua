Instance.properties = properties({
    {name="Prop", type="Int", onUpdate="onParamUpdate"},
})

function Instance:onParamUpdate(value)
    self:getParent()onParamUpdate(self, value)
end