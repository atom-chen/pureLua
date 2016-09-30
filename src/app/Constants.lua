cc.exports.girl             = girl or {}

-- 默认字体大小
girl.FONT_SIZE 			    = 22

girl.ZORDER                 = 1024

-- 动画节点监听事件类型
girl.AnimationNodeEventType =
{
	-- 动画开始
    ANIMATION_START 	    = 0,
    -- 动画打断结束
    ANIMATION_END 		    = 1,
    -- 动画正常播放完成
    ANIMATION_COMPLETE 	    = 2,
    -- 帧事件
    ANIMATION_EVENT 	    = 3,
}


girl.MessageLayer           =
{
    -- ui层
    UI                      = 0,
    -- 网络层
    NET                     = 1,
    -- 战斗层
    BATTLE                  = 2,
    --奥义
    EXSKILL                 = 3,

    HOME                    = 4,
}

girl.UiMessage              =
{
   SELLPRICE_CHANGE         = 0,
   HEROEQUIP_UPGRADE        = 1,
   TOP_IN                   = 2, --TopPanel In
   TOP_OUT                  = 3, --TopPanel Out
   USE_PROP                 = 4,
   HOME_CLEAN_UP            = 5, --Home
   SOUL_RELOAD              = 6, --soul card refresh
   CLOTH_SHOP_REFRESH       = 7, --服装店更新
   HOME_BG_REFRESH          = 8, -- 背景层刷新
   HOME_BG_TRY              = 9, -- 背景试用
}


girl.BGM                    =
{
   HOME                     = 5000000,
   UU                       = 5000100,
   BATTLE                   = 5000001, --战姬脱装备声音
   CHAPTER                  = 5000016,

}



girl.UiMusicId              =
{
   BUTTON_CLICK             = 6000004,
   CHAPTER_BGM              = 5000016,
   ASSEMBLE_TAKE_OFF        = 6000039, --战姬脱装备声音
   ASSEMBLE_SUIT_UP         = 6000040, --战姬穿装备声音
   BAG_COUNT_CHANGE         = 6000045, --背包界面出售加减数量
   BAG_CHOOSE               = 6000044, --背包界面勾选声音
   HOME_ATTACK              = 6000000, --主界面点出击按钮声音
   BATTLE_START             = 6000001, --战斗开始
   BOSS_COMING              = 6000002, --BOSS要出现的声音
   CLICK_NORESPONSE         = 6000003, --点击没有响应的声音
   CLICK_BTN                = 6000004, --普通按钮点击声音
   CLICK_WRONG              = 6000005, --点击禁用或者出错声音
   WINDOW_CLOSE             = 6000006, --弹出的窗口关闭声音
   DRAW_GET                 = 6000007, --抽卡界面抽到东西声音
   WINDOW_OPEN              = 6000008, --消息窗口弹出打开声音
   PROGRESS_UP              = 6000009, --进度条上涨的声音
   MISSILE_CROSS            = 6000010, --导弹飞过的声音
   NUMBER_UP                = 6000011, --经验数字上涨的声音
   PAUSE                    = 6000012, --暂停界面弹出时的声音
   BATTLE_LOSE              = 6000013, --战斗失败界面弹出时的声音
   BATTLE_WIN               = 6000014, --战斗胜利界面弹出时的声音
   PAGE_SLIDE               = 6000015, --PAGEVIEW划动到下一页的声音
   EXSKILLSOUND             = 6000016, --奥义UI音效
   EQUIP_UPGRADE            = 6000017, --战姬强化
   EQUIP_CHANGE             = 6000018, --战姬升阶
   EXSKILL_READY            = 6000019, --奥义准备
   TEAM_GOBATTLE            = 6000020, --team界面点击去战斗
   PICK_UP                  = 6000021, --掉落拾取
   BAG_SELL                 = 6000022, --背包界面物品卖出后的音效
   STAR_PUT                 = 6000024, --星星盖上去的音效
   SOUL_ADVANCED            = 6000025, --战姬进阶成功界面音效
   BATTLE_RESULT            = 6000026, --结算界面，过关后的语音配上背景音效
   SOUL_UPGRADE             = 6000027, --战姬强化界面点击一次红色按钮的音效
   SOUL_WASH                = 6000028, --战姬强化界面洗点后的音效
   GATE_NEW                 = 6000029, --关卡选择界面，新关卡出现的音效
   DAY_GET                  = 6000030, --签到界面-左侧礼物IN的音效
   BATH_CLOSEDOOR           = 6000031, --恢复界面-关门的音效
   BATH_OPENDOOR            = 6000032, --恢复界面-开门的音效
   HEROEQUIP_UPGRADE        = 6000033, --主角界面强化成功后的音效
   ITEM_GET                 = 6000034, --通过get弹出界面-获取物品的音效
   INTIMACY_DOWN            = 6000035, --养成界面亲密度下降动画播放音效
   INTIMACY_UP              = 6000036, --养成界面亲密度升级动画播放音效
   BATH_BG                  = 6000037, --恢复界面背景循环泡泡音效
   BATH_DONE                = 6000038, --恢复界面恢复完成播放的提示音效
   BOX_GET                  = 6000041, --关卡选择界面结算界面-宝箱打开音效
   SECRET_LOCK              = 6000042, --养成界面-秘密解锁音效
   THEME_SCREEN             = 6000043, --主题界面-全屏查看音效
   INTIMACY_NUMUP           = 6000046, --养成界面亲密度数字上升的音效
   INTIMACY_NUMDOWN         = 6000047, --养成界面亲密度数字下降的音效
   CURTAIN                  = 6000048, --养成界面换装拉动窗帘的音效
   TOUCH_GIRL               = 6000049, --养成界面抚摸的音效



}

