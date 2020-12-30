/*
	Prints completed/uncompleted maps.
*/

void DB_PrintOverallCompletedMaps(int client, int targetSteamID, int timeType)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	if (timeType == TimeType_Nub)
	{
		FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall, targetSteamID);
	}
	else
	{
		FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall_pro, targetSteamID);
	}
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(timeType);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintCompletedMaps, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

void DB_PrintOverallUncompletedMaps(int client, int targetSteamID, int timeType)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	if (timeType == TimeType_Nub)
	{
		FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall, targetSteamID);
	}
	else
	{
		FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall_pro, targetSteamID);
	}
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(timeType);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintUncompletedMaps, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_PrintCompletedMaps(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int timeType = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	if (!SQL_FetchRow(results[0]))
	{
		return;
	}

	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%T", "Player No Maps Completed", client, alias);
		GoBackWhereCameFrom(client);
		return;
	}

	Menu menu = new Menu(MenuHandler_CompletedUncompletedMaps);
	menu.SetTitle("%T", "Completed Maps Menu - Title", client, gC_TimeTypeNames[timeType], alias);

	char buffer[128];
	while (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, buffer, sizeof(buffer));
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public void DB_TxnSuccess_PrintUncompletedMaps(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int timeType = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	if (!SQL_FetchRow(results[0]))
	{
		return;
	}

	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%T", "Player All Maps Completed", client, alias);
		GoBackWhereCameFrom(client);
		return;
	}

	Menu menu = new Menu(MenuHandler_CompletedUncompletedMaps);
	menu.SetTitle("%T", "Uncompleted Maps Menu - Title", client, gC_TimeTypeNames[timeType], alias);

	char buffer[128];
	while (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, buffer, sizeof(buffer));
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_CompletedUncompletedMaps(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		GoBackWhereCameFrom(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

static void GoBackWhereCameFrom(int client)
{
	if (GetCameFromProfileMenu(client))
	{
		ReopenProfile(client);
	}	
}
