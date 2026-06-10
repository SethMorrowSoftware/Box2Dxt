-- =====================================================================
-- box2dxt-platformer.livecodescript  ·  Game Kit Phases 1+2+4 showcase
--
-- A short, polished SCROLLING platformer level (3072px world in a 1024px
-- viewport) that exercises most of the engine: keyboard input with edge
-- detection, atlas spritesheets with named animations and scaling, the
-- camera (follow + deadzone + bounds + shake), one-way bridge chains, a
-- spike pit, a pressure plate + crate puzzle driving a kinematic gate, a
-- patrolling stompable slime, a saw hazard with a hit-pose respawn chain,
-- spinning coins, and a goal flag. Anything without sheet art falls back
-- to plain graphics, so the level runs even with no asset folder.
--
-- HOW TO RUN
--   1. In OXT, make a new stack. Put this whole file into the STACK script.
--   2. Make sure the box2dxt extension is loaded. Close and reopen.
--   3. First run asks for the repo's Spritesheets folder (remembered in a
--      stack property; Shift+Reset re-asks; Cancel = placeholder shapes).
--
-- CONTROLS  arrows or A/D run · SPACE / UP / W jumps (tap = hop, hold =
--           full) · drag bodies with the mouse (the crate!)
--
-- THE ROUTE  jump up through the bridge planks; clear the SPIKE PIT; drag
--           or push the CRATE onto the gold PRESSURE PLATE so the red
--           gate stays open; slip past the saw; stomp (or avoid) the
--           slime; climb the platforms and touch the FLAG.
--
-- WHAT TO VERIFY (the scrolling-level OXT pass)
--   1. The view scrolls smoothly after the hero, easing to a stop; it
--      never shows past the level's left/right ends.
--   2. The hills backdrop does NOT scroll (far parallax); tiles do.
--   3. Mouse-dragging works mid-level (grab is camera-corrected).
--   4. The pit spikes hurt; the camera SHAKES on every hurt.
--   5. Standing on the plate opens the gate, leaving closes it; the
--      crate parked on the plate holds it open for good.
--   6. The slime patrols and turns; landing on top squashes it flat
--      (and bounces you); touching its side hurts.
--   7. Coins, saw, bridge, flag and hit-respawn all behave as before.
--   8. Reset and stack-reopen leave no ghosts; ms/frame stays ~16-18.
-- =====================================================================

local gStarted, gHero, gHeroSpr, gHudLast, gHurtLock
local gCoins, gCoinsTotal, gAssetsOK, gBeeSpr, gLoadNote, gWon
local gGate, gGateSprA, gGateSprB, gPlateCount, gPlateLook, gCamOK
local gSlime, gSlimeSpr, gSlimeDir, gSlimeGoneAt

constant kMoveSpeed = 280
constant kJumpSpeed = 430
constant kPfUIVersion = "3"
constant kLevelW = 3072
constant kHeroSheetB64 = "iVBORw0KGgoAAAANSUhEUgAAAYAAAAEACAYAAAC6d6FnAAAI/ElEQVR42u3dPVLjShgFUJlyxCJwTOqVQEDORojYCDkBrMSpY7EIUl4knixjj9vqH7V0TtVUYaZLvhZPffUZ3tA0AAAAAAAAAAAAAAAAAAAAAAAAAABAHquxB3h7ufsZe4zn16+VLwVAJQUQY+OfQhEosLKcf6ioAIYX7NPDdnSI989d9gtagdWfWxFAxgLoX7QxNv5zRZDqYlZgZTfQuZx/WFQBpN78c5SAAiu7gc7h/MPiCiDX5p/yQlZg886uBCDcTcjiHJt/iufJWWD948d8mybHa6g5e+rXAIssgO4iyrX5Dy/kmBexAiu7gdZ6/sEEUCkFVvZ55nT+YVEFUOridRHbQAETQJWbp03U+QcFgA0UmKx1rAPdbj8OHn/vHqOuB2CCBTDczLvPndrUQ9fnoMDKcv6hwgIYXoibzf3vx227P7owQ9eX2HwUmPMPS3AT88Ltb+bd4/6a0PUlNp/N5v73z6mNJmR9yQ001nrnHxTA7N92UGAfzj8oABQYoAAAUABDw2+6te3+6HF/Teh6ACY8Afy1qXd//trMQ9enpMDKcv6h8gL468I89blr1+fehBSY8w9LsE51Icden3oTCvm5+ND1ObP3N/VTG2jIeucfFMDi3o5QYM4/KAAUGDBLfgwUQAEAoAAAUAAAKAAAFAAACgAABQCAAgBAAQCgAACoowCeX79WTdM075+7IuG65+1yhJJf/jH5wQQAwDILoNRdXKy7N/nld5lDhAkg10Wc6nnklx8ILID+XVTqi6t//Fh3b/LLD4yYAHJcxCkvXvnlBw4FXyRvL3c/5/7+6WE7ekRPefHKLz9wZQFcchHHulMstQnJLz8sgR8DBVio6L8U/pI7sJR3gPLLD5gAAFAAACgAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAksop5sBi/q/WS3wmbivzyyy//kvKvphK85BdCfvnll3+J+Vcxgz89bEcHf//cZftCyC+//PIvOf8qRvgYwc+9kBRfBPnll1/+pee/mWL44XFjj0jyyy+//PJfUQA5wqf8Isgvv/zyyz9iAsgRPmdDyi+//PIvMX9QAXQtkiv88EWMbWH55ZdffvkjTAAA1O3iAijVXrFaWH755Zdf/sP8JgAAEwAAS7JOcdDb7cfB4+/dY9T1qckvv/zyLyH/Terwpz537frcJ19++eWXf6751ynDbzb3vx+37f6omULX5z758ssvv/xzzn+TI3z3uL8mdH3Jky+//PLLP8f8vgkMsFAKAEABAKAArjD8hkPb7o8e99eErk9Nfvnll39p+dexX0T/Gw/9UH+FCV2f44sgv/zyy7+U/DcpXsQln7t2fe4mll9++eWfa/51rhcRc32JL4L88ssv/9zy+yYwwEIpAAAFAIACAEABAKAAAFAAACgAABQAAAoAAAUAgAIAoL4CeH79WjVN07x/7ooE7Z63yxFKfvnll1/+w/wmAAATwHRbbGz7yi+//PLLf5z/ZuxBc4Wv5bjyyy+//LXkDy6AfoukfhH9449tX/nll19++SNMADleRIqTL7/88ssv//9GvbC3l7ufc3//9LAdPaLEPvnyyy+//PJHKIBLXkSspiz1RZBffvnln2t+PwYKsFDrlAe/pIFSNqD88ssvv/yFCoDpyzHmgv9+FzgB+A8Q59/5Y7rn3/cAABZKAQAAAAAAAAAAAAAAAABM3CT+OWj/OzpARQWQ4l/RUwQAEy6A4cZ/yW+t+Zfhb7XJWQQmGEABBG6WMTb+c0WQelM1wQAKYCKbf64SmNsEA5C0AHJt/qlLYE4TDMBYQf8cdI7NP9Xz5Cix/nGn/KvmAC4qgG4jy7X5DzfTGBtpzglGCQCznABqV/MEA5C1AErd/cecAuYwwQCYAABQAFO++zcFADVYxzrQ7fbj4PH37jHqegAmOAEMN/NTn7t2PQATnACGG/dmc//7cdvuj+7sQ9fnYoIBTACRNv/ucX9N6PpSm78JBjABLMBcJhiArBPAnDf/miYYAAUAQJ4CGL7d0bb7o8f9NaHrAUhn9PcAvnePB2979Df1vzbz0PUATHAC+NdGH2t9KiYYwASQqARirk9ZAiYYwASwULVOMACTmADmWAI1TDAAJgAAFAAACgAABQCAAgBAAQAoAAAUAAAKAAAFAIACAEABAKAAAFAAACgAABQAAAoAgCkXwPPr16ppmub9c1ckXPe8XY5QtecHMAEAkL8ASt1Fx7p7rj0/wCQmgFybaKrnqT0/QPYC6N/Fpt7c+sePdfdce36AohNAjk005eZZe36A2II3qbeXu59L1j09bM9ukJdu1rHVnh+gWAGEbqTX3qWnVnt+gLGu/jHQlG/R5FB7foCx1jk32BR33fIDZJ4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJZgNfYAby93P2OP8fz6tfKlAKikAGJs/IoAoKICGG78Tw/b0SHeP3fFisAEAyiAwM0yxsZ/rghSb6omGEABTGTzz1UCc5tgAJIWQK7NP3UJzGmCARjrJmRxjs0/1fPkKLH+cVO8xQSQtQC6jSzX5j/cTGNspDknGCUAzHICqF3NEwxA1gIodfcfcwqYwwQDYAIAQAFM+e7fFADUYB3rQLfbj4PH37vHqOsBmOAEMNzMT33u2vUATHACGG7cm83978dtuz+6sw9dn4sJBjABRNr8u8f9NaHrS23+JhjABLAAc5lgALJOAHPe/GuaYAAUAAB5CmD4dkfb7o8e99eErgcgndHfA/jePR687dHf1P/azEPXAzDBCeBfG32s9amYYAATQKISiLk+ZQmYYAATwELVOsEATGICmGMJ1DDBAJgAAFAAACgAABQAAAoAAAUAoAAAUAAALLwAnl+/Vk3TNO+fuyLhuuftcoSqPT+ACQCA/AVQ6i461t1z7fkBJjEB5NpEUz1P7fkBshdA/y429ebWP36su+fa8wMUnQBybKIpN8/a8wPEdvEm9fZy93Pq754etlE2zXOb9li15weILcrvA6j9PW/v2QNL5MdAAUwA1xvzVse5t2ZyqT0/gAkAAAUAgAIAQAEA0PkPK875jF7ESN4AAAAASUVORK5CYII="

-- =====================================================================
-- Lifecycle
-- =====================================================================
on openCard
   if the uPfUIVersionTag of this stack is not kPfUIVersion then buildPfUI
   if gStarted is true then
      b2kStart
   else
      pfStartGame
   end if
   pass openCard
end openCard

on closeCard
   b2kStop
   pass closeCard
end closeCard

-- =====================================================================
-- Chrome (version-tagged; rebuilds when a newer example is pasted in)
-- =====================================================================
command buildPfUI
   if there is a field "pfTitle" then delete field "pfTitle"
   if there is a field "pfHelp" then delete field "pfHelp"
   if there is a field "pfHud" then delete field "pfHud"
   if there is a button "pfbtn_pause" then delete button "pfbtn_pause"
   if there is a button "pfbtn_reset" then delete button "pfbtn_reset"
   set the width of this stack to 1024
   set the height of this stack to 640
   set the loc of this stack to the screenLoc
   create field "pfTitle"
   set the rect of it to 20, 8, 1004, 30
   set the lockText of it to true
   set the traversalOn of it to false
   set the textSize of it to 14
   set the text of it to "Box2Dxt platformer - a scrolling Game Kit showcase (input + sprites + camera)"
   create field "pfHelp"
   set the rect of it to 20, 34, 1004, 92
   set the lockText of it to true
   set the traversalOn of it to false
   set the textSize of it to 11
   create field "pfHud"
   set the rect of it to 20, 584, 760, 612
   set the lockText of it to true
   set the traversalOn of it to false
   set the textSize of it to 11
   create button "pfbtn_pause"
   set the rect of it to 800, 582, 884, 610
   set the label of it to "Pause"
   set the traversalOn of it to false
   create button "pfbtn_reset"
   set the rect of it to 900, 582, 984, 610
   set the label of it to "Reset"
   set the traversalOn of it to false
   set the uPfUIVersionTag of this stack to kPfUIVersion
end buildPfUI

-- =====================================================================
-- Assets: the Kenney atlases, or the embedded placeholder when missing
-- =====================================================================
function pfLoadSheets
   local tFolder, tN
   put empty into gLoadNote
   put the uSpriteSheetFolderPath of this stack into tFolder
   if tFolder is empty or there is no file (tFolder & "/spritesheet-characters-default.png") then
      answer folder "Locate the repo's Spritesheets folder (Cancel = built-in placeholder art):"
      put it into tFolder
      if tFolder is empty or the result is "cancel" then
         put "no folder chosen" into gLoadNote
         return false
      end if
      if there is no file (tFolder & "/spritesheet-characters-default.png") then
         put "spritesheet-characters-default.png is not inside: " & tFolder into gLoadNote
         return false
      end if
      set the uSpriteSheetFolderPath of this stack to tFolder
   end if
   b2kSheetLoadAtlas "chars", tFolder & "/spritesheet-characters-default.png"
   put the result into tN
   if tN < 1 then
      put "characters atlas gave 0 frames (png or xml unreadable) in: " & tFolder into gLoadNote
      return false
   end if
   b2kSheetLoadAtlas "foes", tFolder & "/spritesheet-enemies-default.png"
   put the result into tN
   if tN < 1 then put "enemies atlas gave 0 frames. " after gLoadNote
   b2kSheetLoadAtlas "tiles", tFolder & "/spritesheet-tiles-default.png"
   put the result into tN
   if tN < 1 then put "tiles atlas gave 0 frames. " after gLoadNote
   b2kSheetLoadAtlas "bg", tFolder & "/spritesheet-backgrounds-default.png"
   put the result into tN
   if tN < 1 then put "backgrounds atlas gave 0 frames. " after gLoadNote
   b2kSheetScale "bg", 2.5   -- 256px panels -> 640px (full card height)
   -- the hero (beige; swap the colour word to re-skin)
   b2kAnimDef "chars", "idle", "character_beige_idle", 2, true
   b2kAnimDef "chars", "walk", "character_beige_walk_a,character_beige_walk_b", 6, true
   b2kAnimDef "chars", "jump", "character_beige_jump", 1, true
   b2kAnimDef "chars", "hit", "character_beige_hit", 2, false
   b2kAnimDef "foes", "buzz", "bee_a,bee_b", 8, true
   b2kAnimDef "foes", "sawspin", "saw_a,saw_b", 10, true
   b2kAnimDef "foes", "slimewalk", "slime_normal_walk_a,slime_normal_walk_b", 4, true
   b2kAnimDef "tiles", "spin", "coin_gold,coin_gold_side", 4, true
   b2kAnimDef "tiles", "wave", "flag_blue_a,flag_blue_b", 4, true
   return true
end pfLoadSheets

command pfEmbedPlaceholder
   if there is no image "pf_sheetsrc" then
      create image "pf_sheetsrc"
      set the visible of it to false
      set the text of image "pf_sheetsrc" to base64Decode(kHeroSheetB64)
      set the lockLoc of it to true   -- AFTER the content, so it auto-sized
   end if
   b2kSheetFromImage "chars", the long id of image "pf_sheetsrc", 48, 64
   b2kAnimDef "chars", "idle", "1-4", 4, true
   b2kAnimDef "chars", "walk", "9-16", 10, true
   b2kAnimDef "chars", "jump", "17", 1, true
   b2kAnimDef "chars", "hit", "19", 2, false
end pfEmbedPlaceholder

-- =====================================================================
-- World build / reset
-- =====================================================================
command pfStartGame
   local tRef, tW, tH, tDY, tX, tS
   if the shiftKey is down then set the uSpriteSheetFolderPath of this stack to empty
   b2kTeardown                  -- wipes sheets, closes the camera, sweeps orphans
   pfWipeStage
   put false into gHurtLock
   put false into gWon
   put 0 into gCoins
   put 0 into gPlateCount
   put empty into gPlateLook
   put empty into gSlimeGoneAt
   put 60 into gSlimeDir
   b2kSetup
   b2kSetScale 60
   put pfLoadSheets() into gAssetsOK
   if gAssetsOK is not true then pfEmbedPlaceholder
   if gAssetsOK is true and gLoadNote is empty then
      set the text of field "pfHelp" to "Run with arrows or A/D; SPACE / UP / W jumps. Route: up through the bridge, over the SPIKE PIT, drag the" & cr & "CRATE onto the gold PLATE to hold the red gate open, past the saw, stomp the slime, climb to the FLAG." & cr & "Drag bodies with the mouse. Shift+Reset re-asks for the Spritesheets folder."
   else
      if gAssetsOK is true then
         set the text of field "pfHelp" to "KENNEY CHARACTERS LOADED, but: " & gLoadNote & cr & "Missing atlases fall back to plain shapes." & cr & "Shift+Reset re-asks for the Spritesheets folder."
      else
         set the text of field "pfHelp" to "PLACEHOLDER ART - the atlas load failed: " & gLoadNote & cr & "Press Shift+Reset to pick the Spritesheets folder again (it must contain the" & cr & "spritesheet-*-default.png and .xml files)."
      end if
   end if
   lock screen
   -- ===== far backdrop: static panels on the CARD (they do not scroll) ====
   if gAssetsOK is true and b2kSheetHasFrame("bg", "background_color_hills") then
      b2kSpriteNew "bg", "background_color_hills", 320, 320
      put the result into tRef
      if tRef is not empty then set the layer of tRef to 1
      b2kSpriteNew "bg", "background_color_hills", 960, 320
      put the result into tRef
      if tRef is not empty then set the layer of tRef to 2
   end if
   -- ===== the camera: everything Kit-made from here lives in the view ====
   b2kCamOn
   put (b2kCamIsOn() and b2kCamStatus() is empty) into gCamOK
   b2kCamBounds 0, 0, kLevelW, 640
   b2kCamDeadzone 90, 600
   b2kCamGoto 120, 480   -- open on the spawn point, no startup slide
   -- level bounds (invisible)
   b2kWall 0, 0, 0, 640
   b2kWall kLevelW, 0, kLevelW, 640
   b2kWall 0, 0, kLevelW, 0
   -- ===== terrain: invisible physics slabs + tile art (pit at 1408-1600) ==
   pfSlab "pf_ground1", 0, 576, 1408, 640
   pfSlab "pf_ground2", 1600, 576, kLevelW, 640
   pfSlab "pf_plat1", 2688, 512, 2880, 576
   pfSlab "pf_plat2", 2880, 448, 3008, 576
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "terrain_grass_block_top") then
      repeat with tX = 0 to 1344 step 64
         pfTile "terrain_grass_block_top", tX, 576
      end repeat
      repeat with tX = 1600 to 3008 step 64
         pfTile "terrain_grass_block_top", tX, 576
      end repeat
      pfTile "terrain_grass_block_top_left", 2688, 512
      pfTile "terrain_grass_block_top", 2752, 512
      pfTile "terrain_grass_block_top_right", 2816, 512
      pfTile "terrain_grass_block_top", 2880, 448
      pfTile "terrain_grass_block_top", 2944, 448
      pfTile "terrain_grass_block_center", 2880, 512
      pfTile "terrain_grass_block_center", 2944, 512
      pfShowSlabs false
   else
      pfShowSlabs true
   end if
   -- ===== the spike pit ====
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "block_spikes") then
      pfTile "block_spikes", 1408, 600
      pfTile "block_spikes", 1472, 600
      pfTile "block_spikes", 1536, 600
   else
      create graphic "pf_spikes"
      set the style of it to "rectangle"
      set the rect of it to 1408, 600, 1600, 640
      set the filled of it to true
      set the backgroundColor of it to "200,60,60"
      b2kCamAdopt the long id of graphic "pf_spikes"
   end if
   create graphic "pf_spikesens"
   set the style of it to "rectangle"
   set the rect of it to 1408, 592, 1600, 644
   set the visible of it to false
   put the long id of graphic "pf_spikesens" into tRef
   set the uPfHazardFlag of tRef to true
   b2kAddSensor tRef, "box"
   -- ===== the one-way bridge (chain, solid side up) ====
   b2kSmoothGround "624,440" & cr & "560,440" & cr & "304,440" & cr & "240,440"
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "bridge") then
      repeat with tX = 304 to 496 step 64
         pfTile "bridge", tX, 424
      end repeat
   else
      create graphic "pf_ledge"
      set the style of it to "line"
      set the points of it to "304,440" & cr & "560,440"
      set the lineSize of it to 4
      set the foregroundColor of it to "70,190,110"
      b2kCamAdopt the long id of graphic "pf_ledge"
   end if
   -- ===== plate + gate puzzle ====
   create graphic "pf_plate"
   set the style of it to "rectangle"
   set the rect of it to 1772, 560, 1828, 576
   set the filled of it to true
   set the backgroundColor of it to "220,180,60"
   put the long id of graphic "pf_plate" into tRef
   set the uPfPlateFlag of tRef to true
   b2kCamAdopt tRef
   b2kAddSensor tRef, "box"
   create graphic "pf_gate"
   set the style of it to "rectangle"
   set the rect of it to 1920, 448, 1984, 576
   set the filled of it to true
   set the backgroundColor of it to "190,70,70"
   put the long id of graphic "pf_gate" into gGate
   b2kAddBox gGate
   b2kSetKinematic gGate
   put empty into gGateSprA
   put empty into gGateSprB
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "block_red") then
      set the visible of graphic "pf_gate" to false
      b2kSpriteNew "tiles", "block_red", 1952, 480
      put the result into gGateSprA
      if gGateSprA is not empty then b2kSpriteBind gGateSprA, gGate, 0, -32
      b2kSpriteNew "tiles", "block_red", 1952, 544
      put the result into gGateSprB
      if gGateSprB is not empty then
         b2kSpriteBind gGateSprB, gGate, 0, 32
      end if
   else
      b2kCamAdopt gGate
   end if
   -- the crate that holds the plate down (drag or push it)
   b2kSpawnBox 1700, 520, 56, 56, "orange"
   put the result into tRef
   if tRef is not empty then b2kSetFriction tRef, 0.6
   -- ===== the hero ====
   if gAssetsOK is true then
      b2kSheetScale "chars", 0.75
      put 48 into tW
      put 88 into tH
      put -4 into tDY
   else
      put 36 into tW
      put 60 into tH
      put -2 into tDY
   end if
   create graphic "pf_heroBody"
   set the style of it to "rectangle"
   set the rect of it to 120 - tW div 2, 480 - tH div 2, 120 + tW div 2, 480 + tH div 2
   set the visible of it to false
   put the long id of graphic "pf_heroBody" into gHero
   b2kAddCapsule gHero
   b2kSetFixedRotation gHero, true
   b2kSetFriction gHero, 0.08
   if gAssetsOK is true then
      b2kSpriteNew "chars", "character_beige_idle", 120, 480
   else
      b2kSpriteNew "chars", 1, 120, 480
   end if
   put the result into gHeroSpr
   b2kSpriteBind gHeroSpr, gHero, 0, tDY
   b2kSpriteOnFinish gHeroSpr, "pfHurtDone"
   b2kSpritePlay gHeroSpr, "idle"
   b2kCamFollow gHero, 0.2
   -- ===== pickups ====
   pfMakeCoin 380, 384
   pfMakeCoin 688, 470
   pfMakeCoin 1504, 470
   pfMakeCoin 2400, 480
   pfMakeCoin 2820, 448
   put 5 into gCoinsTotal
   -- ===== hazards + critters ====
   put empty into tRef
   put empty into gBeeSpr
   if gAssetsOK is true and b2kSheetHasFrame("foes", "saw_a") then
      b2kSpriteNew "foes", "saw_a", 2100, 544
      put the result into tRef
      if tRef is not empty then
         set the uPfHazardFlag of tRef to true
         b2kSpritePlay tRef, "sawspin"
         b2kAddSensor tRef, "ball"
      end if
      b2kSpriteNew "foes", "bee_a", 820, 300
      put the result into gBeeSpr
      if gBeeSpr is not empty then b2kSpritePlay gBeeSpr, "buzz"
   end if
   if tRef is empty then
      create graphic "pf_saw"
      set the style of it to "oval"
      set the rect of it to 2076, 520, 2124, 568
      set the filled of it to true
      set the backgroundColor of it to "210,60,60"
      put the long id of graphic "pf_saw" into tRef
      set the uPfHazardFlag of tRef to true
      b2kCamAdopt tRef
      b2kAddSensor tRef, "ball"
   end if
   pfMakeSlime
   -- ===== the goal flag ====
   put empty into tRef
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "flag_blue_a") then
      b2kSpriteNew "tiles", "flag_blue_a", 2944, 416
      put the result into tRef
      if tRef is not empty then
         set the uPfGoalFlag of tRef to true
         b2kSpritePlay tRef, "wave"
         b2kAddSensor tRef, "ball"
      end if
   end if
   if tRef is empty then
      create graphic "pf_flag"
      set the style of it to "rectangle"
      set the rect of it to 2928, 384, 2960, 448
      set the filled of it to true
      set the backgroundColor of it to "70,110,230"
      put the long id of graphic "pf_flag" into tRef
      set the uPfGoalFlag of tRef to true
      b2kCamAdopt tRef
      b2kAddSensor tRef, "box"
   end if
   -- ===== camera-dead fallback: clamp play to the visible screen ====
   if gCamOK is not true then
      b2kWall 1010, 0, 1010, 640
      put empty into tRef
      if gAssetsOK is true and b2kSheetHasFrame("tiles", "flag_blue_a") then
         b2kSpriteNew "tiles", "flag_blue_a", 950, 544
         put the result into tRef
         if tRef is not empty then
            set the uPfGoalFlag of tRef to true
            b2kSpritePlay tRef, "wave"
            b2kAddSensor tRef, "ball"
         end if
      end if
      if tRef is empty then
         create graphic "pf_flagnear"
         set the style of it to "rectangle"
         set the rect of it to 934, 512, 966, 576
         set the filled of it to true
         set the backgroundColor of it to "70,110,230"
         put the long id of graphic "pf_flagnear" into tRef
         set the uPfGoalFlag of tRef to true
         b2kAddSensor tRef, "box"
      end if
      set the text of field "pfHelp" to "CAMERA UNAVAILABLE on this engine (" & b2kCamStatus() & ") - the level is clamped" & cr & "to this screen and the flag moved here so it stays completable. Everything else works." & cr & "Please report the quoted reason."
   end if
   -- ===== input + events ====
   b2kInputOn
   b2kBindAction "jump", "space,up,w"
   b2kFrameTarget the long id of me
   b2kContactTarget the long id of me
   pfChromeFront
   unlock screen
   put empty into gHudLast
   put true into gStarted
   b2kStart
