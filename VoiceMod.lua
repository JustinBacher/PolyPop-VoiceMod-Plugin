local random = math.random

--[[
    UUID function:
    https://gist.github.com/jrus/3197011
]]
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

--[[
    Make a string proper case
    https://stackoverflow.com/a/20285006
]]
function string.proper(str)
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end

--[[
    Insert into a string at pos
    https://stackoverflow.com/a/59561933
]]
function string.insert(str1, str2, pos)
    return str1:sub(1,pos)..str2..str1:sub(pos+1)
end


local voicemodPorts = {59129, 20000, 39273, 42152, 43782, 46667, 35679, 37170, 38501, 33952, 30546}
local envFile = io.open(getLocalFolder() .. ".env", "r")
local apiKey
if envFile then
    apiKey = json.decode(envFile:read("a")).apiKey
    envFile:close()
end

Instance.properties = properties({
    {name="App", type="PropertyGroup", items={
        {name="Status", type="Text", value="Disconnected", ui={readonly=true}},
        {name="UserID", type="Text", ui={readonly=true}},
        {name="License", type="Text", ui={readonly=true}},
    }, ui={expand=true}},
    {name="VoiceChanger", type="PropertyGroup", items={
        {name="Enabled", type="Bool", onUpdate="onVoiceChangerUpdate"},
        {name="Voice", type="Enum", onUpdate="onVoiceUpdate"},
        {name="VoiceProperties", type="ObjectSet", ui={readonly=true}},
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
    self.identity = uuid()
    self.host = getNetwork():getHost("localhost")
    self:attemptConnection()
    self:clearVoiceProperties()
    self.properties.VoiceChanger.Beep = false
    self.properties.App.Status = "Disconnected"
    self.properties.App.UserID = ""
    self.properties.App.License = ""
end

function Instance:clearVoiceProperties()
    local kit = self.properties.VoiceChanger.VoiceProperties:getKit()
    for i = 1, kit:getObjectCount() do
        getEditor():removeFromLibrary(kit:getObjectByIndex(i))
    end
end


--[[--------------------------------------------------------------
    Functions to update VoiceMod
]]----------------------------------------------------------------

function Instance:onParamUpdate(prop, value)
    self:send({
        action="setCurrentVoiceParameter",
        payload={
            parameterName=prop:getName(),
            parameterValue=value,
        }
    })
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

 function Instance:clientRegistered()
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

    self.properties.VoiceChanger:find("Voice"):setElements(voices)
    self.properties.VoiceChanger:find("Voice").value = obj.currentVoice
end

responseActions.getMemes = function(self, obj)
    self.memes = obj.listOfMemes
    local memes = {}

    for _, meme in ipairs(self.memes) do
        table.insert(memes, meme.friendlyName)
    end

    self.properties.Memes:find("MemeSound"):setElements(memes)
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
    local kit = self.properties.VoiceChanger.VoiceProperties:getKit()

    for name, param in pairs(obj.parameters) do
        if string.sub(name, 1, 1) == "_" then
            goto continue
        end
        
        local paramKit
        
        if type(param.value) == "boolean" then
            paramKit = getEditor():createUIX(kit, "BoolParam")
        elseif type(param.value) == "string" then
            paramKit = getEditor():createUIX(kit, "TextParam")
        elseif type(param.value) == "number" then
            if (param.value % 1 == 0) or (param.maxValue % 1 == 0) or (param.minValue % 1 == 0) then
                paramKit = getEditor():createUIX(kit, "IntParam")
            else
                paramKit = getEditor():createUIX(kit, "RealParam")
            end
        end

        paramKit:initParam(name, param)
        ::continue::
    end
end

responseActions.getUserLicense = function(self, obj)
    self.properties.App.License = string.proper(obj.licenseType)
end

responseActions.licenseTypeChanged = responseActions.getUserLicense

responseActions.getUser = function(self, obj)
    self.properties.App.UserID = obj.userID
end


--[[--------------------------------------------------------------
    Websocket Functions
]]----------------------------------------------------------------

function Instance:send(cmd)
    if self.webSocket and self.webSocket:isConnected() then
        cmd.id = self.identity

        local payload = json.encode(cmd)
        if cmd.payload == nil then
            payload = string.insert(payload, ',"payload":{}', #payload - 1)
        end
        print(payload)
        self.webSocket:send(payload)
    elseif cmd.action ~= "registerClient" then
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

function Instance:_onWsConnected(ws)
    print("connected")
    self.webSocket = ws
    self:send({
        action="registerClient",
        id=self.identity,
        payload={
            clientKey=apiKey,
        },
    })
end

function Instance:_onWsMessage(port)
	return function(self, msg)
        local payload = json.decode(msg)

        --print(msg)

        if payload.action == "registerClient" then
            self:clientRegistered()
            return
        end

        if payload.socketId then
            self.identity = payload.socketId
        end

        local action = responseActions[payload.actionType]

        if action == nil then
            print("No action: " .. msg)
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
