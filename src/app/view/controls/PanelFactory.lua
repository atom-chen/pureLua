local CURRENT_MODULE_NAME = ...

-- Panel management
local s_inst = nil
local PanelFactory = class("PanelFactory")


function PanelFactory:getInstance()
	if not s_inst then
		s_inst = PanelFactory.new()
	end
	return s_inst
end

PanelFactory.Panels = table.enumTable({
	"HeroPanel",
	"Hero2Panel",
	"TopPanel",
	"HomePanel",
	"BattlePanel",
	"UIBattlePanel",
	"ResultWinPanel",
	"ResultPanel",
	"DeedPanel",
	"DeedResultPanel",
	"DeedResultTenPanel",
	"SoulsPanel",
	"SoulsDetailPanel",
	"SoulsAdvancePanel",
	"SoulsAdvanceResultPanel",
	"SoulsPeijianPanel",
	"SoulsPeijianListPanel",
	"SoulsUpgradePanel",
	"SmallMapPanel",
	"PrepareFightPanel",
	"BossComePanel",
	"GameMap",
	"PausePanel",
	"LogoPanel",
	"HomeBgPanel",
	"QuestChapterPanel",
	"BagPanel",
	"SceneBgPanel",
	"LoginPanel",
	"EXskillPanel",
	"MessageBoxPanel",
	"QuestTeamPanel1",
	"LoadingPanel",
	"QuestPartPanel",
	"QuestPartGetPanel",
	"QuestPartBoxInfoPanel",
	"MailPanel",
	"StoryScriptPanel",
	"SignPanel",
	"GetPanel",
	"GetMultPanel",
	"BattleScriptPanel",
	"UUPanel",
	"ThemeConsolePanel",
	"RecoveryPanel",
	"EduPanel",
	"SchoolPanel",
	"HelpInfoPanel",
	"BarragePanel",
	"HomeMorePanel",
	"ThemePanel",
	"BarrageBoxPanel",
	"StoryStartPanel"
})

-- 需要gc的Panel，必须在Panel中调用 HomeMorePanel.super.onExit(self, "HomeMorePanel")
PanelFactory.GCPanels = table.enumTable({
	"HomeMorePanel",
	"BattlePanel",
	"DeedPanel",
	"ResultPanel",
	"EduPanel",
	"ThemeConsolePanel",
	"RecoveryPanel",
	"SchoolPanel",
	"QuestTeamPanel1",
	"QuestPartPanel",
	"LoginPanel",
})

