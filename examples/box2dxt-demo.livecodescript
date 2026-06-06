-- #####################################################################
-- #  Box2Dxt  —  SELF-CONTAINED DEMO  (Kit + showcase in one file)    #
-- #                                                                   #
-- #  HOW TO RUN                                                       #
-- #   1. Load the box2dxt.lcb extension and put the box2dxt native    #
-- #      library where it can be found. Check: put b2Version()  -- 3  #
-- #   2. Paste THIS WHOLE FILE into a stack`s script                  #
-- #      (Object > Stack Script).                                     #
-- #   3. Open/close the card, or run  startBox2DDemo  in the          #
-- #      Message Box.  Stop with  stopBox2DDemo.                      #
-- #                                                                   #
-- #  This file bundles a verbatim copy of the reusable Kit            #
-- #  (src/box2dxt-kit.livecodescript) so the demo runs from a single  #
-- #  paste. For your own projects, load the Kit on its own instead.   #
-- #####################################################################

-- =====================================================================
-- EMBEDDED KIT  ·  auto-generated copy of src/box2dxt-kit.livecodescript
--
-- This file is self-contained: paste the whole thing into one stack script
-- and it runs.  The Kit below is a GENERATED copy — do not edit it here.
-- Edit the canonical Kit at src/box2dxt-kit.livecodescript, then run:
--     python3 tools/sync-embedded-kit.py
-- (CI checks it stays in sync via:  tools/sync-embedded-kit.py --check)
-- =====================================================================
-- >>> BEGIN EMBEDDED KIT >>>
-- =====================================================================
-- box2dxt-kit.livecodescript   ·   "Box2Dxt Kit"  (b2k...)
--
-- A friendly, pure-xTalk toolkit over the box2dxt extension. You work in
-- PIXELS, SCREEN coordinates and DEGREES; the kit converts to Box2D's
-- metres / radians / y-up for you, runs the world, and moves your controls.
-- Runs in OpenXTalk (OXT); compatible with LiveCode 9.6.3+.
-- Requires the box2dxt extension loaded (put b2Version() should return 3).
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
end b2kSetup

command b2kResetTables
   put empty into sBody
   put empty into sCtrl
   put empty into sShapeH
   put empty into sRender
   put empty into sVerts
   put empty into sRad
   put empty into sImgAngle
   put empty into sStatic
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
   put b2NewStaticBody(sWorld, 0, 0) into tBody
   get b2AddSegment(tBody, pWx1, pWy1, pWx2, pWy2, 0.6, 0.1)
end b2kEdge

-- A wide invisible ground line at screen height pScreenY (default: near bottom).
command b2kAddGround pScreenY
   local tBody, tWy
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
command b2kSetScale pPixelsPerMetre
   put pPixelsPerMetre into sScale
end b2kSetScale

command b2kSetOrigin pScreenX, pScreenY
   put pScreenX into sOriginX
   put pScreenY into sOriginY
end b2kSetOrigin

command b2kSetGravity pGx, pGy
   if sWorld is not empty then b2SetGravity sWorld, pGx, pGy
end b2kSetGravity

command b2kSetSubsteps pN
   put pN into sSub
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

-- Sanity check from kit-only code: returns the native shim's ABI version (3),
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
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put ((the width of pControl) / 2) / sScale into tHw
   put ((the height of pControl) / 2) / sScale into tHh
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
   return tBody
end b2kAddBox

command b2kAddBall pControl, pDynamic
   local tRef, tType, tBody, tRad, tWx, tWy
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put ((the width of pControl) / 2) / sScale into tRad
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
   return tBody
end b2kAddBall

-- Capsule ("pill"): the long side of the control's rect is the capsule axis,
-- the short side its diameter. Graphics render as a rounded outline (and rotate);
-- images rotate via `the angle`; other controls follow position upright.
command b2kAddCapsule pControl, pDynamic
   local tRef, tType, tFixed, tBody, tWx, tWy, tWm, tHm, tR, tL, tHoriz, tGraphic, tImage
   put the long id of pControl into tRef
   put (pDynamic is not false) into pDynamic
   if pDynamic then put 2 into tType
   else put 0 into tType
   put (the width of pControl) / sScale into tWm
   put (the height of pControl) / sScale into tHm
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
   return tBody
end b2kAddCapsule

-- Build a body from a polygon graphic's own points (<= 8 vertices, convex).
command b2kAddPolygon pControl, pDynamic
   local tRef, tType, tBody, tCx, tCy, tWx, tWy, tPoints, p, tLocal, lx, ly, tCount
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
   if pW is empty then put 40 into pW
   if pH is empty then put pW into pH
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
   if pDiameter is empty then put 40 into pDiameter
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
   if pLength is empty then put 80 into pLength
   if pThickness is empty then put 40 into pThickness
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
   if s is not empty then b2SetShapeRestitution s, pRestitution
end b2kSetBounce

command b2kSetFriction pControl, pFriction
   local s
   put sShapeH[the long id of pControl] into s
   if s is not empty then b2SetShapeFriction s, pFriction
end b2kSetFriction

command b2kSetDensity pControl, pDensity
   local s
   put sShapeH[the long id of pControl] into s
   if s is not empty then b2SetShapeDensity s, pDensity
end b2kSetDensity

-- Re-fit a body's collision shape to the control's CURRENT size, in place on the
-- SAME body so any joints stay valid. pShape is "box" | "ball" | "capsule" | "poly".
-- Resize the control's graphic first, then re-apply materials afterwards.
command b2kReshape pControl, pShape
   local tRef, tBody, tOld, tHw, tHh, tWm, tHm, tR, tL, tHoriz, tCx, tCy, p, lx, ly, tCount, tNewVerts
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
         put b2AddCircle(tBody, 0, 0, tR, 1.0, 0.4, 0.4) into sShapeH[tRef]
         put tR into sRad[tRef]
         break
      case "capsule"
         put (the width of pControl) / sScale into tWm
         put (the height of pControl) / sScale into tHm
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
            exit b2kReshape
         end if
         put b2AddPolygon(tBody, 1.0, 0.4, 0.2) into sShapeH[tRef]
         put tNewVerts into sVerts[tRef]
         break
      default
         put ((the width of pControl) / 2) / sScale into tHw
         put ((the height of pControl) / 2) / sScale into tHh
         put b2AddBox(tBody, tHw, tHh, 1.0, 0.4, 0.2) into sShapeH[tRef]
         if sRender[tRef] is "poly" then
            put ("-" & tHw) & "," & ("-" & tHh) & cr & tHw & "," & ("-" & tHh) & cr \
                  & tHw & "," & tHh & cr & ("-" & tHw) & "," & tHh into sVerts[tRef]
         end if
   end switch
   if tOld is not empty then b2DestroyShape tOld   -- now safe to release the old shape
end b2kReshape

command b2kSetBullet pControl, pFlag
   b2SetBullet sBody[the long id of pControl], (pFlag is true)
end b2kSetBullet

command b2kSetFixedRotation pControl, pFlag
   b2SetFixedRotation sBody[the long id of pControl], (pFlag is true)
end b2kSetFixedRotation

command b2kSetGravityScale pControl, pScale
   b2SetGravityScale sBody[the long id of pControl], pScale
end b2kSetGravityScale

command b2kSetDamping pControl, pLinear, pAngular
   local b
   put sBody[the long id of pControl] into b
   if pLinear is not empty then b2SetLinearDamping b, pLinear
   if pAngular is not empty then b2SetAngularDamping b, pAngular
