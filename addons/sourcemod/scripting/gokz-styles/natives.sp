
// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_ST_ReplicateStyleConVars", Native_ReplicateStyleConVars);
	CreateNative("GOKZ_ST_TweakStyleConVars", Native_TweakStyleConVars);
}

public int Native_ReplicateStyleConVars(Handle plugin, int numParams)
{
	ReplicateConVars(GetNativeCell(1));
}

public int Native_TweakStyleConVars(Handle plugin, int numParams)
{
	TweakConVars(GetNativeCell(1));
}
