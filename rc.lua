require("wicked")
-- Standard awesome library
require("awful")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Load my widget functions
-- require("functions")
 cardid  = 0
 channel = "Master"
 function volume (mode, widget)
    if mode == "update" then
       local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
       local status = fd:read("*all")
       fd:close()
       
       local volume = string.match(status, "(%d?%d?%d)%%")
       volume = string.format("% 3d", volume)
       
       status = string.match(status, "%[(o[^%]]*)%]")
       
       if string.find(status, "on", 1, true) then
	  volume = volume .. "%"
       else
	  volume = volume .. "M"
       end
       widget.text = volume
    elseif mode == "up" then
       io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%+"):read("*all")
       volume("update", widget)
    elseif mode == "down" then
       io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%-"):read("*all")
       volume("update", widget)
    else
       io.popen("amixer -c " .. cardid .. " sset " .. channel .. " toggle"):read("*all")
       volume("update", widget)
    end
 end


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
-- The default is a dark theme
-- theme_path = "/usr/share/awesome/themes/default/theme"
-- Uncommment this for a lighter theme
-- theme_path = "/usr/share/awesome/themes/default/theme"
theme_path = os.getenv("HOME") .. "/.config/awesome/themes/default/theme"

-- Actually load theme
beautiful.init(theme_path)

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor
browser = "firefox"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
-- Volume
cardid = 0
channel = "Master"
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}

-- Text for the current layout 
	layoutText          = { ["awful.layout.suit.tile"]        = "Tiled" 
	                      , ["tileleft"]    = "TileLeft" 
	                      , ["tilebottom"]  = "TileBottom" 
	                      , ["tiletop"]     = "TileTop" 
	                      , ["fairh"]       = "FairH" 
	                      , ["fairv"]       = "FairV" 
	                      , ["magnifier"]   = "Magnifier" 
	                      , ["max"]         = "Max" 
	                      , ["floating"]    = "Floating" 
}  

-- Table of clients that should be set floating. The index may be either
-- the application class or instance. The instance is useful when running
-- a console app in a terminal like (Music on Console)
--    xterm -name mocp -e mocp
floatapps =
{
    -- by class
    ["MPlayer"] = true,
    ["comix"] = true,
    ["comical"] = true,
    ["pinentry"] = true,
    ["gimp"] = true,
    ["nitrogen"] = true,
    -- by instance
    ["mocp"] = true
}

-- Applications to be moved to a pre-defined tag by class or instance.
-- Use the screen and tags indices.
apptags =
{
    -- ["Firefox"] = { screen = 1, tag = 2 },
    -- ["mocp"] = { screen = 2, tag = 4 },
}

-- Define if we want to use titlebar on all applications.
use_titlebar = false
-- }}}

tags = {}
tags.settings = {
    { name = "0",  layout = layouts[1], setslave = true },
    { name = "1", layout = layouts[1], setslave = true },
    { name = "2",   layout = layouts[1]  },
    { name = "3",  layout = layouts[4]  },
    { name = "4",    layout = layouts[10]  }
}
-- Initialize tags
for s = 1, screen.count() do
    tags[s] = {}
    for i, v in ipairs(tags.settings) do
        tags[s][i] = tag(v.name)
        tags[s][i].screen = s
        awful.tag.setproperty(tags[s][i], "layout",   v.layout)
        awful.tag.setproperty(tags[s][i], "setslave", v.setslave)
    end
    tags[s][1].selected = true
end
-- }}}

-- }}}