end b2kSetDamping

command b2kWake pControl
   b2SetAwake sBody[the long id of pControl], true
end b2kWake

-- Send a body to sleep (it stops simulating until something wakes it).
command b2kSleep pControl
   b2SetAwake sBody[the long id of pControl], false
end b2kSleep

-- Below this speed (pixels/sec) a body may fall asleep. Lower = stays awake
-- longer; higher = sleeps sooner (saves CPU).
command b2kSetSleepThreshold pControl, pPxPerSec
   b2SetSleepThreshold sBody[the long id of pControl], pPxPerSec / sScale
end b2kSetSleepThreshold

-- =====================================================================
-- Acting on bodies   (velocities/kicks are in PIXELS/sec, screen-oriented)
-- =====================================================================
command b2kSetVelocity pControl, pVxPx, pVyPx
   b2SetVelocity sBody[the long id of pControl], pVxPx / sScale, - pVyPx / sScale
end b2kSetVelocity

command b2kPush pControl, pDvxPx, pDvyPx
   local b
   put sBody[the long id of pControl] into b
   b2SetVelocity b, b2BodyVX(b) + pDvxPx / sScale, b2BodyVY(b) - pDvyPx / sScale
   b2SetAwake b, true
end b2kPush

command b2kSpin pControl, pDegPerSec
   b2SetAngularVelocity sBody[the long id of pControl], pDegPerSec * kPI / 180
end b2kSpin

-- Add to the current spin (vs b2kSpin which sets it absolutely).
command b2kSpinBy pControl, pDegPerSec
   local b
   put sBody[the long id of pControl] into b
   b2SetAngularVelocity b, b2BodyAngularVelocity(b) + pDegPerSec * kPI / 180
   b2SetAwake b, true
end b2kSpinBy

-- Continuous, screen-oriented force (thrusters, wind). Apply each frame for a
-- sustained effect; b2kPush is the one-shot impulse equivalent.
command b2kForce pControl, pFxPx, pFyPx
   b2ApplyForce sBody[the long id of pControl], pFxPx / sScale, - pFyPx / sScale, true
end b2kForce

-- A one-shot impulse (a sharp kick), screen-oriented. Mass-aware: heavier bodies
-- move less. b2kPush changes velocity directly; this is the impulse equivalent.
command b2kImpulse pControl, pIxPx, pIyPx
   b2ApplyImpulse sBody[the long id of pControl], pIxPx / sScale, - pIyPx / sScale, true
end b2kImpulse

-- A continuous turning force (same units as motor torque). Positive turns one way,
-- negative the other. Apply each frame for a sustained twist; pairs with b2kForce.
command b2kTorque pControl, pTorque
   b2ApplyTorque sBody[the long id of pControl], pTorque, true
end b2kTorque

-- A one-shot twist (a sharp angular kick), mass-aware: bodies with more
-- rotational inertia turn less. b2kSpinBy sets the spin directly; this is the
-- impulse equivalent, and the angular partner of b2kImpulse.
command b2kAngularImpulse pControl, pImpulse
   b2ApplyAngularImpulse sBody[the long id of pControl], pImpulse, true
end b2kAngularImpulse

-- Change a body's type at runtime: "static", "kinematic", or "dynamic".
command b2kSetType pControl, pType
   local tRef, tCode
   put the long id of pControl into tRef
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
   b2DisableBody sBody[the long id of pControl]
end b2kDisable

command b2kEnable pControl
   b2EnableBody sBody[the long id of pControl]
end b2kEnable

command b2kMoveTo pControl, pScreenX, pScreenY, pAngleDeg
   if pAngleDeg is empty then put 0 into pAngleDeg
   b2SetTransform sBody[the long id of pControl], b2kToWorldX(pScreenX), b2kToWorldY(pScreenY), pAngleDeg * kPI / 180
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
   return b2kToScreenX(b2BodyX(b)) & "," & b2kToScreenY(b2BodyY(b))
end b2kPosition

-- A body's centre of mass in SCREEN pixels as "x,y". Differs from b2kPosition
-- for off-centre or compound shapes; it's the true pivot for spin and torque.
function b2kWorldCenter pControl
   local b
   put sBody[the long id of pControl] into b
   return b2kToScreenX(b2BodyWorldCenterX(b)) & "," & b2kToScreenY(b2BodyWorldCenterY(b))
end b2kWorldCenter

function b2kVelocity pControl
   local b
   put sBody[the long id of pControl] into b
   return (b2BodyVX(b) * sScale) & "," & (- b2BodyVY(b) * sScale)
end b2kVelocity

function b2kSpeed pControl
   local b
   put sBody[the long id of pControl] into b
   return sqrt((b2BodyVX(b) * sScale) ^ 2 + (b2BodyVY(b) * sScale) ^ 2)
end b2kSpeed

function b2kAngle pControl
   return b2BodyAngle(sBody[the long id of pControl]) * 180 / kPI
end b2kAngle

function b2kIsAwake pControl
   return b2BodyIsAwake(sBody[the long id of pControl])
end b2kIsAwake

-- Current rotation speed in DEGREES/sec (the getter for b2kSpin / b2kSpinBy).
function b2kSpinRate pControl
   return b2BodyAngularVelocity(sBody[the long id of pControl]) * 180 / kPI
end b2kSpinRate

function b2kIsBullet pControl
   return b2BodyIsBullet(sBody[the long id of pControl])
end b2kIsBullet

function b2kIsEnabled pControl
   return b2BodyIsEnabled(sBody[the long id of pControl])
end b2kIsEnabled

function b2kMass pControl
   return b2BodyMass(sBody[the long id of pControl])
end b2kMass

-- The body's per-body gravity multiplier (the getter for b2kSetGravityScale).
function b2kGravityScale pControl
   return b2BodyGravityScale(sBody[the long id of pControl])
end b2kGravityScale

-- The body's drag as "linear,angular" (the getter for b2kSetDamping).
function b2kDamping pControl
   local b
   put sBody[the long id of pControl] into b
   return b2BodyLinearDamping(b) & "," & b2BodyAngularDamping(b)
end b2kDamping

-- Body type as a word: "static", "kinematic", or "dynamic" (mirrors b2kSetType).
function b2kBodyType pControl
   local tCode
   put b2BodyType(sBody[the long id of pControl]) into tCode
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
   if b2CastRayClosest(sWorld, b2kToWorldX(pX1), b2kToWorldY(pY1), b2kToWorldX(pX2), b2kToWorldY(pY2)) then
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
   if pMaxTorque is empty then put 1000 into pMaxTorque
   b2RevoluteEnableMotor pJoint, true, pDegPerSec * kPI / 180, pMaxTorque
end b2kMotor

-- Optional revolute (hinge) limits/readout. Angles are in DEGREES.
command b2kHingeLimit pJoint, pLowerDeg, pUpperDeg
   b2RevoluteEnableLimit pJoint, true, pLowerDeg * kPI / 180, pUpperDeg * kPI / 180
end b2kHingeLimit

function b2kHingeAngle pJoint
   return b2RevoluteAngle(pJoint) * 180 / kPI
end b2kHingeAngle

-- Rope (distance) extras: read length, set a min/max range, make it springy.
function b2kRopeLength pJoint
   return b2DistanceLength(pJoint) * sScale
end b2kRopeLength

