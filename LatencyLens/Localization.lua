LatencyLensLocalization = {}
local L = LatencyLensLocalization

local locale = GetLocale()

-- English (default language)
L["WAIT_BEFORE_COLLECTING"] = "Please wait before collecting memory again."
L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] Memory Collected:|r %s freed"
L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00Top Addons by Memory Usage:|r"
L["FPS"] = "|cffffff00FPS:|r "
L["HOME_LATENCY"] = "|cffffff00Home Latency:|r "
L["WORLD_LATENCY"] = "|cffffff00World Latency:|r "
L["PRESS_SHIFT"] = "|cff00ff00Press SHIFT to see addon usage|r"

-- German (deDE)
if locale == "deDE" then
	L["WAIT_BEFORE_COLLECTING"] = "Bitte warten Sie, bevor Sie den Speicher erneut sammeln."
	L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] Speicher gesammelt:|r %s freigegeben"
	L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00Top-Addons nach Speichernutzung:|r"
	L["FPS"] = "|cffffff00FPS:|r "
	L["HOME_LATENCY"] = "|cffffff00Heimlatenz:|r "
	L["WORLD_LATENCY"] = "|cffffff00Weltlatenz:|r "
	L["PRESS_SHIFT"] = "|cff00ff00Drücken Sie SHIFT, um Addon-Nutzung zu sehen|r"
	-- French (frFR)
elseif locale == "frFR" then
	L["WAIT_BEFORE_COLLECTING"] = "Veuillez attendre avant de collecter à nouveau la mémoire."
	L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] Mémoire collectée:|r %s libérée"
	L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00Principaux addons par utilisation de la mémoire:|r"
	L["FPS"] = "|cffffff00FPS:|r "
	L["HOME_LATENCY"] = "|cffffff00Latence domestique:|r "
	L["WORLD_LATENCY"] = "|cffffff00Latence mondiale:|r "
	L["PRESS_SHIFT"] = "|cff00ff00Appuyez sur SHIFT pour voir l'utilisation des addons|r"
	-- Spanish (esES)
elseif locale == "esES" then
	L["WAIT_BEFORE_COLLECTING"] = "Por favor, espera antes de recoger la memoria de nuevo."
	L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] Memoria Recogida:|r %s liberada"
	L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00Principales addons por uso de memoria:|r"
	L["FPS"] = "|cffffff00FPS:|r "
	L["HOME_LATENCY"] = "|cffffff00Latencia de casa:|r "
	L["WORLD_LATENCY"] = "|cffffff00Latencia mundial:|r "
	L["PRESS_SHIFT"] = "|cff00ff00Presiona SHIFT para ver el uso de addons|r"
	-- Russian (ruRU)
elseif locale == "ruRU" then
	L["WAIT_BEFORE_COLLECTING"] = "Пожалуйста, подождите перед повторным сбором памяти."
	L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] Память собрана:|r %s освобождено"
	L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00Лучшие аддоны по использованию памяти:|r"
	L["FPS"] = "|cffffff00FPS:|r "
	L["HOME_LATENCY"] = "|cffffff00Домашняя задержка:|r "
	L["WORLD_LATENCY"] = "|cffffff00Мировая задержка:|r "
	L["PRESS_SHIFT"] = "|cff00ff00Нажмите SHIFT, чтобы увидеть использование аддонов|r"
	-- Chinese (Simplified) (zhCN)
elseif locale == "zhCN" then
	L["WAIT_BEFORE_COLLECTING"] = "请稍等再次收集内存。"
	L["MEMORY_COLLECTED"] = "|cFF00CCFF[LatencyLens] 内存已收集:|r %s 已释放"
	L["TOP_ADDONS_BY_MEMORY"] = "|cff00ff00内存使用最多的顶级插件:|r"
	L["FPS"] = "|cffffff00FPS:|r "
	L["HOME_LATENCY"] = "|cffffff00家庭延迟:|r "
	L["WORLD_LATENCY"] = "|cffffff00世界延迟:|r "
	L["PRESS_SHIFT"] = "|cff00ff00按SHIFT查看插件使用情况|r"
end
