/*
	gokz-styles Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_styles_included_
#endinput
#endif
#define _gokz_styles_included_


// =====[ NATIVES ]=====

/**
 * Replicates style convars. Call at the end of ReplicateConVars in mode plugins.
 *
 * @param client		Client index.
 */
native void GOKZ_ST_ReplicateStyleConVars(int client);

/**
 * Tweak style convars. Call at the end of TweakConVars in mode plugins.
 *
 * @param client		Client index.
 */
native void GOKZ_ST_TweakStyleConVars(int client);


// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_styles = 
{
	name = "gokz-styles", 
	file = "gokz-styles.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_styles_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_ST_ReplicateStyleConVars");
	MarkNativeAsOptional("GOKZ_ST_TweakStyleConVars");
}
#endif
