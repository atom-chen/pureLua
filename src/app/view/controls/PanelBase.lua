local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode    = import(".CocostudioNode")
local PanelFactory    = import(".PanelFactory")

local PanelBase = class("PanelBase",AnimationNode)

function PanelBase:setClosedCallback(cb)
	self.cb_onClosed = cb
end

function PanelBase:close(reason)
	self.closedReason = reason
	self:removeFromParent()
end

function PanelBase:onExit(reason)
	PanelBase.super.onExit(self)

	self.closedReason = reason or self.closedReason

	if self.cb_onClosed then
		self.cb_onClosed(self.closedReason)
	end

	if PanelFactory.GCPanels[reason] ~= nil and PanelFactory.GCPanels[reason] > 0 then
		printInfo("func: PanelBase:onExit(reason) exe: girl.gc():"..reason)
		girl.gc()
	end
end

function PanelBase:onEnter()
	PanelBase.super.onEnter(self)
	local frameSize = cc.Director:getInstance():getVisibleSize();
	self:setContentSize(frameSize);
	ccui.Helper:doLayout(self);
end

function PanelBase:reload(  )

end

return PanelBase
