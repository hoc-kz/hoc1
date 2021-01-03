/*
	Opens a menu with player profile.
*/

static float lastProfileQueryTime[MAXPLAYERS + 1];
static bool cameFromProfileMenu[MAXPLAYERS + 1];

static int steamID[MAXPLAYERS + 1];
static char alias[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static char country[MAXPLAYERS + 1][64];
static char lastPlayedDate[MAXPLAYERS + 1][32];
static char createdDate[MAXPLAYERS + 1][32];
static int rank[MAXPLAYERS + 1];
static int maxrank[MAXPLAYERS + 1];
static int level[MAXPLAYERS + 1];
static int prestige[MAXPLAYERS + 1];
static int mapsTotal[MAXPLAYERS + 1];
static int mapsCompletedNub[MAXPLAYERS + 1];
static int mapsCompletedPro[MAXPLAYERS + 1];



bool GetCameFromProfileMenu(int client)
{
	return cameFromProfileMenu[client];
}

void DB_DisplayProfile(int client, int targetSteamID)
{
	char query[1024];

	Transaction txn = SQL_CreateTransaction();

	// Select generic profile information
	FormatEx(query, sizeof(query), sql_players_profile, targetSteamID);
	txn.AddQuery(query);
	// Select level, rank information
	FormatEx(query, sizeof(query), sql_levels_rank_get, targetSteamID);
	txn.AddQuery(query);
	txn.AddQuery(sql_levels_maxrank_get);
	FormatEx(query, sizeof(query), sql_levels_get, targetSteamID);
	txn.AddQuery(query);
	// Select main course count
	txn.AddQuery(sql_getcount_maincourses);
	// Select NUB completed main courses 
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedoverall, targetSteamID);
	txn.AddQuery(query);
	// Select PRO completed main courses
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedprooverall, targetSteamID);
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(targetSteamID);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_DisplayProfile, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_DisplayProfile(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int targetSteamID = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	steamID[client] = targetSteamID;

	if (!SQL_FetchRow(results[0]) || !SQL_FetchRow(results[4]) || !SQL_FetchRow(results[5]) || !SQL_FetchRow(results[6]))
	{
		return;
	}

	SQL_FetchString(results[0], 0, alias[client], sizeof(alias[]));
	SQL_FetchString(results[0], 1, country[client], sizeof(country[]));
	SQL_FetchString(results[0], 2, lastPlayedDate[client], sizeof(lastPlayedDate[]));
	SQL_FetchString(results[0], 3, createdDate[client], sizeof(createdDate[]));

	if (gB_GOKZLevels)
	{
		if (!SQL_FetchRow(results[1]) || !SQL_FetchRow(results[2]) || !SQL_FetchRow(results[3]))
		{
			return;
		}

		rank[client] = SQL_FetchInt(results[1], 0);
		maxrank[client] = IntMax(rank[client], SQL_FetchInt(results[2], 0));
		level[client] = GOKZ_LV_LevelForExperience(SQL_FetchInt(results[3], 0));
		prestige[client] = SQL_FetchInt(results[3], 1);
	}

	mapsTotal[client] = SQL_FetchInt(results[4], 0);
	mapsCompletedNub[client] = SQL_FetchInt(results[5], 0);
	mapsCompletedPro[client] = SQL_FetchInt(results[6], 0);

	ReopenProfile(client);
}

void DB_DisplayProfile_FindPlayer(int client, const char[] target)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);

	DB_FindPlayer(target, DB_TxnSuccess_DisplayProfile_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_DisplayProfile_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[MAX_NAME_LENGTH];
	data.ReadString(playerSearch, sizeof(playerSearch));
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}

	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{
		DB_DisplayProfile(client, SQL_FetchInt(results[0], 0));
	}
}

