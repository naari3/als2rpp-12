-- @description Import rudimentary arrangement from un-gzipped Ableton Live 10 .als 
-- @about Primarily for MIDI AND ENVELOPES; rename .als to .gz, unpack, open the unpacked file
-- @about This script is provided as open source and free of charge, without any guarantees of functionality


-------------------------------------------------------------------------
-- INITIAL CONFIGURATION
-------------------------------------------------------------------------

local writeLogFile = true
local LogFileContent = ''

ticksPerQuarterNote = 960  --INTENTIONALLY GLOBAL; DON'T CHANGE UNLESS YOU KNOW WHAT YOU'RE DOING


-- Setup package path locations to find rtk via ReaPack
local entrypath = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = string.format('%s?.lua;', entrypath)
local rtk = require('rtk')

--------------------------------------------------------------
-- INITIAL INFORMATION FOR THE USER
--------------------------------------------------------------


local initialInformation = 'Import ARRANGEMENT DATA from un-gzipped Ableton Live 10.0.5 .als'
..'\nREQUIRES REAPER v6.71 or newer!'
..'\nNote: may take long time, REAPER may become unresponsive'
..'\n'
..'\nThe following will NOT be imported, apply workarounds in Live before import:'
..'\n'
..'\n- Group tracks'
..'\n      workaround: flatten track structure before importing'
..'\n- Device Racks/Groups and plugins inside them'
..'\n      > flatten tracks\' FX/plugin structure before importing'
..'\n- most of Live native plugins and devices, including Racks'
..'\n      > render them to new Audio tracks as project-length before importing'
..'\n- Audio Clips\' time stretching/tempo settings and Clip Envelopes'
..'\n      > render them to new Audio tracks as project-length before importing'
..'\n      NOTE: audio file paths must not contain non-ASCII characters!'
..'\n- In-Clip Offset settings (loop begins after beginning of clip, etc.)'
..'\n      > will be listed in console after import if such clips were found'
..'\n      > consolidate them or render them to audio before re-attempting import'
..'\n- Clip Modulations which are not CCs,'
..'\n- Clip Modulation loop settings (even if they are for CCs),'
..'\n- Grooves and their effect on MIDI and other data'
..'\n      > will be listed in Console, commit grooves before re-attempting import'
..'\n'
..'\n- Track Delay (time compensation) settings'
..'\n- Mute envelopes (possible, but not currently implemented)'
..'\n- any kind of Clips in Session view,'
..'\n- "CurveControl" attributes of Envelope points'
..'\n'
..'\nThese Live plugins will be converted to REAPER or VST equivalent, with varying degrees of success:'
..'\n Live EQ8  >  ReaEQ' 
..'\n Live AutoFilter  >  ReaEQ, but ENV, LFO and many other parameters discarded'
..'\n Live Reverb  >  Dragonfly Hall Reverb VST'
..'\n Live Simple Delay  >  Spaceship Delay VST'
..'\n Live Ping Pong Delay  >  Spaceship Delay VST'
..'\n Live Gate  >  ReaGate'
..'\n Live Compressor  >  ReaComp'
..'\n Live Simpler  >  RS5k, but NO SETTINGS NOR SAMPLES LOADED '
..'\n Live Sampler  >  RS5k, but NO SETTINGS NOR SAMPLES LOADED '

local askToContinue = reaper.ShowMessageBox(initialInformation, "CONTINUE?", 1)

local continue=true

if askToContinue==2
then

  continue=false
  
end


-----------------------------------------------
-- Live 10 colors to RGB translation
-----------------------------------------------

local Live10_ClipColorIndexTable = {}

Live10_ClipColorIndexTable[0] = {254,148,166}
Live10_ClipColorIndexTable[1] = {255,165,41}
Live10_ClipColorIndexTable[2] = {204,153,39}
Live10_ClipColorIndexTable[3] = {246,243,122}
Live10_ClipColorIndexTable[4] = {191,251,0}
Live10_ClipColorIndexTable[5] = {26,255,47}
Live10_ClipColorIndexTable[6] = {37,255,168}
Live10_ClipColorIndexTable[7] = {92,253,232}
Live10_ClipColorIndexTable[8] = {140,197,252}
Live10_ClipColorIndexTable[9] = {84,128,228}
Live10_ClipColorIndexTable[10] = {146,167,254}
Live10_ClipColorIndexTable[11] = {216,108,228}
Live10_ClipColorIndexTable[12] = {229,83,160}
Live10_ClipColorIndexTable[13] = {252,252,252}

Live10_ClipColorIndexTable[14] = {255,54,54}
Live10_ClipColorIndexTable[15] = {246,108,3}
Live10_ClipColorIndexTable[16] = {151,112,76}
Live10_ClipColorIndexTable[17] = {255,240,52}
Live10_ClipColorIndexTable[18] = {135,254,104}
Live10_ClipColorIndexTable[19] = {61,195,0}
Live10_ClipColorIndexTable[20] = {0,191,175}
Live10_ClipColorIndexTable[21] = {25,233,255}
Live10_ClipColorIndexTable[22] = {16,164,238}
Live10_ClipColorIndexTable[23] = {0,125,192}
Live10_ClipColorIndexTable[24] = {136,108,228}
Live10_ClipColorIndexTable[25] = {182,119,198}
Live10_ClipColorIndexTable[26] = {255,57,212}
Live10_ClipColorIndexTable[27] = {195,195,195}

Live10_ClipColorIndexTable[28] = {226,103,90}
Live10_ClipColorIndexTable[29] = {254,163,115}
Live10_ClipColorIndexTable[30] = {207,172,113}
Live10_ClipColorIndexTable[31] = {236,253,173}
Live10_ClipColorIndexTable[32] = {209,228,151}
Live10_ClipColorIndexTable[33] = {185,206,117}
Live10_ClipColorIndexTable[34] = {154,197,142}
Live10_ClipColorIndexTable[35] = {208,246,236}
Live10_ClipColorIndexTable[36] = {208,246,236}
Live10_ClipColorIndexTable[37] = {183,193,227}
Live10_ClipColorIndexTable[38] = {204,187,227}
Live10_ClipColorIndexTable[39] = {174,152,229}
Live10_ClipColorIndexTable[40] = {229,220,225}
Live10_ClipColorIndexTable[41] = {167,167,167}

Live10_ClipColorIndexTable[42] = {199,146,140}
Live10_ClipColorIndexTable[43] = {182,130,86}
Live10_ClipColorIndexTable[44] = {152,131,106}
Live10_ClipColorIndexTable[45] = {190,185,106}
Live10_ClipColorIndexTable[46] = {166,190,0}
Live10_ClipColorIndexTable[47] = {122,174,76}
Live10_ClipColorIndexTable[48] = {136,193,185}
Live10_ClipColorIndexTable[49] = {144,172,196}
Live10_ClipColorIndexTable[50] = {144,172,196}
Live10_ClipColorIndexTable[51] = {131,147,205}
Live10_ClipColorIndexTable[52] = {178,154,185}
Live10_ClipColorIndexTable[53] = {178,154,185}
Live10_ClipColorIndexTable[54] = {118,113,150}
Live10_ClipColorIndexTable[55] = {115,115,115}

Live10_ClipColorIndexTable[56] = {175,51,51}
Live10_ClipColorIndexTable[57] = {169,81,49}
Live10_ClipColorIndexTable[58] = {114,79,65}
Live10_ClipColorIndexTable[59] = {219,195,0}
Live10_ClipColorIndexTable[60] = {133,150,31}
Live10_ClipColorIndexTable[61] = {83,159,49}
Live10_ClipColorIndexTable[62] = {10,156,142}
Live10_ClipColorIndexTable[63] = {35,99,132}
Live10_ClipColorIndexTable[64] = {26,47,150}
Live10_ClipColorIndexTable[65] = {47,82,162}
Live10_ClipColorIndexTable[66] = {98,75,173}
Live10_ClipColorIndexTable[67] = {163,75,173}
Live10_ClipColorIndexTable[68] = {204,46,110}
Live10_ClipColorIndexTable[69] = {56,56,56}

local Live10_ColorIndexTable = {}

Live10_ColorIndexTable[140] = {254,148,166}
Live10_ColorIndexTable[141] = {255,165,41}
Live10_ColorIndexTable[142] = {204,153,39}
Live10_ColorIndexTable[143] = {246,243,122}
Live10_ColorIndexTable[144] = {191,251,0}
Live10_ColorIndexTable[145] = {26,255,47}
Live10_ColorIndexTable[146] = {37,255,168}
Live10_ColorIndexTable[147] = {92,253,232}
Live10_ColorIndexTable[148] = {140,197,252}
Live10_ColorIndexTable[149] = {84,128,228}
Live10_ColorIndexTable[150] = {146,167,254}
Live10_ColorIndexTable[151] = {216,108,228}
Live10_ColorIndexTable[152] = {229,83,160}
Live10_ColorIndexTable[153] = {252,252,252}

Live10_ColorIndexTable[154] = {255,54,54}
Live10_ColorIndexTable[155] = {246,108,3}
Live10_ColorIndexTable[156] = {151,112,76}
Live10_ColorIndexTable[157] = {255,240,52}
Live10_ColorIndexTable[158] = {135,254,104}
Live10_ColorIndexTable[159] = {61,195,0}
Live10_ColorIndexTable[160] = {0,191,175}
Live10_ColorIndexTable[161] = {25,233,255}
Live10_ColorIndexTable[162] = {16,164,238}
Live10_ColorIndexTable[163] = {0,125,192}
Live10_ColorIndexTable[164] = {136,108,228}
Live10_ColorIndexTable[165] = {182,119,198}
Live10_ColorIndexTable[166] = {255,57,212}
Live10_ColorIndexTable[167] = {195,195,195}

Live10_ColorIndexTable[168] = {226,103,90}
Live10_ColorIndexTable[169] = {254,163,115}
Live10_ColorIndexTable[170] = {207,172,113}
Live10_ColorIndexTable[171] = {236,253,173}
Live10_ColorIndexTable[172] = {209,228,151}
Live10_ColorIndexTable[173] = {185,206,117}
Live10_ColorIndexTable[174] = {154,197,142}
Live10_ColorIndexTable[175] = {208,246,236}
Live10_ColorIndexTable[176] = {208,246,236}
Live10_ColorIndexTable[177] = {183,193,227}
Live10_ColorIndexTable[178] = {204,187,227}
Live10_ColorIndexTable[179] = {174,152,229}
Live10_ColorIndexTable[180] = {229,220,225}
Live10_ColorIndexTable[181] = {167,167,167}

Live10_ColorIndexTable[182] = {199,146,140}
Live10_ColorIndexTable[183] = {182,130,86}
Live10_ColorIndexTable[184] = {152,131,106}
Live10_ColorIndexTable[185] = {190,185,106}
Live10_ColorIndexTable[186] = {166,190,0}
Live10_ColorIndexTable[187] = {122,174,76}
Live10_ColorIndexTable[188] = {136,193,185}
Live10_ColorIndexTable[189] = {144,172,196}
Live10_ColorIndexTable[190] = {144,172,196}
Live10_ColorIndexTable[191] = {131,147,205}
Live10_ColorIndexTable[192] = {178,154,185}
Live10_ColorIndexTable[193] = {178,154,185}
Live10_ColorIndexTable[194] = {118,113,150}
Live10_ColorIndexTable[195] = {115,115,115}

Live10_ColorIndexTable[196] = {175,51,51}
Live10_ColorIndexTable[197] = {169,81,49}
Live10_ColorIndexTable[198] = {114,79,65}
Live10_ColorIndexTable[199] = {219,195,0}
Live10_ColorIndexTable[200] = {133,150,31}
Live10_ColorIndexTable[201] = {83,159,49}
Live10_ColorIndexTable[202] = {10,156,142}
Live10_ColorIndexTable[203] = {35,99,132}
Live10_ColorIndexTable[204] = {26,47,150}
Live10_ColorIndexTable[205] = {47,82,162}
Live10_ColorIndexTable[206] = {98,75,173}
Live10_ColorIndexTable[207] = {163,75,173}
Live10_ColorIndexTable[208] = {204,46,110}
Live10_ColorIndexTable[209] = {56,56,56}


-------------------------

local startTimeInSeconds = 0

WARNINGS_TABLE = {} 

TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS = {}

TRACK_ID_TABLE = {} 
--[[ 
TRACK_ID_TABLE 
LEVEL 1						VALUE
[#] track index in REAPER 	Live's Track Id 
--]]

TRACK_ROUTINGS_TABLE = {}  
--[[ 
TRACK_ROUTINGS_TABLE 
LEVEL 1						LEVEL 2					VALUE
[#] track index in REAPER 	[1]AudioIn Target		string
							[2]MidiIn Target		string
							[3]AudioOut Target		string
							[4]MidiOut Target 		string
--]]

TRACK_RETURNS_ID_TABLE = {} 
--[[ 
TRACK_RETURNS_ID_TABLE 
LEVEL 1						LEVEL 2					
[#] TABLE INDEX 1-## 		[1] REAPER track index 	number
							[2] Live Track Id		string	

--]]

TRACK_SENDS_TO_RETURNS_TABLE = {} 

REACOMPS_SIDECHAINS_SETTINGS_TABLE = {}
--[[ 
[#] TABLE INDEX 1-## 		[0] = currentTrackIndex				-- RECEIVE TRACK
							[1] = currentFXindex
							[2] = SourceTrack_LiveTrackId	-- SOURCE TRACK
							[3] = SourceTrack_SendMode	

--]]


GROOVE_ID_TABLE = {}
--[[ 
	[#] TABLE INDEX 1-##	[0] = GrooveId
							[1] = GrooveName
--]]


CLIPS_WITH_GROOVES_TABLE = {}
--[[ 	

	[#] TABLE INDEX 1-## 	[0] = currentTrackIndex
							[1] = thisTrackName
							[2] = ((LiveMidiClip_CurrentStart/4)+1) -- at bar
							[3] = LiveMidiClip_CurrentStart -- at 1/4th
							[4] = currentClipsGrooveId
							[5] = clip name					
--]]



function checkIfTrackIs_SIDECHAIN_CLICK(given_track)			
	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_track,'')
			
	if string.match(currentREAPERtrack_name,'sc click')
	or string.match(currentREAPERtrack_name,'SC CLICK')
	or string.match(currentREAPERtrack_name,'sidechain click')
	or string.match(currentREAPERtrack_name,'SIDECHAIN CLICK')
	or string.match(currentREAPERtrack_name,'4/4 click')
	or string.match(currentREAPERtrack_name,'4-4 click')
	or string.match(currentREAPERtrack_name,'4 note click')
	then
		return true
	end
end--function checkIfTrackIs_SIDECHAIN_CLICK




function printTrackRoutingToConsole(given_RPRtrackIndex)

	local routingMessage ='\n    '
	..' Audio In Target:'
	..TRACK_ROUTINGS_TABLE[given_RPRtrackIndex][1]	
	..', MidiIn Target:'
	..TRACK_ROUTINGS_TABLE[given_RPRtrackIndex][2]
	..', AudioOut Target:'
	..TRACK_ROUTINGS_TABLE[given_RPRtrackIndex][3]
	..', MidiOut Target:'
	..TRACK_ROUTINGS_TABLE[given_RPRtrackIndex][4]
	
	
	reaper.ShowConsoleMsg(routingMessage)
	LogFileContent = LogFileContent..routingMessage

end--function printTrackRoutingToConsole









--*********************************************************
-- INITIALIZE GLOBAL MEDIA ITEM COUNT
--*********************************************************

currentProjectMediaItemCount = 0 -- MUST BE HERE BEFORE FUNCTION FOR INSERTING MEDIA ITEMS








--*********************************************************
-- CHOOSE FILE, GET FILE CONTENTS
--*********************************************************

function getFileForReading()

	retval, openFile = reaper.GetUserFileNameForRead("", "Select file to open","")

	reaper.ShowConsoleMsg("\n\nSELECTED FILE: "..openFile.."\n")

	local lastInstanceOfDot = openFile:match'^.*().'-9

	pathToFile = string.sub(openFile, 0, lastInstanceOfDot) --INTENTIONALLY GLOBAL

	--reaper.ShowConsoleMsg("\n\nPATH TO FILE: "..pathToFile.."\n")

	function lines_from(file)
		
		lines = {}
		
		for line in io.lines(file) 
		do
			lines[#lines + 1] = line
		end
		
		return lines
	end


	local tableOfLinesFromFile = lines_from(openFile)


	--[[
	-- print table
	for s=1,#tableOfLinesFromFile
	do
		reaper.ShowConsoleMsg("\n table index "..s..":"..tableOfLinesFromFile[s])	
	end --for s
	
	
	local fileContents = ''


	-- print table
	for t=1,#tableOfLinesFromFile
	do
		fileContents = fileContents..tableOfLinesFromFile[t]	
	end --for t

	--reaper.ShowConsoleMsg("\n\nfileContents:\n"..fileContents)
	--return fileContents
	--]]	
	
	return tableOfLinesFromFile

end--function getFileForReading()






--*********************************************************
-- ShowConsoleMsg_and_AddtoLog
--*********************************************************
function ShowConsoleMsg_and_AddtoLog(message)

	reaper.ShowConsoleMsg(message)
	LogFileContent = LogFileContent..message

end








--*********************************************************
-- dBtoAmplitude (convert decibels to amplitude)
--*********************************************************
function dBtoAmplitude(given_dB)
	local amplitude =  10^(given_dB/20)
	return amplitude
end--function


--*********************************************************
-- amplitudeToDB (convert amplitude to dB)
--*********************************************************
function amplitudeTodB(given_amplitude)
	local dB =  20 * math.log(given_amplitude,10)
	return dB
end--function







--*********************************************************
-- PPDelay_MidFreq_to_SpcshpDly_LC_HC
--*********************************************************
function PPDelay_MidFreq_to_SpcshpDly_LC_HC(given_MidFreq,given_BandWidth)

-- note: inaccurate but close enough!
-- NOTE:  Hz to Spaceship Delay Normalized conversion: NormalizedValue = (math.log(valueFromTable+valueFromTable)*0.14447)-0.531

	-- MidFreq: 50 to 18000 in Hz

	LowCutValue = given_MidFreq - ((given_MidFreq/10) * given_BandWidth) - 280
	LowCutValue = math.floor(LowCutValue+0.5)
	
	if LowCutValue < 20 then LowCutValue = 20 end

	HighCutValue = given_MidFreq + ((given_MidFreq*2)*given_BandWidth)
	HighCutValue = math.floor(HighCutValue+0.5)
	
	if HighCutValue > 20000 then HighCutValue = 20000 end
	
	--reaper.ShowConsoleMsg('\n    '..LowCutValue..'    '..given_MidFreq..'    '..HighCutValue)

	-- NORMALIZATION
	LowCutValue = (math.log(LowCutValue+LowCutValue)*0.14447)-0.531
	HighCutValue = (math.log(HighCutValue+HighCutValue)*0.14447)-0.531

	return LowCutValue,HighCutValue
end--function PPDelay_MidFreq_to_SpcshpDly_LC_HC











--*********************************************************
--  checkIfAutomationTableHasEventsForId
--*********************************************************
function checkIfAutomationXMLTable_HasEventsForTargetId(
											given_AutomationTargetId,
											given_AutomationEnvelopesXMLTable
											)

	local hasEnvelopeEvents = false

	for i=1,#given_AutomationEnvelopesXMLTable,1
	do
		if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
		then
			local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AutomationEnvelopesXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AutomationEnvelope>'				-- given_EndTag
																		)	
			local currentEnvelope_PointeeId
			
			for j=1,#AutomationEnvelope_XMLTable,1
			do
				if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
				then
					currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
					break -- enclosing for loop
				end--if
			end--for j=1,#AutomationEnvelope_XMLTable,1
				
			if currentEnvelope_PointeeId == given_AutomationTargetId
			then 
				for k=1,#AutomationEnvelope_XMLTable,1
				do
					if string.match(AutomationEnvelope_XMLTable[k],'<EnumEvent Id="') then hasEnvelopeEvents = true break end
					if string.match(AutomationEnvelope_XMLTable[k],'<BoolEvent Id="') then hasEnvelopeEvents = true break end
					if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="') then hasEnvelopeEvents = true break end

				end--for k=1,#AutomationEnvelope_XMLTable,1
			end--if
			
		end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')

	end--for

	return hasEnvelopeEvents

end--checkIfAutomationXMLTable_HasEventsForTargetId











--************************************************************************************************************************************

-- convertHzTo_ReaEQNormalizedFreq FOR ReaEQ 					

-- REASON FOR THIS HACKY WORKAROUND: writer could not figure out a simple formula to convert Hz values to ReaEQ Freq envelope values

--************************************************************************************************************************************
function convertHzTo_ReaEQNormalizedFreq(	given_Track,
											given_ReaEQFXindex,
											given_FreqParamNumber,
											given_Hz
											)

	local properNormalized = 0
	local Intended_Hz_value = tonumber(given_Hz)
	
	-- IMPORTANT! ROUND THE VALUE 
	Intended_Hz_value = math.floor(Intended_Hz_value*10)/10 --(Intended_Hz_value+0.5)
	
	-- ReaEQ does not support values below 20Hz; increase to 20.1 to be sure that normalized values are positive
	if Intended_Hz_value < 20.1 then Intended_Hz_value = 20.1 end
	
	if Intended_Hz_value > 24000 then Intended_Hz_value = 24000 end

	local attemptNormalized_from_Formatted = ( (math.log(Intended_Hz_value)*0.1620)+((1/math.log(Intended_Hz_value))*0.70)+(Intended_Hz_value*0.0000018) )-0.745
	
	-- FOR FIRST COMPARISON, GET FORMATTED VALUE from attemptNormalized_from_Formatted
	local retval, FormattedByReaScript = reaper.TrackFX_FormatParamValue(given_Track,given_ReaEQFXindex,given_FreqParamNumber,attemptNormalized_from_Formatted,64)
	FormattedByReaScript = tonumber(string.sub(FormattedByReaScript,1,(string.find(FormattedByReaScript,' Hz')-1)))									
	--reaper.ShowConsoleMsg('\n INITIAL FormattedByReaScript:'..FormattedByReaScript)

	local FormattedMatchesIntended = false
	--local searchIterationsWereNeeded = 0
	
	while FormattedMatchesIntended == false
	do
		-- CLOSE ENOUGH ACCURACY; FINDING EXACT VALUES WOULD BE INEFFICIENT AND UNNECESSARY
		if FormattedByReaScript > (Intended_Hz_value-(Intended_Hz_value/1000)) and FormattedByReaScript < (Intended_Hz_value+(Intended_Hz_value/1000))
		then
			FormattedMatchesIntended = true
			properNormalized = attemptNormalized_from_Formatted
			--[[
			reaper.ShowConsoleMsg('\n Intended_Hz_value:'..Intended_Hz_value
			..' properNormalized:'..properNormalized
			..', FormattedByReaScript:'..FormattedByReaScript
			..', search iterations done to find this:'..searchIterationsWereNeeded)
			--]]
		end
		
		if FormattedByReaScript > Intended_Hz_value
		then
			attemptNormalized_from_Formatted = attemptNormalized_from_Formatted - 0.0001
			retval, FormattedByReaScript = reaper.TrackFX_FormatParamValue(given_Track,given_ReaEQFXindex,given_FreqParamNumber,attemptNormalized_from_Formatted,64)
			FormattedByReaScript = tonumber(string.sub(FormattedByReaScript,1,(string.find(FormattedByReaScript,' Hz')-1)))
			--searchIterationsWereNeeded=searchIterationsWereNeeded+1
		end
		
		if FormattedByReaScript < Intended_Hz_value
		then
			attemptNormalized_from_Formatted = attemptNormalized_from_Formatted + 0.0001
			retval, FormattedByReaScript = reaper.TrackFX_FormatParamValue(given_Track,given_ReaEQFXindex,given_FreqParamNumber,attemptNormalized_from_Formatted,64)
			FormattedByReaScript = tonumber(string.sub(FormattedByReaScript,1,(string.find(FormattedByReaScript,' Hz')-1)))
			--searchIterationsWereNeeded=searchIterationsWereNeeded+1
		end

	end--while
	
	return properNormalized
	
end--function convertHzTo_ReaEQNormalizedFreq







--*********************************************************
-- Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm
--*********************************************************
function Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm(given_BeatDelayTime)

	local given_BeatDelayTime = tonumber(given_BeatDelayTime)
	local DelaySyncNormalized = 0
	
	--[[ 0 = 1x1/16  --]] if 		given_BeatDelayTime == 0 then DelaySyncNormalized = 0.29166665673256 -- 1/16  = 0.29166665673256
	--[[ 1 = 2x1/16  --]] elseif	given_BeatDelayTime == 1 then DelaySyncNormalized = 0.375 			-- 1/8 	 = 0.375
	--[[ 2 = 3x1/16  --]] elseif	given_BeatDelayTime == 2 then DelaySyncNormalized = 0.40277779102325 -- 1/8 D = 0.40277779102325
	--[[ 3 = 4x1/16  --]] elseif	given_BeatDelayTime == 3 then DelaySyncNormalized = 0.625 			-- 1/4   = 0.625
	--[[ 4 = 5x1/16  --]] elseif	given_BeatDelayTime == 4 then DelaySyncNormalized = 0.65277779102325 -- NOT SUPPORTED, 0.78125
	--[[ 5 = 6x1/16  --]] elseif	given_BeatDelayTime == 5 then DelaySyncNormalized = 0.65277779102325 -- 1/4 D = 0.65277779102325
	--[[ 6 = 8x1/16  --]] elseif	given_BeatDelayTime == 6 then DelaySyncNormalized = 0.70833331346512 -- 1/2   = 0.70833331346512
	--[[ 7 = 16x1/16 --]] elseif	given_BeatDelayTime == 7 then DelaySyncNormalized = 0.79166668653488 -- 1/1   = 0.79166668653488
							
							else    DelaySyncNormalized = 0.375
	
						  end--if
						  
	return DelaySyncNormalized
	
end--function Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm









--*********************************************************
-- Live_BeatDelayTime_to_QuarterNotes
--*********************************************************
function Live_BeatDelayTime_to_QuarterNotes(given_BeatDelayTime)

	local given_BeatDelayTime = tonumber(given_BeatDelayTime)
	local BeatDelayTime_InQN = 0
	
	--[[ 0 = 1x1/16  --]] if 		given_BeatDelayTime == 0 then BeatDelayTime_InQN = 0.25		-- 1/16
	--[[ 1 = 2x1/16  --]] elseif	given_BeatDelayTime == 1 then BeatDelayTime_InQN = 0.5	 	-- 1/8
	--[[ 2 = 3x1/16  --]] elseif	given_BeatDelayTime == 2 then BeatDelayTime_InQN = 0.75		-- 1/8 + 1/16 
	--[[ 3 = 4x1/16  --]] elseif	given_BeatDelayTime == 3 then BeatDelayTime_InQN = 1	 	-- 1/4
	--[[ 4 = 5x1/16  --]] elseif	given_BeatDelayTime == 4 then BeatDelayTime_InQN = 1.25		-- 1/4 + 1/16
	--[[ 5 = 6x1/16  --]] elseif	given_BeatDelayTime == 5 then BeatDelayTime_InQN = 1.5		-- 1/4 + 1/8 
	--[[ 6 = 8x1/16  --]] elseif	given_BeatDelayTime == 6 then BeatDelayTime_InQN = 2		 -- 1/2   
	--[[ 7 = 16x1/16 --]] elseif	given_BeatDelayTime == 7 then BeatDelayTime_InQN = 4 		-- 1/1  
							
							else    BeatDelayTime_InQN = 0.75
	
						  end--if
						  
	return BeatDelayTime_InQN
	
end--function Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm











--*********************************************************
-- convertMillisecondsTo_SpaceshipNormalizedMs
--*********************************************************
function convertMillisecondsTo_SpaceshipNormalizedMs(	given_Track,
														given_FXindex,
														given_ParamNumber,
														given_Ms
														)

	local properNormalized = 0
	local Intended_Ms_value = tonumber(given_Ms)
	
	-- IMPORTANT! ROUND THE VALUE 
	Intended_Ms_value = math.floor(Intended_Ms_value*10)/10 --(Intended_Ms_value+0.5)
	
	if Intended_Ms_value < 0.1 then Intended_Ms_value = 0.1 end
	
	if Intended_Ms_value > 6000 then Intended_Ms_value = 6000 end

	local attemptNormalized_from_Formatted = math.log(Intended_Ms_value+(Intended_Ms_value*7.5))/10.75
	
	-- FOR FIRST COMPARISON, GET FORMATTED VALUE from attemptNormalized_from_Formatted
	reaper.TrackFX_SetParamNormalized(	given_Track,						-- MediaTrack track, 
										given_FXindex,						-- integer fx, 
										given_ParamNumber,					-- integer param, 
										attemptNormalized_from_Formatted	-- number value
										)

	local retval, FormattedValue = reaper.TrackFX_GetFormattedParamValue(given_Track,		-- MediaTrack track, 
																		given_FXindex,		-- integer fx, 
																		given_ParamNumber,	-- integer param, 
																		64					-- string buf
																		)


	FormattedValue = tonumber(FormattedValue)									
	--reaper.ShowConsoleMsg('\n INITIAL FormattedValue:'..FormattedValue)

	local FormattedMatchesIntended = false
	local searchIterationsWereNeeded = 0
	
	while FormattedMatchesIntended == false
	do
		-- CLOSE ENOUGH ACCURACY; FINDING EXACT VALUES WOULD BE INEFFICIENT AND UNNECESSARY
		if FormattedValue > (Intended_Ms_value-(Intended_Ms_value/1000)) and FormattedValue < (Intended_Ms_value+(Intended_Ms_value/1000))
		then
			FormattedMatchesIntended = true
			properNormalized = attemptNormalized_from_Formatted
			--[[
			reaper.ShowConsoleMsg('\n Intended_Ms_value:'..Intended_Ms_value
			..' properNormalized:'..properNormalized
			..', FormattedValue:'..FormattedValue
			..', search iterations done to find this:'..searchIterationsWereNeeded)
			--]]
		end
		
		if FormattedValue > Intended_Ms_value
		then
			attemptNormalized_from_Formatted = attemptNormalized_from_Formatted - 0.0001
			reaper.TrackFX_SetParamNormalized(	given_Track,given_FXindex,given_ParamNumber,attemptNormalized_from_Formatted)
			retval, FormattedValue = reaper.TrackFX_GetFormattedParamValue(given_Track,given_FXindex,given_ParamNumber,64)
			FormattedValue = tonumber(FormattedValue)
			searchIterationsWereNeeded=searchIterationsWereNeeded+1
		end
		
		if FormattedValue < Intended_Ms_value
		then
			attemptNormalized_from_Formatted = attemptNormalized_from_Formatted + 0.0001
			reaper.TrackFX_SetParamNormalized(	given_Track,given_FXindex,given_ParamNumber,attemptNormalized_from_Formatted)
			retval, FormattedValue = reaper.TrackFX_GetFormattedParamValue(given_Track,given_FXindex,given_ParamNumber,64)
			FormattedValue = tonumber(FormattedValue)
			
			searchIterationsWereNeeded=searchIterationsWereNeeded+1
		end

	end--while
	
	return properNormalized
	
end--function convertMillisecondsTo_SpaceshipNormalizedMs






--*********************************************************
-- convertHexToBytes
--*********************************************************

--directly from stackoverflow...
-- usage: 
--("48656C6C6F20776F726C6421"):convertHexToBytes() --> Hello world!

function string.convertHexToBytes(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end




--*********************************************************
-- convertToBase64
--*********************************************************
-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function convertToBase64(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end








--*********************************************************
-- removeSpacesAndTabs
--*********************************************************

function removeSpacesAndTabs(given_string)

    local stringWithoutSpaces = string.gsub(given_string, "%s", "")
          
    stringWithoutSpacesAndTabs = string.gsub(stringWithoutSpaces, "\t", "")
    
    return  stringWithoutSpacesAndTabs

end--removeSpacesAndTabs





--*********************************************************
-- printTableToConsole
--*********************************************************

function printTableToConsole(given_Table,given_TableName)

	reaper.ShowConsoleMsg("\n\nContents of table:"..given_TableName)
	
	for i=1,#given_Table,1
	do
		reaper.ShowConsoleMsg("\n"..i..":"..given_Table[i])
	end --for i
	
end--function printTableToConsole




--*********************************************************
-- printTableToString
--*********************************************************

function printTableToString(given_Table,given_TableName)

    local stringFromTable = "\n\nContents of table:"..given_TableName
	
	for i=1,#given_Table,1
	do
    
        stringFromTable = stringFromTable.."\n"..i..":"..given_Table[i]
    
	end --for i
    
    return stringFromTable
	
end--function printTableToString









--*********************************************************
-- makeTableFrom_RPPXMLchunk
--*********************************************************

function makeTableFrom_RPPXMLchunk(given_Chunk)

	local returnableTable = {}

	local PreviousLinebreakIndex = 0 

	for i=1,string.len(given_Chunk),1
	do
		--reaper.ShowConsoleMsg('\nstring.sub(given_Chunk,i,i))='..string.sub(given_Chunk,i,i))
		if string.sub(given_Chunk,i,i) == "\n"
		then
			--reaper.ShowConsoleMsg('PreviousLinebreakIndex:'..PreviousLinebreakIndex)
			--reaper.ShowConsoleMsg('\nstring.sub(given_Chunk,i,(i+1))='..string.sub(given_Chunk,i,(i+1)))
			--reaper.ShowConsoleMsg('\nLine break found at '..i)
			
			local newLine = string.sub(given_Chunk,(PreviousLinebreakIndex+1),(i-1)) -- +1 i-1 removes line breaks
			--reaper.ShowConsoleMsg('\nnewLine:'..newLine)
			table.insert(returnableTable,newLine)
			
			PreviousLinebreakIndex = i

		end--if string.sub(given_Chunk,i,i) == "\n"
		
	end--for i=1,string.len(given_Chunk),1
	
	return returnableTable
	
end--makeTableFrom_RPPXMLchunk(given_Chunk)
	
	
	




	
--*********************************************************
-- getValueFrom_SingleLineXMLTag
--*********************************************************

function getValueFrom_SingleLineXMLTag(given_Table,given_Index,given_TagStartString,given_TagEndString)

	String_Value = tostring(given_Table[given_Index])
	String_Value = string.sub(String_Value,
	string.find(String_Value,given_TagStartString)+string.len(given_TagStartString),
	string.find(String_Value,given_TagEndString)-1
	)			

	return String_Value

end--function getValueFrom_SingleLineXMLTag








--*********************************************************
-- searchTableFor_FIRST_SingleLineXMLTagValue
--*********************************************************

function searchTableFor_FIRST_SingleLineXMLTagValue(given_Table,given_TagStartString,given_TagEndString)

	local String_Value = ''

	for i=1,#given_Table,1
	do
		if string.match(given_Table[i],given_TagStartString)
		then
			String_Value = tostring(given_Table[i])
			String_Value = string.sub(String_Value,
			string.find(String_Value,given_TagStartString)+string.len(given_TagStartString),
			string.find(String_Value,given_TagEndString)-1
			)
			
		break--enclosing for loop
		
		end--if
	end--for

	return String_Value

end-- function searchTableFor_FIRST_SingleLineXMLTagValue








--*********************************************************
-- makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt
--*********************************************************

function makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(given_Table,given_StartTag,given_EndTag)

	local newTable = {}

	-----------------------
	-- FIND START TAG INDEX
	-----------------------
	
	local StartTagIndex = 0
	
	for i=1,#given_Table,1
	do
		if string.match(given_Table[i],given_StartTag)
		then
			StartTagIndex = i
			break--enclosing for loop
		end
	end

	-----------------------
	-- FIND END TAG INDEX
	-----------------------
	
	local EndTagIndex = 0
	
	for j=StartTagIndex,#given_Table,1
	do
		-- start filling newTable from found StartTagIndex
		table.insert(newTable,given_Table[j])
		
		if string.match(given_Table[j],given_EndTag)
		then
			break--enclosing for loop
		end
	end
	
	--for check=1,#newTable,1 do reaper.ShowConsoleMsg('\n'..newTable[check]) end
	
	return newTable

end--makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt








--*********************************************************
-- makeSubtableBy_StartIndex_and_FIRST_EndTag
--*********************************************************

function makeSubtableBy_StartIndex_and_FIRST_EndTag(given_Table,given_StartTagIndex,given_EndTag)

	local newTable = {}

	-----------------------
	-- FIND END TAG INDEX
	-----------------------
	
	--reaper.ShowConsoleMsg("\n given_StartTagIndex at "..given_StartTagIndex..": "..given_Table[given_StartTagIndex])
	--reaper.ShowConsoleMsg("\n Looking for  given_EndTag:"..given_EndTag)
	
	local currentIteration = given_StartTagIndex
	
	local endTagIndex = 0
	
	-- search forwards in given_Table, starting from given_StartTagIndex
	while endTagIndex == 0
	do
		currentIteration = currentIteration+1
		
		if string.match(given_Table[currentIteration],given_EndTag)
		then
			endTagIndex = currentIteration
			--reaper.ShowConsoleMsg("\n endTag "..given_EndTag.." found at "..currentIteration..": "..given_Table[currentIteration])
		end--if
		
	end--while
	
	
	-----------------------------------------------------------------------------------------
	--FILL newTable with given_Table CONTENTS FROM BETWEEN given_StartIndex and endTagIndex
	-----------------------------------------------------------------------------------------
	
	for i=given_StartTagIndex,endTagIndex,1
	do
		table.insert(newTable,given_Table[i])
	end

	return newTable
	

end--function makeSubtableBy_StartIndex_and_FIRST_EndTag








--*******************************************************************
-- function makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag
--********************************************************************

function makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag(given_Table,given_StartTagIndex,given_EndTag)

	local newTable = {}

	-----------------------
	-- FIND END TAG INDEX
	-----------------------
	
	--reaper.ShowConsoleMsg("\n given_StartTagIndex at "..given_StartTagIndex..": "..given_Table[given_StartTagIndex])
	--reaper.ShowConsoleMsg("\n Looking for  given_EndTag:"..given_EndTag)
	
	local currentIteration = given_StartTagIndex
	
	local endTagIndex = 0
	
	-- search forwards in given_Table, starting from given_StartTagIndex
	while endTagIndex == 0
	do
		currentIteration = currentIteration+1
		
		if string.match(given_Table[currentIteration],given_EndTag)
		then
			endTagIndex = currentIteration
			--reaper.ShowConsoleMsg("\n endTag "..given_EndTag.." found at "..currentIteration..": "..given_Table[currentIteration])
		end--if
		
	end--while
	
	
	-----------------------------------------------------------------------------------------
	--FILL newTable with given_Table CONTENTS FROM BETWEEN given_StartIndex and endTagIndex
	-----------------------------------------------------------------------------------------
	
	for i=given_StartTagIndex,(endTagIndex-1),1
	do
		table.insert(newTable,given_Table[i])
	end

	return newTable
	

end--function makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag







--*********************************************************
-- makeSubtableBy_StartIndex_and_LAST_EndTag
--*********************************************************

function makeSubtableBy_StartIndex_and_LAST_EndTag(given_Table,given_StartTagIndex,given_EndTag)

	local newTable = {}

	-----------------------
	-- FIND END TAG INDEX
	-----------------------
	
	--reaper.ShowConsoleMsg("\n given_StartTagIndex at "..given_StartTagIndex..": "..given_Table[given_StartTagIndex])
	--reaper.ShowConsoleMsg("\n Looking for  given_EndTag:"..given_EndTag)
	
	local currentIteration = #given_Table
	
	local endTagIndex = #given_Table
	
	-- search from end of given_Table, starting from last index in table
	while endTagIndex == #given_Table
	do
		currentIteration = currentIteration-1
		
		if string.match(given_Table[currentIteration],given_EndTag)
		then
			endTagIndex = currentIteration
			--reaper.ShowConsoleMsg("\n endTag "..given_EndTag.." found at "..currentIteration..": "..given_Table[currentIteration])
		end--if
		
	end--while
	
	
	-----------------------------------------------------------------------------------------
	--FILL newTable with given_Table CONTENTS FROM BETWEEN given_StartIndex and endTagIndex
	-----------------------------------------------------------------------------------------
	
	for i=given_StartTagIndex,endTagIndex,1
	do
		table.insert(newTable,given_Table[i])
	end

	return newTable
	

end--function makeSubtableBy_StartIndex_and_LAST_EndTag









--*********************************************************
-- makeSubtableBy_StartIndex_and_LAST_EndTag_ExcludingLastIndex
--*********************************************************

function makeSubtableBy_StartIndex_and_LAST_EndTag_ExcludingLastIndex(given_Table,given_StartTagIndex,given_EndTag)

	local newTable = {}

	-----------------------
	-- FIND END TAG INDEX
	-----------------------
	
	--reaper.ShowConsoleMsg("\n given_StartTagIndex at "..given_StartTagIndex..":\n"..given_Table[given_StartTagIndex])
	--reaper.ShowConsoleMsg("\n Looking for  given_EndTag:"..given_EndTag)
	

	local endTagIndex = 0
	
	-- search from end of given_Table, starting from second-to-last index in table
	for i=#given_Table-1,1,-1
	do
		if string.match(given_Table[i],given_EndTag)
		then
			endTagIndex = i
			--reaper.ShowConsoleMsg("\n endTag "..given_EndTag.." found at "..i..":\n"..given_Table[i])
			break
		end--if
		
	end--while
	
	
	-----------------------------------------------------------------------------------------
	--FILL newTable with given_Table CONTENTS FROM BETWEEN given_StartIndex and endTagIndex
	-----------------------------------------------------------------------------------------
	
	for i=given_StartTagIndex,endTagIndex,1
	do
		table.insert(newTable,given_Table[i])
	end

	return newTable
	

end--makeSubtableBy_StartIndex_and_LAST_EndTag_ExcludingLastIndex








--*************************************************
--  getSubstringBetweenStrings
--*************************************************
function getSubstringBetweenStrings(given_FullString,given_StartString,given_EndString)

	--reaper.ShowConsoleMsg("\ngiven_FullString:"..given_FullString..", given_StartString:"..given_StartString..", given_EndString:"..given_EndString)

	newSubstring = string.sub(given_FullString,
									string.find(given_FullString,given_StartString)+string.len(given_StartString),
									string.find(given_FullString,given_EndString)-1
									)
	return newSubstring
	

end--function getSubstringBetweenStrings








--*************************************************
-- get_LiveManualValue_FromXMLTable
--*************************************************
function get_LiveManualValue_FromXMLTable(given_Table)

	local manualValue

	for i=1,#given_Table,1
	do	
		if string.match(given_Table[i],'<Manual Value="')
		then
			manualValue = tostring(given_Table[i])
			manualValue = string.sub(manualValue,
			string.find(manualValue,'<Manual Value="')+15,
			string.find(manualValue,'" />')-1
			)	
		end--if
		
	end--for
	
	return manualValue

end--function get_LiveManualValue_FromTable(given_table)








--*************************************************
-- get_LiveAutomationTargetId_FromXMLTable
--*************************************************
function get_LiveAutomationTargetId_FromXMLTable(given_Table)

	local AutomationTargetId

	for i=1,#given_Table,1
	do	
		if string.match(given_Table[i],'<AutomationTarget Id="')
		then
			AutomationTargetId = tostring(given_Table[i])
			AutomationTargetId = string.sub(
			AutomationTargetId,
			string.find(AutomationTargetId,'<AutomationTarget Id="')+22,
			string.find(AutomationTargetId,'">')-1
			)	
		end--if
		
	end--for
	
	return AutomationTargetId

end--function get_LiveManualValue_FromTable(given_table)







--*****************************************************
-- get_ManVal_AuTargId_from_ContTagInXMLTable
--*****************************************************
function get_ManVal_AuTargId_from_ContTagInXMLTable(given_Table,given_StartTag)

	local EndTag = '</'..string.sub(given_StartTag,2,string.len(given_StartTag)-1)..'>'
	
	--reaper.ShowConsoleMsg('\nget_ManVal_AuTargId_from_ContTagInXMLTable')
	--reaper.ShowConsoleMsg('\ngiven_StartTag:'..given_StartTag..' EndTag:'..EndTag)
	
	local ManualValue
	local AutomationTargetId
	
	----------------------------------------------------------------------------
	-- START SEARCHING THE WHOLE TABLE FOR CONTAINER'S given_StartTag
	----------------------------------------------------------------------------
	for i=1,#given_Table,1
	do
		----------------------------------------------------------------------------
		-- IF CONTAINER'S given_StartTag IS FOUND...
		-- (MEANING THAT i HAS REACHED THE SPECIFIED CONTAINER TAG IN XML TABLE)
		----------------------------------------------------------------------------
		if string.match(given_Table[i],given_StartTag)
		then
			--reaper.ShowConsoleMsg('\n'..i..' Found given_StartTag:'..given_StartTag..':'..given_Table[i])
			-----------------------------------------------------------------------------
			-- ...START SEARCHING FOR SINGLE-LINE TAGS ManualValue and AutomationTargetId 
			-- BEGINNING FROM INDEX AT WHICH given_StartTag WAS FOUND
			-----------------------------------------------------------------------------
			for j=i,#given_Table,1
			do
				if string.match(given_Table[j],'<Manual Value="')
				then
					--reaper.ShowConsoleMsg('\n'..j..' Found <Manual Value=":'..given_Table[j])
					ManualValue = tostring(given_Table[j])
					ManualValue = string.sub(ManualValue,
					string.find(ManualValue,'<Manual Value="')+15,
					string.find(ManualValue,'" />')-1
					)
					--reaper.ShowConsoleMsg('\n ManualValue:'..ManualValue)
				end--if
				

				if string.match(given_Table[j],'<AutomationTarget Id="')
				then
					--reaper.ShowConsoleMsg('\n'..j..' Found <AutomationTarget Id=":'..given_Table[j])
					AutomationTargetId = tostring(given_Table[j])
					AutomationTargetId = string.sub(
					AutomationTargetId,
					string.find(AutomationTargetId,'<AutomationTarget Id="')+22,
					string.find(AutomationTargetId,'">')-1
					)
					--reaper.ShowConsoleMsg('\n AutomationTargetId:'..AutomationTargetId)
				
					------------------------------------------------------------------
					-- BREAK j LOOP HERE BECAUSE VALUES AFTER THIS WERE NOT REQUESTED
					------------------------------------------------------------------
					
					break--enclosing for loop
					
				end--if
			
			end--for j

		end--if string.match(given_Table[i],given_StartTag)
	
	
		----------------------------------------------------------------------------
		-- IF CONTAINER'S EndTag IS FOUND...
		----------------------------------------------------------------------------
		if string.match(given_Table[i],EndTag)
		then
		
			--reaper.ShowConsoleMsg('\n'..i..' Found EndTag:'..EndTag)
			
			---------------------------------------------------------------------------------------
			-- ...BREAK i LOOP HERE, BECAUSE REQUESTED XML CONTAINER ENDS HERE 
			-- CONTINUING WOULD RISK GETTING VALUES FROM WRONG CONTAINERS, AS WELL AS WASTE CYCLES
			---------------------------------------------------------------------------------------
							
			break--enclosing for loop
			
		end--if string.match(given_Table[i],EndTag)
		
	end--for i

	return ManualValue,AutomationTargetId

end--function get_ManVal_AuTargId_from_ContTagInXMLTable







--*************************************************
-- getFXSlotBypassParameterNumber
--*************************************************
function getFXSlotBypassParameterNumber(given_Track,given_FXindex)

	local numberOfParameters = reaper.TrackFX_GetNumParams(given_Track,given_FXindex)

	--local WetParNum = numberOfParameters-1 --should be Wet in REAPER versions before v6.37
	local BypassParNum = numberOfParameters-3 --should be Bypass in REAPER versions before v6.37
	
	-- SINCE REAPER v6.37:
	--	-1: Delta, -2: Wet, -3: Bypass
	
	local retval, currentParamName = reaper.TrackFX_GetParamName(given_Track,given_FXindex,BypassParNum,64)

	if currentParamName ~= 'Bypass'
	then
		ShowConsoleMsg_and_AddtoLog('\n WARNING: Bypass parameter not found: Parameter Number'..BypassParNum..', currentParamName:'.. currentParamName)
	end
	
	return BypassParNum
	
end--function getFXSlotBypassParameterNumber








--*************************************************
-- getFXSlotWetParameterNumber
--*************************************************
function getFXSlotWetParameterNumber(given_Track,given_FXindex)

	local numberOfParameters = reaper.TrackFX_GetNumParams(given_Track,given_FXindex)

	local WetParNum = numberOfParameters-2 --should be Wet in REAPER versions before v6.37
	
	-- SINCE REAPER v6.37:
	--	-1: Delta, -2: Wet, -3: Bypass

	local retval, currentParamName = reaper.TrackFX_GetParamName(given_Track,given_FXindex,WetParNum,64)

	if currentParamName ~= 'Wet'
	then
		ShowConsoleMsg_and_AddtoLog('\n WARNING: Wet parameter not found: Parameter Number'..WetParNum..', currentParamName:'.. currentParamName)
	end
	
	return WetParNum
	
end--function getFXSlotWetParameterNumber







--*********************************************************
-- getParNumBy_1stParNameInPNPMTable
--*********************************************************
function getParNumBy_1stParNameInPNPMTable(given_ParameterTable,given_ParameterName)

	local ParameterNumber = 0
	
	for i=0,#given_ParameterTable,1
	do
		if given_ParameterTable[i] == given_ParameterName
		then
			ParameterNumber = i
			break
		end
	end
	
	return ParameterNumber

end--getParNumBy_1stParNameInPNPMTable








--*************************************************
-- applyTrackRouting
-- NOTE: must be done AFTER all tracks are inserted
--*************************************************
function applyTrackRouting()

	ShowConsoleMsg_and_AddtoLog('\n\nApplying track routings...')


	--[[ 
	TRACK_ID_TABLE 
	LEVEL 1						VALUE
	[#] track index in REAPER 	Track Id 
	--]]


	--[[ 
	TRACK_ROUTINGS_TABLE 
	LEVEL 1						LEVEL 2					VALUE
	[#] track index in REAPER 	[1]AudioIn Target		string
								[2]MidiIn Target		string
								[3]AudioOut Target		string
								[4]MidiOut Target 		string
								[5]Is Sidechain Source 	boolean
	--]]


	--[[
	reaper.SetTrackSendInfo_Value(
								-- MediaTrack tr; THIS REAPER TRACK!
								-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
								-- send index (integer)
								-- parameter name (string)
								-- new value (number)
								)
								
	PARAMETERS			POSSIBLE VALUES						
	'I_SENDMODE'	:	0=post-fader, 1=pre-fx, 3=post-fx
	'I_SRCCHAN' 	:	channels on SOURCE, stereo pairs, -1 = none (MIDI only), note: THE PROPER WAY TO SET MIDI ONLY!
	'I_DSTCHAN' 	:	channels on DESTINATION, stereo pairs, -1 = MIDI only
	'I_MIDIFLAGS'	:	31 = no MIDI
	--]]


	local function findREAPERtrackIndex_basedOnLiveTrackId(given_LiveTrackId)
	
		local trIndex
		
		--reaper.ShowConsoleMsg('\ngiven_LiveTrackId:'..given_LiveTrackId)
		
		for c=0,#TRACK_ID_TABLE,1
		do
			-- find which Reaper track index has given_LiveTrackId
			if TRACK_ID_TABLE[c] == given_LiveTrackId
			then
				
				--reaper.ShowConsoleMsg('\nTRACK_ID_TABLE['..c..']:'..TRACK_ID_TABLE[c]..', given_LiveTrackId:'..given_LiveTrackId)
			
				trIndex = c
				break
			end--if
		end--for c
		
		return trIndex
		
	end--function findREAPERtrackIndex_basedOnLiveTrackId



	for i=0,#TRACK_ROUTINGS_TABLE,1
	do
		local thisREAPERtrack = reaper.GetTrack(0,i)
		local retval, thisREAPERtrack_name = reaper.GetTrackName(thisREAPERtrack,'')
		
		local trackToReceiveAudioFrom_index
		local trackToReceiveAudioFrom
		local trackToReceiveAudioFrom_name 
		
		local trackToSendAudioTo_index
		local trackToSendAudioTo
		local trackToSendAudioTo_name
		
		local trackToReceiveMIDIFrom_index
		local trackToReceiveMIDIFrom
		local trackToReceiveMIDIFrom_name
		
		local trackToSendMIDITo_index
		local trackToSendMIDITo
		local trackToSendMIDITo_name
		
		local showRoutingMessage = true
		
		--reaper.ShowConsoleMsg('\n    REAPER track index:'..i..', Id='..TRACK_ID_TABLE[i])
		
		
		---------------------------------------------------------------
		-- <AudioInputRouting>
		---------------------------------------------------------------
		local AudioInput_string = TRACK_ROUTINGS_TABLE[i][1]
		local AudioInput_Id = ''
		local AudioInput_SENDMODE = 0 --0=post-fader, 1=pre-fx, 3=post-fx
		local AudioInput_SENDMODE_name = ''
		
		if string.match(AudioInput_string,'AudioIn/External')
		then
			AudioInput_Id = AudioInput_string
			showRoutingMessage = false
			
		elseif string.match(AudioInput_string,'AudioIn/None')
		then
			AudioInput_Id = AudioInput_string
			showRoutingMessage = false

		elseif string.match(AudioInput_string,'/PreFxOut')
		then
		
			--reaper.ShowConsoleMsg('\n    AudioInput_string:'..AudioInput_string..' contains /PreFxOut')
		
			AudioInput_Id = getSubstringBetweenStrings(AudioInput_string,'AudioIn/Track.','/PreFxOut')
			AudioInput_SENDMODE = 1
			AudioInput_SENDMODE_name = 'PreFxOut'
			showRoutingMessage = true
			
			-- receive from track ID
			trackToReceiveAudioFrom_index = findREAPERtrackIndex_basedOnLiveTrackId(AudioInput_Id)
			trackToReceiveAudioFrom = reaper.GetTrack(0,trackToReceiveAudioFrom_index)
			retval, trackToReceiveAudioFrom_name = reaper.GetTrackName(trackToReceiveAudioFrom,'')
			
			reaper.CreateTrackSend(trackToReceiveAudioFrom,thisREAPERtrack)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									AudioInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
			
			
		elseif string.match(AudioInput_string,'/PostFxOut')
		then
		
			--reaper.ShowConsoleMsg('\n    AudioInput_string:'..AudioInput_string..' contains /PostFxOut')
			
		
			AudioInput_Id = getSubstringBetweenStrings(AudioInput_string,'AudioIn/Track.','/PostFxOut')
			AudioInput_SENDMODE = 3
			AudioInput_SENDMODE_name = 'PostFxOut'
			showRoutingMessage = true
			
			-- receive from track ID
			trackToReceiveAudioFrom_index = findREAPERtrackIndex_basedOnLiveTrackId(AudioInput_Id)
			trackToReceiveAudioFrom = reaper.GetTrack(0,trackToReceiveAudioFrom_index)
			retval, trackToReceiveAudioFrom_name = reaper.GetTrackName(trackToReceiveAudioFrom,'')
			
			reaper.CreateTrackSend(trackToReceiveAudioFrom,thisREAPERtrack)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									AudioInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
			
		elseif string.match(AudioInput_string,'/TrackOut')
		then
		
			--reaper.ShowConsoleMsg('\n    AudioInput_string:'..AudioInput_string..' contains /TrackOut')
		
			AudioInput_Id = getSubstringBetweenStrings(AudioInput_string,'AudioIn/Track.','/TrackOut')
			AudioInput_SENDMODE = 0
			AudioInput_SENDMODE_name = 'TrackOut'
			showRoutingMessage = true
			
			-- receive from track ID
			trackToReceiveAudioFrom_index = findREAPERtrackIndex_basedOnLiveTrackId(AudioInput_Id)
			trackToReceiveAudioFrom = reaper.GetTrack(0,trackToReceiveAudioFrom_index)
			retval, trackToReceiveAudioFrom_name = reaper.GetTrackName(trackToReceiveAudioFrom,'')
			
			reaper.CreateTrackSend(trackToReceiveAudioFrom,thisREAPERtrack)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									AudioInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
									
		else
		
			showRoutingMessage = false
			ShowConsoleMsg_and_AddtoLog('\n ERROR:   AUDIO INPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    AudioInput_string:'..AudioInput_string)
			
			table.insert(WARNINGS_TABLE,'\n AUDIO INPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    AudioInput_string:'..AudioInput_string)

		end--if string.match(AudioInput
		
		if showRoutingMessage == true
		then
			ShowConsoleMsg_and_AddtoLog('\n    Track '..(i+1)..' "'..thisREAPERtrack_name
			..'" (Live Id:'..TRACK_ID_TABLE[i]
			..') receives audio from track '..(trackToReceiveAudioFrom_index+1)..': "'..trackToReceiveAudioFrom_name
			..'" (LiveId: '..AudioInput_Id
			..') Live receive mode:'..AudioInput_SENDMODE_name..', REAPER I_SENDMODE:'..AudioInput_SENDMODE
			)
		end
		

		---------------------------------------------------------------
		-- <MidiInputRouting>
		---------------------------------------------------------------
		local MidiInput_string = TRACK_ROUTINGS_TABLE[i][2]
		local MidiInput_Id = ''
		local MidiInput_SENDMODE = 1 -- 1=pre-fx, 3=post-fx
		local MidiInput_SENDMODE_name = ''
		
		if string.match(MidiInput_string,'MidiIn/External')
		then
			MidiInput_Id = MidiInput_string
			showRoutingMessage = false
			
		elseif string.match(MidiInput_string,'MidiIn/None')
		then
			MidiInput_Id = MidiInput_string
			showRoutingMessage = false
				
		elseif string.match(MidiInput_string,'/PreFxOut')
		then
			MidiInput_Id = getSubstringBetweenStrings(MidiInput_string,'MidiIn/Track.','/PreFxOut')
			MidiInput_SENDMODE = 1
			MidiInput_SENDMODE_name = 'PreFxOut'
			showRoutingMessage = true
			
			-- receive from track ID
			trackToReceiveMIDIFrom_index = findREAPERtrackIndex_basedOnLiveTrackId(MidiInput_Id)
			trackToReceiveMIDIFrom = reaper.GetTrack(0,trackToReceiveMIDIFrom_index)
			retval, trackToReceiveMIDIFrom_name = reaper.GetTrackName(trackToReceiveMIDIFrom,'')
			
			reaper.CreateTrackSend(trackToReceiveMIDIFrom,thisREAPERtrack)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									MidiInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
			
			-- SET TO RECEIVE MIDI ONLY			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SRCCHAN',				-- parameter name (string) 
									-1							-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
			
		elseif string.match(MidiInput_string,'/PostFxOut')
		then
			MidiInput_Id = getSubstringBetweenStrings(MidiInput_string,'MidiIn/Track.','/PostFxOut')
			MidiInput_SENDMODE = 3
			MidiInput_SENDMODE_name = 'PostFxOut'
			showRoutingMessage = true
			
			-- receive from track ID
			trackToReceiveMIDIFrom_index = findREAPERtrackIndex_basedOnLiveTrackId(MidiInput_Id)
			trackToReceiveMIDIFrom = reaper.GetTrack(0,trackToReceiveMIDIFrom_index)
			retval, trackToReceiveMIDIFrom_name = reaper.GetTrackName(trackToReceiveMIDIFrom,'')
			
			reaper.CreateTrackSend(trackToReceiveMIDIFrom,thisREAPERtrack)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									MidiInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
			
			-- SET TO RECEIVE MIDI ONLY			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									-1,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SRCCHAN',				-- parameter name (string) 
									-1							-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
		
		else
		
			showRoutingMessage = false
			ShowConsoleMsg_and_AddtoLog('\n ERROR:   MIDI INPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    MidiInput_string:'..MidiInput_string)
			
			table.insert(WARNINGS_TABLE,'\n MIDI INPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    MidiInput_string:'..MidiInput_string)
			
		end--if string.match(MidiInput
		
		if showRoutingMessage == true
		then
			ShowConsoleMsg_and_AddtoLog('\n         Track '..(i+1)..' "'..thisREAPERtrack_name
			..'" (Live Id:'..TRACK_ID_TABLE[i]
			..') receives MIDI from track '..(trackToReceiveMIDIFrom_index+1)..': "'..trackToReceiveMIDIFrom_name
			..'" (LiveId: '..MidiInput_Id
			..') Live receive mode:'..MidiInput_SENDMODE_name..', REAPER I_SENDMODE:'..MidiInput_SENDMODE
			)
		end


		---------------------------------------------------------------
		-- <AudioOutputRouting>
		---------------------------------------------------------------
		local AudioOutput_string = TRACK_ROUTINGS_TABLE[i][3]
		local AudioOutput_Id = ''
		local AudioOutput_SENDMODE = 0
		local AudioOutput_SENDMODE_name = ''
		

		
		if string.match(AudioOutput_string,'AudioOut/External') and TRACK_ROUTINGS_TABLE[i][5] == false
		then
			AudioOutput_Id = AudioOutput_string
			showRoutingMessage = false
			
		elseif string.match(AudioOutput_string,'AudioOut/None') and TRACK_ROUTINGS_TABLE[i][5] == false
		then
			AudioOutput_Id = AudioOutput_string
			showRoutingMessage = false

		elseif string.match(AudioOutput_string,'/TrackIn') and TRACK_ROUTINGS_TABLE[i][5] == false
		then
			AudioOutput_Id = getSubstringBetweenStrings(AudioOutput_string,'AudioOut/Track.','/TrackIn')
			AudioOutput_SENDMODE = 0
			AudioOutput_SENDMODE_name = 'TrackIn'
			showRoutingMessage = true
			
			-- send to track ID
			trackToSendAudioTo_index = findREAPERtrackIndex_basedOnLiveTrackId(AudioOutput_Id)
			trackToSendAudioTo = reaper.GetTrack(0,trackToSendAudioTo_index)
			retval, trackToSendAudioTo_name = reaper.GetTrackName(trackToSendAudioTo,'')
			
			reaper.CreateTrackSend(thisREAPERtrack,trackToSendAudioTo)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									AudioInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
									)
									
			-- SET REAPER MASTER SEND OFF
			reaper.SetMediaTrackInfo_Value(
											thisREAPERtrack,		-- MediaTrack tr, 
											'B_MAINSEND',			-- string parmname, 
											0						-- number newvalue
											)
			
		elseif string.match(AudioOutput_string,'AudioOut/Master') 
		and string.match(TRACK_ROUTINGS_TABLE[i][4],"MidiOut/None") --is not a MIDI-only track
		then
			AudioOutput_Id = 'Master'
			AudioOutput_SENDMODE = 0
			AudioOutput_SENDMODE_name = 'Master'
			
			trackToSendAudioTo_index = #TRACK_ID_TABLE -- LIVE MASTER should be the last track in TRACK_ID_TABLE
			trackToSendAudioTo = reaper.GetTrack(0,trackToSendAudioTo_index)
			retval, trackToSendAudioTo_name = reaper.GetTrackName(trackToSendAudioTo,'')
			
			--reaper.ShowConsoleMsg('\n         OUTPUTS TO MASTER, trackToSendAudioTo:'..trackToSendAudioTo)
			
			
			if TRACK_ROUTINGS_TABLE[i][5] == false
			then
			
				showRoutingMessage = true
			
				reaper.CreateTrackSend(thisREAPERtrack,trackToSendAudioTo)
				
				reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
							thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
							0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
							0,							-- send index (integer)
							'I_SENDMODE',				-- parameter name (string)
							AudioInput_SENDMODE			-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
							)
			end
				
				
			-- SET REAPER MASTER SEND OFF
			reaper.SetMediaTrackInfo_Value(
											thisREAPERtrack,		-- MediaTrack tr, 
											'B_MAINSEND',			-- string parmname, 
											0						-- number newvalue
											)
		else
		
			showRoutingMessage = false
			ShowConsoleMsg_and_AddtoLog('\n ERROR:   AUDIO OUTPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    AudioOutput_string:'..AudioOutput_string)
			
			table.insert(WARNINGS_TABLE,'\n AUDIO OUTPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    AudioOutput_string:'..AudioOutput_string)	
			
		end--if string.match(AudioOutput
		
		if showRoutingMessage == true and IsSidechainClickSource == false
		then
			ShowConsoleMsg_and_AddtoLog('\n    Track '..(i+1)..' "'..thisREAPERtrack_name
			..'" (Live Id:'..TRACK_ID_TABLE[i]
			..') sends audio to track '..(trackToSendAudioTo_index+1)..': "'..trackToSendAudioTo_name
			..'" (LiveId: '..AudioOutput_Id
			..') Live send mode:'..AudioOutput_SENDMODE_name..', REAPER I_SENDMODE:'..AudioOutput_SENDMODE
			)
		end
		
		
		
		---------------------------------------------------------------
		-- <MidiOutputRouting> 
		---------------------------------------------------------------
		--[[ NOTE: in Live, 
		
			if a MIDI track has NO INSTRUMENTS/audio-making plugins,
			it outputs only MIDI
				therefore cannot output audio, 
				therefore does not send audio anywhere

			if a MIDI track has an INSTRUMENT/audio-making plugin,
			it becomes an AUDIO-SENDING track (MidiOut/None), so no MIDI send routing needed..?
			
		--]]
		---------------------------------------------------------------
		local MidiOutput_string = TRACK_ROUTINGS_TABLE[i][4]
		local MidiOutput_Id = ''
		local MidiOutput_SENDMODE = 0
		local MidiOutput_SENDMODE_name = ''
		
		if string.match(MidiOutput_string,'MidiOut/External')
		then
			MidiOutput_Id = MidiOutput_string
			showRoutingMessage = false
			
			ShowConsoleMsg_and_AddtoLog('\n\n        NOTE: Track '..(i+1)..' "'..thisREAPERtrack_name..' outputs MIDI to external device:'..MidiOutput_string)
	
		elseif string.match(MidiOutput_string,'MidiOut/None')
		then
			MidiOutput_Id = MidiOutput_string
			showRoutingMessage = false

		elseif string.match(MidiOutput_string,'/TrackIn')		-- IF OUTPUTS MIDI TO a Track
		then
			MidiOutput_Id = getSubstringBetweenStrings(MidiOutput_string,'MidiOut/Track.','/TrackIn')
			MidiOutput_SENDMODE = 0 --get midi Post-Fader, meaning after entire MIDI device chain
			MidiOutput_SENDMODE_name = 'TrackIn'
			showRoutingMessage = true
			
			-- send to track ID
			trackToSendMIDITo_index = findREAPERtrackIndex_basedOnLiveTrackId(MidiOutput_Id)
			trackToSendMIDITo = reaper.GetTrack(0,trackToSendMIDITo_index)
			retval, trackToSendMIDITo_name = reaper.GetTrackName(trackToSendMIDITo,'')
			
			reaper.CreateTrackSend(thisREAPERtrack,trackToSendMIDITo)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									MidiOutput_SENDMODE			-- new value (number)
									)
									
			-- SET TO SEND MIDI ONLY			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SRCCHAN',				-- parameter name (string) 
									-1							-- new value (number)
									)							
									
			-- SET REAPER MASTER SEND OFF
			reaper.SetMediaTrackInfo_Value(
											thisREAPERtrack,		-- MediaTrack tr, 
											'B_MAINSEND',			-- string parmname, 
											0						-- number newvalue
											)


		--IF OUTPUTS MIDI TO specific Device on a Track
		elseif string.match(MidiOutput_string,'/DeviceIn')
		then
		
			MidiOutput_Id = getSubstringBetweenStrings(MidiOutput_string,'MidiOut/Track.','/DeviceIn')
			MidiOutput_SENDMODE = 0
			MidiOutput_SENDMODE_name = 'DeviceIn'
			showRoutingMessage = true
			
			-- send to track ID
			trackToSendMIDITo_index = findREAPERtrackIndex_basedOnLiveTrackId(MidiOutput_Id)
			trackToSendMIDITo = reaper.GetTrack(0,trackToSendMIDITo_index)
			retval, trackToSendMIDITo_name = reaper.GetTrackName(trackToSendMIDITo,'')
			
			reaper.CreateTrackSend(thisREAPERtrack,trackToSendMIDITo)
			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SENDMODE',				-- parameter name (string)
									MidiOutput_SENDMODE			-- new value (number)
									)
									
			-- SET TO SEND MIDI ONLY			
			reaper.SetTrackSendInfo_Value( --NOTE: send index will be 0 because Live sends/receives only one track
									thisREAPERtrack,			-- MediaTrack tr; THIS REAPER TRACK!
									0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									0,							-- send index (integer)
									'I_SRCCHAN',				-- parameter name (string) 
									-1							-- new value (number)
									)
									
			-- SET REAPER MASTER SEND OFF
			reaper.SetMediaTrackInfo_Value(
											thisREAPERtrack,		-- MediaTrack tr, 
											'B_MAINSEND',			-- string parmname, 
											0						-- number newvalue
											)
		
			
			ShowConsoleMsg_and_AddtoLog('\n\n        NOTE: Track '..(i+1)..' "'..thisREAPERtrack_name
			..'" in Live outputs MIDI directly to Device "'..MidiOutput_string
			..'".\n        This does not directly translate to REAPER, so do the equivalent routing manually, if needed.'
			)
			
		elseif  string.match(MidiOutput_string,'MidiOut/None') --true for audio tracks and instrument tracks; nothing needs to be done..?
		then
		
			showRoutingMessage = false
		
		else
		
			showRoutingMessage = false
			ShowConsoleMsg_and_AddtoLog('\n ERROR:   MIDI OUTPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    MidiOutput_string:'..MidiOutput_string)
			
			table.insert(WARNINGS_TABLE,'\n MIDI OUTPUT NOT CONNECTED!'
			..'\n    REAPER track index:'..i..', Live Track Id=\"'..TRACK_ID_TABLE[i]..'\", thisREAPERtrack_name:'..thisREAPERtrack_name
			..'\n    MidiOutput_string:'..MidiOutput_string)		
		
		end--if string.match(MidiOutput
		
		
		if showRoutingMessage == true
		then
			ShowConsoleMsg_and_AddtoLog('\n         Track '..(i+1)..' "'..thisREAPERtrack_name
			..'" (Live Id:'..TRACK_ID_TABLE[i]
			..') sends MIDI to track '..(trackToSendMIDITo_index+1)..': "'..trackToSendMIDITo_name
			..'" (LiveId: '..MidiOutput_Id
			..') Live send mode:'..MidiOutput_SENDMODE_name..', REAPER I_SENDMODE:'..MidiOutput_SENDMODE
			)
		end
		
	
	end--for i=1,#TRACK_ROUTINGS_TABLE,1

end--function applyTrackRouting








--******************************************************************************************************
-- applySendsToReturns
-- NOTE: done this way (AFTER ALL TRACKS ADDED, DATA PASSED IN GLOBAL TABLES) to minimize risk of errors
-- there might be a cleverer way, but this was done on principle of "if it works, that's enough"
--*******************************************************************************************************

--[[ 
TRACK_RETURNS_ID_TABLE 
LEVEL 1						LEVEL 2					
[#] TABLE INDEX 1-## 		[1] REAPER track index 	number
							[2] Live Track Id		string	
--]]

function applySendsToReturns()


	ShowConsoleMsg_and_AddtoLog('\n\nApplying Sends to RETURN tracks...')
	--reaper.ShowConsoleMsg('\nTRACK_SENDS_TO_RETURNS_TABLE indices:'..#TRACK_SENDS_TO_RETURNS_TABLE)
		
	if #TRACK_SENDS_TO_RETURNS_TABLE > 0
	then

		--------------------------------------------------------
		--go through table of REAPER indices of ordinary tracks
		--------------------------------------------------------
		for i=0,#TRACK_SENDS_TO_RETURNS_TABLE,1 
		do
		
			local sourceREAPERTrack = reaper.GetTrack(0,i)
			local retval, sourceREAPERTrack_name = reaper.GetTrackName(sourceREAPERTrack,'')
		
			ThisTracksSendsTable = TRACK_SENDS_TO_RETURNS_TABLE[i] 
			
			------------------------------------------------------------------------------
			-- per each ordinary REAPER track, go through table of sends to RETURN tracks
			--------------------------------------------------------------------------------
			for j=0,#ThisTracksSendsTable,1
			do

			--[[
			LEVEL 1							LEVEL 2									LEVEL 3
			TRACK_SENDS_TO_RETURNS_TABLE	ThisTracksSendsTable	
			[#] SEND NUMBER 				[1] REAPER SOURCE track name 			string
											[2] Live_TrackSendHolderId				number (find destination REAPER track from TRACK_RETURNS_ID_TABLE by this)
											[3] Live_SendManualValue				number
											[4] Live_SendAutomationTargetId			string
											[5] passedAutomationEnvelope_XMLTable	TABLE CONTAINING AN ENVELOPE
			--]]
				-----------------------------------------------------------------------------------------------
				-- GET REAPER TRACK Index to send to, based on Live_TrackSendHolderId in TRACK_RETURNS_ID_TABLE
				-----------------------------------------------------------------------------------------------
				local destinationREAPERtrackIndex = "NO DESTINATION"
				local destinationREAPERTrack_name = "NO DESTINATION TRACK NAME"
				
				-- TRACK_RETURNS_ID_TABLE[j][2] should be the correct index
				destinationREAPERtrackIndex = TRACK_RETURNS_ID_TABLE[j][1]
				
				destinationREAPERTrack = reaper.GetTrack(0,destinationREAPERtrackIndex)
				retval, destinationREAPERTrack_name = reaper.GetTrackName(destinationREAPERTrack,'')
				
				--reaper.ShowConsoleMsg('\n        destinationREAPERtrackIndex:'..TRACK_RETURNS_ID_TABLE[j][2])
				
				--[[
				for h=0,#TRACK_RETURNS_ID_TABLE,1
				do
				--reaper.ShowConsoleMsg('\n h='..h..', Live_TrackSendHolderId:'..ThisTracksSendsTable[j][2])
					if h == ThisTracksSendsTable[j][2]
					then
						destinationREAPERtrackIndex = TRACK_RETURNS_ID_TABLE[h][2]
						destinationREAPERTrack = reaper.GetTrack(0,30)
						retval, destinationREAPERTrack_name = reaper.GetTrackName(destinationREAPERTrack,'')
						reaper.ShowConsoleMsg('\n        TRACK_RETURNS_ID_TABLE['..h..']: REAPER track index:'..TRACK_RETURNS_ID_TABLE[h][1]..', Live Id:'..TRACK_RETURNS_ID_TABLE[h][2])
						break
					end
				end
				--]]
				
				local given_AutomationEnvelope_XMLTable = ThisTracksSendsTable[j][5]
				

				-- ! ! ! -----------------------------------------------------------------------------
				-- ONLY CREATE SEND IF (VOLUME) is more than -60 DB OR if track has an envelope
				-- because all tracks in Live send to RETURNS at non-zero volume, 
				-- and it's confusing to make zero-level sends to all RETURNs into a REAPER project
				---------------------------------------------------------------------------------------
				
				if ThisTracksSendsTable[j][3] > 0.001 or #given_AutomationEnvelope_XMLTable > 1
				then
				
					local SendsRoutingMessage = '\n'
					..'    Track '..(i+1)..' "'..sourceREAPERTrack_name..'" sends audio to '
					--										..'\n      REAPER SOURCE:"'..ThisTracksSendsTable[j][1]..'"')
					..'track '..(destinationREAPERtrackIndex+1)..' RETURN:"'..destinationREAPERTrack_name..'"'
					..', Live TSH_Id:'..ThisTracksSendsTable[j][2]
					--									..', RPR tr idx:'..destinationREAPERtrackIndex --internal index, not needed for user information
					..'  Vol ManVal:'..ThisTracksSendsTable[j][3]
					..', AuTargId:'..ThisTracksSendsTable[j][4]
					..', Indices in Env.TABLE:'..#given_AutomationEnvelope_XMLTable
					
					ShowConsoleMsg_and_AddtoLog(SendsRoutingMessage)
					--]]	
					
					--[[
					-- CHECK NUMBER OF EXISTING RECEIVES - not necessary as reaper.CreateTrackSend creates new send
					local number_of_existing_sends = reaper.GetTrackNumSends(
																			sourceREAPERTrack,  -- MediaTrack tr
																			0					-- <0 = receives, 0=sends, >0 hardware outputs 
																			)
					--]]


					local newSendIndex = reaper.CreateTrackSend(sourceREAPERTrack,destinationREAPERTrack)
				
					reaper.SetTrackSendInfo_Value(
								sourceREAPERTrack,			-- MediaTrack tr; THIS REAPER TRACK!
								0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
								newSendIndex,				-- send index (integer)
								'I_SENDMODE',				-- parameter name (string)
								0							-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
								)
								
					reaper.SetTrackSendInfo_Value(
								sourceREAPERTrack,						-- MediaTrack tr; THIS REAPER TRACK!
								0,										-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
								newSendIndex,							-- send index (integer)
								'D_VOL',								-- parameter name (string)
								tonumber(ThisTracksSendsTable[j][3])	-- new value (number) 
								)
							
		
					---------------------------------------------------------------------------------------
					-- CHECK FOR ENVELOPES (indices in given_AutomationEnvelope_XMLTable) and create if any
					---------------------------------------------------------------------------------------
					
					if  #given_AutomationEnvelope_XMLTable > 1
					then
						ShowConsoleMsg_and_AddtoLog('\n\n NOTE:  Track '..(i+1)..' "'..sourceREAPERTrack_name..'" has a Send envelope; import is possible but NOT IMPLEMENTED YET! ')
						--[[
						NOTE: Send envelopes are actually contained in RECEIVING (destination) TRACK's chunk data
						<AUXVOLENV
						--]]
						
						-- GET TRACK CHUNK OF destinationREAPERTrack with each line as TABLE
						
						-- get line that has 'AUXRECV '..destinationREAPERtrackIndex, save its index
						
						-- make TrackStateChunk_UPPER_TABLE  from upper portion of state chunk, up until line after AUXRECV
						
						-- make TrackStateChunk_LOWER_TABLE of lower portion of state chunk, up until line after AUXRECV
						
						-- form the <AUXVOLENV start chunk
						local AuxVolEnvChunk_Start =  "    <AUXVOLENV"
													.."\n      ACT 1 -1"
													.."\n      VIS 1 1 1"
													.."\n      LANEHEIGHT 0 0"
													.."\n      ARM 1"
													.."\n      DEFSHAPE 0 -1 -1"
													.."\n      VOLTYPE 1"
						
						-- form the envelope points list from Live XML
						-- local AuxVolEnvChunk_PointList
						-- for each point in LIve XML,
						--local currentPoint = "\n      PT "..pointTime.." "..pointValue.." 0"
						--AuxVolEnvChunk_PointList=AuxVolEnvChunk_PointList..currentPoint
						
						local AuxVolEnvChunk_End = "\n    >"	
						

						--form the new track chunk:
							
							-- TrackStateChunk_UPPER_stringChunk = make string from TrackStateChunk_UPPER_TABLE
							-- TrackStateChunk_LOWER_stringChunk = make string from TrackStateChunk_UPPER_TABLE
							
							--[[ 
							newTrackStateChunk = TrackStateChunk_UPPER_stringChunk
							..AuxVolEnvChunk_Start
							..AuxVolEnvChunk_PointList
							..AuxVolEnvChunk_End
							..TrackStateChunk_LOWER_stringChunk
							--]]
							
							
						-- SET TRACK CHUNK OF destinationREAPERTrack with each line as TABLE
							
					end--if  #given_AutomationEnvelope_XMLTable > 1
					
						
						
				end--if ThisTracksSendsTable[j][3] > 0.001
				
			end--for j=1,#ThisTracksSendsTable,1  --]]
			
		end--for i=0,#TRACK_SENDS_TO_RETURNS_TABLE,1
		 
	elseif #TRACK_SENDS_TO_RETURNS_TABLE < 1
	then
		ShowConsoleMsg_and_AddtoLog('\nNo RETURN tracks found (TRACK_SENDS_TO_RETURNS_TABLE indices:'..#TRACK_SENDS_TO_RETURNS_TABLE..')')
		
	end--if #TRACK_SENDS_TO_RETURNS_TABLE > 0

end--function applySendsToReturns








--*********************************************************************************

-- useDataFrom_PluginFloatParameter_XMLTable 
-- SEARCH FOR PLUGIN ENVELOPES from received <AutomationEnvelope tags

--*********************************************************************************

function useDataFrom_PluginFloatParameter_XMLTable(
										given_FXPluginIndex,
										given_PluginFloatParameterXMLTable,
										given_RPRtrack,
										given_AutomationEnvelopesXMLTable
										)
										
	---------------------------------------------------------------------------
	-- search for <ParameterId Value="#" /> and <AutomationTarget Id="#####">
	---------------------------------------------------------------------------
	
	local Live_PluginParameterIdValue = ''
	local Live_AutomationTarget_Id = ''
	
	for o=1,#given_PluginFloatParameterXMLTable,1
	do
		if string.match(given_PluginFloatParameterXMLTable[o],'<ParameterId Value="')
		then
			Live_PluginParameterIdValue = getValueFrom_SingleLineXMLTag(given_PluginFloatParameterXMLTable,o,'<ParameterId Value="','" />')			
			--reaper.ShowConsoleMsg("\n                Live_PluginParameterIdValue:"..Live_PluginParameterIdValue)
		end--if
	
		if string.match(given_PluginFloatParameterXMLTable[o],'<AutomationTarget Id="')
		then
			Live_AutomationTarget_Id = getValueFrom_SingleLineXMLTag(given_PluginFloatParameterXMLTable,o,'<AutomationTarget Id="','">')	
			--reaper.ShowConsoleMsg("\n                Live_AutomationTarget_Id:"..Live_AutomationTarget_Id)
			
			break--enclosing for loop
			
		end--if
		
	end--for


	local retval, current_PluginParameterName = reaper.TrackFX_GetParamName(
																		given_RPRtrack, 
																		given_FXPluginIndex, 
																		Live_PluginParameterIdValue, 
																		64)	


	------------------------------------------------------------------------------------------
	--- GO THROUGH given_AutomationEnvelopesXMLTable to find envelopes for this parameter
	------------------------------------------------------------------------------------------

	for i=1,#given_AutomationEnvelopesXMLTable,1
	do
		if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
		then
			local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AutomationEnvelopesXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AutomationEnvelope>'				-- given_EndTag
																		)
																		
			--reaper.ShowConsoleMsg("\n                AutomationEnvelope_XMLTable indices:"..#AutomationEnvelope_XMLTable)
		
			local currentEnvelope_PointeeId
			
			
			for j=1,#AutomationEnvelope_XMLTable,1
			do
				
				if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
				then
					currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
					--reaper.ShowConsoleMsg("\n                currentEnvelope_PointeeId:"..currentEnvelope_PointeeId)
					
					break--enclosing for loop
					
				end--if
				
			end--for j=1,#AutomationEnvelope_XMLTable,1
				
			if currentEnvelope_PointeeId == Live_AutomationTarget_Id
			then
				
				--================================================================
				-- ADD PLUGIN ENVELOPE
				--================================================================

				local newEnvelope = reaper.GetFXEnvelope(
												given_RPRtrack,
												given_FXPluginIndex,
												Live_PluginParameterIdValue,
												true
												)

				ShowConsoleMsg_and_AddtoLog('\n                ENVELOPE added for plugin '
				..given_FXPluginIndex..'\'s parameter '..Live_PluginParameterIdValue..': "'..current_PluginParameterName..'"'
				--..'" newEnvelope:'..tostring(newEnvelope)
				)
				
				------------------------------------------------------------------
				-- GET AND INSERT ENVELOPE POINTS
				------------------------------------------------------------------
				
				local previousEventTime = 0
				
				for k=1,#AutomationEnvelope_XMLTable,1
				do
					
					if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					then
						
						local current_FloatEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Event_Time = string.sub(
						current_FloatEventTag_contents,
						string.find(current_FloatEventTag_contents,'Time="')+6,
						string.find(current_FloatEventTag_contents,'" Value=')-1
						)
						if Event_Time == '-63072000' then Event_Time = 0 end
						Event_Time = tonumber(Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Event_Time == previousEventTime then Event_Time = (Event_Time * 1.0000001) end 
						--reaper.ShowConsoleMsg("\n    Event_Time:"..Event_Time)
						
						-- add point in REAPER only if time value is positive
						if Event_Time > -1
						then
						
							EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Event_Time)
						
							local Event_Value = string.sub(
							current_FloatEventTag_contents,
							string.find(current_FloatEventTag_contents,'Value="')+7,
							string.find(current_FloatEventTag_contents,'" />')-1
							)
							
							-- if  CurveControl found, cut it off
							if string.match(Event_Value,'CurveControl')
							then
								Event_Value = string.sub(Event_Value,
														1,
														string.find(Event_Value,'" CurveControl')-1
														)
							end
							
							Event_Value = tonumber(Event_Value)
							
							--reaper.ShowConsoleMsg("\n    Event_Value:"..Event_Value)
							
							
							--================================================================
							-- ADD PLUGIN ENVELOPE POINT
							--================================================================
							
							reaper.InsertEnvelopePoint(
												newEnvelope,
												EventTime_inReaperTime,
												Event_Value,
												0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn
												
							previousEventTime = Event_Time
						
						end--if Event_Time > -1
			
			
					end--if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					
				
				end--for k=1,#AutomationEnvelope_XMLTable,1


				------------------------------------------------------------------
				-- SORT ENVELOPE POINTS (AFTER ALL POINTS ARE ADDED)
				------------------------------------------------------------------

				reaper.Envelope_SortPoints(newEnvelope)
			


			end -- if currentEnvelope_PointeeId == Live_AutomationTarget_Id

		end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
	
	end--for i=1,#given_AutomationEnvelopesXMLTable,1

end--function useDataFrom_PluginFloatParameter_XMLTable 







--*********************************************************************************
-- checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum
--*********************************************************************************

function checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
														given_RPRtrack,
														given_FXPluginIndex,
														given_AutomationTargetId,
														given_PluginParameterNumber,
														given_AutomationEnvelopesXMLTable,
														ENVELOPE_POINT_UNIT
														)
																			
	--reaper.ShowConsoleMsg('\n STARTING function checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum')
	--reaper.ShowConsoleMsg('\n Indices in given_AutomationEnvelopesXMLTable:'..#given_AutomationEnvelopesXMLTable)

	local retval, current_PluginParameterName = reaper.TrackFX_GetParamName(
																		given_RPRtrack, 
																		given_FXPluginIndex, 
																		given_PluginParameterNumber, 
																		64)



	------------------------------------------------------------------------------------------
	--- GO THROUGH given_AutomationEnvelopesXMLTable to find envelopes for this parameter
	------------------------------------------------------------------------------------------

	for i=1,#given_AutomationEnvelopesXMLTable,1
	do
		if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
		then
			local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AutomationEnvelopesXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AutomationEnvelope>'				-- given_EndTag
																		)	
			--reaper.ShowConsoleMsg("\n                AutomationEnvelope_XMLTable indices:"..#AutomationEnvelope_XMLTable)
		
			local currentEnvelope_PointeeId
			
			for j=1,#AutomationEnvelope_XMLTable,1
			do
				if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
				then
					currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
					--reaper.ShowConsoleMsg("\n                currentEnvelope_PointeeId:"..currentEnvelope_PointeeId)
					break
				end--if
			end--for j=1,#AutomationEnvelope_XMLTable,1
				
			if currentEnvelope_PointeeId == given_AutomationTargetId
			then 

				--================================================================
				-- ADD PLUGIN ENVELOPE
				--================================================================

				local newEnvelope = reaper.GetFXEnvelope(
												given_RPRtrack,
												given_FXPluginIndex,
												given_PluginParameterNumber,
												true
												)
				
				ShowConsoleMsg_and_AddtoLog('\n                ENVELOPE added for plugin '
				..given_FXPluginIndex..'\'s parameter '..given_PluginParameterNumber..': "'..current_PluginParameterName..'"'
				--..'" newEnvelope:'..tostring(newEnvelope)
				)
				
				local newEnvelopeScalingMode = reaper.GetEnvelopeScalingMode(newEnvelope)
				--reaper.ShowConsoleMsg("\n        newEnvelopeScalingMode:"..tostring(newEnvelopeScalingMode))
				
				------------------------------------------------------------------
				-- GET AND INSERT ENVELOPE POINTS
				------------------------------------------------------------------
				
				local previousEventTime = 0
				
				for k=1,#AutomationEnvelope_XMLTable,1
				do
					----------------------------------
					-- FIND AND SET EnumEvents
					----------------------------------
				
					if string.match(AutomationEnvelope_XMLTable[k],'<EnumEvent Id="')
					then
						local current_EnumEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Enum_Event_Time = string.sub(
						current_EnumEventTag_contents,
						string.find(current_EnumEventTag_contents,'Time="')+6,
						string.find(current_EnumEventTag_contents,'" Value=')-1
						)
						if Enum_Event_Time == '-63072000' then Enum_Event_Time = 0 end
						Enum_Event_Time = tonumber(Enum_Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Enum_Event_Time == previousEventTime then Enum_Event_Time = (Enum_Event_Time * 1.001) end 

						
						if Enum_Event_Time > -1 -- add point in REAPER only if time value is positive
						then
							Enum_EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Enum_Event_Time)
							
							local Enum_Event_Value = string.sub(
							current_EnumEventTag_contents,
							string.find(current_EnumEventTag_contents,'Value="')+7,
							string.find(current_EnumEventTag_contents,'" />')-1
							)
						
							if ENVELOPE_POINT_UNIT == 'Compressor2_to_ReaComp-Pre-comp'
							then
							
								if 		Enum_Event_Value == '0' then Enum_Event_Value = 0 
								elseif 	Enum_Event_Value == '1'	then Enum_Event_Value = 1
								elseif 	Enum_Event_Value == '2'	then Enum_Event_Value = 10 
								end
								
								Enum_Event_Value = (Enum_Event_Value/250)
							end
							
							--================================================================
							-- EnumEvent ADD PLUGIN ENVELOPE POINT
							--================================================================
							
							reaper.InsertEnvelopePoint(
												newEnvelope,					-- TrackEnvelope envelope
												Enum_EventTime_inReaperTime,	-- number time
												Enum_Event_Value,				-- number value
												1,								-- integer shape, 0=lin, 1=sqr, 2=Slow St/end, 3=Fast st, 4=Fast end, 5=Bezier
												0,								-- number tension
												0,								-- boolean selected
												1								-- optional boolean noSortIn
												)
												
							previousEventTime = Enum_Event_Time
						
						end--if Enum_Event_Time > -1
					
					end--if string.match(AutomationEnvelope_XMLTable[k],'<EnumEvent Id="')
				
				
				
					----------------------------------
					-- FIND AND SET BoolEvents
					----------------------------------
					if string.match(AutomationEnvelope_XMLTable[k],'<BoolEvent Id="')
					then
						local current_BoolEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Bool_Event_Time = string.sub(
						current_BoolEventTag_contents,
						string.find(current_BoolEventTag_contents,'Time="')+6,
						string.find(current_BoolEventTag_contents,'" Value=')-1
						)
						if Bool_Event_Time == '-63072000' then Bool_Event_Time = 0 end
						Bool_Event_Time = tonumber(Bool_Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Bool_Event_Time == previousEventTime then Bool_Event_Time = (Bool_Event_Time * 1.001) end 

						
						if Bool_Event_Time > -1 -- add point in REAPER only if time value is positive
						then
							Bool_EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Bool_Event_Time)
							
							local Bool_Event_Value = string.sub(
							current_BoolEventTag_contents,
							string.find(current_BoolEventTag_contents,'Value="')+7,
							string.find(current_BoolEventTag_contents,'" />')-1
							)
						
							-- FOR ON/OFF (true/false) VALUES
							if Bool_Event_Value == 'true' 	then Bool_Event_Value = 1 end
							if Bool_Event_Value == 'false' 	then Bool_Event_Value = 0 end
							--reaper.ShowConsoleMsg("\n    Bool_Event_Value:"..Bool_Event_Value)
							
							
							if ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-Delay Sync Type' --boolean
							or ENVELOPE_POINT_UNIT == 'SimpleDelay_to_Spaceship Delay-Delay Sync Type' --boolean
							then 
								if Bool_Event_Value == 'true' 
								then Bool_Event_Value = 0.83333331346512 
								else Bool_Event_Value = 0.16666667163372 
								end
							end

							
							--================================================================
							-- BoolEvent ADD PLUGIN ENVELOPE POINT
							--================================================================
							
							reaper.InsertEnvelopePoint(
												newEnvelope,					-- TrackEnvelope envelope
												Bool_EventTime_inReaperTime,	-- number time
												Bool_Event_Value,				-- number value
												1,								-- integer shape, 0=lin, 1=sqr, 2=Slow St/end, 3=Fast st, 4=Fast end, 5=Bezier
												0,								-- number tension
												0,								-- boolean selected
												1								-- optional boolean noSortIn
												)
												
							previousEventTime = Bool_Event_Time
						
						end--if Bool_Event_Time > -1
					
					end--if string.match(AutomationEnvelope_XMLTable[k],'<BoolEvent Id="')
				
				
					----------------------------------
					-- FIND AND SET FloatEvents
					----------------------------------
					
					if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					then
						local current_FloatEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Event_Time = string.sub(
						current_FloatEventTag_contents,
						string.find(current_FloatEventTag_contents,'Time="')+6,
						string.find(current_FloatEventTag_contents,'" Value=')-1
						)
						if Event_Time == '-63072000' then Event_Time = 0 end
						Event_Time = tonumber(Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Event_Time == previousEventTime then Event_Time = (Event_Time * 1.0000001) end 
						--reaper.ShowConsoleMsg("\n    Event_Time:"..Event_Time)
						
						-- add point in REAPER only if time value is positive
						if Event_Time > -1 
						then
						
							EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Event_Time)
						
							local Event_Value = string.sub(
							current_FloatEventTag_contents,
							string.find(current_FloatEventTag_contents,'Value="')+7,
							string.find(current_FloatEventTag_contents,'" />')-1
							)
							
							-- IF  CurveControl found, CUT IT OFF
							if string.match(Event_Value,'CurveControl')
							then
								Event_Value = string.sub(Event_Value,
														1,
														string.find(Event_Value,'" CurveControl')-1
														)
							end
							--reaper.ShowConsoleMsg("\n    Event_Value:"..Event_Value)
							
							
							-- IMPORTANT! ---------------------
							Event_Value = tonumber(Event_Value)
							
							
							--------------------------------------
							------- FOR Eq8_to_ReaEQ
							--------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'ReaEQ-Freq'
							then
								-- FORMULA: CLOSE, BUT SIGNIFICANTLY INACCURATE IN SOME CASES (writer could not figure out direct formula)
								-- Event_Value =  ( (math.log(Event_Value)*0.1620)+((1/math.log(Event_Value))*0.70)+(Event_Value*0.0000018) )-0.745
								
								-- GOOD ENOUGH ACCURACY VIA CONVERSION FUNCTION
								Event_Value = convertHzTo_ReaEQNormalizedFreq(
																		given_RPRtrack,				-- given_Track,
																		given_FXPluginIndex, 			-- given_ReaEQFXindex,
																		given_PluginParameterNumber,	-- given_FreqParamNumber,
																		Event_Value						-- given_Hz
																		)
							end--if
							

							if ENVELOPE_POINT_UNIT == 'ReaEQ-Gain'
							then
								Event_Value = dBtoAmplitude(Event_Value)
								Event_Value = (Event_Value*0.25)
							end
							
							
							if ENVELOPE_POINT_UNIT == 'Eq8_to_ReaEQ-Q'
							then
--- EQ Q WORK IN PROGRESS !!!!!!!!!!							
								-- Eq8: 	min: 0, 	def 0.71, 	max: 18
								-- ReaEQ:	"min": 4, 	def 2.0, 	"max":0.1
								
								-- set to ensure than inversing never goes above 10
								if Event_Value < 0.1 then Event_Value = 0.1 end
								
								-- scale to 0-4:  value/4.5
								--Event_Value = Event_Value/4.5
								
									Event_Value = 1/Event_Value -- 1/18 = 0.05;  1/0.71 = 1.4; 1/0.1 = 10
									Event_Value = (Event_Value*0.15)
							end
							
						
						
							--------------------------------------
							------- FOR AutoFilter_to_ReaEQ
							--------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'AutoFilter_to_ReaEQ-Freq'
							then
			
								-- POTENTIAL (without Hz conversion)
								-- Event_Value = ( (Event_Value/120.12)-((1/Event_Value)*2)  )-0.155  --math.log(Event_Value)/10
								
								-- CLOSE ENOUGH, with Hz conversion
								Event_Value = ((Event_Value^(Event_Value*0.0102))*23.7)-20 
								
								Event_Value = convertHzTo_ReaEQNormalizedFreq(
										given_RPRtrack,				-- given_Track,
										given_FXPluginIndex, 			-- given_ReaEQFXindex,
										given_PluginParameterNumber,	-- given_FreqParamNumber,
										Event_Value						-- given_Hz
										)
								
							end--if
							
							
							if ENVELOPE_POINT_UNIT == 'AutoFilter_to_ReaEQ-Q'
							then
								--reaper.ShowConsoleMsg("\nENVELOPE_POINT_UNIT == 'ReaEQ-Q'")
								--reaper.ShowConsoleMsg("\nAutoFilter_to_ReaEQ-Q Event_Value from Live:"..Event_Value)
								
								
								-- set to ensure than inverting never goes above 10
								if Event_Value < 0.1 then Event_Value = 0.1 end
								
								Event_Value = 1/Event_Value
								--Event_Value = Event_Value/2.5 -- 10-0.8 to 4-0.32
								Event_Value = Event_Value/3.9	-- 10-0.8 to 2.56-0.205
								
								--reaper.ShowConsoleMsg("\nAutoFilter_to_ReaEQ-Q Event_Values after inv and div:"..Event_Value)

								if Event_Value < 0.07 then Event_Value = 0.07 end -- 0.07 = max. 24db res
								if Event_Value > 3.99 then Event_Value = 3.99 end

								-- normalize (/4)
								Event_Value = Event_Value/4
								
							end
							
							
							if ENVELOPE_POINT_UNIT == 'AutoFilter_to_ReaEQ-Q-Legacy'
							then
								--reaper.ShowConsoleMsg("\nENVELOPE_POINT_UNIT == 'ReaEQ-Q-Legacy'")
								--reaper.ShowConsoleMsg("\nAutoFilter_to_ReaEQ-Q-Legacy Event_Value from Live:"..Event_Value)
								
								-- set to ensure than inverting never goes above 10
								if Event_Value < 0.1 then Event_Value = 0.1 end
								
								Event_Value = 1/Event_Value			-- 5-0.3
								--Event_Value = Event_Value*1.36	-- 5-0.3 to 6.8-0.4
								Event_Value = Event_Value *1.2		-- 5-0.3 to 6.0-0.36
								
								--reaper.ShowConsoleMsg("\nAutoFilter_to_ReaEQ-Q-Legacy Event_Values after inv and div:"..Event_Value)

								if Event_Value < 0.07 then Event_Value = 0.07 end -- 0.07 = max. 24db res
								if Event_Value > 3.99 then Event_Value = 3.99 end

								-- normalize (/4)
								Event_Value = Event_Value/4
							end	
							
							
							
							--------------------------------------
							------- FOR Compressor2_to_ReaComp
							--------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'Compressor2_to_ReaComp-Attack'
							then Event_Value = (Event_Value/500) end
							
							
							if ENVELOPE_POINT_UNIT == 'Compressor2_to_ReaComp-Release'
							then Event_Value = (Event_Value/5000) end
							
							
							if ENVELOPE_POINT_UNIT == 'Compressor2_to_ReaComp-Ratio'
							then Event_Value = ((-(1-Event_Value))/100)  end
							
							
							if ENVELOPE_POINT_UNIT == 'Compressor2_to_ReaComp-Knee'
							then Event_Value = (Event_Value/24) end
							
							
	
							--------------------------------------
							------- FOR Gate_to_ReaGate
							--------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'Gate_to_ReaGate-Attack'
							then Event_Value = (Event_Value/500) end
							
							
							if ENVELOPE_POINT_UNIT == 'Gate_to_ReaGate-Hold'
							then
								if Hold_ManVal > 1000 
								then 
									Hold_ManVal = 1000 
								end
								Event_Value = (Event_Value/1000) 
							end
							
							
							if ENVELOPE_POINT_UNIT == 'Gate_to_ReaGate-Release'
							then Event_Value = (Event_Value/5000) end
							
							
							
							-- NOTE: 	Live Gate Floor = 	-inf							0dB; 
							-- 			ReaGate Hystrsis = 	-inf	 	-48dB 				0dB 		+12dB; 
							-- displayed in FX window		0.0, 		0.0020000000949949	0.5			1.9905358552933
							-- tested to work				(dB to amplitude)				1
							
							if ENVELOPE_POINT_UNIT == 'Gate_to_ReaGate-Hystrsis'
							then
							
							--reaper.ShowConsoleMsg("\n\n inputted Live Gate Event_Value:"..Event_Value)

								if 		Event_Value == 0 						then Event_Value = 1
								--elseif 	Event_Value < 0 and Event_Value > -48 	then Event_Value = (dBtoAmplitude(Event_Value) * 1)	
								--elseif 	Event_Value < -48 						then Event_Value = 0.0
								else Event_Value = (dBtoAmplitude(Event_Value) * 1)
								end
								
							--reaper.ShowConsoleMsg("\n Translated ReaGate Event_Value:"..Event_Value)
							
							--[[
							local retval, GateFloorValueFormattedByReaScript = reaper.TrackFX_FormatParamValue(	given_RPRtrack,
																												given_FXPluginIndex,
																												given_PluginParameterNumber,
																												Event_Value,
																												64)

							local retval, GateFloorValueFormattedNormalizedByReaScript = reaper.TrackFX_FormatParamValue(	given_RPRtrack,
																															given_FXPluginIndex,
																															given_PluginParameterNumber,
																															Event_Value,
																															64)																													
							
							
							reaper.ShowConsoleMsg("\n GateFloorValueFormattedByReaScript:"..GateFloorValueFormattedByReaScript)
							reaper.ShowConsoleMsg("\n GateFloorValueFormattedNormalizedByReaScript:"..GateFloorValueFormattedNormalizedByReaScript)
							--]]
							
							end
							
							
							-----------------------------------------------------
							------- FOR PingPongDelay_to_Spaceship Delay
							-----------------------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-Delay Ms'
							or ENVELOPE_POINT_UNIT == 'SimpleDelay_to_Spaceship Delay-Delay Ms'
							then 

								Event_Value = convertMillisecondsTo_SpaceshipNormalizedMs(	given_RPRtrack,					-- given_Track,
																							given_FXPluginIndex, 			-- given_FXindex,
																							given_PluginParameterNumber,	-- given_ParamNumber,
																							Event_Value						-- given_Ms
																							)
							end
							
							-- FOR PLACEHOLDER ONLY
							if ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-MidFreq'
							then
									Event_Value = Event_Value / 100000
							end
							
							-- FOR PLACEHOLDER ONLY
							if ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-BandWidth'
							then
							 		Event_Value = Event_Value / 10
							end
							
							
							-----------------------------------------------------
							------- FOR Reverb_to_Dragonfly Reverb
							-----------------------------------------------------
							
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-PreDelay'
							then
								Event_Value = Event_Value / 100 -- to get normalized value (0.x to 100 = 0.00x to 1)
								if Event_Value > 1 then Event_Value = 1 end
							end
							
							
							
														
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-Decay'
							then
								Event_Value = Event_Value / 10000 -- to get normalized value (0.x to 10 = 0.0x to 1)
								if Event_Value > 1 then Event_Value = 1 end
							end
							
							
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-Width'
							then
								Event_Value = Event_Value * 0.833 --0-120 to "0-100" conversion
								if Event_Value < 50 then Event_Value = 50 end  -- leaves 50 to 100
								Event_Value = Event_Value / 100 -- 50-100 to 0.5 - 1.0 conversion
								Event_Value = Event_Value - 0.5  -- 0.5 - 1.0 to 0.0-0.5 conversion
							end

							
		
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-High Cross'
							then
								if Event_Value < 1000 then Event_Value = 1000 end --conform to Dragonfly
								Event_Value = Event_Value - 1000
								Event_Value = math.floor((Event_Value * 0.000066667)*10000)/10000
							end
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-High Mult'
							then
								Event_Value = Event_Value -0.2
							end
							
									
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-Low Cross'
							then
								if Event_Value < 200 then Event_Value = 200 end --conform to Dragonfly
								if Event_Value > 1200 then Event_Value = 1200 end --conform to Dragonfly
								Event_Value = Event_Value - 200
								Event_Value = math.floor((Event_Value * 0.001)*10000)/10000
							end
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-Low Mult'
							then
								-- INACCURATE BUT OK
								if Event_Value < 0.5 then Event_Value = 0.5 end
								Event_Value = Event_Value * 0.25
							end
							

							
							if ENVELOPE_POINT_UNIT == 'Reverb_to_Dragonfly Reverb-Size'
							then
								-- INACCURATE
								if Event_Value > 100 then Event_Value = 100 end
								Event_Value = Event_Value / 100 --turns 100 into 1
							end



							--================================================================
							-- FloatEvent ADD PLUGIN ENVELOPE POINT
							--================================================================
							
							--reaper.ShowConsoleMsg("\n Final Event_Value:"..Event_Value)
							
							reaper.InsertEnvelopePoint(
												newEnvelope,				-- TrackEnvelope envelope
												EventTime_inReaperTime,		-- number time
												Event_Value,				-- number value
												0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn
												
							previousEventTime = EventTime
						
						end--if Event_Time > -1
			
					end--if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					
				end--for k=1,#AutomationEnvelope_XMLTable,1


				------------------------------------------------------------------
				-- SORT ENVELOPE POINTS (AFTER ALL POINTS ARE ADDED)
				------------------------------------------------------------------

				reaper.Envelope_SortPoints(newEnvelope)
			
			end -- if currentEnvelope_PointeeId == given_AutomationTargetId

		end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
	
	end--for i=1,#given_AutomationEnvelopesXMLTable,1

end--function checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum









--*********************************************************************************
-- useDataFrom_LiveDevice_Eq8_XMLTable2
--*********************************************************************************

function useDataFrom_LiveDevice_Eq8_XMLTable2(
								given_PluginDeviceXMLTable,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)
								
	----------------------------------------------------------------------------------------
	-- GET GlobalGain_ManualValue -- NOTE: ReaEQ DOES NOT SUPPORT Global Gain AUTOMATION!
	----------------------------------------------------------------------------------------
	local GlobalGain_ManualValue = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<GlobalGain>')
	GlobalGain_ManualValue = tonumber(GlobalGain_ManualValue)
	
	
	--------------------------------------------------------
	-- GET Bands XML as tables into EQ8_BANDS_TABLE
	--------------------------------------------------------
	
	local EQ8_BANDS_TABLE = {}
	
	for i=1,#given_PluginDeviceXMLTable,1
	do
		-- GET BANDS
		if string.match(given_PluginDeviceXMLTable[i],'<Bands.')
		then
			local thisBandTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																	given_PluginDeviceXMLTable,	-- given_Table,
																	i,							-- given_StartTagIndex
																	'</Bands'					-- given_EndTag
																	)
			table.insert(EQ8_BANDS_TABLE,thisBandTable)
		end--if
	end--for  i
	
	--reaper.ShowConsoleMsg("\n    EQ8_BANDS_TABLE indices:"..#EQ8_BANDS_TABLE)
	


	-------------------------------------------------------------
	-- GET EACH BANDS' SETTINGS FROM Eq8
	-------------------------------------------------------------
	
	local EQ8_TABLE = {}
	
	--[[------------------------------------------------
	
	-- EQ8_TABLE[0]		[0] band IsOn
						[1] bandtype
						[2] freq
						[3] freq Automation Target Id
						[4] gain
						[5] gain Automation Target Id
						[6] Q
						[7] Q Automation Target Id
						
	--]]--------------------------------------------------
	
	-- FOR EACH EQ BAND
	for j=1,#EQ8_BANDS_TABLE,1
	do
		local thisBandXMLTable = EQ8_BANDS_TABLE[j]
		--reaper.ShowConsoleMsg("\n\n   Band "..j)
		--reaper.ShowConsoleMsg(", indices in thisBandXMLTable:"..#thisBandXMLTable)
		
		local THISBANDS_TABLE = {}
		
		-- GET DATA FROM THIS BAND's TABLE
		for k=1,#thisBandXMLTable,1
		do
			-- GET <ParameterA> table
			if string.match(thisBandXMLTable[k],'<ParameterA>')
			then
				local ParameterA_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag( thisBandXMLTable,	-- given_Table,
																						k,					-- given_StartTagIndex
																						'</ParameterA>'		-- given_EndTag
																						)
				--reaper.ShowConsoleMsg("\n        indices in ParameterA_XMLTable:"..#ParameterA_XMLTable)
				
				-- initialize THISBANDS_TABLE for this band
				THISBANDS_TABLE = {}
				
				THISBANDS_TABLE[0] = get_ManVal_AuTargId_from_ContTagInXMLTable(ParameterA_XMLTable,'<IsOn>')
																								
				THISBANDS_TABLE[1] = get_ManVal_AuTargId_from_ContTagInXMLTable(ParameterA_XMLTable,'<Mode>')
																								
				THISBANDS_TABLE[2],THISBANDS_TABLE[3] = get_ManVal_AuTargId_from_ContTagInXMLTable(ParameterA_XMLTable,'<Freq>')
																											
				THISBANDS_TABLE[4],THISBANDS_TABLE[5] = get_ManVal_AuTargId_from_ContTagInXMLTable(ParameterA_XMLTable,'<Gain>')

				THISBANDS_TABLE[6],THISBANDS_TABLE[7] = get_ManVal_AuTargId_from_ContTagInXMLTable(ParameterA_XMLTable,'<Q>')																												
				
				--for check=0,#THISBANDS_TABLE,1 do reaper.ShowConsoleMsg('\n    THISBANDS_TABLE['..check..']:'..THISBANDS_TABLE[check]) end
				
	
			end--if string.match(thisBandXMLTable[k],'<ParameterA>')
				

			--[[
			--------------------------------------------------------------------------------
			-- GET <ParameterB> table		- NOT IMPLEMENTED, not possible in ReaEQ
			--------------------------------------------------------------------------------
			if string.match(thisBandXMLTable[k],'<ParameterB>')
			then
				local ParameterB_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			thisBandXMLTable,	-- given_Table,
																			k,					-- given_StartTagIndex
																			'</ParameterB>'		-- given_EndTag
																			)
				--reaper.ShowConsoleMsg("\n        indices in ParameterB_XMLTable:"..#ParameterB_XMLTable)
			end--if string.match(thisBandXMLTable[k],'<ParameterB>')
			--]]
		
		end--for k=1,#thisBandXMLTable,1
		
		
		EQ8_TABLE[j-1] = THISBANDS_TABLE
		
	end--for j=1,#EQ8_BANDS_TABLE,1
	
	
	--[[ CHECK #EQ8_TABLE
	reaper.ShowConsoleMsg('\n Indices in EQ8_TABLE:'..#EQ8_TABLE)
	for i=0,#EQ8_TABLE,1
	do
		reaper.ShowConsoleMsg('\nEQ8_TABLE['..i..']:') 
		for j=0,#EQ8_TABLE[i],1 
		do 
			reaper.ShowConsoleMsg('\n    ['..j..']:'..EQ8_TABLE[i][j]) 
		end
	end --]]



	--==========================================================================================================
	-- ADD ReaEQ
	--==========================================================================================================

	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaEQ as substitute for EQ8")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'ReaEQ (Cockos)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == ""
	then
		ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin")
	end--if
	
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')
		
		


	--[[----------------------------------------
		--     SET GlobalGain_ManualValue
		--------------------------------------------
		
		NOTE: must be converted for ReaEQ
		Eq8: 	-12 	to +12 dB 
		ReaEQ: 	-inf 	to +12 dB
		
		OBSERVED ReaEQ RANGE: 1.0 - 0.484 = 0.516

		0.484	= 	-12.0 dB
		0.5 	=	-11 dB
		0.7 	=	-0.8 dB
		0.717 	=  	0 dB
		0.8	 	=	+3.8 dB
		0.9 	=	+8.0 dB
		1.0 	=	+12 dB
		
		map 0 to 24 to 0.516 to 1.0
		linear: 0.516 / 24 = 0.0215
		0.717 - 0.484 = 0.233, / 12 = 0.19416
		1-0.717 = 0.283, / 12 = 0.235
		
		-------------------------------------------]]

		-- INACCURATE BUT CLOSE ENOUGH CONVERSION
		if GlobalGain_ManualValue < 0 -- -12 to -0.0001
		then
			GlobalGain_ManualValue = GlobalGain_ManualValue+12
			GlobalGain_ManualValue = (0.484+(0.019*GlobalGain_ManualValue))
		elseif GlobalGain_ManualValue == 0
		then
			GlobalGain_ManualValue = 0.717
		elseif GlobalGain_ManualValue > 0 -- 0.0001 to 12
		then
			GlobalGain_ManualValue = (0.717+(0.0235*GlobalGain_ManualValue))
		end

		reaper.TrackFX_SetEQParam(	given_RPRtrack,				-- MediaTrack track, 
									currentFXindex,				-- integer fxidx, 
									-1,							-- integer bandtype, -1 for master gain
									-1,							-- integer bandidx,  (ignored for master gain)
									-1,							-- integer paramtype, (ignored for master gain) 
									GlobalGain_ManualValue,		-- number val, 
									0							-- boolean isnorm
									)

						
		-- ! ! ! ----------------------------------------------------
		-- NOTE: ReaEQ DOES NOT SUPPORT Global Gain AUTOMATION!
		-------------------------------------------------------------



		-------------------------------------------------------------
		-- RESET ReaEQ, SET ALL BANDS TO SAME BANDTYPE 
		-------------------------------------------------------------
		
		-- ! ! !--------------------------------------------------------------------------------
		
		-- NOTE: NamConPar_ResetBandType and SetEQPar_ResetBandType must refer to same band type
		
		local NamConPar_ResetBandType = 8 -- this is for ReaEQ_Bands_ResetAndEnsureAtLeast8
		local SetEQPar_ResetBandType = 2 --  this is for ReaEQ_Set_FreqGainQ 
		
		------------------------------------------------------------------------------------------
		
		function ReaEQ_Bands_ResetAndEnsureAtLeast8(given_Track,given_FXindex,given_RESETBANDTYPE)

			local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_Track,given_FXindex)
			local numberOfTabs = math.floor(currentFX_NumberOfParameters/3)
			
			
			--[[-- BAND TYPES DEPENDING ON ACCESS METHOD -------
			
			TrackFX_SetNamedConfigParm 		TrackFX_SetEQParam		
			'BANDTYPE#'						bandidx
							
					0			Low Shelf		1				
					1			High Shelf		4
					2			Band(alt2)
					3			Low Pass		5
					4			High Pass		0
					5			All Pass
					6			Notch			3
					7			Band Pass		
					8			Band			2
					9			Band(alt)					
			-------------------------------------------------]]
			
				
			-- FOR EACH TAB, DISABLE AND RESET BAND TYPE
			for i=0,numberOfTabs,1
			do
				reaper.TrackFX_SetNamedConfigParm(given_Track,given_FXindex,'BANDTYPE'..i,given_RESETBANDTYPE)						
				reaper.TrackFX_SetNamedConfigParm(given_Track,given_FXindex,'BANDENABLED'..i,0)							
			end

			-- INCREASE BAND NUMBER,IF NEEDED, VIA INCREASING BANDTYPE INDEX 
			-- (yep, it's silly compared to addressing by tab, but at the time of writing this scripter no other way that would work)
			if numberOfTabs < 8
			then
				-- ADD BANDS AND RESET ALL FREQUENCIES
				for j=0,7,1
				do		
					reaper.TrackFX_SetEQParam( 	given_Track,			-- MediaTrack track, 
												given_FXindex,			-- integer fxidx, 
												given_RESETBANDTYPE,	-- integer bandtype,
												j,						-- integer bandidx,
												0,						-- integer paramtype, -- Paramtype (ignored for master gain):  0=freq, 1=gain, 2=Q.
												100*(j+1),				-- number val, 
												0						-- boolean isnorm
												)
				end
				
				-- SET ALL DISABLED
				for k=0,7,1
				do			
					reaper.TrackFX_SetNamedConfigParm(given_Track,given_FXindex,'BANDENABLED'..k,0)							
				end
			end
			
		end-- function ReaEQ_Bands_ResetAndEnsureAtLeast8
		
		-------------------------------------------------------------
		-- ReaEQ_Bands_ResetAndEnsureAtLeast8
		-------------------------------------------------------------
		ReaEQ_Bands_ResetAndEnsureAtLeast8(given_RPRtrack,currentFXindex,NamConPar_ResetBandType)
		
		
		
		-----------------------------------------------------------------------------------
		-- ReaEQ_Set_FreqGainQ -- NOTE: targets by bandidx, all bands MUST be of same type
		-----------------------------------------------------------------------------------
		
		function ReaEQ_Set_FreqGainQ(
									given_EQ8_TABLE,
									given_Track,
									given_EQindex,
									given_RESETBANDTYPE
									)
		
			--reaper.ShowConsoleMsg('\n Indices in given_EQ8_TABLE:'..#given_EQ8_TABLE)
			
			for i=0,#given_EQ8_TABLE,1
			do
				--reaper.ShowConsoleMsg('\n    given_EQ8_TABLE['..i..'][0]:'..given_EQ8_TABLE[i][0]) 
			
				if given_EQ8_TABLE[i][0] == 'true'
				then
				
				-- ! ! ! --------------------------------------------------
				-- NOTE: targets by bandidx, all bands MUST be of same type 
				-----------------------------------------------------------
				
				--------------------------------------------------------						
				-- SET BAND ENABLED
				--------------------------------------------------------																				
				reaper.TrackFX_SetEQBandEnabled(	given_Track,			-- MediaTrack track, 
													given_EQindex,			-- integer fxidx, 
													given_RESETBANDTYPE,	-- integer bandtype, 
													i,						-- integer bandidx, 
													1						-- boolean enable
													)


				--------------------------------------------------------						
				-- SET FREQUENCY
				--------------------------------------------------------

				local 	Freq = given_EQ8_TABLE[i][2]
						Freq = (math.floor(tonumber(Freq)*10)/10) -- round to 1 decimals
				
				reaper.TrackFX_SetEQParam(	given_Track,			-- MediaTrack track, 
											given_EQindex,			-- integer fxidx, 
											given_RESETBANDTYPE,	-- integer bandtype, SET ACCORDING TO Live type
											i,						-- integer bandidx,
											0,						-- integer paramtype, 0=freq, 1=gain, 2=Q (ignored for master gain) 
											Freq,					-- number val, 
											0						-- boolean isnorm
											)
						
						
				--------------------------------------------------------
				-- SET GAIN
				--------------------------------------------------------	

				local 	Gain = given_EQ8_TABLE[i][4]
						Gain = (math.floor(tonumber(Gain)*10)/10) -- round to 1 decimals
						Gain = dBtoAmplitude(Gain) --NOTE: must be converted to amplitude for ReaEQ
			
				reaper.TrackFX_SetEQParam(	given_Track,			-- MediaTrack track, 
											given_EQindex,			-- integer fxidx, 
											given_RESETBANDTYPE,	-- integer bandtype, SET ACCORDING TO Live type
											i,						-- integer bandidx,
											1,						-- integer paramtype, 0=freq, 1=gain, 2=Q (ignored for master gain) 
											Gain,					-- number val, 
											0						-- boolean isnorm
											)			


				--------------------------------------------------------
--WORK IN PROGRESS				-- SET Q
				--------------------------------------------------------
				
				local 	Q = given_EQ8_TABLE[i][6]
						Q = (1/tonumber(Q)) --convert to ReaEQ format; 
						Q = (math.floor(Q*100)/100) -- round to 2 decimals, helps matching params later
						
						if Q > 3.9 then Q = 3.9 end
						if Q < 0.1 then Q = 0.1 end

				reaper.TrackFX_SetEQParam(	given_Track,			-- MediaTrack track, 
											given_EQindex,			-- integer fxidx, 
											given_RESETBANDTYPE,	-- integer bandtype, SET ACCORDING TO Live type
											i,						-- integer bandidx,
											2,						-- integer paramtype, 0=freq, 1=gain, 2=Q (ignored for master gain) 
											Q,						-- number val, 
											0						-- boolean isnorm
											)
				
				end--if
				
			end --]]
						
		end--function set_ReaEQBand_FromEq8Band
		
		-------------------------------------------------------------
		-- ReaEQ_Set_FreqGainQ
		-------------------------------------------------------------
		ReaEQ_Set_FreqGainQ(EQ8_TABLE,given_RPRtrack,currentFXindex,SetEQPar_ResetBandType)
		
		
		
		-------------------------------------------------------------
		-- SET BAND TYPES AND AUTOMATION ENVELOPES
		-------------------------------------------------------------
		
		function ReaEQ_Set_BandTypesAndEnvelopes(
												given_EQ8_TABLE,
												given_Track,
												given_EQindex,
												given_AutomationEnvelopesXMLTable
												)
			
			--[[-- BAND TYPE CONVERSION TABLE ---------------------------------------------
			
			Live Eq8				TrackFX_SetNamedConfigParm 		TrackFX_SetEQParam			
			<Mode>					'BANDTYPE#'						bandtype
			
			0: 48dB/oct Low Cut			4 High Pass		  	    		High pass (extreme setting or 4 bands overlayed)
			1: 12dB/oct Low Cut		4 High Pass						0 High pass
			2: Low Shelf			0 Low Shelf						1 Low Shelf
			3: Band (Bell Curve)	2 Band(alt2)						2 Band (NOTE: different Q)
			4: Notch				6 Notch							3 Notch
			5: High Shelf			1 High Shelf					4 High Shelf
			6: High Cut 12dB/Oct	3 Low Pass						5 Low Pass
			7: High Cut 48dB/Oct		3 Low Pass			  	    	Low Pass (extreme setting or 4 bands overlayed)
			
			---------------------------------------------------------------------------]]
			
			local function convertBandtype_fromEq8_toReaEQNamConPar(given_Mode)
			
				--reaper.ShowConsoleMsg('\n    given_Mode:'..given_Mode)
				
				local BandType_NamConPar = 2
			
				if     given_Mode == 0 	--[[ 48dB/oct Low Cut  --]] then BandType_NamConPar = 4 -- High Pass
				elseif given_Mode == 1 	--[[ 12dB/oct Low Cut  --]] then BandType_NamConPar = 4 -- High Pass
				elseif given_Mode == 2 	--[[ Low Shelf         --]] then BandType_NamConPar = 0 -- Low Shelf
				elseif given_Mode == 3	--[[ Band (Bell Curve) --]] then BandType_NamConPar = 2 -- Band(alt2)
				elseif given_Mode == 4 	--[[ Notch             --]] then BandType_NamConPar = 6 -- Notch
				elseif given_Mode == 5 	--[[ High Shelf        --]] then BandType_NamConPar = 1 -- High Shelf
				elseif given_Mode == 6 	--[[ High Cut 12dB/Oct --]] then BandType_NamConPar = 3 -- Low Pass
				elseif given_Mode == 7 	--[[ High Cut 48dB/Oct --]] then BandType_NamConPar = 3 -- Low Pass
				end--if
				
				--reaper.ShowConsoleMsg('\n    BandType_NamConPar:'..BandType_NamConPar)
				
				return BandType_NamConPar
			
			end-- function convertBandtype_fromEq8_toReaEQNamConPar
		
			-------------------------------------------------
			-- SET BAND TYPES
			-------------------------------------------------
			for i=0,#given_EQ8_TABLE,1
			do
				local convertedBandType = convertBandtype_fromEq8_toReaEQNamConPar(tonumber(given_EQ8_TABLE[i][1]))
				
				-- FOR EACH TAB, SET BAND TYPE
				reaper.TrackFX_SetNamedConfigParm(given_Track,given_EQindex,'BANDTYPE'..i,convertedBandType)
				
			end
			
			
			-------------------------------------------------
			-- SET AUTOMATION ENVELOPES
			-------------------------------------------------

			local increasingParamNumber = 0
			
			for j=0,#given_EQ8_TABLE,1
			do
				--given_EQ8_TABLE[j][3] --Automation Target Id for Freq
				checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
																	given_Track,						-- given_RPRtrack,
																	given_EQindex,						-- given_FXPluginIndex,
																	given_EQ8_TABLE[j][3],				-- given_AutomationTargetId,
																	increasingParamNumber,				-- given_PluginParameterNumber,
																	given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
																	'ReaEQ-Freq'						-- ENVELOPE_POINT_UNIT
																	)
				increasingParamNumber = increasingParamNumber+1
				
				
				--given_EQ8_TABLE[j][5] --Automation Target Id for Gain
				checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
																	given_Track,						-- given_RPRtrack,
																	given_EQindex,						-- given_FXPluginIndex,
																	given_EQ8_TABLE[j][5],				-- given_AutomationTargetId,
																	increasingParamNumber,				-- given_PluginParameterNumber,
																	given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
																	'ReaEQ-Gain'						-- ENVELOPE_POINT_UNIT
																	)
				increasingParamNumber = increasingParamNumber+1
				
				--given_EQ8_TABLE[j][7] --Automation Target Id for Q
				checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
																	given_Track,						-- given_RPRtrack,
																	given_EQindex,						-- given_FXPluginIndex,
																	given_EQ8_TABLE[j][7],				-- given_AutomationTargetId,
																	increasingParamNumber,				-- given_PluginParameterNumber,
																	given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
																	'Eq8_to_ReaEQ-Q'							-- ENVELOPE_POINT_UNIT
																	)
				increasingParamNumber = increasingParamNumber+1
				
			end--for j=0,#given_EQ8_TABLE,1
		

		end--ReaEQ_Set_BandTypesAndEnvelopes
		
		-------------------------------------------------------------
		-- ReaEQ_Set_BandTypesAndEnvelopes
		-------------------------------------------------------------
		ReaEQ_Set_BandTypesAndEnvelopes(EQ8_TABLE,given_RPRtrack,currentFXindex,given_AutomationEnvelopesXMLTable)



		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
		
		
	end--if pluginNameForChecking ~= ""

end--function useDataFrom_LiveDevice_Eq8_XMLTable2








--****************************************************
-- useDataFrom_LiveDevice_AutoFilter_XMLTable
--****************************************************
function useDataFrom_LiveDevice_AutoFilter_XMLTable(
											given_PluginDeviceXMLTable,
											given_RPRtrack,
											given_AutomationEnvelopesXMLTable
											)
											
	--reaper.ShowConsoleMsg('\n\nSTARTING function useDataFrom_LiveDevice_AutoFilter_XMLTable')
	
	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')
	
	
	-- GET <LegacyMode Value="false" />
	local LegacyModeValue = searchTableFor_FIRST_SingleLineXMLTagValue(given_PluginDeviceXMLTable,'<LegacyMode Value="','" />')
	
	
	-- GET <LegacyFilterType> 0=Lowpass, 1=Highpass, 2=Bandpass, 3=Notch,
	local LegacyFilterType_ManVal, LegacyFilterType_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LegacyFilterType>')


	--[[ GET <FilterType>  0=Lowpass, 1=Highpass, 2=Bandpass, 3=Notch, 4=Morph 	--]]
	local FilterType_ManVal, FilterType_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<FilterType>')
		if FilterType_ManVal == '4' then
		table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
		..' AutoFilter to ReaEQ: <FilterType> is of type "Morph"; not supported in ReaEQ, Bandpass used instead; "Morph" automation NOT imported') end


	-- GET <CircuitLpHp></CircuitLpHp> -- 0: Clean, 1: OSR, 2: MS2, 3:SMP, 4: PRD
	local CircuitLpHp_ManVal, CircuitLpHp_AuTargId  = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<CircuitLpHp>')
		if CircuitLpHp_ManVal ~= '0' then
		table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
		..' AutoFilter to ReaEQ: <CircuitLpHp> is not of type "Clean"; extra types not supported in ReaEQ; "Drive" automation NOT imported') end
	
	
	-- GET <CircuitBpNoMo></CircuitBpNoMo> --  0: Clean, 1: OSR
	local CircuitBpNoMo_ManVal, CircuitBpNoMo_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<CircuitBpNoMo>')
		if CircuitBpNoMo_ManVal ~= '0' then
		table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
		..' AutoFilter to ReaEQ: <CircuitBpNoMo> is not of type "Clean"; extra circuit types not supported in ReaEQ') end
	
	
	--[[  GET <Slope>	true = 24dB, false = 12dB 	--]]
	local Slope_ManVal, Slope_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Slope>')


	--[[  GET <Cutoff></Cutoff>: 	26.0 Hz - 19.9 kHz --]]
	local Cutoff_ManVal, Cutoff_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Cutoff>')
	

	-- GET <CutoffLimit Value="135" />
	local CutoffLimitValue = searchTableFor_FIRST_SingleLineXMLTagValue(given_PluginDeviceXMLTable,'<CutoffLimit Value="','" />')
	
	
	-- GET <LegacyQ></LegacyQ>: <Manual Value="0" /><AutomationTarget Id="#####">
	local LegacyQ_ManVal, LegacyQ_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LegacyQ>')


	--[[  GET <Resonance></Resonance>: 0 - 1.25 	--]]
	local Resonance_ManVal,Resonance_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Resonance>')


	-- GET <Morph></Morph>: <Manual Value="0" /><AutomationTarget Id="#####">
	-- GET <Drive></Drive>: <Manual Value="0" /><AutomationTarget Id="#####">
	

	-- GET <ModHub></ModHub> (Envelope) : <Manual Value="0" /><AutomationTarget Id="#####">
	local ModHub_ManVal, ModHub_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ModHub>')
		if ModHub_ManVal ~= '0' then
		table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
		..' AutoFilter to ReaEQ: <ModHub> (Envelope) is not 0; envelope following not supported in ReaEQ; ENVELOPE FOLLOWER DATA DISCARDED') end
	
	-- GET <Attack></Attack>: <Manual Value="0" /><AutomationTarget Id="#####">
	-- GET <Release></Release>: <Manual Value="0" /><AutomationTarget Id="#####">
	
	
	-- GET <LfoAmount></LfoAmount>: <Manual Value="0" /><AutomationTarget Id="#####">
	local LfoAmount_ManVal, LfoAmount_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LfoAmount>')
		if LfoAmount_ManVal ~= '0' then
		table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
		..' AutoFilter to ReaEQ: <LfoAmount> is not 0; LFO not supported in ReaEQ; LFO DATA DISCARDED') end
	
	-- GET <Lfo></Lfo> NOTE: contains a set of own values
	
	-- GET <SideChain></SideChain> NOTE: contains a set of own values
	local SideChain_XMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(given_PluginDeviceXMLTable,'<SideChain>','</SideChain>')
		-- GET <SideChain><OnOff>
		local SideChain_OnOff_ManVal = get_ManVal_AuTargId_from_ContTagInXMLTable(SideChain_XMLTable,'<OnOff>')
			if SideChain_OnOff_ManVal == 'true' then
			table.insert(WARNINGS_TABLE,'Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex
			..' AutoFilter to ReaEQ: Sidechain is on; sidechain is not supported in ReaEQ; SIDECHAIN DATA DISCARDED') end
	
	
	--[[
	reaper.ShowConsoleMsg('\n LegacyModeValue:'..LegacyModeValue)
	reaper.ShowConsoleMsg('\n LegacyFilterType_ManVal:'..LegacyFilterType_ManVal)
	reaper.ShowConsoleMsg('  LegacyFilterType_AuTargId:'..LegacyFilterType_AuTargId)
	reaper.ShowConsoleMsg('\n FilterType_ManVal:'..FilterType_ManVal)
	reaper.ShowConsoleMsg('  FilterType_AuTargId:'..FilterType_AuTargId)
	reaper.ShowConsoleMsg('\n Slope_ManVal:'..Slope_ManVal)
	reaper.ShowConsoleMsg('  Slope_AuTargId:'..Slope_AuTargId)
	reaper.ShowConsoleMsg('\n Cutoff_ManVal:'..Cutoff_ManVal)
	reaper.ShowConsoleMsg('  Cutoff_AuTargId:'..Cutoff_AuTargId)
	reaper.ShowConsoleMsg('\n CutoffLimitValue:'..CutoffLimitValue)
	reaper.ShowConsoleMsg('\n LegacyQ_ManVal:'..LegacyQ_ManVal)
	reaper.ShowConsoleMsg('  LegacyQ_AuTargId:'..LegacyQ_AuTargId)
	reaper.ShowConsoleMsg('\n Resonance_ManVal:'..Resonance_ManVal)
	reaper.ShowConsoleMsg('  Resonance_AuTargId:'..Resonance_AuTargId)
	reaper.ShowConsoleMsg('\n LfoAmount_ManVal:'..LfoAmount_ManVal)
	reaper.ShowConsoleMsg('\n SideChain_OnOff_ManVal:'..SideChain_OnOff_ManVal)
	--]]
	

	-----------------------------------------------
	-- ACCOUNT FOR AutoFilter LEGACY values
	-----------------------------------------------

--- NOTE - WORK IN PROGRESS!
	
	local Final_FilterType_ManVal = 	FilterType_ManVal
	local Final_FilterType_AuTargId = 	FilterType_AuTargId
	
	local Final_Q_ManVal = 		Resonance_ManVal
	local Final_Q_AuTargId = 	Resonance_AuTargId
	
	if LegacyModeValue == 'true'
	then
		Final_FilterType_ManVal = 	LegacyFilterType_ManVal
		Final_FilterType_AuTargId = LegacyFilterType_AuTargId
	
		Final_Q_ManVal = 	LegacyQ_ManVal
		Final_Q_AuTargId = 	LegacyQ_AuTargId
	end
	
	
	--==========================================================================================================
	-- ADD ReaEQ
	--==========================================================================================================

	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaEQ as substitute for AutoFilter - mainly to get its Freq and Q envelopes")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'ReaEQ (Cockos)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found



	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == ""
	then
		ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin")
	end--if
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')
		
		
		--------------------------------------------------------
		-- SET PLUGIN NAME  !!! NOT IMPLEMENTED, NEEDS TO BE DONE VIA CHUNK PARSING
		--------------------------------------------------------
		--[[
	
		
		local this_FX_GUID = reaper.TrackFX_GetFXGUID(given_RPRtrack,currentFXindex)
		
		local thisPluginName = ''
		
			if     FilterType_ManVal == 0 	 then thisPluginName = 'Low Pass (ReaEQ)'
			elseif FilterType_ManVal == 1 	 then thisPluginName = 'High Pass(ReaEQ)'
			elseif FilterType_ManVal == 2 	 then thisPluginName = 'Band Pass (not exact)(ReaEQ)'
			elseif FilterType_ManVal == 3	 then thisPluginName = 'Notch(ReaEQ)'
			elseif FilterType_ManVal == 4 	 then thisPluginName = 'Band Pass (substitute for Morph)(ReaEQ)'
			end--if
				
		local retval, thisTrackStateChunk = reaper.GetTrackStateChunk(	given_RPRtrack, --MediaTrack track,
																		'', 			--string str,
																		false)   		-- boolean isundo
																		
		-- make table from chunk
		
		-- find line that contains GUID, save table position
		
		-- go back in table until found line that contains '<VST "VST: ReaEQ (Cockos)"'
		
		-- replace the table index contents '<VST "VST: ReaEQ (Cockos)"' with '<VST "'..thisPluginName..'"'
		
		-- reassemble chunk from table
		
		-- set chunk

		--]]

		
		-- ! ! !--------------------------------------------------------------------------------
		
		-- NOTE: NamConPar_ResetBandType and SetEQPar_ResetBandType must refer to same band type
		
		local NamConPar_ResetBandType = 8 -- this is for ReaEQ_Bands_ResetAndEnsureAtLeast8
		local SetEQPar_ResetBandType = 2 --  this is for ReaEQ_Set_FreqGainQ 
		
		------------------------------------------------------------------------------------------
			

		-------------------------------------------------------------------
		-- RESET ReaEQ (all types same (RESETTYPE), all bands disabled)
		-------------------------------------------------------------------
		
		function ReaEQ_Bands_SetExistingToSameType_and_Disable(given_Track,given_FXindex,given_RESETBANDTYPE)

			local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_Track,given_FXindex)
			local numberOfTabs = math.floor(currentFX_NumberOfParameters/3)
			
			-- FOR EACH TAB, DISABLE AND RESET BAND TYPE
			for i=0,numberOfTabs,1
			do
				reaper.TrackFX_SetNamedConfigParm(given_Track,given_FXindex,'BANDTYPE'..i,given_RESETBANDTYPE)						
				reaper.TrackFX_SetNamedConfigParm(given_Track,given_FXindex,'BANDENABLED'..i,0)							
			end
			
		end-- function ReaEQ_Bands_SetExistingToSameType_and_Disable
		
		
		ReaEQ_Bands_SetExistingToSameType_and_Disable(given_RPRtrack,currentFXindex,NamConPar_ResetBandType)



	
		-- ! ! ! --------------------------------------------------
		-- NOTE: targets by bandidx, all bands MUST be of same type 
		-----------------------------------------------------------
		
		--------------------------------------------------------						
		-- SET BAND ENABLED
		--------------------------------------------------------																				
		reaper.TrackFX_SetEQBandEnabled(	given_RPRtrack,		-- MediaTrack track, 
											currentFXindex,	-- integer fxidx, 
											SetEQPar_ResetBandType,	-- integer bandtype, 
											0,						-- integer bandidx, 
											1						-- boolean enable
											)


		--------------------------------------------------------						
		-- SET FREQUENCY
		--------------------------------------------------------
		
		
-- NOTE: NEEDS CONVERSION!
		

		local 	Freq = ((Cutoff_ManVal^(Cutoff_ManVal*0.0102))*23.7)-20 -- CLOSE ENOUGH	
				Freq = (math.floor(tonumber(Freq)*10)/10) -- round to 1 decimals
		
		reaper.TrackFX_SetEQParam(	given_RPRtrack,		-- MediaTrack track, 
									currentFXindex,	-- integer fxidx, 
									SetEQPar_ResetBandType,	-- integer bandtype,
									0,						-- integer bandidx,
									0,						-- integer paramtype, 0=freq, 1=gain, 2=Q (ignored for master gain) 
									Freq,					-- number val, 
									0						-- boolean isnorm
									)


		--------------------------------------------------------
-- WORK IN PROGRESS		-- SET Q
		--------------------------------------------------------
		
		local 	Q =  tonumber(Final_Q_ManVal)
		
		if LegacyModeValue == 'false' -- Q value = 0 to 125% in UI, 0.0 to 1.25 in XML
		then
		
		
		--------------------------------------------------------------
		--					LESS RESONANCE				MORE RESONANCE
		--
		-- ReaEQ:			"min": 4, 	 def 	2.0, 	"max":	0.1
		-- AutoFilter: 	 	 min: 0, 	"def": 	0.14 	 max: 	1.25
				
		-- 1/ AutoFilter	(1/0.1) 10							0.8
		-- scaling by /2.5		4								0.32
		--------------------------------------------------------------
								
		--									0dB res peak	+6dB res peak		+12dB res peak		+18dB res peak		+24dB res peak	
								
		-- AutoFilter @ 12dB: 				0.14 			0.48				0.65				0.81				1.00
		-- AutoFilter @ 24dB: 				0.18 			0.41				0.63				0.81				1.00
		-- AutoFilter apprx. 	0.1			0.15 			0.45				0.65				0.8					1.00			1.25
								
		-- 1/AutoFilter apprx. 	10			6.66			2.22				1.53				1.25				1				0.8				
							
		--1/AF apprx /3.9		2.56		1.7				0.57				0.39				0.32				0.26			0.205			
								
		-- ReaEQ							1.7				0.68				0.34				0.16				0.07
								
		---------------------------------------------------------------------------------------------------------------------------------------
		
					-- set to ensure than inversing never goes above 10
					if Q < 0.1 then Q = 0.1 end
					
					Q = 1/Q			-- 10-0.8
					--Q = Q/2.5 	-- 10-0.8 to 4-0.32
					Q = Q/3.9		-- 10-0.8 to 2.56-0.205
					
					Q = (math.floor(Q*100)/100) -- round to 2 decimals, helps matching params later
					
					if Q > 3.99 then Q = 3.99 end
					if Q < 0.07 then Q = 0.07 end -- now pay attention ;) 0.07 = 24dB resonance peak 

		end --if LegacyModeValue == 'false'
		
		
		if LegacyModeValue == 'true' -- Q value = 0.20 to 3.0 in UI
		then
		
		---------------------------------------------------------------------------
		--							LESS RESONANCE					MORE RESONANCE
		--
		-- ReaEQ:					"min": 4, 	 	def 	2.0, 	"max":	0.1
		-- AutoFilter Legacy Mode: 	 min: 0.20, 	"def": 	0.8 	 max: 	3.0
				
		-- 1/ AutoFilter Legacy Mode	5				1.25				0.3
		
		----------------------------------------------------------------------------
								
		--											0dB res peak	+6dB res peak		+12dB res peak		
								
		-- AutoFilter Legacy Mode: 			0.2		0.8 			1.75				3.0								
								
		-- 1/AutoFilter Legacy Mode: 		5		1.25			0.57				0.3		
							
		--1/AF apprx Legacy Mode * 1.36		6.8		1.7				0.77				0.4
		
		--1/AF apprx Legacy Mode * 1.2		6		1.5				0.684				0.36
								
		-- ReaEQ									1.7				0.68				0.34			
								
		-------------------------------------------------------------------------------------------
		
		
					-- set to ensure than inversing never goes above 10
					if Q < 0.1 then Q = 0.1 end
					
					Q = 1/Q			-- 5-0.3
					--Q = Q *1.36	-- 5-0.3 to 6.8-0.4
					Q = Q *1.2		-- 5-0.3 to 6.0-0.36
					
					Q = (math.floor(Q*100)/100) -- round to 2 decimals, helps matching params later
					
					if Q > 3.99 then Q = 3.99 end
					if Q < 0.07 then Q = 0.07 end -- 0.07 = 24dB resonance peak 

		end -- if LegacyModeValue == 'true'
		

		reaper.TrackFX_SetEQParam(	given_RPRtrack,		-- MediaTrack track, 
									currentFXindex,	-- integer fxidx, 
									SetEQPar_ResetBandType,	-- integer bandtype, 
									0,						-- integer bandidx,
									2,						-- integer paramtype, 0=freq, 1=gain, 2=Q (ignored for master gain) 
									Q,						-- number val, 
									0						-- boolean isnorm
									)
				

		
		--[[-- BAND TYPE CONVERSION TABLE ---------------------------------------------
		
		Live AutoFilter		TrackFX_SetNamedConfigParm 		TrackFX_SetEQParam			
		<FilterType>		'BANDTYPE#'						bandtype
		
		0: Lowpass			3 -- Low Pass		  	    	5 Low Pass
		1: Highpass			4 -- High Pass					0 High pass
		2: Bandpass			7 -- Band Pass	(not exact)			
		3: Notch			6 -- Notch						3 Notch
		4: Morph			7 -- Band Pass (substitute )						

		---------------------------------------------------------------------------]]
		
		local function convertBandtype_fromAutoFilter_toReaEQNamConPar(given_FilterType)
		
			--reaper.ShowConsoleMsg('\n    given_Mode:'..given_Mode)
			
			local BandType_NamConPar = 2
		
			if     given_FilterType == 0 	--[[ Lowpass  	--]] then BandType_NamConPar = 3 -- Low Pass
			elseif given_FilterType == 1 	--[[ Highpass  	--]] then BandType_NamConPar = 4 -- High Pass
			elseif given_FilterType == 2 	--[[ Bandpass	--]] then BandType_NamConPar = 7 -- Band Pass (not exact)
			elseif given_FilterType == 3	--[[ Notch 		--]] then BandType_NamConPar = 6 -- Notch	
			elseif given_FilterType == 4 	--[[ Morph      --]] then BandType_NamConPar = 7 -- Band Pass (substitute )
			end--if
			
			--reaper.ShowConsoleMsg('\n    BandType_NamConPar:'..BandType_NamConPar)
			
			return BandType_NamConPar
		
		end-- function convertBandtype_fromAutoFilter_toReaEQNamConPar
	
	
	
	
		-------------------------------------------------
		-- SET BAND TYPE
		-------------------------------------------------

		local convertedBandType = convertBandtype_fromAutoFilter_toReaEQNamConPar(tonumber(Final_FilterType_ManVal))
	
		--reaper.ShowConsoleMsg('\n    Final_FilterType_ManVal:'..tonumber(Final_FilterType_ManVal))
		--reaper.ShowConsoleMsg('\n    convertedBandType:'..convertedBandType)
	
		reaper.TrackFX_SetNamedConfigParm(	given_RPRtrack,
											currentFXindex,
											'BANDTYPE'..0,
											convertedBandType )

		
		-------------------------------------------------
		-- SET AUTOMATION ENVELOPES
		-------------------------------------------------
		
			
-- NOTE - WORK IN PROGRESS!
-- check for bandtype automation, WARNING: DISCARDED if it is automated	
-- look for filter type's AutomationTargetId in given_AutomationEnvelopesXMLTable
	
	
	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
															given_RPRtrack,					-- given_RPRtrack,
															currentFXindex,					-- given_FXPluginIndex,
															Cutoff_AuTargId,					-- given_AuTargId,
															0,									-- given_PluginParameterNumber,
															given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
															'AutoFilter_to_ReaEQ-Freq'			-- ENVELOPE_POINT_UNIT
															)

		
		if LegacyModeValue == 'false' -- Q value = 0 to 125% in UI, 0.0 to 1.25 in XML
		then
			checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
																given_RPRtrack,					-- given_RPRtrack,
																currentFXindex,					-- given_FXPluginIndex,
																Final_Q_AuTargId,					-- given_AuTargId,
																2,									-- given_PluginParameterNumber,
																given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
																'AutoFilter_to_ReaEQ-Q'				-- ENVELOPE_POINT_UNIT
																)
		end
		
		
		if LegacyModeValue == 'true' -- Q value = 0.20 to 3.0 in UI
		then
			checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(
																given_RPRtrack,					-- given_RPRtrack,
																currentFXindex,					-- given_FXPluginIndex,
																Final_Q_AuTargId,					-- given_AuTargId,
																2,									-- given_PluginParameterNumber,
																given_AutomationEnvelopesXMLTable,	-- given_AutomationEnvelopesXMLTable
																'AutoFilter_to_ReaEQ-Q-Legacy'		 -- ENVELOPE_POINT_UNIT
																)
		end	
	
	

		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
	
	
	end--if pluginNameForChecking ~= ""
		
end--function useDataFrom_LiveDevice_AutoFilter_XMLTable








function addReaSynthAs_SidechainClickSignal(given_RPRtrack)	-- given_RPRtrack

	local numberOfFX_OnCurrentTrack = reaper.TrackFX_GetCount(given_RPRtrack)
	
	if numberOfFX_OnCurrentTrack == 0 --ENSURE THAT GETS ADDED AS FIRST FX
	then

		-- IF TRACK IS MUTED, UNMUTE IT
		local retval, stateChunkOfCurrentTrack =  reaper.GetTrackStateChunk(given_RPRtrack,"",false)
		-- note: in Lua, dash "-" needs to be escaped "%-1" when matching strings for replacing them
		if string.match(stateChunkOfCurrentTrack,'MUTESOLO 1 0 0')
		then
			stateChunkOfCurrentTrack=string.gsub(stateChunkOfCurrentTrack,"MUTESOLO 1 0 0","MUTESOLO 0 0 0")
			reaper.SetTrackStateChunk(given_RPRtrack,stateChunkOfCurrentTrack,false)	
		end		
		
		
		--==========================================================================================================
		-- ADD "ReaSynth (Cockos)"
		--==========================================================================================================

		ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaSynth as SIDECHAIN CLICK TRACK")
		
		reaper.TrackFX_AddByName(	given_RPRtrack, 
									'ReaSynth (Cockos)',
									false,
									-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


		--------------------------------------------------------
		-- CONTINUE ONLY IF PLUGIN LOADED
		--------------------------------------------------------
		
		local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
		if pluginNameForChecking == "" then ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin") end--if
		if pluginNameForChecking ~= ""
		then
			ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
		

			--------------------------------------------------------
			-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
			--------------------------------------------------------
			local PARNUM_PARNAME_TABLE = {}		
			local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
			for i=0,currentFX_NumberOfParameters-2,1	-- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
			do 
				local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
				PARNUM_PARNAME_TABLE[i] = PluginParameterName
			end
			--for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
		
		
			--------------------------------------------------------
			-- SET ReaSynth PARAMETERS
			--------------------------------------------------------
			
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Release'),9.7)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Square'),1.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Saw'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Triangle'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Volume'),0.49)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Decay'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Extrasin'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'sine2tun'),0.5)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Sustain'),0.0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Pulse Wi'),0.14)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'detune'),0.5)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'legacytu'),0.0)
			

			--------------------------------------------------------
			-- INCREMENT PLUGIN INDEX
			--------------------------------------------------------
		
			currentFXindex = currentFXindex+1

		end--if pluginNameForChecking ~= ""
		
	end--if numberOfFX_OnCurrentTrack == 0

end--function addReaSynthAs_SidechainClickSignal(given_RPRtrack)	-- given_RPRtrack





--*********************************************************************************
-- useDataFrom_LiveDevice_Reverb_XMLTable
--*********************************************************************************

function useDataFrom_LiveDevice_Reverb_XMLTable(
				given_PluginDeviceXMLTable,			-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)

	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')
	
	
	--==========================================================================================================
	-- ADD Dragonfly Hall Reverb
	--==========================================================================================================


	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding Dragonfly Hall Reverb as substitute for Reverb")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'Dragonfly Hall Reverb',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == "" then ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin") end--if
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
	

		--------------------------------------------------------
		-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
		--------------------------------------------------------
		
		local PARNUM_PARNAME_TABLE = {}
		local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
		for i=0,currentFX_NumberOfParameters-2,1	-- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
		do 
			local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
			PARNUM_PARNAME_TABLE[i] = PluginParameterName
		end
		--for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
		
			
		-----------------------------------------------------------------------
		-- GET Live Reverb parameters and SET Dragonfly Hall Reverb parameters
		-----------------------------------------------------------------------
		
		-- NOTE: Live <On> setting retrieved at the end of function
		
		-- SET Dragonfly Reverb Dry to zero (FX slot Dry/Wet used instead)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Dry Level '),0)
		


		local PreDelay_ManVal, PreDelay_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<PreDelay>')
		PreDelay_ManVal = (tonumber(PreDelay_ManVal) / 100) -- to get normalized value (0.x to 100 = 0.00x to 1)
		if PreDelay_ManVal > 1 then PreDelay_ManVal = 1 end
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Predelay'),PreDelay_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,PreDelay_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Predelay'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-PreDelay' )										-- ENVELOPE_POINT_UNIT --]]
		
		-- <BandHighOn>
		-- <BandLowOn>
		-- <BandFreq>
		-- <BandWidth>
		
		
		-- <SpinOn>
		
		-- <EarlyReflectModFreq>
		-- <EarlyReflectModDepth>
		
		
		
		-- <DiffuseDelay> Live: Shape
		
		--[[ FROM LIVE MANUAL: "Shape control ”sculpts” the prominence of the early reflections, as well as their overlap with the diffused sound. 
		With small values, the reflections decay more gradually and the diffused
		sound occurs sooner, leading to a larger overlap between these components. 
		With large values, the reflections decay more rapidly and the diffused onset occurs later." --]]
				
		
		
		--- DEFAULTS FOR Dragonfly Hall reverb (inaccurate, here just for sake of having some default values)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Cut'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Cut'),1)
		
		
		-- <ShelfHighOn>
		local ShelfHighOn_ManVal, ShelfHighOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfHighOn>')
		
		-- <ShelfHiFreq> - Live: 20 to 16000; Dragonfly "High Cross" 1000-16000; normalized 0.0 to 1.0
		local ShelfHiFreq_ManVal, ShelfHiFreq_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfHiFreq>')
		ShelfHiFreq_ManVal = tonumber(ShelfHiFreq_ManVal)
		
		if ShelfHiFreq_ManVal < 1000 then ShelfHiFreq_ManVal = 1000 end --conform to Dragonfly
		ShelfHiFreq_ManVal = ShelfHiFreq_ManVal - 1000
		ShelfHiFreq_ManVal = math.floor((ShelfHiFreq_ManVal * 0.000066667)*10000)/10000
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Cross'),ShelfHiFreq_ManVal)	

		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,ShelfHiFreq_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Cross'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-High Cross' )									-- ENVELOPE_POINT_UNIT --]]


		-- <ShelfHiGain> - Live: 0.2 to 1; Dragonfly "High Mult" 0.2-1.2; normalized 0 to 1; 1x = 0.825
		-- rough conversion: Live value -0.2
		local ShelfHiGain_ManVal, ShelfHiGain_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfHiGain>')
		ShelfHiGain_ManVal = (tonumber(ShelfHiGain_ManVal))-0.2
	
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Mult'),ShelfHiGain_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,ShelfHiGain_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Mult'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-High Mult' )									-- ENVELOPE_POINT_UNIT --]]
								
		-- RESET High Cross and Gain if it was OFF
		if ShelfHighOn_ManVal == 'false' 
		then 
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Cross'),1)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'High Mult'),0.825)	
		end
		
		
		
		
		-- <ShelfLowOn>	
		local ShelfLowOn_ManVal, ShelfLowOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfLowOn>')
		
		-- <ShelfLoFreq> Live: 20Hz to 15000Hz; Dragonfly: 200Hz to 1200Hz
		local ShelfLoFreq_ManVal, ShelfLoFreq_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfLoFreq>')
		ShelfLoFreq_ManVal = tonumber(ShelfLoFreq_ManVal)
		
		if ShelfLoFreq_ManVal < 200 then ShelfLoFreq_ManVal = 200 end --conform to Dragonfly
		if ShelfLoFreq_ManVal > 1200 then ShelfLoFreq_ManVal = 1200 end --conform to Dragonfly
		ShelfLoFreq_ManVal = ShelfLoFreq_ManVal - 200
		ShelfLoFreq_ManVal = math.floor((ShelfLoFreq_ManVal * 0.001)*10000)/10000
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Cross'),ShelfLoFreq_ManVal)	

		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,ShelfLoFreq_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Cross'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Low Cross' )									-- ENVELOPE_POINT_UNIT --]]	
		
		
		-- <ShelfLoGain> Live: 0.2 to 1.0 (8x 0.1 steps) Dragonfly: 0.5 to 2.5; Dragonfly normalized: 0=0.5x, 0.25 = 1.0x
		--- conversion: conform Live to 0.5-1.0 (5x 0.1 steps); Dragonfly: 5x 0.05 steps from 0.0 to 0.25
		local ShelfLoGain_ManVal, ShelfLoGain_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ShelfLoGain>')
		ShelfLoGain_ManVal = tonumber(ShelfLoGain_ManVal)
		-- INACCURATE BUT OK
		if ShelfLoGain_ManVal < 0.5 then ShelfLoGain_ManVal = 0.5 end
		ShelfLoGain_ManVal = ShelfLoGain_ManVal * 0.25
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Mult'),ShelfLoGain_ManVal)

		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,ShelfLoGain_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Mult'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Low Mult' )								
		
		-- RESET Low Cross and Gain if it was OFF
		if ShelfLowOn_ManVal == 'false' 
		then 
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Cross'),0)
			reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Low Mult'),0.25)	
		end
		
		
		
		-- <ChorusOn>
		-- <SizeModFreq>
		-- <SizeModDepth>



		local DecayTime_ManVal, DecayTime_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<DecayTime>')
		DecayTime_ManVal = (tonumber(DecayTime_ManVal) / 10000) -- NOTE: Live value in Ms -- NOT PRECISE BUT CLOSE ENOUGH
		if DecayTime_ManVal > 1 then DecayTime_ManVal = 1 end
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Decay'),DecayTime_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,DecayTime_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Decay'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Decay' )										-- ENVELOPE_POINT_UNIT --]]
							
		
		
		
		-- <AllPassGain> Live: Density; values in XML 0.0 to 0.96 
		-- Dragonfly Hall: "Diffuse"; values normalized 0.0 to 1.0
		local AllPassGain_ManVal, AllPassGain_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<AllPassGain>')
		AllPassGain_ManVal = tonumber(AllPassGain_ManVal)
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Diffuse'),AllPassGain_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,AllPassGain_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Diffuse'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Diffuse' )										-- ENVELOPE_POINT_UNIT --]]
		
		
		
		-- <AllPassSize> Related to Diffuse; DISCARDED
		
		-- <FreezeOn>		DISCARDED
		-- <FlatOn>			DISCARDED
		-- <CutOn>			DISCARDED
		
		
		
		
		
		-- <RoomSize>	
		--[[

		Room size translation @ density / diffuse 100%
		
		Live: 0.22 to 500
		Dragonfly Hall: 10m to 60m; 
		Dragonfly Hall normalized: 0 = 10; 1=60, each step 0.02
		
		Live @ High			Dragonfly Hall
		
		0.22				0.10m
		20					20m 
		60					60m
		80					60m? 
		100					60m?
		
		Decided: Live 0-100 range gets converted to Dragonfly 10-60 (0.0-1.0) range
		crude conversion:Dragonfly range = Live range / 100
		--]]
		local RoomSize_ManVal, RoomSize_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<RoomSize>')	
		RoomSize_ManVal = tonumber(RoomSize_ManVal)
		if RoomSize_ManVal > 100 then RoomSize_ManVal = 100 end
		RoomSize_ManVal = RoomSize_ManVal / 100 --turns 100 into 1
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Size'),RoomSize_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,RoomSize_AuTargId,			-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Size'),					-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Size' )												-- ENVELOPE_POINT_UNIT --]]
		
		
		
		local StereoSeparation_ManVal, StereoSeparation_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<StereoSeparation>')	
		--[[ NOTE: Live 0-120, Dragonfly Hall: 50-150; 
			correspondence: Live 50 = Df 50 (normalized=0), Live 120 = Df 100 (normalized=50); 
			range in Live: 50 to 120 (70 units); range in Df: 0.0 to 0.5 (50 units) --]]
		StereoSeparation_ManVal = tonumber(StereoSeparation_ManVal)
		StereoSeparation_ManVal = StereoSeparation_ManVal * 0.833 --0-120 to "0-100" conversion
		if StereoSeparation_ManVal < 50 then StereoSeparation_ManVal = 50 end  -- leaves 50 to 100
		StereoSeparation_ManVal = StereoSeparation_ManVal / 100 -- 50-100 to 0.5 - 1.0 conversion
		StereoSeparation_ManVal = StereoSeparation_ManVal - 0.5  -- 0.5 - 1.0 to 0.0-0.5 conversion
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Width'),StereoSeparation_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,StereoSeparation_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Width'),				-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'Reverb_to_Dragonfly Reverb-Width' )											-- ENVELOPE_POINT_UNIT --]]
		
		
		
		-- <StereoSeparationOnDrySignal Value="false" />	
		
		
		-- <RoomType> Live: Quality -- DISCARDED
		
		
		-- <MixReflect>
		-- <MixDiffuse>
		
		--- DEFAULTS FOR Dragonfly Hall reverb (inaccurate, here just for sake of having some default values)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Early Level'),0.25)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Early Level'),0.5)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Late Level'),0.8)
		
		

		local MixDirect_ManVal, MixDirect_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<MixDirect>')
		-- NOTE: Wet/Dry via FX SLOT "Wet" control
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getFXSlotWetParameterNumber(given_RPRtrack,currentFXindex),MixDirect_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,MixDirect_AuTargId,	-- given_AutomationTargetId,
								getFXSlotWetParameterNumber(given_RPRtrack,currentFXindex),					-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'' )																		-- ENVELOPE_POINT_UNIT


		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1

	end--if pluginNameForChecking ~= ""
	
end--function useDataFrom_LiveDevice_Reverb_XMLTable



--*********************************************************************************
-- useDataFrom_LiveDevice_SimpleDelay_XMLTable
--*********************************************************************************

-- GLOBALS

SimpleDelay_to_SpcshpDly_5x16ths_exist = false

function useDataFrom_LiveDevice_SimpleDelay_XMLTable(
						given_PluginDeviceXMLTable,				-- given_PluginDeviceXMLTable,
						given_RPRtrack,							-- given_RPRtrack
						given_AutomationEnvelopesXMLTable		-- given_AutomationEnvelopesXMLTable
						)
	
	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')
	
	-- NOTE: <On> setting retrieved at the end of function

	local Linked_ManVal, Linked_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Linked>') 
	
	-- Simple Delay LEFT DELAY
	local SyncModeLeft_ManVal, SyncModeLeft_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<SyncModeLeft>')
	local BeatDelayEnumL_ManVal, BeatDelayEnumL_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<BeatDelayEnumL>')
	local NoteOffsetLeft_ManVal, NoteOffsetLeft_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<NoteOffsetLeft>')
	   if NoteOffsetLeft_ManVal ~= '0' then 
	   ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
		..'" FX:'..currentFXindex..'  _to_Spaceship Delay: SimpleDelay had NoteOffsetLeft of '..NoteOffsetLeft_ManVal
		..', THIS IS NOT SUPPORTED in Spaceship Delay') end
	local MsDelayLeft_ManVal, MsDelayLeft_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<MsDelayLeft>')
	
	-- Simple Delay Right DELAY
	local SyncModeRight_ManVal, SyncModeRight_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<SyncModeRight>')
	local BeatDelayEnumR_ManVal, BeatDelayEnumR_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<BeatDelayEnumR>')
	local NoteOffsetRight_ManVal, NoteOffsetRight_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<NoteOffsetRight>')
	   if NoteOffsetRight_ManVal ~= '0' then
	   ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
		..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay: SimpleDelay had NoteOffsetRight of '..NoteOffsetRight_ManVal
		..', THIS IS NOT SUPPORTED in Spaceship Delay') end
	local MsDelayRight_ManVal, MsDelayRight_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<MsDelayRight>')

	--NOTE: THESE MUST BE AT THIS POINT OF ORDER
	if SyncModeLeft_ManVal ~= SyncModeRight_ManVal then 
		ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
		..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay: Sync Mode was different in L and R'
		..', THIS IS NOT SUPPORTED in Spaceship Delay; Sync Mode set according to LEFT setting.') end

	if Linked_ManVal == 'true' 
	then 
		SyncModeRight_ManVal	= 	SyncModeLeft_ManVal 
		BeatDelayEnumR_ManVal	= 	BeatDelayEnumL_ManVal
		MsDelayRight_ManVal 	= 	MsDelayLeft_ManVal
	end


	local Feedback_ManVal, Feedback_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Feedback>')
	
	local DryWet_ManVal, DryWet_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<DryWet>')
	

	-- GET <DelayTransitionMode Value="1" />
	
	
	--==========================================================================================================
	-- ADD Spaceship Delay
	--==========================================================================================================


	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding Spaceship Delay as substitute for Simple Delay")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'Spaceship Delay (Musical Entropy)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == "" then ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin") end--if
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
	

		--------------------------------------------------------
		-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
		--------------------------------------------------------
		
		local PARNUM_PARNAME_TABLE = {}
		local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
		for i=0,currentFX_NumberOfParameters-2,1	-- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
		do 
			local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
			PARNUM_PARNAME_TABLE[i] = PluginParameterName
		end
		--for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
	
	
		--------------------------------------------------------
		-- SET Spaceship Delay PARAMETERS
		--------------------------------------------------------
		
		-- PERMANENT SETTINGS corresponding to Simple Delay -------------------------
		
		-- General section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Input'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Output'),0.5)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Reverb'),0)
		
		-- Delay section PERMANENT					"Delay Mode":Delay Mode 	0.5=Ping Pong  0.83333331346512=Dual/Stereo
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Mode'),0.83333331346512)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Line Type'),0.83333331346512)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Freeze / Looper'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Cross Feedback'),0.0)

		
		-- Filters section PERMANENT				"Filter Type": 0.10000000149012  = No FX; 0.30000001192093 = Low/High Cut
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Type'),0.10000000149012)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filt. Location'),0.25)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Prm 3'),0.75)
		
		-- Modeling section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Saturation Type'),0.10000000149012)
		
		-- Modulation section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mod. Amount'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter LFO'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter EF'),0.5)
		
		-- Effects section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Effect Type'),0.10000000149012)
		
		-- / PERMANENT SETTINGS corresponding to Simple Delay -------------------------
		
		
		----------------------------------------------------------------------------------------------------------------------
		-- SETTINGS from Simple Delay settings 
		----------------------------------------------------------------------------------------------------------------------
		
		-- General section ----------------------------------------------------------------------------------------------------------------------
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mix'),DryWet_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,DryWet_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mix'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Mix' )									-- ENVELOPE_POINT_UNIT
								

		
		-- Delay section ----------------------------------------------------------------------------------------------------------------------
		
		
		-------------------------------------------------------------------------------
		-- WORKAROUND FOR LACK OF 5 x 16ths (1/4 + 1/16th) setting in Spaceship Delay
		-------------------------------------------------------------------------------


		local five_16ths_as_Seconds = reaper.TimeMap2_beatsToTime(0,1.25)	-- ReaProject proj, number tpos, optional number measuresIn
		
		-- IF ONLY LEFT HAS 5x16ths
		if BeatDelayEnumL_ManVal  == 4 -- 5 x 1/16
		and BeatDelayEnumR_ManVal ~= 4
		then
		
			SyncModeLeft_ManVal = 'false' -- force Ms timings
			MsDelayLeft_ManVal = math.floor((five_16ths_as_Seconds * 1000)+0.5)
			MsDelayRight_ManVal = reaper.TimeMap2_beatsToTime(0, Live_BeatDelayTime_to_QuarterNotes(BeatDelayEnumR_ManVal) )

			table.insert(WARNINGS_TABLE,'On track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay: SimpleDelay had Left Sync of 5 x 16ths '
			..', THIS IS NOT SUPPORTED in Spaceship Delay; equivalent millisecond value '..MsDelayLeft_ManVal..' set instead')
		end
		
		-- IF ONLY RIGHT HAS 5x16ths
		if BeatDelayEnumL_ManVal  ~= 4
		and BeatDelayEnumR_ManVal == 4 -- 5 x 1/16
		then
		
			SyncModeLeft_ManVal = 'false' -- force Ms timings
			MsDelayLeft_ManVal = reaper.TimeMap2_beatsToTime(0, Live_BeatDelayTime_to_QuarterNotes(BeatDelayEnumL_ManVal) )
			MsDelayRight_ManVal = math.floor((five_16ths_as_Seconds * 1000)+0.5)

			ShowConsoleMsg_and_AddtoLog('On track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay: SimpleDelay had Right Sync of 5 x 16ths '
			..', THIS IS NOT SUPPORTED in Spaceship Delay; equivalent millisecond value '..MsDelayRight_ManVal..' set instead')
		end
		
		
		-- IF BOTH HAVE 5x16ths
		if BeatDelayEnumL_ManVal  == 4 -- 5 x 1/16
		and BeatDelayEnumR_ManVal == 4 -- 5 x 1/16
		then
		
			SyncModeLeft_ManVal = 'false' -- force Ms timings
			MsDelayLeft_ManVal =  math.floor((five_16ths_as_Seconds * 1000)+0.5)
			MsDelayRight_ManVal = math.floor((five_16ths_as_Seconds * 1000)+0.5)


			ShowConsoleMsg_and_AddtoLog('On track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay: SimpleDelay had Right and Left Sync of 5 x 16ths '
			..', THIS IS NOT SUPPORTED in Spaceship Delay; equivalent millisecond value '..MsDelayRight_ManVal..' set instead')
		end
		
		
		
		
		
		-- Delay Sync Type (Live: DelayModeSwitch_ManVal)	     -- 0.83333331346512:Host                       0.16666667163372:Free 
		if SyncModeLeft_ManVal == 'true' then SyncModeLeft_ManVal = 0.83333331346512 else SyncModeLeft_ManVal = 0.16666667163372 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex, 	
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Type'),SyncModeLeft_ManVal)
								
		if checkIfAutomationXMLTable_HasEventsForTargetId(SyncModeLeft_AuTargId,given_AutomationEnvelopesXMLTable) == true
		or checkIfAutomationXMLTable_HasEventsForTargetId(SyncModeRight_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then	ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
				..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay:  Delay Time Sync Mode was automated;'
				..' THIS CONVERSION IS NOT CURRENTLY SUPPORTED by THIS SCRIPT, AUTOMATION DISCARDED') end				
		--[[						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,SyncModeLeft_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Type'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Delay Sync Type' )								-- ENVELOPE_POINT_UNIT --]]



		BeatDelayEnumL_ManVal = Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm(BeatDelayEnumL_ManVal)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
				getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Left'),BeatDelayEnumL_ManVal)
				
		if checkIfAutomationXMLTable_HasEventsForTargetId(BeatDelayEnumL_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then	ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
				..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay:  Synced Delay Left Time was automated;'
				..' THIS CONVERSION IS NOT CURRENTLY SUPPORTED by THIS SCRIPT, AUTOMATION DISCARDED') end			
		--[[
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,BeatDelayEnumL_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Left'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Delay Sync' )									-- ENVELOPE_POINT_UNIT --]]
								
		BeatDelayEnumR_ManVal = Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm(BeatDelayEnumR_ManVal)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Right'),BeatDelayEnumR_ManVal)
								
		if checkIfAutomationXMLTable_HasEventsForTargetId(BeatDelayEnumR_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then	ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
				..'" FX:'..currentFXindex..' SimpleDelay_to_Spaceship Delay:  Synced Delay Right Time was automated;'
				..' THIS CONVERSION IS NOT CURRENTLY SUPPORTED by THIS SCRIPT, AUTOMATION DISCARDED') end	
		--[[						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,BeatDelayEnumR_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Right'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Delay Sync' )									-- ENVELOPE_POINT_UNIT --]]



		MsDelayLeft_ManVal = convertMillisecondsTo_SpaceshipNormalizedMs(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),MsDelayLeft_ManVal)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),MsDelayLeft_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,MsDelayLeft_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Delay Ms' )										-- ENVELOPE_POINT_UNIT --]]
								
		MsDelayRight_ManVal = convertMillisecondsTo_SpaceshipNormalizedMs(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),MsDelayRight_ManVal)						
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Right'),MsDelayRight_ManVal)	
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,MsDelayRight_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Right'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Delay Ms' )										-- ENVELOPE_POINT_UNIT --]]		
		

								
		-- Feedback_ManVal NOTE: PPDly 0-95%, SpcshpDly 0-110%	-- NOTE: MIGHT NEED CONVERSION
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Feedback'),Feedback_ManVal)									
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Feedback_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Feedback'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'SimpleDelay_to_Spaceship Delay-Feedback' )								-- ENVELOPE_POINT_UNIT --]]


		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1

	end--if pluginNameForChecking ~= ""
		
end--function useDataFrom_LiveDevice_SimpleDelay_XMLTable








--[[*******************************************************************************

-- PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES_FROM_PLACEHOLDERS

 LOGIC: Use MidFreq and BandWidth envelopes to control Low Cut and High Cut
 
 NOTE: SHOULD BE CALLED ONLY AFTER ANY REQUIRED PLACEHOLDER ENVELOPES EXIST in REAPER!

--*********************************************************************************--]]


function PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES_FROM_PLACEHOLDERS(	given_RPRtrack, given_FXPluginIndex )
	
	-------------------------------------------------------------------------------------------------
	-- IF HAS MidFreq envelope, AND HAS BandWidth envelope
	-------------------------------------------------------------------------------------------------
	
	if 		PPDelay_to_SpcshpDelay_MidFreq_Constant_Value 		== -1 -- has "Effect Prm 1" envelope
	and 	PPDelay_to_SpcshpDelay_BandWidth_Constant_Value 	== -1 -- has "Effect Prm 2" envelope
	then
	
		local MidFreq_and_BandWidth_EVENT_TIMES_TABLE = {}
		
		local MidFreq_SourceEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,29,false) -- 29 "Effect Prm 1"
		local BandWidth_SourceEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,30,false) -- 30 "Effect Prm 2"
		
		local MidFreq_NumberOfPoints = reaper.CountEnvelopePoints(MidFreq_SourceEnvelope)
		local BandWidth_NumberOfPoints = reaper.CountEnvelopePoints(BandWidth_SourceEnvelope)
	
		
		for mfnp=0,MidFreq_NumberOfPoints,1
		do
			local retval, currentMidFreqPointTime,MFval,MFsh,MFtns,Mfsel = reaper.GetEnvelopePoint(MidFreq_SourceEnvelope,mfnp)
			table.insert(MidFreq_and_BandWidth_EVENT_TIMES_TABLE,currentMidFreqPointTime)
		end
		
		for bwnp=0,BandWidth_NumberOfPoints,1
		do
			local retval, currentBandWidthPointTime,BWval,BWsh,BWtns,BWsel = reaper.GetEnvelopePoint(BandWidth_SourceEnvelope,bwnp)
			table.insert(MidFreq_and_BandWidth_EVENT_TIMES_TABLE,currentBandWidthPointTime)
		end
		
		--reaper.ShowConsoleMsg("\nINDICES IN MidFreq_and_BandWidth_EVENT_TIMES_TABLE:"..#MidFreq_and_BandWidth_EVENT_TIMES_TABLE)
		

		local newLowCutEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,23,true)
		local newHighCutEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,24,true)
		
		
		for MBPointTime=1,#MidFreq_and_BandWidth_EVENT_TIMES_TABLE,1
		do
		
			local retval, MidFreq_VALUE = reaper.Envelope_Evaluate(	MidFreq_SourceEnvelope,									-- TrackEnvelope envelope, 
																	MidFreq_and_BandWidth_EVENT_TIMES_TABLE[MBPointTime],	-- number time, 
																	0,														-- number samplerate, 
																	0														-- integer samplesRequested
																	)
			MidFreq_VALUE = MidFreq_VALUE*100000 --restore to Hz
		
			local retval, BandWidth_VALUE = reaper.Envelope_Evaluate(	BandWidth_SourceEnvelope,								-- TrackEnvelope envelope, 
																	MidFreq_and_BandWidth_EVENT_TIMES_TABLE[MBPointTime],	-- number time, 
																	0,														-- number samplerate, 
																	0														-- integer samplesRequested
																	)
			BandWidth_VALUE = BandWidth_VALUE*10 --restore to Live native value
			
			
			--reaper.ShowConsoleMsg("\nTime:"..MidFreq_and_BandWidth_EVENT_TIMES_TABLE[MBPointTime]..' MidFreq_VALUE:'..MidFreq_VALUE..' BandWidth_VALUE:'..BandWidth_VALUE)
		
			Event_Value_LowCut, Event_Value_HighCut = PPDelay_MidFreq_to_SpcshpDly_LC_HC(MidFreq_VALUE,BandWidth_VALUE)
			
			reaper.InsertEnvelopePoint(
								newHighCutEnvelope,										-- TrackEnvelope envelope
								MidFreq_and_BandWidth_EVENT_TIMES_TABLE[MBPointTime],	-- number time
								Event_Value_HighCut,									-- number value
								0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn

			reaper.InsertEnvelopePoint(
								newLowCutEnvelope,										-- TrackEnvelope envelope
								MidFreq_and_BandWidth_EVENT_TIMES_TABLE[MBPointTime],	-- number time
								Event_Value_LowCut,										-- number value
								0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn


		end--for MBPointTime=1,#MidFreq_and_BandWidth_EVENT_TIMES_TABLE,1
		
		------------------------------------------------------------------
		-- SORT ENVELOPE POINTS (AFTER ALL POINTS ARE ADDED)
		------------------------------------------------------------------

		reaper.Envelope_SortPoints(newLowCutEnvelope)
		reaper.Envelope_SortPoints(newHighCutEnvelope)	
		
	end---- IF HAS MidFreq envelope, AND HAS BandWidth envelope
	
end-- PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES_FROM_PLACEHOLDERS








--[[*******************************************************************************

-- PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES

-- FOR NORMAL ENVELOPES (when other value is constant)

--*********************************************************************************--]]
function PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES(	given_RPRtrack,
													given_FXPluginIndex,
													given_AutomationTargetId,
													given_AutomationEnvelopesXMLTable,
													ENVELOPE_POINT_UNIT
													)

	for i=1,#given_AutomationEnvelopesXMLTable,1
	do
		if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
		then
			local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AutomationEnvelopesXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AutomationEnvelope>'				-- given_EndTag
																		)	
			local currentEnvelope_PointeeId
			
			for j=1,#AutomationEnvelope_XMLTable,1
			do
				if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
				then
					currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
					break
				end--if
			end--for j=1,#AutomationEnvelope_XMLTable,1
			
			
			if currentEnvelope_PointeeId == given_AutomationTargetId
			then 

				local newLowCutEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,23,true)
				local newHighCutEnvelope = reaper.GetFXEnvelope(given_RPRtrack,given_FXPluginIndex,24,true)
				
				local previousEventTime = 0
				
				for k=1,#AutomationEnvelope_XMLTable,1
				do
					
					if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					then
						local current_FloatEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Event_Time = string.sub(current_FloatEventTag_contents,
						string.find(current_FloatEventTag_contents,'Time="')+6,
						string.find(current_FloatEventTag_contents,'" Value=')-1)
						
						if Event_Time == '-63072000' then Event_Time = 0 end
						
						-- IMPORTANT! -------------------
						Event_Time = tonumber(Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Event_Time == previousEventTime then Event_Time = (Event_Time * 1.0000001) end 

						-- ADD POINT IN REAPER ONLY IF TIME VALUE IS POSITIVE
						if Event_Time > -1 
						then
						
							EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Event_Time)
						
							local Event_Value = string.sub(current_FloatEventTag_contents,
							string.find(current_FloatEventTag_contents,'Value="')+7,
							string.find(current_FloatEventTag_contents,'" />')-1)
							
							if string.match(Event_Value,'CurveControl') -- IF  CurveControl found, CUT IT OFF
							then Event_Value = string.sub(Event_Value,1,string.find(Event_Value,'" CurveControl')-1) end

							-- IMPORTANT! ---------------------
							Event_Value = tonumber(Event_Value)
							
							local Event_Value_LowCut, Event_Value_HighCut = 0,1	
							
							-- IF IS MidFreq ENVELOPE and THERE IS NO BandWidth ENVELOPE
							if 		ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-MidFreq'
							and 	PPDelay_to_SpcshpDelay_MidFreq_Constant_Value 		== -1 -- MidFreq has envelope data
							and 	PPDelay_to_SpcshpDelay_BandWidth_Constant_Value 	~= -1 -- BandWidth has constant value	
							then
								Event_Value_LowCut, Event_Value_HighCut = PPDelay_MidFreq_to_SpcshpDly_LC_HC(	tonumber(Event_Value),
																												tonumber(PPDelay_to_SpcshpDelay_BandWidth_Constant_Value)
																												)
							end
							
							-- IF IS BandWidth ENVELOPE and THERE IS NO MidFreq ENVELOPE
							if 	ENVELOPE_POINT_UNIT == 'PingPongDelay_to_Spaceship Delay-BandWidth'
							and 	PPDelay_to_SpcshpDelay_MidFreq_Constant_Value 		~= -1 -- MidFreq has constant value
							and 	PPDelay_to_SpcshpDelay_BandWidth_Constant_Value 	== -1 -- BandWidth has envelope data
							then
							
								Event_Value_LowCut, Event_Value_HighCut = PPDelay_MidFreq_to_SpcshpDly_LC_HC(	tonumber(PPDelay_to_SpcshpDelay_MidFreq_Constant_Value),
																												tonumber(Event_Value)
																												)
							end
							
							reaper.InsertEnvelopePoint(
												newHighCutEnvelope,			-- TrackEnvelope envelope
												EventTime_inReaperTime,		-- number time
												Event_Value_HighCut,		-- number value
												0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn

							reaper.InsertEnvelopePoint(
												newLowCutEnvelope,			-- TrackEnvelope envelope
												EventTime_inReaperTime,		-- number time
												Event_Value_LowCut,			-- number value
												0,0,0,1 )-- integer shape, number tension, boolean selected, optional boolean noSortIn
												
							previousEventTime = EventTime

						end--if Event_Time > -1
			
					end--if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					
				end--for k=1,#AutomationEnvelope_XMLTable,1

				------------------------------------------------------------------
				-- SORT ENVELOPE POINTS (AFTER ALL POINTS ARE ADDED)
				------------------------------------------------------------------

				reaper.Envelope_SortPoints(newLowCutEnvelope)
				reaper.Envelope_SortPoints(newHighCutEnvelope)
			
			end -- if currentEnvelope_PointeeId == given_AutomationTargetId

		end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
	
	end--for i=1,#given_AutomationEnvelopesXMLTable,1

end--function PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES








--*********************************************************************************
-- useDataFrom_LiveDevice_PingPongDelay_XMLTable
--*********************************************************************************

-- GLOBALS ------------------------------------------

PPDelay_to_SpcshpDelay_MidFreq_Constant_Value = -1
PPDelay_to_SpcshpDelay_BandWidth_Constant_Value = -1

function useDataFrom_LiveDevice_PingPongDelay_XMLTable(
						given_PluginDeviceXMLTable,			-- given_PluginDeviceXMLTable,
						given_RPRtrack,						-- given_RPRtrack
						given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
						)
	
	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')
	
	-- NOTE: <On> setting retrieved at the end of function										
	
	local MidFreq_ManVal, MidFreq_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<MidFreq>')
	
	local BandWidth_ManVal, BandWidth_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<BandWidth>')
	
	local DelayModeSwitch_ManVal, DelayModeSwitch_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<DelayModeSwitch>')
	
	local BeatDelayTime_ManVal, BeatDelayTime_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<BeatDelayTime>')

	local BeatDelayOffset_ManVal = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<BeatDelayOffset>')
	if BeatDelayOffset_ManVal ~= '0' then 
		ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
		..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay: PingPongDelay had Beat Delay Offset of '..BeatDelayOffset_ManVal
		..', THIS IS NOT SUPPORTED in Spaceship Delay') end
	
	
	local MsDelayTime_ManVal, MsDelayTime_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<MsDelayTime>')
	
	local Feedback_ManVal, Feedback_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Feedback>')
	
	local DryWet_ManVal, DryWet_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<DryWet>')
	
	local Freeze_ManVal, Freeze_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Freeze>')

	-- GET <DelayTransitionMode Value="1" />
	
	

	--==========================================================================================================
	-- ADD Spaceship Delay
	--==========================================================================================================


	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding Spaceship Delay as substitute for PingPongDelay")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'Spaceship Delay (Musical Entropy)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == "" then ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin") end
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
	

		--------------------------------------------------------
		-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
		--------------------------------------------------------
		local PARNUM_PARNAME_TABLE = {}
		local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
		for i=0,currentFX_NumberOfParameters-2,1	-- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
		do 
			local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
			PARNUM_PARNAME_TABLE[i] = PluginParameterName
		end
		--for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
		

		--------------------------------------------------------
		-- SET Spaceship Delay PARAMETERS
		--------------------------------------------------------
		
		-- PERMANENT SETTINGS corresponding to PingPongDelay -------------------------
		
		-- General section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Input'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Output'),0.5)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Reverb'),0)
		
		-- Delay section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Mode'),0.5)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Line Type'),0.83333331346512)
		
		-- Filters section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Type'),0.30000001192093)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filt. Location'),0.25)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Prm 3'),0.75)
		
		-- Modeling section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Saturation Type'),0.10000000149012)
		
		-- Modulation section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mod. Amount'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter LFO'),0)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter EF'),0.5)
		
		-- Effects section PERMANENT
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Effect Type'),0.10000000149012)
		
		-- / PERMANENT SETTINGS corresponding to PingPongDelay -------------------------
		
		
		----------------------------------------------------------------------------------------------------------------------
		-- SETTINGS from PingPongDelay settings 
		----------------------------------------------------------------------------------------------------------------------
		
		-- General section ----------------------------------------------------------------------------------------------------------------------
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mix'),DryWet_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,DryWet_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Mix'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Mix' )								-- ENVELOPE_POINT_UNIT
								
								
		-- Filters section ----------------------------------------------------------------------------------------------------------------------

		
		if checkIfAutomationXMLTable_HasEventsForTargetId(MidFreq_AuTargId,given_AutomationEnvelopesXMLTable) == false
		then 
			--  IF BandWidth IS AUTOMATED BUT MidFreq IS NOT
			PPDelay_to_SpcshpDelay_MidFreq_Constant_Value = tonumber(MidFreq_ManVal)

		elseif checkIfAutomationXMLTable_HasEventsForTargetId(MidFreq_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then 
		
			reaper.ShowConsoleMsg('\n On track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay: MidFreq has automation; ADDING PLACEHOLDER ENVELOPE')
			
			-- SAVE MidFreq AUTOMATION PLACEHOLDER INTO Spaceship Delay's "Effect Prm 1" ENVELOPE WHICH SHOULD NOT BE IN USE IN THIS CASE
			
			checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,MidFreq_AuTargId,	-- given_AutomationTargetId,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Effect Prm 1'),			-- given_PluginParameterNumber,
							given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
							'PingPongDelay_to_Spaceship Delay-MidFreq' )									-- ENVELOPE_POINT_UNIT --]]
							
		end
		

		
		if checkIfAutomationXMLTable_HasEventsForTargetId(BandWidth_AuTargId,given_AutomationEnvelopesXMLTable) == false
		then
			-- IF MidFreq IS AUTOMATED BUT BandWidth IS NOT
			PPDelay_to_SpcshpDelay_BandWidth_Constant_Value = tonumber(BandWidth_ManVal)
			
		elseif checkIfAutomationXMLTable_HasEventsForTargetId(BandWidth_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then
			reaper.ShowConsoleMsg('\n On track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay: BandWidth has automation; ADDING PLACEHOLDER ENVELOPE')
			
			-- SAVE MidFreq AUTOMATION PLACEHOLDER INTO Spaceship Delay's "Effect Prm 1" ENVELOPE WHICH SHOULD NOT BE IN USE IN THIS CASE
			checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,BandWidth_AuTargId,	-- given_AutomationTargetId,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Effect Prm 2'),			-- given_PluginParameterNumber,
							given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
							'PingPongDelay_to_Spaceship Delay-BandWidth' )									-- ENVELOPE_POINT_UNIT --]]
		end
		
		
		
		-------------------------------------------------------------------------------------------------
		-- IF HAS MidFreq envelope OR BandWidth envelope BUT NOT BOTH (check is in called function)
		-------------------------------------------------------------------------------------------------
		
		PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES(	given_RPRtrack,currentFXindex,MidFreq_AuTargId,given_AutomationEnvelopesXMLTable,
													'PingPongDelay_to_Spaceship Delay-MidFreq')
													
		PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES(	given_RPRtrack,currentFXindex,BandWidth_AuTargId,given_AutomationEnvelopesXMLTable,
													'PingPongDelay_to_Spaceship Delay-BandWidth')



		-------------------------------------------------------------------------------------------------
		-- IF HAS MidFreq envelope, AND HAS BandWidth envelope
		-------------------------------------------------------------------------------------------------
	
		if 		PPDelay_to_SpcshpDelay_MidFreq_Constant_Value 		== -1 -- has "Effect Prm 1" envelope
		and 	PPDelay_to_SpcshpDelay_BandWidth_Constant_Value 	== -1 -- has "Effect Prm 2" envelope
		then
				PPDly_to_SpcshpDly_ADD_FILTER_ENVELOPES_FROM_PLACEHOLDERS(	given_RPRtrack,currentFXindex )
		end
		

		-- SET MANUAL VALUES ----------------------------------------------------------------------------------
		local LowCutValue_Norm, HighCutValue_Norm = PPDelay_MidFreq_to_SpcshpDly_LC_HC(tonumber(MidFreq_ManVal),tonumber(BandWidth_ManVal))
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Prm 1'),LowCutValue_Norm)				

		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Prm 2'),HighCutValue_Norm)

		
		-- Delay section ----------------------------------------------------------------------------------------------------------------------
		
		
		
		--[[  PingPong Delay to Spaceship Delay time Milliseconds to Normalized; Ms values from Live:	<MsDelayTime>	1-999	
		
				Spaceship Delay:
				"Delay Left" ms		Normalized
				
				0.1					0.0
				0.2					0.063199289143085
				0.3					0.099991321563721 
				0.4					0.1260429173708
				0.5					0.14633190631866
				0.6					0.1628124713897
				0.7					0.1769206225872
				
				1					0.20930847525597
				
				10.142				0.41985791921616
				100					0.62785792350769
				1000.943			0.8372295498848
				2000.585			0.90017181634903
				6000				1.0
				
		--]]

		-------------------------------------------------------------------------------
		-- WORKAROUND FOR LACK OF 5 x 16ths (1/4 + 1/16th) setting in Spaceship Delay
		-------------------------------------------------------------------------------
		
		if BeatDelayTime_ManVal == '4' -- 5 x 1/16
		then
			local five_16ths_as_Seconds = reaper.TimeMap2_beatsToTime(	0,		-- ReaProject proj, 
																		1.25	-- number tpos, 
																				-- optional number measuresIn
																		)
			DelayModeSwitch_ManVal = 'false'
			MsDelayTime_ManVal = math.floor((five_16ths_as_Seconds * 1000)+0.5)	
			
			--reaper.ShowConsoleMsg('\n Found 5x16ths delay value'..five_16ths_as_Seconds)

			ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
			..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay: PingPongDelay had Beat Sync of 5 x 16ths '
			..', THIS IS NOT SUPPORTED in Spaceship Delay; equivalent millisecond value '..MsDelayTime_ManVal..' set instead')
		end
			
		
		
		-- Delay Sync Type (Live: DelayModeSwitch_ManVal ) 			   -- 0.83333331346512:Host						     0.16666667163372:Free 
		if DelayModeSwitch_ManVal == 'true' then DelayModeSwitch_ManVal = 0.83333331346512 else DelayModeSwitch_ManVal = 0.16666667163372 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex, 	
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Type'),DelayModeSwitch_ManVal)
								
		if checkIfAutomationXMLTable_HasEventsForTargetId(DelayModeSwitch_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then	ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
				..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay:  Delay Sync Mode was automated;'
				..' THIS CONVERSION IS NOT CURRENTLY SUPPORTED by THIS SCRIPT, AUTOMATION DISCARDED') end
		--[[						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,DelayModeSwitch_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Type'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Delay Sync Type' )							-- ENVELOPE_POINT_UNIT --]]
								
				
				
		BeatDelayTime_ManVal = Live_BeatDelayTime_to_SpcshpDly_DelaySyncNorm(BeatDelayTime_ManVal)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Left'),BeatDelayTime_ManVal)	
								
		if checkIfAutomationXMLTable_HasEventsForTargetId(BeatDelayTime_AuTargId,given_AutomationEnvelopesXMLTable) == true
		then	ShowConsoleMsg_and_AddtoLog('\nOn track '..currentTrackIndex..':"'..currentREAPERtrack_name
				..'" FX:'..currentFXindex..' PingPongDelay_to_Spaceship Delay:  Synced Delay Time was automated;'
				..' THIS CONVERSION IS NOT CURRENTLY SUPPORTED by THIS SCRIPT, AUTOMATION DISCARDED') end				
		--[[					
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,BeatDelayTime_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Sync Left'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Delay Sync' )									-- ENVELOPE_POINT_UNIT --]]

 
 
		MsDelayTime_ManVal = convertMillisecondsTo_SpaceshipNormalizedMs(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),MsDelayTime_ManVal)
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),MsDelayTime_ManVal)		
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,MsDelayTime_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Delay Left'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Delay Ms' )								-- ENVELOPE_POINT_UNIT --]]
		


		-- Feedback_ManVal NOTE: PPDly 0-95%, SpcshpDly 0-110%	-- NOTE: MIGHT NEED CONVERSION
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Feedback'),Feedback_ManVal)								
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Feedback_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Feedback'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Feedback' )								-- ENVELOPE_POINT_UNIT --]]


		if Freeze_ManVal == 'true' then Freeze_ManVal = 1 else Freeze_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Freeze / Looper'),Freeze_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Freeze_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Freeze / Looper'),	-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'PingPongDelay_to_Spaceship Delay-Freeze / Looper' )						-- ENVELOPE_POINT_UNIT --]]



		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
		
	
	end--if pluginNameForChecking ~= ""
	
end--function useDataFrom_LiveDevice_PingPongDelay_XMLTable








--*********************************************************
-- useDataFrom_LiveDevice_Gate_XMLTable
--*********************************************************
function useDataFrom_LiveDevice_Gate_XMLTable(
								given_PluginDeviceXMLTable,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)
								
	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')							
								
								
	-- NOTE: <On> setting retrieved at the end of function										
	
	local Threshold_ManVal, Threshold_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Threshold>')
	
	local Attack_ManVal, Attack_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Attack>')
	
	local Hold_ManVal, Hold_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Hold>')
	
	local Release_ManVal, Release_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Release>')


	-- GET <Return>
	
	
	local Gain_ManVal, Gain_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Gain>')


	-- GET <SideChain> AS A TABLE
	local SideChain_XMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(given_PluginDeviceXMLTable,'<SideChain>','</SideChain>')
		
		-- GET <SideChain><OnOff>
		local SideChain_OnOff_ManVal,SideChain_OnOff_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(SideChain_XMLTable,'<OnOff>')
		
		-- GET <SideChain><RoutedInput> AS A TABLE
		local RoutedInput_XMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(SideChain_XMLTable,'<RoutedInput>','</RoutedInput>')
		
		local RoutedInput_TargetValue = getValueFrom_SingleLineXMLTag(RoutedInput_XMLTable,3,'<Target Value="','" />') 	
				
		-- GET <SideChain><RoutedInput><Volume>
		local SideChain_Volume_ManVal,SideChain_Volume_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(RoutedInput_XMLTable,'<Volume>')
	

	local SideListen_ManVal, SideListen_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<SideListen>')


	-- GET <SideChainEq> AS A TABLE
	

	local FlipMode_ManVal, FlipMode_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<FlipMode>')


	-- GET	<Live8LegacyMode Value="


	local LookAhead_ManVal, LookAhead_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LookAhead>')



	--==========================================================================================================
	-- ADD ReaGate
	--==========================================================================================================

	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaGate as substitute for Gate")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'ReaGate (Cockos)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == ""
	then
		ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin")
	end--if
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
	

		--------------------------------------------------------
		-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
		--------------------------------------------------------
		local PARNUM_PARNAME_TABLE = {}		
		local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
		for i=0,currentFX_NumberOfParameters-2,1	-- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
		do 
			local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
			PARNUM_PARNAME_TABLE[i] = PluginParameterName
		end
		--for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
		
		
		--------------------------------------------------------
		-- SET ReaGate PARAMETERS
		--------------------------------------------------------
		
		-- SET ReaGate to receive detector from Main Input L+R (SignIn = 0, normalized:0)
		-- NOTE: WILL BE CHANGED LATER IF SIDECHAIN IS ON
		reaper.TrackFX_SetParamNormalized(given_RPRtrack,currentFXindex,
						getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'SignIn'),0.0)
	
								

		-- NOTE: Attack value needs to be formatted for ReaGate... 0.0002 = 0.1 ms, 0.002 = 1ms, 0.01 = 5ms, 0.1 = 50 ms, 1=500ms
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),(Attack_ManVal/500))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Attack_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-Attack' )													-- ENVELOPE_POINT_UNIT
		
		
		-- NOTE: needs to be 1000 or less, also for envelopes!
		Hold_ManVal = tonumber(Hold_ManVal)
		if Hold_ManVal > 1000 then Hold_ManVal = 1000 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Hold'),(Hold_ManVal/1000))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Hold_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Hold'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-Hold' )												-- ENVELOPE_POINT_UNIT

		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Release'),(Release_ManVal/5000))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Release_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Release'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-Release' )												-- ENVELOPE_POINT_UNIT
		
		
		
		-- <Return>
		
		
		-- <Gain> = Floor, range -inf to -0;
		
				-- NOTE: 	Live Gate Floor = 	-inf							0dB; 
				-- 			ReaGate Hystrsis = 	-inf	 	-48dB 				0dB 		+12dB; 
				-- displayed in FX window		0.0, 		0.0020000000949949	0.5			1.9905358552933
				-- tested to work				(dB to amplitude)				1
		
		Gain_ManVal = tonumber(Gain_ManVal)
		if 		Gain_ManVal == 0 						then Gain_ManVal = 1
		--elseif 	Gain_ManVal < 0 and Gain_ManVal > -48 	then Gain_ManVal = (dBtoAmplitude(Gain_ManVal) * 1)	
		--elseif 	Gain_ManVal < -48 						then Gain_ManVal = 0.0
		else 	Gain_ManVal = (dBtoAmplitude(Gain_ManVal) * 1)
		end
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Hysteresis'),Gain_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Gain_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Hysteresis'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-Hystrsis' )											-- ENVELOPE_POINT_UNIT						


		-- <SideChain>
		if SideChain_OnOff_ManVal == 'true' 
		then
			--reaper.ShowConsoleMsg('\n SideChain_OnOff_ManVal:'..SideChain_OnOff_ManVal)
			--reaper.ShowConsoleMsg('\n RoutedInput_TargetValue:'..RoutedInput_TargetValue)
			--reaper.ShowConsoleMsg('\n SideChain_Volume_ManVal:'..SideChain_Volume_ManVal)
			
			-- SET ReaComp to receive detector from Auxiliary Input L+R (SignIn = 2, normalized:0.0018450184725225)
			reaper.TrackFX_SetParamNormalized(given_RPRtrack,currentFXindex,
						getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'SignIn'),0.0018450184725225)
						
			
			
			ShowConsoleMsg_and_AddtoLog('\n\n NOTE:  ReaGate Sidechain INPUT NOT CONNECTED! Set manually according to settings in Live.'
			..'\n        Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex)
			
			
			table.insert(WARNINGS_TABLE,'\n ReaGate Sidechain INPUT NOT CONNECTED! Set manually according to settings in Live.'
			..'\n        Track '..currentTrackIndex..':"'..currentREAPERtrack_name..'" FX:'..currentFXindex)		
			
						
		end				
						
						
						

		if SideListen_ManVal == 'true' then SideListen_ManVal = 1 else SideListen_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Preview Filter'),SideListen_ManVal)				
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,SideListen_AuTargId,	-- given_AutomationTargetId,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Preview Filter'),				-- given_PluginParameterNumber,
							given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
							'Gate_to_ReaGate-PreviewF' )													-- ENVELOPE_POINT_UNIT	
	
		-- <SideChainEq>


-- WORK IN PROGRESS NOTE: MAKE SURE THIS IS ACTUALLY THE SAME THING IN BOTH Live and ReaGate
		-- <FlipMode>  
		if FlipMode_ManVal == 'true' then FlipMode_ManVal = 1 else FlipMode_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Invert Wet'),FlipMode_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FlipMode_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Invert Wet'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-InvrtWet' )											-- ENVELOPE_POINT_UNIT
		

		-- <Live8LegacyMode Value="false" />


		if 		LookAhead_ManVal == '0' then LookAhead_ManVal = 0 
		elseif 	LookAhead_ManVal == '1'	then LookAhead_ManVal = 1.5
		elseif 	LookAhead_ManVal == '2'	then LookAhead_ManVal = 10 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Pre-open'),(LookAhead_ManVal/250))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,LookAhead_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Pre-open'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Gate_to_ReaGate-Pre-open' )												-- ENVELOPE_POINT_UNIT	





        ----------------------------------------------------------------------------------------
        -- SET Threshold value (for some reason, works more reliably at this stage) 
        ----------------------------------------------------------------------------------------
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Threshold'),(Threshold_ManVal))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Threshold_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Threshold'),	    -- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								''	)																		-- ENVELOPE_POINT_UNIT
                                
                                


		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
	
	
	end--if pluginNameForChecking ~= ""


end--function useDataFrom_LiveDevice_Gate_XMLTable








--*********************************************************
-- useDataFrom_LiveDevice_Compressor_XMLTable
--*********************************************************
function useDataFrom_LiveDevice_Compressor_XMLTable(
												given_PluginDeviceXMLTable,
												given_RPRtrack,
												given_AutomationEnvelopesXMLTable
												)
									
	-- NOTE: <On> setting retrieved at the end of function										
	
	local Threshold_ManVal, Threshold_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Threshold>')
    
            --ShowConsoleMsg_and_AddtoLog("\n Threshold_ManVal is:"..Threshold_ManVal)
            --ShowConsoleMsg_and_AddtoLog("\n amplitudeTodB(Threshold_ManVal) is:"..amplitudeTodB(Threshold_ManVal))
	
	local Ratio_ManVal, Ratio_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Ratio>')
	
	local ExpansionRatio_ManVal, ExpansionRatio_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<ExpansionRatio>')
	
	local Attack_ManVal, Attack_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Attack>')
	
	local Release_ManVal, Release_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Release>')
	
	local AutoReleaseControlOnOff_ManVal, AutoReleaseControlOnOff_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,
																														'<AutoReleaseControlOnOff>')
	local Gain_ManVal, Gain_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Gain>')
	
	local GainCompensation_ManVal, GainCompensation_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<GainCompensation>')
	
	local DryWet_ManVal, DryWet_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<DryWet>')
	
	local Model_ManVal, Model_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Model>')
	
	local LegacyModel_ManVal, LegacyModel_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LegacyModel>')
	
	-- GET <LogEnvelope>
	-- local LogEnvelope_ManVal, LogEnvelope_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LogEnvelope>')
	
	local LegacyEnvFollowerMode_ManVal, LegacyEnvFollowerMode_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,
																													'<LegacyEnvFollowerMode>')
	
	local Knee_ManVal, Knee_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<Knee>')
	
	local LookAhead_ManVal, LookAhead_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<LookAhead>')
	
	local SideListen_ManVal, SideListen_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<SideListen>')


	-- GET <SideChain> AS A TABLE
	local SideChain_XMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(given_PluginDeviceXMLTable,'<SideChain>','</SideChain>')
		
		-- GET <SideChain><OnOff>
		local SideChain_OnOff_ManVal,SideChain_OnOff_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(SideChain_XMLTable,'<OnOff>')
		
		-- GET <SideChain><RoutedInput> AS A TABLE
		local RoutedInput_XMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(SideChain_XMLTable,'<RoutedInput>','</RoutedInput>')
		
		local RoutedInput_TargetValue = getValueFrom_SingleLineXMLTag(RoutedInput_XMLTable,3,'<Target Value="','" />') 	
				
		-- GET <SideChain><RoutedInput><Volume>
		local SideChain_Volume_ManVal,SideChain_Volume_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(RoutedInput_XMLTable,'<Volume>')
		
		
	-- GET <SideChainEq> AS A TABLE
	
	
	--==========================================================================================================
	-- ADD ReaComp
	--==========================================================================================================

	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaComp as substitute for Compressor; NOTE: EXPANSION mode not supported")
	
	reaper.TrackFX_AddByName(	given_RPRtrack, 
								'ReaComp (Cockos)',
								false,
								-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == "" then ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin") end--if
	
	if pluginNameForChecking ~= ""
	then
		ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')								
	

		--------------------------------------------------------
		-- GET PARAMETERS AND THEIR NAMES; MAKE TABLE
		--------------------------------------------------------
		local PARNUM_PARNAME_TABLE = {}		
		local currentFX_NumberOfParameters = reaper.TrackFX_GetNumParams(given_RPRtrack,currentFXindex)
		for i=0,currentFX_NumberOfParameters-2,1 -- NOTE: WITH "-2", EXCLUDE FX SLOT'S "Bypass" and WET
		do 
			local retval, PluginParameterName = reaper.TrackFX_GetParamName(given_RPRtrack,currentFXindex,i,64)																
			PARNUM_PARNAME_TABLE[i] = PluginParameterName
		end
		
        --for check=0,#PARNUM_PARNAME_TABLE,1 do reaper.ShowConsoleMsg('\n'..PARNUM_PARNAME_TABLE[check]) end
		
		
		--------------------------------------------------------
		-- SET ReaComp PARAMETERS
		--------------------------------------------------------
		
		-- SET ReaComp to receive detector from Main Input L+R (SignIn = 0, normalized:0)
		-- NOTE: WILL BE CHANGED LATER IF SIDECHAIN IS ON
		reaper.TrackFX_SetParamNormalized(given_RPRtrack,currentFXindex,
						getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'SignIn'),0.0)


								

		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Ratio'),((-(1-Ratio_ManVal))/100)) --(-(1-Ratio_ManVal))/100						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Ratio_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Ratio'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Compressor2_to_ReaComp-Ratio'	)											-- ENVELOPE_POINT_UNIT
								

		-- NOTE: Attack value needs to be formatted for ReaComp... 0.0002 = 0.1 ms, 0.002 = 1ms, 0.01 = 5ms, 0.1 = 50 ms, 1=500ms
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),(Attack_ManVal/500))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Attack_AuTargId,		-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Attack'),			-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								'Compressor2_to_ReaComp-Attack' )											-- ENVELOPE_POINT_UNIT
		
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Release'),(Release_ManVal/5000))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Release_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Release'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'Compressor2_to_ReaComp-Release' )										-- ENVELOPE_POINT_UNIT
		
		
		if AutoReleaseControlOnOff_ManVal == 'true' then AutoReleaseControlOnOff_ManVal = 1 else AutoReleaseControlOnOff_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Auto Release'),AutoReleaseControlOnOff_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,AutoReleaseControlOnOff_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Auto Release'),						-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,														-- given_AutomationEnvelopesXMLTable
								'ReaComp-AutoRel' )																		-- ENVELOPE_POINT_UNIT
		
		
		--NOTE: Live Out Gain range: -36 to +36; ReaComp Wet range -inf to +12: 
		--reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								--getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Wet'),Gain_ManVal)
								
		
		if GainCompensation_ManVal == 'true' then GainCompensation_ManVal = 1 else GainCompensation_ManVal = 0 end
		if SideChain_OnOff_ManVal == 'true'  then GainCompensation_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Auto Make Up Gain'),GainCompensation_ManVal)						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,GainCompensation_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Auto Make Up Gain'),				-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
								'ReaComp-AutoMkUp' )															-- ENVELOPE_POINT_UNIT
		
		
		-- NOTE: THIS NEEDS TO BE THE FX SLOT "Wet" control
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getFXSlotWetParameterNumber(given_RPRtrack,currentFXindex),DryWet_ManVal)
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,DryWet_AuTargId,	-- given_AutomationTargetId,
								getFXSlotWetParameterNumber(given_RPRtrack,currentFXindex),				-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,										-- given_AutomationEnvelopesXMLTable
								'' )																	-- ENVELOPE_POINT_UNIT
		

		-- NOTE: THIS NEEDS CONDITIONS (DIFFERENT RMS VALUES)
		-- Model_ManVal
		--reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
		--						getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'RMS size'),?????????????????)
		
		-- LegacyModel_ManVal
		
		-- LegacyEnvFollowerMode_ManVal
		 
		
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Knee'),(Knee_ManVal/24))						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Knee_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Knee'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,									-- given_AutomationEnvelopesXMLTable
								'Compressor2_to_ReaComp-Knee' )										-- ENVELOPE_POINT_UNIT						
								
				
		if 		LookAhead_ManVal == '0' then LookAhead_ManVal = 0 
		elseif 	LookAhead_ManVal == '1'	then LookAhead_ManVal = 1
		elseif 	LookAhead_ManVal == '2'	then LookAhead_ManVal = 10 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Pre-comp'),(LookAhead_ManVal/250))
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,LookAhead_AuTargId,	-- given_AutomationTargetId,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Pre-comp'),				-- given_PluginParameterNumber,
							given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
							'Compressor2_to_ReaComp-Pre-comp' )												-- ENVELOPE_POINT_UNIT	


		if SideListen_ManVal == 'true' then SideListen_ManVal = 1 else SideListen_ManVal = 0 end
		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Preview'),SideListen_ManVal)						
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,SideListen_AuTargId,	-- given_AutomationTargetId,
							getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Filter Preview'),				-- given_PluginParameterNumber,
							given_AutomationEnvelopesXMLTable,												-- given_AutomationEnvelopesXMLTable
							'ReaComp-PreviewF' )															-- ENVELOPE_POINT_UNIT	
	

	
		---------------------------------------------------------------
		-- GET SIDECHAINING DATA FOR USING AFTER ALL TRACKS ARE ADDED
		----------------------------------------------------------------

		if SideChain_OnOff_ManVal == 'true' 
		then
			--reaper.ShowConsoleMsg('\n SideChain_OnOff_ManVal:'..SideChain_OnOff_ManVal)
			--reaper.ShowConsoleMsg('\n RoutedInput_TargetValue:'..RoutedInput_TargetValue)
			--reaper.ShowConsoleMsg('\n SideChain_Volume_ManVal:'..SideChain_Volume_ManVal)
			
			-- SET ReaComp to receive detector from Auxiliary Input L+R (SignIn = 2, normalized:0.0018450184725225)
			reaper.TrackFX_SetParamNormalized(given_RPRtrack,currentFXindex,
						getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'SignIn'),0.0018450184725225)
			
			
			-- SET THIS (DESTINATION) TRACK TO HAVE 4 CHANNELS
			-- NECESSARY TO HAVE ReaComp receive 3/4
			reaper.SetMediaTrackInfo_Value(
										given_RPRtrack,	-- MediaTrack tr, 
										'I_NCHAN',		-- string parmname, 
										4				-- number newvalue
										)

			--------------------------------------------------------
			-- SET FX PINS (not strictly necessary but just in case)
			--------------------------------------------------------
			

			reaper.TrackFX_SetPinMappings(given_RPRtrack, currentFXindex, 0, 0, 1, 0) 
			reaper.TrackFX_SetPinMappings(given_RPRtrack, currentFXindex, 0, 1, 2, 0)
			reaper.TrackFX_SetPinMappings(given_RPRtrack, currentFXindex, 0, 2, 4, 0)
			reaper.TrackFX_SetPinMappings(given_RPRtrack, currentFXindex, 0, 3, 8, 0)
		
		--[[
			local inPin0 = reaper.TrackFX_GetPinMappings(given_RPRtrack, currentFXindex, 0, 0)
			local inPin1 = reaper.TrackFX_GetPinMappings(given_RPRtrack, currentFXindex, 0, 1)
			local inPin2 = reaper.TrackFX_GetPinMappings(given_RPRtrack, currentFXindex, 0, 2)
			local inPin3 = reaper.TrackFX_GetPinMappings(given_RPRtrack, currentFXindex, 0, 3)
			reaper.ShowConsoleMsg('\n inPin0:'..inPin0..' inPin1:'..tostring(inPin1)..' inPin2:'..inPin2..' outPin3:'..inPin3)
			
			--]]
				
			

			local SourceTrack_Id = ''
			local SourceTrack_SENDMODE = 0 --0=post-fader, 1=pre-fx, 3=post-fx
			
			local applyRouting = false
			
			if string.match(RoutedInput_TargetValue,'AudioIn/External') then applyRouting = false
			elseif string.match(RoutedInput_TargetValue,'AudioIn/None') then applyRouting = false

			elseif string.match(RoutedInput_TargetValue,'/PreFxOut')
			then
				SourceTrack_Id = getSubstringBetweenStrings(RoutedInput_TargetValue,'AudioIn/Track.','/PreFxOut')
				SourceTrack_SENDMODE = 1 --0=post-fader, 1=pre-fx, 3=post-fx
				applyRouting = true

			elseif string.match(RoutedInput_TargetValue,'/PostFxOut')
			then
				SourceTrack_Id = getSubstringBetweenStrings(RoutedInput_TargetValue,'AudioIn/Track.','/PostFxOut')
				SourceTrack_SENDMODE = 3 --0=post-fader, 1=pre-fx, 3=post-fx
				applyRouting = true
				
			elseif string.match(RoutedInput_TargetValue,'/TrackOut')
			then
				SourceTrack_Id = getSubstringBetweenStrings(RoutedInput_TargetValue,'AudioIn/Track.','/TrackOut')
				SourceTrack_SENDMODE = 0 --0=post-fader, 1=pre-fx, 3=post-fx
				applyRouting = true
				
			end--if string.match
			
			if applyRouting == true
			then
			
				ShowConsoleMsg_and_AddtoLog('\n'
				..'                SIDECHAIN: Compressor received sidechain from Live Track of Id '..SourceTrack_Id
				..', REAPER receive mode:'..SourceTrack_SENDMODE)
				
				local SOURCES_LIVETRACKID_TABLE = {}
			
				SOURCES_LIVETRACKID_TABLE[0] = currentTrackIndex		-- RECEIVE TRACK, from current global value
				SOURCES_LIVETRACKID_TABLE[1] = currentFXindex
				SOURCES_LIVETRACKID_TABLE[2] = SourceTrack_Id			-- SOURCE TRACK
				SOURCES_LIVETRACKID_TABLE[3] = SourceTrack_SENDMODE
				SOURCES_LIVETRACKID_TABLE[4] = SideChain_Volume_ManVal
				SOURCES_LIVETRACKID_TABLE[5] = SideChain_Volume_AuTargId			
				
				table.insert(REACOMPS_SIDECHAINS_SETTINGS_TABLE,SOURCES_LIVETRACKID_TABLE)
				
				--for check=0,#SOURCES_LIVETRACKID_TABLE,1 do reaper.ShowConsoleMsg('\n'..SOURCES_LIVETRACKID_TABLE[check]) end
				
				
			elseif applyRouting == false
			then
				ShowConsoleMsg_and_AddtoLog('\n                SIDECHAIN NOT APPLIED: Compressor received sidechain from "'..RoutedInput_TargetValue..'", THIS SIDECHAIN WAS NOT SET IN REAPER')
			end
			
		end
	
    
    
        ----------------------------------------------------------------------------------------
        -- SET Threshold value (for some reason, works more reliably at this stage) 
        ----------------------------------------------------------------------------------------

         --[[ 
        
         ReaComp Threshold range:                                                                                    Live Compressor Equivalent

         i=12 ParamName:Threshold Param:3.9810717105865 ParamNormalized:1.9905358552933 FormattedParamValue:+12.0
         i=9 ParamName:Threshold Param:2.8183829784393 ParamNormalized:1.4091914892197 FormattedParamValue:+9.0
         
         i=6 ParamName:Threshold Param:1.9952622652054 ParamNormalized:0.99763113260269 FormattedParamValue:+6.0            1.99526238
         i=3 ParamName:Threshold Param:1.4125375747681 ParamNormalized:0.70626878738403 FormattedParamValue:+3.0            1.41253746
         
         i=0 ParamName:Threshold Param:1.0 ParamNormalized:0.5 FormattedParamValue:+0.0                                     1
         
         i=-3 ParamName:Threshold Param:0.70794576406479 ParamNormalized:0.35397288203239 FormattedParamValue:-3.0          0.7079458237
         i=-6 ParamName:Threshold Param:0.50118720531464 ParamNormalized:0.25059360265732 FormattedParamValue:-6.0          0.5011872053
         i=-9 ParamName:Threshold Param:0.35481339693069 ParamNormalized:0.17740669846535 FormattedParamValue:-9.0          0.3548133373
         i=-12 ParamName:Threshold Param:0.25118863582611 ParamNormalized:0.12559431791306 FormattedParamValue:-12.0        0.251188606
         i=-15 ParamName:Threshold Param:0.17782793939114 ParamNormalized:0.088913969695568 FormattedParamValue:-15.0       0.1778279543
         i=-18 ParamName:Threshold Param:0.12589253485203 ParamNormalized:0.062946267426014 FormattedParamValue:-18.0       0.1258925349
         i=-21 ParamName:Threshold Param:0.089125096797943 ParamNormalized:0.044562548398972 FormattedParamValue:-21.0      0.08912508935
         i=-24 ParamName:Threshold Param:0.063095733523369 ParamNormalized:0.031547866761684 FormattedParamValue:-24.0      0.06309572607
         i=-27 ParamName:Threshold Param:0.044668357819319 ParamNormalized:0.022334178909659 FormattedParamValue:-27.0      0.04466835409
         i=-30 ParamName:Threshold Param:0.031622774899006 ParamNormalized:0.015811387449503 FormattedParamValue:-30.0      0.0316227749
         i=-33 ParamName:Threshold Param:0.022387212142348 ParamNormalized:0.011193606071174 FormattedParamValue:-33.0      0.02238721214
         i=-36 ParamName:Threshold Param:0.015848932787776 ParamNormalized:0.007924466393888 FormattedParamValue:-36.0      0.01584892906
         i=-39 ParamName:Threshold Param:0.011220184154809 ParamNormalized:0.0056100920774043 FormattedParamValue:-39.0     0.01122018229
         i=-42 ParamName:Threshold Param:0.007943281903863 ParamNormalized:0.0039716409519315 FormattedParamValue:-42.0     0.007943280973
         i=-45 ParamName:Threshold Param:0.0056234132498503 ParamNormalized:0.0028117066249251 FormattedParamValue:-45.0    0.00562341325
         i=-48 ParamName:Threshold Param:0.003981071524322 ParamNormalized:0.001990535762161 FormattedParamValue:-48.0      0.003981071059
         i=-51 ParamName:Threshold Param:0.0028183830436319 ParamNormalized:0.001409191521816 FormattedParamValue:-51.0     0.002818383276
         i=-54 ParamName:Threshold Param:0.0019952622242272 ParamNormalized:0.0009976311121136 FormattedParamValue:-54.0    0.001995261991
         i=-57 ParamName:Threshold Param:0.0014125375309959 ParamNormalized:0.00070626876549795 FormattedParamValue:-57.0   0.001412537065
         i=-60 ParamName:Threshold Param:0.0010000000474975 ParamNormalized:0.00050000002374873 FormattedParamValue:-60.0   0.001000000047
         i=-63 ParamName:Threshold Param:0.00070794578641653 ParamNormalized:0.00035397289320827 FormattedParamValue:-63.0  0.0007079456118
         i=-66 ParamName:Threshold Param:0.00050118722720072 ParamNormalized:0.00025059361360036 FormattedParamValue:-66.0  0.0005011872854
         i=-69 ParamName:Threshold Param:0.00035481338272803 ParamNormalized:0.00017740669136401 FormattedParamValue:-69.0  0.0003548133536
        
        --]]

		reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Threshold'),(Threshold_ManVal))                      
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,Threshold_AuTargId,	-- given_AutomationTargetId,
								getParNumBy_1stParNameInPNPMTable(PARNUM_PARNAME_TABLE,'Threshold'),		-- given_PluginParameterNumber,
								given_AutomationEnvelopesXMLTable,											-- given_AutomationEnvelopesXMLTable
								''	)																		-- ENVELOPE_POINT_UNIT
    
    
    

		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
	
		
	end--if pluginNameForChecking ~= ""	
												
end--function useDataFrom_PluginDeviceXMLTable








--*********************************************************************************
-- useDataFrom_PluginDeviceXMLTable (load plugins and their envelopes, if any)
--*********************************************************************************

function useDataFrom_PluginDeviceXMLTable(
							given_PluginDeviceXMLTable,
							given_RPRtrack,
							given_AutomationEnvelopesXMLTable)

	--reaper.ShowConsoleMsg("\n        Starting useDataFrom_PluginDeviceXMLTable, currentFXindex (plugin index in this track's FX chain):"..currentFXindex)
	
	
	-- ! ! ! -----------------------------------------------------------------
	-- NOTE: global currentFXindex is initiated / RESET elsewhere!
	--------------------------------------------------------------------------
	
    local pluginIsVST = false -- for checking later for <VstPreset (to be sure) before pplying VST preset data
	
	local PluginDeviceXMLTable_EndIndex = #given_PluginDeviceXMLTable

	local increasing_PluginDeviceXMLTableStartIndex = 1

	local function updatePluginDeviceXMLTraversalRange(given_Index)
		increasing_PluginDeviceXMLTableStartIndex = given_Index
		--reaper.ShowConsoleMsg("\n                Traversal range of given_PluginDeviceXMLTable: start:"..increasing_PluginDeviceXMLTableStartIndex..", end:"..PluginDeviceXMLTable_EndIndex)	
	end--function updatePluginDeviceXMLTraversalRange
	
	
	------------------------------------------------------------
	--GET  <PluginDevice Id="#"><PluginDesc> XML
	------------------------------------------------------------
	
	local PluginDescTag_XMLTable

	for i=increasing_PluginDeviceXMLTableStartIndex,PluginDeviceXMLTable_EndIndex,1
	do
		if string.match(given_PluginDeviceXMLTable[i],'<PluginDesc>')
		then
			PluginDescTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_PluginDeviceXMLTable,	-- given_Table,
																		i,							-- given_StartTagIndex
																		'</PluginDesc>'				-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n                PluginDescTag_XMLTable indices:"..#PluginDescTag_XMLTable)
			--printTableToConsole(PluginDescTag_XMLTable,'PluginDescTag_XMLTable')-- given_Table,given_TableName
			updatePluginDeviceXMLTraversalRange(i)
			break --STOP the for loop when first occurrence of start is found
		end--if
	end--for  i
	
	
		---------------------------------------------
		-- GET PLUGIN <FileName Value="
		---------------------------------------------
		
		local Live_PluginFileNameValue = ''
		
		for j=1,#PluginDescTag_XMLTable,1
		do
			if string.match(PluginDescTag_XMLTable[j],'<FileName Value="')
			then			
				Live_PluginFileNameValue = getValueFrom_SingleLineXMLTag(PluginDescTag_XMLTable,j,'<FileName Value="','" />')		
				--reaper.ShowConsoleMsg("\n                Live_PluginFileNameValue:"..Live_PluginFileNameValue)
				break --STOP the for loop when first occurrence of start is found
			end--if
		end--for  i
		
		
		---------------------------------------------
		-- GET PLUGIN <PlugName Value="
		---------------------------------------------
		
		local Live_PluginPlugNameValue = ''
		
		for k=1,#PluginDescTag_XMLTable,1
		do
			if string.match(PluginDescTag_XMLTable[k],'<PlugName Value="')
			then
				Live_PluginPlugNameValue = getValueFrom_SingleLineXMLTag(PluginDescTag_XMLTable,k,'<PlugName Value="','" />')			
				--reaper.ShowConsoleMsg("\n                Live_PluginPlugNameValue:"..Live_PluginPlugNameValue)
				break --STOP the for loop when first occurrence of start is found
			end--if
		end--for  k
		
		
		---------------------------------------------
		-- GET PLUGIN <Preset> as a table
		---------------------------------------------
		
		local Live_PluginPresetXMLTable
		local currentPresetBufferTable = {}
		local Live_PluginPresetBinaryData = ''
		
	
		
		for ki=1,#PluginDescTag_XMLTable,1
		do
			if string.match(PluginDescTag_XMLTable[ki],'<Preset>')
			then
				Live_PluginPresetXMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_PluginDeviceXMLTable,	-- given_Table,
																			ki,							-- given_StartTagIndex
																			'</Preset>'					-- given_EndTag
																			)
				--reaper.ShowConsoleMsg("\n                Live_PluginPresetXMLTable indices:"..#Live_PluginPresetXMLTable)
				--printTableToConsole(Live_PluginPresetXMLTable,'Live_PluginPresetXMLTable')-- given_Table,given_TableName
		

                for xi=1,#Live_PluginPresetXMLTable,1
                do    
                    if string.match(Live_PluginPresetXMLTable[xi],'<VstPreset Id="')
                    then 
                        pluginIsVST = true
                        break  --out of this nested for loop
                    end--if
                end--for
        
        
        
                if pluginIsVST == true
                then 
                              
                    for kii=1,#Live_PluginPresetXMLTable,1
                    do

                        if string.match(Live_PluginPresetXMLTable[kii],'<Buffer>')
                        then
                            currentPresetBufferTable = makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag(
                                                                                        Live_PluginPresetXMLTable,	-- given_Table,
                                                                                        (kii+1),					-- given_StartTagIndex
                                                                                        '</Buffer>'					-- given_EndTag
                                                                                        )
                            --ShowConsoleMsg_and_AddtoLog("\n                currentPresetBufferTable indices:"..#currentPresetBufferTable)
                            --ShowConsoleMsg_and_AddtoLog(printTableToString(currentPresetBufferTable,'currentPresetBufferTable'))-- given_Table,given_TableName
                            break
                            
                        end--if
   
                    end--for kii=1,#Live_PluginPresetXMLTable,1

                    break --STOP the for loop when first occurrence of start is found   
               
               
                end--if pluginIsVST == true
               
			end--if string.match(PluginDescTag_XMLTable[ki],'<Preset>')
			
		end-- ki=1,#PluginDescTag_XMLTable,1
		
		
        
        if pluginIsVST == true
        then 
            
            if #currentPresetBufferTable > 0
            then
                for kj=1,#currentPresetBufferTable,1
                do
                    --ShowConsoleMsg_and_AddtoLog('\n'..currentPresetBufferTable[kj])
                    Live_PluginPresetBinaryData = Live_PluginPresetBinaryData..removeSpacesAndTabs(currentPresetBufferTable[kj])
                
                end--for
            end-- if #currentPresetBufferTable > 0
            

            --ShowConsoleMsg_and_AddtoLog('\n               Live_PluginPresetBinaryData:"'..Live_PluginPresetBinaryData..'"')
            
            Live_PluginPresetBinaryData = Live_PluginPresetBinaryData:convertHexToBytes()

            --ShowConsoleMsg_and_AddtoLog('\n               Live_PluginPresetBinaryData after converting to bytes:"'..Live_PluginPresetBinaryData..'"')
            
            Live_PluginPresetDataAsBase64 = convertToBase64(Live_PluginPresetBinaryData)
            
            --ShowConsoleMsg_and_AddtoLog('\n               Live_PluginPresetDataAsBase64:"'..Live_PluginPresetDataAsBase64)
		end--if
        
	--==========================================================================================================
	-- ADD PLUGIN BY NAME (WORKS IN MOST CASES, but sometimes Live and REAPER get different names from plugins)
	--==========================================================================================================
	
	-- REMEMBER! To get presets loaded, maybe try modifying track chunk after effects have been added?
	
	ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding plugin by name:"..Live_PluginPlugNameValue)
	
	reaper.TrackFX_AddByName(	given_RPRtrack,
								Live_PluginPlugNameValue,
								false,
								-1)    -- -1 = always create new, 0 = only query first instance, 1 = add one if not found
	

	--======================================================================
	-- IF PLUGIN DID NOT LOAD BY NAME, TRY LOADING BY NAME of its .dll file
	--======================================================================
	
	--get plugin name to see if it was found
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	--reaper.ShowConsoleMsg("\npluginNameForChecking:"..pluginNameForChecking)
	
	
	
	if pluginNameForChecking == ""
	then
		ShowConsoleMsg_and_AddtoLog("\n    pluginNameForChecking:empty; plugin not loaded, trying to add by FileName: "..Live_PluginFileNameValue)
		
		reaper.TrackFX_AddByName(	given_RPRtrack,
									Live_PluginFileNameValue,
									false,
									-1)    -- -1 = always create new, 0 = only query first instance, 1 = add one if not found
		
	end--if
	
	
	-------------------------------------------------
	-- IF PLUGIN STILL DID NOT LOAD, LOG THE FAILURE
	-------------------------------------------------
	
	--get plugin name to see if it was found
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking == ""
	then
		ShowConsoleMsg_and_AddtoLog("\nCould not load plugin "
		..currentFXindex.." of this chain. PlugName and FileName from Live file: "
		..Live_PluginPlugNameValue..","..Live_PluginFileNameValue)
	
	end--if



	--------------------------------------------------------
	-- CONTINUE ONLY IF PLUGIN LOADED
	--------------------------------------------------------
	
	--get plugin name
	local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
	
	if pluginNameForChecking ~= ""
	then
	
		ShowConsoleMsg_and_AddtoLog(' (verification: Plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')
		--reaper.ShowConsoleMsg(' Live_PluginPresetXMLTable indices:'..#Live_PluginPresetXMLTable)
        
        
        
        ------------------------------------------------------------
		-- LOAD PLUGIN DATA (Live_PluginPresetDataAsBase64)
		------------------------------------------------------------
        if pluginIsVST == true
        then 
        
        -- reaper.TrackFX_SetNamedConfigParm(MediaTrack track, integer fx, string parmname, string value)

        reaper.TrackFX_SetNamedConfigParm(given_RPRtrack,currentFXindex,'vst_chunk',Live_PluginPresetDataAsBase64)
        
        ShowConsoleMsg_and_AddtoLog('\n Applied VST preset data to "'..pluginNameForChecking..'"')
        
        end--if


        

		------------------------------------------------------------
		--GET  <PluginDevice Id="#"><ParameterList> XML
		------------------------------------------------------------
		
		local ParameterListTag_XMLTable

		for l=increasing_PluginDeviceXMLTableStartIndex,PluginDeviceXMLTable_EndIndex,1
		do
			if string.match(given_PluginDeviceXMLTable[l],'<ParameterList>')
			then
			
				ParameterListTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_PluginDeviceXMLTable,	-- given_Table,
																			l,								-- given_StartTagIndex
																			'</ParameterList>'				-- given_EndTag
																			)
																			
				
				--reaper.ShowConsoleMsg("\n            ParameterListTag_XMLTable indices:"..#ParameterListTag_XMLTable)
				--printTableToConsole(ParameterListTag_XMLTable,'ParameterListTag_XMLTable')-- given_Table,given_TableName
				
				updatePluginDeviceXMLTraversalRange(l)
				
				break --STOP the for loop when first occurrence of start is found
			end--if
		end--for  l
	
	
		-----------------------------------------------------------------------------------
		-- MAKE TABLE of <PluginFloatParameter Id="#"> indices in ParameterListTag_XMLTable
		------------------------------------------------------------------------------------
	
		local PluginFloatParameterTagStartIndices_XMLTable = {}
		
		for m=1,#ParameterListTag_XMLTable,1
		do	
			if string.match(ParameterListTag_XMLTable[m],'<PluginFloatParameter Id="')
			then
				
				table.insert(PluginFloatParameterTagStartIndices_XMLTable,m)
				--reaper.ShowConsoleMsg('\n            Found <PluginFloatParameter Id=" tag at index:'..m..' of ParameterListTag_XMLTable')
				
			end--if
			
		end--for m
		
		--reaper.ShowConsoleMsg("\n                PluginFloatParameterTagStartIndices_XMLTable indices:"..#PluginFloatParameterTagStartIndices_XMLTable)
	
	
		-------------------------------------------------------------------------------------
		-- FOR EACH <PluginFloatParameter Id="#">
		-- GET <PluginFloatParameter Id="#"> to </PluginFloatParameter> contents as table
		-------------------------------------------------------------------------------------
		
		for n=1,#PluginFloatParameterTagStartIndices_XMLTable,1
		do	
			local PluginFloatParameterTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		ParameterListTag_XMLTable,						-- given_Table,
																		PluginFloatParameterTagStartIndices_XMLTable[n],-- given_StartTagIndex
																		'</PluginFloatParameter>'						-- given_EndTag
																		)
			
			--reaper.ShowConsoleMsg("\n                PluginFloatParameterTag_XMLTable indices:"..#PluginFloatParameterTag_XMLTable)	
		
			useDataFrom_PluginFloatParameter_XMLTable(
													currentFXindex,			-- given_FXPluginIndex
													PluginFloatParameterTag_XMLTable,	-- given_PluginFloatParameterXMLTable
													given_RPRtrack,					-- given_RPRtrack
													given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
													)

		end--for n=1,#PluginFloatParameterTagStartIndices_XMLTable,1




		--------------------------------------------------------
		-- SET FX BYPASS STATE from its <On> tag in Live
		--------------------------------------------------------
	
		local FXOn_ManVal, FXOn_AuTargId = get_ManVal_AuTargId_from_ContTagInXMLTable(given_PluginDeviceXMLTable,'<On>')
		local BypassParNum = getFXSlotBypassParameterNumber(given_RPRtrack,currentFXindex)
		if FXOn_ManVal == 'false' then reaper.TrackFX_SetParam(given_RPRtrack,currentFXindex,BypassParNum,1) ShowConsoleMsg_and_AddtoLog(' BYPASSED') end
		checkAndAdd_FXPlugEnv_by_AuTargId_and_FXParNum(given_RPRtrack,currentFXindex,FXOn_AuTargId,BypassParNum,given_AutomationEnvelopesXMLTable,'')
	
		--------------------------------------------------------
		-- INCREMENT PLUGIN INDEX
		--------------------------------------------------------
	
		currentFXindex = currentFXindex+1
	
		
	end--if pluginNameForChecking ~= ""

end--function useDataFrom_PluginDeviceXMLTable









--*********************************************************
-- useDataFrom_LiveDevice_OriginalSimpler_XMLTable
--*********************************************************
function useDataFrom_LiveDevice_OriginalSimpler_XMLTable(
								given_PluginDeviceXMLTable,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)
								
								
	if checkIfTrackIs_SIDECHAIN_CLICK(given_RPRtrack) ~= true
	then
		
		--==========================================================================================================
		-- ADD ReaSamplOmatic5000
		--==========================================================================================================

		ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaSamplOmatic5000 as substitute for Simpler")
		
		reaper.TrackFX_AddByName(	given_RPRtrack, 
									'ReaSamplOmatic5000 (Cockos)',
									false,
									-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


		--------------------------------------------------------
		-- CONTINUE ONLY IF PLUGIN LOADED
		--------------------------------------------------------
		
		--get plugin name
		local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
		
		if pluginNameForChecking == ""
		then
			ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin")
		end--if
		
		
		if pluginNameForChecking ~= ""
		then
			ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')
			
			
			--------------------------------------------------------
			-- INCREMENT PLUGIN INDEX
			--------------------------------------------------------
		
			currentFXindex = currentFXindex+1
			
			
		end--if
		
	end--if checkIfTrackIs_SIDECHAIN_CLICK
	
end--function useDataFrom_LiveDevice_OriginalSimpler_XMLTable









--*********************************************************
-- useDataFrom_LiveDevice_MultiSampler_XMLTable
--*********************************************************
function useDataFrom_LiveDevice_MultiSampler_XMLTable(
								given_PluginDeviceXMLTable,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)
								
								
								
	if checkIfTrackIs_SIDECHAIN_CLICK(given_RPRtrack) ~= true
	then
		
		--==========================================================================================================
		-- ADD ReaSamplOmatic5000
		--==========================================================================================================

		ShowConsoleMsg_and_AddtoLog("\n        FX "..currentFXindex..": Adding ReaSamplOmatic5000 as substitute for Simpler")
		
		reaper.TrackFX_AddByName(	given_RPRtrack, 
									'ReaSamplOmatic5000 (Cockos)',
									false,
									-1)   -- -1 = always create new, 0 = only query first instance, 1 = add one if not found


		--------------------------------------------------------
		-- CONTINUE ONLY IF PLUGIN LOADED
		--------------------------------------------------------
		
		--get plugin name
		local retval, pluginNameForChecking = reaper.TrackFX_GetFXName(given_RPRtrack,currentFXindex,64)
		
		if pluginNameForChecking == ""
		then
			ShowConsoleMsg_and_AddtoLog("\nWARNING: Could not load plugin")
		end--if
		
		
		if pluginNameForChecking ~= ""
		then
			ShowConsoleMsg_and_AddtoLog(' (verification: plugin '..currentFXindex..' is "'..pluginNameForChecking..'")')
			
			
			--------------------------------------------------------
			-- INCREMENT PLUGIN INDEX
			--------------------------------------------------------
		
			currentFXindex = currentFXindex+1
			
			
		end--if
		
	end--if checkIfTrackIs_SIDECHAIN_CLICK
		
		

end--function useDataFrom_LiveDevice_MultiSampler_XMLTable










--*********************************************************
-- useDataFrom_INNER_DeviceChainXMLTable
--*********************************************************


-- INITIALIZE GLOBAL plugin index in FX chain
currentFXindex = 0


function useDataFrom_INNER_DeviceChainXMLTable(
										given_INNER_DeviceChainXMLTable,
										given_RPRtrack,
										given_AutomationEnvelopesXMLTable
										)

	----------------------------------------
	-- RESET DEVICE NUMBER in FX CHAIN
	----------------------------------------
	currentFXindex = 0

	---------------------------------------------------------------------
	-- FOR EACH PLUGIN DEVICE, PASS ON ITS XML table to its own function
	---------------------------------------------------------------------

	for j=1,#given_INNER_DeviceChainXMLTable,1
	do	
		-- PASS ON external plugins (<PluginDevice Id=)
		if string.match(given_INNER_DeviceChainXMLTable[j],'<PluginDevice Id="')
		then
			local PluginDeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</PluginDevice>'					-- given_EndTag
																			)
			useDataFrom_PluginDeviceXMLTable(
				PluginDeviceTag_XMLTable,			-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)	
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<OriginalSimpler Id="')
		then
			local OriginalSimpler_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</OriginalSimpler>'					-- given_EndTag
																			)
			useDataFrom_LiveDevice_OriginalSimpler_XMLTable(
				OriginalSimpler_DeviceTag_XMLTable,	-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<MultiSampler Id="')
		then
			local MultiSampler_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</MultiSampler>'					-- given_EndTag
																			)
			useDataFrom_LiveDevice_MultiSampler_XMLTable(
				MultiSampler_DeviceTag_XMLTable,	-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<Eq8 Id="')
		then
			local Eq8_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</Eq8>'							-- given_EndTag
																			)
			useDataFrom_LiveDevice_Eq8_XMLTable2(
				Eq8_DeviceTag_XMLTable,				-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<AutoFilter Id="')
		then
			local AutoFilter_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</AutoFilter>'						-- given_EndTag
																			)
			useDataFrom_LiveDevice_AutoFilter_XMLTable(
				AutoFilter_DeviceTag_XMLTable,			-- given_PluginDeviceXMLTable,
				given_RPRtrack,							-- given_RPRtrack
				given_AutomationEnvelopesXMLTable		-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<Compressor2 Id="')
		then
			local Compressor2_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</Compressor2>'					-- given_EndTag
																			)
			useDataFrom_LiveDevice_Compressor_XMLTable(
				Compressor2_DeviceTag_XMLTable,				-- given_PluginDeviceXMLTable,
				given_RPRtrack,							-- given_RPRtrack
				given_AutomationEnvelopesXMLTable			-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<Gate Id="')
		then
			local Gate_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</Gate>'							-- given_EndTag
																			)
			useDataFrom_LiveDevice_Gate_XMLTable(
				Gate_DeviceTag_XMLTable,				-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable		-- given_AutomationEnvelopesXMLTable
				)
		end--if
		
		
		if string.match(given_INNER_DeviceChainXMLTable[j],'<PingPongDelay Id="')
		then
			local PingPongDelay_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</PingPongDelay>'					-- given_EndTag
																			)
			useDataFrom_LiveDevice_PingPongDelay_XMLTable(
				PingPongDelay_DeviceTag_XMLTable,		-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable		-- given_AutomationEnvelopesXMLTable
				)
		end--if		
		


		-- <CrossDelay Id=" (Simple Delay)
		if string.match(given_INNER_DeviceChainXMLTable[j],'<CrossDelay Id="')
		then
			local CrossDelay_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</CrossDelay>'						-- given_EndTag
																			)
			useDataFrom_LiveDevice_SimpleDelay_XMLTable(
				CrossDelay_DeviceTag_XMLTable,		-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)
		end--if		
		
		
		-- <Reverb Id="
		if string.match(given_INNER_DeviceChainXMLTable[j],'<Reverb Id="')
		then
			local Reverb_DeviceTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_INNER_DeviceChainXMLTable,	-- given_Table,
																			j,									-- given_StartTagIndex
																			'</Reverb>'							-- given_EndTag
																			)
			useDataFrom_LiveDevice_Reverb_XMLTable(
				Reverb_DeviceTag_XMLTable,			-- given_PluginDeviceXMLTable,
				given_RPRtrack,						-- given_RPRtrack
				given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
				)
		end--if	--]]	
		
		

	end--for j=1,#PluginDeviceTagStartIndices_XMLTable,1

	
end--useDataFrom_INNER_DeviceChainXMLTable









function useDataFrom_TrackEnvelopeXMLTable(
								given_TrackEnvelopeXMLTable,
								given_TrackEnvelopeChunkName,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)
								
								
	-------------------------------------------
	-- search for <AutomationTarget Id="#####">
	-------------------------------------------
	
	local TrackEnvelope_AutomationTarget_Id = ''
	
	for c=1,#given_TrackEnvelopeXMLTable,1
	do
		if string.match(given_TrackEnvelopeXMLTable[c],'<AutomationTarget Id="')
		then
			TrackEnvelope_AutomationTarget_Id = getValueFrom_SingleLineXMLTag(given_TrackEnvelopeXMLTable,c,'<AutomationTarget Id="','">')	
			--reaper.ShowConsoleMsg("\n                TrackEnvelope_AutomationTarget_Id:"..TrackEnvelope_AutomationTarget_Id)
			break --STOP the for loop when first occurrence of start is found
		end--if
	
	end--for	
	
	
	------------------------------------------------------------------------------------------
	--- GO THROUGH given_AutomationEnvelopesXMLTable to find envelopes for this parameter
	------------------------------------------------------------------------------------------

	for i=1,#given_AutomationEnvelopesXMLTable,1
	do
		if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
		then
			local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AutomationEnvelopesXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AutomationEnvelope>'				-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n                AutomationEnvelope_XMLTable indices:"..#AutomationEnvelope_XMLTable)
		
		
			local currentEnvelope_PointeeId = ''

			for j=1,#AutomationEnvelope_XMLTable,1
			do
				if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
				then
					currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
					--reaper.ShowConsoleMsg("\n                currentEnvelope_PointeeId:"..currentEnvelope_PointeeId)
					
					break--enclosing for loop
					
				end--if
			end--for j=1,#AutomationEnvelope_XMLTable,1
			
			
			--------------------------------------------------------------------------
			-- IF AutomationEnvelopes section has an envelope for this parameter
			--------------------------------------------------------------------------
			if currentEnvelope_PointeeId == TrackEnvelope_AutomationTarget_Id
			then 
			
				--reaper.ShowConsoleMsg("\n        Found automated track envelope for:"..given_TrackEnvelopeChunkName..", PointeeIdTag_contents:"..currentEnvelope_PointeeId..", given_AutomationTargetId:"..TrackEnvelope_AutomationTarget_Id)


				--[[------------------------------------------------
			
				VOLUME VALUES TRANSLATION
				
				----------------------------------------------------
				  dB		Live				REAPER
				----------------------------------------------------
				 +6 dB	=	1.99526238			1.99526231
				  0 db 	= 	1					1
				-12 dB	=	0.251188606			0.25118864
				-24 dB	=	0.06309572607		0.06309573				
				-36 dB	= 	0.01584892906		0.01584893
				-48 dB	=	0.003981071059		0.00398107
				-60 dB	=	0.001000000047		0.001
				
				--------------------------------------------------]]
					
					
				--================================================================
				-- ADD TRACK ENVELOPE
				--================================================================
				
				local newEnvelope = reaper.GetTrackEnvelopeByChunkName(given_RPRtrack,given_TrackEnvelopeChunkName)
				
				local newEnvelopeScalingMode = reaper.GetEnvelopeScalingMode(newEnvelope)
				--reaper.ShowConsoleMsg("\n        newEnvelopeScalingMode:"..tostring(newEnvelopeScalingMode))

				ShowConsoleMsg_and_AddtoLog('\n        ENVELOPE added for track '..currentTrackIndex..': '..given_TrackEnvelopeChunkName
				--..", newEnvelope:"..tostring(newEnvelope)
				)
				
				--retval, newEnvelopeStateChunk = reaper.GetEnvelopeStateChunk(newEnvelope,"",false)
				--reaper.ShowConsoleMsg("\n\nnewEnvelopeStateChunk:"..newEnvelopeStateChunk.."\n")
				-- set bypass state to active
				--newEnvelopeStateChunk=string.gsub(newEnvelopeStateChunk,'ACT 0 -1','ACT 1 -1')
				--reaper.SetEnvelopeStateChunk(newEnvelope,newEnvelopeStateChunk,true)


				------------------------------------------------------------------
				-- GET AND INSERT ENVELOPE POINTS
				------------------------------------------------------------------
				
				local previousEventTime = 0
				
				for k=1,#AutomationEnvelope_XMLTable,1
				do
					
					if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					then
						
						local current_FloatEventTag_contents = tostring(AutomationEnvelope_XMLTable[k])

						local Event_Time = string.sub(
						current_FloatEventTag_contents,
						string.find(current_FloatEventTag_contents,'Time="')+6,
						string.find(current_FloatEventTag_contents,'" Value=')-1
						)
						if Event_Time == '-63072000' then Event_Time = 0 end
						Event_Time = tonumber(Event_Time)
						
						-- ENSURE THAT SQUARE-LIKE SHAPES ARE RETAINED
						if Event_Time == previousEventTime then Event_Time = (Event_Time * 1.0000001) end 
						--reaper.ShowConsoleMsg("\n    Event_Time:"..Event_Time)
						
						-- add point in REAPER only if time value is positive
						if Event_Time > -1
						then
						
							EventTime_inReaperTime = reaper.TimeMap2_beatsToTime(0,Event_Time)
						
							local Event_Value = string.sub(
							current_FloatEventTag_contents,
							string.find(current_FloatEventTag_contents,'Value="')+7,
							string.find(current_FloatEventTag_contents,'" />')-1
							)
							--reaper.ShowConsoleMsg("\n    Event_Value:"..Event_Value)
							
							-- IF  CurveControl found, CUT IT OFF
							if string.match(Event_Value,'CurveControl')
							then
								Event_Value = string.sub(Event_Value,
														1,
														string.find(Event_Value,'" CurveControl')-1
														)
							end
							--reaper.ShowConsoleMsg("\n    Event_Value:"..Event_Value)
							
							Event_Value = tonumber(Event_Value)
							
							--scale volume values
							if newEnvelopeScalingMode == 1
							then
								Event_Value = reaper.ScaleToEnvelopeMode(1,Event_Value)
							end
							
							
							--================================================================
							-- ADD TRACK ENVELOPE POINT
							--================================================================
							
							--reaper.ShowConsoleMsg("\n    Point attributes: time:"..EventTime_inReaperTime..", value:"..Event_Value)
							
							reaper.InsertEnvelopePoint(
												newEnvelope,
												EventTime_inReaperTime,
												Event_Value,
												0,
												0,
												0,
												1
												)
												
							previousEventTime = Event_Time
						
						end--if Event_Time > -1
			
			
					end--if string.match(AutomationEnvelope_XMLTable[k],'<FloatEvent Id="')
					
				
				end--for k=1,#AutomationEnvelope_XMLTable,1


				------------------------------------------------------------------
				-- SORT ENVELOPE POINTS (AFTER ALL POINTS ARE ADDED)
				------------------------------------------------------------------

				reaper.Envelope_SortPoints(newEnvelope)


				------------------------------------------------------------------
				-- SET ENVELOPE VISIBLE
				------------------------------------------------------------------
				
				--[[
				
				-- ! ! ! -----------------------------------------------------------------------------------------
				-- NOTE: this, for some reason, forcedly sets the envelope bypassed despite changing active chunk
				-- TRY INSTEAD: native REAPER action for showing all envelopes of the track
				---------------------------------------------------------------------------------------------------
				
				retval, newEnvelopeStateChunk = reaper.GetEnvelopeStateChunk(newEnvelope,"",false)
				--reaper.ShowConsoleMsg("\n\nnewEnvelopeStateChunk:"..newEnvelopeStateChunk.."\n")
				
				-- set bypass state to active
				newEnvelopeStateChunk=string.gsub(newEnvelopeStateChunk,'ACT 0 -1','ACT 1 -1')
				
				--set envelope visible
				newEnvelopeStateChunk=string.gsub(newEnvelopeStateChunk,'VIS 0 1 1','VIS 1 1 1')
				--reaper.ShowConsoleMsg("\n\nnewEnvelopeStateChunk:"..newEnvelopeStateChunk.."\n")
				reaper.SetEnvelopeStateChunk(newEnvelope,newEnvelopeStateChunk,true)
				
				--]]


			end -- if currentEnvelope_PointeeId == Live_AutomationTarget_Id

		end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
	
	end--for i=1,#given_AutomationEnvelopesXMLTable,1


end--function useDataFrom_TrackEnvelopeXMLTable







--*********************************************************
-- useDataFrom_SendsXMLTable
--*********************************************************

function useDataFrom_SendsXMLTable(
								given_SendsTag_XMLTable,
								given_RPRtrack,
								given_AutomationEnvelopesXMLTable
								)

	local retval, currentREAPERtrack_name = reaper.GetTrackName(given_RPRtrack,'')

	--reaper.ShowConsoleMsg('\n        given_SendsTag_XMLTable indices:'..#given_SendsTag_XMLTable)

	---------------------------------------------
	-- GET TAGS <Sends><TrackSendHolder Id="
	---------------------------------------------
	
	local ThisTracksSendsTable = {}
	
	
	for f=1,#given_SendsTag_XMLTable,1
	do
	
		if string.match(given_SendsTag_XMLTable[f],'<TrackSendHolder Id="')
		then
			local Live_TrackSendHolderId = getValueFrom_SingleLineXMLTag(given_SendsTag_XMLTable,f,'<TrackSendHolder Id="','">')
			Live_TrackSendHolderId = tonumber(Live_TrackSendHolderId)
			
			local TrackSendHolder_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
														given_SendsTag_XMLTable,	-- given_Table,
														f,							-- given_StartTagIndex
														'</TrackSendHolder>'		-- given_EndTag
														)
			
		
			------------------------------------------------
			-- GET <Manual Value= and <AutomationTarget Id="
			------------------------------------------------
			
			local Live_SendManualValue
			local Live_SendAutomationTargetId
			
			for g=1,#TrackSendHolder_XMLTable,1
			do
				if string.match(TrackSendHolder_XMLTable[g],'<Manual Value="')
				then
					Live_SendManualValue = getValueFrom_SingleLineXMLTag(TrackSendHolder_XMLTable,g,'<Manual Value="','" />')
					Live_SendManualValue = tonumber(Live_SendManualValue)					
				end--if

				if string.match(TrackSendHolder_XMLTable[g],'<AutomationTarget Id="')
				then
					Live_SendAutomationTargetId = getValueFrom_SingleLineXMLTag(TrackSendHolder_XMLTable,g,'<AutomationTarget Id="','">')				
					
					break--enclosing for loop
					
				end--if
				
			end--for  g
			
			
			--------------------------------------
			-- CHECK FOR AUTOMATION
			--------------------------------------
			
			local passedAutomationEnvelope_XMLTable = {}

			for i=1,#given_AutomationEnvelopesXMLTable,1
			do
				if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
				then
					local AutomationEnvelope_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																				given_AutomationEnvelopesXMLTable,	-- given_Table,
																				i,									-- given_StartTagIndex
																				'</AutomationEnvelope>'				-- given_EndTag
																				)
																				
					--reaper.ShowConsoleMsg("\n                AutomationEnvelope_XMLTable indices:"..#AutomationEnvelope_XMLTable)
				
					for j=1,#AutomationEnvelope_XMLTable,1
					do
						if string.match(AutomationEnvelope_XMLTable[j],'<PointeeId Value="')
						then
							local currentEnvelope_PointeeId = getValueFrom_SingleLineXMLTag(AutomationEnvelope_XMLTable,j,'<PointeeId Value="','" />')	
							--reaper.ShowConsoleMsg("\n                currentEnvelope_PointeeId:"..currentEnvelope_PointeeId)
							
							if currentEnvelope_PointeeId == Live_SendAutomationTargetId
							then
								passedAutomationEnvelope_XMLTable = AutomationEnvelope_XMLTable
							end--if
							
							break--enclosing for loop
							
						end--if
					end--for j=1,#AutomationEnvelope_XMLTable,1
					
				end--if string.match(given_AutomationEnvelopesXMLTable[i],'<AutomationEnvelope Id="')
			
			end--for i=1,#given_AutomationEnvelopesXMLTable,1
			
			
			-----------------------------------------------------------------------------
			-- MAKE TABLE TO BE NESTED into MAIN TRACK_SENDS_TO_RETURNS_TABLE[currentTrackIndex] 
			------------------------------------------------------------------------------
			local ThisSendsDataTable =  {
			currentREAPERtrack_name,			--SOURCE TRACK
			Live_TrackSendHolderId,				-- <TrackSendHolder Id="#">, in Live should be strictly ordered starting from 0
			Live_SendManualValue,				--MANUAL VALUE
			Live_SendAutomationTargetId,		--Automation Target ID
			passedAutomationEnvelope_XMLTable	-- passedAutomationEnvelope_XMLTable
			}
			
			ThisTracksSendsTable[Live_TrackSendHolderId] = ThisSendsDataTable
										
		end--if string.match(given_SendsTag_XMLTable[f],'<TrackSendHolder Id="')
		
	end--for  f

	TRACK_SENDS_TO_RETURNS_TABLE[currentTrackIndex] = ThisTracksSendsTable

end-- useDataFrom_SendsXMLTable()








--*********************************************************
-- useDataFrom_MixerXMLTable
--*********************************************************

function useDataFrom_MixerXMLTable(
						given_MixerXMLTable,
						given_RPRtrack,
						given_AutomationEnvelopesXMLTable,
						given_TrackType
						)
						
	--printTableToConsole(given_MixerXMLTable,'given_MixerXMLTable')-- given_Table,given_TableName

	

	local MixerXMLTable_EndIndex = #given_MixerXMLTable
	local decreasing_MixerXMLTableStartIndex = 1
	
	local function updateMixerXMLTableTraversalRange(given_Index)
		decreasing_MixerXMLTableStartIndex = given_Index
		--reaper.ShowConsoleMsg("\n                Traversal range of given_MixerXMLTable: start:"..decreasing_MixerXMLTableStartIndex..", end:"..MixerXMLTable_EndIndex)
	end--function updateMixerXMLTableTraversalRange
	
	
	------------------------------------------------------------
	-- GET <Sends> XML as a table
	------------------------------------------------------------
	local Live_SendsTag_XMLTable
	
	--DON'T do this for RETURNs themselves nor MASTER
	if given_TrackType ~= 'RETURN' and given_TrackType ~= 'MASTER' 
	then
		for e=decreasing_MixerXMLTableStartIndex,MixerXMLTable_EndIndex,1
		do

			if string.match(given_MixerXMLTable[e],'<Sends>')
			then
			
				Live_SendsTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_MixerXMLTable,	-- given_Table,
																			e,						-- given_StartTagIndex
																			'</Sends>'				-- given_EndTag
																			)
				updateMixerXMLTableTraversalRange(e)
				

				--===========================================================
				-- PASS Live_SendsTag_XMLTable to its own function
				--===========================================================		

				useDataFrom_SendsXMLTable(
								Live_SendsTag_XMLTable,				-- given_SendsTag_XMLTable,
								given_RPRtrack,					-- given_RPRtrack,
								given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
								)
				
				break --breaks enclosing for
			end--if string.match(given_MixerXMLTable[e],'<Sends>')
			
		end-- for e=decreasing_MixerXMLTableStartIndex,MixerXMLTable_EndIndex,1
		
	end--if given_TrackType ~= 'RETURN'

	
	------------------------------------------------------------
	-- GET <Speaker> XML as a table
	-- get <Speaker><Manual Value="
	------------------------------------------------------------
	
	local Live_SpeakerTag_XMLTable
	local Live_SpeakerManualValue = ''

	for i=decreasing_MixerXMLTableStartIndex,MixerXMLTable_EndIndex,1
	do
		if string.match(given_MixerXMLTable[i],'<Speaker>')
		then
		
			Live_SpeakerTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MixerXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</Speaker>'			-- given_EndTag
																		)
			updateMixerXMLTableTraversalRange(i)
			
			
			---------------------------------------------
			-- GET <Speaker><Manual Value="
			---------------------------------------------

			for j=1,#Live_SpeakerTag_XMLTable,1
			do
				if string.match(Live_SpeakerTag_XMLTable[j],'<Manual Value="')
				then
					Live_SpeakerManualValue = getValueFrom_SingleLineXMLTag(Live_SpeakerTag_XMLTable,j,'<Manual Value="','" />')			
					--reaper.ShowConsoleMsg('\n                Live_SpeakerManualValue:'..Live_SpeakerManualValue)
					break
				end--if
			end--for  j
			
			
			-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			-- NOTE: MUTE ENVELOPE NOT PASSED to REAPER, 
			-- MAY BE IMPLEMENTED LATER IF NEEDED, as REAPER does have a Mute envelope
			
			
			break --STOP the for loop when first occurrence of start is found
		end--if
	end--for  i


	------------------------------------------------------------
	-- GET <Pan> XML as a table
	-- get <Pan><Manual Value="
	------------------------------------------------------------
	
	local Live_PanTag_XMLTable
	local Live_PanManualValue

	for k=decreasing_MixerXMLTableStartIndex,MixerXMLTable_EndIndex,1
	do
		if string.match(given_MixerXMLTable[k],'<Pan>')
		then

			Live_PanTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MixerXMLTable,	-- given_Table,
																		k,						-- given_StartTagIndex
																		'</Pan>'				-- given_EndTag
																		)
			--printTableToConsole(Live_PanTag_XMLTable,'Live_PanTag_XMLTable')-- given_Table,given_TableName
			updateMixerXMLTableTraversalRange(k)
			
			---------------------------------------------
			-- GET <Pan><Manual Value="
			---------------------------------------------
		
			for l=1,#Live_PanTag_XMLTable,1
			do
				if string.match(Live_PanTag_XMLTable[l],'<Manual Value="')
				then
					Live_PanManualValue = getValueFrom_SingleLineXMLTag(Live_PanTag_XMLTable,l,'<Manual Value="','" />')			
					--reaper.ShowConsoleMsg('\n                Live_PanManualValue:'..Live_PanManualValue)
					break
				end--if
			end--for  l
			
			
						
			--===========================================================
			-- PASS Live_PanTag_XMLTable to track envelope function
			--===========================================================
			
			useDataFrom_TrackEnvelopeXMLTable(
								Live_PanTag_XMLTable,				-- given_TrackEnvelopeXMLTable,
								'<PANENV2',							-- given_TrackEnvelopeChunkName,
								given_RPRtrack,					-- given_RPRtrack,
								given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
								)
			
			
			
			
			break --STOP the for loop when first occurrence of start is found
		end--if
	end--for  j


	------------------------------------------------------------
	-- GET <Volume> XML as a table
	-- get <Volume> <Manual Value="
	------------------------------------------------------------
	
	local Live_VolumeTag_XMLTable
	local Live_VolumeManualValue
			
	for m=decreasing_MixerXMLTableStartIndex,#given_MixerXMLTable,1
	do
		if string.match(given_MixerXMLTable[m],'<Volume>')
		then
			Live_VolumeTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MixerXMLTable,	-- given_Table,
																		m,						-- given_StartTagIndex
																		'</Volume>'				-- given_EndTag
																		)
			--printTableToConsole(Live_VolumeTag_XMLTable,'Live_VolumeTag_XMLTable')-- given_Table,given_TableName
			updateMixerXMLTableTraversalRange(m)
			
			
			---------------------------------------------
			-- GET <Volume><Manual Value="
			---------------------------------------------

			for n=1,#Live_VolumeTag_XMLTable,1
			do
				if string.match(Live_VolumeTag_XMLTable[n],'<Manual Value="')
				then
					Live_VolumeManualValue = getValueFrom_SingleLineXMLTag(Live_VolumeTag_XMLTable,n,'<Manual Value="','" />')			
					--reaper.ShowConsoleMsg('\n                Live_VolumeManualValue:'..Live_VolumeManualValue)
					break
				end--if
			end--for  n
			
			
			--===========================================================
			-- PASS Live_VolumeTag_XMLTable to track envelope function
			--===========================================================
			
			useDataFrom_TrackEnvelopeXMLTable(
								Live_VolumeTag_XMLTable,			-- given_TrackEnvelopeXMLTable,
								'<VOLENV3',	--given_TrackEnvelopeChunkName; '<VOLENV' = volume (Pre-FX), '<VOLENV2' = volume, '<VOLENV3' = Trim Volume
								given_RPRtrack,					-- given_RPRtrack,
								given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
								)
			
			
			
			break --STOP the for loop when first occurrence of start is found
		end--if
		
	end--for  m




	--===========================================
	-- SET MANUAL MUTE VALUE
	--===========================================
	
	-- note: assumes that default MUTESOLO string is "MUTESOLO 0 0 0"

	if Live_SpeakerManualValue == 'false'
	then
		local newMUTESOLOstring = 'MUTESOLO 1 0 0'
	
		-- NOTE: intentionally global
		retval, stateChunkOfCurrentTrack =  reaper.GetTrackStateChunk(given_RPRtrack,"",false)
		-- note: in Lua, dash "-" needs to be escaped "%-1" when matching strings for replacing them
		stateChunkOfCurrentTrack=string.gsub(stateChunkOfCurrentTrack,"MUTESOLO 0 0 0",newMUTESOLOstring)
		reaper.SetTrackStateChunk(given_RPRtrack,stateChunkOfCurrentTrack,false)
	end


	--===========================================
	-- SET VOLUME AND PAN VALUE
	--===========================================
		
	-- note: assumes that default VOLPAN string is "VOLPAN 1 0 -1 -1 1"	
	
	local newVOLPANstring = 'VOLPAN '..Live_VolumeManualValue.." "..Live_PanManualValue..' -1 -1 1'
	retval, stateChunkOfCurrentTrack =  reaper.GetTrackStateChunk(given_RPRtrack,"",false)

	-- REMEMBER! in Lua, dash "-" needs to be escaped "%-1" when matching strings for replacing them!
	stateChunkOfCurrentTrack=string.gsub(stateChunkOfCurrentTrack,"VOLPAN 1 0 %-1 %-1 1",newVOLPANstring)
	reaper.SetTrackStateChunk(given_RPRtrack,stateChunkOfCurrentTrack,false)
	
	--[[
	-- for checking only
	retval, stateChunkOfCurrentTrack =  reaper.GetTrackStateChunk(given_RPRtrack,"",false)
	reaper.ShowConsoleMsg("\nstateChunkOfCurrentTrack:\n"..stateChunkOfCurrentTrack.."\n")
	--]]
	

end--function useDataFrom_MixerXMLTable








--*********************************************************
-- useDataFrom_KeyTracksXMLTable
--*********************************************************

function useDataFrom_KeyTracksXMLTable(
							given_KeyTracksXMLTable,
							given_REAPERCurrentTake,
							given_Live_MIDILoopLength_InQN,
							given_MIDI_ManualStartOffset_InQN,
							given_MIDI_MoveEventsBackBy_InQN				-- this is subtracted from event time
							)

	-----------------------------------------------------------------
	-- for <KeyTrack Id=" in table LiveMidiClip_KeyTracksXMLTable
	------------------------------------------------------------------
	local ManualStartOffset_InPPQ = math.floor((given_MIDI_ManualStartOffset_InQN*ticksPerQuarterNote)+0.5)
	local MIDI_MoveEventsBackBy_InPPQ = math.floor((given_MIDI_MoveEventsBackBy_InQN*ticksPerQuarterNote)+0.5)
	
	if ManualStartOffset_InPPQ > -1
	then
		ShowConsoleMsg_and_AddtoLog("\nNOTE INSERTION, ManualStartOffset_InPPQ:"..ManualStartOffset_InPPQ)
	end
	
	local IntendedEndOfLoop_InPPQ = math.floor((given_Live_MIDILoopLength_InQN*ticksPerQuarterNote)+0.5)
	
	for i=1,#given_KeyTracksXMLTable,1
	do
		if string.match(given_KeyTracksXMLTable[i],'<KeyTrack Id="')
		then
			local currentKeyTrackTagTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_KeyTracksXMLTable,	-- given_Table,
																		i,							-- given_StartTagIndex
																		'</KeyTrack>'				-- given_EndTag
																		)
			
			local currentMIDInote_OnTime = 0
			local currentMIDInote_Duration = 0
			local currentMIDInote_OnVelocity = 0
			local currentMIDInote_OffVelocity = 0
			local currentMIDInote_IsEnabled = true
			
			local currentMIDInote_Number = 0
			
			-- search from end for <MidiKey Value=" as a string															
			for j=#currentKeyTrackTagTable,1,-1
			do
				if string.match(currentKeyTrackTagTable[j],'<MidiKey Value="')
				then	
					currentMIDInote_Number = getValueFrom_SingleLineXMLTag(currentKeyTrackTagTable,j,'<MidiKey Value="','" />')
				break
				end--if	
			end--for j
			
			-- search from end for <MidiNoteEvent															
			for k=1,#currentKeyTrackTagTable,1
			do
				if string.match(currentKeyTrackTagTable[k],'<MidiNoteEvent')
				then
					local MidiNoteEvent_string = currentKeyTrackTagTable[k]
					local root = rtk.xmlparse(string.gsub(MidiNoteEvent_string, " />$", "></MidiNoteEvent>"))
				
					-- currentMIDInote_OnTime = string.sub(MidiNoteEvent_string, 
					-- 			string.find(MidiNoteEvent_string,'Time="')+6,
					-- 			string.find(MidiNoteEvent_string,'" Duration')-1)
					-- currentMIDInote_OnTime = tonumber(currentMIDInote_OnTime)
					currentMIDInote_OnTime = tonumber(root.attrs.Time.value)

					
					-- currentMIDInote_Duration = string.sub(MidiNoteEvent_string,
					-- 			string.find(MidiNoteEvent_string,'Duration="')+10,
					-- 			string.find(MidiNoteEvent_string,'" Velocity')-1)
					-- currentMIDInote_Duration = tonumber(currentMIDInote_Duration)
					currentMIDInote_Duration = tonumber(root.attrs.Duration.value)
	
	
					currentMIDInote_OffTime = currentMIDInote_OnTime+currentMIDInote_Duration

					
					-- currentMIDInote_OnVelocity = string.sub(MidiNoteEvent_string,
					-- 			string.find(MidiNoteEvent_string,'Velocity="')+10,
					-- 			string.find(MidiNoteEvent_string,'" OffVelocity')-1)
					-- currentMIDInote_OnVelocity = math.floor(tonumber(currentMIDInote_OnVelocity)+0.5)
					currentMIDInote_OnVelocity = tonumber(root.attrs.Velocity.value)
					
					-- currentMIDInote_OffVelocity = string.sub(MidiNoteEvent_string,
					-- 			string.find(MidiNoteEvent_string,'OffVelocity="')+13,
					-- 			string.find(MidiNoteEvent_string,'" IsEnabled')-1)
					-- currentMIDInote_OffVelocity = math.floor(tonumber(currentMIDInote_OffVelocity)+0.5)
					currentMIDInote_OffVelocity = tonumber(root.attrs.OffVelocity.value)
					
					-- currentMIDInote_IsEnabled = string.sub(MidiNoteEvent_string,
					-- 			string.find(MidiNoteEvent_string,'IsEnabled="')+11,
					-- 			string.find(MidiNoteEvent_string,'" />')-1)
					currentMIDInote_IsEnabled = root.attrs.IsEnabled.value
					

					currentMIDInote_IsMuted_boolean = false
					if currentMIDInote_IsEnabled == 'false'
					then
						currentMIDInote_IsMuted_boolean = true
					end
					
					
					local noteStartInPPQ = math.floor((currentMIDInote_OnTime*ticksPerQuarterNote)+0.5)
					local noteEndInPPQ = math.floor((currentMIDInote_OffTime*ticksPerQuarterNote)+0.5)
					
					noteStartInPPQ = noteStartInPPQ - MIDI_MoveEventsBackBy_InPPQ
					noteEndInPPQ =  noteEndInPPQ - MIDI_MoveEventsBackBy_InPPQ
					
					
					
					
					--===============================================
					-- INSERT MIDI NOTE
					--===============================================
					
					if noteStartInPPQ > -1
					and noteStartInPPQ > ManualStartOffset_InPPQ 
					and noteStartInPPQ < IntendedEndOfLoop_InPPQ
					then
					
						if noteEndInPPQ > IntendedEndOfLoop_InPPQ 
						then 
							noteEndInPPQ = IntendedEndOfLoop_InPPQ 
						end
					
						reaper.MIDI_InsertNote(
								given_REAPERCurrentTake,
								false,
								currentMIDInote_IsMuted_boolean,
								noteStartInPPQ,
								noteEndInPPQ,
								0,
								currentMIDInote_Number,
								currentMIDInote_OnVelocity,
								true
								)
					end
					
				end--if string.match(given_KeyTracksXMLTable[k],'<MidiNoteEvent')
			
			end--for k

		end--if
		
	end--for  i	

end--function useDataFrom_KeyTracksXMLTable









--********************************************************************
-- useDataFrom_INNER_EnvelopesXMLTable (MIDI CC Envelopes in CLIPS)
--********************************************************************

function useDataFrom_INNER_EnvelopesXMLTable(
								given_INNER_EnvelopesXMLTable,
								given_REAPERCurrentItem,
								given_REAPERCurrentTake,
								given_MidiControllersXMLTable,
								given_Live_MIDILoopLength_InQN,
								given_MIDI_ManualStartOffset_InQN,		-- will not insert events before this
								given_MIDI_MoveEventsBackBy_InQN		-- gets subtracted from event time
								)
	
	local ManualStartOffset_InPPQ = math.floor((given_MIDI_ManualStartOffset_InQN*ticksPerQuarterNote)+0.5)	
	local MIDI_MoveEventsBackBy_InPPQ = math.floor((given_MIDI_MoveEventsBackBy_InQN*ticksPerQuarterNote)+0.5)
	
	if ManualStartOffset_InPPQ > -1
	then
		ShowConsoleMsg_and_AddtoLog("\nCC INSERTION, ManualStartOffset_InPPQ:"..ManualStartOffset_InPPQ)
	end
	
	
	local IntendedEndOfLoop_InPPQ = math.floor((given_Live_MIDILoopLength_InQN*ticksPerQuarterNote)+0.5)

	local previousEventTime = 0

	-- for each <ClipEnvelope Id="
	for i=1,#given_INNER_EnvelopesXMLTable,1
	do
		if string.match(given_INNER_EnvelopesXMLTable[i],'<ClipEnvelope Id="')
		then
			local currentClipEnvelopeTagTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_INNER_EnvelopesXMLTable,	-- given_Table,
																		i,								-- given_StartTagIndex
																		'</ClipEnvelope>'				-- given_EndTag
																		)
			
			
			---------------------------------------------------------------
			-- get <PointeeId Value="#####" /> of current ClipEnvelope
			---------------------------------------------------------------
			local currentPointeeId = 0
			
			for j=1,#currentClipEnvelopeTagTable,1
			do
				if string.match(currentClipEnvelopeTagTable[j],'<PointeeId Value="')
				then	
					currentPointeeId = getValueFrom_SingleLineXMLTag(currentClipEnvelopeTagTable,j,'<PointeeId Value="','" />')
					break
				end--if	
			end--for j
			
			
			---------------------------------------------------------------------------------------------------
			-- GO THROUGH MIDI CC AUTOMATION TARGETS, get controller ID based on ClipEnvelope's PointeeID tag
			---------------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------------------------
			-- FIND '<ControllerTargets.' parts
			-- Live 10.0.5: <MidiTrack Id="#"><DeviceChain><MainSequencer><MidiControllers><ControllerTargets.# Id="######">
			-----------------------------------------------------------------------------------------------------------------
			
			for c=1,#given_MidiControllersXMLTable,1
			do

				if string.match(given_MidiControllersXMLTable[c],'<ControllerTargets.') 
				then
						
					local ControllerTargetsTag_contents = tostring(given_MidiControllersXMLTable[c])

					if string.find(ControllerTargetsTag_contents,currentPointeeId)
					then
						--reaper.ShowConsoleMsg("\n\nControllerTargetsTag_contents:"..ControllerTargetsTag_contents.." includes PointeeId:"..currentPointeeId)
					
					
						local current_LiveMidiControllerTarget = string.sub(
						ControllerTargetsTag_contents,
						string.find(ControllerTargetsTag_contents,'<ControllerTargets.')+19,
						string.find(ControllerTargetsTag_contents,' Id="')
						)
						current_LiveMidiControllerTarget = tonumber(current_LiveMidiControllerTarget)
						--reaper.ShowConsoleMsg("\ncurrentClipEnvelopeNumber_InLiveControllerTargets:"..currentClipEnvelopeNumber_InLiveControllerTargets)
					

						-------------------------------------------------------------
						-- COMMENCE ADDING MIDI CC POINTS
						-------------------------------------------------------------
						-- NOTE: CC events will be sorted alongside MIDI notes 
						-- in function useDataFrom_MidiClipXMLTable
						-------------------------------------------------------------
					
						-- get <Events> as TABLE to contain <FloatEvent Id="														
						for k=1,#currentClipEnvelopeTagTable,1
						do
							if string.match(currentClipEnvelopeTagTable[k],'<Events>')
							then
								local currentEventsTagTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																				currentClipEnvelopeTagTable,	-- given_Table,
																				k,								-- given_StartTagIndex
																				'</Events>'						-- given_EndTag
																				)
																				
								
								-- for each <FloatEvent Id="									
								for l=1,#currentEventsTagTable,1
								do
									if string.match(currentEventsTagTable[l],'<FloatEvent Id="')
									then
									
										local FloatEvent_string = tostring(currentEventsTagTable[l])
										
										--reaper.ShowConsoleMsg("\nFloatEvent_string:"..FloatEvent_string)
						
										local Event_Time = string.sub(
										FloatEvent_string,
										string.find(FloatEvent_string,'Time="')+6,
										string.find(FloatEvent_string,'" Value=')-1
										)
										if Event_Time == '-63072000' then Event_Time = 0 end
										Event_Time = tonumber(Event_Time)
										Event_Time = math.floor((Event_Time*ticksPerQuarterNote)+0.5)
										
										Event_Time = Event_Time - MIDI_MoveEventsBackBy_InPPQ
										
										-- to retain square-like shapes
										if Event_Time == previousEventTime then Event_Time = Event_Time + 1 end 
										
										previousEventTime = Event_Time


										---------------------------------
										-- add point in REAPER
										-- only if time value is positive
										---------------------------------
										
										if Event_Time > -1 and Event_Time > ManualStartOffset_InPPQ and Event_Time < IntendedEndOfLoop_InPPQ --- and within intended loop range
										then
										
											local Event_Value = string.sub(
											FloatEvent_string,
											string.find(FloatEvent_string,'Value="')+7,
											string.find(FloatEvent_string,'" />')-1
											)
											Event_Value = tonumber(Event_Value)
											--reaper.ShowConsoleMsg(" Event_Value:"..Event_Value)
											

											--[[
												TESTED:
												Live number					MIDI Standard 		REAPER chanmsg 	msg1 		msg2
												-------------------------------------------------------------------------------------
												<ControllerTargets.0   = 	PITCH MODULATION			224 	LSB 0-127	MSB 0-127
												<ControllerTargets.1   = 	CHANNEL PRESSURE			208		0-127 		0
												<ControllerTargets.2   = 	CC 0 Bank Select MSB		176		0 (CCnum)	0-127
												<ControllerTargets.3   = 	CC 1 Mod Wheel MSB			176		1 (CCnum)	0-127
												.....
												<ControllerTargets.7   = 	CC 5						176		5 (CCnum)	0-127
												.....
												<ControllerTargets.12  = 	CC 10						176		10 (CCnum)	0-127
												..........
												<ControllerTargets.22  = 	CC 20						176		20 (CCnum)	0-127
												.......... .......... .......... .......... .......... .......... ..........
												<ControllerTargets.102 = 	CC 100						176		100 (CCnum)	0-127 
												........
												<ControllerTargets.121 = 	CC 119						176		100 (CCnum)	0-127 
												
												PRESUMABLY:
												ControllerTargets.122 = 	120 All Sounds Off
												ControllerTargets.123 = 	121 All Controllers Off
												ControllerTargets.124 = 	122 Local keyboard on/off
												ControllerTargets.125 = 	123 All Notes Off
												ControllerTargets.126 = 	124 Omni Mode Off
												ControllerTargets.127 = 	125 Omni Mode On
												ControllerTargets.128 = 	126 Mono Operation
												ControllerTargets.129 = 	127 Poly Operation
											--]]
											
											
											--initialize; will be used for recognizing string to replace in item chunk to add ENV 1 0 0
											local currentCCeventEnd = ''
											
											
											--=========================
											-- INSERT PITCH 
											--=========================
											
											if current_LiveMidiControllerTarget == 0
											then

												
												--reaper.ShowConsoleMsg("\nEvent_Time:"..Event_Time..", Event_Value:"..Event_Value)
												
												local Event_Value_MSB = 64
												local Event_Value_MSB_int = 64
												
												local Event_Value_LSB_fraction = 0
												local Event_Value_LSB_int = 0

												--conversion to MSB and LSB format
												if Event_Value > -1 -- 0 to 8192, MSB 64-127
												then
												
													local Event_Value_PlusSide = Event_Value/128 --0 to 64
												
													Event_Value_MSB = Event_Value_PlusSide+64  --64 to 127
													
													Event_Value_MSB_int, Event_Value_LSB_fraction = math.modf(Event_Value_MSB)
													
														if Event_Value_MSB_int == nil
														then
															Event_Value_MSB_int = 64
														end
													
														if Event_Value_LSB_fraction ~= nil
														then
															Event_Value_LSB_int = math.floor((127*Event_Value_LSB_fraction)+0.5)
														end
												
												elseif Event_Value < 0 --  -1 to -8192, MSB 0-64
												then
												
													Event_Value = Event_Value + 8192 --(0 to 8192)
													local Event_Value_MinusSide = Event_Value/128 --0 to 64
												
													Event_Value_MSB = Event_Value_MinusSide --0 to 64
													
													Event_Value_MSB_int, Event_Value_LSB_fraction = math.modf(Event_Value_MSB)
													
														if Event_Value_MSB_int == nil
														then
															Event_Value_MSB_int = 0
														end
														
														if Event_Value_LSB_fraction ~= nil
														then
															Event_Value_LSB_int = math.floor((127*Event_Value_LSB_fraction)+0.5)
														end
													
												end


												reaper.MIDI_InsertCC(
															given_REAPERCurrentTake,
															false,
															false,
															Event_Time,
															224,
															0,
															Event_Value_LSB_int,
															Event_Value_MSB_int
															)
												
												currentCCeventEnd =  -- for setting shape via gsub
												string.format("%02x", tostring(224))
												.." "..string.format("%02x", tostring(Event_Value_LSB_int))
												.." "..string.format("%02x", tostring(Event_Value_MSB_int))
												--reaper.ShowConsoleMsg("\n currentCCeventEnd:"..currentCCeventEnd)
												
												
												--reaper.ShowConsoleMsg("\nEvent_Time:"..Event_Time..", Event_Value_MSB:"..Event_Value_MSB..", Event_Value_MSB_int:"..Event_Value_MSB_int..", Event_Value_LSB_int:"..Event_Value_LSB_int)
												
											--=========================
											-- INSERT CHANNEL PRESSURE
											--=========================
												
											elseif current_LiveMidiControllerTarget == 1
											then

												Event_Value = math.floor(Event_Value+0.5)

												reaper.MIDI_InsertCC(
															given_REAPERCurrentTake,
															false,
															false,
															Event_Time,
															208,
															0,
															Event_Value,
															0
															)
												
												currentCCeventEnd = -- for setting shape via gsub 
												string.format("%02x", tostring(208))
												.." "..string.format("%02x", tostring(Event_Value))
												.." "..string.format("%02x", tostring(0))
												--reaper.ShowConsoleMsg("\n currentCCeventEnd:"..currentCCeventEnd)
												
											-----------------------------------------------------
											-- CATCH Bank select MSB, DO NOT INSERT
											-----------------------------------------------------
												
											elseif current_LiveMidiControllerTarget == 2
											then
												ShowConsoleMsg_and_AddtoLog("\nEnvelope found for MIDI Bank Select MSB (Live <ControllerTargets.2)\nIT WAS NOT IMPORTED to REAPER! Modify script code if you need it.")
											end --
											
											
											--=========================
											-- INSERT ordinary CCs
											--=========================
											
											local currentCCNumber = 1
											
											if current_LiveMidiControllerTarget > 2 -- 3 or larger
											then 
												currentCCNumber = current_LiveMidiControllerTarget-2


                                                -- check!
                                                if  Event_Value ~= nil
                                                then
                                                    Event_Value = math.floor(Event_Value+0.5)
                                                elseif Event_Value == nil
                                                then
                                                    Event_Value = 0
                                                end--if

												--reaper.ShowConsoleMsg("\n Inserting point: CC "..currentCCNumber..", Event_Time "..Event_Time..", Event_Value:"..Event_Value)
												
												reaper.MIDI_InsertCC(
															given_REAPERCurrentTake,
															false,
															false,
															Event_Time,
															176,
															0,
															currentCCNumber,
															Event_Value
															)
												
												currentCCeventEnd = -- for setting shape via gsub
												string.format("%02x", tostring(176))
												.." "..string.format("%02x", tostring(currentCCNumber))
												.." "..string.format("%02x", tostring(Event_Value))
												--reaper.ShowConsoleMsg("\n currentCCeventEnd:"..currentCCeventEnd)
											
											end --if current_LiveMidiControllerTarget > 2 -- 3 or larger
											
											
											
											--------------------------------------------------------
											-- SET MIDI CC SHAPE for the just set point
											--------------------------------------------------------
											-- NOTE: TRY USING reaper.MIDI_SetCCShape()
											-- last time it did not work correctly in THIS fucntion (three last points did not receive shape)
											---------------------------------------------------------------------------------------------------
	
											-- E PPQtick xx xx xx
			
											--retval, CCSelected, CCMuted, CCPPQpos, CCchanmsg, CCchan, CCmsg2, CCmsg3 = reaper.MIDI_GetCC(given_targetTake,CC_PointIndex)
											--reaper.ShowConsoleMsg("\n MIDI_GetCC returns: "..CCPPQpos..", "..CCchanmsg.." "..CCmsg2.." "..CCmsg3)

											local retval, currentMediaItemStateChunk = reaper.GetItemStateChunk(given_REAPERCurrentItem,"",false)
											--modify CC end
											currentCCeventEnd = tostring(currentCCeventEnd)
											currentMediaItemStateChunk=string.gsub(currentMediaItemStateChunk,
															currentCCeventEnd,
															currentCCeventEnd..'\nENV 1 0 0')
											--reaper.ShowConsoleMsg("\n currentMediaItemStateChunk:"..currentMediaItemStateChunk)
														
											reaper.SetItemStateChunk(given_REAPERCurrentItem,currentMediaItemStateChunk,false)
											
											
						-------------------------------------------------------------
						-- NOTE: CC events will be sorted alongside MIDI notes 
						-- in function useDataFrom_MidiClipXMLTable
						-------------------------------------------------------------
						
										
										end --if Event_Time > -1 --0 or greater
										
									end--if	
									
								end--for l																						

							end--if
						
						end--for k
					
					
					
					end--if string.find(ControllerTargetsTag_contents,currentPointeeId)
				
				end--if string.match(given_MidiControllersXMLTable[c],'<ControllerTargets.')
			
			
			end--for c=1,#given_MidiControllersXMLTable,1
			

		end--if string.match(given_INNER_EnvelopesXMLTable[i],'<ClipEnvelope Id="')
		
	end--for i=1,#given_INNER_EnvelopesXMLTable,1
				
end -- function useDataFrom_INNER_EnvelopesXMLTable









--*********************************************************
-- useDataFrom_MidiClipXMLTable
--*********************************************************

currentProjectMediaItemCount = 0

function useDataFrom_MidiClipXMLTable(
							given_MidiClipXMLTable,
							given_RPRtrack,
							given_MidiControllersXMLTable
							)
							
	local retval, thisTrackName = reaper.GetTrackName(given_RPRtrack,'')

	local LiveMidiClip_CurrentStart
	local LiveMidiClip_CurrentEnd
	local LiveMidiClip_LoopStart
	local LiveMidiClip_LoopEnd
	local LiveMidiClip_LoopOn
	local LiveMidiClip_Name
	local LiveMidiClip_OUTER_EnvelopesXMLTable
	--local LiveMidiClip_GrooveSettingsXMLTable
	local LiveMidiClip_KeyTracksXMLTable
	local LiveMidiClip_ColorIndex
	local LiveMidiClip_Color


-- ! ! ! -------------------------------------------------------------
-- NOTE: Traversal order matters here for first set of clip tags
-- must be in same order as in Live set (same as above list)
----------------------------------------------------------------------

	-- GET <CurrentStart Value=" as string
	for i=1,#given_MidiClipXMLTable,1
	do
		if string.match(given_MidiClipXMLTable[i],'<CurrentStart Value="')
		then												
			LiveMidiClip_CurrentStart = tonumber(getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<CurrentStart Value="','" />'))	
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_CurrentStart:"'..LiveMidiClip_CurrentStart..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<CurrentEnd Value="')
		then												
			LiveMidiClip_CurrentEnd = tonumber(getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<CurrentEnd Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_CurrentEnd:"'..LiveMidiClip_CurrentEnd..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<LoopStart Value="')
		then												
			LiveMidiClip_LoopStart = tonumber(getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<LoopStart Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_LoopStart:"'..LiveMidiClip_LoopStart..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<LoopEnd Value="')
		then												
			LiveMidiClip_LoopEnd = tonumber(getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<LoopEnd Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_LoopEnd:"'..LiveMidiClip_LoopEnd..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<StartRelative Value="')
		then												
			LiveMidiClip_StartRelative = tonumber(getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<StartRelative Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_StartRelative:"'..LiveMidiClip_StartRelative..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<LoopOn Value="')
		then												
			LiveMidiClip_LoopOn = getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<LoopOn Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_LoopOn:"'..LiveMidiClip_LoopOn..'"')
		end--if


		if string.match(given_MidiClipXMLTable[i],'<Name Value="')
		then												
			LiveMidiClip_Name = getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<Name Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_Name:"'..LiveMidiClip_Name..'"')	
		end--if


		if string.match(given_MidiClipXMLTable[i],'<ColorIndex Value="')
		then												
			LiveMidiClip_ColorIndex = getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<ColorIndex Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_ColorIndex:"'..LiveMidiClip_ColorIndex..'"')
			LiveMidiClip_ColorIndex = tonumber(LiveMidiClip_ColorIndex)			
		end--if


		if string.match(given_MidiClipXMLTable[i],'<Color Value="')
		then												
			LiveMidiClip_Color = getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<Color Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_Color:"'..LiveMidiClip_Color..'"')
			LiveMidiClip_Color = tonumber(LiveMidiClip_Color)			
		end--if


		if string.match(given_MidiClipXMLTable[i],'<Disabled Value="')
		then												
			LiveMidiClip_Disabled = getValueFrom_SingleLineXMLTag(given_MidiClipXMLTable,i,'<Disabled Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveMidiClip_Disabled:"'..LiveMidiClip_Disabled..'"')	
		end--if
		
	end--for i
	
	

	--[[------------------------------------------------
	
	-- COMMENCE ADDING MIDI CLIPS
	
	-- LiveMidiClip_CurrentStart
	-- LiveMidiClip_CurrentEnd
	-- LiveMidiClip_LoopStart
	-- LiveMidiClip_LoopEnd
	-- LiveMidiClip_StartRelative
	-- LiveMidiClip_LoopOn
	-- LiveMidiClip_Name
	
	
	-------------------------------------------------------------------------------------------------------
	--   DETERMINE AND SET CLIP / ITEM LENGTHS, LOOPS AND RELATIVE STARTS
	-------------------------------------------------------------------------------------------------------
	
	NOTE: !!!! Live LiveMidiClip_StartRelative 
							is RELATIVE TO LiveMidiClip_LoopStart
							
		While in REAPER, Start Offset is relative to ...Item start?
	
	NOTE: In REAPER, creating MIDI item sets its loop point immediately by AllNotesOff command IN THE ITEM
	
			HOWEVER: if MIDI clip has data beyond that point, THE LOOP POINT IS MOVED FORWARD
			THEREFORE, data in MIDI clips is shortened to NOT be longer than intended loop length
	
	
	---------------------------------------------------------------------------------------------------------]]
	--reaper.ShowConsoleMsg("\n    Adding MIDI clip:"..LiveMidiClip_Name)
	
	local Live_ClipLengthInArrangement 		= LiveMidiClip_CurrentEnd - LiveMidiClip_CurrentStart
	
	local MIDI_ManualStartOffset_InQN 		= -1 -- if not overridden, events after this will be allowed 
	local Live_MIDILoopLength_InQN 			= LiveMidiClip_LoopEnd - LiveMidiClip_LoopStart -- if not overridden, events after this will be discarded 
	local MIDI_MoveEventsBackBy_InQN		= 0 --gets subtracted from event time to simulate start offsets
	
	local REAPER_StartTime_InQN = 0
	local REAPER_EndTime_InQN = 0
	local REAPER_StartOffset_InQN = 0
	local REAPER_LoopOn = 0
	
	
	local ClipImportedIncorrectly = false
	
	
					
--[[----------------------------------------------------------------------------------------------------------------------------
						LoopOn	  LoopStart   StartRelative
--------------------------------------------------------------------------------------------------------------------------------
		CASE A1 (A3): 	false, 		==0, 		==0	
		CASE A2: 		true, 		==0, 		==0	
										
		CASE A3 (A5): 	false,  	 >0, 		==0  if saved as this in Live, becomes CASE A1: 	false, 	==0, 	==0	
		CASE A4: 		true,  	 	 >0, 		==0
																		
		CASE A5: 		false, 		==0, 		 >0  if saved as this in Live, becomes CASE A3:		false,   >0, 	==0 
		CASE A6: 		true, 		==0, 		 >0 
		
		CASE A7: 		false, 		 >0, 		 >0  if saved as this in Live, becomes CASE A3:		false,   >0, 	==0 
		CASE A8: 		true, 		 >0, 		 >0 
		
		
		
		CASE B1			false,		  >0		 <0	if saved as this in Live, becomes CASE A1: 	false, 	==0, 	==0		
		CASE B2			true,		  >0		 <0	leaves notes before loop, not importable to REAPER


--------------------------------------------------------------------------------------------------------------------------------]]


	-- ALL LOOP OFF CLIPS (basic) --NOTE: In clips with Loop Off, StartRel values are saved in LoopStart
	if LiveMidiClip_LoopOn == "false" and LiveMidiClip_LoopStart == 0 and LiveMidiClip_StartRelative == 0 
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentEnd
		REAPER_LoopOn = 0
		REAPER_StartOffset_InQN = LiveMidiClip_LoopStart
		
		
	elseif LiveMidiClip_LoopOn == "false" and LiveMidiClip_LoopStart > 0 and LiveMidiClip_StartRelative == 0 
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentEnd
		REAPER_LoopOn = 0
		
		
		--reaper.ShowConsoleMsg('\n                LiveMidiClip_LoopStart:"'..LiveMidiClip_LoopStart..'"')	
		
		--REAPER_StartOffset_InQN = LiveMidiClip_LoopStart
		MIDI_MoveEventsBackBy_InQN = LiveMidiClip_LoopStart

	
-- CASE A2: 				true, 								==0, 								==0	
--------------------------------------------------------------------------------------------------------
	-- LOOPED CLIPS WITHOUT OFFSETS (basic)
	elseif LiveMidiClip_LoopOn == "true" and LiveMidiClip_LoopStart == 0 and LiveMidiClip_StartRelative == 0 --NOTE: StartRel won't ever be longer than loop
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentStart + (LiveMidiClip_LoopEnd - LiveMidiClip_LoopStart)
		REAPER_LoopOn = 1


-- CASE A4: 					true,  	 					 >0, 									==0
--------------------------------------------------------------------------------------------------------
	-- LOOPED CLIPS WITH LOOP START AFTER 0 (usually shorter than even-bar loops)
	elseif LiveMidiClip_LoopOn == "true" and LiveMidiClip_LoopStart > 0 and LiveMidiClip_StartRelative == 0
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentStart + (LiveMidiClip_LoopEnd - LiveMidiClip_LoopStart)
		REAPER_LoopOn = 1
		MIDI_MoveEventsBackBy_InQN = LiveMidiClip_LoopStart -- start events from LoopStart


-- CASE A6: 					true, 						==0, 		 							>0
--------------------------------------------------------------------------------------------------------
	-- LOOPED CLIPS WITH LOOP START AT ZERO AND RELATIVE START AFTER LOOP START	
	elseif LiveMidiClip_LoopOn == "true" and LiveMidiClip_LoopStart == 0 and LiveMidiClip_StartRelative > 0 --NOTE: StartRel won't ever be longer than loop
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentStart + (LiveMidiClip_LoopEnd - LiveMidiClip_LoopStart)
		REAPER_LoopOn = 1
		REAPER_StartOffset_InQN = LiveMidiClip_StartRelative

		
--CASE A8: 		true, 		 >0, 		 >0 
--------------------------------------------------------------------------------------------------------
	elseif LiveMidiClip_LoopOn == "true" and LiveMidiClip_LoopStart > 0 and LiveMidiClip_StartRelative > 0 --NOTE: StartRel won't ever be longer than loop
	then
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentStart + (LiveMidiClip_LoopEnd - LiveMidiClip_LoopStart)
		
		REAPER_LoopOn = 1

		MIDI_MoveEventsBackBy_InQN = LiveMidiClip_LoopStart -- start events from LoopStart
		REAPER_StartOffset_InQN = LiveMidiClip_StartRelative -- offset by StartRelative
		
	else 	-- this includes any MIDI clips which have negative values for LoopStart or StartRelative, 
			-- which are not importable into REAPER 6.x without reformatting data in such clips into several new items; 
			-- imported incorrectly here for purpose of finding them more easily
			-- BEST TO SIMPLY CONSOLIDATE THEM in Live AND ATTEMPT IMPORT AGAIN
		
		ClipImportedIncorrectly = true
	
		local incorrectClipImportWarning = '    INCORRECT CLIP IMPORT: Track '..(currentTrackIndex+1)..' "'..thisTrackName..'"'
			..' bar '..((LiveMidiClip_CurrentStart/4)+1)..' (1/4ths:'..LiveMidiClip_CurrentStart..')'
			..' Midi Clip "'..LiveMidiClip_Name..'"'
			..' LoopStart='..LiveMidiClip_LoopStart..' (1/4ths)'
			..' StartRelative='..LiveMidiClip_StartRelative..' (1/4ths)'
			
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS,incorrectClipImportWarning)
	
		REAPER_StartTime_InQN = LiveMidiClip_CurrentStart
		REAPER_EndTime_InQN = LiveMidiClip_CurrentEnd
		Live_MIDILoopLength_InQN = LiveMidiClip_LoopEnd
		REAPER_LoopOn = 0

	end--if


	--reaper.ShowConsoleMsg(' LiveMidiClip_Name:"'..LiveMidiClip_Name..'"')


	------------------------------------
	-- CREATE INITIAL MIDI ITEM
	------------------------------------
	
	--reaper.ShowConsoleMsg('\n CreateNewMIDIItemInProj: REAPER_StartTime_InQN:'..REAPER_StartTime_InQN..',  REAPER_EndTime_InQN:'..REAPER_EndTime_InQN)

		reaper.CreateNewMIDIItemInProj(
										given_RPRtrack,					-- MediaTrack track,
										REAPER_StartTime_InQN,				-- number starttime, 
										REAPER_EndTime_InQN,				-- number endtime,
										true								-- optional boolean qnIn (in quarter notes)
										) 								
		

	-- GET ITEM AND TAKE FOR LATER FUNCTIONS
	local currentItem = reaper.GetMediaItem(0,currentProjectMediaItemCount)	
	local currentTake = reaper.GetTake(currentItem,0)


	-------------------------------------------------------------------------------------------------------------------
	-- GET MEDIA ITEM STATE CHUNK (in Reaper RPP format) AND MODIFY ITS VALUES
	-------------------------------------------------------------------------------------------------------------------

	local retval, currentMediaItemStateChunk = reaper.GetItemStateChunk(currentItem,"",false)
	currentMediaItemStateChunk=string.gsub(currentMediaItemStateChunk,'NAME ""','NAME "'..LiveMidiClip_Name..'"')
	reaper.SetItemStateChunk(currentItem,currentMediaItemStateChunk,false)
		
	
	-- SET LOOP STATE
	reaper.SetMediaItemInfo_Value(currentItem,'B_LOOPSRC',REAPER_LoopOn) --REAPER_LoopOn
	--reaper.ShowConsoleMsg("\n B_LOOPSRC:"..REAPER_LoopOn)
		
		
	-- SET START OFFSET
	reaper.SetMediaItemTakeInfo_Value(currentTake,'D_STARTOFFS', reaper.TimeMap2_beatsToTime(0,REAPER_StartOffset_InQN))
	--reaper.ShowConsoleMsg('  REAPER_StartOffset_InQN:'..REAPER_StartOffset_InQN)
	

	-- SET LENGTH IN ARRANGEMENT, INCLUDING LOOP
	local ClipLengthInArrangement_inREAPERtime = reaper.TimeMap2_beatsToTime(0,Live_ClipLengthInArrangement)
	reaper.SetMediaItemInfo_Value(currentItem,'D_LENGTH',ClipLengthInArrangement_inREAPERtime)
	--reaper.ShowConsoleMsg("  D_LENGTH:"..ClipLengthInArrangement_inREAPERtime)

	--reaper.SetMediaItemLength(currentItem, 1, 1)

	
	-- SET MUTE/DISABLED
	if LiveMidiClip_Disabled == "true"
	then
		reaper.SetMediaItemInfo_Value(currentItem,'B_MUTE',1)
	end
	
	
	------------------------------------------
	-- SET ITEM COLOR
	------------------------------------------
	local colorIndex
	if colorIndex ~= nil
	then
		colorIndex = LiveMidiClip_ColorIndex
	else
		colorIndex = LiveMidiClip_Color
	end
	if colorIndex > -1 and  colorIndex < 70
	then
		for l=0,69,1  --NOTE: intentional manual values; #Live10_ColorIndexTable doesn't appear to work
		do
			if l == colorIndex
			then
				local ClipColor = reaper.ColorToNative(
											Live10_ClipColorIndexTable[l][1],
											Live10_ClipColorIndexTable[l][2],
											Live10_ClipColorIndexTable[l][3]
											)|0x01000000
											
											
				reaper.SetMediaItemInfo_Value(currentItem,'I_CUSTOMCOLOR',ClipColor)
			end--if
		end--for
	end--if

	
	
	-----------------------------------------------
	-- SET WARNING COLOR IF IMPORTED INCORRECTLY
	-----------------------------------------------
	if ClipImportedIncorrectly == true
	then
		local clipWarningColor = reaper.ColorToNative(255,80,0)|0x01000000
		reaper.SetMediaItemInfo_Value(currentItem,'I_CUSTOMCOLOR',clipWarningColor)
	end
	
	
	-----------------------------------------------------------------------
	-- GET <GrooveSettings> AS A TABLE, SAVE INTO A TABLE FOR CHECKING
	-----------------------------------------------------------------------
	local GrooveSettingsXMLTable = makeSubtableBy_FIRST_StartTag_and_FIRST_EndTag_AfterIt(given_MidiClipXMLTable,'<GrooveSettings>','</GrooveSettings>')
	
	--reaper.ShowConsoleMsg('\n indices in GrooveSettingsXMLTable:'..#GrooveSettingsXMLTable)
	
	for gc=1,#GrooveSettingsXMLTable,1 
	do 
		if string.match(GrooveSettingsXMLTable[gc],'<GrooveId Value="')
		then
			local currentClipsGrooveId = getValueFrom_SingleLineXMLTag(GrooveSettingsXMLTable,gc,'<GrooveId Value="','" />')
			
			if currentClipsGrooveId ~= '-1'
			then
				local GrooveClipDataTable = {}
				
				GrooveClipDataTable[0] = currentTrackIndex
				GrooveClipDataTable[1] = thisTrackName
				GrooveClipDataTable[2] = ((LiveMidiClip_CurrentStart/4)+1) -- at bar
				GrooveClipDataTable[3] = LiveMidiClip_CurrentStart -- at 1/4th
				GrooveClipDataTable[4] = currentClipsGrooveId
				GrooveClipDataTable[5] = LiveMidiClip_Name
				
				table.insert(CLIPS_WITH_GROOVES_TABLE,GrooveClipDataTable)
			end--if
			
		end--if
	end--for
	
	
	---------------------------------------------------------	
	-- GET <KeyTracks> as a TABLE to contain <KeyTrack Id="
	---------------------------------------------------------	
	
	-- GO BACKWARDS FROM TABLE END
	for l=#given_MidiClipXMLTable,1,-1
	do
		if string.match(given_MidiClipXMLTable[l],'<KeyTracks>')
		then
			LiveMidiClip_KeyTracksXMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MidiClipXMLTable,	-- given_Table,
																		l,						-- given_StartTagIndex
																		'</KeyTracks>'			-- given_EndTag
																		)
																		
			--reaper.ShowConsoleMsg("\n             LiveMidiClip_KeyTracksXMLTable indices:"..#LiveMidiClip_KeyTracksXMLTable)
			--printTableToConsole(LiveMidiClip_KeyTracksXMLTable,'LiveMidiClip_KeyTracksXMLTable')-- given_Table,given_TableName
			
			break --STOP the for loop when first occurrence of start is found
		end--if
	end--for  l	
		
		
		--================================================================
		-- PASS LiveMidiClip_KeyTracksXMLTable to its own function
		--================================================================
		
		if LiveMidiClip_KeyTracksXMLTable ~= nil
		then

		useDataFrom_KeyTracksXMLTable(
							LiveMidiClip_KeyTracksXMLTable,	-- given_KeyTracksXMLTable,
							currentTake,					-- given_REAPERCurrentTake
							Live_MIDILoopLength_InQN,		-- will not insert events after this
							MIDI_ManualStartOffset_InQN,	-- will not insert events before this
							MIDI_MoveEventsBackBy_InQN		-- this is subtracted from event time
							)--]]
		
		end

	------------------------------------
	-- get OUTER <Envelopes> as a table
	------------------------------------
	
	local LiveMidiClip_OUTER_EnvelopesXMLTable = {}
	
	for m=1,#given_MidiClipXMLTable,1
	do
		if string.match(given_MidiClipXMLTable[m],'<Envelopes>')
		then
			LiveMidiClip_OUTER_EnvelopesXMLTable = makeSubtableBy_StartIndex_and_LAST_EndTag(
																		given_MidiClipXMLTable,	-- given_Table,
																		m,						-- given_StartTagIndex
																		'</Envelopes>'			-- given_EndTag
																		)
																		
			--reaper.ShowConsoleMsg("\n             LiveMidiClip_OUTER_EnvelopesXMLTable:"..#LiveMidiClip_OUTER_EnvelopesXMLTable)
			--printTableToConsole(LiveMidiClip_OUTER_EnvelopesXMLTable,'LiveMidiClip_OUTER_EnvelopesXMLTable')-- given_Table,given_TableName
			
			break--enclosing for loop
		end--if
	end--for  m	
		
		
		------------------------------------------------------------------
		-- GET INNER <Envelopes> as a TABLE to contain <ClipEnvelope Id="
		------------------------------------------------------------------
		
		local LiveMidiClip_INNER_EnvelopesXMLTable = {}
		
		-- NOTE: startIndex=2 needed to bypass OUTER <Envelopes> tag
		for n=2,#LiveMidiClip_OUTER_EnvelopesXMLTable,1
		do
			if string.match(LiveMidiClip_OUTER_EnvelopesXMLTable[n],'<Envelopes>')
			then
				LiveMidiClip_INNER_EnvelopesXMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			LiveMidiClip_OUTER_EnvelopesXMLTable,	-- given_Table,
																			n,								-- given_StartTagIndex
																			'</Envelopes>'							-- given_EndTag
																			)
				--reaper.ShowConsoleMsg("\n             LiveMidiClip_INNER_EnvelopesXMLTable:"..#LiveMidiClip_INNER_EnvelopesXMLTable)
				--printTableToConsole(LiveMidiClip_INNER_EnvelopesXMLTable,'LiveMidiClip_INNER_EnvelopesXMLTable')-- given_Table,given_TableName
				
				break--enclosing for loop
				
			end--if
		end--n

		--================================================================
		-- PASS LiveMidiClip_INNER_EnvelopesXMLTable to its own function
		--================================================================

		useDataFrom_INNER_EnvelopesXMLTable(
							LiveMidiClip_INNER_EnvelopesXMLTable,	-- given_INNER_EnvelopesXMLTable,
							currentItem,							-- given_REAPERCurrentItem
							currentTake,							-- given_REAPERCurrentTake
							given_MidiControllersXMLTable,			-- given_MidiControllersXMLTable
							Live_MIDILoopLength_InQN,				-- will cut off events after this
							MIDI_ManualStartOffset_InQN,			-- will not insert events before this
							MIDI_MoveEventsBackBy_InQN				-- this is subtracted from event time
							)--]]
		

	-------------------------------------------------
	-- SORT MIDI Events
	--------------------------------------------------
	reaper.MIDI_Sort(currentTake)

	---------------------------------------------------------------
	-- INCREMENT PROJECT MEDIA ITEM COUNT
	---------------------------------------------------------------
			
	currentProjectMediaItemCount = currentProjectMediaItemCount+1


end--function useDataFrom_MidiClipXMLTable








--*********************************************************
-- useDataFrom_AudioClipXMLTable
--*********************************************************

function useDataFrom_AudioClipXMLTable(
								given_AudioClipXMLTable,
								given_RPRtrack
								)
	
	local LiveAudioClip_WarpMarkersXMLTable = {}
	
	local LiveAudioClip_CurrentStart
	local LiveAudioClip_CurrentEnd
	local LiveAudioClip_LoopStart
	local LiveAudioClip_LoopEnd
	local LiveAudioClip_StartRelative
	local LiveAudioClip_LoopOn
	local LiveAudioClip_Name
	local LiveAudioClip_ColorIndex
	local LiveAudioClip_Color
	local LiveAudioClip_Disabled
	local LiveAudioClip_IsWarped
	local LiveAudioClip_PitchCoarse = 0
	local LiveAudioClip_PitchFine = 0
	
	-- GET TRACK NAME FOR WARNINGS etc.
	local retval, thisTrackName = reaper.GetTrackName(given_RPRtrack,'')


-- ! ! ! -------------------------------------------------------------
-- NOTE: Traversal order matters here for first set of clip tags
-- must be in same order as in Live set (same as above list)
----------------------------------------------------------------------

	-- GET <CurrentStart Value=" as string
	for i=1,#given_AudioClipXMLTable,1
	do
	
		if string.match(given_AudioClipXMLTable[i],'<WarpMarkers>')
		then
			LiveAudioClip_WarpMarkersXMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																			given_AudioClipXMLTable,	-- given_Table,
																			i,							-- given_StartTagIndex
																			'</WarpMarkers>'				-- given_EndTag
																			)
			--reaper.ShowConsoleMsg("\n             LiveAudioClip_WarpMarkersXMLTable:"..#LiveAudioClip_WarpMarkersXMLTable)
			--printTableToConsole(LiveAudioClip_WarpMarkersXMLTable,'LiveAudioClip_WarpMarkersXMLTable')-- given_Table,given_TableName
		end--if
	
	
		if string.match(given_AudioClipXMLTable[i],'<CurrentStart Value="')
		then												
			LiveAudioClip_CurrentStart = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<CurrentStart Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_CurrentStart:"'..LiveAudioClip_CurrentStart..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<CurrentEnd Value="')
		then												
			LiveAudioClip_CurrentEnd = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<CurrentEnd Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_CurrentEnd:"'..LiveAudioClip_CurrentEnd..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<LoopStart Value="')
		then												
			LiveAudioClip_LoopStart = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<LoopStart Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_LoopStart:"'..LiveAudioClip_LoopStart..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<LoopEnd Value="')
		then												
			LiveAudioClip_LoopEnd = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<LoopEnd Value="','" />'))	
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_LoopEnd:"'..LiveAudioClip_LoopEnd..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<StartRelative Value="')
		then												
			LiveAudioClip_StartRelative = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<StartRelative Value="','" />'))	
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_StartRelative:"'..LiveAudioClip_StartRelative..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<LoopOn Value="')
		then												
			LiveAudioClip_LoopOn = getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<LoopOn Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_LoopOn:"'..LiveAudioClip_LoopOn..'"')
		end--if


		if string.match(given_AudioClipXMLTable[i],'<Name Value="')
		then												
			LiveAudioClip_Name = getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<Name Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_Name:"'..LiveAudioClip_Name..'"')	
		end--if


		if string.match(given_AudioClipXMLTable[i],'<ColorIndex Value="')
		then												
			LiveAudioClip_ColorIndex = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<ColorIndex Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_ColorIndex:"'..LiveAudioClip_ColorIndex..'"')			
		end--if


		if string.match(given_AudioClipXMLTable[i],'<Color Value="')
		then												
			LiveAudioClip_Color = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<Color Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_Color:"'..LiveAudioClip_Color..'"')			
		end--if


		if string.match(given_AudioClipXMLTable[i],'<Disabled Value="')
		then												
			LiveAudioClip_Disabled = getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<Disabled Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_Disabled:"'..LiveAudioClip_Disabled..'"')	
		end--if
	
			
		if string.match(given_AudioClipXMLTable[i],'<IsWarped Value="')
		then												
			LiveAudioClip_IsWarped = getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<IsWarped Value="','" />')		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_IsWarped:"'..LiveAudioClip_IsWarped..'"')	

		------------------------------------------------------------------------
		-- BREAK HERE -- INSIDE LAST if!  - BECAUSE NO DATA FROM TAGS LATER THAN THIS IS NEEDED
		-- change place of this break if searches for tags after this are added
		------------------------------------------------------------------------
			-- break--enclosing for loop
		------------------------------------------------------------------------
			
		end--if
		
		
		if string.match(given_AudioClipXMLTable[i],'<PitchCoarse Value="')
		then												
			LiveAudioClip_PitchCoarse = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<PitchCoarse Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_PitchCoarse:"'..LiveAudioClip_PitchCoarse..'"')	
		end--if
		

		if string.match(given_AudioClipXMLTable[i],'<PitchFine Value="')
		then												
			LiveAudioClip_PitchFine = tonumber(getValueFrom_SingleLineXMLTag(given_AudioClipXMLTable,i,'<PitchFine Value="','" />'))		
			--reaper.ShowConsoleMsg('\n                LiveAudioClip_PitchFine:"'..LiveAudioClip_PitchFine..'"')	
		end--if
	end--for i
	

	-------------------------------------------------------------------------
	-- GET <SampleRef> as a TABLE (OUT OF ORDER FROM PREVIOUS TRAVERSAL)
	-------------------------------------------------------------------------

	local LiveAudioClip_FileRef_Name = ''
	local LiveAudioClip_FileRef_DataTable = ''	
	local LiveAudioClip_FileRef_DataString = ''
	local LiveAudioClip_FileRef_Path = ''
	
	
	-- GO BACKWARDS FROM TABLE END
	for j=1,#given_AudioClipXMLTable,1
	do
		if string.match(given_AudioClipXMLTable[j],'<SampleRef>')
		then
			LiveAudioClip_SampleRefXMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_AudioClipXMLTable,	-- given_Table,
																		j,						-- given_StartTagIndex
																		'</SampleRef>'			-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n             LiveAudioClip_SampleRefXMLTable indices:"..#LiveAudioClip_SampleRefXMLTable)
			--printTableToConsole(LiveAudioClip_SampleRefXMLTable,'LiveAudioClip_SampleRefXMLTable')-- given_Table,given_TableName
			
			
			for k=1,#LiveAudioClip_SampleRefXMLTable,1
			do
				if string.match(LiveAudioClip_SampleRefXMLTable[k],'<Name Value="')
				then												
					LiveAudioClip_FileRef_Name = getValueFrom_SingleLineXMLTag(LiveAudioClip_SampleRefXMLTable,k,'<Name Value="','" />')		
					--reaper.ShowConsoleMsg('\n                LiveAudioClip_FileRef_Name:"'..LiveAudioClip_FileRef_Name..'"')	
				end--if

				if string.match(LiveAudioClip_SampleRefXMLTable[k],'<Data>')
				then												
					LiveAudioClip_FileRef_DataTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		LiveAudioClip_SampleRefXMLTable,	-- given_Table,
																		k,									-- given_StartTagIndex
																		'</Data>'							-- given_EndTag
																		)
					--reaper.ShowConsoleMsg("\n             LiveAudioClip_FileRef_DataTable indices:"..#LiveAudioClip_FileRef_DataTable)
					--printTableToConsole(LiveAudioClip_FileRef_DataTable,'LiveAudioClip_FileRef_DataTable')-- given_Table,given_TableName
					
					break--enclosing for loop
					
				end--if

				if string.match(LiveAudioClip_SampleRefXMLTable[k],'<Path Value="')
				then												
					LiveAudioClip_FileRef_Path = getValueFrom_SingleLineXMLTag(LiveAudioClip_SampleRefXMLTable,k,'<Path Value="','" />')		
					--reaper.ShowConsoleMsg('\n                LiveAudioClip_FileRef_Name:"'..LiveAudioClip_FileRef_Name..'"')	
				end--if
			end--for k
			
			-- MAKE STRING FROM CONTENTS OF <Data>
			for m=2,#LiveAudioClip_FileRef_DataTable-1,1
			do
				LiveAudioClip_FileRef_DataString = LiveAudioClip_FileRef_DataString..LiveAudioClip_FileRef_DataTable[m]
			end--for m
			
			-- ! ! ! --------------------------------------------------
			-- NOTE: Data given here by Live appears to be UTF-16 hex
			----------------------------------------------------------
			
			-- REMOVE TABS FROM DATA STRING
			LiveAudioClip_FileRef_DataString = string.gsub(LiveAudioClip_FileRef_DataString,'\t+','')
			
			-------------------------------------------------------
			-- MacGyvered CONVERSION OF HEX DATA TO ASCII
			-------------------------------------------------------
			-- !!! MAY NOT WORK FOR SPECIAL CHARACTERS !!!
			-------------------------------------------------------
			function makeAsciiFromHex(given_string)
			
				local newString = ''
-- WORK IN PROGRESS - Problems on Mac				
				for i=1,string.len(given_string),2
				do
					currentHexVal = string.sub(given_string,i,i+1)
					currentASCIIval = string.char(tonumber(currentHexVal,16))
					
					if currentHexVal ~= "00"
					then
						newString = newString..currentASCIIval
					end
					--reaper.ShowConsoleMsg("\ncurrentHexVal:"..currentHexVal..", currentASCIIval:"..currentASCIIval)
				end--for
				
				--reaper.ShowConsoleMsg("\nnewString:"..newString)
				return newString
				
			end--function makeAsciiFromHex(given_string)
			-------------------------------------------------------
			
			LiveAudioClip_FileRef_DataString = makeAsciiFromHex(LiveAudioClip_FileRef_DataString)

			--reaper.ShowConsoleMsg("\n             LiveAudioClip_FileRef_DataString:"..LiveAudioClip_FileRef_DataString)
			
			break--enclosing for loop
			
		end--if
	end--for  j	


	--[[-------------------------------------------------
	
	COMMENCE ADDING AUDIO CLIP
	
	
	local LiveAudioClip_CurrentStart
	local LiveAudioClip_CurrentEnd
	local LiveAudioClip_LoopStart
	local LiveAudioClip_LoopEnd
	local LiveAudioClip_StartRelative
	local LiveAudioClip_LoopOn
	local LiveAudioClip_Name
	local LiveAudioClip_ColorIndex
	local LiveAudioClip_Disabled
	local LiveAudioClip_IsWarped
	local LiveAudioClip_PitchCoarse
	local LiveAudioClip_PitchFine
	
	------------------------------------------------------]]

	
	-------------------------------------------------------------------------------------------------------
	--   DETERMINE AND SET CLIP / ITEM LENGTHS, LOOPS AND RELATIVE STARTS
	-------------------------------------------------------------------------------------------------------
	
	
	reaper.ShowConsoleMsg("\n    Audio clip: "..LiveAudioClip_Name)
	
	reaper.ShowConsoleMsg("\n                "
							.."CurrentStart: "..LiveAudioClip_CurrentStart
							..", CurrentEnd: "..LiveAudioClip_CurrentEnd
							..", LoopStart: "..LiveAudioClip_LoopStart
							..", LoopEnd: "..LiveAudioClip_LoopEnd
							..", StartRelative: "..LiveAudioClip_StartRelative
							..", LoopOn: "..LiveAudioClip_LoopOn
							..", IsWarped: "..LiveAudioClip_IsWarped
							..", PitchCoarse: "..LiveAudioClip_PitchCoarse
							..", PitchFine: "..LiveAudioClip_PitchFine
							)


	local REAPER_AudioTakeProps_StartPosInArrangement_InQN = 0
	local REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart

	local REAPER_AudioTakeProps_LoopOn = 0
	local REAPER_AudioTakeProps_StartInSource_InQN = 0 -- Offsets the start time;  DOES NOT SHORTEN THE LOOP
	
	local REAPER_AudioTake_ModifySOURCEProperties = false	
	local REAPER_AudioTake_SOURCE_SECTION_InQN = 0 -- "start time / offset"
	local REAPER_AudioTake_SOURCE_LENGTH_InQN = 0  -- "length of looped area"
	
					
--[[----------------------------------------------------------------------------------------------------------------------------
		CASE SWITCHES				LoopOn	  LoopStart   StartRelative									
--------------------------------------------------------------------------------------------------------------------------------]]

--[[----------------------------------------------------------------------------------------------------------------------------
-- NOT WARPED, NOT LOOPED -- NOTE: In clips with Loop Off, StartRelative should be always 0, because StartRelative values are saved in LoopStart
--------------------------------------------------------------------------------------------------------------------------------]]

	----------------------------------------------------------------------------------------------------------		
	-- NO LOOP, NO OFFSETS -- NOTE: If warped, length set by LengthInArrangement
	----------------------------------------------------------------------------------------------------------	
	if LiveAudioClip_LoopOn == "false" and LiveAudioClip_LoopStart == 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 0
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= false	
		--REAPER_AudioTake_SOURCE_SECTION_InQN = 0 -- "start time / offset"
		--REAPER_AudioTake_SOURCE_LENGTH_InQN = 0  -- "length of looped area"
		
		
	----------------------------------------------------------------------------------------------------------			
	-- NO LOOP, POSITIVE START OFFSET -- NOTE: In clips with Loop Off, StartRelative values are saved in LoopStart
	----------------------------------------------------------------------------------------------------------	
	elseif LiveAudioClip_LoopOn == "false" and LiveAudioClip_LoopStart > 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 0
		REAPER_AudioTakeProps_StartInSource_InQN = LiveAudioClip_LoopStart --BECAUSE in clips with Loop Off, Start offset = LoopStart
		
		REAPER_AudioTake_ModifySOURCEProperties	= false	
		--REAPER_AudioTake_SOURCE_SECTION_InQN = 0 -- "start time / offset"
		--REAPER_AudioTake_SOURCE_LENGTH_InQN = 0 "length of looped area"
		
	
	----------------------------------------------------------------------------------------------------------		
	-- NO LOOP, NEGATIVE LOOP OR START OFFSET -- NOTE: In clips with Loop Off, StartRelative values are saved in LoopStart
	----------------------------------------------------------------------------------------------------------	
	elseif LiveAudioClip_LoopOn == "false" and LiveAudioClip_LoopStart < 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 0
		REAPER_AudioTakeProps_StartInSource_InQN = LiveAudioClip_LoopStart --BECAUSE in clips with Loop Off, Start offset = LoopStart
		
		REAPER_AudioTake_ModifySOURCEProperties	= false	
		--REAPER_AudioTake_SOURCE_SECTION_InQN = 0 -- "start time / offset"
		--REAPER_AudioTake_SOURCE_LENGTH_InQN = 0 "length of looped area"
		
		local AudioClip_NoLoop_LoopStartNegative_warning = '    POSSIBLY INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has LoopStart='..LiveAudioClip_LoopStart
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_NoLoop_LoopStartNegative_warning)



	
--[[----------------------------------------------------------------------------------------------------------------------------
-- LOOPED (and warped), LiveAudioClip_LoopStart == 0 
--------------------------------------------------------------------------------------------------------------------------------]]	

-- NOTE: StartRelative seems to be saved by Live as RELATIVE TO LOOP START

	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP START 0 (AT SOURCE DATA START), NO StartRelative OFFSET	
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart == 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= false	
		REAPER_AudioTake_SOURCE_SECTION_InQN = 0
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopStart+LiveAudioClip_LoopEnd
		
		
	----------------------------------------------------------------------------------------------------------			
	-- LOOP ON, LOOP START 0 (AT SOURCE DATA START), POSITIVE StartRelative OFFSET 	
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart == 0 and LiveAudioClip_StartRelative > 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = LiveAudioClip_StartRelative
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = 0
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopStart+LiveAudioClip_LoopEnd
		

		
	
	
--[[----------------------------------------------------------------------------------------------------------------------------
-- LOOPED (and warped), LiveAudioClip_LoopStart > 0 (POSITIVE)
--------------------------------------------------------------------------------------------------------------------------------]]	

	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP START positive (AFTER SOURCE DATA START), NO StartRelative OFFSET	
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart > 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd - LiveAudioClip_LoopStart


	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP START positive (AFTER SOURCE DATA START), POSITIVE StartRelative OFFSET 		
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart > 0 and LiveAudioClip_StartRelative > 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd - LiveAudioClip_LoopStart
		
		local AudioClip_LoopStartPos_StartRelPos_warning = '    POSSIBLY INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has StartRelative='..LiveAudioClip_StartRelative..' in 1/4ths ('..((LiveAudioClip_StartRelative/4)+1)..' in 16ths)'
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_LoopStartPos_StartRelPos_warning)
		
		
		
	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP START positive (AFTER SOURCE DATA START), NEGATIVE StartRelative OFFSET 		
	----------------------------------------------------------------------------------------------------------

	-- NOTE: StartRelative seems to be saved by Live as RELATIVE TO LOOP START

	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart > 0 and LiveAudioClip_StartRelative < 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart + LiveAudioClip_LoopStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart - LiveAudioClip_LoopStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd - LiveAudioClip_LoopStart
		
		local AudioClip_LoopStartPos_StartRelNeg_warning = '    POSSIBLY INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has StartRelative='..LiveAudioClip_StartRelative..' in 1/4ths ('..((LiveAudioClip_StartRelative/4)+1)..' in 16ths)'
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_LoopStartPos_StartRelNeg_warning)
	


--[[----------------------------------------------------------------------------------------------------------------------------
-- LOOPED (and warped), LiveAudioClip_LoopStart < 0  (NEGATIVE)
--------------------------------------------------------------------------------------------------------------------------------]]		

	
	-- LOOP ON, LOOP START negative (BEFORE SOURCE DATA START), NO START OFFSET	
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart < 0 and LiveAudioClip_StartRelative == 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd+math.abs(LiveAudioClip_LoopStart) -- convert LoopStart to pos, add at end

	
	-- LOOP ON, LOOP START negative (BEFORE SOURCE DATA START), POSITIVE StartRelative OFFSET 
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart < 0 and LiveAudioClip_StartRelative > 0 
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd
		
		local AudioClip_LoopStartNeg_StartRelPos_warning = '    POSSIBLY INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has StartRelative='..LiveAudioClip_StartRelative..' in 1/4ths ('..((LiveAudioClip_StartRelative/4)+1)..' in 16ths)'
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_LoopStartNeg_StartRelPos_warning)
	



	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP Start 0, NEGATIVE START OFFSET	
	----------------------------------------------------------------------------------------------------------
	elseif 	LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart == 0 and LiveAudioClip_StartRelative < 0
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart + math.abs(LiveAudioClip_StartRelative)
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= true	
		REAPER_AudioTake_SOURCE_SECTION_InQN = 0
		REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd
	
		--------------------------------------------------------
		-- INSERT WARNING FOR OFFSET CLIPS
		--------------------------------------------------------
	--[[
		local AudioClip_LoopStartZero_StartRelNegWarning = '    INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has StartRelative='..LiveAudioClip_StartRelative..' in 1/4ths ('..((LiveAudioClip_StartRelative/4)+1)..' in 16ths)'
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_LoopStartZero_StartRelNegWarning)
	]]--

	
	----------------------------------------------------------------------------------------------------------	
	-- LOOP ON, LOOP Start NEGATIVE, NEGATIVE START OFFSET	
	----------------------------------------------------------------------------------------------------------
	elseif LiveAudioClip_LoopOn == "true" and LiveAudioClip_LoopStart < 0 and 	LiveAudioClip_StartRelative < 0
	then
		REAPER_AudioTakeProps_StartPosInArrangement_InQN = LiveAudioClip_CurrentStart
		REAPER_AudioTakeProps_LengthInArrangement_InQN = LiveAudioClip_CurrentEnd - LiveAudioClip_CurrentStart
		
		REAPER_AudioTakeProps_LoopOn = 1
		REAPER_AudioTakeProps_StartInSource_InQN = 0
		
		REAPER_AudioTake_ModifySOURCEProperties	= false	
		--REAPER_AudioTake_SOURCE_SECTION_InQN = LiveAudioClip_LoopStart
		--REAPER_AudioTake_SOURCE_LENGTH_InQN = LiveAudioClip_LoopEnd
	
		--------------------------------------------------------
		-- INSERT WARNING FOR OFFSET CLIPS
		--------------------------------------------------------

		local AudioClip_LoopStartNeg_StartRelNegWarning = '    INCORRECT Audio Clip IMPORT on track '..(currentTrackIndex+1)..' "'
		..thisTrackName..'"'
		..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
		..' Audio Clip "'..LiveAudioClip_Name..'"'
		..' has StartRelative='..LiveAudioClip_StartRelative..' in 1/4ths ('..((LiveAudioClip_StartRelative/4)+1)..' in 16ths)'
		
		table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, AudioClip_LoopStartNeg_StartRelNegWarning)




	end--if CASES FOR DIFFERENT LoopOn, LoopStart and StartRelative SETTINGS


	--[[
	-- LOOP OFFSET WARNING
	local current_LoopStartOffsetWarning = '    On track '..(currentTrackIndex+1)..' "'..thisTrackName..'"'
	..' at bar '..((LiveAudioClip_CurrentStart/4)+1)..' (in 1/4ths:'..LiveAudioClip_CurrentStart..')'
	..' Audio Clip "'..LiveAudioClip_Name..'"'
	..' has LoopStart='..LiveAudioClip_LoopStart..' in 1/4ths ('..((LiveAudioClip_LoopStart/4)+1)..' in 16ths)'
	
	table.insert(TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS, current_LoopStartOffsetWarning) end
	
	]]



	----------------------------------------------------------
	-- CONVERT Live Quarter Note VALUES to REAPER TIME VALUES
	----------------------------------------------------------
	local REAPER_AudioTakeProps_StartPosInArrangement = reaper.TimeMap2_beatsToTime(0,REAPER_AudioTakeProps_StartPosInArrangement_InQN)
	local REAPER_AudioTakeProps_LengthInArrangement = reaper.TimeMap2_beatsToTime(0,REAPER_AudioTakeProps_LengthInArrangement_InQN)
	local REAPER_AudioTakeProps_StartInSource = reaper.TimeMap2_beatsToTime(0,REAPER_AudioTakeProps_StartInSource_InQN)
	
		-- NOTE: If clip is unwarped, Live saves LoopStart etc. as Time value, not QN, so that InQN value is actually Time
		if LiveAudioClip_IsWarped == "false"
		then
			REAPER_AudioTakeProps_StartInSource = REAPER_AudioTakeProps_StartInSource_InQN
		end--if
	
	local REAPER_AudioTake_SOURCE_SECTION = reaper.TimeMap2_beatsToTime(0,REAPER_AudioTake_SOURCE_SECTION_InQN)
	local REAPER_AudioTake_SOURCE_LENGTH = reaper.TimeMap2_beatsToTime(0,REAPER_AudioTake_SOURCE_LENGTH_InQN)
	

	


	-----------------------------------
	-- ADD NEW AUDIO ITEM
	-----------------------------------
	local newAudioItem = reaper.AddMediaItemToTrack(given_RPRtrack)
	local currentTake = reaper.AddTakeToMediaItem(newAudioItem) --reaper.GetTake(newAudioItem,0)
	local currentSource
	if LiveAudioClip_FileRef_DataString ~= ""
	then
		currentSource = reaper.PCM_Source_CreateFromFile(LiveAudioClip_FileRef_DataString)
	else
		currentSource = reaper.PCM_Source_CreateFromFile(LiveAudioClip_FileRef_Path)
	end
	
	reaper.SetMediaItemTake_Source(currentTake,currentSource)
			
	reaper.SetMediaItemPosition(
							newAudioItem,
							REAPER_AudioTakeProps_StartPosInArrangement,		-- position (number)
							true												-- refreshUI (boolean text)	
							)
							

	
	----------------------------------------------------------------------------------------------------------------
	-- GET MEDIA ITEM STATE CHUNK (in Reaper RPP format) AND MODIFY ITS VALUES
	----------------------------------------------------------------------------------------------------------------

	local retval, currentMediaItemStateChunk = reaper.GetItemStateChunk(newAudioItem,"",false)

	-----------------------------------------------------------------------------------------------------------------
	-- MODIFY NAME
	-----------------------------------------------------------------------------------------------------------------
	currentMediaItemStateChunk=string.gsub(currentMediaItemStateChunk,'NAME ""','NAME "'..LiveAudioClip_Name..'"')
	reaper.SetItemStateChunk(newAudioItem,currentMediaItemStateChunk,false)
	-----------------------------------------------------------------------------------------------------------------
					
	--reaper.ShowConsoleMsg('\ncurrentMediaItemStateChunk:\n'..currentMediaItemStateChunk)
	


	-----------------------------------------------------------------
	-- GET AND SET SOURCE SECTION CHUNK
	-----------------------------------------------------------------

	local currentMediaItemChunkLines_Table = makeTableFrom_RPPXMLchunk(currentMediaItemStateChunk)

	
	local ItemChunk_UPPER_Table ---from currentMediaItemChunkLines_Table
	
	for i=1,#currentMediaItemChunkLines_Table,1 
	do
		--reaper.ShowConsoleMsg('\n'..i..':'..currentMediaItemChunkLines_Table[i])
		if string.match(currentMediaItemChunkLines_Table[i],"<SOURCE WAVE")
		then
			ItemChunk_UPPER_Table = makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag(
															currentMediaItemChunkLines_Table,	-- given_Table,
															1,									-- given_StartTagIndex
															'<SOURCE WAVE'						-- given_EndTag
															)
			--printTableToConsole(ItemChunk_UPPER_Table,'ItemChunk_UPPER_Table')-- given_Table,given_TableName
			break--enclosing for
			
		elseif string.match(currentMediaItemChunkLines_Table[i],"<SOURCE MP3")
		then
			ItemChunk_UPPER_Table = makeSubtableBy_StartIndex_and_FIRST_EndTag_ExcludingEndTag(
															currentMediaItemChunkLines_Table,	-- given_Table,
															1,									-- given_StartTagIndex
															'<SOURCE MP3'						-- given_EndTag
															)
			--printTableToConsole(ItemChunk_UPPER_Table,'ItemChunk_UPPER_Table')-- given_Table,given_TableName
			break--enclosing for
			
		end--if
		
	end--for i
	

	
	local ItemChunk_SOURCEWAVE_Table
	
	
	for j=1,#currentMediaItemChunkLines_Table,1 
	do
		--reaper.ShowConsoleMsg('\n'..j..':'..currentMediaItemChunkLines_Table[j])
		if string.match(currentMediaItemChunkLines_Table[j],"<SOURCE WAVE")
		then
			ItemChunk_SOURCEWAVE_Table = makeSubtableBy_StartIndex_and_FIRST_EndTag(
															currentMediaItemChunkLines_Table,	-- given_Table,
															j,									-- given_StartTagIndex
															'>'						-- given_EndTag
															)
			--printTableToConsole(ItemChunk_SOURCEWAVE_Table,'ItemChunk_SOURCEWAVE_Table')-- given_Table,given_TableName
			break--enclosing for
			
		--reaper.ShowConsoleMsg('\n'..j..':'..currentMediaItemChunkLines_Table[j])
		elseif string.match(currentMediaItemChunkLines_Table[j],"<SOURCE MP3")
		then
			ItemChunk_SOURCEWAVE_Table = makeSubtableBy_StartIndex_and_FIRST_EndTag(
															currentMediaItemChunkLines_Table,	-- given_Table,
															j,									-- given_StartTagIndex
															'>'									-- given_EndTag
															)
			break--enclosing for
		
		end--if
			

	end--for j
	
	for ja=1,#currentMediaItemChunkLines_Table,1 
	do

	end--for j


	-- SET SOURCE SECTION values
	local ItemChunk_SOURCESECTION_Table = {
    '  <SOURCE SECTION',
    '    LENGTH '..REAPER_AudioTake_SOURCE_LENGTH,	-- Item Properties / Take media source / Length
    '    STARTPOS '..REAPER_AudioTake_SOURCE_SECTION, -- Item Properties / Take media source / Section; pos = to left; neg = to right AND EMPTY SPACE included in loop
    '    OVERLAP 0.0',
    '   '..ItemChunk_SOURCEWAVE_Table[1],	--<SOURCE WAVE
    '   '..ItemChunk_SOURCEWAVE_Table[2],	--	FILE "Y:\Samples\file.wav"
    '   '..ItemChunk_SOURCEWAVE_Table[3],	--	>
	'>'
	}
	

	local ItemChunk_LOWER_Table = {currentMediaItemChunkLines_Table[#currentMediaItemChunkLines_Table]} --should be ">"
	--printTableToConsole(ItemChunk_LOWER_Table,'ItemChunk_LOWER_Table')-- given_Table,given_TableName
	
	
	local FINAL_currentMediaItemStateChunk = ''
	
	
	for k=1,#ItemChunk_UPPER_Table,1
	do FINAL_currentMediaItemStateChunk=FINAL_currentMediaItemStateChunk..'\n'..ItemChunk_UPPER_Table[k]
	end
	
	for l=1,#ItemChunk_SOURCESECTION_Table,1
	do FINAL_currentMediaItemStateChunk=FINAL_currentMediaItemStateChunk..'\n'..ItemChunk_SOURCESECTION_Table[l]
	end
	
	for m=1,#ItemChunk_LOWER_Table,1
	do FINAL_currentMediaItemStateChunk=FINAL_currentMediaItemStateChunk..'\n'..ItemChunk_LOWER_Table[m]
	end
	
	--reaper.ShowConsoleMsg('\nFINAL_currentMediaItemStateChunk:'..FINAL_currentMediaItemStateChunk)

	if REAPER_AudioTake_ModifySOURCEProperties == true
	then
		reaper.SetItemStateChunk(newAudioItem,FINAL_currentMediaItemStateChunk,false)
	end--if
	
	
	-------------------------------------------------------------------------
	-- SET MEDIA ITEM Loop Source STATE	-- MUST BE AT THIS POINT AFTER CHUNK!
	-------------------------------------------------------------------------

	reaper.SetMediaItemInfo_Value(newAudioItem,'B_LOOPSRC',REAPER_AudioTakeProps_LoopOn)
	-- reaper.ShowConsoleMsg('\n                B_LOOPSRC set to:"'..REAPER_AudioTakeProps_LoopOn..'"')
	
	
	
	--[[-------------------------------------------------------------------------------------------------
	-- SET TAKE START OFFSET ("SOFFS" in RPP, Item Properties / Take properties / Start in source)
	-------------------------------------------------------------------------------------------------
	
	- MUST BE IN SECONDS
	
	- positive values move source TO THE LEFT = audio starts sooner; "Loop source" does not modify this
	
	- negative values move source TO THE RIGHT = audio starts later 		
			NOTE: "Loop source" MODIFIES THIS VALUE ! 
					if "Loop source" is off, then empty space added at start;
					if "Loop source" is on, then part of loop contunues at start, and this value is set to be IN RELATION TO ?????????????
	--]]------------------------------------------------------------------------------------------------------------------	
	
	reaper.SetMediaItemTakeInfo_Value(	currentTake,  						-- MediaItem_Take take,
										'D_STARTOFFS',  					-- string parmname
										REAPER_AudioTakeProps_StartInSource	-- number newvalue
										)
	
	--[[-------------------------------------------------------------------------------------------------				
	NOTE:  SOURCE (Take media source) defines the looped section of audio
			SECTION: defines start of loop; if positive, time cut from start; if negative, EMPTY time added to start AND INCLUDED IN LOOP
			LENGTH: defines area after SECTION; if longer than source audio, EMPTY SPACE ADDED AT END AND INCLUDED IN LOOP
	--]]------------------------------------------------------------------------------------------------------------------
	
	
	---------------------------------------------
	-- SET LENGTH IN ARRANGEMENT, INCLUDING LOOP
	---------------------------------------------
	
	reaper.SetMediaItemInfo_Value(newAudioItem,'D_LENGTH',REAPER_AudioTakeProps_LengthInArrangement)
	
	--[[
	reaper.SetMediaItemLength(
							newAudioItem,
							REAPER_AudioTakeProps_LengthInArrangement,	-- length (number)
							true										-- refreshUI (boolean text)	
							)
							--]]
	
	
	
	------------------------------------------
	-- SET ITEM COLOR
	------------------------------------------
	local colorIndex
	if LiveAudioClip_ColorIndex ~= nil
	then
		colorIndex = LiveAudioClip_ColorIndex
	else
		colorIndex = LiveAudioClip_Color
	end
	if colorIndex > -1 and  colorIndex < 70
	then
		for l=0,69,1  --NOTE: intentional manual values; #Live10_ColorIndexTable doesn't appear to work
		do
			if l == colorIndex
			then
				local ClipColor = reaper.ColorToNative(
											Live10_ClipColorIndexTable[l][1],
											Live10_ClipColorIndexTable[l][2],
											Live10_ClipColorIndexTable[l][3]
											)|0x01000000
											
											
				reaper.SetMediaItemInfo_Value(newAudioItem,'I_CUSTOMCOLOR',ClipColor)
			end--if
		end--for
	end--if
	
	
	---------------------
	-- SET MUTE/DISABLED
	---------------------
	if LiveAudioClip_Disabled == "true"
	then
		reaper.SetMediaItemInfo_Value(newAudioItem,'B_MUTE',1)
	end
	

	---------------------
	-- SET PITCH
	---------------------
	if LiveAudioClip_PitchCoarse ~= 0 or LiveAudioClip_PitchFine ~= 0
	then
		reaper.SetMediaItemTakeInfo_Value(	currentTake,  				-- MediaItem_Take take,
			'D_PITCH',  												-- string parmname
			LiveAudioClip_PitchCoarse + LiveAudioClip_PitchFine * 0.01	-- number newvalue
		)
	end
	
	
	-----------------------
	-- GET AND SET MARKERS 
	-----------------------
	local current_StretchMarker_SecTime = 0
	local current_StretchMarker_BeatTime_InQN = 0
	local current_StretchMarker_BeatTime = 0

	for n=1,#LiveAudioClip_WarpMarkersXMLTable,1
	do
		if string.match(LiveAudioClip_WarpMarkersXMLTable[n],'<WarpMarker Id="')
		then
		
			current_StretchMarker_SecTime = string.sub(
							LiveAudioClip_WarpMarkersXMLTable[n],
							string.find(LiveAudioClip_WarpMarkersXMLTable[n],'SecTime="')+9,
							string.find(LiveAudioClip_WarpMarkersXMLTable[n],'" BeatTime="')-1
							)
			current_StretchMarker_SecTime = tonumber(current_StretchMarker_SecTime)
							
			current_StretchMarker_BeatTime_InQN = string.sub(
							LiveAudioClip_WarpMarkersXMLTable[n],
							string.find(LiveAudioClip_WarpMarkersXMLTable[n],'BeatTime="')+10,
							string.find(LiveAudioClip_WarpMarkersXMLTable[n],'" />')-1
							)
			current_StretchMarker_BeatTime_InQN = tonumber(current_StretchMarker_BeatTime_InQN)
							
			--ShowConsoleMsg_and_AddtoLog('\n    Found a WarpMarker; SecTime: '..current_StretchMarker_SecTime..', BeatTime: '..current_StretchMarker_BeatTime)
		
			current_StretchMarker_BeatTime = reaper.TimeMap2_beatsToTime(0,current_StretchMarker_BeatTime_InQN)
		
			-- SET STRETCH MARKER
			reaper.SetTakeStretchMarker(	currentTake,	-- MediaItem_Take take, 
											-1,				-- integer idx, If idx<0, marker will be added. If idx>=0, marker will be updated
											current_StretchMarker_BeatTime,	-- number pos, 
											current_StretchMarker_SecTime	-- optional number srcposIn
											)

		
		
		end--if	

	
	end--for n
	
	-----------------------------------------------------------------
	-- INCREMENT currentProjectMediaItemCount after adding an item
	-----------------------------------------------------------------
	
	currentProjectMediaItemCount=currentProjectMediaItemCount+1
	


end--function useDataFrom_AudioClipXMLTable








--*********************************************************
-- useDataFrom_MainSequencerXMLTable
--*********************************************************

function useDataFrom_MainSequencerXMLTable(
							given_MainSequencerXMLTable,
							given_RPRtrack,
							given_TrackType
							)


-- ! ! ! ----------------------------------------------------------------------------
-- NOTE: Don't use ordered, single for loop XML traversal here, 
-- because tables here need to be made out of sync from Live's XML listing order
-- ! ! ! ----------------------------------------------------------------------------



	----------------- XML FOR AUDIO CLIPS ------------------------------------


	----------------------------------------------------------------------------------------------
	-- get <Sample> as a TABLE to contain <AudioClip Id="
	-- Live 10.0.5: <LiveSet><Tracks><AudioTrack Id="#"><DeviceChain><MainSequencer><Sample>
	----------------------------------------------------------------------------------------------
	
	local Sample_XMLTable = {}
	
	for s=1,#given_MainSequencerXMLTable,1
	do
		if string.match(given_MainSequencerXMLTable[s],'<Sample>')
		then
		
			Sample_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MainSequencerXMLTable,	-- given_Table,
																		s,								-- given_StartTagIndex
																		'</Sample>'						-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n        Sample_XMLTable indices:"..#Sample_XMLTable)
			--printTableToConsole(Sample_XMLTable,'Sample_XMLTable')-- given_Table,given_TableName
			break--enclosing for loop
		end--if
	end--for  s	
	
	
	------------------------------------------------------------------------------------------------
	-- FOR EACH <AudioClip Id=" in Sample_XMLTable, make a table for contents of <AudioClip Id="
	------------------------------------------------------------------------------------------------
	for t=1,#Sample_XMLTable,1
	do
		if string.match(Sample_XMLTable[t],'<AudioClip Id="')
		then
			--ShowConsoleMsg_and_AddtoLog('\n    Found <AudioClip Id=" at index '..t..' of Sample_XMLTable')
			local AudioClip_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		Sample_XMLTable,	-- given_Table,
																		t,					-- given_StartTagIndex
																		'</AudioClip>'		-- given_EndTag
																		)
																		
			
			reaper.ShowConsoleMsg("\n    AudioClip_XMLTable indices:"..#AudioClip_XMLTable)
			printTableToConsole(AudioClip_XMLTable,'AudioClip_XMLTable')-- given_Table,given_TableName
		
			useDataFrom_AudioClipXMLTable(
								AudioClip_XMLTable,			--given_AudioClip_XMLTable,
								given_RPRtrack			--given_RPRtrack
								)
		end--if
	end--for  t	



	----------------- XML FOR MIDI CLIPS ------------------------------------


	------------------------------------------------------------------------------------------------
	-- get <MidiControllers> as table of Id's to match MIDI CC with automations
	-- Live 10.0.5: <LiveSet><Tracks><MidiTrack Id="#"><DeviceChain><MainSequencer><MidiControllers>
	------------------------------------------------------------------------------------------------
	
	local MidiControllers_XMLTable = {}

	-- GO BACKWARDS FROM TABLE END
	for i=#given_MainSequencerXMLTable,1,-1
	do
		if string.match(given_MainSequencerXMLTable[i],'<MidiControllers>')
		then
		
			MidiControllers_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MainSequencerXMLTable,	-- given_Table,
																		i,								-- given_StartTagIndex
																		'</MidiControllers>'			-- given_EndTag
																		)
																		
			
			--reaper.ShowConsoleMsg("\n        MidiControllers_XMLTable indices:"..#MidiControllers_XMLTable)
			--printTableToConsole(MidiControllers_XMLTable,'MidiControllers_XMLTable')-- given_Table,given_TableName
			
			break --STOP the for loop when first occurrence of start is found
		end--if
	end--for  i	


	----------------------------------------------------------------------------------------------
	-- get <ClipTimeable> as a TABLE to contain <MidiClip Id="
	-- Live 10.0.5: <LiveSet><Tracks><MidiTrack Id="#"><DeviceChain><MainSequencer><ClipTimeable>
	----------------------------------------------------------------------------------------------

	local ClipTimeable_XMLTable = {}

	for j=1,#given_MainSequencerXMLTable,1
	do
		if string.match(given_MainSequencerXMLTable[j],'<ClipTimeable>')
		then
			ClipTimeable_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_MainSequencerXMLTable,	-- given_Table,
																		j,								-- given_StartTagIndex
																		'</ClipTimeable>'				-- given_EndTag
																		)

			--reaper.ShowConsoleMsg("\n        ClipTimeable_XMLTable indices:"..#ClipTimeable_XMLTable)
			--printTableToConsole(ClipTimeable_XMLTable,'ClipTimeable_XMLTable')-- given_Table,given_TableName
			break--enclosing for loop
		end--if
	end--for  j	
	
	
	------------------------------------------------------------------------------------------------
	-- FOR EACH <MidiClip Id=" in ClipTimeable_XMLTable, make a table for contents of <MidiClip Id="
	------------------------------------------------------------------------------------------------
	for k=1,#ClipTimeable_XMLTable,1
	do
		if string.match(ClipTimeable_XMLTable[k],'<MidiClip Id="')
		then
			--reaper.ShowConsoleMsg('\n    Found <MidiClip Id=" at index '..k..' of ClipTimeable_XMLTable')
			local MidiClip_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		ClipTimeable_XMLTable,	-- given_Table,
																		k,						-- given_StartTagIndex
																		'</MidiClip>'			-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n    MidiClip_XMLTable indices:"..#MidiClip_XMLTable)
			--printTableToConsole(MidiClip_XMLTable,'MidiClip_XMLTable')-- given_Table,given_TableName

			useDataFrom_MidiClipXMLTable(
								MidiClip_XMLTable,			--given_MidiClipXMLTable,
								given_RPRtrack,			--given_RPRtrack,
								MidiControllers_XMLTable	--given_MidiControllersXMLTable
								)
		end--if
		
	end--for  k	

end--function useDataFrom_MainSequencerXMLTable








--*********************************************************
-- useDataFrom_OUTER_DeviceChainXMLTable
--*********************************************************

function useDataFrom_OUTER_DeviceChainXMLTable(
							given_OUTER_DeviceChainXMLTable,
							given_RPRtrack,
							given_AutomationEnvelopesXMLTable,
							given_TrackType
							)

	--[[ 	TRACK_ROUTINGS_TABLE 
			LEVEL 1						LEVEL 2
			
			[#] track index in REAPER 	[1]AudioIn Target
										[2]MidiIn Target
										[3]AudioOut Target
										[4]MidiOut Target 
										[5]Is Sidechain Click Source 
										
			NOTE: currentTrackIndex should be global, 
			initiated before function useDataFrom_TrackXMLTable
	--]]
	
	-- MAKE NESTED TABLE FOR ROUTING DATA OF THIS TRACK
	TRACK_ROUTINGS_TABLE[currentTrackIndex] = {}
	

	-- NOTE: i=2 to skip first <DeviceChain> tag!
	for i=2,#given_OUTER_DeviceChainXMLTable,1
	do
	
		------------------------------------------------------
		-- GET <DeviceChain><AudioInputRouting> XML as a table
		------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<AudioInputRouting>')
		then
			local AudioInputRouting_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_OUTER_DeviceChainXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AudioInputRouting>'				-- given_EndTag
																		)
			AudioInputRouting_TargetValue = searchTableFor_FIRST_SingleLineXMLTagValue(AudioInputRouting_XMLTable,'<Target Value="','" />')	
			TRACK_ROUTINGS_TABLE[currentTrackIndex][1] = AudioInputRouting_TargetValue
		end--if


		------------------------------------------------------
		-- GET <DeviceChain><MidiInputRouting> XML as a table
		------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<MidiInputRouting>')
		then
			local MidiInputRouting_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_OUTER_DeviceChainXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</MidiInputRouting>'				-- given_EndTag
																		)
			MidiInputRouting_TargetValue = searchTableFor_FIRST_SingleLineXMLTagValue(MidiInputRouting_XMLTable,'<Target Value="','" />')	
			TRACK_ROUTINGS_TABLE[currentTrackIndex][2] = MidiInputRouting_TargetValue
		end--if


		-------------------------------------------------------
		-- GET <DeviceChain><AudioOutputRouting> XML as a table
		-------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<AudioOutputRouting>')
		then
			local AudioOutputRouting_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_OUTER_DeviceChainXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</AudioOutputRouting>'				-- given_EndTag
																		)
			AudioOutputRouting_TargetValue = searchTableFor_FIRST_SingleLineXMLTagValue(AudioOutputRouting_XMLTable,'<Target Value="','" />')	
			TRACK_ROUTINGS_TABLE[currentTrackIndex][3] = AudioOutputRouting_TargetValue
		end--if

	
		------------------------------------------------------
		-- GET <DeviceChain><MidiOutputRouting> XML as a table
		------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<MidiOutputRouting>')
		then
			local MidiOutputRouting_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_OUTER_DeviceChainXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</MidiOutputRouting>'				-- given_EndTag
																		)
			MidiOutputRouting_TargetValue = searchTableFor_FIRST_SingleLineXMLTagValue(MidiOutputRouting_XMLTable,'<Target Value="','" />')	
			TRACK_ROUTINGS_TABLE[currentTrackIndex][4] = MidiOutputRouting_TargetValue
		end--if

		--printTrackRoutingToConsole(currentTrackIndex)
	
		-- for checking if track is sidechain source; INITIALIZE THIS HERE!
		TRACK_ROUTINGS_TABLE[currentTrackIndex][5] = false
	
		-------------------------------------------------------------------------------------------
		-- GET <DeviceChain><Mixer> XML as a table
		-------------------------------------------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<Mixer>')
		then
			local Mixer_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																	given_OUTER_DeviceChainXMLTable,	-- given_Table,
																	i,									-- given_StartTagIndex
																	'</Mixer>'							-- given_EndTag
																	)
			--reaper.ShowConsoleMsg("\n        Mixer_XMLTable indices:"..#Mixer_XMLTable)
			--printTableToConsole(Mixer_XMLTable,'Mixer_XMLTable')-- given_Table,given_TableName
			
			useDataFrom_MixerXMLTable(
								Mixer_XMLTable,						--given_MixerXMLTable,
								given_RPRtrack,					--given_RPRtrack,
								given_AutomationEnvelopesXMLTable,	--given_AutomationEnvelopesXMLTable
								given_TrackType						--given_TrackType
								)
		end--if


		-------------------------------------------------------------------------------------------
		--GET <DeviceChain><MainSequencer> XML (contains Clips, ClipEnvelopes and MidiControllers)
		-------------------------------------------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<MainSequencer>')
		then
			local MainSequencer_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_OUTER_DeviceChainXMLTable,	-- given_Table,
																		i,									-- given_StartTagIndex
																		'</MainSequencer>'					-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n        MainSequencer_XMLTable indices:"..#MainSequencer_XMLTable)
			--printTableToConsole(MainSequencer_XMLTable,'MainSequencer_XMLTable')-- given_Table,given_TableName

			useDataFrom_MainSequencerXMLTable(
								MainSequencer_XMLTable,				--given_MainSequencerXMLTable,
								given_RPRtrack,					--given_RPRtrack
								given_TrackType						--given_TrackType
								)
		end--if


		-------------------------------------------------------------------------------------------
		--GET <DeviceChain><DeviceChain> XML (contains plugins)
		-------------------------------------------------------------------------------------------
		if string.match(given_OUTER_DeviceChainXMLTable[i],'<DeviceChain>')
		then
			local INNER_DeviceChain_XMLTable = makeSubtableBy_StartIndex_and_LAST_EndTag_ExcludingLastIndex(
																		given_OUTER_DeviceChainXMLTable,					-- given_Table,
																		i,	--NOTE: outer <DeviceChain> SKIPPED IN for loop!-- given_StartTagIndex
																		'</DeviceChain>'									-- given_EndTag
																		)
			-- reaper.ShowConsoleMsg("\n        OUTER_DeviceChainXMLTable indices:"..#given_OUTER_DeviceChainXMLTable)
			-- reaper.ShowConsoleMsg("\n        INNER_DeviceChain_XMLTable indices:"..#INNER_DeviceChain_XMLTable)
			-- printTableToConsole(INNER_DeviceChain_XMLTable,'INNER_DeviceChain_XMLTable')-- given_Table,given_TableName
			
			if INNER_DeviceChain_XMLTable ~= nil
			then
				useDataFrom_INNER_DeviceChainXMLTable(
						INNER_DeviceChain_XMLTable,			-- given_INNER_DeviceChainXMLTable,
						given_RPRtrack,						-- given_RPRtrack
						given_AutomationEnvelopesXMLTable	-- given_AutomationEnvelopesXMLTable
						)
			end--if
		

			
			if checkIfTrackIs_SIDECHAIN_CLICK(given_RPRtrack) == true
			then
				addReaSynthAs_SidechainClickSignal(given_RPRtrack)
				TRACK_ROUTINGS_TABLE[currentTrackIndex][5] = true
				
			end

		
		------------------------------------------------------------------------
		-- BREAK HERE, AS NO DATA FROM TAGS LATER THAN THIS IS NEEDED
		-- change place of this break if searches for tags after this are added
		------------------------------------------------------------------------
			break--enclosing for loop
		------------------------------------------------------------------------
			
			
		end--if string.match(given_OUTER_DeviceChainXMLTable[i],'<DeviceChain>')
		
	end--for i=2,#given_OUTER_DeviceChainXMLTable,1

end--function useDataFrom_OUTER_DeviceChainXMLTable









--*********************************************************
-- useDataFrom_TrackXMLTable
--*********************************************************

-- NOTE: REPATED FOR EACH TRACK; 
-- SO INITIALIZE outside-of-track INCREASING VARABLES as *GLOBALS* OUTSIDE FUNCTION!

currentTrackIndex = 0
RETURNtrack_LiveId_Index = 0
 
function useDataFrom_TrackXMLTable(given_TrackXMLTable)

	--reaper.ShowConsoleMsg("\n\nStarting work on track "..currentTrackIndex)
	
	local isRETURNtrack = false

	---------------------------------------------
	-- GET TYPE and Id of the track
	---------------------------------------------

	local currentTrackType = ''
	local currentTrackId = ''
	
	if string.match(given_TrackXMLTable[1],'<MidiTrack')
	then
		currentTrackType = 'MIDI'										
		currentTrackId = getValueFrom_SingleLineXMLTag(given_TrackXMLTable,1,'<MidiTrack Id="','">')		
		--reaper.ShowConsoleMsg('\n        currentTrackId:"'..currentTrackId..'"')	

	elseif string.match(given_TrackXMLTable[1],'<AudioTrack')
	then
		currentTrackType = 'AUDIO'
		currentTrackId = getValueFrom_SingleLineXMLTag(given_TrackXMLTable,1,'<AudioTrack Id="','">')		
		--reaper.ShowConsoleMsg('\n        currentTrackId:"'..currentTrackId..'"')

	elseif string.match(given_TrackXMLTable[1],'<GroupTrack')
	then
		currentTrackType = 'GROUP'
		currentTrackId = getValueFrom_SingleLineXMLTag(given_TrackXMLTable,1,'<GroupTrack Id="','">')		
		--reaper.ShowConsoleMsg('\n        currentTrackId:"'..currentTrackId..'"')
		
	
	elseif string.match(given_TrackXMLTable[1],'<ReturnTrack')
	then
		isRETURNtrack = true
		currentTrackType = 'RETURN'
		currentTrackId = getValueFrom_SingleLineXMLTag(given_TrackXMLTable,1,'<ReturnTrack Id="','">')		
		--reaper.ShowConsoleMsg('\n        currentTrackId:"'..currentTrackId..'"')
		
		local currentTrackReturnData = {currentTrackIndex,currentTrackId}
		
		TRACK_RETURNS_ID_TABLE[RETURNtrack_LiveId_Index] = currentTrackReturnData
		
		RETURNtrack_LiveId_Index = RETURNtrack_LiveId_Index+1
		
	elseif string.match(given_TrackXMLTable[1],'<MasterTrack>')
	then
		currentTrackType = 'MASTER'
		currentTrackId =  'Master'		
		--reaper.ShowConsoleMsg('\n        currentTrackId:"'..currentTrackId..'"')
	end
	
	
	TRACK_ID_TABLE[currentTrackIndex] = currentTrackId
	
	local Live_TrackEffectiveName = 'no name found'
	local LiveColorIndexValue
	local LiveColorValue
	local colorValue
	local AutomationEnvelopes_XMLTable = {}
	local OUTER_DeviceChain_XMLTable

	for i=1,#given_TrackXMLTable,1
	do
		--------------------
		-- GET TRACK NAME
		--------------------
		
		if string.match(given_TrackXMLTable[i],'<EffectiveName Value="')
		then
			Live_TrackEffectiveName = getValueFrom_SingleLineXMLTag(given_TrackXMLTable,i,'<EffectiveName Value="','" />')		
		
		
			--Live_TrackEffectiveName = '[Id='..currentTrackId..'] '..Live_TrackEffectiveName
			
			if currentTrackType == 'RETURN'
			then
				Live_TrackEffectiveName = '>> RETURN '..Live_TrackEffectiveName
			end--if
		
		
			if currentTrackType == 'GROUP'
			then
				Live_TrackEffectiveName = '!!! WAS A GROUP: '..Live_TrackEffectiveName
			end--if
		
		
			if currentTrackType == 'MASTER'
			then
				Live_TrackEffectiveName = '>>> LIVE MASTER' -- ..'[Id='..currentTrackId..']'
			end--if
			
		end--if
		
		--------------------
		-- GET TRACK COLOR
		--------------------
		if string.match(given_TrackXMLTable[i],'<ColorIndex Value="')
		then
			LiveColorIndexValue = tonumber(getValueFrom_SingleLineXMLTag(given_TrackXMLTable,i,'<ColorIndex Value="','" />'))	
		end--if
		
		if string.match(given_TrackXMLTable[i],'<Color Value="')
		then
			LiveColorValue = tonumber(getValueFrom_SingleLineXMLTag(given_TrackXMLTable,i,'<Color Value="','" />'))	
		end--if

		if LiveColorIndexValue ~= nil
		then
			colorValue = LiveColorIndexValue
		else
			colorValue = LiveColorValue
		end
		
		-------------------------------------------------------------------------
		-- GET XML CONTAINING THIS ENVELOPE LANES AND POINTS 
		-- in Live 10, these are stored in TRACK'S XML
		-- Live 10.0.5: <LiveSet><Tracks><MidiTrack Id="#"><AutomationEnvelopes>
		-------------------------------------------------------------------------
		-- GET <AutomationEnvelopes> XML as a table
		---------------------------------------------
		if string.match(given_TrackXMLTable[i],'<AutomationEnvelopes>')
		then
			AutomationEnvelopes_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_TrackXMLTable,		-- given_Table,
																		i,							-- given_StartTagIndex
																		'</AutomationEnvelopes>'	-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n    AutomationEnvelopes_XMLTable indices:"..#AutomationEnvelopes_XMLTable)
			--printTableToConsole(AutomationEnvelopes_XMLTable,'AutomationEnvelopes_XMLTable')-- given_Table,given_TableName
		end--if
	
	
		--------------------------------------------------
		-- GET first (outer) <DeviceChain> XML as a table
		--------------------------------------------------
		if string.match(given_TrackXMLTable[i],'<DeviceChain>')
		then
			
			OUTER_DeviceChain_XMLTable = makeSubtableBy_StartIndex_and_LAST_EndTag(
																		given_TrackXMLTable,		-- given_Table,
																		i,							-- given_StartTagIndex
																		'</DeviceChain>'			-- given_EndTag
																		)
			--reaper.ShowConsoleMsg("\n    OUTER_DeviceChain_XMLTable[1]:\n"..OUTER_DeviceChain_XMLTable[1])
			--reaper.ShowConsoleMsg("\n    OUTER_DeviceChain_XMLTable (#tablesize) :\n"..OUTER_DeviceChain_XMLTable[#OUTER_DeviceChain_XMLTable])
			--reaper.ShowConsoleMsg("\n    OUTER_DeviceChain_XMLTable indices:"..#OUTER_DeviceChain_XMLTable)
			--printTableToConsole(OUTER_DeviceChain_XMLTable,'OUTER_DeviceChain_XMLTable')-- given_Table,given_TableName
			
			
		------------------------------------------------------------------------
		-- BREAK HERE, AS NO DATA FROM TAGS LATER THAN THIS IS NEEDED
		-- change place of this break if searches for tags after this are added
		------------------------------------------------------------------------
			break--enclosing for loop
		------------------------------------------------------------------------
			
		end--if
	
	end--for i
	
	--=========================================================================
	-- INSERT TRACK (must be done here so next function can work on it)
	--=========================================================================
			
	ShowConsoleMsg_and_AddtoLog('\n\n'..(currentTrackIndex+1)
	..' "'..Live_TrackEffectiveName..'"'
	..' ('..currentTrackType..')'
	..' REAPER trackIndex:'..currentTrackIndex
	..' Live Id:'..currentTrackId
	)	
	
	if isRETURNtrack == true
	then 
		ShowConsoleMsg_and_AddtoLog(", isRETURNtrack:"..tostring(isRETURNtrack)..", RETURNtrack_LiveId_Index:"..RETURNtrack_LiveId_Index-1) 
		--NOTE:RETURNtrack_LiveId_Index-1 because it was incremented previously
	end--if
	
	reaper.InsertTrackAtIndex(currentTrackIndex,true)
	local trackCurrentlyWorkedOn = reaper.GetTrack(0,currentTrackIndex)
	
	-------------------
	-- SET TRACK NAME
	-------------------
	local retval, stateChunkOfCurrentTrack =  reaper.GetTrackStateChunk(trackCurrentlyWorkedOn,"",false)
	stateChunkOfCurrentTrack=string.gsub(stateChunkOfCurrentTrack,'NAME ""','NAME "'..Live_TrackEffectiveName..'"')
	reaper.SetTrackStateChunk(trackCurrentlyWorkedOn,stateChunkOfCurrentTrack,false)

	------------------------------------------
	-- SET TRACK COLOR
	------------------------------------------
	if colorValue > 139 and  colorValue < 210
	then
		for l=140,209,1  --NOTE: intentional manual values; #Live10_ColorIndexTable doesn't appear to work
		do
			if l == colorValue
			then
				-- SET TRACK COLOR
				local TrackColor = reaper.ColorToNative(
											Live10_ColorIndexTable[l][1],
											Live10_ColorIndexTable[l][2],
											Live10_ColorIndexTable[l][3]
											)
				reaper.SetTrackColor(trackCurrentlyWorkedOn,TrackColor)
			end--if
		end--for
	end--if
	
	if currentTrackType == 'GROUP'
	then
		local GroupTrackColor = reaper.ColorToNative(255,80,0)
		reaper.SetTrackColor(trackCurrentlyWorkedOn,GroupTrackColor)
	end--if
	
	if currentTrackType == 'RETURN'
	then
		local GroupTrackColor = reaper.ColorToNative(255,80,0)
		reaper.SetTrackColor(trackCurrentlyWorkedOn,GroupTrackColor)
	end--if
	
	if currentTrackType == 'MASTER'
	then
		local MasterTrackColor = reaper.ColorToNative(255,0,0)
		reaper.SetTrackColor(trackCurrentlyWorkedOn,MasterTrackColor)
	end--if
	
	
	--=========================================================================
	-- PASS OUTER_DeviceChain_XMLTable to its own function
	--=========================================================================
	
	useDataFrom_OUTER_DeviceChainXMLTable(
					OUTER_DeviceChain_XMLTable,		-- given_OUTER_DeviceChainXMLTable,
					trackCurrentlyWorkedOn,			-- given_RPRtrack
					AutomationEnvelopes_XMLTable,	-- given_AutomationEnvelopesXMLTable
					currentTrackType				-- given_TrackType
					)



	--------------------------
	-- INCREMENT TRACK INDEX
	---------------------------
	currentTrackIndex = currentTrackIndex+1
	
	
end--function useDataFrom_TrackXMLTable(given_TrackXMLTable)







function getTempoFromMasterTrack(given_LivesetXMLTable)

	------------------------------------------------------------
	-- GET <Tempo> XML as a table
	-- get <Tempo> <Manual Value="
	------------------------------------------------------------
	
	local Live_TempoTag_XMLTable
	local Live_TempoManualValue
	
	-- SEARCH FROM END OF THE SET (quicker for real-life sets with many tracks)
	-- also skips potential "tempo" words in ordinary track data etc. (unlikely but possible)?
	for n=#given_LivesetXMLTable,1,-1
	do
		if string.match(given_LivesetXMLTable[n],'<Tempo>')
		then
			Live_TempoTag_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LivesetXMLTable,	-- given_Table,
																		n,						-- given_StartTagIndex
																		'</Tempo>'				-- given_EndTag
																		)
			--printTableToConsole(Live_TempoTag_XMLTable,'Live_TempoTag_XMLTable')-- given_Table,given_TableName

			---------------------------------------------
			-- GET <Tempo><Manual Value="
			---------------------------------------------

			for ni=1,#Live_TempoTag_XMLTable,1
			do
				if string.match(Live_TempoTag_XMLTable[ni],'<Manual Value="')
				then
					Live_TempoManualValue = tonumber(getValueFrom_SingleLineXMLTag(Live_TempoTag_XMLTable,ni,'<Manual Value="','" />')) 			
					--reaper.ShowConsoleMsg('\n                Live_TempoManualValue:'..Live_TempoManualValue)
					break--enclosing for loop
				end--if
			end--for  ni
			
			--===========================================================
			-- SET CONSTANT TEMPO VALUE
			--===========================================================
			
			ShowConsoleMsg_and_AddtoLog('\nSetting main constant tempo to:'..Live_TempoManualValue)
				
				reaper.SetCurrentBPM(
									0,						--ReaProject __proj, 
									Live_TempoManualValue,	--number bpm, 
									false					--boolean wantUndo
									)
			
			
			--[[
			
			--===========================================================
			-- MAKE TEMPO ENVELOPES:  Tempo/Signature markers
			--===========================================================
			
			TO BE IMPLEMENTED
			
			boolean reaper.SetTempoTimeSigMarker(
												-- ReaProject proj, 
												-- integer ptidx, 
												-- number timepos, 
												-- integer measurepos, 
												-- number beatpos, 
												-- number bpm, 
												-- integer timesig_num, 
												-- integer timesig_denom, 
												-- boolean lineartempo
												)


			Set parameters of a tempo/time signature marker. 
			Provide either timepos (with measurepos=-1, beatpos=-1), 
			or measurepos and beatpos (with timepos=-1). 
			If timesig_num and timesig_denom are zero, 
			the previous time signature will be used. 
			ptidx=-1 will insert a new tempo/time signature marker. 
			See CountTempoTimeSigMarkers, GetTempoTimeSigMarker, AddTempoTimeSigMarker.
	
			--]]
			
			
			break--enclosing for loop
		end--if
		
	end--for  n
	
end--function getTempoFromMasterTrack









--*********************************************************
-- useDataFrom_LocatorsXMLTable
--*********************************************************
function useDataFrom_LocatorsXMLTable(given_LocatorsXMLTable)	
	
	for i=1,#given_LocatorsXMLTable,1
	do
		if string.match(given_LocatorsXMLTable[i],'<Locator Id="')
		then
			Locator_XMLTable = makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LocatorsXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</Locator>'			-- given_EndTag
																		)
			--printTableToConsole(Locator_XMLTable,'Locator_XMLTable')-- given_Table,given_TableName

			local Locator_Id = tonumber(getValueFrom_SingleLineXMLTag(given_LocatorsXMLTable,i,'<Locator Id="','">')) 		
			local Locator_TimeValue = 0
			local Locator_NameValue = 'Locator_NameValue'

			---------------------------------------------
			-- GET <Locator Id="><Time Value="
			---------------------------------------------

			for j=1,#Locator_XMLTable,1
			do
				if string.match(Locator_XMLTable[j],'<Time Value="')
				then
					Locator_TimeValue = tonumber(getValueFrom_SingleLineXMLTag(Locator_XMLTable,j,'<Time Value="','" />')) 			
					--reaper.ShowConsoleMsg('\n                Locator_TimeValue:'..Locator_TimeValue)
					break--enclosing for loop
				end--if
			end--for  j
			
			---------------------------------------------
			-- GET <Locator Id="><Name Value="
			---------------------------------------------			
			
			for k=1,#Locator_XMLTable,1
			do
				if string.match(Locator_XMLTable[k],'<Name Value="')
				then
					Locator_NameValue = getValueFrom_SingleLineXMLTag(Locator_XMLTable,k,'<Name Value="','" />')		
					--reaper.ShowConsoleMsg('\n                Locator_NameValue:'..Locator_NameValue)
					break--enclosing for loop
				end--if
			end--for  k
			
			
			---------------------------------------------
			-- ADD REAPER PROJECT MARKERS
			---------------------------------------------
			
			Locator_TimeValue_RPR = reaper.TimeMap_QNToTime(Locator_TimeValue)
			
			reaper.AddProjectMarker(	0, 						-- ReaProject proj
										0, 						-- boolean isrgn
										Locator_TimeValue_RPR, 	-- number pos
										0,						-- number rgnend
										Locator_NameValue, 		-- string name
										Locator_Id				-- integer wantidx
										)
			
		end--if string.match
		
	end--for i=1,#given_LocatorsXMLTable,1
	
end--function useDataFrom_LocatorsXMLTable




--*********************************************************
-- startParsingLiveSetXML
--*********************************************************

function startParsingLiveSetXML(given_LiveSetXMLTable)


	-------------------------------------------------------------------
	-- GET AND SET Tempo (might affect conversions later, so done here)
	-------------------------------------------------------------------
	getTempoFromMasterTrack(given_LiveSetXMLTable)
	
	
	-------------------------------------------------------
	-- GET Locators XML FOR EACH TRACK
	-------------------------------------------------------	
	

	-- search from end of given_Table
	for readPosLoc=#given_LiveSetXMLTable,1,-1
	do
		if string.match(given_LiveSetXMLTable[readPosLoc],'<Locators>')
		then
		
		--reaper.ShowConsoleMsg("\n    <Locators> at position:\n"..readPosLoc)
			
		local LocatorsXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		readPosLoc,				-- given_StartTagIndex
																		'</Locators>'			-- given_EndTag
																		)
																		
		--reaper.ShowConsoleMsg("\n    #LocatorsXMLTable:\n"..#LocatorsXMLTable)
		--printTableToConsole(LocatorsXMLTable,'LocatorsXMLTable')-- given_Table,given_TableName
		
		-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
		useDataFrom_LocatorsXMLTable(LocatorsXMLTable)	
		
		break
																		
		end--if
	end--for																	
	
	
	
	
	
	-------------------------------------------------------
	-- GET TRACK XML FOR EACH TRACK
	-------------------------------------------------------
	for i=1,#given_LiveSetXMLTable,1
	do
		if string.match(given_LiveSetXMLTable[i],'<GroupTrack Id="')
		then	
			local GroupTrackXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</GroupTrack>'			-- given_EndTag
																		)
			-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
			useDataFrom_TrackXMLTable(GroupTrackXMLTable)																		
			
			for ii=1,#GroupTrackXMLTable,1
			do
				if string.match(GroupTrackXMLTable[ii],'<EffectiveName Value="')
				then
					GroupTrackName = getValueFrom_SingleLineXMLTag(GroupTrackXMLTable,ii,'<EffectiveName Value="','" />') 			
					break--enclosing for loop
				end--if
			end--for  ni
													
			local GroupTrackWarning = 'GROUP TRACK "'..GroupTrackName..'" was NOT imported as a group/folder track.'
			..'\n        Workaround: Check its settings from Live and manually replicate them in REAPER.'
			table.insert(WARNINGS_TABLE,GroupTrackWarning)
		end
	

		if string.match(given_LiveSetXMLTable[i],'<MidiTrack Id="')
		then	
			local MidiTrackXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</MidiTrack>'			-- given_EndTag
																		)
			-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
			useDataFrom_TrackXMLTable(MidiTrackXMLTable)
		end
		
		
		if string.match(given_LiveSetXMLTable[i],'<AudioTrack Id="')
		then
			local AudioTrackXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</AudioTrack>'			-- given_EndTag
																		)
			-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
			useDataFrom_TrackXMLTable(AudioTrackXMLTable)
		end
		
		
		if string.match(given_LiveSetXMLTable[i],'<ReturnTrack Id="')
		then
			local ReturnTrackXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</ReturnTrack>'		-- given_EndTag
																		)
			-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
			useDataFrom_TrackXMLTable(ReturnTrackXMLTable)
		end
		
		
		if string.match(given_LiveSetXMLTable[i],'<MasterTrack>')
		then
			local MasterTrackXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</MasterTrack>'		-- given_EndTag
																		)
			-- PASS TRACK XML FORWARD TO ITS OWN FUNCTION
			useDataFrom_TrackXMLTable(MasterTrackXMLTable)
		
		end
		
		
		if string.match(given_LiveSetXMLTable[i],'<GroovePool>')
		then
			local GroovePoolXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		given_LiveSetXMLTable,	-- given_Table,
																		i,						-- given_StartTagIndex
																		'</GroovePool>'		-- given_EndTag
																		)
			for gp=1,#GroovePoolXMLTable,1
			do
				if string.match(GroovePoolXMLTable[gp],'<Groove Id="')
				then
					local GrooveId = getValueFrom_SingleLineXMLTag(GroovePoolXMLTable,gp,'<Groove Id="','">') 
					local GrooveIdXMLTable =  makeSubtableBy_StartIndex_and_FIRST_EndTag(
																		GroovePoolXMLTable,	-- given_Table,
																		gp,					-- given_StartTagIndex
																		'</Groove>'			-- given_EndTag
																		)
					local GrooveName = searchTableFor_FIRST_SingleLineXMLTagValue(GrooveIdXMLTable,'<Name Value="','" />')
					local GROOVEDATATABLE = {}
					GROOVEDATATABLE[0] = GrooveId
					GROOVEDATATABLE[1] = GrooveName
					table.insert(GROOVE_ID_TABLE,GROOVEDATATABLE)
				end--if
			
			end--for
			
			
		------------------------------------------------------------------------
		-- BREAK HERE, AS NO DATA FROM TAGS LATER THAN THIS IS NEEDED
		-- change place of this break if searches for tags after this are added
		------------------------------------------------------------------------
			break--enclosing for loop
		-------------------------------------------------------------------------
		
		end--if
		
		
	end--for i
	

	------------------------------------------------------------------
	-- APPLY TRACK ROUTING and SENDS
	------------------------------------------------------------------
	
	applyTrackRouting()
	
	applySendsToReturns()
	
	
	
	----------------------------------------------
	-- CHECK FOR COMPRESSORS' SIDECHAIN ROUTINGS	
	----------------------------------------------
	ShowConsoleMsg_and_AddtoLog('\n\nApplying SIDECHAINs from Live Compressors to ReaComps...')	
	if #REACOMPS_SIDECHAINS_SETTINGS_TABLE > 0
	then
	
	
		-- FOR CHECKING and NOT DUPLICATING SENDS; PER TRACK
		local num_of_recvs_on_DESTINATION
		local DESTINATION_GivenReceiveOnChannels
	
		local LastSet_DestinationTrack
		local LastSet_ReceiveNumber
		local LastSet_ChannelsOnReceive
	
		for i=1,#REACOMPS_SIDECHAINS_SETTINGS_TABLE,1
		do
			local SourceTrack_REAPERtrackIndex = -1
			
			for j=0,#TRACK_ID_TABLE,1
			do
				if TRACK_ID_TABLE[j] == REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][2]
				then
					SourceTrack_REAPERtrackIndex = j
				end
			end
			
			if SourceTrack_REAPERtrackIndex > -1
			then
				
				local SOURCE_REAPERtrack = reaper.GetTrack(0,SourceTrack_REAPERtrackIndex)
				local retval, SOURCE_REAPERtrack_name = reaper.GetTrackName(SOURCE_REAPERtrack,'')
				
				local DESTINATION_REAPERtrack = reaper.GetTrack(0,REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][0])
				local retval, DESTINATION_REAPERtrack_name = reaper.GetTrackName(DESTINATION_REAPERtrack,'')
			
				local SendMode = tonumber(REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][3])
				local SendVolume = tonumber(REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][4])
				

				-----------------------------------------------------------
				-- UPDATE VALUES FOR CHECKING
				-----------------------------------------------------------
				num_of_recvs_on_DESTINATION = reaper.GetTrackNumSends( --returns number of sends/receives/hardware outputs 
																			DESTINATION_REAPERtrack, 	-- MediaTrack tr, 
																			-1							-- integer category	<0 = receives, 0=sends, >0 hardware outputs
																			)
				DESTINATION_GivenReceiveOnChannels = reaper.GetTrackSendInfo_Value(
															DESTINATION_REAPERtrack,			-- MediaTrack tr, 
															-1,									-- integer category, <0 = recv, 0=sends, >0 hw out
															(num_of_recvs_on_DESTINATION-1),	-- integer sendidx, 
															'I_DSTCHAN'							-- string parmname
															)
				
				
				-----------------------------------------------------------
				-- CHECK NUMBER OF EXISTING RECEIVES on DESTINATION track
				-----------------------------------------------------------
				
				local SameExactSendAsPrevious = false
				
				if LastSet_DestinationTrack == DESTINATION_REAPERtrack
				and LastSet_ReceiveNumber == num_of_recvs_on_DESTINATION
				and	LastSet_ChannelsOnReceive == DESTINATION_GivenReceiveOnChannels
				then
				
					SameExactSendAsPrevious = true
					ShowConsoleMsg_and_AddtoLog('\n        NOTE: several compressors receive channels 3/4 on this track ')
					--reaper.ShowConsoleMsg('\n LastSet_DestinationTrack == DESTINATION_REAPERtrack,'
					--..'LastSet_ReceiveNumber == num_of_recvs_on_DESTINATION'
					--..'LastSet_ChannelsOnReceive == DESTINATION_GivenReceiveOnChannels')
				end
				
				
				if SameExactSendAsPrevious == false
				then 

					----------------------
					-- APPLY ROUTING
					----------------------
					
					ShowConsoleMsg_and_AddtoLog('\n'
					..'    On track idx '..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][0]..' "'..DESTINATION_REAPERtrack_name..'"'
					..' ReaComp in FXidx '..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][1]
					..' receives SC from'
					--..' SOURCE Live Track Id:'..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][2]
					..' trackidx '..SourceTrack_REAPERtrackIndex..' "'..SOURCE_REAPERtrack_name..'"'
					..', SC SENDMODE:'..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][3]
					..', Vol ManVal:'..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][4]
					..', Vol AuTargId:'..REACOMPS_SIDECHAINS_SETTINGS_TABLE[i][5]
					)

					-- Create a send/receive (desttrInOptional!=NULL), 
					-- or a hardware output (desttrInOptional==NULL) with default properties, 
					-- returns >=0 on success (== new send/receive index)
					local newSideChainSendIndex = reaper.CreateTrackSend(
															SOURCE_REAPERtrack,			-- SOURCE MediaTrack tr
															DESTINATION_REAPERtrack		-- DESTINATION MediaTrack desttrIn
															)
				
					reaper.SetTrackSendInfo_Value(
								SOURCE_REAPERtrack,			-- MediaTrack tr;
								0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
								newSideChainSendIndex,		-- send index (integer)
								'I_SENDMODE',				-- parameter name (string)
								SendMode					-- new value (number) --0=post-fader, 1=pre-fx, 3=post-fx
								)
								
					reaper.SetTrackSendInfo_Value(
								SOURCE_REAPERtrack,			-- MediaTrack tr;
								0,							-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
								newSideChainSendIndex,		-- send index (integer)
								'D_VOL',					-- parameter name (string)
								SendVolume					-- new value (number) 
								)
					

					-- route audio to channel pair 2 (3/4) -- 0=1/2, 2=3/4, 4=5/6,
					reaper.SetTrackSendInfo_Value(
									SOURCE_REAPERtrack,		-- MediaTrack tr;
									0, 						-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									newSideChainSendIndex,	-- send index (integer)
									"I_DSTCHAN",			-- parameter name (string)
									2						-- new value (number)
									)

					--disable MIDI receiving
					reaper.SetTrackSendInfo_Value(	
									SOURCE_REAPERtrack, 	-- MediaTrack tr;
									0,						-- category (integer) <0 = receives, 0=sends, >0 hardware outputs
									newSideChainSendIndex,	-- send index (integer)
									"I_MIDIFLAGS",			-- parameter name (string)
									31
									)
								
			
				end--if SameExactSendAsPrevious == false
				
				
				-----------------------------------------------------------
				-- UPDATE VALUES FOR CHECKING
				-----------------------------------------------------------
				num_of_recvs_on_DESTINATION = reaper.GetTrackNumSends( --returns number of sends/receives/hardware outputs 
																			DESTINATION_REAPERtrack, 	-- MediaTrack tr, 
																			-1							-- integer category	<0 = receives, 0=sends, >0 hardware outputs
																			)
				DESTINATION_GivenReceiveOnChannels = reaper.GetTrackSendInfo_Value(
															DESTINATION_REAPERtrack,			-- MediaTrack tr, 
															-1,									-- integer category, <0 = recv, 0=sends, >0 hw out
															(num_of_recvs_on_DESTINATION-1),	-- integer sendidx, 
															'I_DSTCHAN'							-- string parmname
															)
				LastSet_DestinationTrack = DESTINATION_REAPERtrack
				LastSet_ReceiveNumber = num_of_recvs_on_DESTINATION
				LastSet_ChannelsOnReceive = DESTINATION_GivenReceiveOnChannels	
				
				--reaper.ShowConsoleMsg('\n DESTINATION Track "'..DESTINATION_REAPERtrack_name..'"'
				--..' has '..num_of_recvs_on_DESTINATION..' receives; '
				--..' last receive '..num_of_recvs_on_DESTINATION..' receives to chans '..DESTINATION_GivenReceiveOnChannels)

		

				
				
				--[[
		
				LATER: automatically increase plugin pins etc... NOTE: some of this code already exists in your sidechain routing function
				
				-- CHECK FOR EXISTING SENDS TO DESTINATION TRACK
				
				0 check whether thisREAPERtrack has sends to 3/4, if so, send to later ones
			
				
				
				]]--

			
				
			end--if SourceTrack_REAPERtrackIndex > -1
			
		end--for i=1,#REACOMPS_SIDECHAINS_SETTINGS_TABLE,1
		
	elseif	#REACOMPS_SIDECHAINS_SETTINGS_TABLE == 0
	then
	ShowConsoleMsg_and_AddtoLog('\nNo "Compressor to ReaComp" sidechain routings found')
	end--if #REACOMPS_SIDECHAINS_SETTINGS_TABLE > 0
	



	------------------------------------------------------------------
	-- SET ALL ENVELOPES VISIBLE
	------------------------------------------------------------------
					
	reaper.Main_OnCommand(41149, 0) -- Envelope: Show all envelopes for tracks
	

	------------------------------------------------------------------
	-- SHOW REPORT
	------------------------------------------------------------------
	 
	local endReport = 'Importing finished'
	..'\n Tracks imported:'..currentTrackIndex
	..'\n'
	..'\nIMPORTANT!  To continue work on this imported project:' 
	..'\n		1. first save it as new REAPER project (.RPP)'
	..'\n		2. then restart REAPER and open that .RPP project.'
	..'\n'
	..'\nOtherwise automation and routings may not be active.'
	..'\n'
	..'\nClick OK to continue and see any warnings in Console'
	..'\n (check Console before clicking OK to see data about elements which were imported without issues)'
	..'\n'
	reaper.ShowConsoleMsg('\n\n'..endReport)
	reaper.ShowMessageBox(endReport, "Import finished", 0)
	
	
	local ThereWereWarnings = false
	
	------------------------------------------------------------------
	-- SHOW WARNINGS TABLE
	------------------------------------------------------------------
	
	if #WARNINGS_TABLE > 0
	then	
			ThereWereWarnings = true
			
			ShowConsoleMsg_and_AddtoLog('\n\n\nWARNINGS:\n--------------------------------------------------------------\n')
	
		for p=1,#WARNINGS_TABLE,1
		do
			ShowConsoleMsg_and_AddtoLog('\n'..WARNINGS_TABLE[p])
		end--for
	end--if
	
	------------------------------------------------------------------
	-- SHOW Clips with offsets REPORT
	------------------------------------------------------------------
	
	if #TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS > 0
	then
		
		ThereWereWarnings = true
	
		ShowConsoleMsg_and_AddtoLog('\n\nWARNING: The Live project had clips with start offsets in loops or unlooped clips.'
		..' Importing those settings is not supported. \nConsolidate the following clips before attempting import again:\n')
	
		for q=1,#TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS,1
		do
			ShowConsoleMsg_and_AddtoLog('\n'..TABLE_OF_CLIPS_WITH_OFFSET_LOOPS_OR_STARTS[q])
		end--for
	end--if
	
	------------------------------------------------------------------
	-- SHOW Clips with Grooves REPORT
	------------------------------------------------------------------
	--[[
	
	CLIPS_WITH_GROOVES_TABLE
	-----------------------------------------------
	[#] TABLE INDEX 1-## 	[0] = currentTrackIndex
							[1] = thisTrackName
							[2] = ((LiveMidiClip_CurrentStart/4)+1) -- at bar
							[3] = LiveMidiClip_CurrentStart -- at 1/4th
							[4] = currentClipsGrooveId
							[5] = clip name
							
	GROOVE_ID_TABLE
	-----------------------------------------------
	[#] TABLE INDEX 1-##	[0] = GrooveId
							[1] = GrooveName			--]]
		
	
	if #CLIPS_WITH_GROOVES_TABLE > 0
	then
		
		ThereWereWarnings = true

		ShowConsoleMsg_and_AddtoLog('\n\nWARNING: The Live project had clips with grooves.' 
		..'\nCommit grooves before attempting import again (select all groove-containing clips, press Commit in Live\'s Clip View):')
	
		for gr=1,#CLIPS_WITH_GROOVES_TABLE,1
		do
			local GrooveNameById = ''
			
			for grIx=1,#GROOVE_ID_TABLE,1
			do
				if GROOVE_ID_TABLE[grIx][0] == CLIPS_WITH_GROOVES_TABLE[gr][4]
				then
					GrooveNameById = GROOVE_ID_TABLE[grIx][1] 
				end
			end

		
			local ClipsGroovesReport = '\n'
			..'    On track:'..(CLIPS_WITH_GROOVES_TABLE[gr][0])+1 	-- currentTrackIndex
			..' "'..CLIPS_WITH_GROOVES_TABLE[gr][1]..'"' 			-- thisTrackName
			..' at bar '..CLIPS_WITH_GROOVES_TABLE[gr][2]
			..' (in 1/4th:'..CLIPS_WITH_GROOVES_TABLE[gr][3]..')' 
			..' the Clip "'..CLIPS_WITH_GROOVES_TABLE[gr][5]..'"' 
			..' uses groove: "'..GrooveNameById..'"'
			..' (Groove Id:'..CLIPS_WITH_GROOVES_TABLE[gr][4]..')'
			
			ShowConsoleMsg_and_AddtoLog(ClipsGroovesReport)
			
		end--for
	end--if


	if writeLogFile == true --and ThereWereWarnings == true
	then
        
        local WarningMessage = ""
        
        if ThereWereWarnings == true 
        then 
            WarningMessage = "There were warnings during import." 
        end--if
    
    
		local askToSaveLog = reaper.ShowMessageBox(WarningMessage.." \n\nSave a log file into same directory as selected un-gzipped project file?", "Save a log file?", 1)

		if askToSaveLog==1
		then
			local currentTime = os.date("%Y-%m-%d %H%M%S")
			newLogFile = io.open(pathToFile.." Import Log "..currentTime..".txt", "w")
			newLogFile:write(LogFileContent)
			newLogFile:close()

			reaper.ShowConsoleMsg("\n\nLog SAVED TO FILE: "..pathToFile.." Import Log "..currentTime..".txt")
		end--if

	end--if writeLogFile == true
	
	

	
	

end--function startParsingLiveSetXML() -------------------------------------------------------------------------------------------------------------








--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
-- START THE SCRIPT'S FUNCTIONALITY
--------------------------------------------------------

if continue==true
then

	local selectedFileContents = getFileForReading()

	startTimeInSeconds = reaper.time_precise()
	
	startParsingLiveSetXML(selectedFileContents)

	--search_for_Tracks(selectedFileContents)
	
end