-- Set a rope (distance) joint's exact rest length, in pixels.
command b2kRopeSetLength pJoint, pLengthPx
   b2DistanceSetLength pJoint, pLengthPx / sScale
end b2kRopeSetLength

command b2kRopeRange pJoint, pMinPx, pMaxPx
   b2DistanceSetLengthRange pJoint, pMinPx / sScale, pMaxPx / sScale
end b2kRopeRange

command b2kSpring pJoint, pHertz, pDamping
   if pDamping is empty then put 0.5 into pDamping
   b2DistanceEnableSpring pJoint, true, pHertz, pDamping
end b2kSpring

-- Make a weld springy (0 hertz = rigid again).
command b2kWeldSpring pJoint, pHertz, pDamping
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
   if pMaxForce is empty then put 1000 into pMaxForce
   b2PrismaticEnableMotor pJoint, true, pPxPerSec / sScale, pMaxForce
end b2kSliderMotor

command b2kSliderLimit pJoint, pLowerPx, pUpperPx
   b2PrismaticEnableLimit pJoint, true, pLowerPx / sScale, pUpperPx / sScale
end b2kSliderLimit

function b2kSliderPos pJoint
   return b2PrismaticTranslation(pJoint) * sScale
end b2kSliderPos

-- Wheel: a sprung sliding axis + free spin (vehicle wheels). pChassis carries
-- pWheel; anchor defaults to the wheel's centre, suspension axis to world "up".
-- Drive with b2kWheelMotor, tune ride with b2kWheelSpring.
command b2kWheel pChassis, pWheel, pScreenX, pScreenY, pAxisDeg
   local bA, bB, anchX, anchY, aA, aB, wax, way, ca, sa, lax, lay, angA, j
   put sBody[the long id of pChassis] into bA
   put sBody[the long id of pWheel] into bB
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
   if pMaxTorque is empty then put 1000 into pMaxTorque
   b2WheelEnableMotor pJoint, true, pDegPerSec * kPI / 180, pMaxTorque
end b2kWheelMotor

command b2kWheelSpring pJoint, pHertz, pDamping
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
   put true into sSensor[tRef]
   return sBody[tRef]
end b2kAddSensor

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
   if pAngleDeg is empty then put 0 into pAngleDeg
   if pMaxForce is empty then put 1000 into pMaxForce
   if pMaxTorque is empty then put 1000 into pMaxTorque
   return b2MotorJoint(sWorld, bRef, bMover, pOffsetXPx / sScale, - pOffsetYPx / sScale, \
         pAngleDeg * kPI / 180, pMaxForce, pMaxTorque, 0.3, false)
end b2kMotorTo

-- Stop two specific controls from colliding with each other (without changing how
-- either collides with anything else). Returns a joint handle (b2kRemoveJoint).
command b2kNoCollide pCtrlA, pCtrlB
   return b2FilterJoint(sWorld, sBody[the long id of pCtrlA], sBody[the long id of pCtrlB])
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
-- The loop  (fixed timestep, generation-guarded, screen-locked sync)
-- =====================================================================
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
      b2kSync
      b2kDispatchContacts
      b2kDispatchSensors
      if sFrameObj is not empty then dispatch "b2kFrame" to sFrameObj
      unlock screen           -- one redraw per frame: sync + events + app drawing
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
   b2kSync
   b2kDispatchContacts
   b2kDispatchSensors
   if sFrameObj is not empty then dispatch "b2kFrame" to sFrameObj
   unlock screen
end b2kStepOnce

command b2kSync
   local tRef, tBody, tWx, tWy, tDead, d
   put empty into tDead
   lock screen
   repeat for each key tRef in sBody
      if sStatic[tRef] is true then next repeat
      put sBody[tRef] into tBody
      if b2BodyIsAwake(tBody) is false then next repeat   -- asleep = at rest, skip redraw
      try
         put b2BodyX(tBody) into tWx
         put b2BodyY(tBody) into tWy
         switch sRender[tRef]
            case "poly"
               b2kDrawPoly tRef, tWx, tWy, b2BodyAngle(tBody)
               break
            case "ball"
               b2kDrawBall tRef, tWx, tWy
               break
            case "image"
               b2kDrawImage tRef, tWx, tWy, b2BodyAngle(tBody)
               break
            default
               set the loc of tRef to round(b2kToScreenX(tWx)) & "," & round(b2kToScreenY(tWy))
         end switch
      catch tErr
         put tRef & cr after tDead   -- control vanished; clean up below
      end try
   end repeat
   unlock screen
   repeat for each line d in tDead
      if d is not empty then
         if sBody[d] is not empty then b2DestroyBody sBody[d]
         delete variable sBody[d]
      end if
   end repeat
end b2kSync

command b2kDrawPoly pRef, pWx, pWy, pWa
   local c, s, p, pt, tPts, tFirst
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
end b2kDrawPoly

command b2kDrawBall pRef, pWx, pWy
   local tRp, tSx, tSy
   put sRad[pRef] * sScale into tRp
   put b2kToScreenX(pWx) into tSx
   put b2kToScreenY(pWy) into tSy
   set the rect of pRef to round(tSx - tRp), round(tSy - tRp), round(tSx + tRp), round(tSy + tRp)
end b2kDrawBall