void ReopenProfile(int client)
{
	cameFromProfileMenu[client] = false;

	char buffer[64];
	Panel menu = new Panel();

	FormatEx(buffer, sizeof(buffer), "%T - %s", "Profile - Player", client, alias[client]);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%T - %s", "Profile - From", client, country[client]);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	if (gB_GOKZLevels)
	{
		FormatEx(buffer, sizeof(buffer), "%T - %d/%d", "Profile - Rank", client, rank[client], maxrank[client]);
		menu.DrawText(buffer);
		FormatEx(buffer, sizeof(buffer), "%T - %d", "Profile - Level", client, level[client]);
		menu.DrawText(buffer);
		FormatEx(buffer, sizeof(buffer), "%T - %d", "Profile - Prestige", client, prestige[client]);
		menu.DrawText(buffer);
		menu.DrawText(" ");
	}

	FormatEx(buffer, sizeof(buffer), "%T - %s", "Profile - First Seen", client, createdDate[client]);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%T - %s", "Profile - Last Seen", client, lastPlayedDate[client]);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	float mapsCompletedNubPercent = 100.0 * (mapsCompletedNub[client] / float(mapsTotal[client]));
	float mapsCompletedProPercent = 100.0 * (mapsCompletedPro[client] / float(mapsTotal[client]));
	FormatEx(buffer, sizeof(buffer), "%T - %d/%d (%0.1f%%)", "Profile - NUB Completion", client, mapsCompletedNub[client], mapsTotal[client], mapsCompletedNubPercent);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%T - %d/%d (%0.1f%%)", "Profile - PRO Completion", client, mapsCompletedPro[client], mapsTotal[client], mapsCompletedProPercent);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	FormatEx(buffer, sizeof(buffer), "%s %T", gC_TimeTypeNames[TimeType_Nub], "Profile - Completed Maps", client);
	menu.DrawItem(buffer);
	FormatEx(buffer, sizeof(buffer), "%s %T", gC_TimeTypeNames[TimeType_Pro], "Profile - Completed Maps", client);
	menu.DrawItem(buffer);
	FormatEx(buffer, sizeof(buffer), "%s %T", gC_TimeTypeNames[TimeType_Nub], "Profile - Uncompleted Maps", client);
	menu.DrawItem(buffer);
	FormatEx(buffer, sizeof(buffer), "%s %T", gC_TimeTypeNames[TimeType_Pro], "Profile - Uncompleted Maps", client);
	menu.DrawItem(buffer);

	menu.CurrentKey = 9;
	menu.DrawText(" ");

	FormatEx(buffer, sizeof(buffer), "%T", "Exit", client);
	menu.DrawItem(buffer);

	menu.Send(client, MenuHandler_Profile, MENU_TIME_FOREVER);
}

public int MenuHandler_Profile(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		cameFromProfileMenu[param1] = true;

		// Play menu sounds since we're actually using a panel.
		if (param2 == 9)
		{
			EmitSoundToClient(param1, "buttons/combine_button7.wav");
		}
		else
		{
			EmitSoundToClient(param1, "buttons/button14.wav");

			if (!IsSpammingProfileQueries(param1))
			{
				switch (param2)
				{
					case 1: DB_PrintOverallCompletedMaps(param1, steamID[param1], TimeType_Nub);
					case 2: DB_PrintOverallCompletedMaps(param1, steamID[param1], TimeType_Pro);
					case 3: DB_PrintOverallUncompletedMaps(param1, steamID[param1], TimeType_Nub);
					case 4: DB_PrintOverallUncompletedMaps(param1, steamID[param1], TimeType_Pro);
				}
			}
			else
			{
				ReopenProfile(param1);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

static bool IsSpammingProfileQueries(int client, bool printMessage = true)
{
	float currentTime = GetEngineTime();
	float timeSinceLastCommand = currentTime - lastProfileQueryTime[client];
	if (timeSinceLastCommand < LR_PROFILE_QUERY_COOLDOWN)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command", LR_PROFILE_QUERY_COOLDOWN - timeSinceLastCommand + 0.1);
		}
		return true;
	}

	// Not spamming commands - all good!
	lastProfileQueryTime[client] = currentTime;
	return false;
}