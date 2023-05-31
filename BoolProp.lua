Instance.properties = properties({
    {name="Prop", type="Bool", onUpdate="onValueUpdate"},
})

function Instance:onValueUpdate()
    self:getParent()onValueUpdate(self, value)
end