-- {{{ Wibox
-- Create a textbox widget
mytextbox = widget({ type = "textbox", align = "right" })
-- Set the default text in textbox
mytextbox.text = "<b><small> " .. AWESOME_RELEASE .. " </small></b>"

-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu.new({ items = {
	{ "awesome", myawesomemenu, beautiful.awesome_icon },
        { "urxvt", terminal },
	{ "firefox", browser },
        { "irc", 'urxvtc -e screen irssi' },
        { "thunar", 'thunar' },
        { "wee", 'urxvtc -e screen weechat-curses' }
	}
})
			 
mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })

-- Create a systray
mysystray = widget({ type = "systray", align = "right" })


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
layoutbox = {}
mytaglist = {}
mytaglist.buttons = { button({ }, 1, awful.tag.viewonly),
                      button({ modkey }, 1, awful.client.movetotag),
                      button({ }, 3, function (tag) tag.selected = not tag.selected end),
                      button({ modkey }, 3, awful.client.toggletag),
                      button({ }, 4, awful.tag.viewnext),
                      button({ }, 5, awful.tag.viewprev) }
mytasklist = {}
mytasklist.buttons = { button({ }, 1, function (c)
                                          if not c:isvisible() then
                                              awful.tag.viewonly(c:tags()[1])
                                          end
                                          client.focus = c
                                          c:raise()
                                      end),
                       button({ }, 3, function () if instance then instance:hide() end instance = awful.menu.clients({ width=250 }) end),
                       button({ }, 4, function ()
                                          awful.client.focus.byidx(1)
                                          if client.focus then client.focus:raise() end
                                      end),
                       button({ }, 5, function ()
                                          awful.client.focus.byidx(-1)
                                          if client.focus then client.focus:raise() end
                                      end) }

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = widget({ type = "textbox", align = "left" })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    layoutbox[s] = widget({ type = "imagebox", align = "right" })
    layoutbox[s]:buttons({ button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                             button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                             button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                             button({ }, 5, function () awful.layout.inc(layouts, -1) end) })
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist.new(s, awful.widget.taglist.label.all, mytaglist.buttons)

-- mpd
mpdwidget = widget({
    type = 'textbox',
    name = 'mpdwidget',
    align = 'right'
})

wicked.register(mpdwidget, wicked.widgets.mpd, 
	function (widget, args)
		   if args[1]:find("volume:") == nil then
		      return '<span color="white">MPD: </span>' ..args[1] 
		   else
                      return ''
                   end
		end)
-- sep 
sep = widget({ 
	type = "textbox",
         align = 'right'
})
sep.text = ' <span color ="white"> ¤</span> '

  -- CPU Graph
cpugraphwidget = widget({
    type = 'graph',
    name = 'cpugraphwidget',
    align = 'right'
})

cpugraphwidget.height = 0.85
cpugraphwidget.width = 45
cpugraphwidget.bg = '#333333'
cpugraphwidget.border_color = '#0a0a0a'
cpugraphwidget.grow = 'left'

cpugraphwidget:plot_properties_set('cpu', {
    fg = '#AEC6D8',
    fg_center = '#285577',
    fg_end = '#285577',
    vertical_gradient = false
})

wicked.register(cpugraphwidget, wicked.widgets.cpu, '$1', 1, 'cpu')

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist.new(function(c)
                                                  return awful.widget.tasklist.label.currenttags(c, s)
                                              end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = wibox({ position = "bottom", fg = beautiful.fg_normal, bg = beautiful.bg_normal, height = "14" })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = { mytaglist[s],
                     --      mytasklist[s],
                           mypromptbox[s],
                          -- cpugraphwidget,
                           mpdwidget,
                           sep,
                           mytextbox,
			   layoutbox[s],
			   -- mysystray,
                           s == 1 or nil }
    mywibox[s].screen = s
end
-- }}}

-- {{{ Mouse bindings
root.buttons({
    button({ }, 3, function () mymainmenu:toggle() end),
    button({ }, 4, awful.tag.viewnext),
    button({ }, 5, awful.tag.viewprev)
})
-- }}}

