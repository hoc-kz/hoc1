

void IntegrityChecks_ConvarChecks()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && !IsFakeClient(client))
		{
			QueryClientConVar(client, "fps_max", FPSCheck);
			QueryClientConVar(client, "m_yaw", MYAWCheck);
		}
	}
}

void OnClientPutInServer_ConvarChecks(int client)
{
	gB_waitingForFPSKick[client] = false;
}

public void FPSCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		gI_FPSMax[client] = StringToInt(cvarValue);
		if (gI_FPSMax[client] > 0 && gI_FPSMax[client] < AC_FPS_MAX_MIN_VALUE)
		{
			if (!gB_waitingForFPSKick[client])
			{
				gB_waitingForFPSKick[client] = true;
				CreateTimer(AC_FPS_MAX_KICK_TIMEOUT, FPSKickPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				GOKZ_PrintToChat(client, true, "%t", "Warn Player fps_max");
				if (GOKZ_GetTimerRunning(client))
				{
					GOKZ_StopTimer(client, true);
				}
				else
				{
					EmitSoundToClient(client, GOKZ_SOUND_TIMER_STOP);
				}
			}
		}
		else
		{
			gB_waitingForFPSKick[client] = false;
		}
	}
}

public void MYAWCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (IsValidClient(client) && !IsFakeClient(client) && StringToFloat(cvarValue) > AC_MYAW_MAX_VALUE)
	{
		KickClient(client, "%T", "Kick Player m_yaw", client);
	}
}

Action FPSKickPlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && !IsFakeClient(client) && gB_waitingForFPSKick[client])
	{
		KickClient(client, "%T", "Kick Player fps_max", client);
	}
	
	return Plugin_Handled;
}
