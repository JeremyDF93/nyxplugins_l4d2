#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <nyxtools>
#include <nyxtools_l4d2>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
  name = "Melee Stagger",
  author = NYXTOOLS_AUTHOR,
  description = "Stagger like you're drunk",
  version = "1.0.1",
  url = NYXTOOLS_WEBSITE
};

ConVar nyx_melee_stagger_tank;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
  EngineVersion engine = GetEngineVersion();
  if (engine != Engine_Left4Dead2) {
    strcopy(error, err_max, "Incompatible with this game");
    return APLRes_SilentFailure;
  }

  return APLRes_Success;
}

public void OnPluginStart() {
  nyx_melee_stagger_tank = CreateConVar("nyx_melee_stagger_tank", "0",
      "Allow melee weapons to stagger the tank?", _, true, 0.0, true, 1.0);

  HookEvent("player_hurt", Event_PlayerHurt);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
  int victim = GetClientOfUserId(event.GetInt("userid"));
  int attacker = GetClientOfUserId(event.GetInt("attacker"));
  if (!IsValidClient(victim)) return Plugin_Continue;
  if (!IsValidClient(attacker)) return Plugin_Continue;
  if (!IsPlayerInfected(victim)) return Plugin_Continue;
  if (!IsPlayerSurvivor(attacker)) return Plugin_Continue;

  if (IsPlayerTank(victim)) {
    bool staggerTank = nyx_melee_stagger_tank.BoolValue;
    if (!staggerTank) return Plugin_Continue;
  }

  int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
  if (!IsValidEntity(weapon)) {
    return Plugin_Continue;
  }

  char classname[255]; GetEntityClassname(weapon, classname, sizeof(classname));
  if (strcmp(classname, "weapon_melee", false) != 0) {
    return Plugin_Continue;
  }

  float pos[3]; GetClientAbsOrigin(attacker, pos);
  RunScriptCode("GetPlayerFromUserID(%d).Stagger(Vector(%.3f, %.3f, %.3f))", GetClientUserId(victim), pos[0], pos[1], pos[2]);

  return Plugin_Continue;
}
