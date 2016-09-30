local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local resMgr = import("...data.information.ResManager"):getInstance()

local MusicManager = class("Music")

local s_music = nil
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

function MusicManager:getInstance()
  if nil == s_music then
    s_music = MusicManager.new()
    -- 一开始加资源
    s_music:preload()
  end
  return s_music
end

function MusicManager:ctor()
    
end

function MusicManager:preload()
  for k,v in pairs(resMgr.caches) do
    if v.type == 3 then
      audio.preloadSound( v.name )
    elseif v.type == 5 then
      audio.preloadMusic( v.name )
    end
  end
end

function MusicManager:play(id, isLoop )

  local info = resMgr:findInfo(id)
  if not info then
    printInfo("Music Manager can't find id:"..id)
    return
  end

  if info.type == 3 then
    audio.playSound(info.name, isLoop or false)
  elseif info.type == 5 then
    audio.playMusic( info.name, isLoop or true )
  else
    printInfo("Music Manager can't play")
  end
end

function MusicManager:playEx(name,isLoop)
  audio.playSound(name, isLoop or false)
end

function MusicManager:resume(  )
  audio.resumeMusic()
end

function MusicManager:stopAll(isReleaseData)
  audio.stopAllSounds()
  audio.stopMusic(isReleaseData or false)
end

function MusicManager:setEffectsVolume(volume)
  audio.setSoundsVolume(volume)
end

function MusicManager:setMusicVolume(volume)
  print("MusicManager",volume)
  audio.setMusicVolume(volume)
end

function MusicManager:getEffectsVolume()
   return audio.getSoundsVolume()
end

function MusicManager:getMusicVolume()
   return audio.getMusicVolume()
end




return MusicManager