girl.MessageCode            =
{
   -- PASSWORD_ERROR        = 101,
   -- PASSWORD_NOTEQUAL     = 101,
   CHANGE_ASSEMBLAGE        = 601,
   CHANGE_SOULWASH          = 602,
   FUNC_NOTOPEN             = 2101,
   GET_FRAGMENT             = 2102,
}

girl.Message                =
{
   SOULWASH1                = "花费10000金币洗点将使强化次数和所有已强化的效果清空，确认要洗点吗？",
   SOULWASH2                = "所持金币不足10000，无法洗点",
   SOULWASH3                = "当前强化次数为0，不需要洗点",
   PASSWORD_ERROR           = "密码错误",
   PASSWORD_NOTEQUAL        = "密码不一致",
   FUNC_NOTOPEN             = "暂未开放",

}



girl.Price                  =
{
   SOULWASH                 = 10000, --强化洗点
   DRAWONCE                 = 60, --单抽价格
   DRAWTENCE                = 600, --十连抽价格
}

girl.BagItemType            =
{
   PROP                     = "props",
   MATERIAL                 = "materials",
   ASSEMBLAGE               = "assemblages",
}


girl.BattleMessage          =
{
    SKILL_ADD               = 0,
    BUFF_ADD                = 1,
    BULLET_ADD              = 2,
    SHAKE_ADD               = 3,
    BOSSCOMING_ADD          = 4,
    BATTLE_RUNAI            = 5,
    SCALE_CAMERA            = 6, --放大摄相机
    ADD_WARNING             = 7,
    CLOSE_EXSKILL           = 8, --关闭奥义
    SHOW_MONSTER            = 9, --奥义出怪
    DMG_MONSTER             = 10,
    ADD_FRONT_EFF           = 11, --奥义前景特效
    ADD_BG_EFF              = 12, --奥义背景特效
    SET_LAYER_FOR_MONSTER   = 13,
    ADD_COMBO               = 14, --加combo
    ADD_DROP                = 15, --加掉落处理
    PROCESS_BOSS            = 16, --处理boss
    ADD_MONSTER             = 17, --加怪
    REMOVE_MONSTER          = 18,--移除怪物
    ADD_HP_EFF              = 19, --主角加血特效
}