end pfStartGame

-- An invisible static physics slab (shown grey only in fallback mode).
command pfSlab pName, pL, pT, pR, pB
   create graphic pName
   set the style of it to "rectangle"
   set the rect of it to pL, pT, pR, pB
   set the filled of it to true
   set the backgroundColor of it to "100,105,115"
   set the visible of it to false
   b2kAddStatic the long id of graphic pName
end pfSlab

command pfShowSlabs pFlag
   local tC
   set the itemDelimiter to comma
   repeat for each item tC in "pf_ground1,pf_ground2,pf_plat1,pf_plat2"
      if there is a graphic tC then
         set the visible of graphic tC to pFlag
         if pFlag is true then b2kCamAdopt the long id of graphic tC
      end if
   end repeat
end pfShowSlabs

-- One 64px tile sprite by its top-left corner (sprites centre on x,y).
command pfTile pFrame, pX, pY
   b2kSpriteNew "tiles", pFrame, pX + 32, pY + 32
end pfTile

command pfMakeCoin pX, pY
   local tRef
   put empty into tRef
   if gAssetsOK is true and b2kSheetHasFrame("tiles", "coin_gold") then
      b2kSpriteNew "tiles", "coin_gold", pX, pY
      put the result into tRef
      if tRef is not empty then b2kSpritePlay tRef, "spin"
   end if
   if tRef is empty then
      create graphic ("pf_coin" & pX)
      set the style of it to "oval"
      set the rect of it to pX - 16, pY - 16, pX + 16, pY + 16
      set the filled of it to true
      set the backgroundColor of it to "240,200,70"
      put the long id of it into tRef
      b2kCamAdopt tRef
   end if
   set the uPfCoinFlag of tRef to true
   b2kAddSensor tRef, "ball"
end pfMakeCoin

-- The patrolling slime: an invisible dynamic body, art bound on top.
command pfMakeSlime
   create graphic "pf_slimeBody"
   set the style of it to "rectangle"
   set the rect of it to 2376, 540, 2424, 576
   set the filled of it to true
   set the backgroundColor of it to "110,190,90"
   set the visible of it to false
   put the long id of graphic "pf_slimeBody" into gSlime
   b2kAddBox gSlime
   b2kSetFixedRotation gSlime, true
   b2kSetFriction gSlime, 0.1
   put empty into gSlimeSpr
   if gAssetsOK is true and b2kSheetHasFrame("foes", "slime_normal_walk_a") then
      b2kSpriteNew "foes", "slime_normal_walk_a", 2400, 544
      put the result into gSlimeSpr
      if gSlimeSpr is not empty then
         b2kSpriteBind gSlimeSpr, gSlime, 0, -6
         b2kSpritePlay gSlimeSpr, "slimewalk"
      end if
   end if
   if gSlimeSpr is empty then set the visible of graphic "pf_slimeBody" to true
   if the visible of graphic "pf_slimeBody" is true then b2kCamAdopt gSlime
end pfMakeSlime

command pfChromeFront
   local tN, tC
   put the number of controls of this card into tN
   set the itemDelimiter to comma
   repeat for each item tC in "pfTitle,pfHelp,pfHud"
      if there is a field tC then set the layer of field tC to tN
   end repeat
   repeat for each item tC in "pfbtn_pause,pfbtn_reset"
      if there is a button tC then set the layer of button tC to tN
   end repeat
end pfChromeFront

command pfWipeStage
   local tAgain, i, tName
   put true into tAgain
   repeat while tAgain
      put false into tAgain
      repeat with i = 1 to the number of controls of this card
         put the short name of control i of this card into tName
         if char 1 to 3 of tName is "pf_" then
            delete control i of this card
            put true into tAgain
            exit repeat
         end if
      end repeat
   end repeat
end pfWipeStage

-- =====================================================================
-- The game tick
-- =====================================================================
on b2kFrame
   local tHud
   if gHero is empty then exit b2kFrame
   -- kill plane: anything that slips every other check still respawns
   if gHurtLock is not true then
      set the itemDelimiter to comma
      if (item 2 of b2kPosition(gHero)) > 780 then pfHurt
   end if
   pfTickHero
   pfTickGate
   pfTickSlime
   if gBeeSpr is not empty then
      set the loc of gBeeSpr to round(820 + 90 * sin(the milliseconds / 900)), round(300 + 26 * sin(the milliseconds / 430))
   end if
   put "coins " & gCoins & "/" & gCoinsTotal & "   |   anim " & b2kSpriteAnim(gHeroSpr) & "   |   held " & b2kKeysHeld() & "   |   " & round(b2kFrameMS() * 10) / 10 & " ms" into tHud
   if gCamOK is true then put "   |   cam " & item 1 of b2kCamPos() after tHud
   if gCoins >= gCoinsTotal then put "   ALL COINS!" after tHud
   if gWon is true then put "LEVEL COMPLETE!   " before tHud
   if tHud is not gHudLast then
      put tHud into gHudLast
      set the text of field "pfHud" to tHud
   end if
end b2kFrame

command pfTickHero
   local tAxis, tVel, tVy, tAnim
   set the itemDelimiter to comma
   put b2kAxis("moveX") into tAxis
   if gHurtLock is true then put 0 into tAxis
   put b2kVelocity(gHero) into tVel
   put item 2 of tVel into tVy
   b2kSetVelocity gHero, tAxis * kMoveSpeed, tVy
   if gHurtLock is not true then
      if b2kActionPressed("jump") and pfOnGround() then
         b2kSetVelocity gHero, tAxis * kMoveSpeed, 0 - kJumpSpeed
      end if
      if b2kActionReleased("jump") then
         put b2kVelocity(gHero) into tVel
         if item 2 of tVel < 0 then
            b2kSetVelocity gHero, item 1 of tVel, (item 2 of tVel) * 0.45
         end if
      end if
      if pfOnGround() then
         if tAxis is 0 then
            put "idle" into tAnim
         else
            put "walk" into tAnim
         end if
      else
         put "jump" into tAnim
      end if
      b2kSpritePlay gHeroSpr, tAnim
      if tAxis is not 0 then b2kSpriteFlipH gHeroSpr, (tAxis < 0)
   end if
end pfTickHero

-- The kinematic gate chases its open/closed height; the plate's colour
-- tracks its state. Anything on the plate (the hero OR the crate) holds it.
command pfTickGate
   local tTarget, tY, tLook
   if gGate is empty then exit pfTickGate
   set the itemDelimiter to comma
   if gPlateCount > 0 then
      put 342 into tTarget
      put "down" into tLook
   else
      put 512 into tTarget
      put "up" into tLook
   end if
   if tLook is not gPlateLook then
      put tLook into gPlateLook
      if there is a graphic "pf_plate" then
         if tLook is "down" then
            set the backgroundColor of graphic "pf_plate" to "140,110,30"
         else
            set the backgroundColor of graphic "pf_plate" to "220,180,60"
         end if
      end if
   end if
   put item 2 of b2kPosition(gGate) into tY
   if abs(tY - tTarget) <= 6 then
      b2kSetVelocity gGate, 0, 0
   else
      if tTarget < tY then
         b2kSetVelocity gGate, 0, -160
      else
         b2kSetVelocity gGate, 0, 160
      end if
   end if
end pfTickGate

command pfTickSlime
   local tX
   if gSlimeGoneAt is not empty then
      if the milliseconds > gSlimeGoneAt then
         if gSlimeSpr is not empty then b2kSpriteRemove gSlimeSpr
         put empty into gSlimeSpr
         if there is a graphic "pf_slimeBody" then delete graphic "pf_slimeBody"
         put empty into gSlimeGoneAt
      end if
      exit pfTickSlime
   end if
   if gSlime is empty then exit pfTickSlime
   set the itemDelimiter to comma
   put item 1 of b2kPosition(gSlime) into tX
   if tX is empty then exit pfTickSlime
   if tX <= 2300 then put 60 into gSlimeDir
   if tX >= 2600 then put -60 into gSlimeDir
   b2kSetVelocity gSlime, gSlimeDir, item 2 of b2kVelocity(gSlime)
   if gSlimeSpr is not empty then b2kSpriteFlipH gSlimeSpr, (gSlimeDir < 0)
end pfTickSlime

-- =====================================================================
-- Events: sensors (coins, hazards, plate, goal) and contacts (the slime)
-- =====================================================================
on b2kSensorEnter pSensorCtrl, pVisitorCtrl
   if pSensorCtrl is empty then exit b2kSensorEnter
   if the uPfPlateFlag of pSensorCtrl is true then
      add 1 to gPlateCount
      exit b2kSensorEnter
   end if
   if pVisitorCtrl is not gHero then exit b2kSensorEnter
   if the uPfCoinFlag of pSensorCtrl is true then
      add 1 to gCoins
      b2kSpriteRemove pSensorCtrl
      try
         delete pSensorCtrl
      catch tErr
      end try
      exit b2kSensorEnter
   end if
   if the uPfHazardFlag of pSensorCtrl is true then pfHurt
   if the uPfGoalFlag of pSensorCtrl is true then put true into gWon
end b2kSensorEnter

on b2kSensorExit pSensorCtrl, pVisitorCtrl
   if pSensorCtrl is empty then exit b2kSensorExit
   if the uPfPlateFlag of pSensorCtrl is true then
      subtract 1 from gPlateCount
      if gPlateCount < 0 then put 0 into gPlateCount
   end if
end b2kSensorExit

-- Hero vs slime: falling onto it squashes; anything else hurts.
on b2kContact pA, pB
   local tHit
   if gSlime is empty or gHurtLock is true then exit b2kContact
   put false into tHit
   if pA is gHero and pB is gSlime then put true into tHit
   if pB is gHero and pA is gSlime then put true into tHit
   if not tHit then exit b2kContact
   set the itemDelimiter to comma
   if (item 2 of b2kVelocity(gHero)) > 40 and (item 2 of b2kPosition(gHero)) < (item 2 of b2kPosition(gSlime)) - 16 then
      pfSquashSlime
      b2kSetVelocity gHero, item 1 of b2kVelocity(gHero), -260
   else
      pfHurt
   end if
end b2kContact

command pfSquashSlime
   if gSlime is empty then exit pfSquashSlime
   if gSlimeSpr is not empty and b2kSheetHasFrame("foes", "slime_normal_flat") then
      b2kSpriteSetFrame gSlimeSpr, "slime_normal_flat"
      b2kSpriteUnbind gSlimeSpr
   end if
   b2kRemove gSlime               -- body gone; the flat art lingers a moment
   put empty into gSlime
   put the milliseconds + 700 into gSlimeGoneAt
end pfSquashSlime

command pfHurt
   if gHurtLock is true then exit pfHurt
   put true into gHurtLock
   b2kCamShake 7, 280
   b2kSpritePlay gHeroSpr, "hit", true   -- non-loop; OnFinish respawns
end pfHurt

on pfHurtDone pSprite, pAnim
   b2kMoveTo gHero, 120, 480
   b2kSetVelocity gHero, 0, 0
   put false into gHurtLock
   b2kSpritePlay gHeroSpr, "idle"
end pfHurtDone

-- Grounded = short rays from each foot hit an upward-facing surface.
function pfOnGround
   local tPos, tX, tY, tOff, tReach
   if gHero is empty then return false
   set the itemDelimiter to comma
   put b2kPosition(gHero) into tPos
   put item 1 of tPos into tX
   put item 2 of tPos into tY
   if gAssetsOK is true then
      put 54 into tReach
   else
      put 40 into tReach
   end if
   repeat for each item tOff in "-12,12"
      get b2kRayHit(tX + tOff, tY, tX + tOff, tY + tReach)
      if b2kRayDist() is not empty and b2kRayHitNormalY() <= -0.6 then
         return true
      end if
   end repeat
   return false
end pfOnGround

-- =====================================================================
-- Mouse: buttons by name; everything else is a camera-corrected grab
-- =====================================================================
on mouseDown
   local tName
   put the short name of the target into tName
   if char 1 to 6 of tName is "pfbtn_" then exit mouseDown
   get b2kGrab(b2kCamMouseX(), b2kCamMouseY())
end mouseDown

on mouseUp
   local tName
   put the short name of the target into tName
   switch tName
      case "pfbtn_reset"
         pfStartGame
         break
      case "pfbtn_pause"
         if b2kIsRunning() then
            b2kPause
            set the label of button "pfbtn_pause" to "Resume"
         else
            b2kResume
            set the label of button "pfbtn_pause" to "Pause"
         end if
         break
      default
         b2kRelease
   end switch
end mouseUp

on mouseRelease
   b2kRelease
end mouseRelease

-- =====================================================================
-- The Kit (embedded verbatim; regenerated by tools/sync-embedded-kit.py -
-- do not edit between the sentinels)
-- =====================================================================
-- >>> BEGIN EMBEDDED KIT >>>
-- =====================================================================
-- box2dxt-kit.livecodescript   ·   "Box2Dxt Kit"  (b2k...)
--
-- A friendly, pure-xTalk toolkit over the box2dxt extension. You work in
-- PIXELS, SCREEN coordinates and DEGREES; the kit converts to Box2D's
-- metres / radians / y-up for you, runs the world, and moves your controls.
-- Runs in OpenXTalk (OXT); compatible with LiveCode 9.6.3+.
-- Requires the box2dxt extension loaded (put b2Version() should return 4).
--
-- =====================  60-SECOND START  =============================
--   on openCard
--      b2kQuickStart            -- world + gravity + walls around the card + go
--      b2kSpawnBall 200,80, 50               -- create + drop a ball
--      b2kSpawnBox 260,80, 60,40, "orange"   -- (read `the result` for the ref)
--      b2kContactTarget the long id of me    -- (optional) collision messages
--   end openCard
--   on mouseDown ; get b2kGrab(the mouseH,the mouseV) ; end mouseDown
--   on mouseUp   ; b2kRelease ; end mouseUp
--   on closeCard ; b2kStop ; end closeCard
--
-- =====================  CHEAT SHEET  ================================
-- WORLD   b2kSetup [gx,gy] · b2kQuickStart [gy] · b2kStart · b2kStop ·
--         b2kTeardown · b2kAddWalls · b2kWall x1,y1,x2,y2 · b2kClear ·
--         b2kPause · b2kResume · b2kIsRunning()
-- CONFIG  b2kSetScale px · b2kSetOrigin x,y · b2kSetGravity gx,gy ·
--         b2kSetSubsteps n · b2kContactTarget obj · b2kFrameTarget obj ·
--         b2kEnableSleeping flag · b2kEnableContinuous flag
-- ATTACH  b2kAddBox ctrl[,dyn] · b2kAddBall ctrl[,dyn] · b2kAddCapsule ctrl[,dyn]
--         b2kAddPolygon ctrl[,dyn] · b2kAddStatic ctrl · b2kAddGround [screenY]
-- SPAWN   b2kSpawnBox x,y,w,h[,color] · b2kSpawnBall x,y,diam[,color] ·
--         b2kSpawnCapsule x,y,len,thick[,color]                       (-> control)
-- MATERIAL b2kSetBounce ctrl,0..1 · b2kSetFriction ctrl,0..1 · b2kSetDensity ctrl,d
-- BODY    b2kSetBullet ctrl,flag · b2kSetFixedRotation ctrl,flag ·
--         b2kSetGravityScale ctrl,s · b2kSetDamping ctrl,lin[,ang] · b2kWake ctrl ·
--         b2kSetType ctrl,name · b2kSetStatic/Dynamic/Kinematic ctrl ·
--         b2kEnable/Disable ctrl
-- ACT     b2kPush ctrl,dvx,dvy · b2kImpulse ctrl,ix,iy · b2kForce ctrl,fx,fy ·
--         b2kSetVelocity ctrl,vx,vy · b2kSpin ctrl,deg/s · b2kSpinBy ctrl,deg/s ·
--         b2kTorque ctrl,t · b2kAngularImpulse ctrl,imp · b2kMoveTo ctrl,x,y[,deg] ·
--         b2kExplode x,y[,radius][,power] · b2kRemove ctrl
-- GET     b2kBodyOf(ctrl) · b2kPosition(ctrl) · b2kWorldCenter(ctrl) · b2kVelocity(ctrl) ·
--         b2kSpeed(ctrl) · b2kAngle(ctrl) · b2kMass(ctrl) · b2kBodyType(ctrl) ·
--         b2kGravityScale(ctrl) · b2kDamping(ctrl) · b2kIsAwake(ctrl) · b2kControlAt(x,y) ·
--         b2kControlContains(ctrl,x,y) · b2kBodyCount() · b2kAwakeCount() ·
--         b2kToWorldX/Y(px) · b2kToScreenX/Y(m) ·
--         b2kRayHit(x1,y1,x2,y2) + b2kRayHitX/Y() · b2kRayHitNormalX/Y() · b2kRayDist()
-- JOINTS  b2kHinge ctrlA,ctrlB,x,y · b2kWeld ctrlA,ctrlB · b2kRope ctrlA,ctrlB[,len]
--         b2kSlider ctrlA,ctrlB,axisDeg · b2kWheel chassis,wheel,x,y[,axisDeg]
--         b2kMotor j,degPerSec[,maxTorque] · b2kSliderMotor j,pxPerSec[,maxForce] ·
--         b2kWheelMotor j,degPerSec[,maxTorque] · b2kRemoveJoint j
-- JOINT+  b2kHingeLimit j,loDeg,hiDeg · b2kHingeAngle(j) · b2kSliderLimit j,loPx,hiPx ·
--         b2kSliderPos(j) · b2kRopeRange j,minPx,maxPx · b2kRopeLength(j) ·
--         b2kSpring j,hz[,damp] · b2kWeldSpring j,hz[,damp] · b2kWheelSpring j,hz[,damp]
-- DRAG    b2kGrab(x,y) -> control · b2kRelease
-- INPUT   b2kInputOn/Off · b2kKeyIsDown(k) · b2kKeyPressed/Released(k) ·
--         b2kKeysHeld() · b2kBindAction name,keys · b2kActionIsDown/Pressed/
--         Released(name) · b2kBindAxis name,negKeys,posKeys · b2kAxis(name) ·
--         b2kFrameMS()   (poll-based: arm b2kInputOn, read from on b2kFrame)
-- SPRITE  b2kSheetLoad name,path,fw,fh[,n] · b2kSheetLoadAtlas name,png[,xml] ·
--         b2kSheetFromImage name,img,fw,fh · b2kSheetFrames(name) ·
--         b2kSheetScale name,factor · b2kSheetFrameSize(name,frame) ·
--         b2kAnimDef sheet,anim,frames,fps[,loop] · b2kSpriteNew sheet[,frame,x,y] ·
--         b2kSpriteFromGIF path[,x,y] · b2kSpritePlay spr,anim[,restart] ·
--         b2kSpriteStop spr · b2kSpriteSetFrame spr,f · b2kSpriteFlipH spr,flag ·
--         b2kSpriteFPS spr,fps · b2kSpriteOnFinish spr,msg ·
--         b2kSpriteBind spr,bodyCtrl[,dx,dy] · b2kSpriteRemove spr
-- CAMERA  b2kCamOn [rect] · b2kCamOff · b2kCamFollow ctrl[,lerp] · b2kCamUnfollow ·
--         b2kCamDeadzone w,h · b2kCamBounds x1,y1,x2,y2 · b2kCamGoto x,y ·
--         b2kCamPos() · b2kCamShake amp,ms · b2kCamMouseX/Y() · b2kCamGroup() ·
--         b2kCamAdopt ctrl   (world px == control locs; spawns auto-join the view)
-- EVENTS  on b2kContact pCtrlA,pCtrlB · on b2kEndContact pCtrlA,pCtrlB
--         (long ids; empty for walls/ground) · on b2kFrame  (once per frame)
--         poll instead: b2kContactCount()+b2kContactA/B(i) · b2kEndContactCount()+…
-- SENSOR  b2kAddSensor ctrl[,shape] · on b2kSensorEnter pSensor,pVisitor ·
--         on b2kSensorExit pSensor,pVisitor · b2kSensorCount()+EnterSensor/Visitor(i)
-- FILTER  b2kDefineLayer name · b2kSetCategory ctrl,layers · b2kSetMask ctrl,layers ·
--         b2kSetCollisionGroup ctrl,n · b2kNoCollide ctrlA,ctrlB
-- TERRAIN b2kChain pointList[,loop] · b2kSmoothGround pointList  (>=4 screen points)
-- QUERY+  b2kOverlap x1,y1,x2,y2 · b2kOverlapCircle x,y,r · b2kRayHitAll x1,y1,x2,y2
-- MOTOR   b2kMotorTo mover,ref,dxPx,dyPx,deg[,maxF,maxT] · b2kExplode (native blast)
-- TUNE    b2kSetRestitutionThreshold px/s · b2kSetContactTuning hz,damp,pushPx ·
--         b2kSetJointTuning hz,damp · b2kSetMaxSpeed px/s · b2kEnableWarmStarting f ·
--         b2kProfile() · b2kAwakeBodyCount()
--
-- Tips: pass controls by reference (the long id of ... is safest). Keep moving
-- objects a sensible on-screen size (default scale 40 px/m, so ~4-400 px).
-- Graphic boxes/polygons and dynamic images rotate; buttons/fields/etc follow
-- position upright (their rotation is locked so the sim matches the render).
-- =====================================================================

