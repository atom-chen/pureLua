local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode    = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase        = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GirlsCardNode    = import("..fragment.GirlsCardNode",CURRENT_MODULE_NAME)

local GridView         = import("..controls.GridView", CURRENT_MODULE_NAME)
local SoulAssembleNode = import("..fragment.SoulAssembleNode", CURRENT_MODULE_NAME)

-- singleton
local infoManager      = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory     = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager     = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws               = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder        = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr        = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()

local SoulsPeijianListPanel = class("SoulsPeijianListPanel", PanelBase)

function SoulsPeijianListPanel.create(params)
  return SoulsPeijianListPanel.new({ csbName = "layers/girls/GirlsPeijianList.csb",order = params.order,id = params.id,idTable = params.idTable })
end


function SoulsPeijianListPanel:ctor(params)
  SoulsPeijianListPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"Panel_1","Button_6"})
  self.order = params.order
  self.id =  params.id
  print("self.order:",self.order)

  --dump(playerMgr.souls[self.id])
  self.idTable =  params.idTable

  dump(playerMgr.assemblages)
  self.num = {}
  for k,v in girl.pairsByKeys(playerMgr.assemblages) do
       table.insert(self.num,k)
  end

end


function SoulsPeijianListPanel:onEnter()

  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  SoulsPeijianListPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  self:runAnimation("in", false)

  self.Button_6:onClicked(function()
      musicManager:play(girl.UiMusicId.BUTTON_CLICK)

      self:runAnimation("out", false, function()
            self:close()
       end)


  end)




  local size =  self.Panel_1:getCascadeBoundingBox()
               -- dump(size)
                if nil == self.gridView then

                  self.gridView = GridView:create({
                    rect             = cc.rect(0,0,size.width,size.height),
                    numItems         = 2,
                    Item             = SoulAssembleNode,
                    direction        = cc.SCROLLVIEW_DIRECTION_HORIZONTAL,
                    -- space            = 0,
                    margin           = 0,
                    autoLayoutCell   = true,
                    cb_onCellTouched = function(item,idx) self:onCellTouched(item,idx) end,
                    cb_onNumCells    = function(cell) return #self.num end,--return #playerMgr.servers end,
                    cb_onAddItem     = function(item,idx) self:onAddItem(item,idx) end
                    -- cellData         = playerMgr.servers
                  })
                  :addTo(self.Panel_1,200)


                end

    -- dump(self.gridView.tableView)
    -- dump(self.gridView.numItems)

    -- local x = #playerMgr.assemblages

    -- print(math.fmod(x,2))

    -- for i=1,x do
    --    self["info"..i] = infoManager:findInfo("assemblages","class_id",playerMgr.assemblages[self.num[i]].class_id)
    --    print(self["info"..i].quality)
    -- end


    -- for i=1,math.floor(x/2) do
    --     if i == math.floor(x/2) then
    --         if math.fmod(x,2) ==0 then
    --            print(i)
    --            self.gridView.tableView:cellAtIndex(i):itemAtIndex(2).equipNode:runAnimation(self["info"..2*i].quality)
    --            self.gridView.tableView:cellAtIndex(i):itemAtIndex(1).equipNode:runAnimation(self["info"..2*i-1].quality)
    --         else
    --            self.gridView.tableView:cellAtIndex(i):itemAtIndex(1).equipNode:runAnimation(self["info"..2*i-1].quality)
    --         end
    --     else
    --        print(i)
    --        self.gridView.tableView:cellAtIndex(i):itemAtIndex(2).equipNode:runAnimation(self["info"..2*i].quality)
    --        self.gridView.tableView:cellAtIndex(i):itemAtIndex(1).equipNode:runAnimation(self["info"..2*i-1].quality)
    --     end
    -- end

    -- dump(self.gridView.tableView:cellAtIndex(1):itemAtIndex(1))

    -- for i=1,10 do
    --    self.gridView.tableView:getChildByTag(i).equipNode:runAnimation("2")
    -- end




end

function SoulsPeijianListPanel:changeAssemblage(idx)

   print("do change")

end

function SoulsPeijianListPanel:onCellTouched(item,idx)
   print(idx)
   local function onPanelClosed(reason)
      if reason =="yes" then
        self.idTable[self.order] = self.num[idx]
        local pb = pbBuilder:build({
        proto = "data/pb/interface/assemblagesChange.pb",
        desc  = "interface.assemblagesChange.Request",
        input = { soul_id = self.id ,id = self.idTable}
        })

        ws:send( "ASSEMBLAGESCHANGE", pb, function(resultCode, des)
             print("ASSEMBLAGESCHANGE:", resultCode,des)
             if resultCode == 0 then
                self:runAnimation("out",false,function()
                  self:getParent():changeAssemblage(self.order,self.num[idx])
                  -- print("yes")
                  musicManager:play(girl.UiMusicId.ASSEMBLE_SUIT_UP)
                  self:close()
                end)
             end
        end)
      end
    end
  dump(playerMgr.assemblages[self.num[idx]])
  if playerMgr.assemblages[self.num[idx]].soul_id == 0 then
     self:getParent():changeAssemblage(self.order,self.num[idx])
     self.idTable[self.order] = self.num[idx]
     dump(self.idTable[self.order])
       local pb = pbBuilder:build({
        proto = "data/pb/interface/assemblagesChange.pb",
        desc  = "interface.assemblagesChange.Request",
        input = { soul_id = self.id ,id = self.idTable}
        })

        ws:send( "ASSEMBLAGESCHANGE", pb, function(resultCode, des)
             print("ASSEMBLAGESCHANGE:", resultCode,des)
             if resultCode == 0 then
                 self:runAnimation("out",false,function()
                   musicManager:play(girl.UiMusicId.ASSEMBLE_SUIT_UP)
                   self:close()
                 end)
             end
        end)

      -- self:runAnimation("out",false,function()
      --        self:close()
      -- end)
  else
    if playerMgr.assemblages[self.num[idx]].soul_id == self.id then
       print("已装备")
       return
    else
      local curSoulName = playerMgr.souls[playerMgr.assemblages[self.num[idx]].soul_id].info.name
      local tarSoulName = playerMgr.souls[self.id].info.name
      local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,onPanelClosed,
                      {message = "该配件已装备在"..curSoulName.."身上,要解除并安装在"..tarSoulName.."身上吗？",
                      code = girl.MessageCode.CHANGE_ASSEMBLAGE})
                      :addTo(self,100)
    end

  end


end

function SoulsPeijianListPanel:onAddItem(item,idx)
    --列表里的banner不需要显示减号
    --item.removeButton:setVisible(false)
    --item.ProjectNode_3:setVisible(false)



    -- item:runAnimation("usedin",false)
    -- item.equipNameText:setString("测试")
    -- item.equipNode:runAnimation("2")

    --3个参数分别为装备的class id ，装备在表里的序号，元魂的id
    --item:setTag(idx)
    item:initSelf(playerMgr.assemblages[self.num[idx]].class_id,idx,self.id)


end



return SoulsPeijianListPanel
