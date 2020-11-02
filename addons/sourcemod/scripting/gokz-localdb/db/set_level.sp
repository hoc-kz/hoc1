/*
	Sets player level experience and prestige.
*/

void DB_SetLevel(int client, int experience, int prestige)
{
	if (IsFakeClient(client) || !IsClientAuthorized(client))
	{
		return;
	}

	Transaction txn = SQL_CreateTransaction();

	char query[256];

	FormatEx(query, sizeof(query), sql_levels_upsert, GetSteamAccountID(client), experience, prestige);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_Normal);
}
