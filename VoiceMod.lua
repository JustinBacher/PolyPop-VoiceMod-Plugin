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

local proper = function(str)
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end


local voicemodPorts = {59129, 20000, 39273, 42152, 43782, 46667, 35679, 37170, 38501, 33952, 30546}

Instance.properties = properties({
    {name="App", type="PropertyGroup", items={
        {name="Status", type="Text", value="Disconnected", readonly=true},
        {name="UserID", type="Text", readonly=true},
        {name="License", type="Text", readonly=true},
    }, ui={expand=true}},
    {name="VoiceChanger", type="PropertyGroup", items={
        {name="Voice", type="Enum", onUpdate="onVoiceUpdate"},
        {name="VoiceProperties", type="ObjectSet", readonly=true},
        {name="Enabled", type="Bool", onUpdate="onVoiceChangerUpdate"},
        {name="Background", type="Bool", onUpdate="onBackgroundUpdate"},
        {name="MicMuted", type="Bool", onUpdate="onMicMuteUpdate"},
        {name="HearMyself", type="Bool", onUpdate="onHearMyselfUpdate"},
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
    self:clearVoiceProperties()
    self.properties.VoiceChanger.Beep = false
end

function Instance:clearVoiceProperties()
    local kit = self.properties.VoiceChanger.VoiceProperties:getKit()
    for i = 1, kit:getObjectCount() do
        getEditor():removeFromLibrary(kitgetObjectByIndex(i))
    end
end


--[[--------------------------------------------------------------
    Functions to update VoiceMod
]]----------------------------------------------------------------

function Instance:onParamUpdate(prop, value)
    self:send({action=, payload={parameterName=[prop:getName()], parameterValue=value}})
end

function Instance:onVoiceUpdate()
    local voiceName = self.properties.VoiceChanger.Voice.value
    for _, voice in ipairs(self.voices) do
        if voice.friendlyName == voiceName then
            self:send({action="loadVoice", payload={voiceID=voice.id}})
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

function Instance:onHearMyselfUpdate()
    self:send({action="toggleHearMyVoice"})
end

function Instance:onBeepUpdate()
    self:send({action="setBeepSound", payload={badLanguage=self.properties.VoiceChanger.Beep and 1 or 0}})
end

function Instance:StopAllMemes()
    self:send({action="stopAllMemeSounds"})
end

function Instance:onMuteForMeUpdate()
    self:send({action="toggleMuteForMe"})
end

function Instance:PlayMeme()
    local memes = self.memes
    local memeName = self.properties.Memes.MemeSound.value
    for _, meme in ipairs(self.memes) do
        if meme.Name == memeName then
            self:send({action="playMeme", payload={FileName=meme.FileName, IsKeyDown=true}})
            return
        end
    end
end


--[[--------------------------------------------------------------
    Functions received from VoiceMod
]]----------------------------------------------------------------

local responseActions = {}

 function Instance:clientRegistered(port)
    for p, ws in pairs(self.websockets) do
        if p == port then
            self.webSocket = ws
        end
    end

    self.websockets = nil
    self:send({action="getVoices"})
    self:send({action="getMemes"})
    self:send({action="getHearMyselfStatus"})
    self:send({action="getCurrentVoice"})
    self:send({acion="getUser"})
    self:send({action="getUserLicense"})
    self.properties.App.Status = "Connected"
end

responseActions.getVoices = function(self, obj)
    self.voices = obj.voices
    local voices = {}

    for _, voice in ipairs(self.voices) do
        table.insert(voices, voice.friendlyName)
    end

    self.properties.VoiceChanger.Voice:setElements(voices)
    self.properties.VoiceChanger.Voice.value = obj.currentVoice
end

responseActions.getMemes = function(self, obj)
    self.memes = obj.listOfMemes
    local memes = {}

    for _, meme in ipairs(self.memes) do
        table.insert(memes, meme.friendlyName)
    end

    self.properties.Memes.MemeSound:setElements(memes)
end

responseActions.toggleVoiceChanger = function(self, obj)
    if self.properties.VoiceChanger.Enabled ~= obj.value then
        self.properties.VoiceChanger.Enabled = obj.value
    end
end

responseActions.toggleBackground = function(self, obj)
    if self.properties.VoiceChanger.Background ~= obj.value then
        self.properties.VoiceChanger.Background = obj.value
    end
end

responseActions.toggleHearMyVoice = function(self, obj)
    if self.properties.VoiceChanger.HearMyself ~= obj.value then
        self.properties.VoiceChanger.HearMyself = obj.value
    end
end

responseActions.toggleMuteMic = function(self, obj)
    if self.properties.VoiceChanger.MicMuted ~= obj.value then
        self.properties.VoiceChanger.MicMuted = obj.value
    end
end

responseActions.voiceChangedEvent = function(self, obj)
    self:send({action="getCurrentVoice"})
end

responseActions.getCurrentVoice = function(self, obj)
    self:clearVoiceProperties()
    for param, value in pairs(obj.Parameters) do
        print(param .. ": " .. value)
    end
end

responseActions.licenseTypeChanged = responseActions.getUserLicense = function(self, obj)
    self.properties.App.License = proper(obj.licenseType)
end

responseActions.getUser = function(self, obj)
    self.properties.App.UserID = obj.userID
end


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
    self.properties.App.Status = "Disconnected"
    self.properties.App.UserID = ""
    self.properties.App.License = ""
    --Create timer to check connection repeatedly until VoiceMod opens back up
end