local sWorld, sRunning, sPaused, sGen
local sScale, sOriginX, sOriginY
local sAccum, sLast, sSub
local sBody          -- ctrlRef     -> body handle
local sCtrl          -- body handle -> ctrlRef
local sShapeH        -- ctrlRef     -> shape handle (for material edits)
local sRender        -- ctrlRef     -> "poly" | "ball" | "image" | "loc"
local sVerts         -- ctrlRef     -> local polygon verts (metres) for "poly"
local sRad           -- ctrlRef     -> radius (metres) for "ball"
local sImgAngle      -- ctrlRef     -> last applied angle (deg) for "image"
local sStatic        -- ctrlRef     -> true for bodies that never move
local sSpawned       -- ctrlRef     -> true if the kit created the control
local sSensor        -- ctrlRef     -> true for sensor (non-solid trigger) bodies
local sLayers        -- collision-layer name -> bit value
local sNextBit       -- next free collision-layer bit
local sDragJoint, sDragAnchor, sDragging
local sContactObj    -- object that receives b2kContact messages
local sFrameObj      -- object that receives an on b2kFrame message each frame
local sRayX, sRayY   -- last b2kRayHit point (screen pixels)
local sRayNX, sRayNY -- last b2kRayHit surface normal (screen-oriented)
local sRayDist       -- last b2kRayHit distance from the ray start (pixels)
local sNeedFullSync  -- true when a script-side transform/type edit bypassed move events
local sDrawKey       -- ctrlRef -> last rendered pixel/angle key; avoids redundant redraws
local sInputOn       -- true while the per-frame keyboard sample is armed
local sKeysNow       -- comma-wrapped keycode set held this frame (",65361,32,")
local sKeysPrev      -- last frame's set; pressed/released edges are the diff
local sKeyActions    -- action name -> bound key list ("jump" -> "space,up,w")
local sAxisNeg       -- axis name -> negative-direction key list
local sAxisPos       -- axis name -> positive-direction key list
local sFrameMS       -- real elapsed ms folded into the last frame (b2kFrameMS)
local sSheetSrc      -- sheet -> long id of its hidden source image
local sSheetOwned    -- sheet -> true when the Kit created the source image
local sSheetRegion   -- sheet -> frame key -> "x,y,w,h" region (source px)
local sSheetKeys     -- sheet -> CR list of frame keys, definition order
local sSheetIcon     -- sheet -> frame key -> sliced frame image id (lazy)
local sSheetFlip     -- sheet -> frame key -> mirrored image id (lazy)
local sSheetData     -- sheet -> cached source imageData (freed on teardown)
local sSheetAlpha    -- sheet -> cached source alphaData
local sSheetScale    -- sheet -> display scale factor (default 1; engine-resampled at slice time)
local sAnimList      -- "sheet|anim" -> CR list of frame keys
local sAnimFPS       -- "sheet|anim" -> frames per second
local sAnimLoop      -- "sheet|anim" -> true/false
local sSprRefs       -- CR list of live sprite controls (the tick iterates)
local sSprSheet, sSprKind, sSprAnim, sSprStep, sSprNextMS
local sSprFPS, sSprFPSOver, sSprFlip, sSprMsg, sSprFrameKey, sSprIconNow
local sSprBind, sSprBindDX, sSprBindDY, sSprLastLoc
local sCamGroup      -- viewport group long id while the camera is on
local sCamFollow     -- control the camera tracks (empty = manual)
local sCamLerp       -- follow smoothing 0..1 (1 = snap)
local sCamDZW, sCamDZH -- deadzone box in px (0 = always centre)
local sCamB1X, sCamB1Y, sCamB2X, sCamB2Y -- world bounds (sCamB1X empty = none)
local sCamX, sCamY   -- current view centre (world px)
local sCamShakeAmp, sCamShakeEnd
local sCamLastH, sCamLastV -- last written scroll (skip redundant sets)
local sCamNote       -- empty = healthy; else why the camera is degraded

constant kPI = 3.14159265358979

-- =====================================================================
-- World / lifecycle
-- =====================================================================
command b2kSetup pGravityX, pGravityY
   b2kTeardown
   if pGravityX is empty then put 0 into pGravityX
   if pGravityY is empty then put -10 into pGravityY
   put b2NewWorld(pGravityX, pGravityY, true, true) into sWorld
   put b2NewStaticBody(sWorld, 0, 0) into sDragAnchor
   put 40 into sScale
   put (the width of this card) div 2 into sOriginX
   put (the height of this card) - 40 into sOriginY
   put 4 into sSub
   b2kResetTables
   put empty into sLayers
   put 1 into sNextBit
   put 0 into sDragJoint
   put false into sDragging
   put false into sRunning
   put false into sPaused
   put false into sNeedFullSync
end b2kSetup

command b2kResetTables
   put empty into sBody
   put empty into sCtrl
   put empty into sShapeH
   put empty into sRender
   put empty into sVerts
   put empty into sRad
   put empty into sImgAngle
   put empty into sDrawKey
   put empty into sStatic
   put false into sNeedFullSync
   put empty into sSpawned
   put empty into sSensor
end b2kResetTables

command b2kTeardown
   put false into sRunning
   put the milliseconds & random(9999) into sGen
   if sWorld is not empty then b2DestroyWorld sWorld
   put empty into sWorld
   b2kCamOff       -- dissolve the viewport; its children return to the card
   b2kSheetsWipe   -- sprites, sliced frames, sources: all module state goes
   b2kResetTables
   put 0 into sDragJoint
   put false into sDragging
end b2kTeardown

-- One-liner: world with gravity, walls around the card, loop running.
command b2kQuickStart pGravityY
   b2kSetup 0, pGravityY
   b2kAddWalls
   b2kStart
end b2kQuickStart

command b2kStart
   if sWorld is empty then b2kSetup
   put true into sRunning
   put false into sPaused
   put 0 into sAccum
   put the milliseconds into sLast
   put the milliseconds & "_" & random(1000000) into sGen
   send ("b2kStep " & sGen) to me in 16 milliseconds
end b2kStart

command b2kStop
   put false into sRunning
   put the milliseconds & random(9999) into sGen
end b2kStop

command b2kPause
   put true into sPaused
end b2kPause

command b2kResume
   put false into sPaused
   put the milliseconds into sLast
end b2kResume

function b2kIsRunning
   return (sRunning is true) and (sPaused is not true)
end b2kIsRunning

-- Static, invisible walls along the four card edges.
command b2kAddWalls
   local tL, tR, tT, tB
   put b2kToWorldX(0) into tL
   put b2kToWorldX(the width of this card) into tR
   put b2kToWorldY(0) into tT
   put b2kToWorldY(the height of this card) into tB
   b2kEdge tL, tB, tR, tB
   b2kEdge tL, tT, tR, tT
   b2kEdge tL, tB, tL, tT
   b2kEdge tR, tB, tR, tT
end b2kAddWalls

command b2kEdge pWx1, pWy1, pWx2, pWy2
   local tBody
   if sWorld is empty then exit b2kEdge   -- no world yet: a wall is a quiet no-op
   put b2NewStaticBody(sWorld, 0, 0) into tBody
   get b2AddSegment(tBody, pWx1, pWy1, pWx2, pWy2, 0.6, 0.1)
end b2kEdge

-- A wide invisible ground line at screen height pScreenY (default: near bottom).
command b2kAddGround pScreenY
   local tBody, tWy
   if sWorld is empty then exit b2kAddGround
   if pScreenY is empty then put (the height of this card) - 40 into pScreenY
   put b2kToWorldY(pScreenY) into tWy
   put b2NewStaticBody(sWorld, 0, tWy) into tBody
   get b2AddSegment(tBody, -500, 0, 500, 0, 0.7, 0.1)
end b2kAddGround

-- A static collision segment between two SCREEN points — custom walls, ramps,
-- ledges and floors. Like the card-edge walls it is invisible (draw your own
-- graphic to match) and lives for the world's lifetime; it isn't tracked as a
-- body, so b2kClear leaves it in place.
command b2kWall pX1, pY1, pX2, pY2
   b2kEdge b2kToWorldX(pX1), b2kToWorldY(pY1), b2kToWorldX(pX2), b2kToWorldY(pY2)
end b2kWall

-- Remove every dynamic body (b2kRemove deletes kit-spawned controls; attached
-- controls are just detached). Sprites are Kit-created controls, so they go
-- too; loaded sheets stay (they are assets, not world state).
command b2kClear
   local tRef, tList, d
   b2kSpritesClear
   put empty into tList
   repeat for each key tRef in sBody
      if sStatic[tRef] is not true then put tRef & cr after tList
   end repeat
   repeat for each line d in tList
      if d is not empty then b2kRemove d
   end repeat
end b2kClear

-- =====================================================================
-- Configuration
-- =====================================================================
function b2kNumberOr pValue, pDefault
   if pValue is empty then return pDefault
   if pValue is not a number then return pDefault
   return pValue
end b2kNumberOr

function b2kClamp pValue, pLo, pHi
   local tValue
   put b2kNumberOr(pValue, pLo) into tValue
   if tValue < pLo then put pLo into tValue
   if tValue > pHi then put pHi into tValue
   return tValue
end b2kClamp

command b2kSetScale pPixelsPerMetre
   put b2kClamp(pPixelsPerMetre, 1, 10000) into sScale
end b2kSetScale

command b2kSetOrigin pScreenX, pScreenY
   put b2kNumberOr(pScreenX, sOriginX) into sOriginX
   put b2kNumberOr(pScreenY, sOriginY) into sOriginY
end b2kSetOrigin

command b2kSetGravity pGx, pGy
   put b2kNumberOr(pGx, 0) into pGx
   put b2kNumberOr(pGy, -10) into pGy
   if sWorld is not empty then b2SetGravity sWorld, pGx, pGy
end b2kSetGravity

command b2kSetSubsteps pN
   put round(b2kClamp(pN, 1, 64)) into sSub
end b2kSetSubsteps

-- World toggles: island sleeping (saves CPU) and continuous collision (CCD,
-- stops fast bodies tunnelling through thin walls).
command b2kEnableSleeping pFlag
   if sWorld is not empty then b2EnableSleeping sWorld, (pFlag is true)
end b2kEnableSleeping

command b2kEnableContinuous pFlag
   if sWorld is not empty then b2EnableContinuous sWorld, (pFlag is true)
end b2kEnableContinuous

command b2kContactTarget pObject
   put pObject into sContactObj
end b2kContactTarget

-- Object that receives an `on b2kFrame` message once per simulated frame (after
-- bodies are synced). Use it for per-frame logic: motors, custom drawing, input.
command b2kFrameTarget pObject
   put pObject into sFrameObj
end b2kFrameTarget

function b2kWorld
   return sWorld
end b2kWorld

-- Sanity check from kit-only code: returns the native shim's ABI version (4),
-- i.e. that the box2dxt extension and its native library are loaded and in sync.
function b2kVersion
   return b2Version()
end b2kVersion

-- =====================================================================
-- Coordinate conversion (sim Y up; screen Y down)
-- =====================================================================
function b2kToScreenX pWx
   return sOriginX + pWx * sScale
end b2kToScreenX

function b2kToScreenY pWy
   return sOriginY - pWy * sScale
end b2kToScreenY

function b2kToWorldX pSx
   if sScale is empty or sScale = 0 then return 0   -- before b2kSetup: stay safe
   return (pSx - sOriginX) / sScale
end b2kToWorldX

function b2kToWorldY pSy
   if sScale is empty or sScale = 0 then return 0
   return (sOriginY - pSy) / sScale
end b2kToWorldY

-- =====================================================================
-- Attaching existing controls (pDynamic defaults to true)
-- =====================================================================
command b2kAddBox pControl, pDynamic
   local tRef, tType, tFixed, tBody, tHw, tHh, tWx, tWy, tGraphic, tImage
   if sWorld is empty then return 0   -- attach needs a world (b2kSetup first)
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put ((the width of pControl) / 2) / sScale into tHw
   put ((the height of pControl) / 2) / sScale into tHh
   if tHw <= 0 or tHh <= 0 then return 0
   put b2kToWorldX(item 1 of the loc of pControl) into tWx
   put b2kToWorldY(item 2 of the loc of pControl) into tWy
   put (word 1 of tRef is "graphic") into tGraphic
   put (word 1 of tRef is "image") into tImage
   -- Graphics rotate as polygons; dynamic images rotate via `the angle`. Other
   -- control types (button, field, ...) can't be shown rotated, so we lock
   -- their rotation to keep the simulation consistent with the upright render.
   if tGraphic or (tImage and pDynamic) then put false into tFixed
   else put true into tFixed
   put b2NewBody(sWorld, tType, tWx, tWy, 0, false, tFixed) into tBody
   b2ShapeDefEnableSensorEvents true   -- so sensors can detect this shape
   put b2AddBox(tBody, tHw, tHh, 1.0, 0.4, 0.2) into sShapeH[tRef]
   b2kRegister tRef, tBody, (not pDynamic)
   if tGraphic and pDynamic then
      set the style of pControl to "polygon"
      put "poly" into sRender[tRef]
      put ("-" & tHw) & "," & ("-" & tHh) & cr & tHw & "," & ("-" & tHh) & cr \
            & tHw & "," & tHh & cr & ("-" & tHw) & "," & tHh into sVerts[tRef]
   else if tImage and pDynamic then
      put "image" into sRender[tRef]
   else
      put "loc" into sRender[tRef]
   end if
   -- Draw the new body NOW. The style switch above left a "poly" graphic with
   -- no points (invisible), and the move-event sync can't help: a world that
   -- isn't stepping emits no move events, so a part spawned while the loop is
   -- stopped would stay invisible until the first Run. Attach = visible.
   b2kDrawBody tRef, tWx, tWy, 0
   return tBody
end b2kAddBox

command b2kAddBall pControl, pDynamic
   local tRef, tType, tBody, tRad, tWx, tWy
   if sWorld is empty then return 0
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put ((the width of pControl) / 2) / sScale into tRad
   if tRad <= 0 then return 0
   put b2kToWorldX(item 1 of the loc of pControl) into tWx
   put b2kToWorldY(item 2 of the loc of pControl) into tWy
   put b2NewBody(sWorld, tType, tWx, tWy, 0, false, false) into tBody
   b2ShapeDefEnableSensorEvents true   -- so sensors can detect this shape
   put b2AddCircle(tBody, 0, 0, tRad, 1.0, 0.4, 0.4) into sShapeH[tRef]
   b2kRegister tRef, tBody, (not pDynamic)
   if word 1 of tRef is "graphic" then put "ball" into sRender[tRef]
   else if word 1 of tRef is "image" then put "image" into sRender[tRef]
   else put "loc" into sRender[tRef]
   put tRad into sRad[tRef]
   b2kDrawBody tRef, tWx, tWy, 0   -- visible at attach, even with the loop stopped
   return tBody
end b2kAddBall

-- Capsule ("pill"): the long side of the control's rect is the capsule axis,
-- the short side its diameter. Graphics render as a rounded outline (and rotate);
-- images rotate via `the angle`; other controls follow position upright.
command b2kAddCapsule pControl, pDynamic
   local tRef, tType, tFixed, tBody, tWx, tWy, tWm, tHm, tR, tL, tHoriz, tGraphic, tImage
   if sWorld is empty then return 0
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put (the width of pControl) / sScale into tWm
   put (the height of pControl) / sScale into tHm
   if tWm <= 0 or tHm <= 0 then return 0
   put (tWm >= tHm) into tHoriz
   if tHoriz then
      put tHm / 2 into tR
      put max(0, tWm / 2 - tR) into tL
   else
      put tWm / 2 into tR
      put max(0, tHm / 2 - tR) into tL
   end if
   put b2kToWorldX(item 1 of the loc of pControl) into tWx
   put b2kToWorldY(item 2 of the loc of pControl) into tWy
   put (word 1 of tRef is "graphic") into tGraphic
   put (word 1 of tRef is "image") into tImage
   if tGraphic or (tImage and pDynamic) then put false into tFixed
   else put true into tFixed
   put b2NewBody(sWorld, tType, tWx, tWy, 0, false, tFixed) into tBody
   b2ShapeDefEnableSensorEvents true   -- so sensors can detect this shape
   if tHoriz then
      put b2AddCapsule(tBody, - tL, 0, tL, 0, tR, 1.0, 0.4, 0.2) into sShapeH[tRef]
   else
      put b2AddCapsule(tBody, 0, - tL, 0, tL, tR, 1.0, 0.4, 0.2) into sShapeH[tRef]
   end if
   b2kRegister tRef, tBody, (not pDynamic)
   if tGraphic and pDynamic then
      set the style of pControl to "polygon"
      put "poly" into sRender[tRef]
      put b2kCapsuleVerts(tL, tR, tHoriz) into sVerts[tRef]
   else if tImage and pDynamic then
      put "image" into sRender[tRef]
   else
      put "loc" into sRender[tRef]
   end if
   -- Same as b2kAddBox: the freshly point-less "poly" graphic must be drawn
   -- here, because a stopped world never emits the move event that would.
   b2kDrawBody tRef, tWx, tWy, 0
   return tBody
end b2kAddCapsule

-- Build a body from a polygon graphic's own points (<= 8 vertices, convex).
command b2kAddPolygon pControl, pDynamic
   local tRef, tType, tBody, tCx, tCy, tWx, tWy, tPoints, p, tLocal, lx, ly, tCount
   if sWorld is empty then return 0
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put item 1 of the loc of pControl into tCx
   put item 2 of the loc of pControl into tCy
   put b2kToWorldX(tCx) into tWx
   put b2kToWorldY(tCy) into tWy
   put b2NewBody(sWorld, tType, tWx, tWy, 0, false, false) into tBody
   b2PolyBegin
   put empty into tLocal
   put 0 into tCount
   repeat for each line p in the points of pControl
      if p is empty then next repeat
      if tCount >= 8 then next repeat
      put (item 1 of p - tCx) / sScale into lx
      put - ((item 2 of p - tCy) / sScale) into ly
      b2PolyAddPoint lx, ly
      put lx & "," & ly & cr after tLocal
      add 1 to tCount
   end repeat
   if tCount < 3 then
      b2DestroyBody tBody
      return 0
   end if
   b2ShapeDefEnableSensorEvents true   -- so sensors can detect this shape
   put b2AddPolygon(tBody, 1.0, 0.4, 0.2) into sShapeH[tRef]
   b2kRegister tRef, tBody, (not pDynamic)
   put "poly" into sRender[tRef]
   put tLocal into sVerts[tRef]
   b2kDrawBody tRef, tWx, tWy, 0   -- visible at attach, even with the loop stopped
   return tBody
