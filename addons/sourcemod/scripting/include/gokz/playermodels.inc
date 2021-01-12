#if defined _gokz_playermodels_included_
#endinput
#endif
#define _gokz_playermodels_included_



// =====[ NATIVES ]=====

native void GOKZ_PM_GetPlayerModelDisplayName(int client, char[] buffer, int maxlength);

native void GOKZ_PM_DisplayPlayerModelMenu(int client, bool cameFromOptionsMenu);
