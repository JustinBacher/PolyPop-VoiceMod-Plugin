Instance.properties = properties({
    {name="Prop", type="Real", onUpdate="onValueUpdate"},
})

function Instance:onValueUpdate(value)
    self:getParent()onValueUpdate(self, value)
end