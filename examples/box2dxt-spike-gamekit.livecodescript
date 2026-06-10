-- =====================================================================
-- box2dxt-spike-gamekit.livecodescript  ·  Game Kit Phase 0 runtime spike
--
-- PURPOSE: answer the "(verify in OXT)" questions in docs/game-engine-spec.md
-- on real OXT hardware BEFORE any Game Kit module is built. See plan.md
-- Phase 0 for the S0-S10 test table this implements.
--
-- HOW TO RUN
--   1. In OXT, make a new stack. Put this whole file into the STACK script.
--   2. Make sure the box2dxt extension is loaded (S7-S10 need it; S0-S6 run
--      without it). Close and reopen the stack.
--   3. Click the test buttons top to bottom. Follow the STATUS box; some
--      tests judge themselves, some ask your eyes. Press STOP between tests.
--   4. When done, click "Copy report" and paste the report back to the
--      developer/assistant. Every line matters, including the ENV lines.
--
-- The stage rebuilds itself per test; STOP tears down and wipes it. This
-- file is throwaway scaffolding - it is not an example of Kit style.
-- =====================================================================

local gSpikeGen, gSpikeTest, gExtOK, gEnvDone, gReportN
local gProbeN, gProbeLast, gProbeSum, gProbeMax
local gS1MaxChord, gS1Seen, gS1RawDown, gS1RawUp
local gSheetData, gSheetAlpha
local gS3Frame, gS3Tick, gS4Motion, gS4On, gS4Ang
local gS5Made
local gS8Phase, gS8T0, gS8MinY, gS8Tail, gS8Ball
local gS9Hero, gS9Logged
local gS10T0, gS10Logged, gSpFrame, gSpNext, gSpAng, gSpCX, gSpCY
local gFpsN, gFpsT0, gFpsLast, gFpsMin, gFpsSum, gFpsSamples

constant kSpikeDeg = 0.0174532925
-- 4-frame 32x32 animated GIF (red/green/blue/yellow, 2px black border, 250 ms
-- per frame, loops forever). Generated offline; used by S5.
constant kSpikeGifB64 = "R0lGODlhIAAgAIEAAOZGRgAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQAGQAAACwAAAAAIAAgAAAIbAADCBxIsKDBgwgTKlwIoKHDhxAjSiQosaLFhxQvaoyYcaNHAB0/agwp0iLJkhMHohypcqXJli5TCoxZ8SRNkDBvOrRJk2dMny6BrhSKkmhJoyKRflTqkelGpyxn6sSYcyrUi1dfLtzKtWvXgAAh+QQBGQACACwCAAIAHAAcAIFGyHgAAAAAAAAAAAAIMAABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkwQDAgAh+QQBGQACACwCAAIAHAAcAIFQgv8AAAAAAAAAAAAIMAABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkwQDAgAh+QQBGQACACwCAAIAHAAcAIHwyEYAAAAAAAAAAAAIMAABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkwQDAgA7"

-- =====================================================================
-- Lifecycle
-- =====================================================================
on openCard
   if there is no button "skbtn_S0" then buildSpikeUI
   if gEnvDone is not true then
      put true into gEnvDone
      put 0 into gReportN
      put the milliseconds & "_" & random(100000) into gSpikeGen
      spikeLog "=== Box2Dxt Game Kit spike (Phase 0) ==="
      spikeLog "Run the buttons top to bottom; STOP between tests; Copy report when done."
      spikeEnvReport
   end if
   pass openCard
end openCard

on closeCard
   spikeStopTest true
   pass closeCard
end closeCard

-- =====================================================================
-- UI (built once, programmatically, like the examples do)
-- =====================================================================
command buildSpikeUI
   local tTop, tNames, tLabels, i, tName
   set the width of this stack to 980
   set the height of this stack to 700
   put "S0,S1,S3,S4,S5,S6,S7,S8,S9,S10,stop,copy" into tNames
   put "S0 env + timer|S1+S2 keyboard|S3 sprite scroll|S4 accel + motion|S5 gif frames|S6 flip image|S7 rays (Kit)|S8 one-way (Kit)|S9 camera (Kit)|S10 perf (Kit)|STOP test|Copy report" into tLabels
   put 10 into tTop
   set the itemDelimiter to comma
   repeat with i = 1 to the number of items of tNames
      put item i of tNames into tName
      create button ("skbtn_" & tName)
      set the rect of it to 10, tTop, 170, tTop + 26
      set the itemDelimiter to "|"
      set the label of it to item i of tLabels
      set the itemDelimiter to comma
      set the traversalOn of it to false
      set the autoHilite of it to true
      add 32 to tTop
   end repeat
   create field "skStatus"
   set the rect of it to 190, 10, 960, 108
   set the lockText of it to true
   set the traversalOn of it to false
   set the textSize of it to 12
   create field "skReport"
   set the rect of it to 190, 560, 960, 690
   set the lockText of it to true
   set the traversalOn of it to false
   set the textSize of it to 11
   set the vScrollbar of it to true
   spikeStatus "Ready. Click S0 first, then work down the column."
   try
      focus on nothing
   catch tErr
   end try
end buildSpikeUI

-- One dispatcher for every button (the buttons carry no scripts).
on mouseUp
   local tName
   put the short name of the target into tName
   if char 1 to 6 of tName is "skbtn_" then
      switch tName
         case "skbtn_S0"
            runS0
            break
         case "skbtn_S1"
            runS1
            break
         case "skbtn_S3"
            runS3
            break
         case "skbtn_S4"
            runS4
            break
         case "skbtn_S5"
            runS5
            break
         case "skbtn_S6"
            runS6
            break
         case "skbtn_S7"
            runS7
            break
         case "skbtn_S8"
            runS8
            break
         case "skbtn_S9"
            runS9
            break
         case "skbtn_S10"
            runS10
            break
         case "skbtn_stop"
            spikeStopTest false
            break
         case "skbtn_copy"
            spikeCopyReport
            break
      end switch
      exit mouseUp
   end if
   if gSpikeTest is "S9" or gSpikeTest is "S10" then
      try
         b2kRelease
      catch tErr
      end try
   end if
