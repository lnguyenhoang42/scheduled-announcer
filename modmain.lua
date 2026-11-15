local cfg = {
	sa_announce_boss_respawn = GetModConfigData("sa_announce_boss_respawn"),
	sa_announce_boss_spawn   = GetModConfigData("sa_announce_boss_spawn"),
	sa_announce_full_moon    = GetModConfigData("sa_announce_full_moon"),
	sa_announce_rift         = GetModConfigData("sa_announce_rift"),
	sa_announce_kill         = GetModConfigData("sa_announce_kill"),
	sa_kill_limit            = GetModConfigData("sa_kill_limit"),
	sa_announce_seasonal     = GetModConfigData("sa_announce_seasonal"),
	sa_announce_hound        = GetModConfigData("sa_announce_hound"),
	sa_near_player_radius    = GetModConfigData("sa_near_player_radius"),
	sa_when_rain_end         = GetModConfigData("sa_when_rain_end"),
	sa_announce_nightmare	 = GetModConfigData("sa_announce_nightmare"),   
}

local function announce(msg)
    if GLOBAL.TheNet then
        GLOBAL.TheNet:Announce(msg, nil, nil, nil)
    end
end

local function get_day()
    if GLOBAL.TheWorld and GLOBAL.TheWorld.state then
        return GLOBAL.TheWorld.state.cycles + 1
    end
    return 0
end

-- Returns the day number when `seconds` from now will land
local function get_day_in_seconds(seconds)
    local DAY = GLOBAL.TUNING.TOTAL_DAY_TIME
    local current_time = GLOBAL.TheWorld.state.time
    local total = current_time * DAY + seconds
    local days_ahead = math.floor(total / DAY)
    return get_day() + days_ahead
end

local function is_near_player(inst, radius)
    if not GLOBAL.TheSim then return false end
    local r = radius or cfg.sa_near_player_radius or 50
    local player = GLOBAL.GetClosestInstWithTag("player", inst, r)
    return player ~= nil
end

local function get_season_length(season)
    local T = GLOBAL.TUNING
    if not T then return nil end
    if season == "autumn" then return T.AUTUMN_LENGTH or 20 end
    if season == "winter" then return T.WINTER_LENGTH or 15 end
    if season == "summer" then return T.SUMMER_LENGTH or 15 end
    if season == "spring" then return T.SPRING_LENGTH or 20 end
    return nil
end

-- ============================================================
-- TIME FORMATTING (in-game units)
-- ============================================================
local function formatTime(totalSeconds)
    local hours = math.floor(totalSeconds / 3600)
    local mins  = math.floor((totalSeconds % 3600) / 60)
    local secs  = math.floor(totalSeconds % 60)
    local parts = {}
    if hours > 0 then table.insert(parts, hours .. "h") end
    if mins > 0 then table.insert(parts, mins .. "m") end
    if secs > 0 or #parts == 0 then table.insert(parts, secs .. "s") end
    return table.concat(parts, " ")
end

local curSysNumber = 1
local function logSystemLoaded(sysName)
    print(string.format("[%d] [SA] %s has been loaded!", curSysNumber, sysName))
    curSysNumber = curSysNumber + 1
end

-- ============================================================
-- SEASONAL BOSS FORMULAS
-- ============================================================
local function bearger_spawn_range()
    local len = get_season_length("autumn") or 20
    local base = 0.25 * len
    local variance = 0.0625 * len
    return math.floor(base - variance), math.ceil(base + variance)
end

local function deerclops_first_spawn_day(season_start_day)
    local len = get_season_length("winter") or 15
    local delay = (len - 1) / 5
    return season_start_day + 2 + delay
end

local function deerclops_respawn_days()
    local len = get_season_length("winter") or 15
    return 6 * (len - 1) / 5
end

