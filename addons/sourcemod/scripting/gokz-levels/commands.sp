
void RegisterCommands()
{
	RegConsoleCmd("sm_prestige", CommandPrestige, "[KZ] Trade levels for a prestige.");
}

public Action CommandPrestige(int client, int args)
{
	if (GOKZ_LV_GetLevel(client) == GOKZ_LV_MAX_LEVEL)
	{
		gI_Prestige[client]++;
		gI_Experience[client] = 0;

		GOKZ_PrintToChat(client, true, "%t", "Prestige");

		Call_OnLevelChanged(client, 0, gI_Prestige[client]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Prestige Failed (Not Max Level)");
	}
	return Plugin_Handled;
}