end b2kAddPolygon

command b2kAddStatic pControl
   b2kAddBox pControl, false
end b2kAddStatic

command b2kRegister pRef, pBody, pIsStatic
   put pBody into sBody[pRef]
   put pRef into sCtrl[pBody]
   put (pIsStatic is true) into sStatic[pRef]
end b2kRegister

-- =====================================================================
-- Spawning new controls (create + attach in one call). Returns control ref.
-- =====================================================================
command b2kSpawnBox pScreenX, pScreenY, pW, pH, pColor
   local tName, tRef
   if sWorld is empty then return empty   -- spawn needs a world (b2kSetup first)
   if pW is empty then put 40 into pW
   put b2kClamp(pW, 1, 10000) into pW
   if pH is empty then put pW into pH
   put b2kClamp(pH, 1, 10000) into pH
   put b2kNumberOr(pScreenX, sOriginX) into pScreenX
   put b2kNumberOr(pScreenY, sOriginY) into pScreenY
   put "b2kspawn_" & the milliseconds & "_" & random(1000000) into tName
   if sCamGroup is empty then
      create graphic (tName)
   else
      create graphic (tName) in group "b2kcam_view"
   end if
   put the long id of graphic (tName) into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then
      try
         set the backgroundColor of tRef to pColor
      catch tErr
         -- an unknown colour name (CSS names like "teal" are not LC/X11
         -- names) must not abort the spawn and orphan the control
      end try
   end if
   set the width of tRef to pW
   set the height of tRef to pH
   set the loc of tRef to round(pScreenX) & "," & round(pScreenY)
   b2kAddBox tRef
   put true into sSpawned[tRef]
   return tRef
end b2kSpawnBox

command b2kSpawnBall pScreenX, pScreenY, pDiameter, pColor
   local tName, tRef
   if sWorld is empty then return empty
   if pDiameter is empty then put 40 into pDiameter
   put b2kClamp(pDiameter, 1, 10000) into pDiameter
   put b2kNumberOr(pScreenX, sOriginX) into pScreenX
   put b2kNumberOr(pScreenY, sOriginY) into pScreenY
   put "b2kspawn_" & the milliseconds & "_" & random(1000000) into tName
   if sCamGroup is empty then
      create graphic (tName)
   else
      create graphic (tName) in group "b2kcam_view"
   end if
   put the long id of graphic (tName) into tRef
   set the style of tRef to "oval"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then
      try
         set the backgroundColor of tRef to pColor
      catch tErr
         -- an unknown colour name (CSS names like "teal" are not LC/X11
         -- names) must not abort the spawn and orphan the control
      end try
   end if
   set the width of tRef to pDiameter
   set the height of tRef to pDiameter
   set the loc of tRef to round(pScreenX) & "," & round(pScreenY)
   b2kAddBall tRef
   put true into sSpawned[tRef]
   return tRef
end b2kSpawnBall

-- Create a pill-shaped graphic and attach a capsule body. pLength is along the
-- pill's long axis, pThickness across it; horizontal if pLength >= pThickness.
command b2kSpawnCapsule pScreenX, pScreenY, pLength, pThickness, pColor
   local tName, tRef
   if sWorld is empty then return empty
   if pLength is empty then put 80 into pLength
   if pThickness is empty then put 40 into pThickness
   put b2kClamp(pLength, 1, 10000) into pLength
   put b2kClamp(pThickness, 1, 10000) into pThickness
   put b2kNumberOr(pScreenX, sOriginX) into pScreenX
   put b2kNumberOr(pScreenY, sOriginY) into pScreenY
   put "b2kspawn_" & the milliseconds & "_" & random(1000000) into tName
   if sCamGroup is empty then
      create graphic (tName)
   else
      create graphic (tName) in group "b2kcam_view"
   end if
   put the long id of graphic (tName) into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then
      try
         set the backgroundColor of tRef to pColor
      catch tErr
         -- an unknown colour name (CSS names like "teal" are not LC/X11
         -- names) must not abort the spawn and orphan the control
      end try
   end if
   if pLength >= pThickness then
      set the width of tRef to pLength
      set the height of tRef to pThickness
   else
      set the width of tRef to pThickness
      set the height of tRef to pLength
   end if
   set the loc of tRef to round(pScreenX) & "," & round(pScreenY)
   b2kAddCapsule tRef
   put true into sSpawned[tRef]
   return tRef
end b2kSpawnCapsule

-- =====================================================================
-- Materials & body properties
-- =====================================================================
command b2kSetBounce pControl, pRestitution
   local s
   put sShapeH[the long id of pControl] into s
   put b2kClamp(pRestitution, 0, 2) into pRestitution
   if s is not empty then b2SetShapeRestitution s, pRestitution
end b2kSetBounce

command b2kSetFriction pControl, pFriction
   local s
   put sShapeH[the long id of pControl] into s
   put b2kClamp(pFriction, 0, 10) into pFriction
   if s is not empty then b2SetShapeFriction s, pFriction
end b2kSetFriction

command b2kSetDensity pControl, pDensity
   local s
   put sShapeH[the long id of pControl] into s
   put b2kClamp(pDensity, 0, 10000) into pDensity
   if s is not empty then b2SetShapeDensity s, pDensity
end b2kSetDensity

-- Re-fit a body's collision shape to the control's CURRENT size, in place on the
-- SAME body so any joints stay valid. pShape is "box" | "ball" | "capsule" | "poly".
-- Resize the control's graphic first, then re-apply materials afterwards.
command b2kReshape pControl, pShape
   local tRef, tBody, tOld, tHw, tHh, tWm, tHm, tR, tL, tHoriz, tCx, tCy, p, lx, ly, tCount, tNewVerts
   local tWx, tWy, tWa
   put the long id of pControl into tRef
   if sBody[tRef] is empty then exit b2kReshape
   put sBody[tRef] into tBody
   -- Build the new shape first and drop the old one only afterwards, so the body
   -- is never momentarily shapeless and a rejected shape leaves the original
   -- intact (any joints on the body stay valid throughout).
   put sShapeH[tRef] into tOld
   put empty into sShapeH[tRef]
   b2ShapeDefEnableSensorEvents true   -- keep the reshaped body detectable by sensors
   if sSensor[tRef] is true then b2ShapeDefSensor true   -- a sensor stays a sensor after reshaping
   switch pShape
      case "ball"
         put ((the width of pControl) / 2) / sScale into tR
         if tR <= 0 then
            put tOld into sShapeH[tRef]
            b2ShapeDefReset   -- drop the pending one-shot flags set above
            exit b2kReshape
         end if
         put b2AddCircle(tBody, 0, 0, tR, 1.0, 0.4, 0.4) into sShapeH[tRef]
         put tR into sRad[tRef]
         break
      case "capsule"
         put (the width of pControl) / sScale into tWm
         put (the height of pControl) / sScale into tHm
         if tWm <= 0 or tHm <= 0 then
            put tOld into sShapeH[tRef]
            b2ShapeDefReset   -- drop the pending one-shot flags set above
            exit b2kReshape
         end if
         put (tWm >= tHm) into tHoriz
         if tHoriz then
            put tHm / 2 into tR
            put max(0, tWm / 2 - tR) into tL
            put b2AddCapsule(tBody, - tL, 0, tL, 0, tR, 1.0, 0.4, 0.2) into sShapeH[tRef]
         else
            put tWm / 2 into tR
            put max(0, tHm / 2 - tR) into tL
            put b2AddCapsule(tBody, 0, - tL, 0, tL, tR, 1.0, 0.4, 0.2) into sShapeH[tRef]
         end if
         put b2kCapsuleVerts(tL, tR, tHoriz) into sVerts[tRef]
         break
      case "poly"
         put item 1 of the loc of pControl into tCx
         put item 2 of the loc of pControl into tCy
         b2PolyBegin
         put empty into tNewVerts
         put 0 into tCount
         repeat for each line p in the points of pControl
            if p is empty then next repeat
            if tCount >= 8 then next repeat
            put (item 1 of p - tCx) / sScale into lx
            put - ((item 2 of p - tCy) / sScale) into ly
            b2PolyAddPoint lx, ly
            put lx & "," & ly & cr after tNewVerts
            add 1 to tCount
         end repeat
         if tCount < 3 then           -- degenerate outline: keep the existing shape
            put tOld into sShapeH[tRef]
            b2ShapeDefReset   -- drop the pending one-shot flags set above
            exit b2kReshape
         end if
         put b2AddPolygon(tBody, 1.0, 0.4, 0.2) into sShapeH[tRef]
         put tNewVerts into sVerts[tRef]
         break
      default
         put ((the width of pControl) / 2) / sScale into tHw
         put ((the height of pControl) / 2) / sScale into tHh
         if tHw <= 0 or tHh <= 0 then
            put tOld into sShapeH[tRef]
            b2ShapeDefReset   -- drop the pending one-shot flags set above
            exit b2kReshape
         end if
         put b2AddBox(tBody, tHw, tHh, 1.0, 0.4, 0.2) into sShapeH[tRef]
         if sRender[tRef] is "poly" then
            put ("-" & tHw) & "," & ("-" & tHh) & cr & tHw & "," & ("-" & tHh) & cr \
                  & tHw & "," & tHh & cr & ("-" & tHw) & "," & tHh into sVerts[tRef]
         end if
   end switch
   if tOld is not empty then b2DestroyShape tOld   -- now safe to release the old shape
   -- The size/outline changed but the body need not have moved, so the move-event
   -- sync would skip it (an at-rest body produces no move event). Bust the
   -- pose-keyed draw cache and redraw at the body's current pose right now so the
   -- new shape is visible immediately, awake or asleep.
   delete variable sDrawKey[tRef]
   put b2BodyX(tBody) into tWx
   put b2BodyY(tBody) into tWy
   if sRender[tRef] is "poly" or sRender[tRef] is "image" then put b2BodyAngle(tBody) into tWa
   else put 0 into tWa
   lock screen
   b2kDrawBody tRef, tWx, tWy, tWa
   unlock screen
end b2kReshape

-- Every body-targeting wrapper resolves the control's body first and quietly
-- no-ops when there is none (unregistered, removed, or pre-setup): the kit's
-- contract is that a missing body is never a script error.
command b2kSetBullet pControl, pFlag
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetBullet
   b2SetBullet b, (pFlag is true)
end b2kSetBullet

command b2kSetFixedRotation pControl, pFlag
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetFixedRotation
   b2SetFixedRotation b, (pFlag is true)
end b2kSetFixedRotation

command b2kSetGravityScale pControl, pScale
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetGravityScale
   b2SetGravityScale b, pScale
end b2kSetGravityScale

command b2kSetDamping pControl, pLinear, pAngular
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetDamping
   if pLinear is not empty then b2SetLinearDamping b, pLinear
   if pAngular is not empty then b2SetAngularDamping b, pAngular
end b2kSetDamping

command b2kWake pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kWake
   b2SetAwake b, true
end b2kWake

-- Send a body to sleep (it stops simulating until something wakes it).
command b2kSleep pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSleep
   b2SetAwake b, false
end b2kSleep

-- Below this speed (pixels/sec) a body may fall asleep. Lower = stays awake
-- longer; higher = sleeps sooner (saves CPU).
command b2kSetSleepThreshold pControl, pPxPerSec
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetSleepThreshold
   b2SetSleepThreshold b, pPxPerSec / sScale
end b2kSetSleepThreshold

-- =====================================================================
-- Acting on bodies   (velocities/kicks are in PIXELS/sec, screen-oriented)
-- =====================================================================
command b2kSetVelocity pControl, pVxPx, pVyPx
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSetVelocity
   b2SetVelocity b, pVxPx / sScale, - pVyPx / sScale
end b2kSetVelocity

command b2kPush pControl, pDvxPx, pDvyPx
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kPush
   b2SetVelocity b, b2BodyVX(b) + pDvxPx / sScale, b2BodyVY(b) - pDvyPx / sScale
   b2SetAwake b, true
end b2kPush

command b2kSpin pControl, pDegPerSec
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSpin
   b2SetAngularVelocity b, pDegPerSec * kPI / 180
end b2kSpin

-- Add to the current spin (vs b2kSpin which sets it absolutely).
command b2kSpinBy pControl, pDegPerSec
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kSpinBy
   b2SetAngularVelocity b, b2BodyAngularVelocity(b) + pDegPerSec * kPI / 180
   b2SetAwake b, true
end b2kSpinBy

-- Continuous, screen-oriented force (thrusters, wind). Apply each frame for a
-- sustained effect; b2kPush is the one-shot impulse equivalent.
command b2kForce pControl, pFxPx, pFyPx
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kForce
   b2ApplyForce b, pFxPx / sScale, - pFyPx / sScale, true
end b2kForce

-- A one-shot impulse (a sharp kick), screen-oriented. Mass-aware: heavier bodies
-- move less. b2kPush changes velocity directly; this is the impulse equivalent.
command b2kImpulse pControl, pIxPx, pIyPx
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kImpulse
   b2ApplyImpulse b, pIxPx / sScale, - pIyPx / sScale, true
end b2kImpulse

-- A continuous turning force (same units as motor torque). Positive turns one way,
-- negative the other. Apply each frame for a sustained twist; pairs with b2kForce.
command b2kTorque pControl, pTorque
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kTorque
   b2ApplyTorque b, pTorque, true
end b2kTorque

-- A one-shot twist (a sharp angular kick), mass-aware: bodies with more
-- rotational inertia turn less. b2kSpinBy sets the spin directly; this is the
-- impulse equivalent, and the angular partner of b2kImpulse.
command b2kAngularImpulse pControl, pImpulse
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kAngularImpulse
   b2ApplyAngularImpulse b, pImpulse, true
end b2kAngularImpulse

-- Change a body's type at runtime: "static", "kinematic", or "dynamic".
command b2kSetType pControl, pType
   local tRef, tCode
   put the long id of pControl into tRef
   if sBody[tRef] is empty then exit b2kSetType
   switch pType
      case "static"
         put 0 into tCode
         break
      case "kinematic"
         put 1 into tCode
         break
      default
         put 2 into tCode
   end switch
   b2SetBodyType sBody[tRef], tCode
   put (tCode is 0) into sStatic[tRef]   -- only true statics are skipped by sync
   if tCode is not 0 then b2SetAwake sBody[tRef], true
   put true into sNeedFullSync
end b2kSetType

command b2kSetStatic pControl
   b2kSetType pControl, "static"
end b2kSetStatic

command b2kSetDynamic pControl
   b2kSetType pControl, "dynamic"
end b2kSetDynamic

command b2kSetKinematic pControl
   b2kSetType pControl, "kinematic"
end b2kSetKinematic

-- Temporarily take a body out of / put it back into the simulation.
command b2kDisable pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kDisable
   b2DisableBody b
end b2kDisable

command b2kEnable pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then exit b2kEnable
   b2EnableBody b
   put true into sNeedFullSync
end b2kEnable

command b2kMoveTo pControl, pScreenX, pScreenY, pAngleDeg
   local tRef, tWx, tWy, tWa
   if pAngleDeg is empty then put 0 into pAngleDeg
   put the long id of pControl into tRef
   if sBody[tRef] is empty then exit b2kMoveTo
   put b2kToWorldX(pScreenX) into tWx
   put b2kToWorldY(pScreenY) into tWy
   put pAngleDeg * kPI / 180 into tWa
   b2SetTransform sBody[tRef], tWx, tWy, tWa
   b2kDrawBody tRef, tWx, tWy, tWa
end b2kMoveTo

command b2kRemove pControl
   local tRef, tBody, tWasSpawned
   put the long id of pControl into tRef
   put sBody[tRef] into tBody
   if tBody is not empty and tBody > 0 then
      b2DestroyBody tBody
      delete variable sCtrl[tBody]
   end if
   put (sSpawned[tRef] is true) into tWasSpawned
   delete variable sBody[tRef]
   delete variable sShapeH[tRef]
   delete variable sRender[tRef]
   delete variable sVerts[tRef]
   delete variable sRad[tRef]
   delete variable sImgAngle[tRef]
   delete variable sStatic[tRef]
   delete variable sSpawned[tRef]
   delete variable sSensor[tRef]
   -- If the kit created this control (b2kSpawn...), delete it too, so removing
   -- a body never leaves a dead graphic behind. Attached controls are left alone.
   if tWasSpawned then
      try
         delete tRef
      end try
   end if
end b2kRemove

-- A radial "blast" that kicks nearby dynamic bodies outward. Uses Box2D's native
-- b2World_Explode: it's shape-perimeter aware (so a wide plank catches more blast
-- than a small ball) and affects EVERY dynamic body in range, not just kit ones.
-- pPowerPx is the impulse per unit length of facing surface; pRadiusPx the reach.
command b2kExplode pScreenX, pScreenY, pRadiusPx, pPowerPx
   if pRadiusPx is empty then put 180 into pRadiusPx
   if pPowerPx is empty then put 900 into pPowerPx
   if sWorld is empty then exit b2kExplode
   b2WorldExplode sWorld, b2kToWorldX(pScreenX), b2kToWorldY(pScreenY), \
         pRadiusPx / sScale, (pRadiusPx / sScale) * 0.5, pPowerPx / sScale
end b2kExplode

-- The original velocity-based blast (pre-v3): kicks only kit-tracked dynamic
-- bodies, ignoring their size. Kept for callers that relied on the old feel.
command b2kExplodeLegacy pScreenX, pScreenY, pRadiusPx, pPowerPx
   local cx, cy, tRadM, tRef, b, dx, dy, d, f
   if pRadiusPx is empty then put 180 into pRadiusPx
   if pPowerPx is empty then put 900 into pPowerPx
   put b2kToWorldX(pScreenX) into cx
   put b2kToWorldY(pScreenY) into cy
   put pRadiusPx / sScale into tRadM
   repeat for each key tRef in sBody
      if sStatic[tRef] is true then next repeat
      put sBody[tRef] into b
      put b2BodyX(b) - cx into dx
      put b2BodyY(b) - cy into dy
      put sqrt(dx * dx + dy * dy) into d
      if d > 0.02 and d < tRadM then
         put (1 - d / tRadM) * (pPowerPx / sScale) into f
         b2SetVelocity b, b2BodyVX(b) + dx / d * f, b2BodyVY(b) + dy / d * f
         b2SetAwake b, true
      end if
   end repeat
end b2kExplodeLegacy

-- =====================================================================
-- Getters
-- =====================================================================
function b2kBodyOf pControl
   return sBody[the long id of pControl]
end b2kBodyOf

-- A body's position in SCREEN pixels as "x,y" (the position partner of
-- b2kVelocity). Controls already follow their body, but this reads the exact,
-- sub-pixel centre — handy for aiming, distance checks, or mixing with b2…
function b2kPosition pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return "0,0"
   return b2kToScreenX(b2BodyX(b)) & "," & b2kToScreenY(b2BodyY(b))
end b2kPosition

-- A body's centre of mass in SCREEN pixels as "x,y". Differs from b2kPosition
-- for off-centre or compound shapes; it's the true pivot for spin and torque.
function b2kWorldCenter pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return "0,0"
   return b2kToScreenX(b2BodyWorldCenterX(b)) & "," & b2kToScreenY(b2BodyWorldCenterY(b))
end b2kWorldCenter

function b2kVelocity pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return "0,0"
   return (b2BodyVX(b) * sScale) & "," & (- b2BodyVY(b) * sScale)
end b2kVelocity

function b2kSpeed pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return 0
   return sqrt((b2BodyVX(b) * sScale) ^ 2 + (b2BodyVY(b) * sScale) ^ 2)
end b2kSpeed

function b2kAngle pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return 0
   return b2BodyAngle(b) * 180 / kPI
end b2kAngle

function b2kIsAwake pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return false
   return b2BodyIsAwake(b)
end b2kIsAwake

-- Current rotation speed in DEGREES/sec (the getter for b2kSpin / b2kSpinBy).
function b2kSpinRate pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return 0
   return b2BodyAngularVelocity(b) * 180 / kPI
end b2kSpinRate

function b2kIsBullet pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return false
   return b2BodyIsBullet(b)
end b2kIsBullet

function b2kIsEnabled pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return false
   return b2BodyIsEnabled(b)
end b2kIsEnabled

function b2kMass pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return 0
   return b2BodyMass(b)
end b2kMass

-- The body's per-body gravity multiplier (the getter for b2kSetGravityScale).
function b2kGravityScale pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return 0
   return b2BodyGravityScale(b)
end b2kGravityScale

-- The body's drag as "linear,angular" (the getter for b2kSetDamping).
function b2kDamping pControl
   local b
   put sBody[the long id of pControl] into b
   if b is empty then return "0,0"
   return b2BodyLinearDamping(b) & "," & b2BodyAngularDamping(b)
end b2kDamping

-- Body type as a word: "static", "kinematic", or "dynamic" (mirrors b2kSetType).
function b2kBodyType pControl
   local b, tCode
   put sBody[the long id of pControl] into b
   if b is empty then return "static"
   put b2BodyType(b) into tCode
   if tCode is 1 then return "kinematic"
   if tCode is 2 then return "dynamic"
   return "static"
end b2kBodyType

-- How many bodies the kit is currently tracking.
function b2kBodyCount
   return the number of lines of the keys of sBody
end b2kBodyCount

-- How many dynamic bodies are currently awake (i.e. actively simulating).
function b2kAwakeCount
   local tRef, tCount
   put 0 into tCount
   repeat for each key tRef in sBody
      if sStatic[tRef] is not true and b2BodyIsAwake(sBody[tRef]) then add 1 to tCount
   end repeat
   return tCount
end b2kAwakeCount