end mouseUp

-- Grab test during S9/S10: world coords = mouse + the viewport's scroll
-- (this is exactly the b2kCamMouse mapping the camera module will own).
on mouseDown
   local tName, tScroll
   put the short name of the target into tName
   if char 1 to 6 of tName is "skbtn_" then exit mouseDown
   if gSpikeTest is "S9" then
      if the mouseLoc is within the rect of group "sk_cam" then
         put the hScroll of group "sk_cam" into tScroll
         get b2kGrab(the mouseH + tScroll, the mouseV)
         if it is not empty then
            spikeLogOnce "s9grab", "S9 grab with scroll-corrected coords: WORKS (camera mouse mapping confirmed)"
         end if
      end if
      exit mouseDown
   end if
   if gSpikeTest is "S10" then
      get b2kGrab(the mouseH, the mouseV)
   end if
end mouseDown

-- S1 intel: raw event counts reveal this platform's auto-repeat behaviour.
on rawKeyDown pKeyCode
   if gSpikeTest is "S1" then
      add 1 to gS1RawDown
      put 1 into gS1Seen[pKeyCode]
   end if
   pass rawKeyDown
end rawKeyDown

on rawKeyUp pKeyCode
   if gSpikeTest is "S1" then
      add 1 to gS1RawUp
   end if
   pass rawKeyUp
end rawKeyUp

-- =====================================================================
-- Report helpers
-- =====================================================================
command spikeLog pLine
   add 1 to gReportN
   put gReportN & ". " & pLine & cr after field "skReport"
   set the vScroll of field "skReport" to 100000
end spikeLog

command spikeLogOnce pKey, pLine
   if gS1Seen["once_" & pKey] is 1 then exit spikeLogOnce
   put 1 into gS1Seen["once_" & pKey]
   spikeLog pLine
end spikeLogOnce

command spikeStatus pText
   set the text of field "skStatus" to pText
end spikeStatus

command spikeCopyReport
   try
      set the clipboardData["text"] to the text of field "skReport"
      spikeStatus "Report copied to the clipboard - paste it back to the developer."
   catch tErr
      spikeStatus "Could not reach the clipboard; select the report text and copy by hand."
   end try
end spikeCopyReport

-- =====================================================================
-- Start/stop plumbing
-- =====================================================================
function spikeBeginTest pId, pNeedsExt
   spikeStopTest true
   if pNeedsExt is true and gExtOK is not true then
      spikeLog pId & " SKIPPED - box2dxt extension not loaded"
      spikeStatus pId & " needs the box2dxt extension. Load it and reopen the stack."
      return false
   end if
   put pId into gSpikeTest
   put the milliseconds & "_" & random(100000) into gSpikeGen
   spikeFpsReset
   return true
end spikeBeginTest

command spikeStopTest pQuiet
   local tWas
   put the milliseconds & "_" & random(100000) into gSpikeGen
   put gSpikeTest into tWas
   put empty into gSpikeTest
   if gFpsSamples > 0 then
      if tWas is "S9" or tWas is "S10" then
         spikeLog tWas & " fps: last " & gFpsLast & ", min " & gFpsMin & ", avg " & round(gFpsSum / gFpsSamples * 10) / 10 & " over " & gFpsSamples & " s"
      end if
   end if
   if tWas is "S1" then s1LogSummary
   try
      b2kTeardown
   catch tErr
   end try
   try
      set the acceleratedRendering of this stack to false
   catch tErr
   end try
   spikeWipeControls "sk_"
   put false into gS4Motion
   put false into gS4On
   put false into gS5Made
   if pQuiet is not true then
      spikeStatus "Stopped. Pick the next test."
      spikeLog "-- test stopped --"
   end if
end spikeStopTest

-- Delete every stage control (names start "sk_"); UI uses skbtn_/skStatus/
-- skReport so it survives. Restart the scan after each delete because
-- removing a group takes its children with it.
command spikeWipeControls pPrefix
   local tAgain, i, tName, tLen
   put the number of chars of pPrefix into tLen
   put true into tAgain
   repeat while tAgain
      put false into tAgain
      repeat with i = 1 to the number of controls of this card
         put the short name of control i of this card into tName
         if char 1 to tLen of tName is pPrefix then
            delete control i of this card
            put true into tAgain
            exit repeat
         end if
      end repeat
   end repeat
end spikeWipeControls

command spikeFpsReset
   put 0 into gFpsN
   put empty into gFpsT0
   put empty into gFpsLast
   put empty into gFpsMin
   put 0 into gFpsSum
   put 0 into gFpsSamples
end spikeFpsReset

-- Count b2kFrame dispatches; once a second fold them into last/min/avg and
-- repaint the live readout line (plus the native step time from b2kProfile).
command spikeFpsTick
   local tNow, tLine
   put the milliseconds into tNow
   add 1 to gFpsN
   if gFpsT0 is empty then
      put tNow into gFpsT0
      exit spikeFpsTick
   end if
   if tNow - gFpsT0 >= 1000 then
      put round(gFpsN * 1000 / (tNow - gFpsT0) * 10) / 10 into gFpsLast
      if gFpsMin is empty or gFpsLast < gFpsMin then put gFpsLast into gFpsMin
      add gFpsLast to gFpsSum
      add 1 to gFpsSamples
      put 0 into gFpsN
      put tNow into gFpsT0
      put "fps " & gFpsLast & "   min " & gFpsMin & "   avg " & round(gFpsSum / max(1, gFpsSamples) * 10) / 10 into tLine
      try
         set the itemDelimiter to comma
         put "   |   native step " & item 1 of b2kProfile() & " ms" after tLine
      catch tErr
      end try
      put tLine into line 5 of field "skStatus"
   end if
