-- ============================================================
--  SoundEngine.lua  |  Exvibe Music Player
--  Manages Roblox Sound instance and playback state
-- ============================================================

local E = _G.Exvibe

local SoundEngine = {}
SoundEngine.__index = SoundEngine

function SoundEngine.new()
    local self = setmetatable({}, SoundEngine)
    self.sound = Instance.new("Sound")
    self.sound.Parent               = workspace
    self.sound.Volume               = E.State.volume
    self.sound.RollOffMaxDistance   = 10000
    return self
end

-- Play a song entry from MusicDatabase
function SoundEngine:play(song)
    self.sound:Stop()
    self.sound.SoundId  = "rbxassetid://" .. tostring(song.assetId)
    self.sound:Play()
    E.State.isPlaying   = true
    E.State.isPaused    = false
    E.State.currentSong = song
end

function SoundEngine:pause()
    if E.State.isPlaying then
        self.sound:Pause()
        E.State.isPaused  = true
        E.State.isPlaying = false
    end
end

function SoundEngine:resume()
    if E.State.isPaused then
        self.sound:Resume()
        E.State.isPaused  = false
        E.State.isPlaying = true
    end
end

function SoundEngine:stop()
    self.sound:Stop()
    E.State.isPlaying = false
    E.State.isPaused  = false
end

function SoundEngine:setVolume(v)
    v = math.clamp(v, 0, 1)
    E.State.volume    = v
    self.sound.Volume = v
end

-- Returns 0-1 progress fraction
function SoundEngine:getProgress()
    if self.sound.TimeLength > 0 then
        return self.sound.TimePosition / self.sound.TimeLength
    end
    return 0
end

function SoundEngine:getPosition()
    return self.sound.TimePosition
end

function SoundEngine:getDuration()
    return self.sound.TimeLength
end

function SoundEngine:seekTo(fraction)
    if self.sound.TimeLength > 0 then
        self.sound.TimePosition = math.clamp(fraction, 0, 1) * self.sound.TimeLength
    end
end

-- Expose engine on global namespace
E.Engine = SoundEngine.new()

print("[Exvibe] SoundEngine loaded")
