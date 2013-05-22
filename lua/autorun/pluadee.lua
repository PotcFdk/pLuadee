--[[********************************
     pLuadee - a Lua music tracker  
	         by PotcFdk             
		 Work in Progress !         
********************************]]--



-- Send HUD to the client

if SERVER then
	AddCSLuaFile("pluadee/pluadee-hud.lua")
end

-- Send all songs to the client

for _,file in pairs(file.Find("pluadee_songs/*.pld.lua", "LUA")) do
	if SERVER then
		AddCSLuaFile("pluadee_songs/"..file)
	elseif not pLuadee then
		include("pluadee_songs/"..file)
	end
end

-- Send all samples to the clients

if SERVER then
	local files, folders = file.Find("sound/pluadee_samples/*", "GAME")
	for _,folder in pairs(folders) do
		local files = file.Find("sound/pluadee_samples/"..folder.."/*.wav", "GAME")
		for __,file in pairs(files) do
			resource.AddFile("sound/pluadee_samples/"..folder.."/" .. file)
		end
	end
end
	
local TAG = "pLuadee_net"

local rev_str = "$Revision: 5651 $"
local revision = tonumber(string.sub(rev_str,12,-3))


----------------------------------
-- Helpers
----------------------------------

local function isplayer(ply)
	return type(ply) == "Player"
end

 -- pack / unpack songs

local TableToString
local TableFromString
local _vts
local _kts