end spikeFpsTick

-- =====================================================================
-- S0 - environment + send-in-16 timer cadence (spec 2.6 pacing baseline)
-- =====================================================================
command runS0
   get spikeBeginTest("S0", false)
   spikeEnvReport
   spikeStatus "S0 logs the environment and measures 60 idle send-in-16-ms ticks." & cr & "Wait ~1 second; the cadence line appears in the report."
end runS0

command spikeEnvReport
   spikeLog "ENV platform=" & the platform & "  system=" & the systemVersion & "  engine=" & the version
   spikeLog "ENV screen=" & the screenRect & "  stack=" & the rect of this stack
   try
      spikeLog "ENV box2dxt ABI=" & b2Version() & " (extension loaded)"
      put true into gExtOK
   catch tErr
      put false into gExtOK
      spikeLog "ENV box2dxt extension NOT LOADED - S7-S10 will be skipped"
   end try
   put 0 into gProbeN
   put 0 into gProbeSum
   put empty into gProbeMax
   put the milliseconds into gProbeLast
   send ("spikeProbeTick " & gSpikeGen) to me in 16 milliseconds
end spikeEnvReport

command spikeProbeTick pGen
   local tNow, tDelta
   if pGen is not gSpikeGen then exit spikeProbeTick
   put the milliseconds into tNow
   put tNow - gProbeLast into tDelta
   put tNow into gProbeLast
   add tDelta to gProbeSum
   if gProbeMax is empty or tDelta > gProbeMax then put tDelta into gProbeMax
   add 1 to gProbeN
   if gProbeN >= 60 then
      spikeLog "S0 send-in-16 cadence: avg " & round(gProbeSum / 60 * 10) / 10 & " ms, max " & gProbeMax & " ms over 60 idle ticks (16 = ideal)"
      exit spikeProbeTick
   end if
   send ("spikeProbeTick " & pGen) to me in 16 milliseconds
end spikeProbeTick

-- =====================================================================
-- S1 + S2 - the keysDown poll: held keys, chords, case-shift, raw repeat
-- =====================================================================
command runS1
   if spikeBeginTest("S1", false) is false then exit runS1
   put 0 into gS1MaxChord
   put 0 into gS1RawDown
   put 0 into gS1RawUp
   put empty into gS1Seen
   send ("spikePollKeys " & gSpikeGen) to me in 60 milliseconds
end runS1

command spikePollKeys pGen
   local tHeld, tNames, tK, tN
   if pGen is not gSpikeGen then exit spikePollKeys
   if gSpikeTest is not "S1" then exit spikePollKeys
   put the keysDown into tHeld
   set the itemDelimiter to comma
   if tHeld is not empty then
      put the number of items of tHeld into tN
      if tN > gS1MaxChord then put tN into gS1MaxChord
      repeat for each item tK in tHeld
         put 1 into gS1Seen[tK]
      end repeat
   end if
   put empty into tNames
   repeat for each item tK in tHeld
      put spikeKeyName(tK) & " " after tNames
   end repeat
   spikeStatus "S1/S2 KEYBOARD - the held list must always match your fingers." & cr & "Do: 1) hold LEFT+UP+SPACE together  2) tap w  3) hold SHIFT and tap w  4) press STOP to log" & cr & "held codes: " & tHeld & cr & "held names: " & tNames & cr & "max chord " & gS1MaxChord & "   rawKeyDown " & gS1RawDown & "   rawKeyUp " & gS1RawUp
   send ("spikePollKeys " & pGen) to me in 60 milliseconds
end spikePollKeys

command s1LogSummary
   local tArrows
   spikeLog "S1 max simultaneous keys seen: " & gS1MaxChord & " (3 or more = PASS for chords)"
   put empty into tArrows
   if gS1Seen[65361] is 1 then put "left " after tArrows
   if gS1Seen[65362] is 1 then put "up " after tArrows
   if gS1Seen[65363] is 1 then put "right " after tArrows
   if gS1Seen[65364] is 1 then put "down " after tArrows
   if gS1Seen[32] is 1 then put "space " after tArrows
   spikeLog "S1 keys seen during test: " & tArrows
   if gS1Seen[119] is 1 and gS1Seen[87] is 1 then
      spikeLog "S2 case-shift CONFIRMED: w=119 and W=87 both observed (Kit must bind both)"
   else
      spikeLog "S2 case-shift: saw w(119)=" & (gS1Seen[119] is 1) & " W(87)=" & (gS1Seen[87] is 1) & " (do step 3 next time if both false)"
   end if
   spikeLog "S1 raw events while polling: down " & gS1RawDown & ", up " & gS1RawUp & " (auto-repeat behaviour intel)"
end s1LogSummary

function spikeKeyName pCode
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
         return "return"
      case 65307
         return "esc"
      case 65289
         return "tab"
      case 65505
      case 65506
         return "shift"
      case 65507
      case 65508
         return "ctrl"
      case 65513
      case 65514
         return "alt"
   end switch
   if pCode >= 97 and pCode <= 122 then return numToChar(pCode)
   if pCode >= 65 and pCode <= 90 then return numToChar(pCode)
   if pCode >= 48 and pCode <= 57 then return numToChar(pCode)
   return pCode
end spikeKeyName

