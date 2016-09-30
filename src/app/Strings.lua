
cc.exports.Strings = Strings or { }


Strings.CONNECT_ERROR                    = "连接错误"
Strings.CHECKING_VERSION                 = "正在检查版本"
Strings.LOGINING_ACCOUNT                 = "正在登录"
Strings.ENTERING_GAME                    = "正在登录"
Strings.SAVING_FORMATION	             = "正在保存"
Strings.LOADING 			             = "载入中"
Strings.CONFIRM                          = "确定"
Strings.CANCEL                           = "取消"
Strings.RETRY                            = "重试"
Strings.RESET                            = "重置"
Strings.DATE				             = "%d年%02d月%02d日 %02d时%02d分"
Strings.SUCCESS 			             = "成功"
Strings.ENERGY 				             = "精力不足"
Strings.UPDATE_CHECK 				     = "热更新检查版本"
Strings.UPDATE_CONFIG 				     = "热更新检查配置"
Strings.UPDATE_DOWNLOAD 				 = "热更新下载"
Strings.BARRAGE_INPUT 					 = "亲，请输入弹幕"
Strings.NULL_PANEL 					 	 = "亲，功能暂未开放，请耐心等待"
Strings.GOLD 						 	 = "金币"
Strings.DIMOND 							 = "钻石"

-- 前缀文字
do
	local Prefix   				= Prefix or { }
	Prefix.RANKING 				= "排名: "


	Strings.Prefix = Prefix
end

-- 服务器错误码
Strings.RESULTCODE={
	["0"]="成功",
	["1"]="系统错误",
	["2"]="数据库错误",
	["3"]="参数错误",
	["4"]="数据不存在",
	["5"]="session 超时",
	["6"]="静态数据不同步",
	--用户注册登录  100-199
	["100"]="玩家已经从其他设备登陆",
	["101"]="玩家密码错误",
	["102"]="session 超时，请重新登陆",
	["103"]="玩家已经注册",
	["104"]="玩家没有注册",
	["105"]="服务器人数已满",
	--用户购买商店 200-299
	["200"]="金钱不足",
	["201"]="玩家砖石不足",
	["202"]="玩家item数量不足",
	--关卡 300-399
	["301"]="战机体力不足，点击校园->Spa进行恢复",
	["302"]="关卡次数不够",
	--章节奖励领取 400-499
	["400"]="奖励已经领取",
	["401"]="领取条件不足",
	--邮件领取 500-510
	["500"]="邮件实效",
	--元魂/主角 600-699
	["600"]="元魂碎片不足",
	["601"]="进阶已满",
	["602"]="进阶材料不足",
	["603"]="强化次数达上限",
	["604"]="强化材料不足",
	["605"]="主角等级不足",
	["606"]="主角强化次数已满",
	["607"]="扩建材料不足",
	["608"]="材料不足",
	--活动 700-799
	["700"]="奖励已经领过",
	["701"]="奖励不能领取",
	--养成 800-899
	["800"]="时装已经购买",
	["801"]="礼物不足",
	["802"]="服装不存在",
	["803"]="礼物不存在",
	["804"]="送礼物次数不足",
	--特例
	["10000"]="剧情关卡的结果已经完成过"
}
