local os = require("os")
local naughty = require("naughty")
local gears = require("gears")
local std = require("std")
local awful = require("awful")
local conf_dir = awful.util.get_configuration_dir()
local dir = require("pl.dir")
local string = require("string")

local notify = {
    ids = {},
    defaults = {
        text = "*crickets*",
        position = "top_middle",
        font = "sans 17",
        bg = "#322",
        fg = "white",
    },
}

function notify.fn(args)
    local args_ = std.table.clone (notify.defaults)
    std.table.merge(args_, args)
    args = args_

    args.replaces_id = notify.ids[args.id]
    local t = naughty.notify(args)

    if t and args.id then
        notify.ids[args.id] = t.id
    end
    return t
end

function random_select(t)
    local idx = 1 + math.floor(math.random() * #t)
    return t[idx]
end

function spawn_on_current_tag(cmd)
    if not client.focus then
        return
    end

    local tag = awful.screen.focused().selected_tag
    if not tag then
        return
    end
    notify.fn{
        text = "spawn " .. cmd .. " on tag:" .. tag.name
    }
    setTimeout(1, function()
        local pid = awful.spawn(cmd, {
            tag = tag,
        }, function(shit)
        end)
    end)

    --local done = false
    --local fn = function(c) 
    --    crap1("_----------")
    --    crap1(c.pid)
    --    crap1(pid)
    --    if done or pid ~= c.pid then
    --        notify.fn{text = "blah"}
    --        return
    --    end
    --    done = true
    --    setTimeout(5, function()
    --        notify.fn{text = "blah"}
    --        --c:move_to_tag(tag)
    --    end)
    --    client.disconnect_signal("manage", fn)
    --end
    --client.connect_signal("manage", fn)
end

local _timer = {
    notif = nil,
    inst = nil,
}
function hideTimer(args) 
    if _timer.inst then
        _timer.inst:stop()
        _timer.inst = nil
    end
    if _timer.notif then
        naughty.destroy(_timer.notif)
        _timer.notif = nil
    end
end

-- TODO: there must be only one instance of the timer 
function showTimer(args) 
    args = args or {}
    local args_ = std.table.clone (notify.defaults)
    std.table.merge(args_, args)
    args = args_

    args["timeout"] = -1
    args["position"] = "top_left"
    args["text"] = ""
    args["icon"] = conf_dir .. "/rec.png"

    local text = args["text"] or "recording..."
    local id = args["id"] or "record"
    local start_time = os.time()
    _timer.inst = nil
    _timer.notif = naughty.notify(args)

    args["run"] = stopTimer

    _timer.inst = gears.timer{
        timeout = 1, -- seconds
        autostart = true,
        callback = function()
            local now = os.time()
            local t1 = os.date("*t", start_time)
            local t2 = os.date("*t", now)
            local hours = leftpad(t2["hour"] - t1["hour"], 2, "0")

            local diff = now - start_time
            local time_str = hours .. ":" .. os.date("%M:%S", diff)
            args["text"] = time_str .. " " .. text
            naughty.replace_text(
                _timer.notif, args["title"], args["text"]
            )
            --notify.fn(args)
        end
    }
end

function leftpad(s, n, c)
    s = tostring(s)
    local x = n - string.len(s)
    return string.rep(tostring(c), x) .. s
end

function setTimeout(seconds, fn)
    gears.timer{
        timeout = seconds,
        autostart = true,
        single_shot = true,
        callback = function()
            fn()
            return false
        end
    }
end

function random_bg()
    local bgdir = conf_dir .. "backgrounds"
    local bgs = dir.getfiles(bgdir)
    return random_select(bgs)
end

function random_theme()
    local theme_dir = conf_dir .. "themes"
    local themes = dir.getdirectories(theme_dir)
    if #themes == 0 then
        return ""
    end
    return random_select(themes) .. "/theme.lua"
end

notify.fn{
    text = "module reloaded",
    id = "nvlled.lua",
}

function readCwd(fn)
    if not client.focus then
        return false
    end
    pid = client.focus.pid
    awful.spawn.easy_async( "pgrep -P ".. pid .." -a", function(output) 
        for line in string.gmatch(output, "[^\r\n]+") do
            local words = std.string.split(line)
            if #words >= 2 then
                local n = std.string.find(words[2], "bash")
                if n then
                    local id = words[1]
                    awful.spawn.easy_async(
                        "readlink /proc/"..id.."/cwd",
                        function(cwd) 
                            fn(cwd)
                        end
                    )
                end
            end
        end
    end)
    return true
end


return {
    blah = blah,
    notify = notify.fn,
    readCwd = readCwd,
    random_select = random_select,
    random_bg = random_bg,
    random_theme = random_theme,
    spawn_on_current_tag = spawn_on_current_tag,
    setTimeout = setTimeout,
    showTimer = showTimer,
    hideTimer = hideTimer,
    leftpad = leftpad,
}