-- =====================================================================
-- S3 - spritesheet via clipped group + scroll (the chosen mechanism)
-- S4 - the same while the stack composites with acceleratedRendering and
--      the sprite group is a moving dynamic layer
-- =====================================================================
command runS3
   if spikeBeginTest("S3", false) is false then exit runS3
   spikeEnsureSheet
   get spikeMakeSprite("sk_spr", 320, 240)
   if it is empty then
      spikeStatus "S3 ABORTED - could not build a group from script (see report)."
      put empty into gSpikeTest
      exit runS3
   end if
   put 1 into gS3Frame
   put 0 into gS3Tick
   put 0 into gS4Ang
   spikeStatus "S3 SPRITE SCROLL - the strip at top right is the whole sheet; the square below" & cr & "is one clipped 64px cell, cycling red->green->blue->yellow at ~10 fps." & cr & "PASS if: exactly ONE cell shows, black border intact on all 4 sides (no neighbour" & cr & "bleed), no scrollbars appear, colours cycle. Then click S4."
   send ("spikeAnimTick " & gSpikeGen) to me in 33 milliseconds
end runS3

command runS4
   if gSpikeTest is not "S3" then
      spikeStatus "Run S3 first - S4 toggles compositing + motion on the S3 sprite."
      exit runS4
   end if
   if gS4On is true then
      put false into gS4On
      put false into gS4Motion
      try
         set the acceleratedRendering of this stack to false
         set the layerMode of group "sk_spr" to "static"
      catch tErr
         spikeLog "S4 toggle-off errored: " & tErr
      end try
      spikeLog "S4 toggled OFF (back to plain rendering)"
      exit runS4
   end if
   put true into gS4On
   put true into gS4Motion
   try
      set the acceleratedRendering of this stack to true
      set the layerMode of group "sk_spr" to "dynamic"
      spikeLog "S4 acceleratedRendering=true, sprite layerMode=dynamic, orbit motion on"
   catch tErr
      spikeLog "S4 FAIL enabling compositor: " & tErr
   end try
   spikeStatus "S4 ACCEL + MOTION - the animating cell now orbits the stage under the GPU" & cr & "compositor. PASS if: still one clean cell, no trails/smears, motion smooth," & cr & "animation keeps cycling. Click S4 again to toggle off; STOP to finish and log."
end runS4

command spikeAnimTick pGen
   if pGen is not gSpikeGen then exit spikeAnimTick
   if gSpikeTest is not "S3" then exit spikeAnimTick
   add 1 to gS3Tick
   if gS3Tick mod 3 = 0 then
      put (gS3Frame mod 4) + 1 into gS3Frame
      set the hScroll of group "sk_spr" to (gS3Frame - 1) * 64
   end if
   if gS4Motion is true then
      add 4 to gS4Ang
      set the loc of group "sk_spr" to round(500 + 170 * cos(gS4Ang * kSpikeDeg)), round(330 + 140 * sin(gS4Ang * kSpikeDeg))
   end if
   send ("spikeAnimTick " & pGen) to me in 33 milliseconds
end spikeAnimTick

-- =====================================================================
-- S5 - animated GIF: frameCount / currentFrame / repeatCount control
-- =====================================================================
command runS5
   local tN
   if gS5Made is not true then
      if spikeBeginTest("S5", false) is false then exit runS5
      put true into gS5Made
      create image "sk_gif"
      set the topLeft of it to 420, 200
      set the text of image "sk_gif" to base64Decode(kSpikeGifB64)
      put the frameCount of image "sk_gif" into tN
      spikeLog "S5 gif frameCount=" & tN & " (expect 4)"
      try
         set the repeatCount of image "sk_gif" to -1
      catch tErr
         spikeLog "S5 set repeatCount -1 errored: " & tErr
      end try
      spikeStatus "S5 GIF - the small square should animate red->green->blue->yellow on its own" & cr & "(engine playback, ~4 fps). Click S5 again to STOP playback and step frames by hand."
      exit runS5
   end if
   try
      if the repeatCount of image "sk_gif" is not 0 then
         set the repeatCount of image "sk_gif" to 0
         spikeLog "S5 playback stopped (repeatCount 0); further clicks step currentFrame"
         spikeStatus "S5 GIF manual mode - each S5 click advances one frame. PASS if the colour" & cr & "steps exactly once per click, in order, wrapping after yellow."
         exit runS5
      end if
      set the currentFrame of image "sk_gif" to (the currentFrame of image "sk_gif" mod the frameCount of image "sk_gif") + 1
      spikeLog "S5 stepped to frame " & the currentFrame of image "sk_gif"
   catch tErr
      spikeLog "S5 FAIL manual frame control: " & tErr
   end try
end runS5

-- =====================================================================
-- S6 - flip image horizontal (mirrored-sheet strategy), self-judging
-- =====================================================================
command runS6
   local tData, tRed
   if spikeBeginTest("S6", false) is false then exit runS6
   spikeEnsureSheet
   try
      clone image "sk_sheet"
      set the name of it to "sk_flip"
      set the topLeft of image "sk_flip" to 420, 180
      flip image "sk_flip" horizontal
      put the imageData of image "sk_flip" into tData
      -- pixel (4,4) sits inside frame 1 (red, R=230) on the original; after a
      -- horizontal flip it must show frame 4 (yellow, R=240)
      put byteToNum(byte ((4 * 256 + 4) * 4 + 2) of tData) into tRed
      if tRed >= 235 and tRed <= 245 then
         spikeLog "S6 PASS flip image horizontal works (mirror pixel check R=" & tRed & ")"
      else
         spikeLog "S6 CHECK flip ran but mirror pixel R=" & tRed & " (expected ~240) - eyeball the two strips"
      end if
      spikeStatus "S6 FLIP - two strips at top right: the lower one must be the upper one" & cr & "mirrored left-right (yellow first). The report line gives the byte-level verdict."
   catch tErr
      spikeLog "S6 FAIL flip image errored: " & tErr & " (Kit will fall back to imageData row-mirroring)"
      spikeStatus "S6 flip errored - see report. The Kit has a scripted fallback, so this is" & cr & "informational, not fatal."
   end try
