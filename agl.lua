-- ============================================================================
-- Above Ground Level (AGL) FlyWithLua Script
--   Exponential moving average for filtering
--   ImGui window sizing based on largest text scenario
-- ============================================================================

-- Namespace to prevent global collision
Mg = {}

-- Datarefs
local agl_meters = dataref_table("sim/flightmodel/position/y_agl")

-- ----------------------------------------------------------------------------
-- CONSTANTS & TUNING
-- ----------------------------------------------------------------------------

-- Signal Processing
local EMA_ALPHA = 0.15 -- Smoothing factor (0.0 to 1.0).  Lower is smoother but adds more lag.
local UPDATE_HZ = 6 -- Logic frequency. 6Hz is plenty for UI.
local TICK_INTERVAL = 1 / UPDATE_HZ

-- Conversion Constants
local METERS_TO_FEET = 3.28084

-- Window Decoration Constants (FlyWithLua API)
local WND_TITLE_BAR = 1 -- Standard window with title bar and background
local WND_VISIBLE = true
local WND_HIDDEN = false
local WND_DEFAULT_W = 150
local WND_DEFAULT_H = 60

-- UI / ImGui Styling
local UI_FONT_SCALE = 1.5 -- 1.0 is default size

-- ----------------------------------------------------------------------------
-- STATE VARIABLES
-- ----------------------------------------------------------------------------
local smoothed_agl_ft = nil
local last_update_time = os.clock()

-- Create the window
local window = float_wnd_create(WND_DEFAULT_W, WND_DEFAULT_H, WND_TITLE_BAR, WND_VISIBLE)
float_wnd_set_title(window, "AGL")

-- ----------------------------------------------------------------------------
-- CALLBACKS
-- ----------------------------------------------------------------------------

function Mg.on_draw(wnd, x, y)
	imgui.SetWindowFontScale(UI_FONT_SCALE)

	-- Displaying the smoothed value rounded to the nearest foot (%.0f)
	local val = smoothed_agl_ft or 0
	imgui.TextUnformatted(string.format("AGL: %.0f ft", val))
end

float_wnd_set_imgui_builder(window, Mg.on_draw)

function Mg.on_update()
	local now = os.clock()

	-- Throttle execution to the defined TICK_INTERVAL
	if now - last_update_time < TICK_INTERVAL then
		return
	end
	last_update_time = now

	-- Get raw altitude and convert to feet
	local raw_agl_ft = agl_meters[0] * METERS_TO_FEET
	if raw_agl_ft < 0 then
		raw_agl_ft = 0
	end

	-- Apply Exponential Moving Average (EMA)
	if smoothed_agl_ft == nil then
		smoothed_agl_ft = raw_agl_ft -- Initialize with current altitude
	else
		smoothed_agl_ft = (EMA_ALPHA * raw_agl_ft) + ((1 - EMA_ALPHA) * smoothed_agl_ft)
	end
end

-- Hook into X-Plane's frame loop
do_every_frame("Mg.on_update()")
