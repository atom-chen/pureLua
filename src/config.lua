
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = true

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1136,
    height = 640,
    autoscale = "FIXED_HEIGHT",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        print("framesize.width:%d framesize.height:%d", framesize.width, framesize.height)
        print("ratio:%d", ratio)
        if ratio <= 1.34 then
            -- iPad 1024*768(2048*1536) is 4:3 screen
            return {autoscale = "FIXED_HEIGHT"}
        elseif ratio == 1.5 then
            -- iphone 4s 960*640
            return {autoscale = "FIXED_HEIGHT"}
        elseif ratio == 1.775 then
            -- iphone 5s 1136*640
            return {autoscale = "FIXED_HEIGHT"}
        elseif ratio > 1.775 then
            -- iphone 6  1334x750
            return {autoscale = "FIXED_HEIGHT"}
        end

    end
}