end runS6

-- =====================================================================
-- S7 - ray semantics for the player ground probe (needs the Kit + world)
-- =====================================================================
command runS7
   local tShort, tLong, tAll, tVerdict, tFirst
   if spikeBeginTest("S7", true) is false then exit runS7
   b2kSetup
   create graphic "sk_s7ground"
   set the style of it to "rectangle"
   set the rect of it to 200, 500, 600, 540
   set the filled of it to true
   set the backgroundColor of it to "120,120,130"
   b2kAddStatic the long id of graphic "sk_s7ground"
   create graphic "sk_s7cap"
   set the style of it to "rectangle"
   set the rect of it to 380, 300, 420, 380
   set the filled of it to true
   set the backgroundColor of it to "240,170,70"
   b2kAddCapsule the long id of graphic "sk_s7cap"
   -- ray A starts AND ends inside the capsule: Box2D should report nothing
   put b2kRayHit(400, 340, 400, 360) into tShort
   if tShort is empty then
      spikeLog "S7 ray fully inside own capsule: no hit (self ignored) - as designed"
   else
      spikeLog "S7 CHECK ray inside own capsule hit: " & the short name of tShort
   end if
   -- ray B starts inside the capsule and reaches the ground: the ground probe
   put b2kRayHit(400, 340, 400, 560) into tLong
   if tLong is empty then
      spikeLog "S7 FAIL downward ray hit nothing (expected the ground)"
   else
      spikeLog "S7 downward ray hit: " & the short name of tLong & ", dist " & b2kRayDist() & " px (expect ~160), normalY " & b2kRayHitNormalY() & " (expect ~ -1)"
      if the short name of tLong is "sk_s7ground" then
         put "S7 PASS self-skip: ray from inside the player reports the ground" into tVerdict
      else
         put "S7 FAIL ray reported " & the short name of tLong & " instead of the ground (fallback: b2kRayHitAll + skip self)" into tVerdict
      end if
      spikeLog tVerdict
   end if
   put b2kRayHitAll(400, 340, 400, 560) into tAll
   if tAll is empty then
      spikeLog "S7 ray-all returned 0 hits"
   else
      put line 1 of tAll into tFirst
      spikeLog "S7 ray-all returned " & the number of lines of tAll & " hit(s); first = " & the short name of tFirst
   end if
   spikeStatus "S7 RAYS ran and judged itself - read the three report lines. The orange" & cr & "rectangle is the player capsule, grey is the ground. STOP when done."
end runS7

-- =====================================================================
-- S8 - one-way platforms: b2kWall both windings, then a chain. The ball is
-- pushed up THROUGH the line, then falls back; each phase judges itself.
-- =====================================================================
command runS8
   if spikeBeginTest("S8", true) is false then exit runS8
   put "wallLR" into gS8Phase
   s8Build
   spikeStatus "S8 ONE-WAY - watch the ball: it should rise THROUGH the line, then land ON it." & cr & "Three automatic phases: blue wall (L-to-R winding), red wall (R-to-L), green chain." & cr & "Each phase logs its own verdict after ~5 s. STOP after the chain phase logs."
end runS8

command s8Build
   local tColor
   try
      b2kTeardown
   catch tErr
   end try
   spikeWipeControls "sk_s8"
   b2kSetup
   b2kFrameTarget the long id of me
   create graphic "sk_s8wall"
   set the style of it to "line"
   set the points of it to "250,330" & cr & "550,330"
   set the lineSize of it to 3
   switch gS8Phase
      case "wallLR"
         set the foregroundColor of graphic "sk_s8wall" to "70,130,255"
         b2kWall 250, 330, 550, 330
         break
      case "wallRL"
         set the foregroundColor of graphic "sk_s8wall" to "230,80,80"
         b2kWall 550, 330, 250, 330
         break
      case "chain"
         set the foregroundColor of graphic "sk_s8wall" to "60,180,90"
         -- top surface listed right-to-left = solid side up; outer points are
         -- ghost vertices, so the collidable span is 550 -> 250
         get b2kSmoothGround("650,330" & cr & "550,330" & cr & "250,330" & cr & "150,330")
         break
   end switch
   create graphic "sk_s8ball"
   set the style of it to "oval"
   set the rect of it to 382, 542, 418, 578
   set the filled of it to true
   set the backgroundColor of it to "240,170,70"
   put the long id of graphic "sk_s8ball" into gS8Ball
   b2kAddBall gS8Ball
   b2kPush gS8Ball, 0, -620
   put the milliseconds into gS8T0
   put 99999 into gS8MinY
   put empty into gS8Tail
   b2kStart
end s8Build