-- ============================================================
-- BOSS DEFINITIONS
-- ============================================================
local BOSSES = {
    { prefab = "dragonfly",           name = "Dragonfly",           respawn = 20 },
    { prefab = "bearger",             name = "Bearger",             respawn = 0, seasonal = "autumn" },
    { prefab = "deerclops",           name = "Deerclops",           respawn = 0, seasonal = "winter" },
    { prefab = "antlion",             name = "Antlion",             respawn = 0, seasonal = "summer" },
    { prefab = "beequeen",            name = "Bee Queen",           respawn = 20 },
    { prefab = "malbatross",          name = "Malbatross",          respawn_min = 5, respawn_max = 15 },
    { prefab = "daywalker",           name = "Nightmare Werepig",   respawn = 10, respawns_as = "Scrappy Werepig" },
    { prefab = "daywalker2",          name = "Scrappy Werepig",     respawn = 10, respawns_as = "Nightmare Werepig" },
    { prefab = "minotaur",            name = "Ancient Guardian",    respawn = 0 },
    { prefab = "stalker_atrium",      name = "Ancient Fuelweaver",  respawn = 20 },
    { prefab = "alterguardian_phase1", name = "Celestial Champion", respawn = 0 },
    { prefab = "celestialrevenant",   name = "Celestial Revenant",  respawn = 0 },
    { prefab = "wagboss_robot",       name = "W.A.R.B.O.T.",        respawn = 0 },
    { prefab = "alterguardian_phase4_lunarrift", name = "Celestial Scion", respawn = 0 },
    { prefab = "charlie_boss",        name = "Shrouded Queen",      respawn = 0 },
    { prefab = "klaus",               name = "Klaus",               respawn = 0 },
    { prefab = "mutateddeerclops",    name = "Crystal Deerclops",   respawn = 0 },
    { prefab = "mutatedbearger",      name = "Armored Bearger",     respawn = 0 },
    { prefab = "mutatedwarg",         name = "Possessed Varg",      respawn = 0 },
    { prefab = "shadow_knight",       name = "Shadow Knight",       respawn = 0 },
    { prefab = "shadow_bishop",       name = "Shadow Bishop",       respawn = 0 },
    { prefab = "shadow_rook",         name = "Shadow Rook",         respawn = 0 },
    { prefab = "spiderqueen",         name = "Spider Queen",        respawn = 0, near_player_only = true },
    { prefab = "lordfruitfly",        name = "Lord of the Fruit Flies", respawn = 20 },
    { prefab = "rocky_boss",          name = "Rock Master",         respawn_min = 10, respawn_max = 20 },
    { prefab = "rocky_boss_shadow",   name = "Blighted Rock Master", respawn = 0 },
    { prefab = "leif",                name = "Treeguard",           respawn = 0, near_player_only = true },
    { prefab = "stalker_npc",         name = "Ancient Fuelweaver (NPC)", respawn = 0 },
    { prefab = "stalker",             name = "Reanimated Skeleton (Caves)", respawn = 0 },
    { prefab = "stalker_forest",      name = "Reanimated Skeleton (Forest)", respawn = 0 },
    { prefab = "toadstool",           name = "Toadstool",           respawn = 20 },
    { prefab = "toadstool_dark",      name = "Misery Toadstool",    respawn = 20 },
    { prefab = "warg",                name = "Varg",                respawn = 0 },
    { prefab = "worm_boss",           name = "Great Depths Worm",   respawn = 0 },
    { prefab = "bat_boss",            name = "Hound Batilisk",      respawn = 0 },
    { prefab = "crabking",            name = "Crab King",           respawn = 20 },
    { prefab = "shrouden",            name = "Umbral Abomination",  respawn = 0 },
}

local DIRECT_SPAWNS = {
    dragonfly           = "Dragonfly",
    bearger             = "Bearger",
    deerclops           = "Deerclops",
    antlion             = "Antlion",
    beequeen            = "Bee Queen",
    malbatross          = "Malbatross",
    daywalker           = "Nightmare Werepig",
    daywalker2          = "Scrappy Werepig",
    minotaur            = "Ancient Guardian",
    stalker_atrium      = "Ancient Fuelweaver",
    alterguardian_phase1 = "Celestial Champion",
    celestialrevenant   = "Celestial Revenant",
    wagboss_robot       = "W.A.R.B.O.T.",
    alterguardian_phase4_lunarrift = "Celestial Scion",
    charlie_boss        = "Shrouded Queen",
    klaus               = "Klaus",
    mutateddeerclops    = "Crystal Deerclops",
    mutatedbearger      = "Armored Bearger",
    mutatedwarg         = "Possessed Varg",
    shadow_knight       = "Shadow Knight",
    shadow_bishop       = "Shadow Bishop",
    shadow_rook         = "Shadow Rook",
    spiderqueen         = "Spider Queen",
    lordfruitfly        = "Lord of the Fruit Flies",
    rocky_boss          = "Rock Master",
    rocky_boss_shadow   = "Blighted Rock Master",
    leif                = "Treeguard",
    stalker_npc         = "Ancient Fuelweaver (NPC)",
    stalker             = "Reanimated Skeleton (Caves)",
    stalker_forest      = "Reanimated Skeleton (Forest)",
    toadstool           = "Toadstool",
    toadstool_dark      = "Misery Toadstool",
    warg                = "Varg",
    worm_boss           = "Great Depths Worm",
    bat_boss            = "Hound Batilisk",
    crabking            = "Crab King",
    shrouden            = "Umbral Abomination",
}

