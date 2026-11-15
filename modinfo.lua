name = "Scheduled Announcer"
description = "Announces boss spawns, full moons, rifts, and kill counts"
author = ""
version = "1.0.0"
forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false

all_clients_require_mod = false
client_only_mod = false

configuration_options =
{
    {
        name = "sa_announce_boss_respawn",
        label = "Announce boss respawn",
        hover = "Will spawn on day X",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_announce_boss_spawn",
        label = "Announce boss spawn",
        hover = "Has spawned",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_announce_full_moon",
        label = "Announce full moon / lunar storm",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_announce_rift",
        label = "Announce rifts",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_announce_kill",
        label = "Announce boss kills",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_kill_limit",
        label = "Kill announce limit",
        hover = "0 = unlimited",
        options = {
            { description = "0 (unlimited)", data = 0 },
            { description = "5", data = 5 },
            { description = "10", data = 10 },
            { description = "25", data = 25 },
            { description = "50", data = 50 },
            { description = "100", data = 100 },
        },
        default = 0,
    },
    {
        name = "sa_announce_seasonal",
        label = "Announce seasonal boss spawn",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_announce_hound",
        label = "Announce hound attack",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "sa_near_player_radius",
        label = "Near player radius",
        hover = "Units",
        options = {
            { description = "10", data = 10 },
            { description = "25", data = 25 },
            { description = "50", data = 50 },
            { description = "100", data = 100 },
            { description = "200", data = 200 },
            { description = "500", data = 500 },
        },
        default = 50,
    },
    {
        name = "sa_when_rain_end",
        label = "Announce when rain ends",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
	{
        name = "sa_announce_nightmare",
        label = "Announce cave nightmare cycle",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
}