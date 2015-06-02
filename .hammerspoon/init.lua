-- Bob Ziuchkovski's Hammerspoon config
-- 
-- I'm not sure who to credit for the caffeine icons.  The files are used by several
-- of the configs from https://github.com/Hammerspoon/hammerspoon/wiki/Sample-Configurations
-- but none claim ownership or attribute the icons.  I'm tempted to drop and replace with
-- something that is definitely licensed under the creative commons license.

function reload_config()
  hs.reload()
  hs.notify.new({title='Hammerspoon', subTitle='Configuration loaded'}):send()
end

function flash_utc()
  hs.alert(os.date('!%H:%M:%S UTC'), 2)
end

-- Briefly mark the pointer position
function flash_pointer()
  if timer then
    timer:stop()
  end
  if marker then
    marker:delete()
  end

  marker = mark_position(hs.mouse.getAbsolutePosition())
  timer = hs.timer.doAfter(0.5, function() marker:delete() end)
end

-- Mark an onscreen position with a red circle
function mark_position(pos)
  marker = hs.drawing.circle(hs.geometry.rect(pos.x - 20, pos.y - 20, 40, 40))
  marker:setFill(false)
  marker:setStrokeWidth(5)
  marker:setStrokeColor({['red']=1.0, ['green']=0.0, ['blue']=0.0, ['alpha']=0.5})
  marker:show()
  return marker
end

-- Toggle named app's visibility, launching if needed
function toggle_app(name)
  focused = hs.window.focusedWindow()
  if focused then
    app = focused:application()
    if app:title() == name then
      app:hide()
      return
    end
  end

  hs.application.launchOrFocus(name)
end

-- Create a caffeine-like menu item to prevent the system from sleeping
-- The display is still allowed to sleep (see hs.caffeinate docs)
caffeine = hs.menubar.new()
caffeine:setClickCallback(function()
  set_caffeinated(not hs.caffeinate.get('systemIdle'))
end)

function set_caffeinated(caffeinated)
  ac_and_battery = true
  hs.caffeinate.set('systemIdle', caffeinated, ac_and_battery)
  hs.settings.set('caffeinated', caffeinated)
  if caffeinated then
    caffeine:setIcon('caffeine-on.pdf')
  else
    caffeine:setIcon('caffeine-off.pdf')
  end
end

-- Toggle a window between full screen and orginial position
max_state = {}
function toggle_maximized(window)
  if not window then
    return
  end

  id = window:id()
  if max_state[id] == nil then
    max_state[id] = window:frame()
    window:maximize()
  else
    window:setFrame(max_state[id])
    max_state[id] = nil
  end
end

-- Move a window
-- The rect's x, y, w, and h params are percentages of the screen (0.0 to 1.0)
function move_window(window, rect)
  if not window then
    return
  end

  screen = hs.screen.mainScreen():frame()
  window:setFrame({
    -- screen:frame() accounts for menu and dock, hence the .x/.y offsets
    x = screen.x + rect.x * screen.w,
    y = screen.y + rect.y * screen.h,
    w = rect.w * screen.w,
    h = rect.h * screen.h,
  })
end

function move_focused(x, y, w, h)
  move_window(hs.window.focusedWindow(), x, y, w, h)
end

-- Cycle the focused window between a series of rect positions
-- The op arg is an identifier used to track sequentiality
cycle_state = {}
function cycle_focused(op, rects)
  focused = hs.window.focusedWindow()
  prior = cycle_state[focused:id()]
  
  if prior and op == prior['op'] then
    i = prior['index'] + 1
    if (i > #rects) then
      i = 1
    end
  else
    i = 1
  end
  move_window(focused, rects[i])
  cycle_state[focused:id()] = {['op'] = op, ['index'] = i}
end


-- Init
set_caffeinated(hs.settings.get('caffeinated') == true)
hs.window.animationDuration = 0

-- Keys
mash = {'ctrl', 'alt', 'cmd'}

-- Applications, toggle visibility
-- Chrome is bound to several keys since 'c' is used for centering
hs.hotkey.bind(mash, 'g', function() toggle_app('Google Chrome') end)
hs.hotkey.bind(mash, 'w', function() toggle_app('Google Chrome') end)
hs.hotkey.bind(mash, 'b', function() toggle_app('Google Chrome') end)
hs.hotkey.bind(mash, 'f', function() toggle_app('ForkLift') end)
hs.hotkey.bind(mash, 'i', function() toggle_app('iTerm') end)
hs.hotkey.bind(mash, 's', function() toggle_app('Sublime Text') end)

-- Additional toggle to accomodate my muscle memory
hs.hotkey.bind({'cmd'}, 'f1', function() toggle_app('iTerm') end)

-- Layout, toggle maximized
hs.hotkey.bind(mash, 'm', function() toggle_maximized(hs.window.focusedWindow()) end)

-- Layout, chorded center, left, right, top, and bottom
hs.hotkey.bind(mash, 'c', function()
  cycle_focused('center', {
    hs.geometry.rect(0.1, 0.0, 0.8, 1.0),
    hs.geometry.rect(0.2, 0.0, 0.6, 1.0),
  })
end)

hs.hotkey.bind(mash, 'left', function()
  cycle_focused('left', {
    hs.geometry.rect(0.0, 0.0, 0.5, 1.0),
    hs.geometry.rect(0.0, 0.0, 0.4, 1.0),
    hs.geometry.rect(0.0, 0.0, 0.6, 1.0),
  })
end)

hs.hotkey.bind(mash, 'right', function()
  cycle_focused('right', {
    hs.geometry.rect(0.5, 0.0, 0.5, 1.0),
    hs.geometry.rect(0.6, 0.0, 0.4, 1.0),
    hs.geometry.rect(0.4, 0.0, 0.6, 1.0),
  })
end)

hs.hotkey.bind(mash, 'up', function()
  cycle_focused('up', {
    hs.geometry.rect(0.0, 0.0, 1.0, 0.5),
    hs.geometry.rect(0.0, 0.0, 1.0, 0.4),
    hs.geometry.rect(0.0, 0.0, 1.0, 0.6),
  })
end)

hs.hotkey.bind(mash, 'down', function()
  cycle_focused('down', {
    hs.geometry.rect(0.0, 0.5, 1.0, 0.5),
    hs.geometry.rect(0.0, 0.6, 1.0, 0.4),
    hs.geometry.rect(0.0, 0.4, 1.0, 0.6),
  })
end)

-- Layout, quadrant upper-left, upper-right, lower-left, lower-right
hs.hotkey.bind(mash, '1', function() move_focused(hs.geometry.rect(0.0, 0.0, 0.5, 0.5)) end)
hs.hotkey.bind(mash, '2', function() move_focused(hs.geometry.rect(0.5, 0.0, 0.5, 0.5)) end)
hs.hotkey.bind(mash, '3', function() move_focused(hs.geometry.rect(0.0, 0.5, 0.5, 0.5)) end)
hs.hotkey.bind(mash, '4', function() move_focused(hs.geometry.rect(0.5, 0.5, 0.5, 0.5)) end)

-- Misc
hs.hotkey.bind(mash, 'r', reload_config)
hs.hotkey.bind(mash, ',', flash_pointer)
hs.hotkey.bind(mash, 'u', flash_utc)

hs.hotkey.bind(mash, 'y', hs.toggleConsole)
hs.hotkey.bind(mash, '.', hs.hints.windowHints)
hs.hotkey.bind(mash, 'l', hs.caffeinate.startScreensaver)
