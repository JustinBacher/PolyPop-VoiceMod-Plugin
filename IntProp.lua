Instance.properties = properties({
    {name="Prop", type="Int", onUpdate="onValueUpdate"},
})

function Instance:onValueUpdate(value)
    self:getParent()onValueUpdate(self, value)
end