state("launcher")
{
	float IGT: "game.dll", 0x01F670, 0x0;				// this float ticks every frame while the game is "running"
	string32 LevelName: "game.dll", 0x05B34C, 0x6C;		// this string is changed only on new game start and when level has changed USING DOORS!!! save loads don`t affect this
	byte mainMenuisOpen: "game.dll", 0x002F04, 0x8; 	// this byte switches 0<->1 if the main menu state is changed
	byte newGameMenuisOpen: "game.dll", 0x003024, 0x8;	// this byte switches 0<->1 if the new game menu state is changed
	byte loadMenuisOpen: "game.dll", 0x002DE4, 0x8;		// this byte switches 0<->1 if the load game menu state is changed
	byte gameIsRunning: "game.dll", 0x01F97C, 0x0;		// this byte switches 0<->1 if the game is "running" (game time can still stop/tick independently)
}

init {
	print("Init done");
}

startup {
	settings.Add("subsplitsEnabled", false, "Split on every level");
	settings.SetToolTip("subsplitsEnabled", "Turn this setting ON if you want the autosplitter to split on every door entry");
	
	settings.Add("skipWelltoLevelsSplit", true, "Dont split on (R_Well --> R_Levels) transition", "subsplitsEnabled");
	settings.SetToolTip("skipWelltoLevelsSplit", "Turn this setting ON if you want the autosplitter to NOT split on a very short transition from Redzone_Well to Redzone_Levels map");
	
	settings.Add("skipLevelstoWellSplit", false, "Dont split on (R_Levels --> R_Well) transition", "subsplitsEnabled");
	settings.SetToolTip("skipLevelstoWellSplit", "Turn this setting ON if you DONT use  R_Well split at all");
	
	settings.Add("chapterSplitsEnabled", true, "Split on every Chapter switch");
	settings.SetToolTip("chapterSplitsEnabled", "Turn this setting ON if you want the autosplitter to split whenever you leave any of the zones (White/Green/Red/Blue/Yellow/Black)");
	
	settings.Add("resetOnLoad", true, "Reset timer on game load");
	settings.SetToolTip("resetOnLoad", "Turn this setting ON if you want timer to reset when you load a save");
	
	print("Startup done");
}

start {
	vars.runHasEnded = false; // a toggle to split only once at the end
	
	if(current.IGT == 0 && current.LevelName == "W_Start"){
		return true;	// start the livesplit whenever the IGT is ready to tick and we're in the starting room
	}
}

split{
	if (current.IGT != 0 && current.gameIsRunning == 0 && !vars.runHasEnded) {
		vars.runHasEnded = true; // toggling this so the autosplitter splits only once at the end of the game
		return true; 	// at the end of the game split if the game is not "running" anymore but the time was ticking, so we're for sure not in the main menu
	}
	if (current.LevelName != old.LevelName && settings["subsplitsEnabled"]) {
		if(settings["skipWelltoLevelsSplit"] && current.LevelName == "R_Levels" && old.LevelName == "R_Well"){
			return false; 	// exception for the tiny segment in R_Well (it's <1s, just ignore it)
		}
		if(settings["skipLevelstoWellSplit"] && current.LevelName == "R_Well" && old.LevelName == "R_Levels"){
			return false; 	// exception for those who dont want to use the R_Well at all
		}
		return true;
	} else if (settings["chapterSplitsEnabled"]) {
		if(current.LevelName == "W_Hall" && old.LevelName == "W_Doors"){
			return true; // split for legacy tutorial ending (real one is at the end of the hallway)
		} else if(current.LevelName == "R_Bridge" && old.LevelName == "G_RedCube"){
			return true; // split for Green -> Bridge transition
		} else if(current.LevelName == "R_Bridge" && old.LevelName == "R_Double"){
			return true; // split for Red -> Bridge transition
		} else if(current.LevelName == "R_Bridge" && old.LevelName == "B_Long"){
			return true; // split for Blue -> Bridge transition (only needed for "True endings" runs)
		} else if(current.LevelName == "D_FloorA" && old.LevelName == "R_Descent"){
			return true; // split for Red -> Black transition (only needed for "True endings" or Glitchless runs)
		} else if(current.LevelName == "R_Grate" && old.LevelName == "D_Oven"){
			return true; // split for Black -> Red transition (only needed for "True endings" or Glitchless runs)
		} else if(current.LevelName == "Y_Frame" && old.LevelName == "G_YellowStart"){
			return true; // split for Green -> Yellow transition (only needed for "True endings" or Glitchless runs)
		} else if(current.LevelName == "G_YellowStart" && old.LevelName == "Y_Frame"){
			return true; // split for Yellow -> Green transition (only needed for "True endings" or Glitchless runs)
		}
	}
}

reset{
	if(current.mainMenuisOpen == 0 && current.newGameMenuisOpen == 0 && old.newGameMenuisOpen == 1){
		return true; // This relies on "New Game Menu" being closed only by either going back to main menu or by a new game start, and resets the timer if you start a new game
	} else if(current.mainMenuisOpen == 0 && current.loadMenuisOpen == 0 && old.loadMenuisOpen == 1){
		return true; // This relies on "Load Game Menu" being closed only by either going back to main menu or by a game load, and resets the timer if you load a game save
	}
}

isLoading{
	if(current.IGT == old.IGT){
		return true; 	// pause igt of livesplit if the game clock isn't ticking
	} else {
		return false; 	// unpase it
	}
}

gameTime{
	if(current.IGT > old.IGT){
		return TimeSpan.FromSeconds(current.IGT);	// pass the igt straight from the game, luckily game`s clock is consistent
	}
}
