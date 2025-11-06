#!/usr/bin/osascript
-- Knowledge Base Audiobook Organization
-- Creates hierarchical playlists and sets up smart playlists

tell application "Music"
	-- Create folder structure
	try
		set kbFolder to folder playlist "Knowledge Base Audiobooks"
	on error
		set kbFolder to (make new folder playlist with properties {name:"Knowledge Base Audiobooks"})
	end try

	-- Tier 1 Patterns playlist
	try
		set tier1 to user playlist "KB: Tier 1 Patterns"
	on error
		set tier1 to (make new user playlist with properties {name:"KB: Tier 1 Patterns", parent:kbFolder})
	end try

	-- Voice Auditions playlist
	try
		set auditions to user playlist "KB: Voice Auditions"
	on error
		set auditions to (make new user playlist with properties {name:"KB: Voice Auditions", parent:kbFolder})
	end try

	-- Clear existing tracks to avoid duplicates
	delete tracks of tier1
	delete tracks of auditions

	-- Add Tier 1 cinematic tracks
	set tier1Tracks to (every track whose album is "KB Tier 1 Patterns" or name contains "CINEMATIC")
	repeat with aTrack in tier1Tracks
		try
			duplicate aTrack to tier1
		end try
	end repeat

	-- Add voice audition tracks
	set auditionTracks to (every track whose album is "Voice Auditions" or (name contains "Daniel_" or name contains "Brian_" or name contains "Eric_" or name contains "Chris_"))
	repeat with aTrack in auditionTracks
		try
			duplicate aTrack to auditions
		end try
	end repeat

	-- Create category playlists

	-- Short form (under 5 minutes)
	try
		set shortForm to user playlist "KB: Short Form (<5min)"
	on error
		set shortForm to (make new user playlist with properties {name:"KB: Short Form (<5min)", parent:kbFolder})
	end try

	-- Code-heavy patterns
	try
		set codeHeavy to user playlist "KB: Code-Heavy"
	on error
		set codeHeavy to (make new user playlist with properties {name:"KB: Code-Heavy", parent:kbFolder})
	end try

	-- Filter tracks manually (safer than time comparison)
	delete tracks of shortForm
	delete tracks of codeHeavy

	repeat with aTrack in tier1Tracks
		-- Add to code-heavy if name contains relevant keywords
		set trackName to name of aTrack as string
		if trackName contains "api" or trackName contains "secure" or trackName contains "streaming" then
			try
				duplicate aTrack to codeHeavy
			end try
		end if
	end repeat

	set shortCount to 0
	set codeCount to count of tracks of codeHeavy

	return "✅ Playlists organized: " & (count of tier1Tracks) & " Tier 1 patterns, " & (count of auditionTracks) & " auditions, " & codeCount & " code-heavy"
end tell