-- ============================================================
-- KILL COUNT PERSISTENCE
-- ============================================================
local save_key = "scheduled_announcer_kills"
local kill_counts = {}
for _, b in ipairs(BOSSES) do
    kill_counts[b.prefab] = 0
end

local kills_loaded = false

local function load_kills()
    if not GLOBAL.TheSim then return end
    GLOBAL.TheSim:GetPersistentString(save_key, function(load_success, data)
        if load_success and type(data) == "string" and data ~= "" then
            for line in data:gmatch("[^\n]+") do
                local prefab, count = line:match("^(%S+)=(%d+)$")
                if prefab and count then
                    kill_counts[prefab] = GLOBAL.tonumber(count)
                end
            end
        end
        kills_loaded = true
    end)
end

local function save_kills()
    if not GLOBAL.TheSim then return end
    local buf = {}
    for prefab, count in pairs(kill_counts) do
        if count > 0 then
            table.insert(buf, prefab .. "=" .. count)
        end
    end
    GLOBAL.TheSim:SetPersistentString(save_key, table.concat(buf, "\n"))
end

local function save_boss_killed(prefab)
    if not kills_loaded then return end
    kill_counts[prefab] = (kill_counts[prefab] or 0) + 1
    save_kills()
end

-- ============================================================
-- SHARED: announce defeat + respawn prediction
-- ============================================================
local function announce_defeat(boss, inst)
    local day = get_day()

    if cfg.sa_announce_kill then
        kill_counts[boss.prefab] = (kill_counts[boss.prefab] or 0) + 1
        local count = kill_counts[boss.prefab]
        local limit = cfg.sa_kill_limit or 0
        if limit == 0 or count <= limit then
            local times = count == 1 and "1 time" or (count .. " times")
            announce(boss.name .. " has been defeated! (" .. times .. ")")
            save_boss_killed(boss.prefab)
        end
    end

    if cfg.sa_announce_boss_respawn then
        local who = boss.respawns_as or boss.name

        if boss.seasonal == "winter" and boss.prefab == "deerclops" then
            local days = deerclops_respawn_days()
            announce(who .. " will respawn in " .. math.floor(days) .. " winter days (day " .. (day + days) .. ")")
        elseif boss.seasonal == "summer" and boss.prefab == "antlion" then
            announce(who .. " will respawn next summer")
        elseif boss.seasonal == "autumn" and boss.prefab == "bearger" then
            announce(who .. " will respawn next autumn")
        elseif boss.respawn_min and boss.respawn_max then
            announce(who .. " will spawn between day " .. (day + boss.respawn_min) .. " and " .. (day + boss.respawn_max))
        elseif boss.respawn and boss.respawn > 0 then
            announce(who .. " will spawn on day " .. (day + boss.respawn))
        end
    end
end

-- ============================================================
-- 1. BOSS DEATH
-- ============================================================
for _, b in ipairs(BOSSES) do
    if b.prefab ~= "daywalker" and b.prefab ~= "daywalker2" and b.prefab ~= "minotaur" then
        AddPrefabPostInit(b.prefab, function(inst)
            inst:ListenForEvent("death", function()
                if b.near_player_only then
                    if is_near_player(inst) then
                        announce_defeat(b, inst)
                    end
                else
                    announce_defeat(b, inst)
                end
            end)
        end)
    end
end
logSystemLoaded("Boss death")

-- ============================================================
-- 2. BOSS SPAWN (direct)
-- ============================================================
for prefab_name, display_name in pairs(DIRECT_SPAWNS) do
    local boss_entry = nil
    for _, b in ipairs(BOSSES) do
        if b.prefab == prefab_name then
            boss_entry = b
            break
        end
    end

    AddPrefabPostInit(prefab_name, function(inst)
        if cfg.sa_announce_boss_spawn then
            if boss_entry and boss_entry.near_player_only then
                if is_near_player(inst) then
                    announce(display_name .. " has spawned!")
                end
            else
                announce(display_name .. " has spawned!")
            end
        end
    end)
end
logSystemLoaded("Boss spawn")

