-- https://gist.github.com/jrus/3197011
local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

Instance.properties = properties({
    {name="App", type="PropertyGroup", items={
        {name="Status", type="Text", value="Disconnected", readonly=true},
        {name="License", type="Text", value="free", readonly=true},
    }, ui={expand=true}},
    {name="VoiceChanger", type="PropertyGroup", items={
        {name="Voice", type="Enum"},
        {name="VoiceProperties", type="ObjectSet"},
        {name="VoiceChanger", type="Bool"},
        {name="Background", type="Bool"},
        {name="MicMuted", type="Bool"},
        {name="Beep", type="Bool"},
    }},
    {name="Memes", type="PropertyGroup", items={
        {name="StopAllMemes", type="Action"},
        {name="MuteForMe", type="Bool"},
        {name="MemeSound", type="Enum"},
        {name="PlayMeme", type="Action"},
    }},
})

function Instance:onInit()
    self:attemptConnection()
end

function Instance:send(cmd)
    if self.webSocket and self.webSocket:isConnected() then
        cmd.id = self.identity
        self.webSocket:send(json.encode(cmd))
    elseif cmd.action ~= "requestClient" then
        print("VoiceMod not running. Please start VoiceMod.")
    end
end

function Instance:attemptConnection()
	local host = getNetwork():getHost("localhost")
	self.webSocket = host:openWebSocket("ws://localhost:/v1")
	self.webSocket:setAutoReconnect(true)

	self.webSocket:addEventListener("onMessage", self, self._onWsMessage)
	self.webSocket:addEventListener("onConnected", self, self._onWsConnected)
	self.webSocket:addEventListener("onDisconnected", self, self._onWsDisconnected)
end

function Instance:_onWsConnected()
    self.identity = uuid()

    self:send({
        action="registerClient",
        payload={
            clientKey="xxx",
        },
    })
end

function Instance:_onWsDisconnected()
    --Create timer to check connection repeatedly until VoiceMod opens back up
end

function Instance:clientRegistered()
    
end

function Instance:()
    
end

function Instance:()
    
end

function Instance:()
    
end

local responseActions = {
    requestClient=self.clientConnected,

}

function Instance:_onWsMessage(msg)
	local payload = json.decode(msg)
	local action = responseActions[payload.actionType]

    if action == nil then
        print(payload.actionType)
        return
    end
    action(self, payload.actionObject)
end