/*
	Opens a menu with player profile.
*/



static int steamID[MAXPLAYERS + 1];
static char profileAlias[MAXPLAYERS + 1][MAX_NAME_LENGTH];
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

	SQL_FetchString(results[0], 0, profileAlias[client], sizeof(profileAlias[]));
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
	char buffer[64];
	Panel menu = new Panel();

	FormatEx(buffer, sizeof(buffer), "%T - %s", "Profile - Player", client, profileAlias[client]);
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
		// Play menu sounds since we're actually using a panel.
		if (param2 == 9)
		{
			EmitSoundToClient(param1, "buttons/combine_button7.wav");
		}
		else
		{
			EmitSoundToClient(param1, "buttons/button14.wav");

			switch (param2)
			{
				case 1: DB_OpenProfileMapCompletion(param1, steamID[param1], TimeType_Nub, true);
				case 2: DB_OpenProfileMapCompletion(param1, steamID[param1], TimeType_Pro, true);
				case 3: DB_OpenProfileMapCompletion(param1, steamID[param1], TimeType_Nub, false);
				case 4: DB_OpenProfileMapCompletion(param1, steamID[param1], TimeType_Pro, false);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ OVERALL MAP COMPLETION ]=====

void DB_OpenProfileMapCompletion(int client, int targetSteamID, int timeType, bool completed)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	// Get target name
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	if (completed)
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall, targetSteamID);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall_pro, targetSteamID);
		}
	}
	else
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall, targetSteamID);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall_pro, targetSteamID);
		}	
	}	
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(timeType);
	datapack.WriteCell(completed);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenProfileMapCompletion, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_OpenProfileMapCompletion(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int timeType = datapack.ReadCell();
	bool completed = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	// Get target name
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (timeType == TimeType_Nub)
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - None Completed", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - All Completed", client, alias);
			}
		}
		else
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - None Completed (PRO)", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - All Completed (PRO)", client, alias);
			}
		}
		ReopenProfile(client);
		return;
	}

	Menu menu = new Menu(MenuHandler_ProfileMapCompletionSubmenu);
	if (completed)
	{
		menu.SetTitle("%T", "Profile Map Completion Submenu - Title (Completed)", client, gC_TimeTypeNames[timeType], alias);
	}
	else
	{
		menu.SetTitle("%T", "Profile Map Completion Submenu - Title (Uncompleted)", client, gC_TimeTypeNames[timeType], alias);
	}

	char buffer[128];
	while (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, buffer, sizeof(buffer));
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_ProfileMapCompletionSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		ReopenProfile(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
