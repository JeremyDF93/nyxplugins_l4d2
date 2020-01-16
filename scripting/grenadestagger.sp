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
  name = "Grenade Stagger",
  author = NYXTOOLS_AUTHOR,
  description = "Stagger like you're drunk",
  version = "1.0.2",
  url = NYXTOOLS_WEBSITE
};

ConVar nyx_grenade_launcher_damage;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
  EngineVersion engine = GetEngineVersion();
  if (engine != Engine_Left4Dead2) {
    strcopy(error, err_max, "Incompatible with this game");
    return APLRes_SilentFailure;
  }

  return APLRes_Success;
}

public void OnPluginStart() {
  nyx_grenade_launcher_damage = CreateConVar("nyx_grenade_launcher_damage", "400.0",
      "Amount of damage the grenade launcher does.");
}

public void OnEntityCreated(int entity, const char[] classname) {
  if (strcmp(classname, "grenade_launcher_projectile", false) == 0) {
    SDKHook(entity, SDKHook_StartTouch, OnProjectileStartTouch);
  }
}

public Action OnProjectileStartTouch(int entity, int other) {
  if (IsValidClient(other)) {
    float origin[3]; GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
    RunScriptCode("GetPlayerFromUserID(%d).Stagger(Vector(%.3f, %.3f, %.3f))", GetClientUserId(other),
        origin[0], origin[1], origin[2]);
  }

  float flDamage = nyx_grenade_launcher_damage.FloatValue;
  SetEntPropFloat(entity, Prop_Data, "m_flDamage", flDamage);

  return Plugin_Continue;
}