-- Which attached control sits at a screen point (empty if none).
function b2kControlAt pScreenX, pScreenY
   if sWorld is empty then return empty
   return sCtrl[b2BodyAtPoint(sWorld, b2kToWorldX(pScreenX), b2kToWorldY(pScreenY))]
end b2kControlAt

-- True if SCREEN point (x,y) is inside this control's actual collision shape —
-- rotation- and shape-aware, unlike a bounding-box test. b2kControlAt searches
-- every body; this tests one control you already have (e.g. a precise click hit).
function b2kControlContains pControl, pScreenX, pScreenY
   local tRef
   put the long id of pControl into tRef
   if sShapeH[tRef] is empty then return false
   return b2ShapeTestPoint(sShapeH[tRef], b2kToWorldX(pScreenX), b2kToWorldY(pScreenY))
end b2kControlContains

-- Cast a ray between two screen points; returns the control hit (or empty).
-- Then b2kRayHitX() / b2kRayHitY() give the hit point in screen pixels.
function b2kRayHit pX1, pY1, pX2, pY2
   local dx, dy
   if sWorld is not empty and \
         b2CastRayClosest(sWorld, b2kToWorldX(pX1), b2kToWorldY(pY1), b2kToWorldX(pX2), b2kToWorldY(pY2)) then
      put round(b2kToScreenX(b2RayX())) into sRayX
      put round(b2kToScreenY(b2RayY())) into sRayY
      put b2RayNormalX() into sRayNX        -- surface normal, screen-oriented
      put - b2RayNormalY() into sRayNY
      put pX2 - pX1 into dx
      put pY2 - pY1 into dy
      put b2RayFraction() * sqrt(dx * dx + dy * dy) into sRayDist
      return sCtrl[b2RayBody()]
   end if
   put empty into sRayX
   put empty into sRayY
   put empty into sRayNX
   put empty into sRayNY
   put empty into sRayDist
   return empty
end b2kRayHit

function b2kRayHitX
   return sRayX
end b2kRayHitX

function b2kRayHitY
   return sRayY
end b2kRayHitY

-- Surface normal (a unit direction, screen-oriented) at the last ray hit.
function b2kRayHitNormalX
   return sRayNX
end b2kRayHitNormalX

function b2kRayHitNormalY
   return sRayNY
end b2kRayHitNormalY

-- Distance in pixels from the ray's start to the last hit point.
function b2kRayDist
   return sRayDist
end b2kRayDist

-- ---- contacts, polling style ----------------------------------------
-- The kit also SENDS `on b2kContact` / `on b2kEndContact` to your
-- b2kContactTarget. These functions instead let you POLL the same per-frame
-- snapshot (e.g. from `on b2kFrame`) without registering a target. The snapshot
-- refreshes once per simulated step; indices are 1-based. Each accessor returns
-- the touching control's long id (empty for a wall, the ground, or any body the
-- kit isn't tracking).
function b2kContactCount
   return b2ContactBeginCount()
end b2kContactCount

function b2kContactA pIndex
   return sCtrl[b2ContactBeginBodyA(pIndex)]
end b2kContactA

function b2kContactB pIndex
   return sCtrl[b2ContactBeginBodyB(pIndex)]
end b2kContactB

function b2kEndContactCount
   return b2ContactEndCount()
end b2kEndContactCount

function b2kEndContactA pIndex
   return sCtrl[b2ContactEndBodyA(pIndex)]
end b2kEndContactA

function b2kEndContactB pIndex
   return sCtrl[b2ContactEndBodyB(pIndex)]
end b2kEndContactB

-- =====================================================================
-- Joints (return a joint handle; pass it to b2kMotor / b2kRemoveJoint)
-- =====================================================================
-- Revolute pivot at screen point (x,y). If ctrlB is empty, pins ctrlA to the
-- world at that point (great for pendulums and swinging doors).
command b2kHinge pCtrlA, pCtrlB, pScreenX, pScreenY
   local bA, bB, wx, wy, aA, aB, j
   put sBody[the long id of pCtrlA] into bA
   if bA is empty or sWorld is empty then return 0
   if pCtrlB is not empty and sBody[the long id of pCtrlB] is empty then return 0
   put b2kToWorldX(pScreenX) into wx
   put b2kToWorldY(pScreenY) into wy
   put b2kLocalAnchor(bA, wx, wy) into aA
   if pCtrlB is empty then
      put sDragAnchor into bB
      put wx & "," & wy into aB
   else
      put sBody[the long id of pCtrlB] into bB
      put b2kLocalAnchor(bB, wx, wy) into aB
   end if
   put b2RevoluteJoint(sWorld, bA, bB, item 1 of aA, item 2 of aA, item 1 of aB, item 2 of aB, false) into j
   return j
end b2kHinge

command b2kWeld pCtrlA, pCtrlB
   local bA, bB, wx, wy, aA, refA, j
   put sBody[the long id of pCtrlA] into bA
   put sBody[the long id of pCtrlB] into bB
   if bA is empty or bB is empty or sWorld is empty then return 0
   put b2BodyX(bB) into wx
   put b2BodyY(bB) into wy
   put b2kLocalAnchor(bA, wx, wy) into aA
   put b2BodyAngle(bB) - b2BodyAngle(bA) into refA
   put b2WeldJoint(sWorld, bA, bB, item 1 of aA, item 2 of aA, 0, 0, refA, false) into j
   return j
end b2kWeld

-- Distance link. pLengthPx defaults to the current distance between centres.
command b2kRope pCtrlA, pCtrlB, pLengthPx
   local bA, bB, tLen, dx, dy, j
   put sBody[the long id of pCtrlA] into bA
   put sBody[the long id of pCtrlB] into bB
   if bA is empty or bB is empty or sWorld is empty then return 0
   if pLengthPx is empty then
      put b2BodyX(bB) - b2BodyX(bA) into dx
      put b2BodyY(bB) - b2BodyY(bA) into dy
      put sqrt(dx * dx + dy * dy) into tLen
   else
      put pLengthPx / sScale into tLen
   end if
   put b2DistanceJoint(sWorld, bA, bB, 0, 0, 0, 0, tLen, false) into j
   return j
end b2kRope

command b2kMotor pJoint, pDegPerSec, pMaxTorque
   if pJoint is empty or pJoint <= 0 then exit b2kMotor
   if pMaxTorque is empty then put 1000 into pMaxTorque
   b2RevoluteEnableMotor pJoint, true, pDegPerSec * kPI / 180, pMaxTorque
end b2kMotor

-- Optional revolute (hinge) limits/readout. Angles are in DEGREES.
command b2kHingeLimit pJoint, pLowerDeg, pUpperDeg
   if pJoint is empty or pJoint <= 0 then exit b2kHingeLimit
   b2RevoluteEnableLimit pJoint, true, pLowerDeg * kPI / 180, pUpperDeg * kPI / 180
end b2kHingeLimit

function b2kHingeAngle pJoint
   if pJoint is empty or pJoint <= 0 then return 0
   return b2RevoluteAngle(pJoint) * 180 / kPI
end b2kHingeAngle

-- Rope (distance) extras: read length, set a min/max range, make it springy.
function b2kRopeLength pJoint
   if pJoint is empty or pJoint <= 0 then return 0
   return b2DistanceLength(pJoint) * sScale
end b2kRopeLength

-- Set a rope (distance) joint's exact rest length, in pixels.
command b2kRopeSetLength pJoint, pLengthPx
   if pJoint is empty or pJoint <= 0 then exit b2kRopeSetLength
   b2DistanceSetLength pJoint, pLengthPx / sScale
end b2kRopeSetLength

command b2kRopeRange pJoint, pMinPx, pMaxPx
   if pJoint is empty or pJoint <= 0 then exit b2kRopeRange
   b2DistanceSetLengthRange pJoint, pMinPx / sScale, pMaxPx / sScale
end b2kRopeRange

command b2kSpring pJoint, pHertz, pDamping
   if pJoint is empty or pJoint <= 0 then exit b2kSpring
   if pDamping is empty then put 0.5 into pDamping
   b2DistanceEnableSpring pJoint, true, pHertz, pDamping
end b2kSpring

-- Make a weld springy (0 hertz = rigid again).
command b2kWeldSpring pJoint, pHertz, pDamping
   if pJoint is empty or pJoint <= 0 then exit b2kWeldSpring
   if pDamping is empty then put 0.5 into pDamping
   b2WeldSetStiffness pJoint, pHertz, pDamping, pHertz, pDamping
end b2kWeldSpring

-- Slider (prismatic): constrain pCtrlA to slide along an axis relative to
-- pCtrlB (or the world if empty). pAxisDeg is the on-screen slide direction
-- (0 = horizontal, 90 = vertical; default vertical). Drive it with b2kSliderMotor.
command b2kSlider pCtrlA, pCtrlB, pAxisDeg
   local bMover, bFixed, wax, way, ca, sa, lax, lay, anchX, anchY, aFix, aMov, refA, fixAng, j
   put sBody[the long id of pCtrlA] into bMover
   if pCtrlB is empty then put sDragAnchor into bFixed
   else put sBody[the long id of pCtrlB] into bFixed
   if bMover is empty or bFixed is empty or sWorld is empty then return 0
   if pAxisDeg is empty then put 90 into pAxisDeg
   put cos(pAxisDeg * kPI / 180) into wax
   put - sin(pAxisDeg * kPI / 180) into way
   put b2BodyAngle(bFixed) into fixAng
   put cos(- fixAng) into ca
   put sin(- fixAng) into sa
   put wax * ca - way * sa into lax
   put wax * sa + way * ca into lay
   put b2BodyX(bMover) into anchX
   put b2BodyY(bMover) into anchY
   put b2kLocalAnchor(bFixed, anchX, anchY) into aFix
   put b2kLocalAnchor(bMover, anchX, anchY) into aMov
   put b2BodyAngle(bMover) - fixAng into refA
   put b2PrismaticJoint(sWorld, bFixed, bMover, item 1 of aFix, item 2 of aFix, \
         item 1 of aMov, item 2 of aMov, lax, lay, refA, false) into j
   return j
end b2kSlider

command b2kSliderMotor pJoint, pPxPerSec, pMaxForce
   if pJoint is empty or pJoint <= 0 then exit b2kSliderMotor
   if pMaxForce is empty then put 1000 into pMaxForce
   b2PrismaticEnableMotor pJoint, true, pPxPerSec / sScale, pMaxForce
end b2kSliderMotor

command b2kSliderLimit pJoint, pLowerPx, pUpperPx
   if pJoint is empty or pJoint <= 0 then exit b2kSliderLimit
   b2PrismaticEnableLimit pJoint, true, pLowerPx / sScale, pUpperPx / sScale
end b2kSliderLimit

function b2kSliderPos pJoint
   if pJoint is empty or pJoint <= 0 then return 0
   return b2PrismaticTranslation(pJoint) * sScale
end b2kSliderPos

-- Wheel: a sprung sliding axis + free spin (vehicle wheels). pChassis carries
-- pWheel; anchor defaults to the wheel's centre, suspension axis to world "up".
-- Drive with b2kWheelMotor, tune ride with b2kWheelSpring.
command b2kWheel pChassis, pWheel, pScreenX, pScreenY, pAxisDeg
   local bA, bB, anchX, anchY, aA, aB, wax, way, ca, sa, lax, lay, angA, j
   put sBody[the long id of pChassis] into bA
   put sBody[the long id of pWheel] into bB
   if bA is empty or bB is empty or sWorld is empty then return 0
   if pScreenX is empty then
      put b2BodyX(bB) into anchX
      put b2BodyY(bB) into anchY
   else
      put b2kToWorldX(pScreenX) into anchX
      put b2kToWorldY(pScreenY) into anchY
   end if
   if pAxisDeg is empty then
      put 0 into wax
      put 1 into way
   else
      put cos(pAxisDeg * kPI / 180) into wax
      put - sin(pAxisDeg * kPI / 180) into way
   end if
   put b2BodyAngle(bA) into angA
   put cos(- angA) into ca
   put sin(- angA) into sa
   put wax * ca - way * sa into lax
   put wax * sa + way * ca into lay
   put b2kLocalAnchor(bA, anchX, anchY) into aA
   put b2kLocalAnchor(bB, anchX, anchY) into aB
   put b2WheelJoint(sWorld, bA, bB, item 1 of aA, item 2 of aA, \
         item 1 of aB, item 2 of aB, lax, lay, false) into j
   return j
end b2kWheel

command b2kWheelMotor pJoint, pDegPerSec, pMaxTorque
   if pJoint is empty or pJoint <= 0 then exit b2kWheelMotor
   if pMaxTorque is empty then put 1000 into pMaxTorque
   b2WheelEnableMotor pJoint, true, pDegPerSec * kPI / 180, pMaxTorque
end b2kWheelMotor

command b2kWheelSpring pJoint, pHertz, pDamping
   if pJoint is empty or pJoint <= 0 then exit b2kWheelSpring
   if pHertz is empty then put 4 into pHertz
   if pDamping is empty then put 0.7 into pDamping
   b2WheelEnableSpring pJoint, true, pHertz, pDamping
end b2kWheelSpring

-- OFF switches: the b2k… joint wrappers above only ever turn a feature ON, so
-- these let callers disable a motor or limit again (free swing / unbounded slide).
command b2kMotorOff pJoint
   if pJoint is not empty and pJoint > 0 then b2RevoluteEnableMotor pJoint, false, 0, 0
end b2kMotorOff

command b2kHingeLimitOff pJoint
   if pJoint is not empty and pJoint > 0 then b2RevoluteEnableLimit pJoint, false, 0, 0
end b2kHingeLimitOff

command b2kSliderMotorOff pJoint
   if pJoint is not empty and pJoint > 0 then b2PrismaticEnableMotor pJoint, false, 0, 0
end b2kSliderMotorOff

command b2kSliderLimitOff pJoint
   if pJoint is not empty and pJoint > 0 then b2PrismaticEnableLimit pJoint, false, 0, 0
end b2kSliderLimitOff

command b2kWheelMotorOff pJoint
   if pJoint is not empty and pJoint > 0 then b2WheelEnableMotor pJoint, false, 0, 0
end b2kWheelMotorOff

command b2kRemoveJoint pJoint
   if pJoint is not empty and pJoint > 0 then b2DestroyJoint pJoint
end b2kRemoveJoint

function b2kLocalAnchor pBody, pWx, pWy
   local bcx, bcy, ba, dx, dy, c, s
   put b2BodyX(pBody) into bcx
   put b2BodyY(pBody) into bcy
   put b2BodyAngle(pBody) into ba
   put pWx - bcx into dx
   put pWy - bcy into dy
   put cos(- ba) into c
   put sin(- ba) into s
   return (dx * c - dy * s) & "," & (dx * s + dy * c)
end b2kLocalAnchor

-- =====================================================================
-- Sensors (non-solid trigger zones)
-- =====================================================================
-- Attach a SENSOR fixture to a control: it reports overlaps but never blocks.
-- Static by default (a fixed trigger zone); pShape is "box" (default), "ball" or
-- "capsule". While the loop runs, overlaps are delivered to your b2kContactTarget
-- as `on b2kSensorEnter pSensorCtrl, pVisitorCtrl` / `on b2kSensorExit ...`. The
-- kit enables sensor events on every body it creates, so sensors detect them.
command b2kAddSensor pControl, pShape
   local tRef
   if sWorld is empty then return 0
   put the long id of pControl into tRef
   b2ShapeDefSensor true
   b2ShapeDefEnableSensorEvents true
   switch pShape
      case "ball"
         b2kAddBall pControl, false
         break
      case "capsule"
         b2kAddCapsule pControl, false
         break
      default
         b2kAddBox pControl, false
   end switch
   if sBody[tRef] is empty then
      -- the attach bailed (zero-sized control): clear the pending one-shot
      -- sensor flags so they cannot leak onto the next shape someone creates
      b2ShapeDefReset
      return 0
   end if
   put true into sSensor[tRef]
   return sBody[tRef]
end b2kAddSensor

-- Flip a control's collision between solid and SENSOR (a non-solid trigger that
-- reports overlaps but never blocks). The flag lives on the shape, so rebuild the
-- shape afterwards with b2kReshape — it re-applies the sensor state from here.
command b2kSetSensor pControl, pFlag
   put (pFlag is true) into sSensor[the long id of pControl]
end b2kSetSensor

-- Polling alternative to the on b2kSensorEnter/Exit messages (read in on b2kFrame).
-- Counts/indices are 1-based; each returns a control (empty for untracked bodies).
function b2kSensorCount
   return b2SensorBeginCount()
end b2kSensorCount
function b2kSensorEnterSensor pIndex
   return sCtrl[b2ShapeBody(b2SensorBeginSensorShape(pIndex))]
end b2kSensorEnterSensor
function b2kSensorEnterVisitor pIndex
   return sCtrl[b2ShapeBody(b2SensorBeginVisitorShape(pIndex))]
end b2kSensorEnterVisitor
function b2kSensorExitCount
   return b2SensorEndCount()
end b2kSensorExitCount
function b2kSensorExitSensor pIndex
   return sCtrl[b2ShapeBody(b2SensorEndSensorShape(pIndex))]
end b2kSensorExitSensor
function b2kSensorExitVisitor pIndex
   return sCtrl[b2ShapeBody(b2SensorEndVisitorShape(pIndex))]
end b2kSensorExitVisitor

-- =====================================================================
-- Collision filtering (named layers; up to 32)
-- =====================================================================
-- Define (or fetch) a named collision layer, returning its bit value. Then
-- b2kSetCategory / b2kSetMask take a comma- or space-separated list of layer
-- names (or raw numbers). Two shapes collide only if EACH one's category appears
-- in the other's mask (and no shared negative group forbids it).
command b2kDefineLayer pName
   if sLayers[pName] is not empty then return sLayers[pName]
   if sNextBit is empty or sNextBit < 1 then put 1 into sNextBit
   -- xTalk's bitOr is 32-bit, so layer 33+ would wrap to a category of 0
   -- (= collides with nothing). Refuse instead of corrupting filters.
   if sNextBit > 2147483648 then return 0
   put sNextBit into sLayers[pName]
   put sNextBit * 2 into sNextBit
   return sLayers[pName]
end b2kDefineLayer

function b2kLayerBits pLayerList
   local tBits, tL
   put 0 into tBits
   replace comma with space in pLayerList
   repeat for each word tL in pLayerList
      if tL is empty then next repeat
      if tL is a number then
         put tBits bitOr (tL) into tBits
      else
         -- b2kDefineLayer is a COMMAND: OXT cannot call commands with
         -- function syntax, so invoke it as a statement and read the result
         b2kDefineLayer tL
         put tBits bitOr (the result) into tBits
      end if
   end repeat
   return tBits
end b2kLayerBits

command b2kSetCategory pControl, pLayerList
   local s
   put sShapeH[the long id of pControl] into s
   if s is empty then exit b2kSetCategory
   b2SetShapeFilter s, b2kLayerBits(pLayerList), b2ShapeFilterMask(s), b2ShapeFilterGroup(s)
end b2kSetCategory

command b2kSetMask pControl, pLayerList
   local s
   put sShapeH[the long id of pControl] into s
   if s is empty then exit b2kSetMask
   b2SetShapeFilter s, b2ShapeFilterCategory(s), b2kLayerBits(pLayerList), b2ShapeFilterGroup(s)
end b2kSetMask

-- Group index: bodies sharing a NEGATIVE group never collide; a POSITIVE group
-- always collide. Overrides category/mask. 0 (default) = use category/mask.
command b2kSetCollisionGroup pControl, pGroup
   local s
   put sShapeH[the long id of pControl] into s
   if s is empty then exit b2kSetCollisionGroup
   b2SetShapeFilter s, b2ShapeFilterCategory(s), b2ShapeFilterMask(s), pGroup
end b2kSetCollisionGroup

-- =====================================================================
-- Chains (smooth terrain) and world queries
-- =====================================================================
-- A smooth static chain (ground/terrain) from a list of SCREEN points ("x,y" per
-- line). Unlike joined box/segment edges it has no inner corners for fast bodies
-- to catch on. Needs >= 4 points; pLoop true closes it. Invisible (draw a matching
-- graphic). Returns a chain handle (b2DestroyChain to remove).
command b2kChain pPoints, pLoop
   local tBody, p
   if sWorld is empty then return 0
   put b2NewStaticBody(sWorld, 0, 0) into tBody
   b2ChainBegin
   repeat for each line p in pPoints
      if p is empty then next repeat
      b2ChainAddPoint b2kToWorldX(item 1 of p), b2kToWorldY(item 2 of p)
   end repeat
   return b2CreateChain(tBody, (pLoop is true), 0.6, 0.1)
end b2kChain

command b2kSmoothGround pPoints
   -- statement call + the result: OXT cannot call commands function-style
   b2kChain pPoints, false
   return the result
end b2kSmoothGround

-- Attach a smooth static chain to a CONTROL, from a list of SCREEN points
-- ("x,y" per line) — the control's own outline. Unlike b2kChain (which makes an
-- untracked world body), this registers the body against the control like
-- b2kAddBox/Ball/Polygon, so it selects (b2kControlAt), drags (b2kMoveTo) and
-- removes (b2kRemove) as a normal static part. The points are taken relative to
-- the control's centre, so moving the control moves the terrain with it. pLoop
-- true closes the outline into a solid blob; false leaves a one-sided ground
-- line. Great for smooth, rolling, concave terrain a fast body won't catch on.
command b2kAddChain pControl, pPoints, pLoop
   local tRef, tCx, tCy, tBody, p, lx, ly
   if sWorld is empty then return 0
   put the long id of pControl into tRef
   put item 1 of the loc of pControl into tCx
   put item 2 of the loc of pControl into tCy
   put b2NewStaticBody(sWorld, b2kToWorldX(tCx), b2kToWorldY(tCy)) into tBody
   b2ChainBegin
   repeat for each line p in pPoints
      if p is empty then next repeat
      put (item 1 of p - tCx) / sScale into lx          -- local to the control's centre
      put - ((item 2 of p - tCy) / sScale) into ly
      b2ChainAddPoint lx, ly
   end repeat
   get b2CreateChain(tBody, (pLoop is true), 0.6, 0.1)
   b2kRegister tRef, tBody, true                        -- static, kit-tracked
   put "loc" into sRender[tRef]                          -- static: registered but never synced
   return tBody