do
	local function createHeroPanel( params )
		return import("..panels.HeroPanel",CURRENT_MODULE_NAME).create(params)
	end

	local function createHero2Panel( params )
		return import("..panels.Hero2Panel",CURRENT_MODULE_NAME).create(params)
	end

	local function createTopPanel( params )
		return import("..panels.TopPanel",CURRENT_MODULE_NAME).create(params)
	end

	local function createHomePanel( params )
		return import("..panels.HomePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBattlePanel( params )
		return import("..panels.BattlePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createUIBattlePanel( params )
		return import("..panels.UIBattlePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createResultWinPanel( params )
		return import("..panels.ResultWinPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createResultPanel( params )
		return import("..panels.ResultPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createDeedPanel(params)
		return import("..panels.DeedPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createDeedResultPanel(params)
		return import("..panels.DeedResultPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createDeedResultTenPanel(params)
		return import("..panels.DeedResultTenPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSoulsPanel(params)
		return import("..panels.SoulsPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSoulsDetailPanel(params)
		return import("..panels.SoulsDetailPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSoulsAdvancePanel(params)
		return import("..panels.SoulsAdvancePanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createSoulsAdvanceResultPanel(params)
		return import("..panels.SoulsAdvanceResultPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSoulsPeijianPanel(params)
		return import("..panels.SoulsPeijianPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSoulsPeijianListPanel(params)
		return import("..panels.SoulsPeijianListPanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createSoulsUpgradePanel(params)
		return import("..panels.SoulsUpgradePanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createSmallMapPanel(params)
		return import("..panels.SmallMapPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createPrepareFightPanel(params)
		return import("..panels.PrepareFightPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBossComePanel(params)
		return import("..panels.BossComePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createGameMap(params)
		return import("..battle.GameMap", CURRENT_MODULE_NAME).create(params)
	end

	local function createPausePanel(params)
		return import("..panels.PausePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createLogoPanel(params)
		return import("..panels.LogoPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createHomeBgPanel(params)
		return import("..panels.HomeBgPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createQuestChapterPanel(params)
		return import("..panels.QuestChapterPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBagPanel(params)
		return import("..panels.BagPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSceneBgPanel(params)
		return import("..panels.SceneBgPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createLoginPanel(params)
		return import("..panels.LoginPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createEXskillPanel(params)
		return import("..panels.EXskillPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createMessageBoxPanel(params)
		return import("..panels.MessageBoxPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createQuestTeamPanel1(params)
		return import("..panels.QuestTeamPanel1", CURRENT_MODULE_NAME).create(params)
	end

	local function createLoadingPanel(params)
		return import("..panels.LoadingPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createQuestPartPanel(params)
		return import("..panels.QuestPartPanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createQuestPartGetPanel(params)
		return import("..panels.QuestPartGetPanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createQuestPartBoxInfoPanel(params)
		return import("..panels.QuestPartBoxInfoPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createMailPanel(params)
		return import("..panels.MailPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createStoryScriptPanel(params)
		return import("..panels.StoryScriptPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSignPanel(params)
		return import("..panels.SignPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createGetPanel(params)
		return import("..panels.GetPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createGetMultPanel(params)
		return import("..panels.GetMultPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBattleScriptPanel(params)
		return import("..panels.BattleScriptPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createUUPanel(params)
		return import("..panels.UUPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createThemeConsolePanel(params)
		return import("..panels.ThemeConsolePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createRecoveryPanel(params)
		return import("..panels.RecoveryPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createEduPanel(params)
		return import("..panels.EduPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createSchoolPanel(params)
		return import("..panels.SchoolPanel", CURRENT_MODULE_NAME).create(params)
	end

    local function createHelpInfoPanel(params)
		return import("..panels.HelpInfoPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBarragePanel(params)
		return import("..panels.BarragePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createHomeMorePanel(params)
		return import("..fragment.HomePanelFragment.HomeMorePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createThemePanel(params)
		return import("..panels.ThemePanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createBarrageBoxPanel(params)
		return import("..fragment.HomePanelFragment.BarrageBoxPanel", CURRENT_MODULE_NAME).create(params)
	end

	local function createStoryStartPanel(params)
		return import("..fragment.EduFragment.StoryStartPanel", CURRENT_MODULE_NAME).create(params)
	end

	PanelFactory.Creator = {
		createHeroPanel,
		createHero2Panel,
		createTopPanel,
		createHomePanel,
		createBattlePanel,
		createUIBattlePanel,
		createResultWinPanel,
		createResultPanel,
		createDeedPanel,
		createDeedResultPanel,
		createDeedResultTenPanel,
		createSoulsPanel,
		createSoulsDetailPanel,
		createSoulsAdvancePanel,
		createSoulsAdvanceResultPanel,
		createSoulsPeijianPanel,
		createSoulsPeijianListPanel,
		createSoulsUpgradePanel,
		createSmallMapPanel,
		createPrepareFightPanel,
		createBossComePanel,
		createGameMap,
		createPausePanel,
		createLogoPanel,
		createHomeBgPanel,
		createQuestChapterPanel,
		createBagPanel,
		createSceneBgPanel,
		createLoginPanel,
		createEXskillPanel,
		createMessageBoxPanel,
		createQuestTeamPanel1,
		createLoadingPanel,
		createQuestPartPanel,
		createQuestPartGetPanel,
		createQuestPartBoxInfoPanel,
		createMailPanel,
		createStoryScriptPanel,
		createSignPanel,
		createGetPanel,
		createGetMultPanel,
		createBattleScriptPanel,
		createUUPanel,
		createThemeConsolePanel,
		createRecoveryPanel,
		createEduPanel,
		createSchoolPanel,
		createHelpInfoPanel,
		createBarragePanel,
		createHomeMorePanel,
		createThemePanel,
		createBarrageBoxPanel,
		createStoryStartPanel
  }
end



-- 创建Panel
--
function PanelFactory:createPanel(panel,closedcb,params)
	local creator = PanelFactory.Creator[panel]
	if not creator then
		printError("Can't find creator for panel:"..panel)
		return nil
	else
		cc.Director:getInstance():getTextureCache():removeUnusedTextures()

		local p = creator(params)

		if closedcb then
			p:setClosedCallback(closedcb)
		end
		return p
	end
end


return PanelFactory
