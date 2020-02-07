#pragma semicolon 1
#include <sourcemod>
#include <left4downtown>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <nyxtools>
#include <nyxtools_l4d2>

#pragma newdecls required

public Plugin myinfo = {
  name = "Replace Tank",
  author = NYXTOOLS_AUTHOR,
  description = "Give players the option to pass the tank",
  version = "1.0.0",
  url = NYXTOOLS_WEBSITE
};

/***
 *       ______          _    __
 *      / ____/___  ____| |  / /___ ___________
 *     / /   / __ \/ __ \ | / / __ `/ ___/ ___/
 *    / /___/ /_/ / / / / |/ / /_/ / /  (__  )
 *    \____/\____/_/ /_/|___/\__,_/_/  /____/
 *
 */

ConVar nyx_replacetank_onspawn;

/***
 *        ____  __            _          ____      __            ____
 *       / __ \/ /_  ______ _(_)___     /  _/___  / /____  _____/ __/___ _________
 *      / /_/ / / / / / __ `/ / __ \    / // __ \/ __/ _ \/ ___/ /_/ __ `/ ___/ _ \
 *     / ____/ / /_/ / /_/ / / / / /  _/ // / / / /_/  __/ /  / __/ /_/ / /__/  __/
 *    /_/   /_/\__,_/\__, /_/_/ /_/  /___/_/ /_/\__/\___/_/  /_/  \__,_/\___/\___/
 *                  /____/
 */

public void OnPluginStart() {
  LoadTranslations("common.phrases");

  nyx_replacetank_onspawn = CreateConVar("nyx_replacetank_onspawn", "1", "Display the menu when a tank is spawned?", _, true, 0.0, true, 1.0);

  RegConsoleCmd("sm_giveup", ConCmd_PassTank);
  RegConsoleCmd("sm_passtank", ConCmd_PassTank);

  HookEvent("player_spawn", Event_PlayerSpawn);
}

/***
 *        ______                 __
 *       / ____/   _____  ____  / /______
 *      / __/ | | / / _ \/ __ \/ __/ ___/
 *     / /___ | |/ /  __/ / / / /_(__  )
 *    /_____/ |___/\___/_/ /_/\__/____/
 *
 */

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(event.GetInt("userid"));
  if (!IsPlayerTank(client)) return Plugin_Continue;

  if (nyx_replacetank_onspawn.BoolValue) {
    Display_ConfirmMenu(client);
  }

  return Plugin_Continue;
}

/***
 *       ______                                          __
 *      / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
 *     / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
 *    / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  )
 *    \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/
 *
 */

public Action ConCmd_PassTank(int client, int args) {
  if (!IsPlayerTank(client)) {
    NyxMsgReply(client, "You must be a Tank to use this command");
    return Plugin_Handled;
  }

  int target;
  if (args < 1) {
    char cmd[32];
    GetCmdArg(0, cmd, sizeof(cmd));

    if (StrEqual(cmd, "sm_passtank", false)) {
      Display_GiveTankMenu(client);

      return Plugin_Handled;
    } else {
      int playerCount, playerList[MAXPLAYERS + 1];
      for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidClient(i, true)) continue;
        if (IsPlayerSurvivor(i)) continue;
        if (IsPlayerAlive(i) && !IsPlayerGhost(i)) continue;
        if (client == i) continue;

        playerList[playerCount++] = i;
      }

      target = playerList[GetRandomInt(0, playerCount - 1)];
    }
  } else {
    target = GetCmdTarget(1, client);
  }

  if (GetEntProp(client, Prop_Send, "m_nSequence") >= 65) { // start of tank death animation 67-77
    return Plugin_Handled;
  }

  if (IsValidClient(target)) {
    if (IsPlayerAlive(target) && !IsPlayerGhost(target))
      return Plugin_Handled;

    L4D_ReplaceTank(client, target);
    NyxMsgAll("%N passed the Tank to %N", client, target);
  }

  return Plugin_Handled;
}

/***
 *        __  ___
 *       /  |/  /__  ____  __  _______
 *      / /|_/ / _ \/ __ \/ / / / ___/
 *     / /  / /  __/ / / / /_/ (__  )
 *    /_/  /_/\___/_/ /_/\__,_/____/
 *
 */

 void Display_GiveTankMenu(int client) {
  Menu menu = new Menu(Menu_GiveTank);
  menu.SetTitle("To Who?");
  menu.ExitBackButton = true;
  AddTeamToMenu(menu, client);
  menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_GiveTank(Menu menu, MenuAction action, int param1, int param2) {
  if (action == MenuAction_End) {
    delete menu;
  } else if (action == MenuAction_Cancel) {
    return;
  } else if (action == MenuAction_Select) {
    char info[32];
    menu.GetItem(param2, info, sizeof(info));
    int target = GetClientOfUserId(StringToInt(info));

    if (!IsValidClient(target)) {
      NyxMsgClient(param1, "%t", "Player no longer available");
    } else {
      if (GetEntProp(param1, Prop_Send, "m_nSequence") >= 65) { // start of tank death animation 67-77
        return;
      }

      L4D_ReplaceTank(param1, target);
      NyxMsgAll("%N passed the Tank to %N", param1, target);
    }
  }

  return;
}

void Display_ConfirmMenu(int client) {
  Menu menu = new Menu(Menu_ConfirmMenu);
  menu.SetTitle("Pass the Tank?");
  menu.AddItem("yes", "Yes");
  menu.AddItem("no", "No");
  menu.ExitBackButton = false;
  menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ConfirmMenu(Menu menu, MenuAction action, int param1, int param2) {
  if (action == MenuAction_End) {
    delete menu;
  } else if (action == MenuAction_Cancel) {
    return;
  } else if (action == MenuAction_Select) {
    char info[32];
    menu.GetItem(param2, info, sizeof(info));

    if (!IsValidClient(param1)) return;
    if (StrEqual(info, "no", false)) return;

    Display_GiveTankMenu(param1);
  }

  return;
}

/***
 *       _____ __             __
 *      / ___// /_____  _____/ /_______
 *      \__ \/ __/ __ \/ ___/ //_/ ___/
 *     ___/ / /_/ /_/ / /__/ ,< (__  )
 *    /____/\__/\____/\___/_/|_/____/
 *
 */

stock int AddTeamToMenu(Menu menu, int client, bool filterBots=true) {
  char user_id[12];
  char name[MAX_NAME_LENGTH];
  char display[MAX_NAME_LENGTH + 12];

  int num_clients;

  for (int i = 1; i <= MaxClients; i++) {
    if (!IsValidClient(i, filterBots)) continue;
    if (GetClientTeam(i) != GetClientTeam(client)) continue;
    if (IsPlayerAlive(i) && !IsPlayerGhost(i)) continue;
    if (i == client) continue;

    IntToString(GetClientUserId(i), user_id, sizeof(user_id));
    GetClientName(i, name, sizeof(name));
    Format(display, sizeof(display), "%s", name);
    menu.AddItem(user_id, display);

    num_clients++;
  }
}
