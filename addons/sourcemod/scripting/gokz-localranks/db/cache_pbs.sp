/*
	Caches the player's personal best times on the map.
*/



void DB_CachePBs(int client, int steamID)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Reset PB exists array
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			for (int style = 0; style < STYLE_COUNT; style++)
			{
				gB_PBExistsCache_Nub[client][course][mode][style] = false;
				gB_PBExistsCache_Pro[client][course][mode][style] = false;
			}
		}
	}
	
	int mapID = GOKZ_DB_GetCurrentMapID();
	
	// Get Map PBs
	FormatEx(query, sizeof(query), sql_getpbs, steamID, mapID);
	txn.AddQuery(query);
	// Get PRO PBs
	FormatEx(query, sizeof(query), sql_getpbspro, steamID, mapID);
	txn.AddQuery(query);
	
	PrintToServer("Caching PBs for %N", client);
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_CachePBs, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_High);
}

public void DB_TxnSuccess_CachePBs(Handle db, int userID, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userID);
	if (!IsClientAuthorized(client))
	{
		return;
	}
	
	int course, mode, style;
	
	while (SQL_FetchRow(results[0]))
	{
		course = SQL_FetchInt(results[0], 1);
		mode = SQL_FetchInt(results[0], 2);
		style = SQL_FetchInt(results[0], 3);
		gB_PBExistsCache_Nub[client][course][mode][style] = true;
		gF_PBTimesCache_Nub[client][course][mode][style] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[0], 0));
	}
	
	while (SQL_FetchRow(results[1]))
	{
		course = SQL_FetchInt(results[1], 1);
		mode = SQL_FetchInt(results[1], 2);
		style = SQL_FetchInt(results[1], 3);
		gB_PBExistsCache_Pro[client][course][mode][style] = true;
		gF_PBTimesCache_Pro[client][course][mode][style] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[1], 0));

		PrintToServer("%N PRO PB (course: %d, mode: %d, style: %d) - %f", client, course, mode, style, gF_PBTimesCache_Pro[client][course][mode][style]);
	}
} 