command s8Frame
   local tY, tWentAbove, tResting, tSum, tMin, tMax, tLine, tAvg, tVerdict
   set the itemDelimiter to comma
   put item 2 of b2kPosition(gS8Ball) into tY
   if tY is empty then exit s8Frame
   if tY < gS8MinY then put tY into gS8MinY
   put tY & cr after gS8Tail
   if the number of lines of gS8Tail > 20 then delete line 1 of gS8Tail
   if the milliseconds - gS8T0 < 4500 and tY < 900 then exit s8Frame
   -- judge this phase
   put (gS8MinY < 308) into tWentAbove
   put 0 into tSum
   put empty into tMin
   put empty into tMax
   repeat for each line tLine in gS8Tail
      add tLine to tSum
      if tMin is empty or tLine < tMin then put tLine into tMin
      if tMax is empty or tLine > tMax then put tLine into tMax
   end repeat
   put tSum / max(1, the number of lines of gS8Tail) into tAvg
   put (tMax - tMin < 4 and tAvg > 304 and tAvg < 322) into tResting
   if tWentAbove and tResting then
      put "ONE-WAY OK (rose through, landed on top)" into tVerdict
   else
      if tWentAbove then
         put "NOT one-way: passed up through AND fell back through" into tVerdict
      else
         if gS8MinY > 330 and gS8MinY < 380 then
            put "blocked from below (solid both ways or solid-down winding)" into tVerdict
         else
            put "inconclusive (minY " & round(gS8MinY) & ", restingAvg " & round(tAvg) & ")" into tVerdict
         end if
      end if
   end if
   spikeLog "S8 phase " & gS8Phase & ": " & tVerdict
   switch gS8Phase
      case "wallLR"
         put "wallRL" into gS8Phase
         s8Build
         break
      case "wallRL"
         put "chain" into gS8Phase
         s8Build
         break
      default
         spikeLog "S8 done - all three phases judged"
         b2kStop
         put empty into gSpikeTest
   end switch
end s8Frame

-- =====================================================================
-- S9 - camera: a clipped viewport group scrolled to follow a hero while
-- 20 bodies tumble. Also proves the Kit draw path inside a scrolled group
-- and the scroll-corrected mouse grab. (needs the Kit)
-- =====================================================================
command runS9
   local i, tX, tY, tSize, tRef
   if spikeBeginTest("S9", true) is false then exit runS9
   b2kSetup
   b2kFrameTarget the long id of me
   get spikeNewGroup("sk_cam", 100, 140)
   if it is empty then
      spikeStatus "S9 ABORTED - could not build a group from script (see report)."
      put empty into gSpikeTest
      exit runS9
   end if
   -- world floor: one solid slab, 2000 px wide (the level is ~3 cards wide)
   create graphic "sk_s9ground" in group "sk_cam"
   set the style of it to "rectangle"
   set the rect of it to 100, 500, 2100, 540
   set the filled of it to true
   set the backgroundColor of it to "90,90,100"
   b2kAddStatic the long id of graphic "sk_s9ground"
   -- level bounds (invisible segments)
   b2kWall 100, 140, 100, 540
   b2kWall 2100, 140, 2100, 540
   b2kWall 100, 140, 2100, 140
   -- 20 tumbling boxes spread along the level
   repeat with i = 1 to 20
      put 140 + i * 93 into tX
      put 180 + (i mod 3) * 50 into tY
      put 28 + (i mod 4) * 8 into tSize
      create graphic ("sk_s9box" & i) in group "sk_cam"
      set the style of it to "rectangle"
      set the rect of it to tX, tY, tX + tSize, tY + tSize
      set the filled of it to true
      set the backgroundColor of it to (120 + i * 6) & ",80," & (220 - i * 7)
      put the long id of it into tRef
      try
         set the layerMode of it to "dynamic"
      catch tErr
      end try
      b2kAddBox tRef
      b2kPush tRef, random(240) - 120, 0 - random(120)
   end repeat
   -- the hero: a ball driven rightward; the camera follows it
   create graphic "sk_s9hero" in group "sk_cam"
   set the style of it to "oval"
   set the rect of it to 140, 280, 180, 320
   set the filled of it to true
   set the backgroundColor of it to "250,210,60"
   put the long id of it into gS9Hero
   try
      set the layerMode of it to "dynamic"
   catch tErr
   end try
   b2kAddBall gS9Hero
   -- freeze the viewport: clip to a 600x400 window onto the 2000px world
   set the lockLoc of group "sk_cam" to true
   set the rect of group "sk_cam" to 100, 140, 700, 540
   set the hScroll of group "sk_cam" to 0
   try
      set the acceleratedRendering of this stack to true
      set the layerMode of group "sk_cam" to "scrolling"
      spikeLog "S9 compositor: acceleratedRendering true, viewport layerMode=scrolling"
   catch tErr
      spikeLog "S9 compositor setup errored: " & tErr & " (running unaccelerated)"
   end try
   put false into gS9Logged
   b2kStart
   spikeStatus "S9 CAMERA - a 600x400 window onto a 2000px level; the yellow ball runs right" & cr & "and the view follows (teleports back at the end, forever). PASS if: scroll is smooth," & cr & "nothing draws outside the window, boxes tumble normally. CLICK a box to test the" & cr & "scroll-corrected grab. ~15 s logs an fps line; STOP logs the summary."
end runS9

command s9Frame
   local tHX, tTarget, tCur, tVel
   set the itemDelimiter to comma
   -- keep the hero moving right at 200 px/s without touching its vertical speed
   put b2kVelocity(gS9Hero) into tVel
   b2kSetVelocity gS9Hero, 200, item 2 of tVel
   put item 1 of b2kPosition(gS9Hero) into tHX
   if tHX > 2040 then b2kMoveTo gS9Hero, 160, 300
   -- camera: centre the hero, lerped, clamped to the level
   put trunc(tHX - 100 - 300) into tTarget
   if tTarget < 0 then put 0 into tTarget
   if tTarget > 1400 then put 1400 into tTarget
   put the hScroll of group "sk_cam" into tCur
   set the hScroll of group "sk_cam" to round(tCur + 0.2 * (tTarget - tCur))
   if gS9Logged is not true and gFpsSamples >= 15 then
      put true into gS9Logged
      spikeLog "S9 after 15 s: fps min " & gFpsMin & ", avg " & round(gFpsSum / gFpsSamples * 10) / 10
   end if
end s9Frame