-- ============================================================
-- 3. WEREPIG DEATH (onremove hook)
-- ============================================================
AddPrefabPostInit("daywalker", function(inst)
    inst:ListenForEvent("onremove", function()
        for _, b in ipairs(BOSSES) do
            if b.prefab == "daywalker" then
                announce_defeat(b, inst)
                break
            end
        end
    end)
end)

AddPrefabPostInit("daywalker2", function(inst)
    inst:ListenForEvent("onremove", function()
        for _, b in ipairs(BOSSES) do
            if b.prefab == "daywalker2" then
                announce_defeat(b, inst)
                break
            end
        end
    end)
end)
logSystemLoaded("Werepig checker")

-- ============================================================
-- 4. ANCIENT GUARDIAN RESPAWN
-- ============================================================
AddPrefabPostInit("stalker_atrium", function(inst)
    inst:ListenForEvent("death", function()
        if cfg.sa_announce_boss_respawn then
            announce("Ancient Guardian will spawn!")
        end
    end)
end)
logSystemLoaded("Ancient Guardian checker")

-- ============================================================
-- 5. FULL MOON / LUNAR STORM
-- ============================================================
local moonstorm_active = false

AddPrefabPostInit("world", function(inst)
    if not cfg.sa_announce_full_moon then return end

    inst:ListenForEvent("ms_stormchanged", function(_, data)
        if type(data) ~= "table" then return end
        if data.stormtype == "moonstorm" then
            moonstorm_active = data.setting
            if data.setting then
                announce("Lunar storm is happening!")
            end
        end
    end)

    local function on_moon_phase(_, phase)
        if moonstorm_active then return end
        if phase == "new" then
            inst:DoTaskInTime(1, function()
                announce("Today is new moon!")
            end)
        elseif phase == "full" then
            inst:DoTaskInTime(1, function()
                announce("Today is full moon!")
            end)
        end
    end

    inst:WatchWorldState("moonphase", on_moon_phase)
    logSystemLoaded("Moon detector")
end)

-- ============================================================
-- 6. RIFTS
-- ============================================================
local rift_announced = { lunar = false, shadow = false }

AddPrefabPostInit("world", function(inst)
    if not cfg.sa_announce_rift then return end

    local function check_rifts_enabled()
        if not GLOBAL.TheWorld then return end
        local rs = GLOBAL.TheWorld.components.riftspawner
        if not rs then return end

        if not rift_announced.lunar and rs.GetLunarRiftsEnabled and rs:GetLunarRiftsEnabled() then
            announce("Lunar rift will open on day " .. (get_day() + 5))
            rift_announced.lunar = true
        end

        if not rift_announced.shadow and rs.IsShadowRiftsEnabled and rs:IsShadowRiftsEnabled() then
            announce("Shadow rift will open on day " .. (get_day() + 5))
            rift_announced.shadow = true
        end
    end

    inst:DoPeriodicTask(60, check_rifts_enabled)
    logSystemLoaded("Rift detector")
end)

AddPrefabPostInit("lunarrift_portal", function(inst)
    if cfg.sa_announce_rift then
        announce("Lunar rift is open!")
    end
end)

AddPrefabPostInit("shadowrift_portal", function(inst)
    if cfg.sa_announce_rift then
        announce("Shadow rift is open!")
    end
end)

-- ============================================================
-- 7. SEASONAL BOSS SPAWN
-- ============================================================
AddPrefabPostInit("world", function(inst)
    if not cfg.sa_announce_seasonal then return end
    if inst:HasTag("cave") then return end

    local last_announced_season = nil

    local function on_season(_, season)
        if season == last_announced_season then return end
        last_announced_season = season

        local day = inst.state and inst.state.cycles or 0

        if season == "autumn" then
            local min, max = bearger_spawn_range()
            announce("Bearger will spawn between day " .. (day + min) .. " and " .. (day + max))

        elseif season == "winter" then
            local len = get_season_length("winter") or 15
            local delay = (len - 1) / 5
            announce("Deerclops will spawn on day " .. (day + 2 + delay))

        elseif season == "summer" then
            announce("Antlion will spawn on the first dry day of summer!")
        end
    end

    inst:WatchWorldState("season", on_season)
    logSystemLoaded("Season boss detector")
end)

-- ============================================================
-- 8. HOUND ATTACK
-- ============================================================
local hound_announced = false

