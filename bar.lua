-- SPDX-License-Identifier: GPL-2.0-or-later
-- Menu bar item: a battery icon, and "Unplug" while the battery is charging at or above the chosen
-- charge, with one notification per charge. The popover has the details, the charge and the
-- reminder switch. Settings are kept in wol.state: limit (60..100, default 80) and remind.
-- `wol battery --json`: { present, percent, charge = "Charging" | "Discharging" | "Full", health,
-- cycles, minutes_left, design_mwh, full_mwh }; the last five may be missing.
local function read()
  local ok, out = wol.run { "wol", "battery", "--json", timeout = 5 }
  if not ok then return nil, out end
  local v, e = wol.json.decode(out)
  if not v then return nil, e end
  return v
end

local function wh(mwh) return string.format("%.1f Wh", mwh / 1000) end

-- "Good", "Worn" or "Worn out", from the share of the original capacity left.
local function verdict(health)
  if not health then return "Health unknown" end
  if health >= 80 then return "Good" end
  if health >= 60 then return "Worn: it holds less than it did" end
  return "Worn out: a new battery would last much longer"
end

local function capacity(b)
  if b.full_mwh and b.design_mwh then
    return "Holds " .. wh(b.full_mwh) .. " of the " .. wh(b.design_mwh) .. " it was made for"
  end
  return "Capacity unknown"
end

local function cycles(b)
  if not b.cycles then return "Charge cycles unknown" end
  return string.format("%d charge cycle%s", b.cycles, b.cycles == 1 and "" or "s")
end

local b, err = nil, nil
local notified = false

local function limit()
  local l = wol.state.get("limit")
  if type(l) ~= "number" then return 80 end
  return l
end

local function remind()
  return wol.state.get("remind") ~= false
end

local function time_left(m)
  if not m then return nil end
  return string.format("about %d h %02d min left", math.floor(m / 60), m % 60)
end

local function charge_line()
  if b.charge == "Charging" then return "Charging" end
  if b.charge == "Full" then return "Plugged in, not charging" end
  return time_left(b.minutes_left) or "On battery"
end

local function over()
  return b and b.present and b.charge == "Charging" and (b.percent or 0) >= limit() and remind()
end

return wol.menubar {
  refresh = 60,
  render = function()
    local v, e = read()
    if v then b, err = v, nil else err = e end
    if not b then return wol.image { "battery-symbolic", size = 16 } end
    if not b.present then return wol.image { "battery-missing-symbolic", size = 16 } end
    if b.charge ~= "Charging" then notified = false end
    if over() then
      if not notified then
        notified = true
        wol.notify(string.format("Battery at %d%%", b.percent),
          "Unplug the charger now: a battery that is not kept full lasts longer.")
      end
      return wol.row { spacing = 4,
        wol.image { "battery-full-charging-symbolic", size = 16 },
        wol.label { "Unplug" },
      }
    end
    return wol.image { "battery-good-symbolic", size = 16 }
  end,
  popover = function()
    if not b then
      return wol.stack { spacing = 8,
        wol.label { "Battery Care", role = "title" },
        wol.label { err or "Reading the battery...", role = "secondary" },
      }
    end
    if not b.present then
      return wol.stack { spacing = 8,
        wol.label { "Battery Care", role = "title" },
        wol.label { "This computer has no battery.", role = "secondary" },
      }
    end
    local l = limit()
    return wol.stack { spacing = 12,
      wol.label { "Battery Care", role = "title" },
      wol.list {
        wol.item { title = string.format("Charge %d%%", b.percent or 0), subtitle = charge_line(),
                   icon = "battery-good-symbolic" },
        wol.item { title = b.health and string.format("Health %d%%", b.health) or "Health", subtitle = verdict(b.health),
                   icon = "emblem-ok-symbolic" },
        wol.item { title = cycles(b), subtitle = capacity(b), icon = "view-refresh-symbolic" },
      },
      wol.toggle { label = string.format("Remind me to unplug at %d%%", l), on = remind(),
        on_change = function(on) wol.state.set("remind", on) end },
      wol.slider { value = l, min = 60, max = 100, on_change = function(x)
        wol.state.set("limit", math.floor(x / 5 + 0.5) * 5)
        notified = false
      end },
    }
  end,
}