-- {{{ Key bindings
globalkeys =
{
    key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    key({ modkey,           }, "Escape", awful.tag.history.restore),
    key({ modkey,           }, "j",
       function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    key({ modkey }, "w", function () awful.util.spawn("firefox") end),
    key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),
    key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),
    key({ modkey, "Control" }, "j", function () awful.screen.focus( 1)       end),
    key({ modkey, "Control" }, "k", function () awful.screen.focus(-1)       end),
    key({ modkey,           }, "u", awful.client.urgent.jumpto),
    key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    key({ modkey, "Control" }, "r", awesome.restart),
    key({ modkey, "Shift"   }, "q", awesome.quit),

    key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    key({ modkey }, "F1",
        function ()
            awful.prompt.run({ prompt = "Run: " },
            mypromptbox[mouse.screen],
            awful.util.spawn, awful.completion.bash,
            awful.util.getdir("cache") .. "/history")
        end),

    key({ modkey }, "F4",
        function ()
            awful.prompt.run({ prompt = "Run Lua code: " },
            mypromptbox[mouse.screen],
            awful.util.eval, awful.prompt.bash,
            awful.util.getdir("cache") .. "/history_eval")
        end),
}

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys =
{
    key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    key({ modkey }, "t", awful.client.togglemarked),
    key({ modkey,}, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
}

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

for i = 1, keynumber do
    table.insert(globalkeys,
        key({ modkey }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    awful.tag.viewonly(tags[screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Control" }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    tags[screen][i].selected = not tags[screen][i].selected
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Shift" }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.movetotag(tags[client.focus.screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Control", "Shift" }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.toggletag(tags[client.focus.screen][i])
                end
            end))
end


for i = 1, keynumber do
    table.insert(globalkeys, key({ modkey, "Shift" }, "F" .. i,
                 function ()
                     local screen = mouse.screen
                     if tags[screen][i] then
                         for k, c in pairs(awful.client.getmarked()) do
                             awful.client.movetotag(tags[screen][i], c)
                         end
                     end
                 end))
end

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Hooks
-- Hook function to execute when focusing a client.
awful.hooks.focus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_focus
    end
end)

-- Hook function to execute when unfocusing a client.
awful.hooks.unfocus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_normal
    end
end)

-- Hook function to execute when marking a client
awful.hooks.marked.register(function (c)
    c.border_color = beautiful.border_marked
end)

-- Hook function to execute when unmarking a client.
awful.hooks.unmarked.register(function (c)
    c.border_color = beautiful.border_focus
end)

-- Hook function to execute when the mouse enters a client.
awful.hooks.mouse_enter.register(function (c)
    -- Sloppy focus, but disabled for magnifier layout
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- Hook function to execute when a new client appears.
awful.hooks.manage.register(function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for filtered windows (i.e. no dock, etc).
    if not startup and awful.client.focus.filter(c) then
        c.screen = mouse.screen
    end

    if use_titlebar then
        -- Add a titlebar
        awful.titlebar.add(c, { modkey = modkey })
    end
    -- Add mouse bindings
    c:buttons({
        button({ }, 1, function (c) client.focus = c; c:raise() end),
        button({ modkey }, 1, awful.mouse.client.move),
        button({ modkey }, 3, awful.mouse.client.resize)
    })
    -- New client may not receive focus
    -- if they're not focusable, so set border anyway.
    c.border_width = beautiful.border_width
    c.border_color = beautiful.border_normal

    -- Check if the application should be floating.
    local cls = c.class
    local inst = c.instance
    if floatapps[cls] then
        awful.client.floating.set(c, floatapps[cls])
    elseif floatapps[inst] then
        awful.client.floating.set(c, floatapps[inst])
    end

    -- Check application->screen/tag mappings.
    local target
    if apptags[cls] then
        target = apptags[cls]
    elseif apptags[inst] then
        target = apptags[inst]
    end
    if target then
        c.screen = target.screen
        awful.client.movetotag(tags[target.screen][target.tag], c)
    end

    -- Do this after tag mapping, so you don't see it on the wrong tag for a split second.
    client.focus = c

    -- Set key bindings
    c:keys(clientkeys)

    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Honor size hints: if you want to drop the gaps between windows, set this to false.
    -- c.size_hints_honor = false
end)

-- Hook function to execute when arranging the screen.
-- (tag switch, new client, etc)
awful.hooks.arrange.register(function (screen)
    local layout = awful.layout.getname(awful.layout.get(screen))
    if layout and beautiful["layout_" ..layout] then
        layoutbox[screen].image = image(beautiful["layout_" .. layout])
    else
        layoutbox[screen].image = nil
    end

    -- Give focus to the latest client in history if no window has focus
    -- or if the current window is a desktop or a dock one.
    if not client.focus then
        local c = awful.client.focus.history.get(screen, 0)
        if c then client.focus = c end
    end
end)

-- Hook called every minute
awful.hooks.timer.register(60, function ()
    mytextbox.text = os.date(" %a %b %d, %H:%M ")
end)
-- }}}



