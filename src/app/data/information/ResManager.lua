

local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoManager 	= import(".InfoManager", CURRENT_MODULE_NAME):getInstance()

--
-- ResManager
--
local ResManager = class("ResManager")
local s_database = nil

function ResManager:getInstance()
	if nil == s_database then
		s_database = ResManager.new()
	end
	return s_database
end

function ResManager:ctor()
	self.caches = infoManager:findInfo("ress")
end

function ResManager:findInfo(class_id)
	for k,v in pairs(self.caches) do
		if v.class_id == class_id then
			return v
		end
	end
	girl.MsgBox("找不到资源->"..class_id, 2)
	return nil
end

function ResManager:getResPath( class_id )
	for k,v in pairs(self.caches) do
		if v.class_id == class_id then
			return v.name,v.plistName
		end
	end

	printInfo("[RES] NULL get classId path:", class_id)
	girl.MsgBox("找不到Res资源->"..class_id, 2)
	return nil
end

local test = {
	SOUL_FACE = {

	}
}


ResManager.IconType = {
	SOUL_ORIGIN     = {path = "sundry/textures/icon/soul/#/girl#.png"}, ---1
	SOUL_CARD       = {path = "sundry/textures/icon/soul/#/girlCardL#.png",plist = "sundry/plist/girlCardL%s.plist",param = {"3_29"}},
	SOUL_HEAD       = {path = "sundry/textures/icon/soul/#/girlHead#.png"},
	SOUL_BANNER     = {path = "sundry/textures/icon/soul/#/girlsBanner#.png",plist = "sundry/plist/girlBanner%s.plist",param = {"3_29"}},
	SOUL_SKILL      = {path = "sundry/textures/icon/soul/#/skillName#.png",plist = "sundry/plist/skillName%s.plist",param = {"3_29"}},
	CHAPTER     	= {path = "sundry/textures/icon/chapter/questChapter/chapter#.png",plist = "sundry/plist/questChapter.plist"},
	CHAPTER_PART    = {path = "sundry/textures/icon/chapter/questMap/chapterMap#_!.png"}, ---1
	THEME_VIEW      = {path = "sundry/textures/icon/theme/view/view#.png"},
	THEME_USE       = {path = "sundry/textures/icon/theme/Use/use#.png"},
	THEME_USE_FUCK  = {path = "sundry/textures/icon/theme/Use/use#_!.png"},
	SOUL_FACE       = {path = "sundry/textures/icon/soul/#/face/f!.exp.png",plist = "sundry/plist/face%s.plist",param = {"3-5","6-7","8-10","24-29","0"}},
	ME_NPC_FACE 	= {path = "textures/ui/talk/#.png",plist = "textures/plist/ui/talk_battle.plist"},
	SOUL_Q          = {path = "sundry/textures/icon/soul/#/girlQ#.png",plist = "sundry/plist/q%s.plist",param = {"3_29"}},
	SOUL_CLOTH 	    = {path = "sundry/textures/icon/soul/#/cloth/!.png"},
	GOLD            = {path = "sundry/textures/icon/prop/icon_coin.png"},
	DIMOND 	        = {path = "sundry/textures/icon/prop/icon_crystal.png"},
	PAPAPA 	        = {path = "script/papapa/#.lua"},
	SIGN_7_DAY 		= {path = "script/qiandao/#.lua"},
	SOUL_NAME 		= {path = "sundry/textures/icon/soul/#/name#.png",plist = "sundry/plist/name3_29.plist",param = {"3_29"}},
	BOSS_HEAD 		= {path = "sundry/textures/icon/boss/bossHead/bossHead#.png",plist = "sundry/plist/bosshead.plist"},
	BOSS_HP 		= {path = "textures/ui/Battle/jdt_bossHp#.png",plist = "textures/plist/ui/battle.plist"},
	HELP 			= {path = "sundry/textures/help/about#.png"}, --1
	SHADOW 			= {path = "textures/ui/Battle/shadow.png",plist = "textures/plist/ui/battle.plist"},
}


function ResManager:getIconPath(iconType, ...)
	if not iconType then
		return
	end
	local p = {...}
	local s = iconType.path
	if iconType.plist then

		local plistPath = iconType.plist
		if  iconType.param then
			local  function calc(id)

				-- dump(iconType.param)
				for _,v in ipairs(iconType.param) do

					local nums = string.split(v,"_") -- '_':代表 3_29
					-- dump(nums)
					if #nums > 1 then
						-- dump(nums)
						-- print(" =====================id:"..id)
						if id >= tonumber(nums[1])  and  id <= tonumber(nums[2]) then
							return v
						end
					end
					local nums = string.split(v,"-") -- '_':代表 3|29|x ...
					-- dump(nums)
					for _,vv in ipairs(nums) do
						if id == tonumber(vv) then
							return v
						end
					end
				end
				print("--param Err: getIconPath --")
			end
			plistPath = string.format(plistPath,calc(p[1]))
		end
		-- dump(plistPath)
		cc.SpriteFrameCache:getInstance():addSpriteFrames(plistPath)
	end

	if p[1] then
		s = string.gsub(s, "#", tostring(p[1]))
	end

	if p[2] then
		s = string.gsub(s, "!", tostring(p[2]))
	end

	-- dump(s)
	return s
end

--[[
    1、道具(porp)
    2、元神(soul)
    3、金币
    4、钻石
    5、装备(equipment)
    6、主角(hero)
    7、配件(assmblage)
    8、碎片(null)
    9、材料(material)
    10、好感度
    11、礼物(developPorp)
]]
function ResManager:getItemData(pb)
	-- dump(pb)
	if pb.type == "PROP" then
	    local info = infoManager:findInfo("props","class_id",pb.class_id)
	    pb.path = self:getResPath(info.resId)
	    pb.quality = info.quality
	    pb.name = info.name
	elseif pb.type == "SOUL" then
	    print("SOUL")
	    local info = infoManager:findInfo("souls","class_id",pb.class_id)
	    pb.path    = self:getIconPath(self.IconType.SOUL_HEAD,pb.class_id)
		-- 注意：魂从1开始，动画从0开始
	    pb.quality = info.star - 1
	    pb.name = info.name
	elseif pb.type == "GOLD" then
	    pb.path = self:getIconPath(self.IconType.GOLD)
	    pb.quality = -1
	    pb.name = Strings.GOLD
	elseif pb.type == "DIMOND" then
	    pb.path = self:getIconPath(self.IconType.DIMOND)
	    pb.quality = -1
	    pb.name = Strings.DIMOND
	elseif pb.type == "EQUIP" then
	    print("EQUIP")
	elseif pb.type == "HERO" then
	    print("HERO")
	elseif pb.type == "ASSEMBLAGE" then
	    local info = infoManager:findInfo("assemblages","class_id",pb.class_id)
	    pb.path = self:getResPath(info.resId)
	    pb.quality = info.quality
	    pb.name = info.name
	elseif pb.type == "FRAGMENT" then
	    print("FRAGMENT")
	elseif pb.type == "MATERIAL" then
	    local info = infoManager:findInfo("materials", "class_id",pb.class_id)
	    pb.path = self:getResPath(info.resId)
	    pb.quality = info.quality

	elseif pb.type == "DECORATION" then
	    print("DECORATION")
	end
	return pb
end


return ResManager