end b2kAddChain

-- Controls whose body overlaps a screen RECT (newline-separated long ids).
function b2kOverlap pX1, pY1, pX2, pY2
   if sWorld is empty then return empty
   return b2kQueryToControls(b2OverlapAABB(sWorld, b2kToWorldX(pX1), b2kToWorldY(pY1), b2kToWorldX(pX2), b2kToWorldY(pY2)))
end b2kOverlap

-- Controls whose body overlaps a screen circle.
function b2kOverlapCircle pX, pY, pRadiusPx
   if sWorld is empty then return empty
   return b2kQueryToControls(b2OverlapCircle(sWorld, b2kToWorldX(pX), b2kToWorldY(pY), pRadiusPx / sScale))
end b2kOverlapCircle

-- Every control a ray crosses, nearest-first (vs b2kRayHit's single closest).
function b2kRayHitAll pX1, pY1, pX2, pY2
   if sWorld is empty then return empty
   return b2kQueryToControls(b2RayCastAll(sWorld, b2kToWorldX(pX1), b2kToWorldY(pY1), b2kToWorldX(pX2), b2kToWorldY(pY2)))
end b2kRayHitAll

-- Shared: turn the current query result (count) into a newline list of controls.
function b2kQueryToControls pCount
   local i, c, tList
   put empty into tList
   repeat with i = 1 to pCount
      put sCtrl[b2QueryBody(i)] into c
      if c is not empty then put c & cr after tList
   end repeat
   return tList
end b2kQueryToControls

-- =====================================================================
-- Motor & filter joints
-- =====================================================================
-- Drive pMover toward a target pose relative to pRef (a moving anchor; empty =
-- the world). Offsets are in screen pixels / degrees from pRef's centre. Great for
-- followers, lifts and character motion. Returns a joint handle (b2kRemoveJoint).
command b2kMotorTo pMover, pRef, pOffsetXPx, pOffsetYPx, pAngleDeg, pMaxForce, pMaxTorque
   local bMover, bRef
   put sBody[the long id of pMover] into bMover
   if pRef is empty then put sDragAnchor into bRef
   else put sBody[the long id of pRef] into bRef
   if bMover is empty or bRef is empty or sWorld is empty then return 0
   if pAngleDeg is empty then put 0 into pAngleDeg
   if pMaxForce is empty then put 1000 into pMaxForce
   if pMaxTorque is empty then put 1000 into pMaxTorque
   return b2MotorJoint(sWorld, bRef, bMover, pOffsetXPx / sScale, - pOffsetYPx / sScale, \
         pAngleDeg * kPI / 180, pMaxForce, pMaxTorque, 0.3, false)
end b2kMotorTo

-- Stop two specific controls from colliding with each other (without changing how
-- either collides with anything else). Returns a joint handle (b2kRemoveJoint).
command b2kNoCollide pCtrlA, pCtrlB
   local bA, bB
   put sBody[the long id of pCtrlA] into bA
   put sBody[the long id of pCtrlB] into bB
   if bA is empty or bB is empty or sWorld is empty then return 0
   return b2FilterJoint(sWorld, bA, bB)
end b2kNoCollide

-- =====================================================================
-- World tuning (advanced) + perf readout
-- =====================================================================
-- Below this approach speed (px/sec) collisions stop bouncing, even if bouncy.
command b2kSetRestitutionThreshold pPxPerSec
   if sWorld is not empty then b2SetRestitutionThreshold sWorld, pPxPerSec / sScale
end b2kSetRestitutionThreshold

-- Contact softness: stiffness (hertz), damping ratio, max separation-fix speed (px/sec).
command b2kSetContactTuning pHertz, pDamping, pPushPx
   if sWorld is not empty then b2SetContactTuning sWorld, pHertz, pDamping, pPushPx / sScale
end b2kSetContactTuning

command b2kSetJointTuning pHertz, pDamping
   if sWorld is not empty then b2SetJointTuning sWorld, pHertz, pDamping
end b2kSetJointTuning

-- Clamp how fast any body can move (px/sec) — stops runaway speeds.
command b2kSetMaxSpeed pPxPerSec
   if sWorld is not empty then b2SetMaximumLinearSpeed sWorld, pPxPerSec / sScale
end b2kSetMaxSpeed

command b2kEnableWarmStarting pFlag
   if sWorld is not empty then b2EnableWarmStarting sWorld, (pFlag is true)
end b2kEnableWarmStarting

-- A quick perf readout in milliseconds: "totalStep,collide,solve" for the last step.
function b2kProfile
   if sWorld is empty then return empty
   b2WorldProfileUpdate sWorld
   return b2WorldProfileStep() & "," & b2WorldProfileCollide() & "," & b2WorldProfileSolve()
end b2kProfile

-- How many dynamic bodies are awake right now (native count, vs b2kAwakeCount).
function b2kAwakeBodyCount
   if sWorld is empty then return 0
   return b2AwakeBodyCount(sWorld)
end b2kAwakeBodyCount

-- =====================================================================
-- Dragging: call b2kGrab from mouseDown and b2kRelease from mouseUp.
-- =====================================================================
function b2kGrab pScreenX, pScreenY
   local tWx, tWy, tBody
   if sWorld is empty then return empty   -- grab before setup: nothing to hit
   put b2kToWorldX(pScreenX) into tWx
   put b2kToWorldY(pScreenY) into tWy
   put b2BodyAtPoint(sWorld, tWx, tWy) into tBody
   if tBody > 0 and b2BodyType(tBody) is 2 then
      b2SetAwake tBody, true
      put b2MouseJoint(sWorld, sDragAnchor, tBody, tWx, tWy, 6, 0.7, 4000) into sDragJoint
      put true into sDragging
      return sCtrl[tBody]
   end if
   return empty
end b2kGrab

command b2kRelease
   if sDragJoint is not empty and sDragJoint > 0 then b2DestroyJoint sDragJoint
   put 0 into sDragJoint
   put false into sDragging
end b2kRelease

-- =====================================================================
-- Input (keyboard): poll-and-diff held keys, once per frame
-- =====================================================================
-- Model: one `the keysDown` sample per frame (taken inside the loop, just
-- before b2kFrame dispatches), diffed against the previous frame's sample.
-- Held = in the current set; pressed/released = the diff. This sidesteps
-- every event-path problem at once: OS auto-repeat (Win32 re-sends
-- rawKeyDown with no paired ups), focus stealing by fields/buttons, and
-- frontscript plumbing. Letter keys bind BOTH keysym cases ("w" = 119 and
-- 87) because the reported code shifts with the Shift key.
command b2kInputOn
   put true into sInputOn
   put comma into sKeysNow
   put comma into sKeysPrev
   -- starter bindings; rebind freely (these only fill empty slots)
   if sKeyActions["jump"] is empty then b2kBindAction "jump", "space"
   if sAxisNeg["moveX"] is empty then b2kBindAxis "moveX", "left,a", "right,d"
   if sAxisNeg["moveY"] is empty then b2kBindAxis "moveY", "up,w", "down,s"
end b2kInputOn

command b2kInputOff
   put false into sInputOn
   put comma into sKeysNow
   put comma into sKeysPrev
end b2kInputOff

function b2kInputIsOn
   return (sInputOn is true)
end b2kInputIsOn

-- Internal, called by the loop each frame while armed. The sets are stored
-- comma-wrapped (",65361,32,") so membership is one `contains` test.
command b2kInputTick
   if sInputOn is not true then exit b2kInputTick
   put sKeysNow into sKeysPrev
   put comma & the keysDown & comma into sKeysNow
end b2kInputTick

-- A friendly key name (or raw keycode) -> the keycode candidates it matches,
-- comma-separated. Numbers >= 32 pass through as raw keycodes; single
-- characters resolve to their code (letters to both cases, per the
-- Shift-keysym behaviour the Phase 0 spike confirmed).
function b2kKeyCodes pKey
   local tLower, tUpper
   if pKey is a number and pKey >= 32 then return pKey
   switch pKey
      case "left"
         return 65361
      case "up"
         return 65362
      case "right"
         return 65363
      case "down"
         return 65364
      case "space"
         return 32
      case "return"
      case "enter"
         return "65293,65421"
      case "escape"
      case "esc"
         return 65307
      case "tab"
         return 65289
      case "shift"
         return "65505,65506"
      case "control"
      case "ctrl"
         return "65507,65508"
      case "alt"
      case "option"
         return "65513,65514"
      case "backspace"
         return 65288
      case "delete"
         return 65535
   end switch
   if the number of chars of pKey is 1 then
      put charToNum(toLower(pKey)) into tLower
      put charToNum(toUpper(pKey)) into tUpper
      if tLower >= 97 and tLower <= 122 then return tLower & comma & tUpper
      return charToNum(pKey)
   end if
   return 0
end b2kKeyCodes

-- The reverse map, for readouts: a keycode -> its friendly name (or itself).
function b2kKeyName pCode
   switch pCode
      case 65361
         return "left"
      case 65362
         return "up"
      case 65363
         return "right"
      case 65364
         return "down"
      case 32
         return "space"
      case 65293
      case 65421
         return "return"
      case 65307
         return "escape"
      case 65289
         return "tab"
      case 65505
      case 65506
         return "shift"
      case 65507
      case 65508
         return "control"
      case 65513
      case 65514
         return "alt"
      case 65288
         return "backspace"
      case 65535
         return "delete"
   end switch
   if pCode >= 97 and pCode <= 122 then return numToChar(pCode)
   if pCode >= 65 and pCode <= 90 then return numToChar(pCode + 32)
   if pCode >= 48 and pCode <= 57 then return numToChar(pCode)
   return pCode
end b2kKeyName

-- True when any of pKey's candidate codes is in the given set.
function b2kKeyInSet pSet, pKey
   local tC
   if pSet is empty or pSet is comma then return false
   repeat for each item tC in b2kKeyCodes(pKey)
      if pSet contains (comma & tC & comma) then return true
   end repeat
   return false
end b2kKeyInSet

function b2kKeyIsDown pKey
   return b2kKeyInSet(sKeysNow, pKey)
end b2kKeyIsDown

-- Edge queries: true only on the single frame the state changed.
function b2kKeyPressed pKey
   return b2kKeyInSet(sKeysNow, pKey) and not b2kKeyInSet(sKeysPrev, pKey)
end b2kKeyPressed

function b2kKeyReleased pKey
   return b2kKeyInSet(sKeysPrev, pKey) and not b2kKeyInSet(sKeysNow, pKey)
end b2kKeyReleased

-- Everything held right now, as friendly names (debug HUDs).
function b2kKeysHeld
   local tOut, tC
   put empty into tOut
   repeat for each item tC in char 2 to -2 of sKeysNow
      put b2kKeyName(tC) & space after tOut
   end repeat
   return word 1 to -1 of tOut
end b2kKeysHeld

-- Actions: a named set of keys ("jump" = "space,up,w"). Any bound key
-- counts; the action's edges treat the whole set as one logical key.
command b2kBindAction pName, pKeyList
   put pKeyList into sKeyActions[pName]
end b2kBindAction

function b2kActionIsDown pName
   local tK
   repeat for each item tK in sKeyActions[pName]
      if b2kKeyIsDown(word 1 of tK) then return true
   end repeat
   return false
end b2kActionIsDown

function b2kActionPressed pName
   local tK
   if not b2kActionIsDown(pName) then return false
   repeat for each item tK in sKeyActions[pName]
      if b2kKeyInSet(sKeysPrev, word 1 of tK) then return false
   end repeat
   return true
end b2kActionPressed

function b2kActionReleased pName
   local tK, tWasDown
   put false into tWasDown
   repeat for each item tK in sKeyActions[pName]
      if b2kKeyInSet(sKeysPrev, word 1 of tK) then put true into tWasDown
   end repeat
   if not tWasDown then return false
   return not b2kActionIsDown(pName)
end b2kActionReleased

-- Axes: -1 / 0 / +1 from two key sets ("moveX" defaults to left,a / right,d).
-- Both directions held = 0, which is what character movement wants.
command b2kBindAxis pName, pNegKeys, pPosKeys
   put pNegKeys into sAxisNeg[pName]
   put pPosKeys into sAxisPos[pName]
end b2kBindAxis

function b2kAxis pName
   local tK, tNeg, tPos
   put false into tNeg
   put false into tPos
   repeat for each item tK in sAxisNeg[pName]
      if b2kKeyIsDown(word 1 of tK) then put true into tNeg
   end repeat
   repeat for each item tK in sAxisPos[pName]
      if b2kKeyIsDown(word 1 of tK) then put true into tPos
   end repeat
   if tPos and not tNeg then return 1
   if tNeg and not tPos then return -1
   return 0
end b2kAxis

-- Real elapsed ms folded into the last frame -- drive animations and user
-- timers from this, not the step count (a frame may run 0..n fixed steps).
function b2kFrameMS
   if sFrameMS is empty then return 0
   return sFrameMS
end b2kFrameMS

-- =====================================================================
-- Sprites: sheets, atlases, named animations (icon-button backend)
-- =====================================================================
-- Model (decided by the Phase 0 spike, S12): a sheet registers named or
-- numbered frame REGIONS of one hidden source image; each region is sliced
-- into its own hidden image LAZILY, on first use. A sprite is a transparent
-- BUTTON whose icon is the current frame's image -- a frame switch is one
-- property set, and every sprite of a sheet shares the same frame images.
-- Mirrored (left-facing) frames are flip-clones, also made lazily.
-- Sheets persist until b2kTeardown; sprites are Kit-created controls, so
-- b2kClear removes them like everything else the Kit spawned.

-- Register an image FILE as a uniform grid of pFW x pFH frames (no spacing),
-- numbered 1..N left-to-right, top-to-bottom. Reports the frame count.
command b2kSheetLoad pName, pPath, pFW, pFH, pCount
   local tRef
   put b2kSheetSourceFromFile(pName, pPath) into tRef
   if tRef is empty then return 0
   b2kSheetGridRegions pName, pFW, pFH, pCount
   return the number of lines of sSheetKeys[pName]
end b2kSheetLoad

-- Register an image already in the stack (e.g. base64-embedded art) as a
-- grid sheet. The image is used in place and never deleted by the Kit.
command b2kSheetFromImage pName, pImgRef, pFW, pFH, pCount
   b2kSheetForget pName
   put the long id of pImgRef into sSheetSrc[pName]
   put false into sSheetOwned[pName]
   b2kSheetGridRegions pName, pFW, pFH, pCount
   return the number of lines of sSheetKeys[pName]
end b2kSheetFromImage

-- Register a packed atlas: a PNG plus the TextureAtlas XML that names its
-- regions (<SubTexture name=".." x=".." y=".." width=".." height=".."/> --
-- the Kenney pack format, like Spritesheets/ in this repo). Frames are
-- addressed BY NAME. pXmlPath defaults to the png path with ".xml".
command b2kSheetLoadAtlas pName, pPngPath, pXmlPath
   local tRef, tXml, tLine, tNm, tX, tY, tW, tH
   if pXmlPath is empty then
      put pPngPath into pXmlPath
      set the itemDelimiter to "."
      put "xml" into item -1 of pXmlPath
   end if
   put URL ("file:" & pXmlPath) into tXml
   if tXml is empty then put URL ("binfile:" & pXmlPath) into tXml
   if tXml is empty then return 0
   put b2kSheetSourceFromFile(pName, pPngPath) into tRef
   if tRef is empty then return 0
   set the itemDelimiter to comma
   repeat for each line tLine in tXml
      if tLine contains "<SubTexture" then
         put b2kXmlAttr(tLine, "name") into tNm
         put b2kXmlAttr(tLine, "x") into tX
         put b2kXmlAttr(tLine, "y") into tY
         put b2kXmlAttr(tLine, "width") into tW
         put b2kXmlAttr(tLine, "height") into tH
         if tNm is empty or tX is not a number or tY is not a number then next repeat
         if tW is not a number or tH is not a number then next repeat
         put tX & comma & tY & comma & tW & comma & tH into sSheetRegion[pName][tNm]
         put tNm & cr after sSheetKeys[pName]
      end if
   end repeat
   if the last char of sSheetKeys[pName] is cr then delete the last char of sSheetKeys[pName]
   return the number of lines of sSheetKeys[pName]
end b2kSheetLoadAtlas

function b2kSheetFrames pName
   return the number of lines of sSheetKeys[pName]
end b2kSheetFrames

function b2kSheetHasFrame pName, pFrame
   return (sSheetRegion[pName][pFrame] is not empty)
end b2kSheetHasFrame

-- Display scale for a sheet's frames (default 1). Frames slice lazily, so
-- set this right after loading the sheet, BEFORE creating sprites or anims:
-- already-sliced frames are dropped and re-bake at the new scale, but live
-- sprites keep their button rects. The engine does the resampling, so any
-- frame size displays at any sprite size.
command b2kSheetScale pName, pScale
   local tKey, tId
   put b2kClamp(pScale, 0.05, 8) into pScale
   if b2kNumberOr(sSheetScale[pName], 1) is pScale then exit b2kSheetScale
   put pScale into sSheetScale[pName]
   repeat for each key tKey in sSheetIcon[pName]
      put sSheetIcon[pName][tKey] into tId
      if tId is not empty then
         try
            delete image id tId
         catch tErr
         end try
      end if
   end repeat
   repeat for each key tKey in sSheetFlip[pName]
      put sSheetFlip[pName][tKey] into tId
      if tId is not empty then
         try
            delete image id tId
         catch tErr
         end try
      end if
   end repeat
   delete variable sSheetIcon[pName]
   delete variable sSheetFlip[pName]
end b2kSheetScale

-- A frame's DISPLAY size as "w,h" (its region size times the sheet scale) --
-- lay out tiles and platforms from this instead of hard-coding pixels.
function b2kSheetFrameSize pName, pFrame
   local tRegion, tScale
   put sSheetRegion[pName][pFrame] into tRegion
   if tRegion is empty then return empty
   set the itemDelimiter to comma
   put b2kNumberOr(sSheetScale[pName], 1) into tScale
   return max(1, round((item 3 of tRegion) * tScale)) & comma & max(1, round((item 4 of tRegion) * tScale))
end b2kSheetFrameSize

-- Define a named animation: pFrames is a comma list of frame names and/or
-- 1-based indices, with numeric ranges ("1-8") expanded. pLoop defaults true.
command b2kAnimDef pSheet, pAnim, pFrames, pFPS, pLoop
   local tKey, tList, tItem, tA, tB, i
   put pSheet & "|" & pAnim into tKey
   put empty into tList
   set the itemDelimiter to comma
   repeat for each item tItem in pFrames
      put word 1 to -1 of tItem into tItem
      if tItem contains "-" and tItem is not a number then
         set the itemDelimiter to "-"
         put item 1 of tItem into tA
         put item 2 of tItem into tB
         set the itemDelimiter to comma
         if tA is a number and tB is a number then
            repeat with i = tA to tB
               put i & cr after tList
            end repeat
            next repeat
         end if
      end if
      put tItem & cr after tList
   end repeat
   if the last char of tList is cr then delete the last char of tList
   put tList into sAnimList[tKey]
   put b2kClamp(pFPS, 0.1, 120) into sAnimFPS[tKey]
   put (pLoop is not false) into sAnimLoop[tKey]
end b2kAnimDef

-- Create a sprite: a transparent button showing pFrame (default: the sheet's
-- first frame), centred on pX,pY and sized to the frame. Reports the control.
-- It is an ordinary Kit control: pass it to b2kAddCapsule/b2kAddBox for a
-- body (buttons render position-only with rotation locked), or bind it to
-- another control's body with b2kSpriteBind.
command b2kSpriteNew pSheet, pFrame, pX, pY
   local tName, tRef, tKey, tRegion, tW, tH
   if sSheetKeys[pSheet] is empty then return empty
   put pFrame into tKey
   if tKey is empty then put line 1 of sSheetKeys[pSheet] into tKey
   put b2kSheetFrameSize(pSheet, tKey) into tRegion   -- "w,h" at display scale
   if tRegion is empty then return empty
   set the itemDelimiter to comma
   put item 1 of tRegion into tW
   put item 2 of tRegion into tH
   put b2kNumberOr(pX, (the width of this card) div 2) into pX
   put b2kNumberOr(pY, (the height of this card) div 2) into pY
   put "b2kspr_" & the milliseconds & "_" & random(1000000) into tName
   if sCamGroup is empty then
      create button tName
   else
      create button tName in group "b2kcam_view"
   end if
   put the long id of button tName into tRef
   set the style of tRef to "transparent"
   set the showName of tRef to false
   set the traversalOn of tRef to false
   set the autoHilite of tRef to false
   set the rect of tRef to round(pX - tW / 2), round(pY - tH / 2), round(pX + tW / 2), round(pY + tH / 2)
   try
      set the layerMode of tRef to "dynamic"   -- its own compositor layer
   catch tErr
   end try
   put pSheet into sSprSheet[tRef]
   put "sheet" into sSprKind[tRef]
   put false into sSprFlip[tRef]
   put true into sSpawned[tRef]
   put tRef & cr after sSprRefs
   b2kSpriteShowFrame tRef, tKey
   return tRef
end b2kSpriteNew

-- A sprite backed by an animated GIF file: the engine plays it; the Kit's
-- play/stop/frame calls drive repeatCount/currentFrame instead of icons.
command b2kSpriteFromGIF pPath, pX, pY
   local tName, tRef, tData
   put URL ("binfile:" & pPath) into tData   -- content-load, like the sheets
   if tData is empty then return empty
   put "b2kspr_" & the milliseconds & "_" & random(1000000) into tName
   if sCamGroup is empty then
      create image tName
   else
      create image tName in group "b2kcam_view"
   end if
   put the long id of image tName into tRef
   try
      set the text of tRef to tData
   catch tErr
   end try
   set the lockLoc of tRef to true
   if the width of tRef < 1 then
      try
         delete tRef
      catch tErr
      end try
      return empty
   end if
   put b2kNumberOr(pX, (the width of this card) div 2) into pX
   put b2kNumberOr(pY, (the height of this card) div 2) into pY
   set the loc of tRef to round(pX) & comma & round(pY)
   try
      set the layerMode of tRef to "dynamic"
   catch tErr
   end try
   try
      set the repeatCount of tRef to -1
   catch tErr
   end try
   put "gif" into sSprKind[tRef]
   put true into sSpawned[tRef]
   put tRef & cr after sSprRefs
   return tRef
end b2kSpriteFromGIF

-- Start a named animation; a no-op if it is already playing (so calling it
-- every frame from a state machine is free) unless pRestart forces frame 1.
command b2kSpritePlay pCtrl, pAnim, pRestart
   local tRef, tKey
   put the long id of pCtrl into tRef
   if sSprKind[tRef] is "gif" then
      try
         set the repeatCount of tRef to -1
      catch tErr
      end try
      exit b2kSpritePlay
   end if
   if sSprSheet[tRef] is empty then exit b2kSpritePlay
   put sSprSheet[tRef] & "|" & pAnim into tKey
   if sAnimList[tKey] is empty then exit b2kSpritePlay
   if sSprAnim[tRef] is pAnim and pRestart is not true then exit b2kSpritePlay
   put pAnim into sSprAnim[tRef]
   put 1 into sSprStep[tRef]
   if sSprFPSOver[tRef] is not empty then
      put sSprFPSOver[tRef] into sSprFPS[tRef]
   else
      put sAnimFPS[tKey] into sSprFPS[tRef]
   end if
   if sSprFPS[tRef] is empty or sSprFPS[tRef] <= 0 then put 8 into sSprFPS[tRef]
   put the milliseconds + (1000 / sSprFPS[tRef]) into sSprNextMS[tRef]
   b2kSpriteShowFrame tRef, line 1 of sAnimList[tKey]
end b2kSpritePlay

command b2kSpriteStop pCtrl
   local tRef
   put the long id of pCtrl into tRef
   if sSprKind[tRef] is "gif" then
      try
         set the repeatCount of tRef to 0
      catch tErr
      end try
      exit b2kSpriteStop
   end if
   put empty into sSprAnim[tRef]
end b2kSpriteStop

function b2kSpriteAnim pCtrl
   return sSprAnim[the long id of pCtrl]
end b2kSpriteAnim

-- Show one frame by name/index (stops any running animation first).
command b2kSpriteSetFrame pCtrl, pFrame
   local tRef
   put the long id of pCtrl into tRef
   if sSprKind[tRef] is "gif" then
      try
         set the repeatCount of tRef to 0
         set the currentFrame of tRef to pFrame
      catch tErr
      end try
      exit b2kSpriteSetFrame
   end if
   put empty into sSprAnim[tRef]
   b2kSpriteShowFrame tRef, pFrame
end b2kSpriteSetFrame

function b2kSpriteFrame pCtrl
   return sSprFrameKey[the long id of pCtrl]
end b2kSpriteFrame

-- Per-sprite speed override (empty = use each animation's own fps).
command b2kSpriteFPS pCtrl, pFPS
   local tRef
   put the long id of pCtrl into tRef
   put pFPS into sSprFPSOver[tRef]
   if pFPS is a number and pFPS > 0 then put pFPS into sSprFPS[tRef]
end b2kSpriteFPS

-- Face left (true) or right (false). The mirrored frame image is created
-- the first time it is needed, by flip-cloning the sliced frame.
command b2kSpriteFlipH pCtrl, pFlag
   local tRef
   put the long id of pCtrl into tRef
   if sSprSheet[tRef] is empty then exit b2kSpriteFlipH
   put (pFlag is true) into pFlag
   if sSprFlip[tRef] is pFlag then exit b2kSpriteFlipH
   put pFlag into sSprFlip[tRef]
   if sSprFrameKey[tRef] is not empty then b2kSpriteShowFrame tRef, sSprFrameKey[tRef]
end b2kSpriteFlipH

function b2kSpriteFlipped pCtrl
   return (sSprFlip[the long id of pCtrl] is true)
end b2kSpriteFlipped

-- When a NON-looping animation finishes, send pMessage to the frame target
-- with the sprite and the animation name (attack/death/effect chaining).
command b2kSpriteOnFinish pCtrl, pMessage
   put pMessage into sSprMsg[the long id of pCtrl]
end b2kSpriteOnFinish

-- Pin this sprite to another control's position each frame (offset in px) --
-- the standard pattern for "art bigger than the collision shape": give an
-- invisible control the body, bind the sprite to it.
command b2kSpriteBind pCtrl, pBodyCtrl, pDX, pDY
   local tRef
   put the long id of pCtrl into tRef
   put the long id of pBodyCtrl into sSprBind[tRef]
   put b2kNumberOr(pDX, 0) into sSprBindDX[tRef]
   put b2kNumberOr(pDY, 0) into sSprBindDY[tRef]
end b2kSpriteBind

command b2kSpriteUnbind pCtrl
   delete variable sSprBind[the long id of pCtrl]
end b2kSpriteUnbind

-- Remove a sprite (and its body, if it has one).
command b2kSpriteRemove pCtrl
   local tRef
   put the long id of pCtrl into tRef
   if sBody[tRef] is not empty then
      b2kRemove tRef          -- destroys the body and deletes the control
   else
      try
         delete tRef
      catch tErr
      end try
   end if
   b2kSpriteForget tRef
end b2kSpriteRemove

-- Internal: drop a sprite's registry entries (the control is already gone).
command b2kSpriteForget pRef
   local tLn
   delete variable sSprSheet[pRef]
   delete variable sSprKind[pRef]
   delete variable sSprAnim[pRef]
   delete variable sSprStep[pRef]
   delete variable sSprNextMS[pRef]
   delete variable sSprFPS[pRef]
   delete variable sSprFPSOver[pRef]
   delete variable sSprFlip[pRef]
   delete variable sSprMsg[pRef]
   delete variable sSprBind[pRef]
   delete variable sSprBindDX[pRef]
   delete variable sSprBindDY[pRef]
   delete variable sSprFrameKey[pRef]
   delete variable sSprIconNow[pRef]
   delete variable sSprLastLoc[pRef]
   set the wholeMatches to true
   put lineOffset(pRef, sSprRefs) into tLn
   if tLn > 0 then delete line tLn of sSprRefs
end b2kSpriteForget

-- Internal: remove every live sprite (b2kClear / b2kTeardown path).
command b2kSpritesClear
   local tRef, tList
   put sSprRefs into tList
   repeat for each line tRef in tList
      if tRef is not empty then b2kSpriteRemove tRef
   end repeat
   put empty into sSprRefs
end b2kSpritesClear

-- Internal: forget one sheet -- its regions, anims, sliced/mirrored frame
-- images, and (if the Kit loaded it) the hidden source image.
command b2kSheetForget pName
   local tKey, tId
   if sSheetSrc[pName] is empty and sSheetKeys[pName] is empty then exit b2kSheetForget
   repeat for each key tKey in sSheetIcon[pName]
      put sSheetIcon[pName][tKey] into tId
      if tId is not empty then
         try
            delete image id tId
         catch tErr
         end try
      end if
   end repeat
   repeat for each key tKey in sSheetFlip[pName]
      put sSheetFlip[pName][tKey] into tId
      if tId is not empty and tId is not sSheetIcon[pName][tKey] then
         try
            delete image id tId
         catch tErr
         end try
      end if
   end repeat
   if sSheetOwned[pName] is not false and sSheetSrc[pName] is not empty then
      try
         delete sSheetSrc[pName]
      catch tErr
      end try
   end if
   delete variable sSheetSrc[pName]
   delete variable sSheetOwned[pName]
   delete variable sSheetRegion[pName]
   delete variable sSheetKeys[pName]
   delete variable sSheetIcon[pName]
   delete variable sSheetFlip[pName]
   delete variable sSheetData[pName]
   delete variable sSheetAlpha[pName]
   delete variable sSheetScale[pName]
   repeat for each key tKey in sAnimList
      if char 1 to (the number of chars of pName) + 1 of tKey is pName & "|" then
         delete variable sAnimList[tKey]
         delete variable sAnimFPS[tKey]
         delete variable sAnimLoop[tKey]
      end if
   end repeat
end b2kSheetForget

-- Internal: every sheet + every sprite (b2kTeardown path).
command b2kSheetsWipe
   local tName
   b2kSpritesClear
   repeat for each key tName in sSheetSrc
      b2kSheetForget tName
   end repeat
   put empty into sSheetSrc
   put empty into sSheetRegion
   put empty into sSheetKeys
   put empty into sSheetIcon
   put empty into sSheetFlip
   put empty into sSheetData
   put empty into sSheetAlpha
   put empty into sSheetScale
   put empty into sAnimList
   put empty into sAnimFPS
   put empty into sAnimLoop
   b2kSpriteSweepOrphans
end b2kSheetsWipe

-- Internal: delete Kit-generated sprite/sheet controls left over from a
-- PREVIOUS session. Script-locals reset when a stack reopens (or a new
-- script is pasted in), but the controls persist -- registry cleanup can't
-- see them, so a reopened stack would show ghost sprites frozen on their
-- last frame. Swept by name prefix on every teardown.
command b2kSpriteSweepOrphans
   local tAgain, i, tName, tHit
   put true into tAgain
   repeat while tAgain
      put false into tAgain
      repeat with i = 1 to the number of controls of this card
         put the short name of control i of this card into tName
         if char 1 to 7 of tName is "b2kcam_" then
            -- a dead session's viewport: free the children, then the shell
            try
               ungroup control i of this card
            catch tErr
               delete control i of this card
            end try
            put true into tAgain
            exit repeat
         end if
         put false into tHit
         if char 1 to 7 of tName is "b2kspr_" then put true into tHit
         if char 1 to 6 of tName is "b2kfr_" then put true into tHit
         if char 1 to 6 of tName is "b2kfl_" then put true into tHit
         if char 1 to 9 of tName is "b2ksheet_" then put true into tHit
         if tHit then
            delete control i of this card
            put true into tAgain
            exit repeat
         end if
      end repeat
   end repeat
end b2kSpriteSweepOrphans

-- ---- sprite internals ------------------------------------------------

-- Internal: load an image file into a hidden, Kit-owned source image.
-- The bytes are loaded as CONTENT (binfile -> set the text), not as a
-- filename reference: referenced images size and load lazily for hidden
-- controls, which broke the slicer's stride; content images adopt their
-- pixel size immediately -- the exact path b2kSheetFromImage users (and
-- the platformer's embedded placeholder) already exercise successfully.
-- lockLoc only AFTER the content, so the control has auto-sized first.
function b2kSheetSourceFromFile pName, pPath
   local tImg, tData
   b2kSheetForget pName
   if there is no file pPath then return empty
   put URL ("binfile:" & pPath) into tData
   if tData is empty then return empty
   put "b2ksheet_" & pName into tImg
   if there is an image tImg then delete image tImg
   create image tImg
   set the visible of it to false
   try
      set the text of image tImg to tData
   catch tErr
      delete image tImg
      return empty
   end try
   if the width of image tImg < 2 then
      delete image tImg
      return empty
   end if
   set the lockLoc of image tImg to true
   put the long id of image tImg into sSheetSrc[pName]
   put true into sSheetOwned[pName]
   return sSheetSrc[pName]
end b2kSheetSourceFromFile

-- Internal: register grid regions over the current source image.
command b2kSheetGridRegions pName, pFW, pFH, pCount
   local tCols, tRows, tMax, i, tC, tR
   if sSheetSrc[pName] is empty then exit b2kSheetGridRegions
   put b2kClamp(pFW, 1, 4096) into pFW
   put b2kClamp(pFH, 1, 4096) into pFH
   put (the width of sSheetSrc[pName]) div pFW into tCols
   put (the height of sSheetSrc[pName]) div pFH into tRows
   put tCols * tRows into tMax
   if pCount is a number and pCount > 0 and pCount < tMax then put pCount into tMax
   repeat with i = 1 to tMax
      put (i - 1) mod tCols into tC
      put (i - 1) div tCols into tR
      put (tC * pFW) & comma & (tR * pFH) & comma & pFW & comma & pFH into sSheetRegion[pName][i]
      put i & cr after sSheetKeys[pName]
   end repeat
   if the last char of sSheetKeys[pName] is cr then delete the last char of sSheetKeys[pName]
end b2kSheetGridRegions

-- Internal: one attribute value out of an XML tag line (attr="value").
function b2kXmlAttr pLine, pAttr
   local tFrom, tLen
   put offset(pAttr & "=" & quote, pLine) into tFrom
   if tFrom is 0 then return empty
   add the number of chars of pAttr + 2 to tFrom
   put offset(quote, pLine, tFrom - 1) into tLen
   if tLen is 0 then return empty
   return char tFrom to tFrom + tLen - 2 of pLine
end b2kXmlAttr

-- Internal: make sure a frame's sliced image exists (lazy, cached). The
-- source pixels are fetched once per sheet and kept until teardown.
command b2kSheetEnsureIcon pSheet, pKey
   local tRegion, tX, tY, tW, tH, tSW, tRowPx, tFD, tFA, y, tName, tScale, tW2, tH2
   if sSheetIcon[pSheet][pKey] is not empty then exit b2kSheetEnsureIcon
   put sSheetRegion[pSheet][pKey] into tRegion
   if tRegion is empty then exit b2kSheetEnsureIcon
   if sSheetData[pSheet] is empty then
      put the imageData of sSheetSrc[pSheet] into sSheetData[pSheet]
      put the alphaData of sSheetSrc[pSheet] into sSheetAlpha[pSheet]
   end if
   set the itemDelimiter to comma
   put item 1 of tRegion into tX
   put item 2 of tRegion into tY
   put item 3 of tRegion into tW
   put item 4 of tRegion into tH
   put the width of sSheetSrc[pSheet] into tSW
   -- refuse to slice from inconsistent pixels: a stride mismatch must yield
   -- an empty (invisible) frame, never garbage on screen
   if the number of bytes in sSheetData[pSheet] is not tSW * (the height of sSheetSrc[pSheet]) * 4 then exit b2kSheetEnsureIcon
   if tX + tW > tSW then exit b2kSheetEnsureIcon
   put empty into tFD
   put empty into tFA
   repeat with y = 0 to tH - 1
      put (tY + y) * tSW + tX into tRowPx
      put byte (tRowPx * 4 + 1) to (tRowPx * 4 + tW * 4) of sSheetData[pSheet] after tFD
      put byte (tRowPx + 1) to (tRowPx + tW) of sSheetAlpha[pSheet] after tFA
   end repeat
   if the number of bytes in tFD is not tW * tH * 4 then exit b2kSheetEnsureIcon
   if the number of bytes in tFA is not tW * tH then
      put empty into tFA   -- no usable alpha: ship the frame fully opaque
   end if
   put "b2kfr_" & the milliseconds & "_" & random(1000000) into tName
   create image tName
   set the visible of it to false
   set the lockLoc of it to true
   set the width of it to tW
   set the height of it to tH
   set the imageData of image tName to tFD
   if tFA is not empty then set the alphaData of image tName to tFA
   -- sheet scale: resize the control (the engine resamples the render),
   -- then bake that render back in as the frame's real pixels
   put b2kNumberOr(sSheetScale[pSheet], 1) into tScale
   if tScale is not 1 then
      put max(1, round(tW * tScale)) into tW2
      put max(1, round(tH * tScale)) into tH2
      set the width of image tName to tW2
      set the height of image tName to tH2
      put the imageData of image tName into tFD
      put the alphaData of image tName into tFA
      set the imageData of image tName to tFD
      if tFA is not empty then set the alphaData of image tName to tFA
   end if
   put the id of image tName into sSheetIcon[pSheet][pKey]
end b2kSheetEnsureIcon

-- Internal: the mirrored copy of a frame (falls back to the unmirrored
-- frame if this engine's flip throws, so facing left never errors).
command b2kSheetEnsureFlip pSheet, pKey
   local tName
   if sSheetFlip[pSheet][pKey] is not empty then exit b2kSheetEnsureFlip
   b2kSheetEnsureIcon pSheet, pKey
   if sSheetIcon[pSheet][pKey] is empty then exit b2kSheetEnsureFlip
   try
      clone image id sSheetIcon[pSheet][pKey]
      put "b2kfl_" & the milliseconds & "_" & random(1000000) into tName
      set the name of it to tName
      set the visible of it to false
      flip image tName horizontal
      put the id of image tName into sSheetFlip[pSheet][pKey]
   catch tErr
      put sSheetIcon[pSheet][pKey] into sSheetFlip[pSheet][pKey]
   end try
end b2kSheetEnsureFlip

-- Internal: point a sprite's icon at a frame, honouring its facing. Skips
-- the property set when the icon is already right (the sDrawKey idea).
command b2kSpriteShowFrame pRef, pKey
   local tSheet, tIcon
   put sSprSheet[pRef] into tSheet
   if tSheet is empty then exit b2kSpriteShowFrame
   if sSprFlip[pRef] is true then
      b2kSheetEnsureFlip tSheet, pKey
      put sSheetFlip[tSheet][pKey] into tIcon
   else
      b2kSheetEnsureIcon tSheet, pKey
      put sSheetIcon[tSheet][pKey] into tIcon
   end if
   if tIcon is empty then exit b2kSpriteShowFrame
   put pKey into sSprFrameKey[pRef]
   if sSprIconNow[pRef] is tIcon then exit b2kSpriteShowFrame
   set the icon of pRef to tIcon
   put tIcon into sSprIconNow[pRef]
end b2kSpriteShowFrame

-- Internal: per-frame service -- bound sprites follow their body's control,
-- playing animations advance on wall-clock time. Vanished controls are
-- forgotten, like the body sync does.
command b2kSpritesTick
   local tNow, tRef, tDead, tSheet, tAnim, tAKey, tList, tStep, tN, tLoc, tBX, tBY
   if sSprRefs is empty then exit b2kSpritesTick
   put the milliseconds into tNow
   put empty into tDead
   set the itemDelimiter to comma
   repeat for each line tRef in sSprRefs
      if tRef is empty then next repeat
      try
         if sSprBind[tRef] is not empty then
            put the loc of sSprBind[tRef] into tLoc
            put (item 1 of tLoc) + sSprBindDX[tRef] into tBX
            put (item 2 of tLoc) + sSprBindDY[tRef] into tBY
            put tBX & comma & tBY into tLoc
            if sSprLastLoc[tRef] is not tLoc then
               set the loc of tRef to tLoc
               put tLoc into sSprLastLoc[tRef]
            end if
         end if
         if sSprKind[tRef] is "sheet" and sSprAnim[tRef] is not empty then
            if tNow >= sSprNextMS[tRef] then
               put sSprSheet[tRef] into tSheet
               put sSprAnim[tRef] into tAnim
               put tSheet & "|" & tAnim into tAKey
               put sAnimList[tAKey] into tList
               put the number of lines of tList into tN
               put sSprStep[tRef] + 1 into tStep
               if tStep > tN then
                  if sAnimLoop[tAKey] is false then
                     put empty into sSprAnim[tRef]
                     if sSprMsg[tRef] is not empty and sFrameObj is not empty then
                        dispatch sSprMsg[tRef] to sFrameObj with tRef, tAnim
                     end if
                     next repeat
                  end if
                  put 1 into tStep
               end if
               put tStep into sSprStep[tRef]
               add (1000 / sSprFPS[tRef]) to sSprNextMS[tRef]
               if sSprNextMS[tRef] < tNow then put tNow + (1000 / sSprFPS[tRef]) into sSprNextMS[tRef]
               b2kSpriteShowFrame tRef, (line tStep of tList)
            end if
         end if
      catch tErr
         put tRef & cr after tDead   -- control vanished; clean up below
      end try
   end repeat
   repeat for each line tRef in tDead
      if tRef is not empty then b2kSpriteForget tRef
   end repeat
end b2kSpritesTick

-- =====================================================================
-- Camera: a clipped viewport group the loop scrolls (proven in spike S9)
-- =====================================================================
-- While the camera is on, Kit-created controls (spawns and sprites) are
-- placed INSIDE the viewport group; their locs stay WORLD pixels, because
-- contents of a scrolled group keep their coordinates -- the body sync and
-- all physics math are untouched, the scroll is pure presentation. Chrome
-- stays on the card; anything behind the (transparent) group reads as an
-- infinite-distance parallax backdrop. Map mouse points with
-- b2kCamMouseX/Y. Level coordinates should start at 0,0: an invisible
-- anchor pins the group's content origin there, so scroll == view corner.
command b2kCamOn pRect
   local tG
   if sCamGroup is not empty then exit b2kCamOn
   put empty into sCamNote
   if pRect is empty then put the rect of this card into pRect
   try
      create group "b2kcam_view"
   catch tErr
      put "create group failed: " & tErr into sCamNote
      exit b2kCamOn
   end try
   put the long id of group "b2kcam_view" into tG
   try
      set the margins of tG to 0
      set the showBorder of tG to false
      set the hScrollbar of tG to false
      set the vScrollbar of tG to false
      create graphic "b2kcam_anchor" in group "b2kcam_view"
      set the rect of it to 0, 0, 1, 1
      set the visible of it to false
      set the lockLoc of tG to true
      set the rect of tG to pRect
   catch tErr
      put "viewport setup failed: " & tErr into sCamNote
      try
         delete group "b2kcam_view"
      catch tErr
      end try
      exit b2kCamOn
   end try
   try
      set the unboundedHScroll of tG to true
      set the unboundedVScroll of tG to true
   catch tErr
   end try
   try
      set the layerMode of tG to "scrolling"   -- compositor scroll mode
   catch tErr
   end try
   put tG into sCamGroup
   set the itemDelimiter to comma
   put ((item 1 of pRect) + (item 3 of pRect)) / 2 into sCamX
   put ((item 2 of pRect) + (item 4 of pRect)) / 2 into sCamY
   put 0.15 into sCamLerp
   put 0 into sCamDZW
   put 0 into sCamDZH
   put empty into sCamFollow
   put empty into sCamB1X
   put 0 into sCamShakeAmp
   put empty into sCamLastH
   put empty into sCamLastV
   -- self-test: prove the scroll property actually pans this group. The
   -- anchor is stretched first so content exceeds the view (engines clamp
   -- scroll to content bounds), then restored; failure is reported via
   -- b2kCamStatus instead of letting the player walk out of a frozen view.
   try
      set the rect of graphic "b2kcam_anchor" to 0, 0, 4000, 2000
      set the hScroll of sCamGroup to 7
      if the hScroll of sCamGroup is not 7 then
         put "group scroll is ineffective on this engine" into sCamNote
      end if
      set the hScroll of sCamGroup to 0
      set the rect of graphic "b2kcam_anchor" to 0, 0, 1, 1
   catch tErr
      put "setting the group scroll failed: " & tErr into sCamNote
   end try
   b2kCamApply
end b2kCamOn

-- Dissolve the viewport: children return to the card with their world locs.
command b2kCamOff
   if sCamGroup is empty then exit b2kCamOff
   try
      ungroup group "b2kcam_view"
   catch tErr
   end try
   if there is a graphic "b2kcam_anchor" then delete graphic "b2kcam_anchor"
   put empty into sCamGroup
end b2kCamOff

function b2kCamIsOn
   return (sCamGroup is not empty)
end b2kCamIsOn

-- The viewport group's reference (empty when the camera is off) -- create
-- your own level controls inside it: create graphic "x" in b2kCamGroup().
function b2kCamGroup
   return sCamGroup
end b2kCamGroup

-- Move an existing control (IDE-designed levels) into the viewport.
command b2kCamAdopt pCtrl
   if sCamGroup is empty then exit b2kCamAdopt
   try
      relayer pCtrl to front of group "b2kcam_view"
   catch tErr
      -- no script relayer on this engine: the control stays on the card.
      -- Physics is unaffected; only its drawing will not scroll.
   end try
end b2kCamAdopt

command b2kCamFollow pCtrl, pLerp
   put the long id of pCtrl into sCamFollow
   if pLerp is a number then put b2kClamp(pLerp, 0.01, 1) into sCamLerp
end b2kCamFollow

command b2kCamUnfollow
   put empty into sCamFollow
end b2kCamUnfollow

-- Follow only once the target leaves a centre box (0 = always centre).
command b2kCamDeadzone pW, pH
   put b2kNumberOr(pW, 0) into sCamDZW
   put b2kNumberOr(pH, 0) into sCamDZH
end b2kCamDeadzone

command b2kCamBounds pX1, pY1, pX2, pY2
   put pX1 into sCamB1X
   put pY1 into sCamB1Y
   put pX2 into sCamB2X
   put pY2 into sCamB2Y
   -- stretch the invisible anchor across the whole level: the group's
   -- scrollable content then always spans the bounds, so the engine can
   -- never clamp the scroll short (works with or without unbounded scroll)
   if sCamGroup is not empty then
      try
         set the rect of graphic "b2kcam_anchor" to pX1, pY1, pX2, pY2
      catch tErr
      end try
   end if
end b2kCamBounds

command b2kCamGoto pX, pY
   put b2kNumberOr(pX, sCamX) into sCamX
   put b2kNumberOr(pY, sCamY) into sCamY
   b2kCamApply
end b2kCamGoto

function b2kCamPos
   return round(sCamX) & comma & round(sCamY)
end b2kCamPos

-- A decaying random view offset on top of the follow (impacts, blasts).
command b2kCamShake pAmpPx, pMs
   put b2kClamp(pAmpPx, 0, 200) into sCamShakeAmp
   put the milliseconds + b2kClamp(pMs, 0, 5000) into sCamShakeEnd
end b2kCamShake

-- The mouse in WORLD pixels (camera-aware) -- use these for b2kGrab,
-- spawning at the pointer, click-picking, instead of the mouseH/V.
function b2kCamMouseX
   if sCamGroup is empty then return the mouseH
   set the itemDelimiter to comma
   return the mouseH - (item 1 of the rect of sCamGroup) + the hScroll of sCamGroup
end b2kCamMouseX

function b2kCamMouseY
   if sCamGroup is empty then return the mouseV
   set the itemDelimiter to comma
   return the mouseV - (item 2 of the rect of sCamGroup) + the vScroll of sCamGroup
end b2kCamMouseY

-- Health: empty = camera fine (or simply off); otherwise the reason the
-- camera could not run properly (create-group/scroll failures). Check it
-- after b2kCamOn and degrade your level gracefully.
function b2kCamStatus
   return sCamNote
end b2kCamStatus

-- Internal, called by the loop each frame: chase the followed control. The
-- follow eases, but the target is GUARANTEED on screen: if it would leave
-- the view (fast falls, teleports, lerp lag), the camera snaps to it.
command b2kCamTick
   local tLoc, tTX, tTY, tHalfW, tHalfH
   if sCamGroup is empty then exit b2kCamTick
   if sCamFollow is not empty then
      try
         set the itemDelimiter to comma
         put the loc of sCamFollow into tLoc
         put item 1 of tLoc into tTX
         put item 2 of tLoc into tTY
         if abs(tTX - sCamX) > sCamDZW / 2 then
            put sCamX + sCamLerp * (tTX - sCamX) into sCamX
         end if
         if abs(tTY - sCamY) > sCamDZH / 2 then
            put sCamY + sCamLerp * (tTY - sCamY) into sCamY
         end if
         -- the never-offscreen guarantee (32 px inside the view edges)
         put ((item 3 of the rect of sCamGroup) - (item 1 of the rect of sCamGroup)) / 2 into tHalfW
         put ((item 4 of the rect of sCamGroup) - (item 2 of the rect of sCamGroup)) / 2 into tHalfH
         if abs(tTX - sCamX) > tHalfW - 32 then put tTX into sCamX
         if abs(tTY - sCamY) > tHalfH - 32 then put tTY into sCamY
      catch tErr
         put empty into sCamFollow   -- target vanished
      end try
   end if
   b2kCamApply
end b2kCamTick

-- Internal: clamp to bounds, add shake, write the scroll (skip when same).
command b2kCamApply
   local tVW, tVH, tHalfW, tHalfH, tX, tY, tH, tV, tNow
   if sCamGroup is empty then exit b2kCamApply
   set the itemDelimiter to comma
   put (item 3 of the rect of sCamGroup) - (item 1 of the rect of sCamGroup) into tVW
   put (item 4 of the rect of sCamGroup) - (item 2 of the rect of sCamGroup) into tVH
   put tVW / 2 into tHalfW
   put tVH / 2 into tHalfH
   put sCamX into tX
   put sCamY into tY
   if sCamB1X is not empty then
      if tX > sCamB2X - tHalfW then put sCamB2X - tHalfW into tX
      if tX < sCamB1X + tHalfW then put sCamB1X + tHalfW into tX
      if tY > sCamB2Y - tHalfH then put sCamB2Y - tHalfH into tY
      if tY < sCamB1Y + tHalfH then put sCamB1Y + tHalfH into tY
   end if
   if sCamShakeAmp > 0 then
      put the milliseconds into tNow
      if tNow >= sCamShakeEnd then
         put 0 into sCamShakeAmp
      else
         put tX + (random(sCamShakeAmp * 2 + 1) - sCamShakeAmp - 1) into tX
         put tY + (random(sCamShakeAmp * 2 + 1) - sCamShakeAmp - 1) into tY
      end if
   end if
   put round(tX - tHalfW) into tH   -- content origin pinned at 0,0
   put round(tY - tHalfH) into tV
   if tH is not sCamLastH then
      set the hScroll of sCamGroup to tH
      put tH into sCamLastH
   end if
   if tV is not sCamLastV then
      set the vScroll of sCamGroup to tV
      put tV into sCamLastV
   end if
end b2kCamApply

-- =====================================================================
-- The loop  (fixed timestep, generation-guarded; one screen lock per frame)
-- =====================================================================
-- The whole frame -- body sync, contact/sensor dispatch and the app's own
-- b2kFrame drawing -- runs inside a single lock screen / unlock screen so it
-- composites in ONE redraw (no tearing between bodies and the joints/HUD a user
-- draws on top). The try/catch guarantees the unlock even if a user handler
-- throws, so a faulty event handler can never leave the screen frozen.
on b2kStep pGen
   local tNow, tElapsed, tFixed, tNext
   if not sRunning then exit b2kStep
   if pGen is not sGen then exit b2kStep
   if sPaused is not true then
      put the milliseconds into tNow
      put (tNow - sLast) / 1000 into tElapsed
      put tNow into sLast
      add tElapsed to sAccum
      if sAccum > 0.20 then put 0.20 into sAccum
      put tElapsed * 1000 into sFrameMS
      put 1 / 60 into tFixed
      repeat while sAccum >= tFixed
         b2Step sWorld, tFixed, sSub
         subtract tFixed from sAccum
      end repeat
      if sDragging then
         -- camera-aware: b2kCamMouseX/Y fall back to the raw mouse when off
         b2MouseSetTarget sDragJoint, b2kToWorldX(b2kCamMouseX()), b2kToWorldY(b2kCamMouseY())
      end if
      lock screen
      try
         b2kSyncBodies         -- lock-free; this frame's single lock is held here
         b2kInputTick          -- keyboard sample, so b2kFrame sees this frame's edges
         b2kSpritesTick        -- bound sprites follow bodies; animations advance
         b2kCamTick            -- viewport chases its target over the fresh locs
         b2kDispatchContacts
         b2kDispatchSensors
         if sFrameObj is not empty then dispatch "b2kFrame" to sFrameObj
      catch tErr               -- a user handler error must never freeze the screen
      end try
      unlock screen
   end if
   -- Pace the next step against what this frame consumed instead of a flat
   -- 16 ms scheduled AFTER the work: the flat delay made the real rate
   -- "timer cadence (~16.5 ms) plus frame cost", measured at ~50 fps under
   -- load in the Phase 0 spike. Clamp to 1..16 so a heavy frame reschedules
   -- immediately and an idle one never busy-loops.
   if sPaused is true then
      send ("b2kStep " & sGen) to me in 16 milliseconds
   else
      put 16 - (the milliseconds - tNow) into tNext
      if tNext < 1 then put 1 into tNext
      if tNext > 16 then put 16 into tNext
      send ("b2kStep " & sGen) to me in tNext milliseconds
   end if
end b2kStep

-- Advance exactly one fixed step, even while paused (drives a Step button).
command b2kStepOnce
   if not sRunning then exit b2kStepOnce
   b2Step sWorld, (1 / 60), sSub
   put 1000 / 60 into sFrameMS   -- a hand-stepped frame is one fixed step long
   if sDragging then
      b2MouseSetTarget sDragJoint, b2kToWorldX(b2kCamMouseX()), b2kToWorldY(b2kCamMouseY())
   end if
   lock screen
   try
      b2kSyncBodies
      b2kInputTick
      b2kSpritesTick
      b2kCamTick
      b2kDispatchContacts
      b2kDispatchSensors
      if sFrameObj is not empty then dispatch "b2kFrame" to sFrameObj
   catch tErr
   end try
   unlock screen
end b2kStepOnce

-- Public, standalone-safe sync: locks the screen and always unlocks, even if a
-- draw throws. This is the "the loop is stopped, redraw by hand" entry point
-- (editors and build modes call it after spawning or moving things), so it must
-- FULL-SCAN: the move-event fast path only reports bodies a b2Step moved, and a
-- stopped world steps never — relying on it here would draw nothing at all.
-- The running loop instead holds one lock across the whole frame and calls the
-- lock-free, move-event-driven b2kSyncBodies directly.
command b2kSync
   lock screen
   try
      b2kSyncAllBodies
   catch tErr
   end try
   unlock screen
end b2kSync

command b2kSyncAll
   lock screen
   try
      b2kSyncAllBodies
   catch tErr
   end try
   unlock screen
end b2kSyncAll

-- Lock-free body sync (the caller owns the screen lock). Fast path: Box2D already
-- gives us the bodies that moved during the last step, so we use that event list
-- instead of scanning every tracked control and calling body-is-awake/x/y/angle
-- across the FFI for each one.
command b2kSyncBodies
   if sNeedFullSync is true then
      b2kSyncAllBodies
      put false into sNeedFullSync
      exit b2kSyncBodies
   end if

   local tN, i, tBody, tRef, tWx, tWy, tWa, tDead
   put empty into tDead
   put b2BodiesUpdate(sWorld) into tN
   if tN <= 0 then exit b2kSyncBodies

   repeat with i = 1 to tN
      put b2BodyMoveBody(i) into tBody
      if tBody <= 0 then next repeat
      put sCtrl[tBody] into tRef
      if tRef is empty then next repeat
      if sStatic[tRef] is true then next repeat
      try
         put b2BodyMoveX(i) into tWx
         put b2BodyMoveY(i) into tWy
         if sRender[tRef] is "poly" or sRender[tRef] is "image" then
            put b2BodyMoveAngle(i) into tWa
         else
            put 0 into tWa
         end if
         b2kDrawBody tRef, tWx, tWy, tWa
      catch tErr
         put tRef & cr after tDead   -- control vanished; clean up below
      end try
   end repeat
   b2kPruneDeadRefs tDead
end b2kSyncBodies

-- Lock-free full scan (the caller owns the screen lock). Comprehensive fallback
-- for script-side edits that do not come from a Box2D step event (for example
-- changing a body type while paused).
command b2kSyncAllBodies
   local tRef, tBody, tWx, tWy, tWa, tDead
   put empty into tDead
   repeat for each key tRef in sBody
      if sStatic[tRef] is true then next repeat
      put sBody[tRef] into tBody
      if b2BodyIsAwake(tBody) is false then next repeat   -- asleep = at rest, skip redraw
      try
         put b2BodyX(tBody) into tWx
         put b2BodyY(tBody) into tWy
         if sRender[tRef] is "poly" or sRender[tRef] is "image" then
            put b2BodyAngle(tBody) into tWa
         else
            put 0 into tWa
         end if
         b2kDrawBody tRef, tWx, tWy, tWa
      catch tErr
         put tRef & cr after tDead   -- control vanished; clean up below
      end try
   end repeat
   b2kPruneDeadRefs tDead
end b2kSyncAllBodies

command b2kPruneDeadRefs pDead
   local d, tBody
   repeat for each line d in pDead
      if d is not empty then
         put sBody[d] into tBody
         if tBody is not empty then
            b2DestroyBody tBody
            delete variable sCtrl[tBody]
         end if
         -- drop every parallel entry, exactly like b2kRemove, so a vanished
         -- control leaves no stale state behind
         delete variable sBody[d]
         delete variable sShapeH[d]
         delete variable sRender[d]
         delete variable sVerts[d]
         delete variable sRad[d]
         delete variable sImgAngle[d]
         delete variable sStatic[d]
         delete variable sSpawned[d]
         delete variable sSensor[d]
         delete variable sDrawKey[d]
      end if
   end repeat
end b2kPruneDeadRefs

command b2kDrawBody pRef, pWx, pWy, pWa
   local tSx, tSy, tKey
   switch sRender[pRef]
      case "poly"
         b2kDrawPoly pRef, pWx, pWy, pWa
         break
      case "ball"
         b2kDrawBall pRef, pWx, pWy
         break
      case "image"
         b2kDrawImage pRef, pWx, pWy, pWa
         break
      default
         put round(b2kToScreenX(pWx)) into tSx
         put round(b2kToScreenY(pWy)) into tSy
         put tSx & "," & tSy into tKey
         if sDrawKey[pRef] is tKey then exit b2kDrawBody
         set the loc of pRef to tKey
         put tKey into sDrawKey[pRef]
   end switch
end b2kDrawBody

command b2kDrawPoly pRef, pWx, pWy, pWa
   local c, s, p, pt, tPts, tFirst, tKey
   put round(b2kToScreenX(pWx)) & "," & round(b2kToScreenY(pWy)) & "," & round(pWa * 1800 / kPI) into tKey
   if sDrawKey[pRef] is tKey then exit b2kDrawPoly
   put cos(pWa) into c
   put sin(pWa) into s
   put empty into tPts
   put empty into tFirst
   repeat for each line p in sVerts[pRef]
      put b2kCorner(pWx, pWy, item 1 of p, item 2 of p, c, s) into pt
      if tFirst is empty then put pt into tFirst
      put pt & cr after tPts
   end repeat
   put tFirst after tPts
   set the points of pRef to tPts
   put tKey into sDrawKey[pRef]
end b2kDrawPoly

command b2kDrawBall pRef, pWx, pWy
   local tRp, tSx, tSy, tKey
   put sRad[pRef] * sScale into tRp
   put round(b2kToScreenX(pWx)) into tSx
   put round(b2kToScreenY(pWy)) into tSy
   put tSx & "," & tSy & "," & round(tRp) into tKey
   if sDrawKey[pRef] is tKey then exit b2kDrawBall
   set the rect of pRef to round(tSx - tRp), round(tSy - tRp), round(tSx + tRp), round(tSy + tRp)
   put tKey into sDrawKey[pRef]
end b2kDrawBall

-- Position + rotate an image control to follow its body. The body angle is in
-- radians, CCW-positive in the sim's y-up frame; with this kit's y-flip that is
-- also a CCW screen rotation, which matches `the angle` (CCW-positive). We keep
-- the image at its design size and skip redundant re-rotations (each set of the
-- angle resamples the image, but always from the original, so there's no drift).
command b2kDrawImage pRef, pWx, pWy, pWa
   local tDeg, tSx, tSy, tKey
   put ((round(pWa * 180 / kPI) mod 360) + 360) mod 360 into tDeg
   put round(b2kToScreenX(pWx)) into tSx
   put round(b2kToScreenY(pWy)) into tSy
   put tSx & "," & tSy & "," & tDeg into tKey
   if sDrawKey[pRef] is tKey then exit b2kDrawImage
   if sImgAngle[pRef] is not tDeg then
      set the angle of pRef to tDeg
      put tDeg into sImgAngle[pRef]
   end if
   set the loc of pRef to tSx & "," & tSy
   put tKey into sDrawKey[pRef]
end b2kDrawImage

function b2kCorner pWx, pWy, pLx, pLy, c, s
   local rx, ry
   put pLx * c - pLy * s into rx
   put pLx * s + pLy * c into ry
   return round(b2kToScreenX(pWx + rx)) & "," & round(b2kToScreenY(pWy + ry))
end b2kCorner

-- Local-space outline (metres) approximating a capsule of half-length pL and
-- radius pR: two half-circle caps joined by straight edges. Built along local X
-- and transposed to local Y when the capsule is vertical. Used only to draw the
-- graphic; the collision shape is a true Box2D capsule.
function b2kCapsuleVerts pL, pR, pHoriz
   local tV, i, a, lx, ly
   local n
   put 8 into n
   put empty into tV
   repeat with i = 0 to n               -- right cap: -90 -> +90 degrees
      put (-90 + 180 * i / n) * kPI / 180 into a
      put pL + pR * cos(a) into lx
      put pR * sin(a) into ly
      if pHoriz then put lx & "," & ly & cr after tV
      else put ly & "," & lx & cr after tV
   end repeat
   repeat with i = 0 to n               -- left cap: +90 -> +270 degrees
      put (90 + 180 * i / n) * kPI / 180 into a
      put - pL + pR * cos(a) into lx
      put pR * sin(a) into ly
      if pHoriz then put lx & "," & ly & cr after tV
      else put ly & "," & lx & cr after tV
   end repeat
   return tV
end b2kCapsuleVerts

command b2kDispatchContacts
   local tN, i, tA, tB
   -- Always snapshot so begin/end counts are current even with no target.
   put b2ContactsUpdate(sWorld) into tN
   if sContactObj is empty then exit b2kDispatchContacts
   repeat with i = 1 to tN
      put sCtrl[b2ContactBeginBodyA(i)] into tA
      put sCtrl[b2ContactBeginBodyB(i)] into tB
      dispatch "b2kContact" to sContactObj with tA, tB
   end repeat
   repeat with i = 1 to b2ContactEndCount()
      put sCtrl[b2ContactEndBodyA(i)] into tA
      put sCtrl[b2ContactEndBodyB(i)] into tB
      dispatch "b2kEndContact" to sContactObj with tA, tB
   end repeat
end b2kDispatchContacts

-- Snapshot sensor begin/end overlaps each frame and (if a target is set) deliver
-- them as on b2kSensorEnter / on b2kSensorExit. Sensor and visitor shapes are
-- mapped back to their controls via the shape's body.
command b2kDispatchSensors
   local tN, i, tS, tV
   put b2SensorsUpdate(sWorld) into tN
   if sContactObj is empty then exit b2kDispatchSensors
   repeat with i = 1 to tN
      put sCtrl[b2ShapeBody(b2SensorBeginSensorShape(i))] into tS
      put sCtrl[b2ShapeBody(b2SensorBeginVisitorShape(i))] into tV
      dispatch "b2kSensorEnter" to sContactObj with tS, tV
   end repeat
   repeat with i = 1 to b2SensorEndCount()
      put sCtrl[b2ShapeBody(b2SensorEndSensorShape(i))] into tS
      put sCtrl[b2ShapeBody(b2SensorEndVisitorShape(i))] into tV
      dispatch "b2kSensorExit" to sContactObj with tS, tV
   end repeat
end b2kDispatchSensors
-- <<< END EMBEDDED KIT <<<
