-- grid view
local GridCell = class("GridCell",function()
	return cc.TableViewCell:new()
end)

-- 边距
GridCell.margin = 10
-- 间距
GridCell.space = 20




local function _calcCellSize(viewSize,itemSize,dir,count)
	local size = cc.size(itemSize.width,itemSize.height)
	local fixedLen = (GridCell.margin * 2) + (GridCell.space * (count - 1))
	if cc.SCROLLVIEW_DIRECTION_VERTICAL == dir then
		size.width = math.max(viewSize.width,(size.width * count) + fixedLen)
	else
		size.height = math.max(viewSize.height,(size.height * count) + fixedLen)
	end
	return size
end

local function _calcItemIndex(cellIndex,numItemsPerCell)
	return cellIndex * numItemsPerCell + 1
end


-- params
-- params.count
-- params.Item  class of item
-- params.viewSize viewsize
-- params.direction direction of table view
-- params.cb_onGetItemSize:
-- params.margin
-- params.space
-- params.index
-- params.autoLayoutCell
function GridCell:ctor(params)
	self.items = { }
	local Item   = params.Item
	local dir    = params.direction or cc.SCROLLVIEW_DIRECTION_HORIZONTAL
	local margin = params.margin or GridCell.margin
	local space  = params.space or GridCell.space
	local x,y    = margin,margin
	local layout = params.autoLayoutCell or false
	local itemSize


	self:setIdx(params.index)

	local itemSpace
	local function calcSpace()
		assert(itemSize)

		if not layout then
		 	if cc.SCROLLVIEW_DIRECTION_VERTICAL == dir then
		 		return space + itemSize.width
		 	else
		 		return space + itemSize.height
		 	end
		else
			if cc.SCROLLVIEW_DIRECTION_VERTICAL == dir then
				return (params.viewSize.width - (margin * 2)) / params.count
			else
				return (params.viewSize.height - (margin * 2)) / params.count
			end
		end
	end

	-- 适应平均分布后起始位置的偏移，需要在获取itemSize后才能够计算
	local offset
	local function calcOffset()
		assert(itemSize and itemSpace)
        -- dump(itemSize)
        -- dump(itemSpace)

		local itemLen
		if cc.SCROLLVIEW_DIRECTION_VERTICAL == dir then
			itemLen = itemSize.width
		else
			itemLen = itemSize.height
		end

		if itemSpace > itemLen then
			return (itemSpace - itemLen) / 2
		end

		return 0
	end

	for i=1,params.count do
		local item = Item.create():addTo(self)

		if not itemSize then
			if params.cb_onGetItemSize then
				itemSize = params.cb_onGetItemSize(params.index) -- 只计算第一个
			else
				local bbox = item:getCascadeBoundingBox()
				itemSize = cc.size(bbox.width,bbox.height)
			end
		end

		-- 计算锚点
		local anchorX,anchorY = 0,0
		if layout then
			anchorX = itemSize.width * 0.5
			anchorY = itemSize.height * 0.5
		end

		-- --add by Jason
		-- local rt = self:getCascadeBoundingBox()
		-- girl.createTestRect(rt):addTo(item,10000)
  --       --end by Jason

		itemSpace = itemSpace or calcSpace()
		offset = offset or calcOffset()
		if cc.SCROLLVIEW_DIRECTION_VERTICAL == dir then
			item:setPosition(x + anchorX + offset,y + anchorY)
			x = x + itemSpace
		else
			item:setPosition(x + anchorX,y + anchorY + offset)
			y = y + itemSpace
		end

		item:setContentSize(itemSize)
		item:setVisible(false)
		--self.items[i] = item

		table.insert(self.items,item)
	end
	self:setContentSize(_calcCellSize(params.viewSize,itemSize,dir,params.count))
end

function GridCell:reset()

	local function deepCallCheckAnimationNode( node )
		local childs = node:getChildren()
		if childs then
			for _,v in pairs(childs) do
				deepCallCheckAnimationNode(v)
			end
		end
		if node.checkAnimationNode then
			node:checkAnimationNode()
		end
	end

	for _,v in ipairs(self.items) do
		deepCallCheckAnimationNode(v)
		-- v:onEnter()  -- 先调用onEnter用来创建timeline
		v:setVisible(false)
	end
end

function GridCell:itemAtIndex(index)
	return self.items[index]
end

