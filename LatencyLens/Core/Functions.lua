local _, functions = ...

do
	-- Helper function to calculate the color gradient and percentage
	local function calculateColorGradient(a, b, ...)
		if a <= 0 or b == 0 then
			return nil, ...
		elseif a >= b then
			return nil, select(-3, ...)
		end

		local numSegments = select("#", ...) / 3
		local segment, relperc = math.modf((a / b) * (numSegments - 1))
		return relperc, select((segment * 3) + 1, ...)
	end

	-- Function to compute the RGB color gradient based on the percentage
	local function rgbColorGradient(a, b, ...)
		local relperc, r1, g1, b1, r2, g2, b2 = calculateColorGradient(a, b, ...)
		if relperc then
			return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
		else
			return r1, g1, b1
		end
	end

	local usageColor = { 0, 1, 0, 1, 1, 0, 1, 0, 0 }
	function functions:smoothColor(cur, max)
		local r, g, b = rgbColorGradient(cur, max, unpack(usageColor))
		return r, g, b
	end

	function functions:formatMemory(value)
		if value > 1024 then
			return format("%.1f mb", value / 1024)
		else
			return format("%.0f kb", value)
		end
	end

	function functions.sortByMemory(a, b)
		return a[3] > b[3]
	end

	function functions.sortByCPU(a, b)
		return a[4] > b[4]
	end

	function functions:GetTooltipAnchor(info)
		local _, height = info:GetCenter()
		if height and height > GetScreenHeight() / 2 then
			return "TOP", "BOTTOM", -15
		else
			return "BOTTOM", "TOP", 15
		end
	end
end
