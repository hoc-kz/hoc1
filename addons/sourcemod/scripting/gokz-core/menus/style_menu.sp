/*
	Lets players choose their style.
*/



// =====[ PUBLIC ]=====

void DisplayStyleMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Style);
	menu.SetTitle("%T", "Style Menu - Title", client);
	GOKZ_MenuAddStyleItems(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

public int MenuHandler_Style(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		GOKZ_SetCoreOption(param1, Option_Style, param2);
		if (GetCameFromOptionsMenu(param1))
		{
			DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		DisplayOptionsMenu(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
} 