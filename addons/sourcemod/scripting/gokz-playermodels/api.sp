

// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_PM_GetPlayerModelDisplayName", Native_GetPlayerModelDisplayName);
	CreateNative("GOKZ_PM_DisplayPlayerModelMenu", Native_DisplayPlayerModelMenu);
}

public int Native_GetPlayerModelDisplayName(Handle plugin, int numParams)
{
	char displayName[64];
	GetPlayerModelDisplayName(GetNativeCell(1), displayName, sizeof(displayName));
	SetNativeString(2, displayName, GetNativeCell(3));
}

public int Native_DisplayPlayerModelMenu(Handle plugin, int numParams)
{
	DisplayPlayerModelMenu(GetNativeCell(1), GetNativeCell(2));
}