-- Widgets using wicked
--mem
memwidget = widget({
   type = 'textbox',
   name = 'memwidget',
   align = "right"
})
wicked.register(memwidget, wicked.widgets.mem,
   ' <span color ="white">MEM:</span> $1% ($2Mb) ')
--date
datewidget = widget({
   type = 'textbox',
   name = 'datewidget',
})
wicked.register(datewidget, wicked.widgets.date,
   ' Date: %c')
-- file system
fswidget = widget({
   type = 'textbox',
   name = 'fswidget',
   align = "right"
})
wicked.register(fswidget, wicked.widgets.fs,
   ' FS: /root ${/ usep}% used, /home  ${/home usep}% used || ', 30)
-- cpu
cpuwidget = widget({
   type = 'textbox',
   name = 'cpuwidget',
   align = "right"
})

wicked.register(cpuwidget, wicked.widgets.cpu,
   ' <span color ="white">CPU:</span> $1% ')
--load avg
-- {{{ Load Averages Widget
-- Volume level progressbar and changer
myvolwidget     = widget({ type = "textbox", name = "myvolwidget", align = "right" })
myvolbarwidget  = widget({ type = "progressbar", name = "myvolbarwidget", align = "right" })
myvolbarwidget.width          = 10
myvolbarwidget.height         = 0.9
myvolbarwidget.gap            = 0
myvolbarwidget.border_padding = 1
myvolbarwidget.border_width   = 0
myvolbarwidget.ticks_count    = 4
myvolbarwidget.ticks_gap      = 1
myvolbarwidget.vertical       = true
myvolbarwidget:bar_properties_set("volume", {
    bg        = beautiful.bg_widget,
    fg        = beautiful.fg_widget,
    fg_center = beautiful.fg_widget,
    fg_end    = beautiful.fg_end_widget,
    fg_off    = beautiful.fg_off_widget,
    min_value = 0,
    max_value = 100
})
function get_volstate()
    local filedescriptor = io.popen('amixer get PCM | awk \'{ field = $NF }; END{sub(/%/," "); print substr($5,2,3)}\'')
    local value = filedescriptor:read()
    filedescriptor:close()
    return {value}
end
wicked.register(myvolwidget, get_volstate, ' <span color ="white">Vol:</span> $1% ', 2)
wicked.register(myvolbarwidget, get_volstate, " $1", 2, "volume")
--vol 2
 tb_volume = widget({ type = "textbox", name = "tb_volume", align = "right" })
 tb_volume:buttons({
	button({ }, 4, function () volume("up", tb_volume) end),
 	button({ }, 5, function () volume("down", tb_volume) end),
 	button({ }, 1, function () volume("mute", tb_volume) end)
 })
 volume("update", tb_volume)
-- net widget
	netwidget = widget(
	{
		type = 'textbox',
		name = 'netwidget',
		align = 'right'
	})
		wicked.register(netwidget, wicked.widgets.net,
		'<span color ="white">NET: </span>[${eth0 down} / ${eth0 up}] ')
-- sep 
sep = widget({ 
type = "textbox", 
align = 'right'
})
sep.text = ' <span color ="brown">¤</span> '
-- bat
mybatwidget = widget({ type = "textbox", name = "mybatwidget", align = "right" })
function get_batstate()
    local filedescriptor = io.popen('acpitool -b | awk \'{sub(/discharging,/,"-")sub(/charging,|charged,/,"+")sub(/\\./," "); print $4 substr($5,1,3)}\'')
    local value = filedescriptor:read()
    filedescriptor:close()
    return {value}
end
wicked.register(mybatwidget, get_batstate, ' <span color ="white">Bat:</span> $1% ', 60)
-- statebar in the bottom
mystatebar = wibox( {position = "top", fg = beautiful.fg_normal, bg = beautiful.bg_trans} )
mystatebar.widgets = {   	
   tb_volume,
   netwidget,
   sep,
   cpuwidget,
   sep,
   memwidget,
  sep,
 myvolwidget,
 myvolbarwidget,
sep, 
 mybatwidget,
}
mystatebar.screen = 1

awful.hooks.timer.register(10, function () volume("update", tb_volume) end)