-- Position + rotate an image control to follow its body. The body angle is in
-- radians, CCW-positive in the sim's y-up frame; with this kit's y-flip that is
-- also a CCW screen rotation, which matches `the angle` (CCW-positive). We keep
-- the image at its design size and skip redundant re-rotations (each set of the
-- angle resamples the image, but always from the original, so there's no drift).
command b2kDrawImage pRef, pWx, pWy, pWa
   local tDeg
   put ((round(pWa * 180 / kPI) mod 360) + 360) mod 360 into tDeg
   if sImgAngle[pRef] is not tDeg then
      set the angle of pRef to tDeg
      put tDeg into sImgAngle[pRef]
   end if
   set the loc of pRef to round(b2kToScreenX(pWx)) & "," & round(b2kToScreenY(pWy))
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

-- =====================================================================
-- DEMO APP  ·  built on the Kit above (b2k...)
--
-- WHAT IT SHOWS
--   · Every shape: boxes, balls, capsules, polygons.
--   · Joints: hinge + motor (windmill, see-saw), distance (cradle), revolute
--     chain (bridge), wheel + suspension (vehicle).
--   · Forces, dragging, contact + end-contact events, live ray casting.
--   · The b2kFrame per-frame hook for app logic and custom drawing.
--
-- NAMING: LiveCode conventions throughout — p* parameters, t* locals,
-- g* script-locals, k* constants — so nothing collides with reserved words.
-- All scene coordinates are in SCREEN PIXELS.
-- =====================================================================

local gScene, gTool, gDrops
local gFrames, gFpsTime, gFps
local gBombs, gFlash
local gCableN, gCableAX, gCableAY, gCableCtrl
local gRingN, gRingX, gRingY, gRingF
local gRayN
local gThrottle, gThrottleTtl, gWheelBack, gWheelFront
local gArenaL, gArenaR, gArenaT, gArenaB
local gObjective, gTargets, gSpawnX, gStartX, gCar
local gScore, gCoins, gCoinTotal, gWheelBC, gWheelFC

constant kScenes     = "playground,pyramid,cradle,bridge,vehicle,lidar"
constant kLabels     = "Playground,Pyramid,Cradle,Bridge,Vehicle,Lidar"
constant kTools      = "box,ball,capsule,poly,bomb"
constant kToolLabels = "Box,Ball,Capsule,Poly,Bomb"
constant kMaxDrops = 70

-- ---------------------------------------------------------------------
on preOpenCard
   startBox2DDemo
end preOpenCard

on closeCard
   stopBox2DDemo
end closeCard

on startBox2DDemo
   -- a proper, centred, non-resizable window
   set the title of this stack to "Box2Dxt — Kit Showcase"
   set the decorations of this stack to "default"
   set the resizable of this stack to false
   set the width of this stack to 980
   set the height of this stack to 660
   set the loc of this stack to the screenLoc
   set the backgroundColor of this card to "22,24,30"
   put "box" into gTool
   buildUI
   switchScene "playground"
end startBox2DDemo

on stopBox2DDemo
   b2kTeardown
   clearSceneControls
end stopBox2DDemo

-- =====================================================================
-- Scene lifecycle
-- =====================================================================
on switchScene pScene
   lock screen
   b2kStop
   clearSceneControls
   clearState
   put pScene into gScene
   b2kSetup 0, -10
   b2kFrameTarget the long id of this stack
   b2kContactTarget the long id of this stack
   switch pScene
      case "playground"
         buildPlayground
         break
      case "pyramid"
         buildPyramid
         break
      case "cradle"
         buildCradle
         break
      case "bridge"
         buildBridge
         break
      case "vehicle"
         buildVehicle
         break
      case "lidar"
         buildLidar
         break
   end switch
   raiseUI                       -- keep the chrome above all scene controls
   b2kStart
   highlightScenes
   highlightTools
   setHelp
   updateHud
   unlock screen
end switchScene

-- Keep every UI control above the scene's bodies/rays so the chrome is always
-- visible and clickable, whatever the simulation draws.
on raiseUI
   local tI, tName, tList
   put empty into tList
   repeat with tI = 1 to the number of controls of this card
      put the short name of control tI of this card into tName
      if char 1 to 3 of tName is "ui_" then put tName & cr after tList
   end repeat
   repeat for each line tName in tList
      set the layer of control tName of this card to top
   end repeat
end raiseUI

on clearState
   put the milliseconds into gFpsTime   -- seed the FPS window so the first reading is sane
   put 0 into gFrames
   put empty into gFps
   put empty into gDrops
   put empty into gBombs
   put empty into gFlash
   put 0 into gCableN
   put empty into gCableAX
   put empty into gCableAY
   put empty into gCableCtrl
   put 0 into gRingN
   put empty into gRingX
   put empty into gRingY
   put empty into gRingF
   put 0 into gRayN
   put 0 into gThrottle
   put 0 into gThrottleTtl
   put empty into gWheelBack
   put empty into gWheelFront
   put empty into gObjective
   put empty into gTargets
   put empty into gSpawnX
   put 0 into gStartX
   put 0 into gScore
   put empty into gCoins
   put 0 into gCoinTotal
   put empty into gWheelBC
   put empty into gWheelFC
end clearState

-- Build the four bounding walls (so bodies stay inside the play area, clear of
-- the toolbar) plus a visible ground strip. Top = below the toolbar.
on prepArena
   local tGroundY, tWide
   put the width of this card into tWide
   put (the height of this card) - 48 into tGroundY
   -- screen-space arena bounds (used to keep gameplay + the lidar inside)
   put 2 into gArenaL
   put tWide - 2 into gArenaR
   put 130 into gArenaT
   put tGroundY into gArenaB
   -- a framed play-field panel behind the bodies (game-board look)
   create graphic "demo_field"
   set the style of graphic "demo_field" to "rectangle"
   set the filled of graphic "demo_field" to true
   set the backgroundColor of graphic "demo_field" to "26,29,37"
   set the foregroundColor of graphic "demo_field" to "46,60,86"
   set the lineSize of graphic "demo_field" to 2
   set the rect of graphic "demo_field" to gArenaL, gArenaT, gArenaR, tGroundY + 20
   -- physics walls (b2kWall takes screen points and converts to world for us)
   b2kWall 2, tGroundY, tWide - 2, tGroundY
   b2kWall 2, 130, tWide - 2, 130
   b2kWall 2, tGroundY, 2, 130
   b2kWall tWide - 2, tGroundY, tWide - 2, 130
   -- visible ground strip
   create graphic "demo_groundbar"
   set the style of graphic "demo_groundbar" to "rectangle"
   set the filled of graphic "demo_groundbar" to true
   set the backgroundColor of graphic "demo_groundbar" to "44,49,60"
   set the lineSize of graphic "demo_groundbar" to 0
   set the rect of graphic "demo_groundbar" to gArenaL, tGroundY, gArenaR, tGroundY + 20
end prepArena

-- =====================================================================
-- Scenes  (all in screen pixels)
-- =====================================================================
on buildPlayground
   prepArena
   local tCx
   put (the width of this card) div 2 into tCx

   -- a sampler of every shape, dropping in
   get newBox(tCx - 250, 200, 58, 58, accentShape(1))
   get newBall(tCx - 120, 180, 56, accentShape(2))
   get newCapsule(tCx + 40, 180, 96, 38, accentShape(3))
   get newPoly(tCx + 210, 180, 36, accentShape(4))

   -- SEE-SAW: a plank hinged to the world at its centre. The fulcrum is purely
   -- decorative — making it a static *body* (as before) jams the plank against
   -- it and the see-saw can't tilt.
   local tPlank, tPivotX, tPivotY
   put tCx - 250 into tPivotX
   put 470 into tPivotY
   create graphic "demo_fulcrum"
   set the style of graphic "demo_fulcrum" to "polygon"
   set the filled of graphic "demo_fulcrum" to true
   set the backgroundColor of graphic "demo_fulcrum" to "92,98,112"
   set the points of graphic "demo_fulcrum" to \
         (tPivotX - 30) & "," & (tPivotY + 70) & cr & (tPivotX + 30) & "," & (tPivotY + 70) \
         & cr & tPivotX & "," & (tPivotY + 6)
   put newBox(tPivotX, tPivotY, 260, 16, "120,180,210") into tPlank
   b2kHinge tPlank, empty, tPivotX, tPivotY
   get newBox(tPivotX - 116, 330, 52, 52, accentShape(5))         -- weight tips it

   -- WINDMILL: a blade hinged to the world, driven by a motor
   local tHubX, tHubY, tBlade, tJoint
   put tCx + 150 into tHubX
   put 300 into tHubY
   put newBox(tHubX, tHubY, 160, 16, "240,212,120") into tBlade
   b2kHinge tBlade, empty, tHubX, tHubY
   put the result into tJoint
   b2kMotor tJoint, 110, 90

   -- PENDULUM: a bob hinged to the world, with a drawn cable
   local tAnchorX, tAnchorY, tBob
   put tCx + 330 into tAnchorX
   put 150 into tAnchorY
   put newBall(tAnchorX + 130, 300, 46, "214,92,92") into tBob
   b2kHinge tBob, empty, tAnchorX, tAnchorY
   addCable tAnchorX, tAnchorY, tBob
   put "Sandbox: drag anything; click empty space to drop the selected shape." into gObjective
end buildPlayground

on buildPyramid
   prepArena
   local tRows, tI, tK, tBw, tCx, tGroundY, tX, tY, tBox
   put 7 into tRows
   put 46 into tBw
   put (the width of this card) div 2 into tCx
   put (the height of this card) - 48 into tGroundY
   repeat with tI = 0 to tRows - 1
      repeat with tK = 0 to tRows - 1 - tI
         put tCx + (tK - (tRows - 1 - tI) / 2) * (tBw + 2) into tX
         put tGroundY - tBw / 2 - tI * (tBw + 1) into tY
         put newBox(tX, tY, tBw, tBw, pyramidColor(tI, tRows)) into tBox
         put tBox & cr after gTargets        -- track for the scatter score
         put tX into gSpawnX[tBox]
      end repeat
   end repeat
   put "Objective: pick the Bomb tool (top-right) and blast the stack apart!" into gObjective
end buildPyramid

on buildCradle
   local tN, tI, tR, tAnchorX, tAnchorY, tRestY, tBob, tBx, tLen, tCx, tSpace
   prepArena
   put 5 into tN
   put 48 into tR                       -- ball diameter
   put tR + 1 into tSpace               -- 1px gap: avoids a spawn-overlap blow-up
   put 160 into tAnchorY
   put 400 into tRestY
   put tRestY - tAnchorY into tLen       -- pendulum arm length
   put (the width of this card) div 2 into tCx
   repeat with tI = 1 to tN
      put tCx + (tI - (tN + 1) / 2) * tSpace into tBx
      if tI is 1 then
         -- Create the end ball ALREADY lifted (~50 deg) so the hinge is built
         -- consistent with its position. Teleporting a ball AFTER hinging it
         -- violates the joint and makes the whole cradle explode on step 1.
         put newBall(tBx - tLen * 0.766, tAnchorY + tLen * 0.643, tR, "196,200,214") into tBob
      else
         put newBall(tBx, tRestY, tR, "196,200,214") into tBob
      end if
      b2kSetBounce tBob, 0.9
      b2kSetFriction tBob, 0.05
      b2kHinge tBob, empty, tBx, tAnchorY
      addCable tBx, tAnchorY, tBob
   end repeat
   put "Watch momentum carry through the line — drag a ball aside and release." into gObjective
end buildCradle

on buildBridge
   local tN, tI, tPw, tPy, tStartX, tX, tPlank, tPrevPlank, tCx
   prepArena
   put 12 into tN
   put 62 into tPw
   put 320 into tPy
   put (the width of this card) div 2 into tCx
   put tCx - tN * tPw / 2 into tStartX
   put empty into tPrevPlank
   repeat with tI = 1 to tN
      put tStartX + (tI - 0.5) * tPw into tX
      put newBox(tX, tPy, tPw, 14, "168,146,98") into tPlank
      if tI is 1 then
         b2kHinge tPlank, empty, tX - tPw / 2, tPy
      else
         b2kHinge tPrevPlank, tPlank, tX - tPw / 2, tPy
      end if
      put tPlank into tPrevPlank
   end repeat
   b2kHinge tPrevPlank, empty, tStartX + tN * tPw, tPy
   get newBall(tCx - 60, 150, 54, "92,202,162")
   get newBall(tCx + 60, 140, 66, "214,118,118")
   put "Objective: pile heavy shapes on the plank bridge and watch it sag." into gObjective
end buildBridge

on buildVehicle
   local tGroundY, tChassis, tWheelB, tWheelF, tX, tY, tPrevX, tPrevY, tPts, tCarY
   prepArena
   put (the height of this card) - 48 into tGroundY
   -- ROLLING TERRAIN: a chain of static segments + a filled silhouette to match.
   put empty into tPts
   put gArenaL + 6 into tPrevX
   put terrainY(tPrevX) into tPrevY
   put tPrevX & "," & round(tPrevY) & cr after tPts
   put tPrevX + 26 into tX
   repeat until tX > gArenaR - 6
      put terrainY(tX) into tY
      b2kWall tPrevX, tPrevY, tX, tY
      put tX & "," & round(tY) & cr after tPts
      put tX into tPrevX
      put tY into tPrevY
      add 26 to tX
   end repeat
   put (gArenaR - 6) & "," & (tGroundY + 20) & cr & (gArenaL + 6) & "," & (tGroundY + 20) after tPts
   create graphic "demo_terrain"
   set the style of graphic "demo_terrain" to "polygon"
   set the filled of graphic "demo_terrain" to true
   set the backgroundColor of graphic "demo_terrain" to "56,72,50"
   set the foregroundColor of graphic "demo_terrain" to "84,108,74"
   set the lineSize of graphic "demo_terrain" to 2
   set the points of graphic "demo_terrain" to tPts
   -- COINS to grab along the course
   put empty into gCoins
   put 0 into gCoinTotal
   put gArenaL + 150 into tX
   repeat until tX > gArenaR - 130
      put newCoin(tX, terrainY(tX) - 52) & cr after gCoins
      add 1 to gCoinTotal
      add 150 to tX
   end repeat
   -- THE CAR: chassis + two sprung wheels
   put terrainY(190) - 64 into tCarY
   put newBox(190, tCarY, 122, 34, "228,132,60") into tChassis
   put newBall(158, tCarY + 30, 44, "40,40,48") into tWheelB
   put newBall(222, tCarY + 30, 44, "40,40,48") into tWheelF
   b2kWheel tChassis, tWheelB
   put the result into gWheelBack
   b2kWheel tChassis, tWheelF
   put the result into gWheelFront
   b2kWheelSpring gWheelBack, 5, 0.7
   b2kWheelSpring gWheelFront, 5, 0.7
   makeSpoke "demo_spokeB"
   makeSpoke "demo_spokeF"
   put tChassis into gCar
   put tWheelB into gWheelBC
   put tWheelF into gWheelFC
   put 190 into gStartX
   put "Drive with the ← / → arrow keys — roll over the hills and grab the coins!" into gObjective
end buildVehicle

-- Terrain height (screen Y) at a screen X — gentle rolling hills that always
-- stay above the arena floor.
function terrainY pX
   local tBase, tRel
   put (the height of this card) - 140 into tBase
   put pX - gArenaL into tRel
   return tBase - 40 * sin(tRel / 115) - 18 * sin(tRel / 270 + 1)
end terrainY

function newCoin pX, pY
   local tName, tRef
   put "demo_coin_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "oval"
   set the filled of tRef to true
   set the backgroundColor of tRef to "246,206,90"
   set the foregroundColor of tRef to "176,136,40"
   set the lineSize of tRef to 2
   set the width of tRef to 26
   set the height of tRef to 26
   set the loc of tRef to round(pX) & "," & round(pY)
   return tRef
end newCoin

on makeSpoke pName
   create graphic pName
   set the style of graphic pName to "line"
   set the lineSize of graphic pName to 3
   set the foregroundColor of graphic pName to "205,205,215"
end makeSpoke

on updateSpoke pName, pWheel
   local tcx, tcy, tA
   put empty into tcx
   try
      put item 1 of the loc of pWheel into tcx
      put item 2 of the loc of pWheel into tcy
   catch tErr
   end try
   if tcx is empty then exit updateSpoke
   put b2kAngle(pWheel) * kPI / 180 into tA
   set the points of graphic pName to round(tcx) & "," & round(tcy) & cr \
         & round(tcx + 19 * cos(tA)) & "," & round(tcy + 19 * sin(tA))
end updateSpoke

on buildLidar
   local tI, tBody
   prepArena
   b2kSetGravity 0, 0
   repeat with tI = 1 to 8
      put newBall(rnd(170, 810), rnd(170, 560), rnd(30, 72), "96,150,210") into tBody
      b2kSetBounce tBody, 1
      b2kSetFriction tBody, 0
      b2kSetVelocity tBody, rnd(-170, 170), rnd(-170, 170)
   end repeat
   repeat with tI = 1 to 3
      put newPoly(rnd(220, 760), rnd(180, 540), rnd(28, 48), "200,160,120") into tBody
      b2kSetBounce tBody, 1
      b2kSetFriction tBody, 0
      b2kSetVelocity tBody, rnd(-130, 130), rnd(-130, 130)
   end repeat
   put 48 into gRayN
   repeat with tI = 1 to gRayN
      create graphic ("demo_ray_" & tI)
      set the style of graphic ("demo_ray_" & tI) to "line"
      set the lineSize of graphic ("demo_ray_" & tI) to 1
      set the foregroundColor of graphic ("demo_ray_" & tI) to "0,214,130"
      set the blendLevel of graphic ("demo_ray_" & tI) to 28
   end repeat
   create graphic "demo_emitter"
   set the style of graphic "demo_emitter" to "oval"
   set the filled of graphic "demo_emitter" to true
   set the backgroundColor of graphic "demo_emitter" to "0,230,140"
   set the foregroundColor of graphic "demo_emitter" to "190,255,220"
   set the lineSize of graphic "demo_emitter" to 2
   set the width of graphic "demo_emitter" to 16
   set the height of graphic "demo_emitter" to 16
   set the visible of graphic "demo_emitter" to false
   put "Move the mouse inside the arena — rays scan outward and stop at the nearest shape." into gObjective
end buildLidar

-- =====================================================================
-- Per-frame hook (the Kit sends this once per simulated frame)
-- =====================================================================
on b2kFrame
   switch gScene
      case "vehicle"
         driveFrame
         break
      case "lidar"
         renderLidar
         break
      case "pyramid"
         framePyramid
         break
   end switch
   renderCables
   updateFlashes
   updateBombs
   updateRings
   tickHud
end b2kFrame

-- Count how many tower blocks have been knocked well away from where they
-- started — the demolition "score".
on framePyramid
   local t, tScattered, tX
   put 0 into tScattered
   repeat for each line t in gTargets
      put empty into tX
      try
         put item 1 of the loc of t into tX
      catch tErr
      end try
      if tX is not empty and abs(tX - gSpawnX[t]) > 70 then add 1 to tScattered
   end repeat
   put "Scattered: " & tScattered & " / " & (the number of lines of gTargets) \
         & "   ·   pick the Bomb tool and click the stack" into gObjective
end framePyramid

on driveFrame
   if gThrottleTtl > 0 then
      subtract 1 from gThrottleTtl
   else
      put 0 into gThrottle
   end if
   if gWheelBack is not empty then
      b2kWheelMotor gWheelBack, gThrottle, 170
      b2kWheelMotor gWheelFront, gThrottle, 170
   end if
   updateSpoke "demo_spokeB", gWheelBC
   updateSpoke "demo_spokeF", gWheelFC
   -- car position
   local tCx, tCy
   put empty into tCx
   try
      put item 1 of the loc of gCar into tCx
      put item 2 of the loc of gCar into tCy
   catch tErr
   end try
   if tCx is empty then exit driveFrame
   -- collect coins on contact
   local tCoin, tKeep, tCoinX, tCoinY, dx, dy
   put empty into tKeep
   repeat for each line tCoin in gCoins
      put empty into tCoinX
      try
         put item 1 of the loc of tCoin into tCoinX
         put item 2 of the loc of tCoin into tCoinY
      catch tErr
      end try
      if tCoinX is empty then next repeat
      put tCoinX - tCx into dx
      put tCoinY - tCy into dy
      if dx * dx + dy * dy < 3600 then          -- within 60 px
         add 1 to gScore
         spawnRing tCoinX, tCoinY
         try
            delete tCoin
         end try
      else
         put tCoin & cr after tKeep
      end if
   end repeat
   put tKeep into gCoins
   local tDist
   put round((tCx - gStartX) / 40 * 10) / 10 into tDist
   put "Coins: " & gScore & " / " & gCoinTotal & "        Distance: " & max(0, tDist) \
         & " m        ← / → to drive" into gObjective
end driveFrame

on renderLidar
   local tN, tI, tAng, tEx, tEy, tTx, tTy, tRange, tHx, tHy
   put gRayN into tN
   if tN < 1 then exit renderLidar
   put the mouseH into tEx
   put the mouseV into tEy
   -- Only scan while the cursor is inside the arena, so rays never spill over
   -- the toolbar/HUD (and the UI stays clickable).
   if tEx < gArenaL or tEx > gArenaR or tEy < gArenaT or tEy > gArenaB then
      hideLidar
      exit renderLidar
   end if
   set the visible of graphic "demo_emitter" to true
   set the loc of graphic "demo_emitter" to round(tEx) & "," & round(tEy)
   put 1400 into tRange    -- long enough to always reach a wall, which stops it
   repeat with tI = 1 to tN
      put (tI - 1) * (2 * kPI / tN) into tAng
      put tEx + cos(tAng) * tRange into tTx
      put tEy + sin(tAng) * tRange into tTy
      get b2kRayHit(tEx, tEy, tTx, tTy)
      put b2kRayHitX() into tHx
      put b2kRayHitY() into tHy
      if tHx is empty then       -- a miss: draw the ray out to its far end
         put round(tTx) into tHx
         put round(tTy) into tHy
      end if
      set the points of graphic ("demo_ray_" & tI) to \
            round(tEx) & "," & round(tEy) & cr & tHx & "," & tHy
   end repeat
end renderLidar

on hideLidar
   local tI
   if there is a graphic "demo_emitter" then set the visible of graphic "demo_emitter" to false
   repeat with tI = 1 to gRayN
      if there is a graphic ("demo_ray_" & tI) then set the points of graphic ("demo_ray_" & tI) to empty
   end repeat
end hideLidar

-- Cables (pendulum / cradle): a line from a fixed anchor to a body's centre.
on addCable pAx, pAy, pCtrl
   add 1 to gCableN
   put pAx into gCableAX[gCableN]
   put pAy into gCableAY[gCableN]
   put pCtrl into gCableCtrl[gCableN]
   create graphic ("demo_cable_" & gCableN)
   set the style of graphic ("demo_cable_" & gCableN) to "line"
   set the lineSize of graphic ("demo_cable_" & gCableN) to 2
   set the foregroundColor of graphic ("demo_cable_" & gCableN) to "150,154,168"
end addCable

on renderCables
   local tI
   if gCableN < 1 then exit renderCables
   repeat with tI = 1 to gCableN
      if there is a graphic ("demo_cable_" & tI) then
         try
            set the points of graphic ("demo_cable_" & tI) to \
                  gCableAX[tI] & "," & gCableAY[tI] & cr & the loc of gCableCtrl[tI]
         end try
      end if
   end repeat
end renderCables

-- Contact flashing: light a body's outline white when it starts touching.
on b2kContact pA, pB
   flashCtrl pA
   flashCtrl pB
end b2kContact

on flashCtrl pCtrl
   if pCtrl is empty then exit flashCtrl
   try
      set the foregroundColor of pCtrl to "255,255,255"
      set the lineSize of pCtrl to 2
      put the milliseconds + 150 into gFlash[pCtrl]
   end try
end flashCtrl

on updateFlashes
   local tKey, tNow
   put the milliseconds into tNow
   repeat for each key tKey in gFlash
      if tNow > gFlash[tKey] then
         try
            set the foregroundColor of tKey to "20,20,24"
            set the lineSize of tKey to 1
         end try
         delete variable gFlash[tKey]
      end if
   end repeat
end updateFlashes

-- Bombs: a flashing fuse, then a radial blast + an expanding shock ring.
on spawnBomb pX, pY
   local tBody
   put newBall(pX, pY, 40, "150,40,40") into tBody
   put 60 into gBombs[tBody]
end spawnBomb

on updateBombs
   local tKey, tFuse, tToBlow
   put empty into tToBlow
   repeat for each key tKey in gBombs
      put gBombs[tKey] - 1 into tFuse
      put tFuse into gBombs[tKey]
      if tFuse < 28 then
         try
            if (tFuse mod 6) < 3 then set the backgroundColor of tKey to "245,80,55"
            else set the backgroundColor of tKey to "150,40,40"
         end try
      end if
      if tFuse <= 0 then put tKey & cr after tToBlow
   end repeat
   repeat for each line tKey in tToBlow
      detonate tKey
   end repeat
end updateBombs

on detonate pBomb
   local tLx, tLy
   try
      put item 1 of the loc of pBomb into tLx
      put item 2 of the loc of pBomb into tLy
      b2kExplode tLx, tLy, 210, 720
      spawnRing tLx, tLy
      b2kRemove pBomb
   end try
   delete variable gBombs[pBomb]
end detonate

on spawnRing pX, pY
   add 1 to gRingN
   put pX into gRingX[gRingN]
   put pY into gRingY[gRingN]
   put 0 into gRingF[gRingN]
   create graphic ("demo_ring_" & gRingN)
   set the style of graphic ("demo_ring_" & gRingN) to "oval"
   set the filled of graphic ("demo_ring_" & gRingN) to false
   set the lineSize of graphic ("demo_ring_" & gRingN) to 3
   set the foregroundColor of graphic ("demo_ring_" & gRingN) to "255,170,70"
end spawnRing

on updateRings
   local tI, tFrame, tRad
   if gRingN < 1 then exit updateRings
   repeat with tI = 1 to gRingN
      if gRingF[tI] is not empty then
         put gRingF[tI] + 1 into tFrame
         put tFrame into gRingF[tI]
         if tFrame > 16 then
            if there is a graphic ("demo_ring_" & tI) then delete graphic ("demo_ring_" & tI)
            put empty into gRingF[tI]
         else
            put tFrame * 15 into tRad
            set the rect of graphic ("demo_ring_" & tI) to \
                  round(gRingX[tI] - tRad), round(gRingY[tI] - tRad), \
                  round(gRingX[tI] + tRad), round(gRingY[tI] + tRad)
            set the blendLevel of graphic ("demo_ring_" & tI) to round(tFrame / 16 * 85)
         end if
      end if
   end repeat
end updateRings

on tickHud
   add 1 to gFrames
   local tNow
   put the milliseconds into tNow
   if tNow - gFpsTime >= 500 then
      put round(gFrames * 1000 / (tNow - gFpsTime)) into gFps
      put 0 into gFrames
      put tNow into gFpsTime
      updateHud
   end if
end tickHud

on updateHud
   if there is not a field "ui_hud" then exit updateHud
   local tLine
   put sceneTitle(gScene) & "        FPS " & gFps & "        Bodies " \
         & b2kBodyCount() & " (" & b2kAwakeCount() & " awake)" into tLine
   if gObjective is not empty then put "        " & gObjective after tLine
   put tLine into field "ui_hud"
end updateHud

-- =====================================================================
-- Input
-- =====================================================================
on mouseDown
   if "ui_" is in the short name of the target then exit mouseDown
   -- If the script was just (re)compiled, the demo isn't running yet; start it
   -- on the first click rather than acting on an un-built world.
   if b2kWorld() is empty then
      startBox2DDemo
      exit mouseDown
   end if
   if gScene is "lidar" then exit mouseDown
   get b2kGrab(the mouseH, the mouseV)
   if it is empty then sceneClick the mouseH, the mouseV
end mouseDown

on mouseUp
   local tName
   put the short name of the target into tName
   if "ui_scene_" is in tName then
      switchScene the uSceneId of the target
      exit mouseUp
   end if
   if "ui_tool_" is in tName then
      put the uToolId of the target into gTool
      highlightTools
      updateHud
      exit mouseUp
   end if
   b2kRelease
end mouseUp

on mouseRelease
   b2kRelease
end mouseRelease

on arrowKey pKey
   if gScene is "vehicle" then
      if pKey is "right" then
         put -560 into gThrottle
         put 20 into gThrottleTtl
      else if pKey is "left" then
         put 560 into gThrottle
         put 20 into gThrottleTtl
      end if
      exit arrowKey
   end if
   pass arrowKey
end arrowKey

on sceneClick pX, pY
   local tCtrl
   switch gTool
      case "ball"
         put newBall(pX, pY, rnd(28, 64), randomColor()) into tCtrl
         break
      case "capsule"
         put newCapsule(pX, pY, rnd(70, 120), 34, randomColor()) into tCtrl
         break
      case "poly"
         put newPoly(pX, pY, rnd(22, 42), randomColor()) into tCtrl
         break
      case "bomb"
         spawnBomb pX, pY
         exit sceneClick
      default
         put newBox(pX, pY, rnd(34, 60), rnd(34, 60), randomColor()) into tCtrl
   end switch
   registerDrop tCtrl
end sceneClick

-- Keep the count of click-dropped bodies bounded so spamming stays smooth.
on registerDrop pCtrl
   put pCtrl & cr after gDrops
   if the number of lines of gDrops > kMaxDrops then
      local tOldest
      put line 1 of gDrops into tOldest
      delete line 1 of gDrops
      try
         b2kRemove tOldest          -- removes the body (and spawned controls)
         delete tOldest             -- and the graphic, for directly-made polys
      end try
   end if
end registerDrop

-- =====================================================================
-- Body factories  (call as functions; return the control)
-- =====================================================================
function newBox pX, pY, pW, pH, pColor
   b2kSpawnBox pX, pY, pW, pH, pColor
   return the result
end newBox

function newBall pX, pY, pDiam, pColor
   b2kSpawnBall pX, pY, pDiam, pColor
   return the result
end newBall

function newCapsule pX, pY, pLen, pThick, pColor
   b2kSpawnCapsule pX, pY, pLen, pThick, pColor
   return the result
end newCapsule

function newPoly pX, pY, pR, pColor
   local tName, tRef, tI, tAng, tPoints
   put "demo_poly_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the backgroundColor of tRef to pColor
   set the foregroundColor of tRef to "20,20,24"
   set the lineSize of tRef to 1
   put empty into tPoints
   repeat with tI = 0 to 5
      put tI * 60 * kPI / 180 into tAng
      put round(pX + pR * cos(tAng)) & "," & round(pY + pR * sin(tAng)) & cr after tPoints
   end repeat
   set the points of tRef to tPoints
   b2kAddPolygon tRef
   return tRef
end newPoly

function newStaticBar pX, pY, pW, pH, pColor
   local tName, tRef
   put "demo_static_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the backgroundColor of tRef to pColor
   set the foregroundColor of tRef to "20,20,24"
   set the lineSize of tRef to 1
   set the width of tRef to pW
   set the height of tRef to pH
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddStatic tRef
   return tRef
end newStaticBar

-- =====================================================================
-- UI
-- =====================================================================
on buildUI
   clearUI
   local tWide, tI, tScene, tTool, tX
   put the width of this card into tWide

   makeBar "ui_header", 0, 0, tWide, 54, "30,33,42"
   makeBar "ui_accent", 0, 54, tWide, 57, "64,132,232"
   makeLabel "ui_title", 18, 11, 320, 44, "Box2Dxt", 22, "236,238,245", true
   makeLabel "ui_sub", 20, 33, 460, 53, "Box2D v3 physics · the OpenXTalk Kit, in action", 11, "150,154,166", false

   put 16 into tX
   repeat with tI = 1 to the number of items of kScenes
      put item tI of kScenes into tScene
      makeButton ("ui_scene_" & tScene), (item tI of kLabels), tX, 66, 96, 28
      set the uSceneId of button ("ui_scene_" & tScene) to tScene
      add 100 to tX
   end repeat

   put tWide - (5 * 62) - 8 into tX
   repeat with tI = 1 to the number of items of kTools
      put item tI of kTools into tTool
      makeButton ("ui_tool_" & tTool), (item tI of kToolLabels), tX, 66, 58, 28
      set the uToolId of button ("ui_tool_" & tTool) to tTool
      add 62 to tX
   end repeat

   makeBar "ui_hudbar", 0, 100, tWide, 126, "18,20,26"
   makeField "ui_hud", 12, 103, tWide - 12, 124, 12, "224,226,234"
   makeBar "ui_helpbar", 0, (the height of this card) - 28, tWide, the height of this card, "18,20,26"
   makeField "ui_help", 12, (the height of this card) - 26, tWide - 12, (the height of this card) - 5, 11, "168,172,184"
end buildUI

on clearUI
   local tI, tName
   repeat with tI = the number of controls of this card down to 1
      put the short name of control tI of this card into tName
      if char 1 to 3 of tName is "ui_" then delete control tI of this card
   end repeat
end clearUI

on clearSceneControls
   local tI, tName
   repeat with tI = the number of controls of this card down to 1
      put the short name of control tI of this card into tName
      if char 1 to 3 of tName is not "ui_" then delete control tI of this card
   end repeat
end clearSceneControls

on makeBar pName, pLeft, pTop, pRight, pBottom, pColor
   create graphic pName
   set the style of graphic pName to "rectangle"
   set the filled of graphic pName to true
   set the lineSize of graphic pName to 0
   set the backgroundColor of graphic pName to pColor
   set the rect of graphic pName to pLeft, pTop, pRight, pBottom
end makeBar

on makeLabel pName, pLeft, pTop, pRight, pBottom, pText, pSize, pColor, pBold
   create field pName
   set the rect of field pName to pLeft, pTop, pRight, pBottom
   set the locked of field pName to true
   set the traversalOn of field pName to false
   set the opaque of field pName to false
   set the showBorder of field pName to false
   set the borderWidth of field pName to 0
   set the textSize of field pName to pSize
   set the textColor of field pName to pColor
   if pBold then set the textStyle of field pName to "bold"
   put pText into field pName
end makeLabel

on makeField pName, pLeft, pTop, pRight, pBottom, pSize, pColor
   create field pName
   set the rect of field pName to pLeft, pTop, pRight, pBottom
   set the locked of field pName to true
   set the traversalOn of field pName to false
   set the opaque of field pName to false
   set the showBorder of field pName to false
   set the borderWidth of field pName to 0
   set the textSize of field pName to pSize
   set the textColor of field pName to pColor
   set the margins of field pName to 6
end makeField

on makeButton pName, pLabel, pX, pY, pW, pH
   create button pName
   set the label of button pName to pLabel
   set the autoHilite of button pName to false
   set the opaque of button pName to true
   set the showBorder of button pName to false
   set the threeD of button pName to false
   set the textSize of button pName to 11
   set the rect of button pName to pX, pY, pX + pW, pY + pH
end makeButton

on highlightScenes
   local tScene
   repeat for each item tScene in kScenes
      if there is a button ("ui_scene_" & tScene) then
         if tScene is gScene then
            set the backgroundColor of button ("ui_scene_" & tScene) to "64,132,232"
            set the textColor of button ("ui_scene_" & tScene) to "255,255,255"
         else
            set the backgroundColor of button ("ui_scene_" & tScene) to "44,48,58"
            set the textColor of button ("ui_scene_" & tScene) to "196,200,212"
         end if
      end if
   end repeat
end highlightScenes

on highlightTools
   local tTool
   repeat for each item tTool in kTools
      if there is a button ("ui_tool_" & tTool) then
         if tTool is gTool then
            set the backgroundColor of button ("ui_tool_" & tTool) to "72,190,130"
            set the textColor of button ("ui_tool_" & tTool) to "255,255,255"
         else
            set the backgroundColor of button ("ui_tool_" & tTool) to "44,48,58"
            set the textColor of button ("ui_tool_" & tTool) to "196,200,212"
         end if
      end if
   end repeat
end highlightTools

on setHelp
   if there is a field "ui_help" then put sceneHelp(gScene) into field "ui_help"
end setHelp

-- =====================================================================
-- Helpers
-- =====================================================================
function shapePalette
   return "92,150,222" & cr & "84,206,142" & cr & "232,182,92" & cr \
         & "214,92,92" & cr & "206,124,206" & cr & "120,200,232"
end shapePalette

function accentShape pIndex
   return line (((pIndex - 1) mod 6) + 1) of shapePalette()
end accentShape

function randomColor
   return line (random(6)) of shapePalette()
end randomColor

function pyramidColor pRow, pRows
   local tT, tRed, tGreen, tBlue
   put pRow / (pRows - 1) into tT
   put round(80 + tT * 150) into tRed
   put round(120 + tT * 60) into tGreen
   put round(220 - tT * 120) into tBlue
   return tRed & "," & tGreen & "," & tBlue
end pyramidColor

function rnd pLow, pHigh
   return pLow + random(max(1, pHigh - pLow))
end rnd

function sceneTitle pScene
   switch pScene
      case "playground"
         return "PLAYGROUND — shapes, a see-saw, a motorised windmill & a pendulum"
      case "pyramid"
         return "PYRAMID — stacking (pick the Bomb tool and click the stack!)"
      case "cradle"
         return "NEWTON'S CRADLE — distance/hinge joints + restitution"
      case "bridge"
         return "BRIDGE — a chain of revolute joints you can load up"
      case "vehicle"
         return "VEHICLE — wheel joints, a motor & spring suspension"
      case "lidar"
         return "LIDAR — live ray casting that follows your mouse"
   end switch
   return pScene
end sceneTitle

function sceneHelp pScene
   local tTail
   put "   Drag any body with the mouse. Click empty space to add the selected shape (top-right). Click a tab to reset that scene." into tTail
   switch pScene
      case "vehicle"
         return "Drive with the LEFT / RIGHT arrow keys to climb the bumps. Drag the car to mess with it." & tTail
      case "lidar"
         return "Move the mouse — rays fan out from the cursor and each stops at the nearest shape (b2kRayHit)."
      case "pyramid"
         return "Choose the Bomb tool and click beside the stack to scatter it with a blast." & tTail
      case "cradle"
         return "Momentum carries through the line of balls. Drag one aside and let go." & tTail
   end switch
   return "Bodies flash white the instant they touch (contact events)." & tTail
end sceneHelp