AddPrefabPostInit("world", function(inst)
    if not cfg.sa_announce_hound then return end
    local enemyName = inst:HasTag("cave") and "Worm" or "Hound"

    local function check_hound()
        if not GLOBAL.TheWorld then return end
        local hounded = GLOBAL.TheWorld.components.hounded
        if not hounded or not hounded.GetTimeToAttack then return end

        local t = hounded:GetTimeToAttack()
        if type(t) ~= "number" then return end

        local DAY = GLOBAL.TUNING.TOTAL_DAY_TIME

        if t > 0 and t <= DAY then
            if not hound_announced then
                local tod = inst.state and inst.state.time or 0
                local time_left_today = (1 - tod) * DAY

                if t <= time_left_today then
                    announce(string.format("%s attack is coming today! (%s)", enemyName, formatTime(t)))
                else
                    announce(string.format("%s attack is coming tomorrow! (%s)", enemyName, formatTime(t)))
                end
                hound_announced = true
            end
        else
            hound_announced = false
        end
    end

    check_hound()
    inst:DoPeriodicTask(30, check_hound)
    logSystemLoaded("Hound predictor")
end)

-- ============================================================
-- 9. RAIN / SNOW / LUNAR HAIL
-- ============================================================
AddPrefabPostInit("world", function(inst)
    if not cfg.sa_when_rain_end then return end
    local is_cave = inst:HasTag("cave")
    local state_var = is_cave and "isacidraining" or "israining"

    local MOISTURE_RATES = {
        MIN = { autumn = 0.25, winter = 0.25, spring = 3, summer = 0.1 },
        MAX = { autumn = 1.0,  winter = 1.0,  spring = 3.75, summer = 0.5 },
    }

    local function get_label()
        if is_cave then return "Acid rain" end
        return GLOBAL.TheWorld.state.issnowing and "Snow" or "Rain"
    end

    local function get_remaining()
        local weather_net = is_cave
            and GLOBAL.TheWorld.net.components.caveweather
            or GLOBAL.TheWorld.net.components.weather
        if not weather_net or not weather_net.GetDebugString then return 0 end

        local dbgstr = weather_net:GetDebugString()
        if not dbgstr then return 0 end

        local _, _, moisture_s, floor_s, ceil_s, _, preciprate_s, peak_s =
            string.find(dbgstr, ".*moisture:%s?(%d+%.%d+)%s?%((%d+%.%d+)/(%d+%.%d+)%) %+ (%-?%d+%.%d+).*preciprate:%s?%((%d+%.%d+) of (%d+%.%d+)%).*")

        if not moisture_s then return 0 end

        local moisture = GLOBAL.tonumber(moisture_s)
        local floor    = GLOBAL.tonumber(floor_s)
        local ceil     = GLOBAL.tonumber(ceil_s)
        local rate     = GLOBAL.tonumber(preciprate_s)
        local peak     = GLOBAL.tonumber(peak_s)

        local total = 0
        local FRAME = GLOBAL.FRAMES or (1/30)

        while moisture > floor do
            if rate > 0 then
                local p = math.max(0, math.min(1, (moisture - floor) / (ceil - floor)))
                local r = 0.1 + 0.9 * math.sin(p * math.pi)
                rate = math.min(r, peak)
                moisture = math.max(moisture - rate * FRAME * 10, 0)
                total = total + FRAME
            else
                break
            end
        end

        return total
    end

    local function get_until_start()
        local state = GLOBAL.TheWorld.state
        local moisture = is_cave and state.cavemoisture or state.moisture
        local moistureceil = is_cave and state.cavemoistureceil or state.moistureceil
        if not moisture or not moistureceil then return 0 end

        local season = state.season
        local seasonprogress = state.seasonprogress
        local elapseddaysinseason = state.elapseddaysinseason
        local remainingdaysinseason = state.remainingdaysinseason

        if not remainingdaysinseason or remainingdaysinseason <= 0 then return 0 end
        if seasonprogress >= 1 then return 0 end

        local totaldaysinseason = remainingdaysinseason / (1 - seasonprogress)
        local _totaldaysinseason = elapseddaysinseason + remainingdaysinseason
        local DAY = GLOBAL.TUNING.TOTAL_DAY_TIME
        local remainingsecondsinday = DAY - (state.time * DAY)
        local totalseconds = 0

        while elapseddaysinseason < _totaldaysinseason do
            local moisturerate

            if season == "winter" and elapseddaysinseason == 2 then
                moisturerate = 50
            else
                local p = 1 - math.sin(math.pi * seasonprogress)
                moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
            end

            local _moisture = moisture + (moisturerate * remainingsecondsinday)

            if _moisture >= moistureceil then
                totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
                break
            else
                moisture = _moisture
                totalseconds = totalseconds + remainingsecondsinday
                remainingsecondsinday = DAY
                elapseddaysinseason = elapseddaysinseason + 1
                remainingdaysinseason = remainingdaysinseason - 1
                seasonprogress = 1 - (remainingdaysinseason / totaldaysinseason)
            end
        end

        return totalseconds
    end

    local function on_rain_change(_, val)
        if val then
            inst:DoTaskInTime(5, function()
                local secs = get_remaining()
                if secs > 0 then
                    local lbl = get_label()
                    local end_day = get_day_in_seconds(secs)
                    announce(string.format("%s will end on day %d (%s)", lbl, end_day, formatTime(secs)))
                end
            end)
        else
            if is_cave then return end
            local secs = get_until_start()
            if secs > 0 then
                local start_day = get_day_in_seconds(secs)
                announce(string.format("Rain will start on day %d (%s)", start_day, formatTime(secs)))
            end
        end
    end

    inst:DoTaskInTime(5, function()
        on_rain_change(nil, GLOBAL.TheWorld.state[state_var])
    end)
    inst:WatchWorldState(state_var, on_rain_change)
    logSystemLoaded(is_cave and "Acid rain predictor" or "Rain predictor")

    -- Lunar Hail (surface only)
    if not is_cave then
        local function on_lunar_hail(_, val)
            if val then
                inst:DoTaskInTime(5, function()
                    local state = GLOBAL.TheWorld.state
                    if not state.islunarhailing then return end
                    local level = state.lunarhaillevel or 0
                    local secs = level * (GLOBAL.TUNING.LUNARHAIL_EVENT_TIME / 100)
                    if secs > 0 then
                        announce(string.format("Lunar hail will end in %s", formatTime(secs)))
                    end
                end)
            else
                announce("Lunar hail has stopped")
            end
        end
		local function on_snow_change(_, val)
			local state = GLOBAL.TheWorld.state
			if state.israining then
				inst:DoTaskInTime(5, function()
					local secs = get_remaining()
					if secs > 0 then
						local lbl = val and "Snow" or "Rain"
						local end_day = get_day_in_seconds(secs)
						announce(string.format("%s will end on day %d (%s)", lbl, end_day, formatTime(secs)))
					end
				end)
			end
		end

        inst:DoTaskInTime(5, function()
            on_lunar_hail(nil, GLOBAL.TheWorld.state.islunarhailing)
        end)
        inst:WatchWorldState("islunarhailing", on_lunar_hail)
        logSystemLoaded("Lunar hail predictor")
		inst:DoTaskInTime(5, function()
			on_snow_change(nil, GLOBAL.TheWorld.state.issnowing)
		end)
		inst:WatchWorldState("issnowing", on_snow_change)
		logSystemLoaded("Snowing predictor")
    end
end)

