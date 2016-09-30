local CURRENT_MODULE_NAME = ...


local EditBoxNode  = class("EditBoxNode", function(param)
    local EditBoxNode = nil
    local params      = param or {}
    local size        = params.size or cc.size(240, 32)
    -- EditBoxNode       = ccui.EditBox:create(size, "textures/ui/common/bd_grilsNum.png")
    EditBoxNode       = ccui.EditBox:create(size, "textures/ui/common/kong.png")
    return EditBoxNode
end)

function EditBoxNode.create(params)
    return EditBoxNode.new(params)
end

function EditBoxNode:ctor(param)
    self:enableNodeEvents()
    local params = param or {}
    local size = params.size or cc.size(240, 32)
    local cb = params.cb
    local fontSize = params.fontSize or 20
    local maxLength = params.maxLength or 20
    local fontColor = params.fontColor or cc.c3b(255,255,255)
    local inputMode = params.inputMode or cc.EDITBOX_INPUT_MODE_SINGLELINE
    local defaultText = params.defaultText or "请输入用户名"

    local function editBoxTextEventHandle(event, sender)
        -- local edit = pSender
        -- local strFmt
        -- if strEventName == "began" then
        --     strFmt = string.format("editBox %p DidBegin !", edit)
        --     print(strFmt)
        -- elseif strEventName == "ended" thensfdshajk
        --     strFmt = string.format("editBox %p DidEnd !", edit)
        --     print(strFmt)
        -- elseif strEventName == "return" then
        --     strFmt = string.format("editBox %p return !", edit)
        --     print(strFmt)
        -- elseif strEventName == "changed" then
        --     strFmt = string.format("editBox %p TextChanged, text: %s ", edit, edit:getText())
        --     print(strFmt)
        -- end
        -- if event == "return" and callfunc then
            if cb then cb(self:getText()) end
        -- end
    end

-- ccui.EditBox:create(size, "textures/ui/common/bd_grilsNum.png"):addTo(self)
-- ccui.EditBox:create(size, "textures/ui/common/kong.png"):addTo(self)

    self:setFontName("fonts/STHeiti-Medium_1.ttf")
    self:setPlaceholderFontName("fonts/STHeiti-Medium_1.ttf")

    self:setFontSize(fontSize)
    self:setPlaceholderFontSize(fontSize)

    self:setFontColor(fontColor)
    self:setPlaceholderFontColor(fontColor)

    self:setPlaceHolder(defaultText)
    self:setMaxLength(maxLength)
    self:setInputMode(inputMode)
    self:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

    self:registerScriptEditBoxHandler(editBoxTextEventHandle)
    self:setAnchorPoint(0,0)
end

return EditBoxNode