function GridCell:touchedItem(loc)
	for i,v in pairs(self.items) do
		if not v:isVisible() then
			break;
		end

		local pos = v:convertToNodeSpace(loc)
		local cs = v:getContentSize()
		if cc.rectContainsPoint(cc.rect(-cs.width * 0.5,-cs.height * 0.5,cs.width,cs.height),pos) then
			return v,_calcItemIndex(self:getIdx(),#self.items) + (i - 1)
		end
	end
	return nil,0
end


local GridView = class("GridView",function()
	return display.newLayer() --{ r = 128, g = 128, b = 128,a = 180 })
end)


-- params.rect: = rectangle
-- params.direction: cc.SCROLLVIEW_DIRECTION_VERTICAL or cc.SCROLLVIEW_DIRECTION_HORIZONTAL
-- params.numItems: Number of items per cell
-- params.Item: Item Class
-- params.margin
-- params.space
-- params.autoLayoutCell: 自动布局cell, 默认true
-- params.cb_onCellTouched
-- params.cb_onNumCells
-- params.cb_onAddItem
-- params.cb_onGetItemSize
function GridView:ctor(params)
	self:enableNodeEvents()

	local rect = params.rect
	local dir = params.direction or cc.SCROLLVIEW_DIRECTION_VERTICAL

	local numItems = params.numItems or 1

	self:setPosition(rect.x,rect.y)
	local contentSize = cc.size(rect.width,rect.height)
	self:setContentSize(contentSize)

	local tableview = cc.TableView:create(contentSize)
	tableview:setDirection(dir)
	tableview:setDelegate()
	tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	self:addChild(tableview)

	girl.addTouchEventListener(tableview,{
        onBegan = function(touch,event)
            self.touchedLoc = touch:getLocation()
        end
    })

	local function onTouched(table,cell)
		local item,index = cell:touchedItem(self.touchedLoc)
		-- print("touch")
		if item and params.cb_onCellTouched and index ~= 0 then
			params.cb_onCellTouched(item,index)
		end
	end

	tableview:registerScriptHandler(function ( table )
		local count = 0
		count = params.cb_onNumCells()
		return math.ceil(count / numItems)
    end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)

	-- registe event
	tableview:registerScriptHandler(function(table,cell)
		onTouched(table,cell)
	end,cc.TABLECELL_TOUCHED)

	local function calcCellSize(idx)
		local size
		if params.cb_onGetItemSize then
			size = params.cb_onGetItemSize(idx)
		else
			local bbox = params.Item.create():getCascadeBoundingBox()
			size = cc.size(bbox.width,bbox.height)
		end
		return _calcCellSize(contentSize,size,dir,numItems)
	end

	local cellSize
	tableview:registerScriptHandler(function ( table, idx )
		cellSize = cellSize or calcCellSize(_calcItemIndex(idx,numItems))
		return cellSize.height,cellSize.width
	end,cc.TABLECELL_SIZE_FOR_INDEX)

	local cellParams = {
		count            = numItems,
		Item             = params.Item,
		direction        = dir,
		viewSize         = contentSize,
		margin           = params.margin,
		space            = params.space,
		autoLayoutCell 	 = params.autoLayoutCell,
		cb_onGetItemSize = params.cb_onGetItemSize
	}
	tableview:registerScriptHandler(function ( table, idx )
		local cell = table:dequeueCell()
		if not cell then
			cellParams.index = idx + 1
			cell = GridCell.new(cellParams)
		else
			cell:reset()
			cell:setIdx(idx + 1)
		end
		-- update it
		local count = params.cb_onNumCells()
		local beginIndex = _calcItemIndex(idx,numItems) -- always start from 1
		local endIndex = math.min(count,beginIndex + numItems - 1)
		local itemIndex = 1
		for i=beginIndex,endIndex do
			local item = cell:itemAtIndex(itemIndex)
			params.cb_onAddItem(item,i)
			item:setVisible(true)
			itemIndex = itemIndex + 1
		end
		return cell
	end,cc.TABLECELL_SIZE_AT_INDEX)

	self.tableView= tableview
	self.numItems = numItems
end

function GridView:onEnter()
	self:reload()
end

function GridView:reload(  )
	self.tableView:reloadData()
end

function GridView:setBounceEnabled( enabled )
	self.tableView:setBounceable(enabled)
end

function GridView:itemAtIndex( index )
	local cellIndex = math.ceil(index / self.numItems)
	local cell = self.tableView:cellAtIndex(cellIndex - 1)

	if cell then
		local itemIndex = math.mod(index,self.numItems)
		if itemIndex == 0 then
			itemIndex = self.numItems
		end
		return cell:itemAtIndex(itemIndex)
	end
	return nil
end

return GridView
