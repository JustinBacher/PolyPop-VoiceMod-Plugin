local random = math.random

--[[
    UUID function from this gist:
    https://gist.github.com/jrus/3197011
]]
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local voicemodPorts = {59129, 20000, 39273, 42152, 43782, 46667, 35679, 37170, 38501, 33952, 30546}

Instance.properties = properties({
    {name="App", type="PropertyGroup", items={
        {name="Status", type="Text", value="Disconnected", readonly=true},
        {name="License", type="Text", value="free", readonly=true},
    }, ui={expand=true}},
    {name="VoiceChanger", type="PropertyGroup", items={
        {name="Voice", type="Enum", onUpdate="onVoiceUpdate"},
        {name="VoiceProperties", type="ObjectSet", readonly=true},
        {name="VoiceChanger", type="Bool", onUpdate="onVoiceChangerUpdate"},

        {name="Background", type="Bool", onUpdate="onBackgroundUpdate"},
        {name="MicMuted", type="Bool", onUpdate="onMicMuteUpdate"},
        {name="Beep", type="Bool", onUpdate="onBeepUpdate"},
    }},
    {name="Memes", type="PropertyGroup", items={
        {name="StopAllMemes", type="Action"},
        {name="MuteForMe", type="Bool", onUpdate="onMuteForMeUpdate"},
        {name="MemeSound", type="Enum", onUpdate="onMemeSoundUpdate"},
        {name="PlayMeme", type="Action"},
    }},
})

function Instance:onInit()
    self.host = getNetwork():getHost("localhost")
    self:attemptConnection()
end


--[[--------------------------------------------------------------
    Functions to update VoiceMod
]]----------------------------------------------------------------

function Instance:onPropValueUpdate(prop, value)
    self:send({[prop:getName()]=value})
end

function Instance:onVoiceUpdate()
    local voice = self.properties.VoiceChanger.Voice.value
    for i = 1, #self.voices do
        if self.voices[i].friendlyName == voice then
            self:send({action="loadVoice", payload={voiceID=self.voices[i].id}})
            return
        end
    end
end

function Instance:onVoiceChangerUpdate()
    self:send({action="toggleVoiceChanger"})
end

function Instance:onBackgroundUpdate()
    self:send({action="toggleBackground"})
end

function Instance:onMicMuteUpdate()
    self:send({action="toggleMuteMic"})
end

function Instance:onBeepUpdate()
    self:send({action="setBeepSound", payload={badLanguage=self.properties.voiceChanger.Beep and 1 or 0}})
end

function Instance:StopAllMemes()
    self:send({action="stopAllMemeSounds"})
end

function Instance:onMuteForMeUpdate()
    self:send({action="toggleMuteForMe"})
end

function Instance:PlayMeme()

end


--[[--------------------------------------------------------------
    Functions received from VoiceMod
]]----------------------------------------------------------------

function Instance:clientRegistered(port)
    for p, ws in pairs(self.websockets) do
        if p == port then
            self.webSocket = ws
        else
            self.websockets[p] = nil
        end
    end
end

function Instance:updateVoices(obj)
    self.voices = obj.voices
    local voices = {}

    for i = 1, #self.voices do
        table.insert(voices, self.voices.friendlyName)
    end

    self.properties.VoiceChanger.Voice:setElements(voices)
    self.properties.VoiceChanger.Voice.value = obj.currentVoice
end

function Instance:()
    
end

function Instance:()
    
end

local responseActions = {
    getVoice=Instance.updateVoices
}


--[[--------------------------------------------------------------
    Websocket Functions
]]----------------------------------------------------------------

function Instance:send(cmd)
    if self.webSocket and self.webSocket:isConnected() then
        cmd.id = self.identity
        
        if cmd.payload == nil then
            cmd.payload = {}
        end
        
        self.webSocket:send(json.encode(cmd))
    elseif cmd.action ~= "requestClient" then
        print("VoiceMod not running. Please start VoiceMod.")
    end
end

function Instance:attemptConnection()
    self.websockets = {}
    for _, port in ipairs(voicemodPorts) do
        local ws = self.host:openWebSocket(string.format("ws://localhost:%s/v1", port))
        ws:addEventListener("onMessage", self, self._onWsMessage(port))
        ws:addEventListener("onConnected", self, self._onWsConnected)
        ws:addEventListener("onDisconnected", self, self._onWsDisconnected)
        self.websockets[port] = ws
    end
end

function Instance:_onWsConnected(port)
    return function()
        self.identity = uuid()

        self:send({
            action="registerClient",
            payload={
                clientKey="xxx",
            },
        })
    end
end

function Instance:_onWsMessage(port)
	return function(port)
        local payload = json.decode(msg)

        if payload.actionType == "requestClient" then
            self:clientRegistered(port)
            return
        end

        local action = responseActions[payload.actionType]

        if action == nil then
            print(payload.actionType)
            return
        end
        action(self, payload.actionObject)
    end
end

function Instance:_onWsDisconnected()
    --Create timer to check connection repeatedly until VoiceMod opens back up
end
