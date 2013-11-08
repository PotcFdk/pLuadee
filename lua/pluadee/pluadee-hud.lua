--[[===========================================================================
    This file is part of pLuadee by PotcFdk.

    pLuadee is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    pLuadee is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with pLuadee.  If not, see <http://www.gnu.org/licenses/>.
===========================================================================]]--

if not pLuadee then return end

pLuadeeHud = pLuadeeHud or {}

-- Helpers 

 -- convert number to hex

local function tohex(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT ~= "" and OUT or "0"
end


-- Tracker HUD

pLuadeeHud.onoff = false
pLuadeeHud.artist = nil
pLuadeeHud.songname = nil
pLuadeeHud.tickrate = 0
pLuadeeHud.position = 0
pLuadeeHud.length = 0
pLuadeeHud.distance = 0


local width = 270
local height = 123

local SCR_W = ScrW()
local SCR_H = ScrH()

local white = Color(255, 255, 255, 255)
local red = Color(255, 0, 0, 255)

local lgray = Color(190, 190, 190, 255)
local black_t = Color(0, 0, 0, 230)

local function make2ln(txt)
	local len = string.len(txt)
	if len >= 2 then return txt end
	if len == 1 then return "0"..txt end
end

local lin = {}
lin.pos = {}
lin.pos[1] = SCR_W/2 -- x pos
lin.font = "DefaultFixed" -- Font
lin.xalign = TEXT_ALIGN_RIGHT -- Horizontal Alignment
lin.yalign = TEXT_ALIGN_CENTER -- Vertical Alignment

hook.Add("HUDPaint", "pLuadee-HUD", function()
	if not pLuadeeHud.onoff then return end
		
	surface.SetAlphaMultiplier(math.Clamp((2000 - pLuadeeHud.distance + 500) / 2000, 0, 1))
		
	lin.xalign = TEXT_ALIGN_RIGHT -- Horizontal Alignment
	
	draw.RoundedBox(6, SCR_W/2 - width/2, -10, width, height, black_t)
	
	for line = -3, 3 do
		local success, result = pLuadee:GetLine(pLuadeeHud.position + line)
		if success then
			lin.pos[2] = 55 + line*10
			lin.color = white
				
			lin.pos[1] = SCR_W/2 - 83
			lin.text = "0x"..make2ln(tohex(math.mod(pLuadeeHud.position+line, 64)))
			draw.Text(lin)
			
			local row = 0
				
			for _, channel in next, result do
				lin.pos[1] = SCR_W/2 - 30 + row*48
				lin.text = ""
				if channel[2] ~= 0 then
					if channel[3] then
						if string.len(channel[3]) == 2 then
							channel[3] = string.sub(channel[3],1,1) .. "-" .. string.sub(channel[3],2,2)
						end
						lin.text = lin.text .. channel[1] .. " " .. string.upper(channel[3])
					else
						lin.text = lin.text .. channel[1] .. " " .. channel[2]
					end
				end
				draw.Text(lin)
				row = row + 1
			end
		end
	end
		
	surface.SetDrawColor(lgray)
		
	surface.DrawLine(SCR_W/2 - 120, 15, SCR_W/2 + 120, 15)
		
	surface.DrawLine(SCR_W/2 - 120, 15, SCR_W/2 - 120, 95)
	surface.DrawLine(SCR_W/2 - 75, 15, SCR_W/2 - 75, 95)
	surface.DrawLine(SCR_W/2 - 25, 15, SCR_W/2 - 25, 95)
	surface.DrawLine(SCR_W/2 + 25, 15, SCR_W/2 + 25, 95)
	surface.DrawLine(SCR_W/2 + 75, 15, SCR_W/2 + 75, 95)
	surface.DrawLine(SCR_W/2 + 120, 15, SCR_W/2 + 120, 95)
		
	surface.DrawLine(SCR_W/2 - 120, 95, SCR_W/2 + 120, 95)
		
	surface.SetDrawColor(red)
	surface.DrawOutlinedRect( SCR_W/2 - 120 , 49, 241, 11 )
		
	lin.pos[2] = 7
	lin.text = pLuadeeHud.artist.." - "..pLuadeeHud.songname
	lin.pos[1] = SCR_W/2
	lin.xalign = TEXT_ALIGN_CENTER
	draw.Text(lin)
		
	local progress = pLuadeeHud.position / pLuadeeHud.length
	lin.pos[2] = 105
	lin.text = pLuadeeHud.position .. " / " .. pLuadeeHud.length .. " (" .. math.floor(progress*100) .. "%)"
	lin.pos[1] = SCR_W/2 + 123
	lin.xalign = TEXT_ALIGN_RIGHT
	draw.Text(lin)
	
	surface.SetDrawColor(Color(0,255,0))
	surface.DrawRect(SCR_W/2-120, 102, 130*progress, 5)
	
	surface.SetDrawColor(Color(255,255,255))
	surface.DrawLine(SCR_W/2-120, 101, SCR_W/2-120, 107)
	surface.DrawLine(SCR_W/2+10, 101, SCR_W/2+10, 107)
end)


hook.Add("pLuadee-Tick", "pLuadee-HUD", function(onoff, artist, songname, tickrate, position, length, distance)
	pLuadeeHud.onoff = onoff
	pLuadeeHud.artist = artist
	pLuadeeHud.songname = songname
	pLuadeeHud.tickrate = tickrate
	pLuadeeHud.position = position
	pLuadeeHud.length = length
	pLuadeeHud.distance = distance
end)