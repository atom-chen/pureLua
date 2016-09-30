local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")

local ServerItem = class("ServerItem",AnimationNode)


function ServerItem.create(param)

	dump(param)
	
	print("次数次数次数次数次数次数")
    
	return ServerItem.new({csbName = "nodes/login/server.csb",data = param})

	
     
end

-- function ServerItem.getSize(param)

-- 	dump(param)
	
-- 	print("次数次数次数次数次数次数")
    
-- 	--return ServerItem.new({csbName = "nodes/login/server.csb",data = param})

-- 	return AnimationNode.new({csbName = "nodes/login/server.csb"})
     
-- end

function ServerItem:ctor(params)
	   -- dump(params.data)

	    ServerItem.super.ctor(self,params)
    	self:enableNodeEvents()

    	self.statesTable = {"正常","火热","推荐","维护"}

        self:mapUiElements({"serverName","stateNode"})

        --self.serverName:setString(params.data.name)
        --print(params.data.name)
        --self.stateNode:runAnimation("green")

end


return ServerItem