_vts = function(v)
  if isstring(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type(v) and TableToString(v) or tostring( v )
  end
end

_kts = function(k)
  if isstring(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[".._vts(k).."]"
  end
end

TableToString = function(tbl)
  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, _vts(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, _kts(k).."=".._vts(v))
    end
  end
  return "{"..table.concat(result, ",").."}"
end

TableFromString = function(str)
	local ch,erro=loadstring("pld_temptab_d="..str)
	if ch then
		pcall(ch)
	end
	local t=pld_temptab_d
	return istable(t) and t or {}
end

local function PackSong(sng)
	if not istable(sng) then return end
	local enc = TableToString(sng)
	enc = util.Compress(enc)
	return enc
end

local function ExtractSong(sng)
	if not isstring(sng) then return end
	local dec = util.Decompress(sng)
	dec = TableFromString(dec)
	return dec
end

----------------------------------
-- Serverside Controls
----------------------------------

if SERVER then
	util.AddNetworkString(TAG)
	
	local function log(...)
		Msg("[pLuadee] ")
		print(...)
	end
	
	pLuadee = {}
	
	function pLuadee:GetRevision()	
		return revision
	end
	
	function pLuadee:BroadcastSong(data)
		assert(istable(data), "Parameter 1 must be songdata!")
		log("Broadcasting song...")
		local package = PackSong(data)
		local length = #package
		net.Start(TAG)
			net.WriteString("data")
			net.WriteUInt(length, 32)
			net.WriteData(package, length)
		net.Broadcast()
	end
	
	function pLuadee:SendSong(ply, data)
		assert(isplayer(ply), "Parameter 1 must be player!")
		assert(istable(data), "Parameter 2 must be songdata!")
		log("Sending song to "..ply:Nick().."...")
		local package = PackSong(data)
		local length = #package
		net.Start(TAG)
			net.WriteString("data")
			net.WriteUInt(length, 32)
			net.WriteData(package, length)
		net.Send(ply)
	end
	
	function pLuadee:Load(ply, name)
		assert(ply, "Parameters expected!")
		if isstring(ply) then 
			log("Broadcasting 'load' event...")
			net.Start(TAG)
				net.WriteString("load")
				net.WriteString(ply)
			net.Broadcast()
		elseif isplayer(ply) and isstring(name) then 
			log("Sending 'load' event to "..ply:Nick().."...")
			net.Start(TAG)
				net.WriteString("load")
				net.WriteString(name)
			net.Send(ply)
		end
	end
	
	function pLuadee:PlayAt(ent)
		assert(IsValid(ent), "Parameter 1 must be an entity!")
		log("Broadcasting 'playat' event...")
		net.Start(TAG)
			net.WriteString("playat")
			net.WriteEntity(ent)
		net.Broadcast() 
	end
	
	function pLuadee:Play(ply)
		net.Start(TAG)
			net.WriteString("play")
		if isplayer(ply) then 
			log("Sending 'play' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'play' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Reset(ply)
		net.Start(TAG)
			net.WriteString("reset")
		if isplayer(ply) then 
			log("Sending 'reset' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'reset' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:PlaySong(song, ply, speaker)
		assert(isstring(song), "Parameter 1 must be the songname!")
		speaker = isentity(speaker) and speaker or NULL
		net.Start(TAG)
			net.WriteString("playsong")
			net.WriteString(song)
			net.WriteEntity(speaker)
		if isplayer(ply) then 
			log("Sending 'playsong' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'playsong' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Stop(ply)
		net.Start(TAG)
			net.WriteString("stop")
		if isplayer(ply) then 
			log("Sending 'stop' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'stop' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Resume(ply)
		net.Start(TAG)
			net.WriteString("resume")
		if isplayer(ply) then 
			log("Sending 'resume' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'resume' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Pause(ply)
		net.Start(TAG)
			net.WriteString("pause")
		if isplayer(ply) then 
			log("Sending 'pause' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'pause' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Mute(ply)
		net.Start(TAG)
			net.WriteString("mute")
		if isplayer(ply) then 
			log("Sending 'mute' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'mute' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:Unmute(ply)
		net.Start(TAG)
			net.WriteString("unmute")
		if isplayer(ply) then 
			log("Sending 'unmute' event to "..ply:Nick().."...")
			net.Send(ply) 
		else 
			log("Broadcasting 'unmute' event...")
			net.Broadcast() 
		end
	end
	
	function pLuadee:SetSpeaker(ent)
		assert(IsValid(ent), "Parameter 1 must be an entity!")
		log("Broadcasting 'setspeaker' event...")
		net.Start(TAG)
			net.WriteString("setspeaker")
			net.WriteEntity(ent)
		net.Broadcast() 
	end
	pLuadee.SetEntity = pLuadee.SetSpeaker
	
	function pLuadee:MuteChannels(...)
		assert(..., "Parameters expected: channel numbers")
		log("Broadcasting 'mutechannels' event...")
		net.Start(TAG)
			net.WriteString("mutechannels")
			net.WriteTable({...})
		net.Broadcast()
	end
	pLuadee.MuteChannel = pLuadee.MuteChannels
	
	function pLuadee:UnmuteChannels(...)
		assert(..., "Parameters expected: channel numbers")
		log("Broadcasting 'unmutechannels' event...")
		net.Start(TAG)
			net.WriteString("unmutechannels")
			net.WriteTable({...})
		net.Broadcast()
	end
	pLuadee.UnmuteChannel = pLuadee.UnmuteChannels
end


----------------------------------
-- Clientside System
----------------------------------


if CLIENT then
	local TAG_TICK = "pLuadee_Tick"
	
	-- Variables
	
	pLuadee = {}
	pLuadeeSongs = pLuadeeSongs or {}

	pLuadee.last = 0
	pLuadee.pos = 1
	pLuadee.tick = 0.1
	
	pLuadee.muted = false
	pLuadee.paused = false
	
	pLuadee.mutedchannels = {}
	
	pLuadee.ent = LocalPlayer()

	pLuadee.channels = {}
	
	function pLuadee:GetRevision()	
		return revision
	end
	
	-- Checks
	
	function pLuadee:SongIsValid(i_sng)
		local song = i_sng or self.song
		
		if not istable(song) then return false end
		if not song["meta"] or not song[1] then return false end
		if not song["meta"]["author"] or not song["meta"]["title"] then return false end
		if #song[1] == 1 then return false end
		return true
	end
	
	function pLuadee:IsPaused()
		return self.paused
	end
	
	function pLuadee:IsMuted()
		return self.muted
	end
	
	function pLuadee:CanPause()
		return not self.muted and not self.paused
	end
	
	function pLuadee:CanMute()
		return not self.muted and not self.paused
	end
	
	-- Announce Functions
	
	function pLuadee:AnnounceBegin()
		LocalPlayer():ChatPrint("[pLuadee] Playing song '"..self.song.meta.title.."' by "..self.song.meta.author..".")
	end
	function pLuadee:AnnounceEnd()
		LocalPlayer():ChatPrint("[pLuadee] Stopped song.")
	end
	function pLuadee:AnnounceResume()
		LocalPlayer():ChatPrint("[pLuadee] Resumed song '"..self.song.meta.title.."' by "..self.song.meta.author..".")
	end
	function pLuadee:AnnouncePause()
		LocalPlayer():ChatPrint("[pLuadee] Paused song.")
	end
	function pLuadee:AnnounceMute()
		LocalPlayer():ChatPrint("[pLuadee] Muted song.")
	end
	function pLuadee:AnnounceUnmute()
		LocalPlayer():ChatPrint("[pLuadee] Unmuted song.")
	end
	function pLuadee:AnnounceLoad()
		LocalPlayer():ChatPrint("[pLuadee] Loaded song '"..self.song.meta.title.."' by "..self.song.meta.author..".")
	end
	
	
	-- Note Conversion

	pLuadee.notes = {
	  [0] = { ["c"] = 16.35, ["c#"] = 17.32, ["d"] = 18.35, ["d#"] = 19.45, ["e"] = 20.60, ["f"] = 21.83, ["f#"] = 23.12, ["g"] = 24.50, ["g#"] = 25.96, ["a"] = 27.50, ["a#"] = 29.14, ["b"] = 30.87, },
	  [1] = { ["c"] = 32.70, ["c#"] = 34.65, ["d"] = 36.71, ["d#"] = 38.89, ["e"] = 41.20, ["f"] = 43.65, ["f#"] = 46.25, ["g"] = 49.00, ["g#"] = 51.91, ["a"] = 55.00, ["a#"] = 58.27, ["b"] = 61.74, },
	  [2] = { ["c"] = 65.41, ["c#"] = 69.30, ["d"] = 73.42, ["d#"] = 77.78, ["e"] = 82.41, ["f"] = 87.31, ["f#"] = 92.50, ["g"] = 98.00, ["g#"] = 103.8, ["a"] = 110.0, ["a#"] = 116.5, ["b"] = 123.5, },
	  [3] = { ["c"] = 130.8, ["c#"] = 138.6, ["d"] = 146.8, ["d#"] = 155.6, ["e"] = 164.8, ["f"] = 174.6, ["f#"] = 185.0, ["g"] = 196.0, ["g#"] = 207.7, ["a"] = 220.0, ["a#"] = 233.1, ["b"] = 246.9, },
	  [4] = { ["c"] = 261.6, ["c#"] = 277.2, ["d"] = 293.7, ["d#"] = 311.1, ["e"] = 329.6, ["f"] = 349.2, ["f#"] = 370.0, ["g"] = 392.0, ["g#"] = 415.3, ["a"] = 440.0, ["a#"] = 466.2, ["b"] = 493.9, },
	  [5] = { ["c"] = 523.3, ["c#"] = 554.4, ["d"] = 587.3, ["d#"] = 622.3, ["e"] = 659.3, ["f"] = 698.5, ["f#"] = 740.0, ["g"] = 784.0, ["g#"] = 830.6, ["a"] = 880.0, ["a#"] = 932.3, ["b"] = 987.8, },
	  [6] = { ["c"] = 1047, ["c#"] = 1109, ["d"] = 1175, ["d#"] = 1245, ["e"] = 1319, ["f"] = 1397, ["f#"] = 1480, ["g"] = 1568, ["g#"] = 1661, ["a"] = 1760, ["a#"] = 1865, ["b"] = 1976, },
	  [7] = { ["c"] = 2093, ["c#"] = 2217, ["d"] = 2349, ["d#"] = 2489, ["e"] = 2637, ["f"] = 2794, ["f#"] = 2960, ["g"] = 3136, ["g#"] = 3322, ["a"] = 3520, ["a#"] = 3729, ["b"] = 3951, },
	  [8] = { ["c"] = 4186, ["c#"] = 4435, ["d"] = 4699, ["d#"] = 4978, ["e"] = 5274, ["f"] = 5588, ["f#"] = 5920, ["g"] = 6272, ["g#"] = 6645, ["a"] = 7040, ["a#"] = 7459, ["b"] = 7902, },
	}
	
	pLuadee.modindex = {
		[1357] = "e2", [1141] = "g2", [480] = "a#3", [64] = "a6", [135] = "g#5", [151] = "f#5", [85] = "e6", [67] = "g#6", [180] = "d#5", [214] = "c5",
		[240] = "a#4", [90] = "d#6", [360] = "d#4", [1077] = "g#2", [1281] = "f2", [76] = "f#6", [95] = "d6", [808] = "c#3", [127] = "a5", [101] = "c#6",
		[190] = "d5", [508] = "a3", [120] = "a#5", [381] = "d4", [907] = "b2", [107] = "c6", [640] = "f3", [762] = "d3", [57] = "b6", [80] = "f6", [1017] = "a2",
		[1525] = "d2", [339] = "e4", [254] = "a4", [60] = "a#6", [302] = "f#4", [453] = "b3", [269] = "g#4", [320] = "f4", [285] = "g4", [428] = "c4", [538] = "g#3",
		[170] = "e5", [678] = "e3", [71] = "g6", [604] = "f#3", [404] = "c#4", [226] = "b4", [720] = "d#3", [856] = "c3", [961] = "a#2", [1209] = "f#2", [1440] = "d#2",
		[1712] = "c2", [1616] = "c#2", [160] = "f5", [143] = "g5", [570] = "g3", [202] = "c#5", [113] = "b5"
	}
	
	pLuadee.modperiods = {
		[1] = 57, [2] = 60, [3] = 64, [4] = 67, [5] = 71, [6] = 76, [7] = 80, [8] = 85, [9] = 90, [10] = 95, [11] = 101, [12] = 107, [13] = 113, [14] = 120,
		[15] = 127, [16] = 135, [17] = 143, [18] = 151, [19] = 160, [20] = 170, [21] = 180, [22] = 190, [23] = 202, [24] = 214, [25] = 226, [26] = 240,
		[27] = 254, [28] = 269, [29] = 285, [30] = 302, [31] = 320, [32] = 339, [33] = 360, [34] = 381, [35] = 404, [36] = 428, [37] = 453, [38] = 480,
		[39] = 508, [40] = 538, [41] = 570, [42] = 604, [43] = 640, [44] = 678, [45] = 720, [46] = 762, [47] = 808, [48] = 856, [49] = 907, [50] = 961,
		[51] = 1017, [52] = 1077, [53] = 1141, [54] = 1209, [55] = 1281, [56] = 1357, [57] = 1440, [58] = 1525, [59] = 1616, [60] = 1712
	}
	
	function pLuadee:FindModNote(input)
		if input == 0 then return end
		
		local array = self.modperiods
		local lopos = 1
		local hipos = #array
		
		while (hipos - lopos) > 1 do
			local midpos = math.floor (0.5 * (hipos + lopos))
			if array[midpos] > input then
				hipos = midpos
			else
				lopos = midpos
			end
		end
		
		local closest_match = math.abs(input - array[lopos]) < math.abs(input - array[hipos]) and array[lopos] or array[hipos]
		
		return self.modindex[closest_match]
	end

	pLuadee.instruments = {
		["bass"] = "/instruments/bass.wav",
		["snare"] = "/instruments/snare.wav",
		["saw"] = "/synth/saw_880.wav",
		["fbass"] = "/synth/triangle_880.wav",
		["white noise"] = "synth/white_noise.wav",
	}
	
	
	-- Sound System

	function pLuadee:PlayCh(channel, instrument, pitch) -- low level sound play
		if self.channels[channel] then self.channels[channel]:Stop() end
		if self.mutedchannels[channel] then return end
		if not instrument then return end
		if instrument == "-" then return end
		if pitch > 255 then return end
		if self.instruments[instrument] then instrument = self.instruments[instrument] end
		if not IsValid(self.ent) then return end
		self.channels[channel] = CreateSound(self.ent,instrument)
		self.channels[channel]:PlayEx(1,pitch)
	end

	function pLuadee:StopChan(channel)
		if self.channels[channel] then self.channels[channel]:Stop() end
	end

	function pLuadee:PlayIns(channel,instrument,note,scale) -- play note
		if not isstring(note) and not isnumber(note) then return end
		
		if isnumber(note) then
			note = self:FindModNote(note)
			if not note then return end
		end
		
		note = string.lower(note)
		local a = string.sub(note,2,2) == "#" and string.sub(note,1,2) or string.sub(note,1,1)
		local b = string.sub(note,2,2) == "#" and string.sub(note,3,3) or string.sub(note,2,2)
		b = tonumber(b)
		if self.notes[b] and self.notes[b][a] then
			self:PlayCh(channel,instrument,100*self.notes[b][a]/scale)
		end
	end

	function pLuadee:PlayTone(channel, data, meta) -- play note, high level, handles instrument mapping
		local instrument = data[1]
		local note = data[2]
		local instrument_inc = meta and meta["instruments"] or nil
		local scale = meta and meta["scale"] or 880
		
		if instrument_inc and instrument_inc[instrument] then
			instrument = instrument_inc[instrument]
		else
			instrument = pLuadee.instruments[instrument]
		end
		
		if instrument == 0 then
			self:StopChan(channel)
		elseif instrument then
			self:PlayIns(channel,instrument,note,scale)
			--print("playing instrument ",instrument)
		end
	end
	
	function pLuadee:Reset()
		self.last = 0
		self.muted = false
		self.paused = false
		table.Empty(self.mutedchannels)
		self:SetPos(1)
	end
	
	function pLuadee:GetLine(position)
		if not self:SongIsValid() then return false end
		local output = {}
		for i=1,4 do 
			if self.song[i][position] then
				local lndat = table.Copy(self.song[i][position])
				local mn = self:FindModNote(lndat[2])
				if mn then table.insert(lndat, mn) end
				table.insert(output, lndat)
			else
				table.insert(output, {0,0})
			end
		end
		return true, output
	end
	
	function pLuadee:IsPlaying()
		return isfunction(hook.GetTable().Think[TAG_TICK])
	end
	
	function pLuadee:SetPos(pos)
		self.begin = SysTime() - pos * self.tick
		self.pos = pos
	end
	
	function pLuadee:GetPos()
		return math.floor((SysTime() - self.begin) /self.tick)
	end
	
	-- Sound Tick

	function pLuadee:Tick()
		if not IsValid(self.ent) or #self.song == 0 then
			self:Stop()
			return
		end
		
		self.pos = self:GetPos()
		
		if self.pos ~= self.last then
			if not self.muted then
				for k,v in pairs(self.song) do
					if k ~= "meta" then
						if v[self.pos] and v[self.pos][1] == "sys" then
							if v[self.pos][2] == "exit" then
								self:Stop()
								return
							end
						else
							local data = v[self.pos] or {0,0}
							self:PlayTone(k,data,self.song["meta"])
						end
					end
				end
			end
			
			hook.Run("pLuadee-Tick", true, self.song.meta.author, self.song.meta.title, self.song.meta.tick, self.pos, #self.song[1])
			
			self.last = self.pos
			
			if self.pos > #self.song[1] then
				self:SetPos(1)
			end
		end
	end
	
	
	-- Clientside Controls

	function pLuadee:Play()
		if not self:SongIsValid() then return end
		self:AnnounceBegin()
		self:Reset()
		self.ent = LocalPlayer()
		hook.Add("Think",TAG_TICK,function() pLuadee:Tick() end)
	end
	
	function pLuadee:PlaySong(song, speaker)
		if self:IsPlaying() then self:Stop() end
		self:Load(song)
		timer.Simple(0.66,function()
			if IsValid(speaker) then
				self:PlayAt(speaker)
			else
				self:Play()
			end
		end)
	end
	
	function pLuadee:PlayAt(ent)
		if not IsValid(ent) then return end
		if not self:SongIsValid() then return end
		self:AnnounceBegin()
		self:Reset()
		self.ent = ent
		hook.Add("Think",TAG_TICK,function() pLuadee:Tick() end)
	end
	
	function pLuadee:Pause()
		if self:CanPause() then
			self:AnnouncePause()
			hook.Remove("Think",TAG_TICK)
			self.pos = self:GetPos()
			timer.Simple(0.66,function()
				for k,v in pairs(self.channels) do
					v:Stop()
				end
			end)
			self.paused = true
		end
	end
	
	function pLuadee:Resume()
		if self:IsPaused() then
			if not self:SongIsValid() then return end
			self:AnnounceResume()
			if not IsValid(self.ent) then self.ent = LocalPlayer() end
			self:SetPos(self.pos)
			hook.Add("Think",TAG_TICK,function() pLuadee:Tick() end)
			self.paused = false
		end
	end
	
	function pLuadee:Stop()
		self:AnnounceEnd()
		hook.Remove("Think",TAG_TICK)
		hook.Run("pLuadee-Tick", false)
		self:SetPos(1)
		timer.Simple(0.66,function()
			for k,v in pairs(self.channels) do
				v:Stop()
			end
		end)
	end
	
	function pLuadee:Mute()
		if self:CanMute() then
			self:AnnounceMute()
			timer.Simple(0.66,function()
				for k,v in pairs(self.channels) do
					v:Stop()
				end
			end)
			self.muted = true
		end
	end
	
	function pLuadee:Unmute()
		if self:IsMuted() then
			if not self:SongIsValid() then return end
			self:AnnounceUnmute()
			if not IsValid(self.ent) then self.ent = LocalPlayer() end
			self.muted = false
		end
	end
	
	function pLuadee:SetSpeaker(ent)
		if not IsValid(ent) then return end
		self.ent = ent
	end
	pLuadee.SetEntity = pLuadee.SetSpeaker
	
	function pLuadee:MuteChannels(data, ...)
		local tab = not data and {1, 2, 3, 4} or ( istable(data) and data or { data, ... } )
		for _, channel in next, tab do
			if tonumber(channel) then
				self.mutedchannels[tonumber(channel)] = true
			end
		end
	end
	
	function pLuadee:UnmuteChannels(data, ...)
		local tab = not data and {1, 2, 3, 4} or ( istable(data) and data or { data, ... } )
		for _, channel in next, tab do
			if tonumber(channel) then
				self.mutedchannels[tonumber(channel)] = nil
			end
		end
	end
	
	function pLuadee:Load(song)
		if not song then return end
		if pLuadeeSongs[song] then
			self:Load(pLuadeeSongs[song])
		else
			self.song = song
			if self:SongIsValid() then 
				self:AnnounceLoad() 
				self.tick = self.song.meta.tick or 0.12
				self:Reset()
			end
		end
	end
	
	
	-- NET Controls

	function pLuadee:Receive()
		local id = net.ReadString()
		if not id then return end
		
		if id == "play" then
			self:Play()
		elseif id == "stop" then
			self:Stop()
		elseif id == "reset" then
			self:Reset()
		elseif id == "playsong" then
			self:PlaySong(net.ReadString(), net.ReadEntity())
		elseif id == "resume" then
			self:Resume()
		elseif id == "pause" then
			self:Pause()
		elseif id == "mute" then
			self:Mute()
		elseif id == "unmute" then
			self:Unmute()
		elseif id == "mutechannels" then
			self:MuteChannels(net.ReadTable())
		elseif id == "unmutechannels" then
			self:UnmuteChannels(net.ReadTable())
		elseif id == "setspeaker" then
			self:SetSpeaker(net.ReadEntity())
		elseif id == "playat" then
			self:PlayAt(net.ReadEntity())
		elseif id == "load" then
			self:Load(net.ReadString())
		elseif id == "data" then
			local length = net.ReadUInt(32)
			local data = net.ReadData(length)
			data = ExtractSong(data)
			self:Load(data)
		end
	end

	net.Receive(TAG, function() pLuadee:Receive() end)
	
	-- Load HUD
	
	include("pluadee/pluadee-hud.lua")
end