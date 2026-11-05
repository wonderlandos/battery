-- SPDX-License-Identifier: GPL-2.0-or-later
-- Desktop card: battery health as the big figure, what it means, the capacity and the cycles.
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

return wol.widget {
  refresh = 300,
  render = function()
    local v, e = read()
    if v then b, err = v, nil else err = e end
    if not b or not b.present then
      return wol.stack { spacing = 4,
        wol.label { "Battery Care", role = "title" },
        wol.label { (b and "This computer has no battery.") or err or "Reading the battery...", role = "secondary" },
      }
    end
    return wol.stack { spacing = 4,
      wol.label { "Battery health", role = "caption" },
      wol.label { b.health and string.format("%d%%", b.health) or "-", role = "display" },
      wol.label { verdict(b.health), role = "body" },
      wol.spacer(),
      wol.label { capacity(b), role = "secondary" },
      wol.label { cycles(b), role = "secondary" },
    }
  end,
}
