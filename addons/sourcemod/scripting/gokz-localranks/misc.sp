/*
	Miscellaneous functions.
*/



// =====[ COMPLETION MVP STARS ]=====

void CompletionMVPStarsUpdate(int client)
{
	DB_GetCompletion(client, GetSteamAccountID(client), GOKZ_GetDefaultMode(), false);
}

void CompletionMVPStarsUpdateAll()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			CompletionMVPStarsUpdate(client);
		}
	}
}



// =====[ ANNOUNCEMENTS ]=====

void PrecacheAnnouncementSounds()
{
	if (!LoadSounds())
	{
		SetFailState("Failed to load file: \"%s\".", LR_CFG_SOUNDS);
	}
}

static bool LoadSounds()
{
	KeyValues kv = new KeyValues("sounds");
	if (!kv.ImportFromFile(LR_CFG_SOUNDS))
	{
		return false;
	}
	
	char downloadPath[256];
	
	kv.GetString("beatrecord", gC_BeatRecordSound, sizeof(gC_BeatRecordSound));
	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", gC_BeatRecordSound);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSound(gC_BeatRecordSound, true);
	
	delete kv;
	return true;
}

static void PlayBeatRecordSound()
{
	EmitSoundToAll(gC_BeatRecordSound);
}

void AnnounceNewTime(
	int client, 
	int course, 
	int mode,
	int style,
	float runTime, 
	int teleportsUsed, 
	bool firstTime, 
	float pbDiff, 
	int rank, 
	int maxRank, 
	bool firstTimePro, 
	float pbDiffPro, 
	int rankPro, 
	int maxRankPro)
{
	// Main Course
	if (course == 0)
	{
		// Main Course PRO Times
		if (teleportsUsed == 0)
		{
			if (firstTimePro)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - First Time (PRO)", 
					client, GOKZ_FormatTime(runTime), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else if (pbDiffPro < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Beat PB (PRO)", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiffPro)), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Miss PB (PRO)", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiffPro), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
		// Main Course NUB Times
		else
		{
			if (firstTime)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - First Time", 
					client, GOKZ_FormatTime(runTime), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else if (pbDiff < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Beat PB", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiff)), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Miss PB", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiff), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
	}
	// Bonus Course
	else
	{
		// Bonus Course PRO Times
		if (teleportsUsed == 0)
		{
			if (firstTimePro)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - First Time (PRO)", 
					client, course, GOKZ_FormatTime(runTime), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else if (pbDiffPro < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Beat PB (PRO)", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiffPro)), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Miss PB (PRO)", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiffPro), rankPro, maxRankPro, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
		// Bonus Course NUB Times
		else
		{
			if (firstTime)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - First Time", 
					client, course, GOKZ_FormatTime(runTime), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else if (pbDiff < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Beat PB", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiff)), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Miss PB", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiff), rank, maxRank, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
	}
}

void AnnounceNewRecord(int client, int course, int mode, int style, int recordType)
{
	if (course == 0)
	{
		switch (recordType)
		{
			case RecordType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (NUB)", client, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			case RecordType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (PRO)", client, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			case RecordType_NubAndPro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (NUB and PRO)", client, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
	}
	else
	{
		switch (recordType)
		{
			case RecordType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (NUB)", client, course, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			case RecordType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (PRO)", client, course, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
			case RecordType_NubAndPro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (NUB and PRO)", client, course, course, gC_ModeNamesShort[mode], gC_StyleNamesShort[style]);
			}
		}
	}
	
	PlayBeatRecordSound(); // Play sound!
}



// =====[ MISSED RECORD TRACKING ]=====

void ResetRecordMissed(int client)
{
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		gB_RecordMissed[client][timeType] = false;
	}
}

void UpdateRecordMissed(int client)
{
	if (!GOKZ_GetTimerRunning(client) || gB_RecordMissed[client][TimeType_Nub] && gB_RecordMissed[client][TimeType_Pro])
	{
		return;
	}
	
	int course = GOKZ_GetCourse(client);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);
	float currentTime = GOKZ_GetTime(client);
	
	bool nubRecordExists = gB_RecordExistsCache_Nub[course][mode][style];
	float nubRecordTime = gF_RecordTimesCache_Nub[course][mode][style];
	bool nubRecordMissed = gB_RecordMissed[client][TimeType_Nub];
	bool proRecordExists = gB_RecordExistsCache_Pro[course][mode][style];
	float proRecordTime = gF_RecordTimesCache_Pro[course][mode][style];
	bool proRecordMissed = gB_RecordMissed[client][TimeType_Pro];
	
	if (nubRecordExists && !nubRecordMissed && currentTime >= nubRecordTime)
	{
		gB_RecordMissed[client][TimeType_Nub] = true;
		
		// Check if nub record is also the pro record, and call the forward appropriately
		if (proRecordExists && FloatAbs(nubRecordTime - proRecordTime) < EPSILON)
		{
			gB_RecordMissed[client][TimeType_Pro] = true;
			Call_OnRecordMissed(client, nubRecordTime, course, mode, Style_Normal, RecordType_NubAndPro);
		}
		else
		{
			Call_OnRecordMissed(client, nubRecordTime, course, mode, Style_Normal, RecordType_Nub);
		}
	}
	else if (proRecordExists && !proRecordMissed && currentTime >= proRecordTime)
	{
		gB_RecordMissed[client][TimeType_Pro] = true;
		Call_OnRecordMissed(client, proRecordTime, course, mode, Style_Normal, RecordType_Pro);
	}
}



// =====[ MISSED PB TRACKING ]=====

#define MISSED_PB_SOUND "buttons/button18.wav"

void ResetPBMissed(int client)
{
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		gB_PBMissed[client][timeType] = false;
	}
}

void UpdatePBMissed(int client)
{
	if (!GOKZ_GetTimerRunning(client) || gB_PBMissed[client][TimeType_Nub] && gB_PBMissed[client][TimeType_Pro])
	{
		return;
	}
	
	int course = GOKZ_GetCourse(client);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);
	float currentTime = GOKZ_GetTime(client);
	
	bool nubPBExists = gB_PBExistsCache_Nub[client][course][mode][style];
	float nubPBTime = gF_PBTimesCache_Nub[client][course][mode][style];
	bool nubPBMissed = gB_PBMissed[client][TimeType_Nub];
	bool proPBExists = gB_PBExistsCache_Pro[client][course][mode][style];
	float proPBTime = gF_PBTimesCache_Pro[client][course][mode][style];
	bool proPBMissed = gB_PBMissed[client][TimeType_Pro];
	
	if (nubPBExists && !nubPBMissed && currentTime >= nubPBTime)
	{
		gB_PBMissed[client][TimeType_Nub] = true;
		
		// Check if nub PB is also the pro PB, and call the forward appropriately
		if (proPBExists && FloatAbs(nubPBTime - proPBTime) < EPSILON)
		{
			gB_PBMissed[client][TimeType_Pro] = true;
			Call_OnPBMissed(client, nubPBTime, course, mode, style, RecordType_NubAndPro);
		}
		else
		{
			Call_OnPBMissed(client, nubPBTime, course, mode, style, RecordType_Nub);
		}
	}
	else if (proPBExists && !proPBMissed && currentTime >= proPBTime)
	{
		gB_PBMissed[client][TimeType_Pro] = true;
		Call_OnPBMissed(client, proPBTime, course, mode, style, RecordType_Pro);
	}
}

void DoPBMissedReport(int client, float pbTime, int recordType)
{
	switch (recordType)
	{
		case RecordType_Nub:GOKZ_PrintToChat(client, true, "%t", "Missed PB (NUB)", GOKZ_FormatTime(pbTime));
		case RecordType_Pro:GOKZ_PrintToChat(client, true, "%t", "Missed PB (PRO)", GOKZ_FormatTime(pbTime));
		case RecordType_NubAndPro:GOKZ_PrintToChat(client, true, "%t", "Missed PB (NUB and PRO)", GOKZ_FormatTime(pbTime));
	}
	EmitSoundToClient(client, MISSED_PB_SOUND);
} 