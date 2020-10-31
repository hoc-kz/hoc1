
// =====[ FORWARDS ]=====

static GlobalForward H_OnLevelChanged;

void CreateGlobalForwards()
{
	H_OnLevelChanged = new GlobalForward("GOKZ_LV_OnLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnLevelChanged(int client, int level, int prestige)
{
	Call_StartForward(H_OnLevelChanged);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_PushCell(prestige);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_LV_GetExperience", Native_GetExperience);
	CreateNative("GOKZ_LV_GetLevel", Native_GetLevel);
	CreateNative("GOKZ_LV_GetPrestige", Native_GetPrestige);
}

public int Native_GetExperience(Handle plugin, int numParams)
{
	return gI_Experience[GetNativeCell(1)];
}

public int Native_GetLevel(Handle plugin, int numParams)
{
	return GOKZ_LV_LevelForExperience(gI_Experience[GetNativeCell(1)]);
}

public int Native_GetPrestige(Handle plugin, int numParams)
{
	return gI_Prestige[GetNativeCell(1)];
}
