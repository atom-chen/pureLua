local CURRENT_MODULE_NAME = ...

-- classs
local ImageLabel		= import("...fragment.ImageLabel")


local TotalImageLabel = class("TotalImageLabel", ImageLabel)

function TotalImageLabel.create(  )
    return TotalImageLabel.new()
end

function TotalImageLabel.seek( parentNode, nodeName)
    return TotalImageLabel.new({
            parentNode 	= parentNode,
            nodeName	= nodeName,
    })
end

function TotalImageLabel:ctor(params)
	TotalImageLabel.super.ctor(self, params)

    for i=1,5 do
        self:mapUiElement(i)
    end
end

function TotalImageLabel:setString(pos, str)
    self:reset()
    for _,v in ipairs(pos) do
        self[v]:show()
    end

    TotalImageLabel.super.setString(self,str)
end

-- function TotalImageLabel:setString(pos, strings, func)
--     self:reset()
--     for _,v in ipairs(pos) do
--         self[v]:show()
--     end
--
--     TotalImageLabel.super.setString(self,strings, func)
-- end

function TotalImageLabel:reset()
    for i=1,5 do
        self[i]:hide()
    end
end

return TotalImageLabel