-- =====================================================================
-- S10 - the combined budget scene: 25 group-scroll sprites animating and
-- orbiting + 25 dynamic bodies + input polling, all in the Kit loop.
-- (needs the Kit)
-- =====================================================================
command runS10
   local i, tCol, tRow, tX, tY, tRef
   if spikeBeginTest("S10", true) is false then exit runS10
   spikeEnsureSheet
   b2kSetup
   b2kFrameTarget the long id of me
   -- arena: keep the action inside a walled box right of the button column
   b2kWall 200, 100, 200, 560
   b2kWall 960, 100, 960, 560
   b2kWall 200, 560, 960, 560
   b2kWall 200, 100, 960, 100
   try
      set the acceleratedRendering of this stack to true
   catch tErr
   end try
   repeat with i = 1 to 25
      put (i - 1) mod 5 into tCol
      put (i - 1) div 5 into tRow
      put 250 + tCol * 130 into tX
      put 140 + tRow * 80 into tY
      get spikeMakeSprite("sk_sp" & i, tX, tY)
      if it is empty then
         spikeStatus "S10 ABORTED - could not build a sprite group (see report)."
         put empty into gSpikeTest
         exit runS10
      end if
      put 1 into gSpFrame[i]
      put the milliseconds + i * 13 into gSpNext[i]
      put i * 29 into gSpAng[i]
      put tX into gSpCX[i]
      put tY into gSpCY[i]
   end repeat
   repeat with i = 1 to 25
      if i mod 2 = 0 then
         get b2kSpawnBox(220 + random(700), 110 + random(80), 30 + random(20), 30 + random(20), "orange")
      else
         get b2kSpawnBall(220 + random(700), 110 + random(80), 26 + random(18), "purple")
      end if
      try
         set the layerMode of it to "dynamic"
      catch tErr
      end try
   end repeat
   put the milliseconds into gS10T0
   put false into gS10Logged
   b2kStart
   spikeStatus "S10 PERF - 25 animated orbiting sprites + 25 tumbling bodies + key polling." & cr & "Let it run ~12 s for the auto fps line; drag bodies around meanwhile (mouse grab)." & cr & "PASS if avg fps >= 55 and motion stays smooth. STOP logs the final summary."
end runS10

command s10Frame
   local i, tNow, tJunk
   put the keysDown into tJunk   -- include the input module's per-frame cost
   put the milliseconds into tNow
   repeat with i = 1 to 25
      add 3 to gSpAng[i]
      set the loc of group ("sk_sp" & i) to round(gSpCX[i] + 24 * cos(gSpAng[i] * kSpikeDeg)), round(gSpCY[i] + 24 * sin(gSpAng[i] * kSpikeDeg))
      if tNow >= gSpNext[i] then
         put (gSpFrame[i] mod 4) + 1 into gSpFrame[i]
         set the hScroll of group ("sk_sp" & i) to (gSpFrame[i] - 1) * 64
         put tNow + 100 into gSpNext[i]
      end if
   end repeat
   if gS10Logged is not true and tNow - gS10T0 > 12000 then
      put true into gS10Logged
      spikeLog "S10 after 12 s: fps min " & gFpsMin & ", avg " & round(gFpsSum / max(1, gFpsSamples) * 10) / 10 & " (PASS if avg >= 55)"
   end if
end s10Frame

-- =====================================================================
-- Kit frame router (the spike card is the b2kFrameTarget for S8-S10)
-- =====================================================================
on b2kFrame
   switch gSpikeTest
      case "S8"
         s8Frame
         break
      case "S9"
         s9Frame
         spikeFpsTick
         break
      case "S10"
         s10Frame
         spikeFpsTick
         break
   end switch
end b2kFrame

-- =====================================================================
-- Stage helpers: the generated sheet, sprite groups, group creation ladder
-- =====================================================================

-- A 4-frame 64x64 strip (256x64) built pixel-by-pixel in script: solid
-- red/green/blue/yellow cells, each with a 2px black border so any clipping
-- bleed or scaling is instantly visible. Cached - building costs ~a second.
command spikeEnsureSheet
   if there is an image "sk_sheet" of this card then exit spikeEnsureSheet
   if gSheetData is empty then
      put spikeSheetData(64, 64, 4) into gSheetData
      put spikeOpaque(256 * 64) into gSheetAlpha
   end if
   create image "sk_sheet"
   set the lockLoc of it to true
   set the rect of it to 420, 96, 676, 160
   set the imageData of image "sk_sheet" to gSheetData
   set the alphaData of image "sk_sheet" to gSheetAlpha
end spikeEnsureSheet

function spikeSheetData pW, pH, pFrames
   local tColors, tBorderPx, tBodyPx, tBorderRow, tBody, tData, tRGB, f, x, y
   put "230,70,70" & cr & "70,200,120" & cr & "80,130,255" & cr & "240,200,70" into tColors
   put numToByte(255) & numToByte(0) & numToByte(0) & numToByte(0) into tBorderPx
   put empty into tBorderRow
   repeat with x = 1 to pW
      put tBorderPx after tBorderRow
   end repeat
   set the itemDelimiter to comma
   repeat with f = 1 to pFrames
      put line f of tColors into tRGB
      put numToByte(255) & numToByte(item 1 of tRGB) & numToByte(item 2 of tRGB) & numToByte(item 3 of tRGB) into tBodyPx
      put tBorderPx & tBorderPx into tBody[f]
      repeat with x = 1 to pW - 4
         put tBodyPx after tBody[f]
      end repeat
      put tBorderPx & tBorderPx after tBody[f]
   end repeat
   put empty into tData
   repeat with y = 1 to pH
      repeat with f = 1 to pFrames
         if y <= 2 or y > pH - 2 then
            put tBorderRow after tData
         else
            put tBody[f] after tData
         end if
      end repeat
   end repeat
   return tData
