; Use Ctrl '/' to toggle Map/Compass window updates
#Requires AutoHotkey v2.0 ; download from https://autohotkey.com/download/
#SingleInstance 
#Warn  ; To assist with detecting common errors.
#MaxThreadsPerHotkey 2

Active := False
Secs := 5 ; seconds between updates
Command := "/llh `;loc{Enter}"

^/:: {
	global Active := not Active
	if not Active SoundBeep()
	SoundBeep()
	While Active {
	  if WinActive("Lord of the Rings Online™") {
		SendInput Command
	  }
	  Sleep Secs*1000
	} 
	Return
}