-- ============================================================
-- 10. LOAD KILL COUNTS ON STARTUP
-- ============================================================
AddPrefabPostInit("world", function(inst)
    inst:DoTaskInTime(1, load_kills)
    logSystemLoaded("Kills save")
end)

-- ============================================================
-- 11. CAVE NIGHTMARE CYCLE
-- ============================================================
AddPrefabPostInit("world", function(inst)
    if not cfg.sa_announce_nightmare then return end
    if not inst:HasTag("cave") then return end

    local PHASE_NAMES = {
        calm = "Calm",
        warn = "Warning",
        wild = "Nightmare",
        dawn = "Dawn",
    }

    local last_phase = "none"

    local function on_phase_change(_, phase)
        if phase == "none" or phase == last_phase then return end
        last_phase = phase

        local state = GLOBAL.TheWorld.state
        local t = state.nightmaretime
        if type(t) ~= "number" or t <= 0 then return end

        local day = get_day_in_seconds(t)
        local name = PHASE_NAMES[phase] or phase

        if phase == "warn" then
            announce(string.format("Nightmare is coming! Ends on day %d (%s)", day, formatTime(t)))
        elseif phase == "wild" then
            announce(string.format("Nightmare phase active! Ends on day %d (%s)", day, formatTime(t)))
        elseif phase == "dawn" then
            announce(string.format("Nightmare is ending! Calm on day %d (%s)", day, formatTime(t)))
        elseif phase == "calm" then
            announce(string.format("Calm phase! Lasts until day %d (%s)", day, formatTime(t)))
        end
    end

	on_phase_change(nil, GLOBAL.TheWorld.state.nightmarephase)
    inst:WatchWorldState("nightmarephase", on_phase_change)
    logSystemLoaded("Nightmare cycle predictor")
end)