end spikeSheetData

function spikeOpaque pCount
   local tS
   put numToByte(255) into tS
   repeat while the number of bytes in tS < pCount
      put tS & tS into tS
   end repeat
   return byte 1 to pCount of tS
end spikeOpaque

-- A sprite: a frame-sized clipped group holding its own copy of the sheet.
-- Frame N shows via: set the hScroll of the group to (N-1) * frameW.
function spikeMakeSprite pName, pX, pY
   local tG
   spikeEnsureSheet
   put spikeNewGroup(pName, pX, pY) into tG
   if tG is empty then return empty
   create image (pName & "_img") in group pName
   set the lockLoc of it to true
   set the rect of it to pX, pY, pX + 256, pY + 64
   set the imageData of image (pName & "_img") to gSheetData
   set the alphaData of image (pName & "_img") to gSheetAlpha
   set the lockLoc of group pName to true
   set the rect of group pName to pX, pY, pX + 64, pY + 64
   set the hScroll of group pName to 0
   return tG
end spikeMakeSprite

-- Group-from-script ladder. Plan A: create an empty group directly. Plan B:
-- group two temporary graphics and rename. Either way the group keeps a 1px
-- invisible anchor at the content's top-left (so it can never become empty,
-- and the content bounds start exactly where the viewport expects). Logs
-- which plan worked - Phase 4 needs to know.
function spikeNewGroup pName, pLeft, pTop
   local tOk, tG
   put false into tOk
   try
      create group pName
      put true into tOk
      spikeLogOnce "grpA", "group creation: plan A (create group) works"
   catch tErr
      put false into tOk
   end try
   if not tOk then
      try
         create graphic "sk_gtmpa"
         set the rect of it to pLeft, pTop, pLeft + 8, pTop + 8
         create graphic "sk_gtmpb"
         set the rect of it to pLeft + 10, pTop, pLeft + 18, pTop + 8
         select graphic "sk_gtmpa" and graphic "sk_gtmpb"
         group
         put line 1 of the selectedObject into tG
         set the name of tG to pName
         select empty
         put true into tOk
         spikeLogOnce "grpB", "group creation: plan B (select + group + rename) works"
      catch tErr
         spikeLog "GROUP FAIL: neither creation plan worked: " & tErr
         return empty
      end try
   end if
   set the margins of group pName to 0
   set the showBorder of group pName to false
   set the hScrollbar of group pName to false
   set the vScrollbar of group pName to false
   create graphic (pName & "_anch") in group pName
   set the rect of it to pLeft, pTop, pLeft + 1, pTop + 1
   set the visible of it to false
   if there is a graphic "sk_gtmpa" then delete graphic "sk_gtmpa"
   if there is a graphic "sk_gtmpb" then delete graphic "sk_gtmpb"
   return the long id of group pName
end spikeNewGroup

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
--      get b2kSpawnBall(200,80, 50)          -- create + drop a ball
--      get b2kSpawnBox(260,80, 60,40, "orange")
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
-- controls are just detached).
command b2kClear
   local tRef, tList, d
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
   create graphic (tName)
   put the long id of graphic (tName) into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then set the backgroundColor of tRef to pColor
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
   create graphic (tName)
   put the long id of graphic (tName) into tRef
   set the style of tRef to "oval"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then set the backgroundColor of tRef to pColor
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
   create graphic (tName)
   put the long id of graphic (tName) into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the foregroundColor of tRef to "20,20,24"
   if pColor is not empty then set the backgroundColor of tRef to pColor
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
      if tL is a number then put tBits bitOr (tL) into tBits
      else put tBits bitOr b2kDefineLayer(tL) into tBits
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
   return b2kChain(pPoints, false)
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
-- The loop  (fixed timestep, generation-guarded; one screen lock per frame)
-- =====================================================================
-- The whole frame -- body sync, contact/sensor dispatch and the app's own
-- b2kFrame drawing -- runs inside a single lock screen / unlock screen so it
-- composites in ONE redraw (no tearing between bodies and the joints/HUD a user
-- draws on top). The try/catch guarantees the unlock even if a user handler
-- throws, so a faulty event handler can never leave the screen frozen.
on b2kStep pGen
   if not sRunning then exit b2kStep
   if pGen is not sGen then exit b2kStep
   if sPaused is not true then
      local tNow, tElapsed, tFixed
      put the milliseconds into tNow
      put (tNow - sLast) / 1000 into tElapsed
      put tNow into sLast
      add tElapsed to sAccum
      if sAccum > 0.20 then put 0.20 into sAccum
      put 1 / 60 into tFixed
      repeat while sAccum >= tFixed
         b2Step sWorld, tFixed, sSub
         subtract tFixed from sAccum
      end repeat
      if sDragging then
         b2MouseSetTarget sDragJoint, b2kToWorldX(the mouseH), b2kToWorldY(the mouseV)
      end if
      lock screen
      try
         b2kSyncBodies         -- lock-free; this frame's single lock is held here
         b2kDispatchContacts
         b2kDispatchSensors
         if sFrameObj is not empty then dispatch "b2kFrame" to sFrameObj
      catch tErr               -- a user handler error must never freeze the screen
      end try
      unlock screen
   end if
   send ("b2kStep " & sGen) to me in 16 milliseconds
end b2kStep

-- Advance exactly one fixed step, even while paused (drives a Step button).
command b2kStepOnce
   if not sRunning then exit b2kStepOnce
   b2Step sWorld, (1 / 60), sSub
   if sDragging then
      b2MouseSetTarget sDragJoint, b2kToWorldX(the mouseH), b2kToWorldY(the mouseV)
   end if
   lock screen
   try
      b2kSyncBodies
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
