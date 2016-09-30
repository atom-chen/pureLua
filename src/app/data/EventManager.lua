--
-- 处理服务器下发事件
--
local s_manager = nil
local playerDataMgr = import(".PlayerDataManager"):getInstance()

local EventManager = class("EventManager")

function EventManager:getInstance()
	if nil == s_manager then
		s_manager = EventManager.new()
	end
	return s_manager
end

function EventManager:push(pb)
	-- dump(pb)
	local FUNCTIONS = {
		DIFF_DATA = function(data) self:processDiffData(data.diff) end,
	}
	local events = pb.events
	-- dump(events)
	for _,v in ipairs(events) do
		printInfo("[EventManager] find event:"..v.event)
		local func = FUNCTIONS[v.event]
		if func then
			func(v)
		else
			printInfo("[EventManager] Unhandled event:"..v.event)
		end
	end
end

function EventManager:processDiffData(diff)
    -- dump(diff.type)
    -- dump(diff)
    if diff.type == PLAYER_SOUL_INTENSIFY then
    	dump(diff.player_soul_intensify)
    end


	local FUNCTIONS = {
		PLAYER_STATUS            = function(diff) playerDataMgr:updateStatusByDiff(diff.player) end,
		PLAYER_SOUL		         = function(diff) playerDataMgr:updateSoulByDiff(diff.player_soul) end,
		PLAYER_SOUL_ASSEMBLAGE	 = function(diff) playerDataMgr:updateSoulAssemblageByDiff(diff.player_soul_assemblage) end,
		PLAYER_SOUL_INTENSIFY	 = function(diff) playerDataMgr:updateSoulIntensifyByDiff(diff.player_soul_intensify) end,
		PLAYER_MATERIAL	         = function(diff) playerDataMgr:updateMaterialByDiff(diff.player_material) end,
		PLAYER_HERO			     = function(diff) playerDataMgr:updateHeroByDiff(diff.player_hero) end,
		PLAYER_HERO_INTENSIFY	 = function(diff) playerDataMgr:updateHeroIntensifyByDiff(diff.player_heroIntensify) end,
		PLAYER_GATE			     = function(diff) playerDataMgr:updateGateByDiff(diff.player_gate) end,
		PLAYER_STAGE		     = function(diff) playerDataMgr:updateStageByDiff(diff.player_stage) end,
		PLAYER_STAGEREWARD	     = function(diff) playerDataMgr:updateStageRewardByDiff(diff.player_stageReward) end,
		PLAYER_MAIL			     = function(diff) playerDataMgr:updateMailByDiff(diff.player_mail) end,
		PLAYER_SIGN              = function(diff) playerDataMgr:updateSignByDiff(diff.player_sign) end,
		PLAYER_PROP              = function(diff) playerDataMgr:updatePropByDiff(diff.player_prop) end,
		PLAYER_ASSEMBLAGE		 = function(diff) playerDataMgr:updateAssemblageByDiff(diff.player_assemblage) end,
		PLAYER_SOUL_FRAGMENT     = function(diff) playerDataMgr:updateSoulFragmentByDiff(diff.player_soul_fragment) end,
		PLAYER_DECORATION        = function(diff) playerDataMgr:updateDecorationByDiff(diff.player_decoration) end,
		PLAYER_SHOWER            = function(diff) playerDataMgr:updateShowerByDiff(diff.player_shower) end,
		PLAYER_DEVPROP           = function(diff) playerDataMgr:updateDevPropByDiff(diff.player_devProp) end,
		PLAYER_DEVPROP_SHOP      = function(diff) playerDataMgr:updateDevPropShopByDiff(diff.player_devPropShop) end,
		PLAYER_ACTIONTOUCH       = function(diff) playerDataMgr:updateActionTouch(diff.player_actionTouch) end,
		PLAYER_SOUL_PROJECT      = function(diff) playerDataMgr:updateSoulProjectDiff(diff.player_soul_project) end,
		PLAYER_CONFIG 			 = function(diff) playerDataMgr:updateConfigDiff(diff.player_config) end,
		PLAYER_SHOP_FASHION 	 = function(diff) playerDataMgr:updateShopFashionDiff(diff.player_shop_fashion) end,
		PLAYER_SOUL_FASHION		 = function(diff) playerDataMgr:updateSoulFashionDiff(diff.player_soul_fashion) end,
		PLAYER_SOUL_SECRET		= function(diff) playerDataMgr:updateSoulSecretDiff(diff.player_soul_secret) end
 	}

	local func = FUNCTIONS[diff.type]
	if func then
		printInfo("[EventManager] diff type:"..diff.type)
		func(diff)
	else
		printInfo("[EventManager] Unhandled diff data:"..diff.type)
	end
end

return EventManager
