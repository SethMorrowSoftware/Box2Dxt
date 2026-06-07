-- #####################################################################
-- #  Box2Dxt  —  CONTRAPTION BUILDER  (Kit + builder GUI in one file) #
-- #                                                                   #
-- #  An interactive sandbox. Drop parts (boxes, balls, capsules,      #
-- #  polygons, imported images and static anchors), wire them up with #
-- #  joints (hinge, weld, rope, slider, wheel), add motors, then      #
-- #  press Run to simulate. It shows how little xTalk it takes to      #
-- #  build a working machine with Box2Dxt.                            #
-- #                                                                   #
-- #  HOW TO RUN                                                       #
-- #   1. Load the box2dxt.lcb extension and put the box2dxt native    #
-- #      library where it can be found. Check: put b2Version()  -- 3  #
-- #   2. Paste THIS WHOLE FILE into a stack's script                  #
-- #      (Object > Stack Script).                                     #
-- #   3. Open/close the card, or run  startCB  in the Message Box.    #
-- #      Stop with  stopCB.                                           #
-- #                                                                   #
-- #  This file bundles a verbatim copy of the reusable Kit            #
-- #  (src/box2dxt-kit.livecodescript) so it runs from a single paste. #
-- #  For your own projects, load the Kit on its own instead.          #
-- #                                                                   #
-- #  Targets OpenXTalk / LiveCode 9.6.3. LiveCode naming throughout:  #
-- #  p* params, t* locals, g* script-locals, k* constants, u* custom  #
-- #  properties, so nothing collides with reserved words.             #
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
-- CONTRAPTION BUILDER  ·  built on the Kit above (b2k...)
--
-- A free-form construction GUI: place parts, connect them with joints,
-- motorise the joints, then flip Build -> Run to watch it go. Every line
-- below only ever calls the friendly b2k... Kit, in screen pixels.
--
-- WORKFLOW
--   · BUILD mode (the loop is stopped, so nothing falls): click empty
--     canvas with a shape tool to drop a part; drag parts to arrange them;
--     the Delete tool removes a part and its joints.
--   · Pick a joint tool, then click part A and part B to connect them.
--     A Hinge pinned to an Anchor (or empty space = the world) makes the
--     best motor mount. Overlapping parts connect fine.
--   · Motor drives new Hinge / Wheel joints; Bouncy makes new parts springy.
--   · RUN mode: gravity + motors run; drag any body with the mouse.
--   · Save / Load store and restore a whole contraption as text.
--
-- NAMING: p* params, t* locals, g* script-locals, k* constants, u* custom
-- properties. kPI is already defined by the embedded Kit above (do not
-- redeclare it). All coordinates here are SCREEN PIXELS.
-- =====================================================================

local gMode, gTool, gJointTool
local gPendCtrl, gPendX, gPendY
local gMotorOn, gMotorSpeed, gBouncy, gMotorsRunning
local gDragCtrl, gDragMode, gDragMoved
local gDrawPts, gDrawCtrl               -- freehand-terrain points + its preview graphic
local gParts
local gJN
local gJKind, gJHandle, gJCa, gJCb
local gJPx, gJPy, gJMotor, gJVis, gJEnd
local gArenaL, gArenaR, gArenaT, gArenaB
local gStatus
local gNextPid
local gNameCount                       -- per-kind counter for auto-names (Bomb 1, Plate 2, ...)
local gWires                           -- CR-list of signal wires, each "srcCtrl<tab>tgtCtrl" (long ids)
local gWireSrc                         -- the pending wire source while the Link tool waits for a target
local gFlash
local gFrames, gFpsTime, gFps, gHudTime   -- gHudTime throttles the live HUD/telemetry refresh
-- new-object + field-force state (balloons rise on their own; fans/magnets are
-- body-less zones that push parts each frame; plates count what rests on them).
-- gKindList[kind] holds a CR-delimited control list per special kind.
local gKindList
local gPlateLoad, gPlateState
local gSensorCount      -- per-sensor count of bodies currently inside (fires on 0→1)
local gRingN, gRingX, gRingY, gRingF
local gDynParts, gDynDirty
-- selection / inspector / onboarding / stress-test bookkeeping
local gSelPart, gHoverId, gOnbStep, gStressCount
local gSelJoint                        -- selected joint index (1..gJN), empty if none
local gFilterPart                      -- part whose collision filter the popup panel is editing
local gInspTab                         -- active inspector tab: shape | physics | collide | special
local gGravityMode                     -- world gravity preset: normal|low|zero|reverse|sideways
local gWorldFeel                       -- world-tuning preset: default|bouncy|floaty|snappy
local gCCD, gSleepOn, gWarmStart, gSubsteps   -- advanced world solver toggles (the "World · Advanced" panel)
local gPreRun                          -- snapshot of the build, taken when Run starts
local gPalOpen                         -- CR-list of palette section titles currently expanded

constant kEditTools    = "drag,delete,duplicate,multiply,link"
constant kEditLabels   = "Drag,Delete,Duplicate,Multiply,Link"
constant kShapeTools   = "box,ball,capsule,poly,image,anchor"
constant kShapeLabels  = "Box,Ball,Capsule,Polygon,Image,Anchor"
constant kSpecialTools = "balloon,bomb,plate,fan,magnet,sensor,laser,thruster"
constant kSpecialLabels = "Balloon,Bomb,Pressure Plate,Fan,Magnet,Sensor,Laser,Thruster"
constant kTerrainTools = "platform,ramp,hill,draw"
constant kTerrainLabels = "Platform,Ramp,Hill,Draw"
constant kDrawStep = 14       -- min pixels between sampled points while drawing freehand terrain
constant kDrawLineSize = 7    -- drawn ground is thick: reads as solid + easy to click/select
constant kVehicleTools = "car"
constant kVehicleLabels = "Car"
constant kJointTools   = "hinge,weld,servo,rope,slider,wheel,bridge,chain"
constant kJointLabels  = "Hinge,Weld,Servo,Rope,Slider,Wheel,Bridge,Chain"
constant kHingeTorque = 1500, kWheelTorque = 320
constant kBridgeFlex = 30   -- a bridge plank pin flexes +/- this many degrees, so a
                            -- loaded deck sags under weight but can never fold back on itself
constant kServoForce = 3000, kServoTorque = 2500   -- how hard a Servo joint holds its pose

-- Layout, in screen pixels. Derived edges (canvas L/R/T/B) are computed from the
-- card size in prepArena/buildUI, because LiveCode constants cannot be expressions.
constant kStackW = 1180, kStackH = 760
constant kTopBarH = 54, kAccentH = 3
constant kPaletteW = 196, kInspectorW = 248, kStatusH = 26
constant kCanvasInset = 2, kGroundBarH = 22
constant kPalPadX = 12, kPalBtnH = 28, kPalBtnGap = 4
constant kPalSectionGap = 8, kPalHeaderH = 22, kPalScrollW = 16, kPalGutterW = 22
-- Bump kUIVersion whenever the built chrome changes, so older saved stacks rebuild once.
constant kUIVersion = "9"

-- Palette theme: one source of truth for the chrome colours (RGB strings) so the
-- idle / active / hover styling never drifts apart. Used by the setBtn*, highlight*
-- and hover helpers. (String literals are valid constants; expressions are not.)
constant kColPaletteBg = "26,28,35", kColBtnIdle = "44,48,58", kColBtnIdleText = "196,200,212"
constant kColBtnHover = "58,64,78", kColBtnText = "255,255,255"
constant kColAccentGreen = "72,190,130", kColAccentAmber = "232,150,72", kColToggleBlue = "64,132,232"
constant kColDanger = "214,92,92", kColHeaderText = "150,156,172", kColRule = "52,57,70"
-- Former magic numbers: starting motor speed (°/s) and world gravity (downward).
constant kDefaultMotorSpeed = 120, kDefaultGravity = -10

-- Materials, motors, feedback timing, and default part sizes (were magic numbers).
constant kBounceOn = 0.7, kFlashMs = 150, kSelectLine = 3
constant kMotorMin = 30, kMotorMax = 600, kFpsWindowMs = 500, kImageMax = 120
constant kBoxMin = 40, kBoxMax = 64, kBallMin = 34, kBallMax = 60
constant kCapLenMin = 80, kCapLenMax = 120, kCapThick = 36
constant kPolyMin = 26, kPolyMax = 44

-- New objects (all built from existing Kit primitives, screen pixels / degrees).
constant kBalloonGravScale = -0.6, kBalloonDamp = 1.2, kBalloonDiam = 46
constant kBombDiam = 40, kBombRadius = 210, kBombPower = 720
constant kBombFuseFrames = 60, kBombImpactSpeed = 700
constant kPlateW = 120, kPlateH = 16
constant kSensorW = 96, kSensorH = 72
constant kFanW = 130, kFanH = 150, kFanForce = 900
constant kMagnetRange = 220, kMagnetForce = 1400, kMagnetMinDist = 16
constant kLaserReach = 1600, kLaserStep = 45   -- laser ray length (px) and the angle step its direction cycles by
constant kContainMargin = 90   -- how far past the arena a body may stray before the containment net pulls it back
constant kStressBatch = 50
constant kSizeMin = 16, kSizeMax = 240
-- Terrain (static scenery) can be larger than parts — wide ledges, long ramps.
constant kTerrainMin = 20, kTerrainMax = 600
-- inspector: rows shown per tab, dimension nudge (px), joint click radius (px)
constant kPropRows = 10, kDimStep = 8, kJointHitR = 16
-- the eight collision channels the filter popup exposes (1..8 -> bits 1,2,4..128)
constant kFilterChannels = 8, kAllChannels = "1,2,3,4,5,6,7,8"
-- numeric settings a user may type an exact value for (toggles/colour stay stepper-only)
constant kEntryKeys = "width,height,length,thickness,diameter,size,angle,bounce,density,friction,gravity,lindamp,angdamp,launchspeed,launchdir,spinrate,blastradius,blastpower,fanforce,fansize,magforce,magrange"

-- =====================================================================
-- Lifecycle
-- =====================================================================
-- Build once: startCB generates the chrome on first run and stamps a version on the
-- stack, so save the stack afterwards. On later opens chromeBuilt() is true, so the
-- ~200-control UI is NOT rebuilt — only the native physics world is recreated (it
-- can't be serialised). Run rebuildCB to regenerate the chrome after editing the
-- builder; bumping kUIVersion makes any older saved stack rebuild itself once.
on preOpenCard
   startCB
end preOpenCard

on closeCard
   stopCB
end closeCard

on startCB
   set the title of this stack to "Box2Dxt — Contraption Builder"
   set the decorations of this stack to "default"
   set the resizable of this stack to false
   set the width of this stack to kStackW
   set the height of this stack to kStackH
   set the loc of this stack to the screenLoc
   set the backgroundColor of this card to "22,24,30"
   put "build" into gMode
   put "drag" into gTool
   put empty into gJointTool
   put false into gMotorOn
   put true into gMotorsRunning
   put kDefaultMotorSpeed into gMotorSpeed
   put false into gBouncy
   put empty into gParts
   put empty into gFlash
   put 1 into gNextPid
   put 0 into gFrames
   put empty into gFps
   put the milliseconds into gFpsTime
   put empty into gSelPart
   put empty into gSelJoint
   put "shape" into gInspTab
   put "normal" into gGravityMode
   put "default" into gWorldFeel
   setWorldOptionDefaults
   put empty into gHoverId
   put 0 into gStressCount
   put "SHAPES" into gPalOpen        -- single-open accordion: SHAPES is the category open first
   resetSceneState
   resetJointArrays
   resetPend
   if not chromeBuilt() then         -- build the chrome once; it persists in the saved stack
      buildUI
      set the uUIVersion of this stack to kUIVersion
   end if
   b2kSetup 0, kDefaultGravity      -- creates the world; the loop stays stopped
   prepArena
   b2kFrameTarget the long id of this stack
   b2kContactTarget the long id of this stack
   raiseUI
   highlightAll
   layoutPalette                    -- re-apply accordion state to the persisted palette
   showInspectorForTool
   put "Welcome! Pick a shape on the left, click the stage to drop it, then press Run." into gStatus
   updateHud
   maybeShowOnboarding
end startCB

on stopCB
   b2kTeardown
   put empty into gParts
   put empty into gFlash
   resetSceneState
   resetJointArrays
   clearSceneControls
end stopCB

-- Force a one-time chrome rebuild — after editing the builder, or to repair the UI.
on rebuildCB
   set the uUIVersion of this stack to empty
   startCB
end rebuildCB

-- Draw every part + joint once. Build mode stops the loop (so nothing falls),
-- which also stops the Kit's own redraw — so we sync by hand after each edit.
on renderBuild
   if b2kWorld() is empty then exit renderBuild
   lock screen
   b2kSync
   renderJoints
   updateLasers
   drawWires
   unlock screen
end renderBuild

-- =====================================================================
-- Arena (walls + a framed play field, mirrors the showcase demo)
-- =====================================================================
on prepArena
   set the acceleratedRendering of this stack to true   -- GPU compositing so dynamic-layer bodies move without trails/clipping
   local tWide, tHigh, tCanvasL, tCanvasR, tCanvasT, tCanvasB
   put the width of this card into tWide
   put the height of this card into tHigh
   put kPaletteW into tCanvasL                  -- play field sits between the panels
   put tWide - kInspectorW into tCanvasR
   put kTopBarH + kAccentH into tCanvasT
   put tHigh - kStatusH into tCanvasB
   put tCanvasL + kCanvasInset into gArenaL
   put tCanvasR - kCanvasInset into gArenaR
   put tCanvasT + kCanvasInset into gArenaT
   put tCanvasB - kGroundBarH into gArenaB
   if there is not a graphic "cb_field" then create graphic "cb_field"
   set the style of graphic "cb_field" to "rectangle"
   set the filled of graphic "cb_field" to true
   set the backgroundColor of graphic "cb_field" to "26,29,37"
   set the foregroundColor of graphic "cb_field" to "46,60,86"
   set the lineSize of graphic "cb_field" to 2
   set the rect of graphic "cb_field" to gArenaL, gArenaT, gArenaR, gArenaB + kGroundBarH
   b2kWall gArenaL, gArenaB, gArenaR, gArenaB    -- floor
   b2kWall gArenaL, gArenaT, gArenaR, gArenaT    -- ceiling
   b2kWall gArenaL, gArenaB, gArenaL, gArenaT    -- left wall
   b2kWall gArenaR, gArenaB, gArenaR, gArenaT    -- right wall
   if there is not a graphic "cb_groundbar" then create graphic "cb_groundbar"
   set the style of graphic "cb_groundbar" to "rectangle"
   set the filled of graphic "cb_groundbar" to true
   set the backgroundColor of graphic "cb_groundbar" to "44,49,60"
   set the lineSize of graphic "cb_groundbar" to 0
   set the rect of graphic "cb_groundbar" to gArenaL, gArenaB, gArenaR, gArenaB + kGroundBarH
end prepArena

-- =====================================================================
-- UI
-- =====================================================================
-- The chrome is generated once and saved with the stack; chromeBuilt reports whether
-- the persisted UI is present and current, so startCB can skip the rebuild on reopen.
-- (A version mismatch — e.g. after the builder is updated — rebuilds it once.)
function chromeBuilt
   return (there is a group "ui_palettescroll") and (the uUIVersion of this stack is kUIVersion)
end chromeBuilt

-- Build the whole UI: a top action bar, a grouped tool palette on the left, an
-- inspector/help panel on the right, and a status bar along the bottom.
on buildUI
   clearUI
   makeTopBar
   makePalette
   makeInspector
   makeStatusBar
   buildRecipesMenu
   buildFilterPanel
   buildWorldPanel
   applyTooltips
end buildUI

-- Top bar: brand on the left, the global actions right-aligned.
on makeTopBar
   local tWide, tY, tX, tIds, tLbls, tWidths, tGap, tI, tId, tW
   put the width of this card into tWide
   makeBar "ui_header", 0, 0, tWide, kTopBarH, "30,33,42"
   makeBar "ui_accent", 0, kTopBarH, tWide, kTopBarH + kAccentH, kColAccentGreen
   makeLabel "ui_title", 18, 7, 280, 33, "Box2Dxt", 22, "236,238,245", true
   makeLabel "ui_sub", 20, 32, 560, 50, "Contraption Builder — build a machine, then press Run to bring it to life", 11, "150,154,166", false
   put "mode,reset,clear,save,load,worldadv,recipes,info" into tIds
   put "Run,Reset,Clear,Save,Load,World,Recipes,?" into tLbls
   put "84,60,64,64,64,64,84,30" into tWidths
   put 6 into tGap
   put 0 into tW
   repeat for each item tId in tWidths
      add tId + tGap to tW
   end repeat
   put tWide - 12 - (tW - tGap) into tX
   put 13 into tY
   repeat with tI = 1 to the number of items of tIds
      makeAction (item tI of tIds), (item tI of tLbls), tX, tY, (item tI of tWidths), 28
      add (item tI of tWidths) + tGap to tX
   end repeat
end makeTopBar

-- Left palette: six colour-coded categories (TOOLS, SHAPES, SPECIAL, TERRAIN,
-- VEHICLES, JOINTS) as a single-open accordion — opening one collapses the others,
-- so the whole toolbox fits the window without a scrollbar. Drag/Delete/Duplicate/
-- Multiply live under TOOLS; SHAPES holds only the parts you actually drop.
on makePalette
   local tWide, tHigh, tY
   put the width of this card into tWide
   put the height of this card into tHigh
   makeBar "ui_palettebg", 0, kTopBarH + kAccentH, kPaletteW, tHigh - kStatusH, kColPaletteBg
   put kTopBarH + kAccentH + 8 into tY
   put makeToolSection("TOOLS", kEditTools, kEditLabels, "tool", tY) into tY
   put makeToolSection("SHAPES", kShapeTools, kShapeLabels, "tool", tY) into tY
   put makeToolSection("SPECIAL", kSpecialTools, kSpecialLabels, "tool", tY) into tY
   put makeToolSection("TERRAIN", kTerrainTools, kTerrainLabels, "tool", tY) into tY
   put makeToolSection("VEHICLES", kVehicleTools, kVehicleLabels, "tool", tY) into tY
   put makeToolSection("JOINTS", kJointTools, kJointLabels, "joint", tY) into tY
   groupPalette
   layoutPalette                          -- apply collapse/expand state, chevrons and scrollbar
end makePalette

-- Wrap the section headers + tool buttons in one scrolling group. The grouping
-- idiom: select the controls, then `group` (the new group is returned in `it`).
on groupPalette
   local tT, tId, tErr
   if there is a group "ui_palettescroll" then exit groupPalette
   -- If grouping ever fails on a platform, degrade to an un-grouped (non-scrolling)
   -- palette rather than aborting the whole UI build.
   try
      select empty
      repeat for each item tT in "TOOLS,SHAPES,SPECIAL,TERRAIN,VEHICLES,JOINTS"
         if there is a button ("ui_hdr_" & tT) then set the selected of button ("ui_hdr_" & tT) to true
         if there is a graphic ("ui_hdrrule_" & tT) then set the selected of graphic ("ui_hdrrule_" & tT) to true
      end repeat
      repeat for each item tId in (kEditTools & comma & kShapeTools & comma & kTerrainTools & comma & kSpecialTools & comma & kVehicleTools)
         if there is a button ("ui_tool_" & tId) then set the selected of button ("ui_tool_" & tId) to true
      end repeat
      repeat for each item tId in kJointTools
         if there is a button ("ui_joint_" & tId) then set the selected of button ("ui_joint_" & tId) to true
      end repeat
      repeat for each item tId in (kEditTools & comma & kShapeTools & comma & kTerrainTools & comma & kSpecialTools & comma & kVehicleTools & comma & kJointTools)
         if there is a field ("ui_g_" & tId) then set the selected of field ("ui_g_" & tId) to true
      end repeat
      group
      set the name of it to "ui_palettescroll"
      select empty
      set the showName of group "ui_palettescroll" to false
      set the showBorder of group "ui_palettescroll" to false
      set the borderWidth of group "ui_palettescroll" to 0
      set the margins of group "ui_palettescroll" to 0
      set the opaque of group "ui_palettescroll" to false
      set the hScrollbar of group "ui_palettescroll" to false
      set the vScrollbar of group "ui_palettescroll" to false   -- single-open always fits; no native bar
      set the unboundedVScroll of group "ui_palettescroll" to false
      set the rect of group "ui_palettescroll" to 0, kTopBarH + kAccentH, kPaletteW, (the height of this card) - kStatusH
      set the vScroll of group "ui_palettescroll" to 0
   catch tErr
      select empty
   end try
end groupPalette

-- Build one labelled palette section: a clickable accordion header (chevron + title)
-- over a hairline rule, then the tool rows. Each row is a left-aligned text button
-- with its glyph in a fixed-width gutter on the left, so every label lines up no
-- matter how wide the glyph is. layoutPalette repositions/shows/hides these after.
function makeToolSection pTitle, pIds, pLabels, pKind, pStartY
   local tY, tI, tId, tLbl, tName, tRight, tGut
   put pStartY into tY
   put kPaletteW - kPalPadX into tRight                      -- shared right edge (symmetric inset, no scrollbar)
   put kPalPadX + kPalGutterW into tGut                      -- labels start after the glyph gutter
   makeButton ("ui_hdr_" & pTitle), (chevronGlyph(pTitle) && pTitle), kPalPadX, tY, tRight - kPalPadX, kPalHeaderH
   set the textAlign of button ("ui_hdr_" & pTitle) to "left"
   set the textStyle of button ("ui_hdr_" & pTitle) to "bold"
   set the textSize of button ("ui_hdr_" & pTitle) to 10
   set the textColor of button ("ui_hdr_" & pTitle) to kColHeaderText
   set the opaque of button ("ui_hdr_" & pTitle) to false   -- reads as a label, still fully clickable
   set the uHdr of button ("ui_hdr_" & pTitle) to pTitle
   makeBar ("ui_hdrrule_" & pTitle), kPalPadX, tY + kPalHeaderH, tRight, tY + kPalHeaderH + 1, kColRule
   add kPalHeaderH + 6 to tY
   repeat with tI = 1 to the number of items of pIds
      put item tI of pIds into tId
      put item tI of pLabels into tLbl
      if pKind is "joint" then
         put "ui_joint_" & tId into tName
         makeButton tName, tLbl, tGut, tY, tRight - tGut, kPalBtnH
         set the uJointId of button tName to tId
      else
         put "ui_tool_" & tId into tName
         makeButton tName, tLbl, tGut, tY, tRight - tGut, kPalBtnH
         set the uToolId of button tName to tId
      end if
      set the textAlign of button tName to "left"          -- menu-style: labels start at the left
      set the margins of button tName to 8
      set the tooltip of button tName to line 1 of toolHelp(tId)   -- set now; survives grouping
      makeLabel ("ui_g_" & tId), kPalPadX, tY, tGut, tY + kPalBtnH, toolGlyph(tId), 13, kColBtnIdleText, false
      set the textAlign of field ("ui_g_" & tId) to "center"
      set the margins of field ("ui_g_" & tId) to 4
      add kPalBtnH + kPalBtnGap to tY
   end repeat
   return tY + kPalSectionGap
end makeToolSection

-- ▾ when a section is expanded, ▸ when collapsed (drives the header label).
function chevronGlyph pTitle
   if pTitle is among the lines of gPalOpen then return "▾"
   return "▸"
end chevronGlyph

-- Title → its tool ids / kind. No new data: routes to the existing constant lists.
function sectionIds pTitle
   switch pTitle
      case "TOOLS"
         return kEditTools
      case "SHAPES"
         return kShapeTools
      case "TERRAIN"
         return kTerrainTools
      case "SPECIAL"
         return kSpecialTools
      case "VEHICLES"
         return kVehicleTools
      case "JOINTS"
         return kJointTools
   end switch
   return empty
end sectionIds

function sectionKind pTitle
   if pTitle is "JOINTS" then return "joint"
   return "tool"
end sectionKind

-- Each category owns an accent colour. It fills the header when the section is open,
-- tints the header title when collapsed, and lights up the selected tool inside it —
-- so the palette reads as distinct, colour-coded groups (white text stays legible on
-- every one of these).
function categoryColor pTitle
   switch pTitle
      case "TOOLS"
         return "76,122,210"
      case "SHAPES"
         return kColAccentGreen
      case "SPECIAL"
         return "158,100,205"
      case "TERRAIN"
         return "190,140,72"
      case "VEHICLES"
         return "66,172,182"
      case "JOINTS"
         return kColAccentAmber
   end switch
   return kColAccentGreen
end categoryColor

-- Lay the palette out from gPalOpen. Every header shows (chevron + colour-coded
-- title); the open category reveals its rule + glyph gutters + tool buttons, while
-- collapsed categories hide their rows and park them at the top of the content. With
-- one category open at a time the whole toolbox fits the panel, so there is no native
-- scrollbar to flicker or resize — the viewport rect is re-asserted here each time.
on layoutPalette
   if there is not a group "ui_palettescroll" then exit layoutPalette
   local tY, tTitle, tIds, tPrefix, tId, tBtn, tGlyph, tOpen, tRight, tGut, tPark, tHdr
   lock screen
   -- Re-assert the viewport rect every layout (a stale persisted height was what let
   -- the native bar flicker in) and keep it bar-free: a single open category always
   -- fits, so nothing needs to scroll.
   set the rect of group "ui_palettescroll" to 0, kTopBarH + kAccentH, kPaletteW, (the height of this card) - kStatusH
   set the vScrollbar of group "ui_palettescroll" to false
   set the vScroll of group "ui_palettescroll" to 0   -- lay children out in unscrolled card coords
   put kPaletteW - kPalPadX into tRight
   put kPalPadX + kPalGutterW into tGut
   put kTopBarH + kAccentH + 8 into tY
   put tY into tPark                                  -- collapsed rows park here (top of content)
   repeat for each item tTitle in "TOOLS,SHAPES,SPECIAL,TERRAIN,VEHICLES,JOINTS"
      put sectionIds(tTitle) into tIds
      if sectionKind(tTitle) is "joint" then put "ui_joint_" into tPrefix
      else put "ui_tool_" into tPrefix
      put ("ui_hdr_" & tTitle) into tHdr
      put (tTitle is among the lines of gPalOpen) into tOpen
      -- Header reads as a colour-coded bar: filled in the category colour when open,
      -- just the coloured title when collapsed.
      set the rect of button tHdr to kPalPadX, tY, tRight, tY + kPalHeaderH
      set the label of button tHdr to (chevronGlyph(tTitle) && tTitle)
      if tOpen then
         set the opaque of button tHdr to true
         set the backgroundColor of button tHdr to categoryColor(tTitle)
         set the textColor of button tHdr to kColBtnText
      else
         set the opaque of button tHdr to false
         set the textColor of button tHdr to categoryColor(tTitle)
      end if
      add kPalHeaderH to tY
      if tOpen then
         set the rect of graphic ("ui_hdrrule_" & tTitle) to kPalPadX, tY, tRight, tY + 1
         set the visible of graphic ("ui_hdrrule_" & tTitle) to true
         add 6 to tY
         repeat for each item tId in tIds
            put tPrefix & tId into tBtn
            put "ui_g_" & tId into tGlyph
            if there is a button tBtn then
               set the rect of button tBtn to tGut, tY, tRight, tY + kPalBtnH
               set the visible of button tBtn to true
            end if
            if there is a field tGlyph then
               set the rect of field tGlyph to kPalPadX, tY, tGut, tY + kPalBtnH
               set the visible of field tGlyph to true
            end if
            add kPalBtnH + kPalBtnGap to tY
         end repeat
      else
         set the rect of graphic ("ui_hdrrule_" & tTitle) to kPalPadX, tPark, tRight, tPark + 1
         set the visible of graphic ("ui_hdrrule_" & tTitle) to false
         repeat for each item tId in tIds
            if there is a button (tPrefix & tId) then
               set the rect of button (tPrefix & tId) to tGut, tPark, tRight, tPark + kPalBtnH
               set the visible of button (tPrefix & tId) to false
            end if
            if there is a field ("ui_g_" & tId) then
               set the rect of field ("ui_g_" & tId) to kPalPadX, tPark, tGut, tPark + kPalBtnH
               set the visible of field ("ui_g_" & tId) to false
            end if
         end repeat
      end if
      add kPalSectionGap to tY
   end repeat
   unlock screen
end layoutPalette

-- Single-open accordion: opening a category collapses the others, so the toolbox
-- always fits without a scrollbar. Pure chrome — tool selection and the HUD are left
-- untouched. gPalOpen holds at most one category title (empty = all collapsed).
on togglePaletteSection pTitle
   if pTitle is empty then exit togglePaletteSection
   if pTitle is among the lines of gPalOpen then
      put empty into gPalOpen        -- click the open category to close it
   else
      put pTitle into gPalOpen        -- this category becomes the only open one
   end if
   layoutPalette
end togglePaletteSection

-- Right inspector: a title + plain-language help, a block of property adjusters
-- (hidden until a part is selected), and the persistent build options.
on makeInspector
   local tWide, tHigh, tL, tTop, tI, tRy
   put the width of this card into tWide
   put the height of this card into tHigh
   put tWide - kInspectorW into tL
   put kTopBarH + kAccentH into tTop
   makeBar "ui_inspbg", tL, tTop, tWide, tHigh - kStatusH, kColPaletteBg
   makeLabel "ui_insp_title", tL + 12, tTop + 10, tWide - 86, tTop + 34, "Inspector", 14, "236,238,245", true
   makeAction "rename", "Rename", tWide - 78, tTop + 8, 66, 22
   makeField "ui_insp_body", tL + 12, tTop + 40, tWide - 12, tTop + 118, 11, "190,194,206"
   -- settings tabs: group a part's many settings so each pane stays short
   makeAction "tab_shape", "Shape", tL + 12, tTop + 124, 50, 24
   makeAction "tab_physics", "Physics", tL + 64, tTop + 124, 56, 24
   makeAction "tab_collide", "Collide", tL + 122, tTop + 124, 56, 24
   makeAction "tab_special", "Special", tL + 180, tTop + 124, 56, 24
   -- a clearly-marked, divided settings block so adjustable values stand out
   makeBar "ui_settings_div", tL + 12, tTop + 156, tWide - 12, tTop + 157, "60,66,80"
   makeLabel "ui_settings_hdr", tL + 12, tTop + 162, tWide - 12, tTop + 182, "PART SETTINGS", 11, "120,220,150", true
   makeField "ui_settings_hint", tL + 12, tTop + 186, tWide - 12, tTop + 250, 11, "150,154,166"
   put tTop + 186 into tRy
   repeat with tI = 1 to kPropRows
      makeField ("ui_prop_lbl_" & tI), tL + 12, tRy + 3, tWide - 92, tRy + 25, 11, "232,236,246"
      makePropBtn ("prop_dec_" & tI), "−", tWide - 84, tRy, 32, 26
      makePropBtn ("prop_inc_" & tI), "+", tWide - 44, tRy, 32, 26
      add 28 to tRy
   end repeat
   add 6 to tRy
   makeBar "ui_options_div", tL + 12, tRy, tWide - 12, tRy + 1, "60,66,80"
   add 8 to tRy
   makeLabel "ui_hdr_OPTIONS", tL + 12, tRy, tWide - 12, tRy + 20, "BUILD OPTIONS", 11, "120,126,140", true
   add 24 to tRy
   makeAction "motor", "Motor", tL + 12, tRy, 74, 26
   makeAction "bouncy", "Bouncy", tL + 92, tRy, 80, 26
   add 32 to tRy
   makeLabel "ui_lbl_speed", tL + 12, tRy + 2, tWide - 92, tRy + 22, "Motor speed", 11, "168,172,184", false
   makeAction "spddn", "−", tWide - 84, tRy, 32, 26
   makeAction "spdup", "+", tWide - 44, tRy, 32, 26
   add 34 to tRy
   makeAction "gravity", "Gravity: Normal", tL + 12, tRy, kInspectorW - 24, 26
   add 32 to tRy
   makeAction "worldfeel", "Feel: Default", tL + 12, tRy, kInspectorW - 24, 26
   add 32 to tRy
   makeAction "pause", "Pause", tL + 12, tRy, 108, 26
   makeAction "step", "Step", tL + 128, tRy, 80, 26
   clearPropRows
   refreshSpeedLabel
   refreshGravityLabel
   refreshWorldFeelLabel
end makeInspector

-- A prominent accent-green +/- button for adjusting a part's settings.
on makePropBtn pId, pLabel, pX, pY, pW, pH
   makeAction pId, pLabel, pX, pY, pW, pH
   setBtnActive ("ui_act_" & pId), kColAccentGreen
   set the textStyle of button ("ui_act_" & pId) to "bold"
end makePropBtn

on refreshSpeedLabel
   if there is a field "ui_lbl_speed" then put "Motor speed: " & gMotorSpeed & "°/s" into field "ui_lbl_speed"
end refreshSpeedLabel

on setSettingsHint pText
   if there is a field "ui_settings_hint" then
      put pText into field "ui_settings_hint"
      set the visible of field "ui_settings_hint" to (pText is not empty)
   end if
end setSettingsHint

on makeStatusBar
   local tWide, tHigh
   put the width of this card into tWide
   put the height of this card into tHigh
   makeBar "ui_statusbar", 0, tHigh - kStatusH, tWide, tHigh, "18,20,26"
   makeField "ui_status", 12, tHigh - kStatusH + 3, tWide - 12, tHigh - 4, 11, "200,206,220"
end makeStatusBar

on makeAction pId, pLabel, pX, pY, pW, pH
   makeButton ("ui_act_" & pId), pLabel, pX, pY, pW, pH
   set the uActId of button ("ui_act_" & pId) to pId
   setBtnIdle ("ui_act_" & pId)
end makeAction

-- Delete the chrome. Collect first, then delete, and only touch *top-level*
-- ui_ controls — deleting the palette group cascades to its grouped buttons.
on clearUI
   local tI, tCtrl, tKill
   put empty into tKill
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      if char 1 to 3 of the short name of tCtrl is "ui_" and word 1 of the owner of tCtrl is "card" \
            then put tCtrl & cr after tKill
   end repeat
   repeat for each line tCtrl in tKill
      if there is a tCtrl then delete tCtrl
   end repeat
end clearUI

on clearSceneControls
   local tI, tName
   repeat with tI = the number of controls of this card down to 1
      put the short name of control tI of this card into tName
      if char 1 to 3 of tName is not "ui_" then delete control tI of this card
   end repeat
end clearSceneControls

-- Keep all chrome above the parts and joint markers. Only raise *top-level* ui_
-- controls (the palette group rises as a unit; raising its members individually
-- would pull them out of the group).
on raiseUI
   local tI, tCtrl, tList
   put empty into tList
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      if char 1 to 3 of the short name of tCtrl is "ui_" and word 1 of the owner of tCtrl is "card" \
            then put tCtrl & cr after tList
   end repeat
   repeat for each line tCtrl in tList
      if there is a tCtrl then set the layer of tCtrl to top
   end repeat
end raiseUI

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

-- Idle / active button styling in one place, so the colours never drift apart and
-- the hover helper can reason about selection state instead of reading pixels.
on setBtnIdle pBtn
   if there is not a button pBtn then exit setBtnIdle
   set the backgroundColor of button pBtn to kColBtnIdle
   set the textColor of button pBtn to kColBtnIdleText
end setBtnIdle

on setBtnActive pBtn, pColor
   if there is not a button pBtn then exit setBtnActive
   set the backgroundColor of button pBtn to pColor
   set the textColor of button pBtn to kColBtnText
end setBtnActive

-- Repaint every palette button. Each category's selected tool lights up in that
-- category's accent colour (Delete stays red); joints use the JOINTS accent.
on highlightAll
   highlightGroup "ui_tool_", kEditTools, gTool, (gJointTool is empty), categoryColor("TOOLS")
   highlightGroup "ui_tool_", kShapeTools, gTool, (gJointTool is empty), categoryColor("SHAPES")
   highlightGroup "ui_tool_", kSpecialTools, gTool, (gJointTool is empty), categoryColor("SPECIAL")
   highlightGroup "ui_tool_", kTerrainTools, gTool, (gJointTool is empty), categoryColor("TERRAIN")
   highlightGroup "ui_tool_", kVehicleTools, gTool, (gJointTool is empty), categoryColor("VEHICLES")
   highlightGroup "ui_joint_", kJointTools, gJointTool, true, categoryColor("JOINTS")
   highlightActions
end highlightAll

-- One palette group's selected/idle styling. The Delete tool flags red when active.
on highlightGroup pPrefix, pItems, pActiveId, pEnabled, pActiveColor
   local tItem, tBtn, tOn
   repeat for each item tItem in pItems
      put pPrefix & tItem into tBtn
      if there is not a button tBtn then next repeat
      put (tItem is pActiveId and pEnabled) into tOn
      if tOn and tItem is "delete" then
         setBtnActive tBtn, kColDanger
      else if tOn then
         setBtnActive tBtn, pActiveColor
      else
         setBtnIdle tBtn
      end if
   end repeat
end highlightGroup

on highlightActions
   local tAccent, tSub
   if there is a button "ui_act_mode" then
      if gMode is "run" then
         set the label of button "ui_act_mode" to "Build"
         setBtnActive "ui_act_mode", kColDanger
      else
         set the label of button "ui_act_mode" to "Run"
         setBtnActive "ui_act_mode", kColAccentGreen
      end if
   end if
   -- A clear, full-width cue for which mode you're in: green accent + neutral
   -- subtitle while building; amber accent + a "running" subtitle while simulating.
   if gMode is "run" then
      put "232,150,60" into tAccent
      put "RUNNING — drag parts to play; press Build or Reset to edit" into tSub
   else
      put kColAccentGreen into tAccent
      put "Contraption Builder — build a machine, then press Run to bring it to life" into tSub
   end if
   if there is a graphic "ui_accent" then set the backgroundColor of graphic "ui_accent" to tAccent
   if there is a field "ui_sub" then set the text of field "ui_sub" to tSub
   setToggle "ui_act_motor", gMotorOn
   setToggle "ui_act_bouncy", gBouncy
end highlightActions

on setToggle pBtn, pOn
   if there is not a button pBtn then exit setToggle
   if pOn then
      setBtnActive pBtn, kColToggleBlue
   else
      setBtnIdle pBtn
   end if
end setToggle

-- =====================================================================
-- Input
-- =====================================================================
on mouseDown
   if "ui_" is in the short name of the target then exit mouseDown
   if b2kWorld() is empty then
      startCB
      exit mouseDown
   end if
   local tx, ty, tHit
   put the mouseH into tx
   put the mouseV into ty
   if gMode is "run" then
      if the shiftKey is down then       -- Shift-click kicks the body under the pointer
         kickPartAt tx, ty
         exit mouseDown
      end if
      get b2kGrab(tx, ty)
      if it is not empty then put "run" into gDragMode
      exit mouseDown
   end if
   -- build mode
   if gJointTool is not empty then
      jointClick tx, ty
      exit mouseDown
   end if
   -- Draw tool: press-drag to sketch a ground line (built on release).
   if gTool is "draw" then
      if inArena(tx, ty) then beginDrawTerrain tx, ty
      exit mouseDown
   end if
   -- Drag tool: a click on a joint marker selects that joint for editing.
   if gTool is "drag" then
      local tJHit
      put jointUnderClick(tx, ty) into tJHit
      if tJHit is not empty then
         selectJoint tJHit
         exit mouseDown
      end if
   end if
   put partUnderClick(tx, ty) into tHit
   if gTool is "delete" then
      if tHit is not empty then
         deletePart tHit
         renderBuild
         updateHud
      end if
      exit mouseDown
   end if
   if gTool is "duplicate" then
      if tHit is not empty then duplicatePart tHit
      exit mouseDown
   end if
   if gTool is "multiply" then
      if tHit is not empty then multiplyPart tHit
      exit mouseDown
   end if
   if gTool is "link" then
      handleLinkClick tHit
      exit mouseDown
   end if
   if tHit is not empty then
      put tHit into gDragCtrl
      put "build" into gDragMode
      put false into gDragMoved
      selectPart tHit
   else
      if gTool is not "drag" and inArena(tx, ty) then
         put placePart(tx, ty) into gDragCtrl   -- drop it, then let the user drag it
         if gDragCtrl is not empty then
            put "build" into gDragMode
            put false into gDragMoved
         end if
      else
         deselectPart                           -- clicked empty space; clear selection
      end if
   end if
end mouseDown

on mouseMove pX, pY
   if gDragMode is "draw" then
      extendDrawTerrain pX, pY
      exit mouseMove
   end if
   if gDragMode is "build" and gDragCtrl is not empty then
      local tCx, tCy, tOld, tDx, tDy, tGroup, tP
      put max(gArenaL, min(gArenaR, pX)) into tCx
      put max(gArenaT, min(gArenaB, pY)) into tCy
      if the uKind of gDragCtrl is "laser" then       -- drag a laser by its emitter, not the beam midpoint
         set the points of gDragCtrl to round(tCx) & "," & round(tCy) & cr & (line 2 of the points of gDragCtrl)
         drawLaserBeam gDragCtrl
         put true into gDragMoved
         exit mouseMove
      end if
      put the loc of gDragCtrl into tOld
      put round(tCx) - item 1 of tOld into tDx       -- how far the grabbed part moved
      put round(tCy) - item 2 of tOld into tDy
      set the loc of gDragCtrl to round(tCx) & "," & round(tCy)
      -- a grouped assembly (e.g. a car) moves as one: shift its other parts too
      put the uGroup of gDragCtrl into tGroup
      if tGroup is not empty then
         repeat for each line tP in gParts
            if tP is empty or tP is gDragCtrl then next repeat
            if the uGroup of tP is tGroup then
               set the loc of tP to (item 1 of the loc of tP + tDx) & "," & (item 2 of the loc of tP + tDy)
            end if
         end repeat
      end if
      put true into gDragMoved
      renderJoints
   end if
end mouseMove

on mouseUp
   if "ui_" is in the short name of the target then
      handleUiClick
      exit mouseUp
   end if
   if gDragMode is "draw" then
      finishDrawTerrain
      put empty into gDragMode
      exit mouseUp
   end if
   if gDragMode is "build" and gDragCtrl is not empty and gDragMoved then
      local tGroup, tP
      reseatDragged gDragCtrl
      put the uGroup of gDragCtrl into tGroup
      if tGroup is not empty then
         repeat for each line tP in gParts
            if tP is not empty and tP is not gDragCtrl and the uGroup of tP is tGroup then reseatDragged tP
         end repeat
      end if
      renderBuild
   end if
   if gDragMode is "run" then b2kRelease
   put empty into gDragCtrl
   put empty into gDragMode
end mouseUp

-- Re-seat a dragged part's body where its graphic was dropped (angle preserved).
on reseatDragged pCtrl
   if pCtrl is empty or not kindHasBody(the uKind of pCtrl) then exit reseatDragged
   local tLoc
   put the loc of pCtrl into tLoc
   b2kMoveTo pCtrl, item 1 of tLoc, item 2 of tLoc, b2kAngle(pCtrl)
end reseatDragged

on mouseRelease
   if gDragMode is "run" then b2kRelease
   put empty into gDragCtrl
   put empty into gDragMode
end mouseRelease

-- Shift-click during Run kicks the dynamic body under the pointer: a sharp,
-- mass-aware upward impulse with a little sideways scatter, plus a tumble. Shows
-- off the one-shot b2kImpulse / b2kAngularImpulse force handlers.
on kickPartAt pX, pY
   local tHit
   put b2kControlAt(pX, pY) into tHit
   if tHit is empty then exit kickPartAt
   if b2kBodyType(tHit) is not "dynamic" then exit kickPartAt
   b2kImpulse tHit, (random(401) - 200), -380       -- up, with random horizontal scatter
   b2kAngularImpulse tHit, (random(481) - 240)       -- a tumble either way
   put "Kicked it! Shift-click any moving part during Run to bat it around." into gStatus
   updateHud
end kickPartAt

on handleUiClick
   local tName, tId
   put the short name of the target into tName
   if tName is "ui_recipescrim" then
      hideRecipesMenu
      exit handleUiClick
   end if
   if tName is "ui_filterscrim" then
      hideFilterPanel
      exit handleUiClick
   end if
   if tName is "ui_worldscrim" then
      hideWorldPanel
      exit handleUiClick
   end if
   -- Click a settings value to type an exact number (steppers stay on the +/- keys).
   if "ui_prop_lbl_" is in tName then
      editPropValue (the uPropKey of the target)
      exit handleUiClick
   end if
   -- Click a palette section header to collapse / expand it (pure chrome, no selection).
   if "ui_hdr_" is in tName then
      togglePaletteSection (the uHdr of the target)
      exit handleUiClick
   end if
   -- Picking a build tool while the simulation runs drops you back into Build.
   if ("ui_tool_" is in tName or "ui_joint_" is in tName) and gMode is "run" then toggleMode
   if "ui_tool_" is in tName then
      put the uToolId of the target into gTool
      put empty into gJointTool
      resetPend
      deselectPart
      deselectJoint
      put "Tool: " & friendlyKind(gTool) into gStatus
      showInspectorForTool
   else if "ui_joint_" is in tName then
      put the uJointId of the target into gJointTool
      resetPend
      deselectPart
      deselectJoint
      put "Joint: " & gJointTool & " — click part A, then part B." into gStatus
      showInspectorForTool
   else if "ui_act_" is in tName then
      put the uActId of the target into tId
      handleAction tId
   end if
   highlightAll
   updateHud
end handleUiClick

on handleAction pId
   if char 1 to 5 of pId is "prop_" then
      adjustProp pId
      exit handleAction
   end if
   if char 1 to 4 of pId is "tab_" then
      selectInspTab (char 5 to -1 of pId)
      exit handleAction
   end if
   if char 1 to 5 of pId is "filt_" then
      handleFilterToggle pId
      exit handleAction
   end if
   if char 1 to 5 of pId is "wopt_" then
      handleWorldToggle pId
      exit handleAction
   end if
   switch pId
      case "mode"
         toggleMode
         break
      case "reset"
         resetMachine
         break
      case "clear"
         clearAll
         break
      case "save"
         saveContraption
         break
      case "load"
         loadContraption
         break
      case "motor"
         put not gMotorOn into gMotorOn
         if gMotorOn then put "Motor ON for new Hinge/Wheel joints (" & gMotorSpeed & " deg/sec)." into gStatus
         else put "Motor OFF." into gStatus
         break
      case "bouncy"
         put not gBouncy into gBouncy
         if gBouncy then put "Bouncy material ON for new parts." into gStatus
         else put "Bouncy material OFF." into gStatus
         break
      case "spddn"
         put max(kMotorMin, gMotorSpeed - 30) into gMotorSpeed
         put "Motor speed: " & gMotorSpeed & " deg/sec." into gStatus
         refreshSpeedLabel
         break
      case "spdup"
         put min(kMotorMax, gMotorSpeed + 30) into gMotorSpeed
         put "Motor speed: " & gMotorSpeed & " deg/sec." into gStatus
         refreshSpeedLabel
         break
      case "gravity"
         cycleGravity
         break
      case "worldfeel"
         cycleWorldFeel
         break
      case "pause"
         togglePause
         break
      case "step"
         stepOnce
         break
      case "recipes"
         toggleRecipesMenu
         break
      case "info"
         startOnboarding
         break
      case "recipeclose"
         hideRecipesMenu
         break
      case "filterclose"
         hideFilterPanel
         break
      case "rename"
         renamePart gSelPart
         break
      case "worldadv"
         openWorldPanel
         break
      case "worldclose"
         hideWorldPanel
         break
      case "cart"
         hideRecipesMenu
         buildSampleCart
         break
      case "swing"
         hideRecipesMenu
         buildSampleSwing
         break
      case "balloonlift"
         hideRecipesMenu
         buildRecipeBalloonLift
         break
      case "platebomb"
         hideRecipesMenu
         buildRecipePlateBomb
         break
      case "fantower"
         hideRecipesMenu
         buildRecipeFanTower
         break
      case "magnetcatch"
         hideRecipesMenu
         buildRecipeMagnetCatch
         break
      case "catapult"
         hideRecipesMenu
         buildRecipeCatapult
         break
      case "cannon"
         hideRecipesMenu
         buildRecipeCannon
         break
      case "trebuchet"
         hideRecipesMenu
         buildRecipeTrebuchet
         break
      case "crane"
         hideRecipesMenu
         buildRecipeCrane
         break
      case "wreckingball"
         hideRecipesMenu
         buildRecipeWreckingBall
         break
      case "cradle"
         hideRecipesMenu
         buildRecipeCradle
         break
      case "dominoes"
         hideRecipesMenu
         buildRecipeDominoes
         break
      case "terrainrun"
         hideRecipesMenu
         buildRecipeTerrainRun
         break
      case "stress"
         hideRecipesMenu
         stressTest
         break
      case "onbnext"
         onboardingNext
         break
      case "onbskip"
         dismissOnboarding
         break
   end switch
end handleAction

on toggleMode
   if gMode is "build" then
      put serializeText() into gPreRun   -- remember the layout so Reset can restore it
      put "run" into gMode
      put empty into gJointTool
      resetPend
      deselectJoint
      put true into gMotorsRunning
      put empty into gSensorCount   -- every sensor zone starts empty each Run
      deleteByPrefix "cb_wire_"     -- wires are a build-time authoring aid; hide them during Run
      armFuses
      armThrusters
      b2kStart                      -- fresh loop: gravity, motors, mouse drag
      applyWorldFeel                -- re-apply the world-tuning preset to the live world
      applyWorldOptions             -- and the advanced solver toggles (CCD, sleeping, substeps…)
      armMotors                     -- re-establish each joint's designed motor state
      armLaunches                   -- fire each part's initial push/spin
      put "Run — gravity & motors live. Drag bodies; Shift-click to kick." into gStatus
   else
      put "build" into gMode
      put empty into gFps
      b2kStop                       -- freeze the loop; parts hold their place
      renderBuild
      put "Build mode — arrange parts and connect joints, then press Run." into gStatus
   end if
   highlightAll
   refreshPauseLabel
end toggleMode

-- The part under a click: prefer the actual control clicked, then fall back to
-- the physics point query (reliable even for thin static anchors).
function partUnderClick pX, pY
   local tT
   put the long id of the target into tT
   if tT is among the lines of gParts then return tT
   return b2kControlAt(pX, pY)
end partUnderClick

-- The part under a point, ignoring one part (so overlapping parts connect).
function otherPartAt pX, pY, pExclude
   local tHit
   put b2kControlAt(pX, pY) into tHit
   if tHit is pExclude and pExclude is not empty then
      b2kDisable pExclude               -- hide A, re-query for the part beneath it
      put b2kControlAt(pX, pY) into tHit
      b2kEnable pExclude
   end if
   return tHit
end otherPartAt

-- True when a screen point is inside the play field (keeps parts off the chrome).
function inArena pX, pY
   return pX >= gArenaL and pX <= gArenaR and pY >= gArenaT and pY <= gArenaB
end inArena

-- =====================================================================
-- Placing parts
-- =====================================================================
function placePart pX, pY
   local tCtrl
   put empty into tCtrl
   switch gTool
      case "box"
         put placeBox(pX, pY, rnd(kBoxMin, kBoxMax), rnd(kBoxMin, kBoxMax), randomColor()) into tCtrl
         break
      case "ball"
         put placeBall(pX, pY, rnd(kBallMin, kBallMax), randomColor()) into tCtrl
         break
      case "capsule"
         put placeCapsule(pX, pY, rnd(kCapLenMin, kCapLenMax), kCapThick, randomColor()) into tCtrl
         break
      case "poly"
         put placePoly(pX, pY, rnd(kPolyMin, kPolyMax), randomColor()) into tCtrl
         break
      case "anchor"
         put placeAnchor(pX, pY) into tCtrl
         break
      case "platform"
      case "ramp"
      case "hill"
         put placeTerrain(gTool, pX, pY) into tCtrl
         break
      case "car"
         put placeVehicle(pX, pY) into tCtrl
         break
      case "image"
         put importImage(pX, pY) into tCtrl
         break
      case "balloon"
         put placeBalloon(pX, pY) into tCtrl
         break
      case "bomb"
         put placeBomb(pX, pY) into tCtrl
         break
      case "plate"
         put placePlate(pX, pY) into tCtrl
         break
      case "sensor"
         put placeSensor(pX, pY) into tCtrl
         break
      case "fan"
         put placeFan(pX, pY) into tCtrl
         break
      case "magnet"
         put placeMagnet(pX, pY) into tCtrl
         break
      case "laser"
         put placeLaser(pX, pY) into tCtrl
         break
      case "thruster"
         put placeThruster(pX, pY) into tCtrl
         break
      default
         return empty
   end switch
   if tCtrl is not empty then
      renderBuild                   -- draw the new part right away (no Run needed)
      put "Placed a " & friendlyKind(gTool) & ". Drag to move it; the inspector on the right explains it." into gStatus
      selectPart tCtrl
      updateHud
   end if
   return tCtrl
end placePart

function placeBox pX, pY, pW, pH, pColor
   local tCtrl
   b2kSpawnBox pX, pY, pW, pH, pColor
   put the result into tCtrl
   tagPart tCtrl, "box", pColor, empty
   return tCtrl
end placeBox

function placeBall pX, pY, pDiam, pColor
   local tCtrl
   b2kSpawnBall pX, pY, pDiam, pColor
   put the result into tCtrl
   tagPart tCtrl, "ball", pColor, empty
   return tCtrl
end placeBall

function placeCapsule pX, pY, pLen, pThick, pColor
   local tCtrl
   b2kSpawnCapsule pX, pY, pLen, pThick, pColor
   put the result into tCtrl
   tagPart tCtrl, "capsule", pColor, empty
   return tCtrl
end placeCapsule

function placePoly pX, pY, pR, pColor
   local tName, tRef, tI, tAng, tPoints
   put "cb_poly_" & the milliseconds & "_" & random(99999) into tName
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
   tagPart tRef, "poly", pColor, empty
   return tRef
end placePoly

function placeAnchor pX, pY
   local tName, tRef
   put "cb_anchor_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the backgroundColor of tRef to "120,126,140"
   set the foregroundColor of tRef to "210,214,224"
   set the lineSize of tRef to 2
   set the width of tRef to 26
   set the height of tRef to 26
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddStatic tRef
   tagPart tRef, "anchor", "120,126,140", empty
   return tRef
end placeAnchor

-- =====================================================================
-- Terrain: static scenery the dynamic parts rest on, roll down and bump
-- into. Each piece is a convex polygon graphic attached as a *static*
-- polygon body, so the Kit's sync skips it (it never moves) and we draw it
-- once. Rotation is baked into the points (the body angle stays 0), so a
-- ramp can tilt without the per-frame redraw a static body never receives.
-- =====================================================================

-- The static scenery kinds, handled together wherever they differ from parts.
function kindIsTerrain pKind
   return pKind is among the items of "platform,ramp,hill"
end kindIsTerrain

-- Default unrotated size for a fresh terrain piece, as "w,h" in pixels.
function terrainDefault pKind
   switch pKind
      case "ramp"
         return "130,82"
      case "hill"
         return "172,84"
   end switch
   return "150,26"                            -- platform: a wide, shallow ledge
end terrainDefault

-- A terrain piece's earthy default fill colour.
function terrainColor pKind
   switch pKind
      case "ramp"
         return "150,120,84"                  -- packed dirt
      case "hill"
         return "96,132,86"                   -- grassy mound
   end switch
   return "108,116,128"                       -- platform: stone
end terrainColor

-- Screen-space points for a terrain outline: the canonical shape scaled to
-- pW x pH with its bounding box centred on (pCx,pCy), optionally mirrored
-- left↔right (pFlip, for ramps facing the other way), then rotated pAngleDeg
-- about the centre. Convex and <= 8 verts, so b2kAddPolygon accepts it.
function terrainPoints pKind, pCx, pCy, pW, pH, pAngleDeg, pFlip
   local tHw, tHh, tBase, tPt, tx, ty, tC, tS, tA, tRot
   local tBumps, tNh, tIh, tT, tEnv, tBump, tHx, tHy, tYBase
   set the itemDelimiter to comma                -- we parse "x,y" points below
   put pW / 2 into tHw
   put pH / 2 into tHh
   if pFlip is true then put - tHw into tHw      -- mirror about the centre (ramps)
   switch pKind
      case "ramp"
         -- right triangle: flat base, upright high edge, slope rising to one side
         put (pCx - tHw) & "," & (pCy + tHh) & cr & (pCx + tHw) & "," & (pCy + tHh) \
               & cr & (pCx + tHw) & "," & (pCy - tHh) into tBase
         break
      case "hill"
         -- Rolling ground: a flat base with an undulating top. The bump count
         -- grows with width, so a narrow hill is a single dome and a wide one
         -- rolls. placeTerrain turns this outline into a smooth chain, so a fast
         -- body rides over the bumps without catching on any seam.
         put max(1, round(pW / 200)) into tBumps
         put 6 * (tBumps + 1) into tNh                       -- top samples
         put pCy + tHh into tYBase
         -- order base-left, top LEFT→RIGHT, base-right: as a closed chain loop
         -- this puts the solid side below the surface (Box2D: solid = right of
         -- the travel direction), so bodies rest ON the hill rather than fall through.
         put (pCx - tHw) & "," & tYBase into tBase           -- base-left
         repeat with tIh = 1 to tNh - 1                      -- interior top points, left → right
            put tIh / tNh into tT
            put sin(tT * kPI) into tEnv                       -- 0 at the ends → meets the base
            put 0.62 + 0.38 * (0.5 - 0.5 * cos(tT * tBumps * 2 * kPI)) into tBump
            put pCx - tHw + tT * pW into tHx
            put tYBase - pH * tEnv * tBump into tHy
            put cr & round(tHx) & "," & round(tHy) after tBase
         end repeat
         put cr & (pCx + tHw) & "," & tYBase after tBase     -- base-right (loop closes to base-left)
         put reversedLines(tBase) into tBase                 -- wind so the chain's solid side faces OUT (bodies rest on top)
         break
      default
         -- platform: an axis-aligned rectangle
         put (pCx - tHw) & "," & (pCy - tHh) & cr & (pCx + tHw) & "," & (pCy - tHh) & cr \
               & (pCx + tHw) & "," & (pCy + tHh) & cr & (pCx - tHw) & "," & (pCy + tHh) into tBase
   end switch
   put ((round(pAngleDeg) mod 360) + 360) mod 360 into tA
   if tA is 0 then return tBase
   put cos(tA * kPI / 180) into tC
   put sin(tA * kPI / 180) into tS
   put empty into tRot
   repeat for each line tPt in tBase
      put (item 1 of tPt) - pCx into tx
      put (item 2 of tPt) - pCy into ty
      put round(pCx + tx * tC - ty * tS) & "," & round(pCy + tx * tS + ty * tC) & cr after tRot
   end repeat
   delete the last char of tRot
   return tRot
end terrainPoints

-- Place a terrain piece: a static polygon body the user can size, rotate and
-- drag like any part. pW/pH default per kind; Load passes the saved size.
function placeTerrain pKind, pX, pY, pW, pH
   local tName, tRef, tWH, tColor
   set the itemDelimiter to comma
   put terrainDefault(pKind) into tWH
   if pW is empty or pW < 1 then put item 1 of tWH into pW
   if pH is empty or pH < 1 then put item 2 of tWH into pH
   put terrainColor(pKind) into tColor
   put "cb_terrain_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the backgroundColor of tRef to tColor
   set the foregroundColor of tRef to "20,20,24"
   set the lineSize of tRef to 2                 -- a bolder edge reads as solid ground
   set the points of tRef to terrainPoints(pKind, round(pX), round(pY), pW, pH, 0, false)
   set the loc of tRef to round(pX) & "," & round(pY)
   if pKind is "hill" then b2kAddChain tRef, the points of tRef, true   -- smooth rolling ground
   else b2kAddPolygon tRef, false                                       -- convex: never falls, never syncs
   tagPart tRef, pKind, tColor, empty
   set the uW of tRef to pW
   set the uH of tRef to pH
   set the uAngle of tRef to 0
   set the uFlip of tRef to false
   set the uFriction of tRef to 0.6           -- terrain grips by default
   b2kSetFriction tRef, 0.6
   return tRef
end placeTerrain

-- Rebuild a terrain piece's outline + static collision shape from its current
-- size and angle. Called on every resize/rotate; the body origin stays put.
on regenTerrain pCtrl
   if pCtrl is empty then exit regenTerrain
   local tCx, tCy
   put item 1 of the loc of pCtrl into tCx
   put item 2 of the loc of pCtrl into tCy
   set the points of pCtrl to terrainPoints(the uKind of pCtrl, tCx, tCy, \
         numOr(the uW of pCtrl, 120), numOr(the uH of pCtrl, 26), numOr(the uAngle of pCtrl, 0), \
         (the uFlip of pCtrl is true))
   set the loc of pCtrl to tCx & "," & tCy     -- keep centred on the body origin
   if the uKind of pCtrl is "hill" then
      rebuildHillChain pCtrl                    -- smooth hills use a chain, not a polygon shape
   else
      b2kReshape pCtrl, "poly"
      reapplyMaterial pCtrl
   end if
end regenTerrain

-- Rebuild a hill's smooth static chain from its current outline (the polygon
-- shape path can't represent the rolling, concave profile). Drops the old chain
-- body and re-attaches one to the same graphic, so the part keeps its identity.
on rebuildHillChain pCtrl
   if b2kBodyOf(pCtrl) is not empty then b2kRemove pCtrl   -- destroy old chain body; graphic stays (not kit-spawned)
   b2kAddChain pCtrl, the points of pCtrl, true
end rebuildHillChain

-- =====================================================================
-- Freehand "Draw" terrain: press-drag to sketch a ground line; on release it
-- becomes a smooth ONE-SIDED chain (b2kAddChain, open) bodies rest on top of.
-- =====================================================================
on beginDrawTerrain pX, pY
   set the itemDelimiter to comma
   put "draw" into gDragMode
   -- Clamp the first vertex to the arena, exactly like extendDrawTerrain — a draw
   -- that begins off the play area must not seed an out-of-bounds point.
   put max(gArenaL, min(gArenaR, pX)) into pX
   put max(gArenaT, min(gArenaB, pY)) into pY
   put round(pX) & "," & round(pY) into gDrawPts
   put "cb_terrain_" & the milliseconds & "_" & random(99999) into gDrawCtrl
   create graphic gDrawCtrl
   put the long id of graphic gDrawCtrl into gDrawCtrl
   set the style of gDrawCtrl to "line"
   set the lineSize of gDrawCtrl to kDrawLineSize
   set the foregroundColor of gDrawCtrl to "150,120,84"
   set the points of gDrawCtrl to gDrawPts
   put "Draw the ground — release to set it." into gStatus
end beginDrawTerrain

on extendDrawTerrain pX, pY
   if gDrawCtrl is empty then exit extendDrawTerrain
   set the itemDelimiter to comma
   local tx, ty, tLast
   put max(gArenaL, min(gArenaR, pX)) into tx
   put max(gArenaT, min(gArenaB, pY)) into ty
   put the last line of gDrawPts into tLast
   if tLast is not empty and (abs(tx - item 1 of tLast) + abs(ty - item 2 of tLast)) < kDrawStep then exit extendDrawTerrain
   put cr & round(tx) & "," & round(ty) after gDrawPts
   set the points of gDrawCtrl to gDrawPts
end extendDrawTerrain

on finishDrawTerrain
   if gDrawCtrl is empty then exit finishDrawTerrain
   set the itemDelimiter to comma
   local tPts
   put gDrawPts into tPts
   if the number of lines of tPts < 2 then        -- a click, not a drag: nothing to build
      try
         delete gDrawCtrl
      end try
      put empty into gDrawCtrl
      put empty into gDrawPts
      put "Press and drag to draw a ground line." into gStatus
      exit finishDrawTerrain
   end if
   -- Normalise the contour left→right, then build a CLOSED, filled ground mass:
   -- the drawn surface on top, straight down to the arena floor. The top is laid
   -- right→left so the chain's solid side faces up (Box2D: solid = right of the
   -- travel direction), matching the smoke test's ground chain — bodies rest on it.
   local tShape, tFloor, tFirstX, tLastX
   if (item 1 of the last line of tPts) < (item 1 of line 1 of tPts) then put reversedLines(tPts) into tPts
   put item 1 of line 1 of tPts into tFirstX
   put item 1 of the last line of tPts into tLastX
   put gArenaB into tFloor
   put tLastX & "," & tFloor & cr & reversedLines(tPts) & cr & tFirstX & "," & tFloor into tShape
   set the style of gDrawCtrl to "polygon"
   set the filled of gDrawCtrl to true
   set the backgroundColor of gDrawCtrl to "120,96,60"
   set the foregroundColor of gDrawCtrl to "70,56,36"
   set the lineSize of gDrawCtrl to 2
   set the points of gDrawCtrl to tShape
   tagPart gDrawCtrl, "draw", "120,96,60", empty
   set the uFriction of gDrawCtrl to 0.6
   b2kAddChain gDrawCtrl, tShape, true            -- closed loop = a solid ground mass
   selectPart gDrawCtrl
   put "Ground drawn. Press Run to test it." into gStatus
   put empty into gDrawCtrl
   put empty into gDrawPts
   updateHud
end finishDrawTerrain

-- A placeholder line graphic for a saved drawn-terrain part; applyPartSpecial
-- fills in its points and chain from the saved point list.
function placeDrawPlaceholder pX, pY
   local tName, tRef
   put "cb_terrain_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the backgroundColor of tRef to "120,96,60"
   set the foregroundColor of tRef to "70,56,36"
   set the lineSize of tRef to 2
   set the loc of tRef to round(pX) & "," & round(pY)
   tagPart tRef, "draw", "120,96,60", empty
   return tRef
end placeDrawPlaceholder

-- Reverse the order of a CR-list of points.
function reversedLines pList
   local tL, tOut
   put empty into tOut
   repeat for each line tL in pList
      if tL is not empty then put tL & cr before tOut
   end repeat
   if tOut is not empty then delete the last char of tOut
   return tOut
end reversedLines

-- A drawn terrain's points packed into one save column (CR -> "|", since ";"
-- and TAB are taken by the save format).
function ptsPacked pCtrl
   local tP
   put the points of pCtrl into tP     -- current points, so a dragged terrain saves where it sits
   filter tP without empty             -- drop any trailing blank line
   replace cr with "|" in tP           -- ";" and TAB are taken by the save format
   return tP
end ptsPacked

-- =====================================================================
-- Vehicle: a ready-made car you drop in like any object — a chassis on two
-- sprung, motorised wheels. All three parts share a uGroup tag so dragging one
-- moves the whole car, and the wheel joints/motors save, load and reset normally.
-- =====================================================================
function placeVehicle pX, pY
   local tGid, tChassis, tWB, tWF, tCW, tCH, tWheel, tDx, tDy, tSpeed, tW
   put "veh" & the milliseconds & "_" & random(99999) into tGid
   put 152 into tCW                           -- chassis width
   put 34 into tCH                            -- chassis height
   put 48 into tWheel                         -- wheel diameter
   put round(tCW * 0.31) into tDx             -- wheel offset from centre (x)
   put round(tCH * 0.9) into tDy              -- wheel sits just below the chassis
   put max(160, gMotorSpeed) into tSpeed      -- a lively default drive speed
   -- chassis: a light body keeps the centre of mass low for a stable ride
   put placeBox(pX, pY, tCW, tCH, "212,84,72") into tChassis
   set the uDensity of tChassis to 0.7
   b2kSetDensity tChassis, 0.7
   set the uBounce of tChassis to 0
   b2kSetBounce tChassis, 0
   set the uGroup of tChassis to tGid
   -- two grippy wheels
   put placeBall(pX - tDx, pY + tDy, tWheel, "40,42,50") into tWB
   put placeBall(pX + tDx, pY + tDy, tWheel, "40,42,50") into tWF
   repeat for each line tW in (tWB & cr & tWF)
      set the uFriction of tW to 1
      b2kSetFriction tW, 1
      set the uDensity of tW to 1
      b2kSetDensity tW, 1
      set the uBounce of tW to 0
      b2kSetBounce tW, 0
      set the uGroup of tW to tGid
   end repeat
   -- sprung, motorised wheel joints (connectJoint adds the suspension + motor)
   get connectJoint("wheel", tChassis, tWB, item 1 of the loc of tWB, item 2 of the loc of tWB, tSpeed)
   get connectJoint("wheel", tChassis, tWF, item 1 of the loc of tWF, item 2 of the loc of tWF, tSpeed)
   return tChassis
end placeVehicle

-- Tag a part with the data save/load needs, register it, apply the material.
on tagPart pCtrl, pKind, pColor, pFile
   if pCtrl is empty then exit tagPart
   set the uPartId of pCtrl to gNextPid
   add 1 to gNameCount[pKind]
   set the uPartName of pCtrl to niceName(pKind) && gNameCount[pKind]   -- auto-name; user-renamable in the inspector
   set the uKind of pCtrl to pKind
   set the uColor of pCtrl to pColor
   set the uFile of pCtrl to pFile
   set the uW of pCtrl to the width of pCtrl       -- design size (the graphic rect inflates when rotated)
   set the uH of pCtrl to the height of pCtrl
   add 1 to gNextPid
   put pCtrl & cr after gParts
   put true into gDynDirty               -- the dynamic-part cache must be rebuilt
   registerKind pCtrl, pKind
   if gBouncy and kindIsDynamic(pKind) then
      b2kSetBounce pCtrl, kBounceOn
      set the uBounce of pCtrl to kBounceOn
   else
      set the uBounce of pCtrl to 0
   end if
   if kindHasBody(pKind) then
      set the uFriction of pCtrl to 0.4
      if kindIsDynamic(pKind) then set the uBodyType of pCtrl to "dynamic"
      else set the uBodyType of pCtrl to "static"
   end if
   if kindIsDynamic(pKind) then
      set the uDensity of pCtrl to 1
      set the uGravity of pCtrl to 1
      set the uFixedRot of pCtrl to false
      set the layerMode of pCtrl to "dynamic"   -- moving bodies composite on their own GPU layer (no smear/clip artifacts)
      b2kWake pCtrl                       -- so the first sync draws it
   end if
end tagPart

-- Whether a kind moves under gravity (so it gets bounce, waking, field forces).
function kindIsDynamic pKind
   return pKind is among the items of "box,ball,capsule,poly,image,balloon,bomb,thruster"
end kindIsDynamic

-- Fans and magnets are GUI-only influence zones with no physics body.
function kindHasBody pKind
   return pKind is not "fan" and pKind is not "magnet" and pKind is not "laser"
end kindHasBody

-- Friendly singular name for status messages.
function friendlyKind pKind
   switch pKind
      case "plate"
         return "pressure plate"
      case "balloon"
         return "helium balloon"
      default
         return pKind
   end switch
end friendlyKind

-- Add a freshly tagged part to its per-kind list (for fast per-frame iteration).
on registerKind pCtrl, pKind
   if pKind is among the items of "balloon,bomb,plate,fan,magnet,sensor,laser,thruster" then
      put pCtrl & cr after gKindList[pKind]
   end if
   if pKind is "plate" then
      put 0 into gPlateLoad[pCtrl]
      put "up" into gPlateState[pCtrl]
   end if
   if pKind is "sensor" then put 0 into gSensorCount[pCtrl]
end registerKind

-- Drop a deleted part from any per-kind list it belonged to.
on unregisterKind pCtrl
   local tKind, tP, tNew
   repeat for each item tKind in "balloon,bomb,plate,fan,magnet,sensor,laser,thruster"
      if pCtrl is not in gKindList[tKind] then next repeat
      put empty into tNew
      repeat for each line tP in gKindList[tKind]
         if tP is not empty and tP is not pCtrl then put tP & cr after tNew
      end repeat
      put tNew into gKindList[tKind]
   end repeat
   if pCtrl is among the keys of gPlateLoad then delete variable gPlateLoad[pCtrl]
   if pCtrl is among the keys of gPlateState then delete variable gPlateState[pCtrl]
   if pCtrl is among the keys of gSensorCount then delete variable gSensorCount[pCtrl]
end unregisterKind

-- The dynamic (gravity-affected) parts, cached and rebuilt only when parts change.
function dynamicParts
   if not gDynDirty then return gDynParts
   local tP, tList
   put empty into tList
   repeat for each line tP in gParts
      if tP is empty then next repeat
      if kindIsDynamic(the uKind of tP) then put tP & cr after tList
   end repeat
   put tList into gDynParts
   put false into gDynDirty
   return gDynParts
end dynamicParts

-- Pick an image file and drop it in as a dynamic body (it rotates via `the angle`).
function importImage pX, pY
   local tFile, tName, tRef, tW, tH, tScale
   answer file "Choose an image (PNG or JPG):" with type "Images|png,jpg,jpeg,gif"
   put it into tFile
   if tFile is empty or the result is "cancel" then
      put "Image import cancelled." into gStatus
      updateHud
      return empty
   end if
   if there is no file tFile then
      put "Could not find that image file." into gStatus
      updateHud
      return empty
   end if
   put "cb_img_" & the milliseconds & "_" & random(99999) into tName
   create image tName
   put the long id of image tName into tRef
   local tErr
   try
      set the filename of tRef to tFile
   catch tErr
      delete tRef
      put "Could not load that image." into gStatus
      updateHud
      return empty
   end try
   put the formattedWidth of tRef into tW
   put the formattedHeight of tRef into tH
   if tW < 1 or tH < 1 then
      delete tRef
      put "That image could not be read (it may be empty or corrupt)." into gStatus
      updateHud
      return empty
   end if
   put kImageMax / max(tW, tH) into tScale
   if tScale > 1 then put 1 into tScale
   set the width of tRef to max(8, round(tW * tScale))
   set the height of tRef to max(8, round(tH * tScale))
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddBox tRef
   tagPart tRef, "image", empty, tFile
   put "Image placed — it tumbles and rotates when you press Run." into gStatus
   updateHud
   return tRef
end importImage

-- =====================================================================
-- Joints (two-click: part A, then part B)
-- =====================================================================
on jointClick pX, pY
   local tHit
   if gPendCtrl is empty then
      put partUnderClick(pX, pY) into tHit
      if tHit is empty then
         put "Click part A first to start the " & gJointTool & " joint." into gStatus
         updateHud
         exit jointClick
      end if
      put tHit into gPendCtrl
      put pX into gPendX
      put pY into gPendY
      flashSelect tHit
      put "Part A set. Now click part B" & jointBHint() into gStatus
      updateHud
      exit jointClick
   end if
   -- second click: the part under the cursor, ignoring A (so overlaps work)
   put otherPartAt(pX, pY, gPendCtrl) into tHit
   if tHit is empty and gJointTool is not "hinge" and gJointTool is not "bridge" and gJointTool is not "chain" then
      put "Part B must be a part for a " & gJointTool & " joint (Hinge, Bridge and Chain can pin to the world)." into gStatus
      resetPend
      updateHud
      exit jointClick
   end if
   makeJoint gJointTool, gPendCtrl, tHit, pX, pY
   resetPend
end jointClick

function jointBHint
   if gJointTool is "hinge" or gJointTool is "bridge" or gJointTool is "chain" then return " (or empty space to anchor to the world)."
   return "."
end jointBHint

on resetPend
   if gPendCtrl is not empty then unflashSelect gPendCtrl
   put empty into gPendCtrl
   put empty into gPendX
   put empty into gPendY
end resetPend

on flashSelect pCtrl
   if pCtrl is empty then exit flashSelect
   try
      set the foregroundColor of pCtrl to "255,255,255"
      set the lineSize of pCtrl to 3
   end try
end flashSelect

on unflashSelect pCtrl
   if pCtrl is empty then exit unflashSelect
   try
      set the foregroundColor of pCtrl to "20,20,24"
      set the lineSize of pCtrl to 1
   end try
end unflashSelect

-- Interactive joint: build it, then add the motor if the Motor toggle is on.
on makeJoint pKind, pA, pB, pX, pY
   if pKind is "bridge" or pKind is "chain" then
      buildSpan pKind, pA, pB, pX, pY
      renderBuild
      updateHud
      exit makeJoint
   end if
   local tMotor
   put 0 into tMotor
   if gMotorOn and (pKind is "hinge" or pKind is "wheel") then put gMotorSpeed into tMotor
   if connectJoint(pKind, pA, pB, pX, pY, tMotor) then
      put "Connected with a " & pKind & " joint. Press Run to test it." into gStatus
      if tMotor > 0 and pKind is "hinge" and pB is not empty \
            and b2kBodyType(pA) is not "static" and b2kBodyType(pB) is not "static" then
         put " Tip: pin one side to an Anchor or the world for a steady spin." after gStatus
      end if
   else
      put "Could not create that joint — try different parts or positions." into gStatus
   end if
   renderJoints
   updateHud
end makeJoint

-- Build a span of hinged segments from the first click point to the second, in
-- the demo's bridge style: a "bridge" is stiff planks, a "chain" is a draping
-- rope of small links. Each segment is a normal part and each link an exact-pivot
-- "pin" joint, so the whole span renders, saves/loads and deletes like anything else.
on buildSpan pKind, pA, pB, pEx, pEy
   local tSx, tSy, tD, tN, tHt, tColor, tDens, tPinKind, tPts, tNpts
   local tI, tJx0, tJy0, tJx1, tJy1, tCx, tCy, tLen, tAng, tSeg, tPrev
   local tAx, tAy, tHalf, tT
   put gPendX into tSx
   put gPendY into tSy
   put sqrt((pEx - tSx) ^ 2 + (pEy - tSy) ^ 2) into tD
   if tD < 50 then
      put "That span is too short — click two points further apart." into gStatus
      exit buildSpan
   end if
   set the itemDelimiter to comma
   -- Build the list of pin points first, then place one equal-length link between
   -- each consecutive pair. A bridge is a straight run of planks; a chain is a
   -- shallow tent (equal links + real slack) that the free pins round into a
   -- natural catenary the moment gravity takes hold on Run.
   if pKind is "bridge" then
      put "deckpin" into tPinKind            -- planks flex a little but never fold back
      put 12 into tHt
      put "168,146,98" into tColor
      put 1 into tDens
      put max(2, min(24, round(tD / 60))) into tN
      put empty into tPts
      repeat with tI = 0 to tN
         put tI / tN into tT
         put round(tSx + tT * (pEx - tSx)) & comma & round(tSy + tT * (pEy - tSy)) & cr after tPts
      end repeat
   else
      put "pin" into tPinKind                 -- links pivot freely so the chain drapes
      put 8 into tHt
      put "150,154,170" into tColor
      put 0.3 into tDens                      -- light links settle into a natural curve
      put (tSx + pEx) / 2 into tAx
      put (tSy + pEy) / 2 + tD * 0.22 into tAy   -- apex sags below the midpoint (the slack)
      put max(3, min(20, round(tD / 34))) into tHalf
      put empty into tPts
      repeat with tI = 0 to tHalf             -- equal links: start -> apex
         put tI / tHalf into tT
         put round(tSx + tT * (tAx - tSx)) & comma & round(tSy + tT * (tAy - tSy)) & cr after tPts
      end repeat
      repeat with tI = 1 to tHalf             -- equal links: apex -> end
         put tI / tHalf into tT
         put round(tAx + tT * (pEx - tAx)) & comma & round(tAy + tT * (pEy - tAy)) & cr after tPts
      end repeat
   end if
   put the number of lines of tPts into tNpts
   put empty into tPrev
   repeat with tI = 1 to tNpts - 1
      put item 1 of line tI of tPts into tJx0
      put item 2 of line tI of tPts into tJy0
      put item 1 of line (tI + 1) of tPts into tJx1
      put item 2 of line (tI + 1) of tPts into tJy1
      put (tJx0 + tJx1) / 2 into tCx
      put (tJy0 + tJy1) / 2 into tCy
      put sqrt((tJx1 - tJx0) ^ 2 + (tJy1 - tJy0) ^ 2) into tLen
      put atan2(tJy1 - tJy0, tJx1 - tJx0) * 180 / kPI into tAng
      put placeBox(round(tCx), round(tCy), max(8, round(tLen)), tHt, tColor) into tSeg
      set the uDensity of tSeg to tDens
      b2kSetDensity tSeg, tDens
      set the uBounce of tSeg to 0           -- spans stay taut even when Bouncy mode is on
      b2kSetBounce tSeg, 0
      b2kMoveTo tSeg, round(tCx), round(tCy), tAng
      if tI is 1 then get connectJoint(tPinKind, pA, tSeg, round(tJx0), round(tJy0), 0)
      else get connectJoint(tPinKind, tPrev, tSeg, round(tJx0), round(tJy0), 0)
      put tSeg into tPrev
   end repeat
   get connectJoint(tPinKind, tPrev, pB, round(pEx), round(pEy), 0)
   put (niceName(pKind) & " built from " & (tNpts - 1) & " segments. Press Run to test it.") into gStatus
end buildSpan

-- The shared joint builder. Picks a sensible pivot per kind, records the joint
-- and its marker, and motorises it when pMotorSpeed > 0. Returns true on success.
function connectJoint pKind, pA, pB, pX, pY, pMotorSpeed
   local tJ, tAxis, tPivX, tPivY, tVis, tEnd, tdx, tdy, tda
   put pX into tPivX
   put pY into tPivY
   put "dot" into tVis
   put empty into tEnd
   put 0 into tJ
   switch pKind
      case "hinge"
         if pB is empty then
            b2kHinge pA, empty, pX, pY            -- pin to the world at the click
            put the result into tJ
            put "rod" into tVis
            put pA into tEnd
         else if b2kBodyType(pA) is "static" and b2kBodyType(pB) is not "static" then
            put item 1 of the loc of pA into tPivX  -- pivot at the static anchor
            put item 2 of the loc of pA into tPivY
            b2kHinge pA, pB, tPivX, tPivY
            put the result into tJ
            put "rod" into tVis
            put pB into tEnd
         else if b2kBodyType(pB) is "static" then
            put item 1 of the loc of pB into tPivX
            put item 2 of the loc of pB into tPivY
            b2kHinge pA, pB, tPivX, tPivY
            put the result into tJ
            put "rod" into tVis
            put pA into tEnd
         else
            put item 1 of the loc of pB into tPivX  -- two dynamic parts: pin at B
            put item 2 of the loc of pB into tPivY
            b2kHinge pA, pB, tPivX, tPivY
            put the result into tJ
            put "dot" into tVis
         end if
         break
      case "weld"
         b2kWeld pA, pB
         put the result into tJ
         put "line" into tVis
         break
      case "servo"
         -- a powered position hold: drives pA to keep its CURRENT pose relative
         -- to pB. It yields under load and springs back, unlike a rigid weld.
         if pB is empty then return false       -- a servo holds between two parts
         put (item 1 of the loc of pA) - (item 1 of the loc of pB) into tdx
         put (item 2 of the loc of pA) - (item 2 of the loc of pB) into tdy
         put round(b2kAngle(pA) - b2kAngle(pB)) into tda
         put b2kMotorTo(pA, pB, tdx, tdy, tda, kServoForce, kServoTorque) into tJ
         put "line" into tVis
         break
      case "rope"
         b2kRope pA, pB
         put the result into tJ
         put "line" into tVis
         break
      case "slider"
         put angleAtoB(pA, pB) into tAxis
         b2kSlider pA, pB, tAxis
         put the result into tJ
         put "line" into tVis
         break
      case "wheel"
         put item 1 of the loc of pB into tPivX     -- axle at the wheel's centre
         put item 2 of the loc of pB into tPivY
         b2kWheel pA, pB, tPivX, tPivY
         put the result into tJ
         if tJ > 0 then b2kWheelSpring tJ, 5, 0.7
         put "dot" into tVis
         break
      case "pin"
         b2kHinge pA, pB, pX, pY            -- exact-pivot hinge for spans (no marker)
         put the result into tJ
         put "none" into tVis
         break
      case "deckpin"
         b2kHinge pA, pB, pX, pY            -- bridge-deck pin: hinged but flex-limited (no marker)
         put the result into tJ
         if tJ > 0 then b2kHingeLimit tJ, - kBridgeFlex, kBridgeFlex
         put "none" into tVis
         break
      default
         return false
   end switch
   if tJ is empty or tJ <= 0 then return false
   recordJoint pKind, tJ, pA, pB, tPivX, tPivY, tVis
   put tEnd into gJEnd[gJN]
   if pMotorSpeed > 0 then
      if pKind is "hinge" then
         b2kMotor tJ, pMotorSpeed, kHingeTorque
      else if pKind is "wheel" then
         b2kWheelMotor tJ, pMotorSpeed, kWheelTorque
      end if
      put pMotorSpeed into gJMotor[gJN]
      set the uMotorOn of graphic ("cb_joint_" & gJN) to true
      set the uMotorSpeed of graphic ("cb_joint_" & gJN) to pMotorSpeed
   end if
   return true
end connectJoint

-- Screen-space direction from A to B, in degrees (slider axis).
function angleAtoB pA, pB
   local tAx, tAy, tBx, tBy
   put item 1 of the loc of pA into tAx
   put item 2 of the loc of pA into tAy
   put item 1 of the loc of pB into tBx
   put item 2 of the loc of pB into tBy
   return atan2(tBy - tAy, tBx - tAx) * 180 / kPI
end angleAtoB

on recordJoint pKind, pJoint, pA, pB, pX, pY, pVis
   local tG
   add 1 to gJN
   put pKind into gJKind[gJN]
   put pJoint into gJHandle[gJN]
   put pA into gJCa[gJN]
   put pB into gJCb[gJN]
   put pX into gJPx[gJN]
   put pY into gJPy[gJN]
   put 0 into gJMotor[gJN]
   put pVis into gJVis[gJN]
   put empty into gJEnd[gJN]
   put "cb_joint_" & gJN into tG
   create graphic tG
   if pVis is "none" then
      set the visible of graphic tG to false      -- internal structural pin: no marker
   else if pVis is "dot" then
      set the style of graphic tG to "oval"
      set the filled of graphic tG to true
      set the backgroundColor of graphic tG to "250,210,90"
      set the foregroundColor of graphic tG to "30,30,36"
      set the lineSize of graphic tG to 1
      set the width of graphic tG to 14
      set the height of graphic tG to 14
      set the loc of graphic tG to round(pX) & "," & round(pY)
   else
      set the style of graphic tG to "line"
      if pVis is "rod" then
         set the lineSize of graphic tG to 4
         set the foregroundColor of graphic tG to "250,210,90"
      else
         set the lineSize of graphic tG to 2
         set the foregroundColor of graphic tG to "200,206,220"
      end if
   end if
   -- default editable joint settings, stored on the marker (like parts' u-props)
   set the uMotorOn of graphic tG to false
   set the uMotorSpeed of graphic tG to gMotorSpeed
   set the uMotorPower of graphic tG to motorPowerDefault(pKind)
   set the uLimitOn of graphic tG to false
   set the uLimitLo of graphic tG to jointLimitLoDefault(pKind)
   set the uLimitHi of graphic tG to jointLimitHiDefault(pKind)
   set the uSpringHz of graphic tG to jointSpringHzDefault(pKind)
   set the uSpringDamp of graphic tG to jointSpringDampDefault(pKind)
   set the uMinLen of graphic tG to 0
   set the uMaxLen of graphic tG to 200
   set the uRangeSet of graphic tG to false
end recordJoint

-- Redraw every joint marker. dot = pivot bead on B; rod = arm from a fixed pivot
-- to the moving part; line = link between the two parts. Empty kind = removed.
on renderJoints
   local tI, tG, tVis, tRunning
   if gJN < 1 then exit renderJoints
   -- While running, the Kit's sync only repositions AWAKE bodies, so a marker
   -- whose tracked body (or bodies) are all asleep is already in the right place
   -- and its redraw — the real per-frame cost on big contraptions — can be
   -- skipped. In build mode parts move under the editor, not the sim, so the
   -- skip is disabled and every marker still follows a dragged part.
   put (gMode is "run") into tRunning
   repeat with tI = 1 to gJN
      put gJVis[tI] into tVis
      if tVis is empty or tVis is "none" then next repeat
      if tRunning then
         if jointAtRest(tI, tVis) then next repeat   -- asleep: marker already correct
      end if
      put "cb_joint_" & tI into tG
      if there is not a graphic tG then next repeat
      try
         if tVis is "dot" then
            set the loc of graphic tG to the loc of gJCb[tI]
         else if tVis is "rod" then
            set the points of graphic tG to \
                  (round(gJPx[tI]) & "," & round(gJPy[tI])) & cr & the loc of gJEnd[tI]
         else
            set the points of graphic tG to the loc of gJCa[tI] & cr & the loc of gJCb[tI]
         end if
      end try
   end repeat
end renderJoints

-- True when a joint marker need not be redrawn this frame: the body (or bodies)
-- it follows are all asleep, so they haven't moved. dot follows B; rod follows
-- its moving end; line follows both A and B.
function jointAtRest pIndex, pVis
   if pVis is "dot" then return not partAwake(gJCb[pIndex])
   if pVis is "rod" then return not partAwake(gJEnd[pIndex])
   return (not partAwake(gJCa[pIndex])) and (not partAwake(gJCb[pIndex]))
end jointAtRest

-- True when a part control has an awake, actively-simulating body. Empty or
-- body-less endpoints (a world pin, a static anchor) count as at rest — they
-- never move — so they don't force a redraw on their own.
function partAwake pCtrl
   if pCtrl is empty then return false
   if b2kBodyOf(pCtrl) is empty then return false
   return b2kIsAwake(pCtrl)
end partAwake

-- =====================================================================
-- Per-frame + contact feedback (only while Running)
-- =====================================================================
on b2kFrame
   renderJoints
   updateFlashes
   applyFieldForces
   updateBombs
   updateRings
   updateLasers
   updateThrusters
   containParts
   tickHud
end b2kFrame

on b2kContact pA, pB
   flashCtrl pA
   flashCtrl pB
   plateTouch pA, pB, 1
   plateTouch pB, pA, 1
   bombImpactCheck pA
   bombImpactCheck pB
end b2kContact

-- A body left a surface: if it stepped off a pressure plate, lighten its load.
on b2kEndContact pA, pB
   plateTouch pA, pB, -1
   plateTouch pB, pA, -1
end b2kEndContact

-- A dynamic body entered a sensor zone. Fire the plate signal on the first
-- arrival (0→1 occupants) so passing traffic doesn't machine-gun the motors.
on b2kSensorEnter pSensor, pVisitor
   if pSensor is empty or pVisitor is empty then exit b2kSensorEnter
   if (the uKind of pSensor is not "sensor") and (the uSensor of pSensor is not true) then exit b2kSensorEnter
   if b2kBodyType(pVisitor) is not "dynamic" then exit b2kSensorEnter
   add 1 to gSensorCount[pSensor]
   if gSensorCount[pSensor] is 1 then
      try
         set the backgroundColor of pSensor to "120,230,140"   -- lit while occupied
      end try
      put "A sensor zone triggered its signal!" into gStatus
      fireEmitter pSensor
      updateHud
   end if
end b2kSensorEnter

-- A body left a sensor zone; when the last one leaves, the zone goes idle again.
on b2kSensorExit pSensor, pVisitor
   if pSensor is empty then exit b2kSensorExit
   if (the uKind of pSensor is not "sensor") and (the uSensor of pSensor is not true) then exit b2kSensorExit
   subtract 1 from gSensorCount[pSensor]
   if gSensorCount[pSensor] <= 0 then
      put 0 into gSensorCount[pSensor]
      try
         set the backgroundColor of pSensor to numOr(the uColor of pSensor, "232,196,92")
      end try
   end if
end b2kSensorExit

on flashCtrl pCtrl
   if pCtrl is empty then exit flashCtrl
   if the uKind of pCtrl is among the items of "plate,anchor,fan,magnet" then exit flashCtrl
   if pCtrl is gSelPart then exit flashCtrl   -- don't fight the selection outline
   try
      set the foregroundColor of pCtrl to "255,255,255"
      set the lineSize of pCtrl to 2
      put the milliseconds + kFlashMs into gFlash[pCtrl]
   end try
end flashCtrl

on updateFlashes
   local tCtrl, tNow, tDead, d
   put the milliseconds into tNow
   put empty into tDead
   repeat for each key tCtrl in gFlash
      if tNow >= gFlash[tCtrl] then
         try
            set the foregroundColor of tCtrl to "20,20,24"
            set the lineSize of tCtrl to 1
         end try
         put tCtrl & cr after tDead
      end if
   end repeat
   repeat for each line d in tDead
      delete variable gFlash[d]
   end repeat
end updateFlashes

-- =====================================================================
-- Delete / clear / reset
-- =====================================================================
on deletePart pCtrl
   if pCtrl is empty then exit deletePart
   if gPendCtrl is pCtrl then resetPend
   if gSelPart is pCtrl then deselectPart
   if gWireSrc is pCtrl then put empty into gWireSrc
   removeWiresFor pCtrl
   local tI, tP, tNew
   if gJN >= 1 then
      repeat with tI = 1 to gJN
         if gJCa[tI] is pCtrl or gJCb[tI] is pCtrl then removeJointAt tI
      end repeat
   end if
   put empty into tNew
   repeat for each line tP in gParts
      if tP is not empty and tP is not pCtrl then put tP & cr after tNew
   end repeat
   put tNew into gParts
   unregisterKind pCtrl
   put true into gDynDirty
   try
      b2kRemove pCtrl
   end try
   try
      delete pCtrl
   end try
   put "Deleted a part and any joints on it." into gStatus
end deletePart

-- Drop an identical copy of a part — same size, colour, material and special
-- settings — nudged off the original, then select it and switch to Drag so it
-- can be moved straight away. (Joints aren't copied; they connect two parts.)
-- Make one independent copy of a part at (pX,pY): same size, colour, material and
-- special settings. The copy carries no group tag, so copying a vehicle part
-- yields a free part rather than something tied to the original's assembly.
function copyPart pCtrl, pX, pY
   local tNew
   put rebuildPart(the uKind of pCtrl, pX, pY, numOr(the uW of pCtrl, the width of pCtrl), \
         numOr(the uH of pCtrl, the height of pCtrl), \
         (the uColor of pCtrl), (the uFile of pCtrl)) into tNew
   if tNew is empty then return empty
   if the uBounce of pCtrl is not empty then
      set the uBounce of tNew to (the uBounce of pCtrl)
      if (the uBounce of pCtrl) > 0 then b2kSetBounce tNew, (the uBounce of pCtrl)
   end if
   applyPartSpecial tNew, partSpecial(pCtrl)
   set the uGroup of tNew to empty
   return tNew
end copyPart

on duplicatePart pCtrl
   if pCtrl is empty then exit duplicatePart
   if pCtrl is not among the lines of gParts then exit duplicatePart
   local tLoc, tNx, tNy, tNew
   put the loc of pCtrl into tLoc
   put (item 1 of tLoc) + 26 into tNx
   put (item 2 of tLoc) + 26 into tNy
   if tNx > gArenaR then put (item 1 of tLoc) - 26 into tNx
   if tNy > gArenaB then put (item 2 of tLoc) - 26 into tNy
   put copyPart(pCtrl, tNx, tNy) into tNew
   if tNew is empty then exit duplicatePart
   renderBuild
   put "drag" into gTool
   selectPart tNew
   highlightAll
   put "Duplicated a " & friendlyKind(the uKind of pCtrl) & ". Drag the copy where you want it." into gStatus
   updateHud
end duplicatePart

-- Multiply: drop a whole batch of copies in a tidy grid, asking how many first.
on multiplyPart pCtrl
   if pCtrl is empty then exit multiplyPart
   if pCtrl is not among the lines of gParts then exit multiplyPart
   local tN, tLoc, tOx, tOy, tStep, tCols, tI, tX, tY, tNew, tLast, tMade
   ask "How many copies would you like?" with "5"
   if it is empty or the result is "Cancel" then
      put "Multiply cancelled." into gStatus
      updateHud
      exit multiplyPart
   end if
   if it is not a number then
      put "Please type a whole number (1–50)." into gStatus
      updateHud
      exit multiplyPart
   end if
   put min(50, max(1, round(it))) into tN
   put the loc of pCtrl into tLoc
   put item 1 of tLoc into tOx
   put item 2 of tLoc into tOy
   put max(28, max(numOr(the uW of pCtrl, the width of pCtrl), \
         numOr(the uH of pCtrl, the height of pCtrl)) + 14) into tStep   -- spacing so copies don't pile up
   put max(1, trunc((gArenaR - tOx - tStep) / tStep)) into tCols          -- columns that fit to the right
   put 0 into tMade
   put empty into tLast
   lock screen
   repeat with tI = 1 to tN
      put tOx + ((tI - 1) mod tCols + 1) * tStep into tX
      put tOy + ((tI - 1) div tCols) * tStep into tY
      put max(gArenaL + tStep / 2, min(gArenaR - tStep / 2, tX)) into tX
      put max(gArenaT + tStep / 2, min(gArenaB - tStep / 2, tY)) into tY
      put copyPart(pCtrl, round(tX), round(tY)) into tNew
      if tNew is not empty then
         add 1 to tMade
         put tNew into tLast
      end if
   end repeat
   renderBuild
   unlock screen
   if tLast is not empty then
      put "drag" into gTool
      selectPart tLast
      highlightAll
   end if
   put "Made " & tMade & " copies of the " & friendlyKind(the uKind of pCtrl) & "." into gStatus
   updateHud
end multiplyPart

on removeJointAt pIndex
   if gSelJoint is pIndex then deselectJoint
   try
      b2kRemoveJoint gJHandle[pIndex]
   end try
   if there is a graphic ("cb_joint_" & pIndex) then delete graphic ("cb_joint_" & pIndex)
   put empty into gJKind[pIndex]
   put 0 into gJHandle[pIndex]
   put empty into gJCa[pIndex]
   put empty into gJCb[pIndex]
   put empty into gJVis[pIndex]
   put empty into gJEnd[pIndex]
end removeJointAt

on clearAll
   resetPend
   deselectPart
   local tP
   lock screen
   clearJoints
   repeat for each line tP in gParts
      if tP is empty then next repeat
      try
         b2kRemove tP
      end try
      try
         delete tP
      end try
   end repeat
   put empty into gParts
   put empty into gFlash
   resetSceneState
   unlock screen
   put "Cleared. Pick a shape and click the canvas to place parts." into gStatus
   updateHud
end clearAll

on clearJoints
   local tI
   if gJN >= 1 then
      repeat with tI = 1 to gJN
         try
            b2kRemoveJoint gJHandle[tI]
         end try
         if there is a graphic ("cb_joint_" & tI) then delete graphic ("cb_joint_" & tI)
      end repeat
   end if
   resetJointArrays
end clearJoints

on resetJointArrays
   put empty into gSelJoint
   put 0 into gJN
   put empty into gJKind
   put empty into gJHandle
   put empty into gJCa
   put empty into gJCb
   put empty into gJPx
   put empty into gJPy
   put empty into gJMotor
   put empty into gJVis
   put empty into gJEnd
end resetJointArrays

function liveJointCount
   local tI, tN
   put 0 into tN
   if gJN >= 1 then
      repeat with tI = 1 to gJN
         if gJKind[tI] is not empty then add 1 to tN
      end repeat
   end if
   return tN
end liveJointCount

-- =====================================================================
-- Sample contraptions (built from the same primitives, one click)
-- =====================================================================
on buildSampleCart
   if gMode is "run" then toggleMode
   clearAll
   get placeVehicle((gArenaL + gArenaR) div 2, gArenaT + 110)
   highlightAll
   renderBuild
   put "Sample cart built. Press Run — the motorised wheels drive it." into gStatus
   updateHud
end buildSampleCart

on buildSampleSwing
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tAnchorX, tAnchorY, tLen, tBob
   put (gArenaL + gArenaR) div 2 into tCx
   put tCx into tAnchorX
   put gArenaT + 30 into tAnchorY
   put 220 into tLen
   -- start the bob lifted ~55 deg so gravity swings it (build it where it sits,
   -- then hinge — never teleport a body after jointing it).
   put placeBall(tAnchorX - tLen * 0.819, tAnchorY + tLen * 0.574, 56, "214,92,92") into tBob
   get connectJoint("hinge", tBob, empty, tAnchorX, tAnchorY, 0)
   renderBuild
   put "Sample swing built. Press Run — gravity pulls the bob into a swing." into gStatus
   updateHud
end buildSampleSwing

-- =====================================================================
-- Save / load (whole contraption as tab-delimited text)
-- =====================================================================
-- Serialise the whole scene to CB2 text (used by Save and by Reset's snapshot).
function serializeText
   local tOut, tP, tI
   put "CB2" & cr into tOut
   put "world" & tab & gGravityMode & tab & gWorldFeel & tab & (gCCD is true) & tab & \
         (gSleepOn is true) & tab & (gWarmStart is true) & tab & numOr(gSubsteps, 4) & cr after tOut
   repeat for each line tP in gParts
      if tP is empty then next repeat
      try
         put partLine(tP) & cr after tOut
      end try
   end repeat
   if gJN >= 1 then
      repeat with tI = 1 to gJN
         if gJKind[tI] is not empty then put jointLine(tI) & cr after tOut
      end repeat
   end if
   set the itemDelimiter to tab
   repeat for each line tP in gWires
      if tP is empty then next repeat
      if (item 1 of tP) is among the lines of gParts and (item 2 of tP) is among the lines of gParts then
         put "wire" & tab & (the uPartId of (item 1 of tP)) & tab & (the uPartId of (item 2 of tP)) & cr after tOut
      end if
   end repeat
   return tOut
end serializeText

on saveContraption
   local tOut
   put serializeText() into tOut
   ask file "Save contraption as:" with "contraption.cbx"
   if it is empty or the result is "cancel" then
      put "Save cancelled." into gStatus
      updateHud
      exit saveContraption
   end if
   put tOut into URL ("file:" & it)
   if the result is not empty then
      put "Save failed: " & the result into gStatus
   else
      put "Saved contraption to " & it into gStatus
   end if
   updateHud
end saveContraption

function partLine pCtrl
   local tLoc
   put the loc of pCtrl into tLoc
   if the uKind of pCtrl is "laser" then put (line 1 of the points of pCtrl) into tLoc   -- a laser's anchor is its emitter, not the beam's bbox centre
   return "part" & tab & (the uPartId of pCtrl) & tab & (the uKind of pCtrl) & tab & \
         (item 1 of tLoc) & tab & (item 2 of tLoc) & tab & \
         numOr(the uW of pCtrl, the width of pCtrl) & tab & numOr(the uH of pCtrl, the height of pCtrl) & tab & \
         (the uBounce of pCtrl) & tab & (the uColor of pCtrl) & tab & (the uFile of pCtrl) & tab & \
         partSpecial(pCtrl) & tab & (the uPartName of pCtrl)
end partLine

-- Pack a part's per-kind extras as "key=value;key=value" (empty for plain shapes).
-- Appended as the last column so old 10-column "CB1" saves still load cleanly.
function partSpecial pCtrl
   local tS, tKind
   put the uKind of pCtrl into tKind
   put empty into tS
   if kindIsTerrain(tKind) then               -- static scenery: grip + baked-in angle (+ ramp facing)
      put addKV(tS, "fric=" & (the uFriction of pCtrl)) into tS
      put addKV(tS, "tang=" & numOr(the uAngle of pCtrl, 0)) into tS
      if tKind is "ramp" then put addKV(tS, "flip=" & (the uFlip of pCtrl is true)) into tS
      return tS
   end if
   if kindHasBody(tKind) then
      put addKV(tS, "fric=" & (the uFriction of pCtrl)) into tS
      put addKV(tS, "dens=" & (the uDensity of pCtrl)) into tS
      put addKV(tS, "grav=" & (the uGravity of pCtrl)) into tS
      put addKV(tS, "frot=" & (the uFixedRot of pCtrl is true)) into tS
      put addKV(tS, "btype=" & (the uBodyType of pCtrl)) into tS
      put addKV(tS, "ldmp=" & (the uLinDamp of pCtrl)) into tS
      put addKV(tS, "admp=" & (the uAngDamp of pCtrl)) into tS
      put addKV(tS, "bul=" & (the uBullet of pCtrl is true)) into tS
      put addKV(tS, "ang=" & round(b2kAngle(pCtrl))) into tS
      put addKV(tS, "lspd=" & (the uLaunchSpeed of pCtrl)) into tS
      put addKV(tS, "ldir=" & (the uLaunchDir of pCtrl)) into tS
      put addKV(tS, "spin=" & (the uSpinRate of pCtrl)) into tS
      if the uGroup of pCtrl is not empty then put addKV(tS, "grp=" & (the uGroup of pCtrl)) into tS
      if numOr(the uLayer of pCtrl, 0) > 0 then put addKV(tS, "lyr=" & (the uLayer of pCtrl)) into tS
      if numOr(the uSleep of pCtrl, 0) > 0 then put addKV(tS, "slp=" & (the uSleep of pCtrl)) into tS
      if the uKind of pCtrl is "image" and the uShape of pCtrl is not empty then put addKV(tS, "ishp=" & (the uShape of pCtrl)) into tS
      if the uActive of pCtrl is false then put addKV(tS, "act=false") into tS
      if the uSensor of pCtrl is true then put addKV(tS, "sen=true") into tS
      if the uOnChans of pCtrl is not empty then put addKV(tS, "cat=" & (the uOnChans of pCtrl)) into tS
      if the uHitChans of pCtrl is not empty then put addKV(tS, "msk=" & (the uHitChans of pCtrl)) into tS
      if the uKind of pCtrl is "draw" then put addKV(tS, "pts=" & ptsPacked(pCtrl)) into tS
   end if
   switch tKind
      case "fan"
         put addKV(tS, "dir=" & (the uFanDir of pCtrl)) into tS
         put addKV(tS, "force=" & (the uFanForce of pCtrl)) into tS
         put addKV(tS, "fscale=" & (the uFanScale of pCtrl)) into tS
         break
      case "magnet"
         put addKV(tS, "pol=" & (the uMagPolarity of pCtrl)) into tS
         put addKV(tS, "force=" & (the uMagForce of pCtrl)) into tS
         put addKV(tS, "range=" & (the uMagRange of pCtrl)) into tS
         break
      case "bomb"
         put addKV(tS, "bradius=" & (the uBlastRadius of pCtrl)) into tS
         put addKV(tS, "bpower=" & (the uBlastPower of pCtrl)) into tS
         put addKV(tS, "fuse=" & (the uFuseOnRun of pCtrl is true)) into tS
         put addKV(tS, "flen=" & numOr(the uFuseLen of pCtrl, kBombFuseFrames)) into tS
         if the uSoftBlast of pCtrl is true then put addKV(tS, "soft=true") into tS
         break
      case "laser"
         put addKV(tS, "ldr=" & numOr(the uLaserDir of pCtrl, 0)) into tS
         break
      case "thruster"
         put addKV(tS, "tdr=" & numOr(the uThrustDir of pCtrl, 270)) into tS
         put addKV(tS, "tpw=" & numOr(the uThrustPower of pCtrl, 0)) into tS
         put addKV(tS, "tsp=" & numOr(the uThrustSpin of pCtrl, 0)) into tS
         break
   end switch
   return tS
end partSpecial

-- Append "key=value" to a packed special string, with a ; separator as needed.
function addKV pS, pKV
   if pS is empty then return pKV
   return pS & ";" & pKV
end addKV

-- Read one value out of a packed "key=value;..." special string (delimiter-safe).
function specialValue pSpecial, pKey
   local tPart, tResult, tKlen
   put empty into tResult
   put the number of chars of pKey into tKlen
   set the itemDelimiter to ";"
   repeat for each item tPart in pSpecial
      if char 1 to tKlen of tPart is pKey and char tKlen + 1 of tPart is "=" then
         put char tKlen + 2 to -1 of tPart into tResult
         exit repeat
      end if
   end repeat
   set the itemDelimiter to comma
   return tResult
end specialValue

function jointLine pIndex
   local tIdA, tIdB
   put 0 into tIdA
   put 0 into tIdB
   try
      if gJCa[pIndex] is not empty then put the uPartId of gJCa[pIndex] into tIdA
   end try
   try
      if gJCb[pIndex] is not empty then put the uPartId of gJCb[pIndex] into tIdB
   end try
   return "joint" & tab & gJKind[pIndex] & tab & tIdA & tab & tIdB & tab & \
         gJPx[pIndex] & tab & gJPy[pIndex] & tab & gJMotor[pIndex] & tab & \
         jointSpecial(pIndex)
end jointLine

on loadContraption
   local tFile, tData
   answer file "Open a contraption:" with type "Contraption|cbx,txt"
   put it into tFile
   if tFile is empty or the result is "cancel" then
      put "Load cancelled." into gStatus
      updateHud
      exit loadContraption
   end if
   put URL ("file:" & tFile) into tData
   if the result is not empty then
      put "Could not read that file: " & the result into gStatus
      updateHud
      exit loadContraption
   end if
   if line 1 of tData is not "CB1" and line 1 of tData is not "CB2" then
      put "That file is not a Contraption Builder save." into gStatus
      updateHud
      exit loadContraption
   end if
   if gMode is "run" then toggleMode
   rebuildFromText tData
   put "Loaded contraption from " & tFile & ". Press Run to simulate." into gStatus
   updateHud
end loadContraption

-- Rebuild the whole scene from CB2/CB1 text, clearing the stage first. Shared by
-- Load (from a file) and Reset (from the pre-run snapshot).
on rebuildFromText pData
   local tLine, tRec, tMap, tNew
   local tId, tKind, tX, tY, tW, tH, tBounce, tColor, tFileRef, tSpecial, tNm
   local tIdA, tIdB, tPx, tPy, tMotor, tA, tB, tJSpecial
   clearAll
   put "normal" into gGravityMode
   put "default" into gWorldFeel
   setWorldOptionDefaults
   put empty into tMap
   lock screen
   repeat for each line tLine in pData
      set the itemDelimiter to tab
      put item 1 of tLine into tRec
      if tRec is "part" then
         put item 2 of tLine into tId
         put item 3 of tLine into tKind
         put item 4 of tLine into tX
         put item 5 of tLine into tY
         put item 6 of tLine into tW
         put item 7 of tLine into tH
         put item 8 of tLine into tBounce
         put item 9 of tLine into tColor
         put item 10 of tLine into tFileRef
         put item 11 of tLine into tSpecial
         put item 12 of tLine into tNm
         set the itemDelimiter to comma
         put rebuildPart(tKind, tX, tY, tW, tH, tColor, tFileRef) into tNew
         if tNew is not empty then
            put tNew into tMap[tId]
            if tBounce is not empty then
               set the uBounce of tNew to tBounce
               if tBounce > 0 then b2kSetBounce tNew, tBounce
            end if
            applyPartSpecial tNew, tSpecial
            if tNm is not empty then set the uPartName of tNew to tNm   -- restore a renamed part's name
         end if
      else if tRec is "joint" then
         put item 2 of tLine into tKind
         put item 3 of tLine into tIdA
         put item 4 of tLine into tIdB
         put item 5 of tLine into tPx
         put item 6 of tLine into tPy
         put item 7 of tLine into tMotor
         put item 8 of tLine into tJSpecial
         set the itemDelimiter to comma
         put tMap[tIdA] into tA
         if tIdB is 0 then put empty into tB
         else put tMap[tIdB] into tB
         if tA is not empty and (tB is not empty or tKind is "hinge" or tKind is "pin" or tKind is "deckpin") then
            if connectJoint(tKind, tA, tB, tPx, tPy, tMotor) then applyJointSpecial gJN, tJSpecial
         end if
      else if tRec is "wire" then
         put item 2 of tLine into tIdA
         put item 3 of tLine into tIdB
         if (tIdA is among the keys of tMap) and (tIdB is among the keys of tMap) then addWire tMap[tIdA], tMap[tIdB]
      else if tRec is "world" then
         put item 2 of tLine into gGravityMode
         put item 3 of tLine into gWorldFeel
         if gWorldFeel is empty then put "default" into gWorldFeel
         if item 4 of tLine is not empty then put (item 4 of tLine is "true") into gCCD
         if item 5 of tLine is not empty then put (item 5 of tLine is "true") into gSleepOn
         if item 6 of tLine is not empty then put (item 6 of tLine is "true") into gWarmStart
         if item 7 of tLine is not empty then put item 7 of tLine into gSubsteps
         set the itemDelimiter to comma
      else
         set the itemDelimiter to comma
      end if
   end repeat
   set the itemDelimiter to comma
   applyGravityMode
   applyWorldFeel
   refreshGravityLabel
   refreshWorldFeelLabel
   renderBuild
   unlock screen
end rebuildFromText

-- Restore the layout captured when Run last started, and return to Build mode.
on resetMachine
   if gPreRun is empty then
      put "Nothing to reset yet — press Run first; then Reset brings this build back." into gStatus
      updateHud
      exit resetMachine
   end if
   lock screen
   if gMode is "run" then toggleMode
   rebuildFromText gPreRun
   unlock screen
   put "Reset to your pre-run build." into gStatus
   updateHud
end resetMachine

function rebuildPart pKind, pX, pY, pW, pH, pColor, pFile
   if pW is empty or pW < 1 then put kBoxMin into pW
   if pH is empty or pH < 1 then put kBoxMin into pH
   switch pKind
      case "box"
         return placeBox(pX, pY, pW, pH, pColor)
      case "ball"
         return placeBall(pX, pY, pW, pColor)
      case "capsule"
         return placeCapsule(pX, pY, max(pW, pH), min(pW, pH), pColor)
      case "poly"
         return placePoly(pX, pY, round(pW / 2), pColor)
      case "anchor"
         return placeAnchor(pX, pY)
      case "platform"
      case "ramp"
      case "hill"
         return placeTerrain(pKind, pX, pY, pW, pH)
      case "draw"
         return placeDrawPlaceholder(pX, pY)   -- points + chain restored by applyPartSpecial
      case "image"
         return rebuildImage(pX, pY, pW, pH, pFile)
      case "balloon"
         return placeBalloon(pX, pY)
      case "bomb"
         return placeBomb(pX, pY)
      case "plate"
         return placePlate(pX, pY)
      case "sensor"
         return placeSensor(pX, pY)
      case "fan"
         return placeFan(pX, pY)
      case "magnet"
         return placeMagnet(pX, pY)
   end switch
   return empty
end rebuildPart

function rebuildImage pX, pY, pW, pH, pFile
   local tName, tRef
   if pFile is empty then return empty
   put "cb_img_" & the milliseconds & "_" & random(99999) into tName
   create image tName
   put the long id of image tName into tRef
   set the filename of tRef to pFile
   set the width of tRef to pW
   set the height of tRef to pH
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddBox tRef
   tagPart tRef, "image", empty, pFile
   return tRef
end rebuildImage

-- =====================================================================
-- HUD + small helpers
-- =====================================================================
on updateHud
   local tInfo, tModeTxt, tMotorTxt
   if gMode is "run" then put "RUN" into tModeTxt
   else put "BUILD" into tModeTxt
   if gMotorOn then put "Motor ON " & gMotorSpeed & " deg/s" into tMotorTxt
   else put "Motor OFF (" & gMotorSpeed & " deg/s)" into tMotorTxt
   put "Mode: " & tModeTxt into tInfo
   if gJointTool is not empty then put tInfo & "    Joint: " & gJointTool into tInfo
   else put tInfo & "    Tool: " & gTool into tInfo
   put tInfo & "    " & tMotorTxt into tInfo
   put tInfo & "    Parts: " & b2kBodyCount() & "    Joints: " & liveJointCount() into tInfo
   if gBouncy then put tInfo & "    Bouncy" into tInfo
   if gMode is "run" and gFps is not empty then put tInfo & "    " & gFps & " fps" into tInfo
   if gMode is "run" then put tInfo & hudPerf() & hudSelection() into tInfo
   if gStatus is not empty then put tInfo & "     |  " & gStatus into tInfo
   if there is a field "ui_status" then put tInfo into field "ui_status"
end updateHud

-- Live engine telemetry for the status bar (Run only): solver step time + how many
-- bodies are still awake. b2kProfile returns "totalStep,collide,solve" in ms.
function hudPerf
   local tProf
   put b2kProfile() into tProf
   if tProf is empty then return empty
   set the itemDelimiter to comma
   return "    step " & fmtMs(item 1 of tProf) & "ms · awake " & b2kAwakeBodyCount()
end hudPerf

-- Live readout for the selected part or joint, so the inspector numbers can be
-- watched changing during a run (speed/mass/angle, or a joint's own measure).
function hudSelection
   local tK, tH
   if gSelJoint is not empty then
      put gJKind[gSelJoint] into tK
      put gJHandle[gSelJoint] into tH
      if tK is "hinge" then return "    hinge " & round(b2kHingeAngle(tH)) & "°"
      if tK is "rope" then return "    rope " & round(b2kRopeLength(tH)) & " px"
      if tK is "slider" then return "    slider " & round(b2kSliderPos(tH)) & " px"
      return empty
   end if
   if gSelPart is not empty and the uKind of gSelPart is "laser" then
      if the uLaserDist of gSelPart is empty then return "    beam: no hit"
      return "    beam: " & (the uLaserDist of gSelPart) & " px"
   end if
   if gSelPart is empty or not kindHasBody(the uKind of gSelPart) then return empty
   return "    sel: " & round(b2kSpeed(gSelPart)) & " px/s · " & fmtMass(b2kMass(gSelPart)) & " · " & round(b2kAngle(gSelPart)) & "°"
end hudSelection

-- Small number formatters for the readouts.
function fmtMs pN
   if pN is empty or pN is not a number then return "0.0"
   return format("%.1f", pN)
end fmtMs

function fmtMass pN
   if pN is empty or pN is not a number then return "0 kg"
   if pN < 10 then return format("%.1f", pN) & " kg"
   return round(pN) & " kg"
end fmtMass

on tickHud
   add 1 to gFrames
   if gFpsTime is empty then put the milliseconds into gFpsTime
   if the milliseconds - gFpsTime >= kFpsWindowMs then
      put round(gFrames * 1000 / (the milliseconds - gFpsTime)) into gFps
      put 0 into gFrames
      put the milliseconds into gFpsTime
   end if
   -- Refresh the HUD ~10x/sec while running so the live telemetry reads smoothly,
   -- without rebuilding the whole status string every single frame.
   if gHudTime is empty or (the milliseconds - gHudTime) >= 100 then
      put the milliseconds into gHudTime
      updateHud
   end if
end tickHud

function rnd pLow, pHigh
   return pLow + random(max(1, pHigh - pLow))
end rnd

function randomColor
   return line (random(6)) of shapePalette()
end randomColor

function shapePalette
   return "92,150,222" & cr & "84,206,142" & cr & "232,182,92" & cr \
         & "214,92,92" & cr & "206,124,206" & cr & "120,200,232"
end shapePalette

-- =====================================================================
-- Special objects: helium balloons, bombs, pressure plates, fans, magnets.
-- All are assembled from the same friendly b2k... Kit as the basic shapes.
-- =====================================================================

-- A helium balloon: a light ball with a negative gravity scale, so it rises.
-- Linear damping gives it a gentle terminal speed instead of shooting away.
function placeBalloon pX, pY
   local tCtrl
   b2kSpawnBall pX, pY, kBalloonDiam, "236,120,150"
   put the result into tCtrl
   tagPart tCtrl, "balloon", "236,120,150", empty
   b2kSetDensity tCtrl, 0.3
   set the uDensity of tCtrl to 0.3
   b2kSetGravityScale tCtrl, kBalloonGravScale
   set the uGravity of tCtrl to kBalloonGravScale
   b2kSetDamping tCtrl, kBalloonDamp, 0.4
   return tCtrl
end placeBalloon

-- A bomb: a dynamic ball that detonates on a hard hit, a pressure-plate
-- signal, or (optionally) a fuse lit the moment Run starts.
function placeBomb pX, pY
   local tCtrl
   b2kSpawnBall pX, pY, kBombDiam, "150,40,40"
   put the result into tCtrl
   tagPart tCtrl, "bomb", "150,40,40", empty
   set the uFuseOnRun of tCtrl to true     -- bombs arm on Run by default (fuse length set in the inspector)
   set the uFuse of tCtrl to 0
   set the uFuseLen of tCtrl to kBombFuseFrames    -- countdown frames once armed (60 = ~1s)
   set the uBlastRadius of tCtrl to kBombRadius
   set the uBlastPower of tCtrl to kBombPower
   return tCtrl
end placeBomb

-- A pressure plate: a flat, solid, static bar that notices weight resting on it.
function placePlate pX, pY
   local tName, tRef
   put "cb_plate_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the backgroundColor of tRef to "150,160,180"
   set the foregroundColor of tRef to "210,214,224"
   set the lineSize of tRef to 1
   set the width of tRef to kPlateW
   set the height of tRef to kPlateH
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddStatic tRef
   tagPart tRef, "plate", "150,160,180", empty
   return tRef
end placePlate

-- A non-solid trigger zone. Nothing collides with it, but when a dynamic body
-- ENTERS it (on b2kSensorEnter) it fires the same signal as a pressure plate —
-- bombs go off and motors flip. Drawn translucent so it reads as a zone.
function placeSensor pX, pY
   local tName, tRef
   put "cb_sensor_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "rectangle"
   set the filled of tRef to true
   set the backgroundColor of tRef to "232,196,92"     -- amber, idle
   set the foregroundColor of tRef to "120,96,32"
   set the lineSize of tRef to 2
   set the blendLevel of tRef to 55                      -- translucent: clearly a zone, not solid
   set the width of tRef to kSensorW
   set the height of tRef to kSensorH
   set the loc of tRef to round(pX) & "," & round(pY)
   b2kAddSensor tRef                                      -- static, non-solid trigger fixture
   tagPart tRef, "sensor", "232,196,92", empty
   return tRef
end placeSensor

-- A fan/wind zone: a translucent arrow that pushes parts inside it. No body.
function placeFan pX, pY
   local tName, tRef
   put "cb_fan_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "polygon"
   set the filled of tRef to true
   set the backgroundColor of tRef to "90,170,230"
   set the foregroundColor of tRef to "150,210,255"
   set the lineSize of tRef to 1
   set the blendLevel of tRef to 64
   set the uFanDir of tRef to 270             -- 0=right 90=down 180=left 270=up
   set the uFanForce of tRef to kFanForce
   set the uFanScale of tRef to 1
   set the points of tRef to fanArrowPoints(round(pX), round(pY), kFanW div 2, kFanH div 2, 270)
   tagPart tRef, "fan", "90,170,230", empty
   return tRef
end placeFan

-- A magnet: a disc that pulls (or pushes) nearby parts. No body.
function placeMagnet pX, pY
   local tName, tRef
   put "cb_magnet_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "oval"
   set the filled of tRef to true
   set the backgroundColor of tRef to "120,90,210"
   set the foregroundColor of tRef to "210,200,250"
   set the lineSize of tRef to 2
   set the width of tRef to 30
   set the height of tRef to 30
   set the loc of tRef to round(pX) & "," & round(pY)
   set the uMagPolarity of tRef to 1          -- +1 attract, -1 repel
   set the uMagForce of tRef to kMagnetForce
   set the uMagRange of tRef to kMagnetRange
   tagPart tRef, "magnet", "120,90,210", empty
   return tRef
end placeMagnet

-- Rebuild the fan's arrow polygon around its current centre for its direction.
on drawFanShape pFan
   local tCx, tCy, tScale, tHw, tHh
   put item 1 of the loc of pFan into tCx
   put item 2 of the loc of pFan into tCy
   put the uFanScale of pFan into tScale
   if tScale is empty then put 1 into tScale
   put round(kFanW * tScale / 2) into tHw
   put round(kFanH * tScale / 2) into tHh
   set the points of pFan to fanArrowPoints(tCx, tCy, tHw, tHh, the uFanDir of pFan)
end drawFanShape

-- A filled triangle that points the way the fan blows (within a w x h box).
function fanArrowPoints pCx, pCy, pHw, pHh, pDir
   local tP
   put empty into tP
   switch pDir
      case 0       -- right
         put (pCx + pHw) & "," & pCy & cr after tP
         put (pCx - pHw) & "," & (pCy - pHh) & cr after tP
         put (pCx - pHw) & "," & (pCy + pHh) & cr after tP
         break
      case 90      -- down
         put pCx & "," & (pCy + pHh) & cr after tP
         put (pCx - pHw) & "," & (pCy - pHh) & cr after tP
         put (pCx + pHw) & "," & (pCy - pHh) & cr after tP
         break
      case 180     -- left
         put (pCx - pHw) & "," & pCy & cr after tP
         put (pCx + pHw) & "," & (pCy - pHh) & cr after tP
         put (pCx + pHw) & "," & (pCy + pHh) & cr after tP
         break
      default      -- 270 up
         put pCx & "," & (pCy - pHh) & cr after tP
         put (pCx - pHw) & "," & (pCy + pHh) & cr after tP
         put (pCx + pHw) & "," & (pCy + pHh) & cr after tP
   end switch
   put (line 1 of tP) after tP                -- close the triangle
   return tP
end fanArrowPoints

-- A laser: a no-body emitter that casts a ray each frame and draws the beam to
-- whatever it hits first (a wall counts), marking the distance. Shows off the
-- Kit's ray API (b2kRayHit + b2kRayHitX/Y + b2kRayDist). The graphic is the beam
-- itself — a thick line from the emitter (point 1) to the hit point (point 2).
function placeLaser pX, pY
   local tName, tRef
   put "cb_laser_" & the milliseconds & "_" & random(99999) into tName
   create graphic tName
   put the long id of graphic tName into tRef
   set the style of tRef to "line"
   set the lineSize of tRef to 5
   set the foregroundColor of tRef to "236,80,80"
   set the uLaserDir of tRef to 0            -- 0=right 90=down 180=left 270=up (45° steps)
   set the points of tRef to round(pX) & "," & round(pY) & cr & round(pX + 40) & "," & round(pY)
   tagPart tRef, "laser", "236,80,80", empty
   drawLaserBeam tRef
   return tRef
end placeLaser

-- Recast a laser's ray from its emitter (point 1) along uLaserDir and stretch the
-- beam to the first hit; store the distance for the live readout.
on drawLaserBeam pLaser
   local tHead, tEx, tEy, tRad, tFx, tFy, tHx, tHy, tHitCtrl
   set the itemDelimiter to comma
   put line 1 of the points of pLaser into tHead
   if tHead is empty then exit drawLaserBeam
   put item 1 of tHead into tEx
   put item 2 of tHead into tEy
   put numOr(the uLaserDir of pLaser, 0) * kPI / 180 into tRad
   put tEx + kLaserReach * cos(tRad) into tFx
   put tEy + kLaserReach * sin(tRad) into tFy
   put b2kRayHit(tEx, tEy, tFx, tFy) into tHitCtrl   -- returns the hit control (or empty), NOT a boolean
   if tHitCtrl is not empty then
      put b2kRayHitX() into tHx
      put b2kRayHitY() into tHy
      set the uLaserDist of pLaser to round(b2kRayDist())
   else
      put tFx into tHx
      put tFy into tHy
      set the uLaserDist of pLaser to empty
   end if
   set the points of pLaser to round(tEx) & "," & round(tEy) & cr & round(tHx) & "," & round(tHy)
end drawLaserBeam

-- Recast every laser (called each frame while running and on every build redraw).
on updateLasers
   local tL
   repeat for each line tL in gKindList["laser"]
      if tL is not empty then drawLaserBeam tL
   end repeat
end updateLasers

-- A thruster: a dynamic rocket body that drives itself. Each frame it applies a
-- continuous force along its own facing (b2kForce) and, when its ignition fires
-- on the first Run frame, a one-shot velocity pop (b2kPush); an optional spin
-- adds continuous torque (b2kTorque). Lock its rotation for a straight climb, or
-- leave it free to tumble.
function placeThruster pX, pY
   local tRef
   b2kSpawnBox pX, pY, 38, 56, "74,84,104"      -- a tall rocket body
   put the result into tRef
   set the uThrustDir of tRef to 270             -- thrust upward by default (lifts off)
   set the uThrustPower of tRef to 700
   set the uThrustSpin of tRef to 0
   set the uThrustLit of tRef to false
   tagPart tRef, "thruster", "74,84,104", empty
   return tRef
end placeThruster

-- Reset every thruster's ignition so a fresh Run pops it off the pad once.
on armThrusters
   local tT
   repeat for each line tT in gKindList["thruster"]
      if tT is not empty then set the uThrustLit of tT to false
   end repeat
end armThrusters

-- Drive every thruster each frame: ignition pop, then sustained thrust + spin.
on updateThrusters
   local tT, tRad, tPow
   repeat for each line tT in gKindList["thruster"]
      if tT is empty then next repeat
      put numOr(the uThrustPower of tT, 0) into tPow
      if tPow <= 0 then next repeat
      put (numOr(the uThrustDir of tT, 270) + b2kAngle(tT)) * kPI / 180 into tRad
      if the uThrustLit of tT is not true then    -- one-shot ignition kick
         b2kPush tT, 140 * cos(tRad), 140 * sin(tRad)
         set the uThrustLit of tT to true
      end if
      b2kForce tT, tPow * cos(tRad), tPow * sin(tRad)
      if numOr(the uThrustSpin of tT, 0) is not 0 then b2kTorque tT, (the uThrustSpin of tT)
   end repeat
end updateThrusters

-- Safety net: a body flung, blasted or thrust clean out of the arena (past a
-- generous margin) is pulled back to the edge with its speed killed, so nothing
-- is ever lost off-screen. CCD stops most tunnelling; this catches the rest.
on containParts
   local tP, tLoc, tX, tY, tNX, tNY
   set the itemDelimiter to comma
   repeat for each line tP in dynamicParts()
      if tP is empty then next repeat
      put the loc of tP into tLoc
      put item 1 of tLoc into tX
      put item 2 of tLoc into tY
      put tX into tNX
      put tY into tNY
      if tX < gArenaL - kContainMargin then put gArenaL + 12 into tNX
      else if tX > gArenaR + kContainMargin then put gArenaR - 12 into tNX
      if tY < gArenaT - kContainMargin then put gArenaT + 12 into tNY
      else if tY > gArenaB + kContainMargin then put gArenaB - 12 into tNY
      if tNX is not tX or tNY is not tY then
         b2kMoveTo tP, tNX, tNY, round(b2kAngle(tP))
         b2kSetVelocity tP, 0, 0
      end if
   end repeat
end containParts

-- Restore every saved per-part setting (common body props + per-kind extras).
on applyPartSpecial pCtrl, pSpecial
   if pCtrl is empty then exit applyPartSpecial
   local tKind, tV
   put the uKind of pCtrl into tKind
   if kindIsTerrain(tKind) then               -- restore grip + angle + facing, then redraw
      put specialValue(pSpecial, "fric") into tV
      if tV is not empty then set the uFriction of pCtrl to tV
      put specialValue(pSpecial, "tang") into tV
      if tV is empty then put 0 into tV
      set the uAngle of pCtrl to tV
      set the uFlip of pCtrl to (specialValue(pSpecial, "flip") is "true")
      regenTerrain pCtrl
      exit applyPartSpecial
   end if
   if kindHasBody(tKind) then
      put specialValue(pSpecial, "fric") into tV
      if tV is not empty then
         set the uFriction of pCtrl to tV
         b2kSetFriction pCtrl, tV
      end if
      put specialValue(pSpecial, "dens") into tV
      if tV is not empty then
         set the uDensity of pCtrl to tV
         b2kSetDensity pCtrl, tV
      end if
      put specialValue(pSpecial, "grav") into tV
      if tV is not empty then
         set the uGravity of pCtrl to tV
         b2kSetGravityScale pCtrl, tV
      end if
      if specialValue(pSpecial, "frot") is "true" then
         set the uFixedRot of pCtrl to true
         b2kSetFixedRotation pCtrl, true
      end if
      put specialValue(pSpecial, "btype") into tV
      if tV is "static" or tV is "kinematic" then
         set the uBodyType of pCtrl to tV
         b2kSetType pCtrl, tV
      end if
      put specialValue(pSpecial, "slp") into tV
      if tV is not empty then
         set the uSleep of pCtrl to tV
         b2kSetSleepThreshold pCtrl, tV
      end if
      if specialValue(pSpecial, "act") is "false" then
         set the uActive of pCtrl to false
         b2kDisable pCtrl
      end if
      put specialValue(pSpecial, "ldmp") into tV
      if tV is not empty then
         set the uLinDamp of pCtrl to tV
         b2kSetDamping pCtrl, tV, empty
      end if
      put specialValue(pSpecial, "admp") into tV
      if tV is not empty then
         set the uAngDamp of pCtrl to tV
         b2kSetDamping pCtrl, empty, tV
      end if
      if specialValue(pSpecial, "bul") is "true" then
         set the uBullet of pCtrl to true
         b2kSetBullet pCtrl, true
      end if
      put specialValue(pSpecial, "lspd") into tV
      if tV is not empty then set the uLaunchSpeed of pCtrl to tV
      put specialValue(pSpecial, "ldir") into tV
      if tV is not empty then set the uLaunchDir of pCtrl to tV
      put specialValue(pSpecial, "spin") into tV
      if tV is not empty then set the uSpinRate of pCtrl to tV
      put specialValue(pSpecial, "grp") into tV
      if tV is not empty then set the uGroup of pCtrl to tV
      put specialValue(pSpecial, "lyr") into tV
      if tV is not empty then
         set the uLayer of pCtrl to tV
         applyCollisionLayer pCtrl
      end if
      put specialValue(pSpecial, "cat") into tV
      if tV is not empty then set the uOnChans of pCtrl to tV
      put specialValue(pSpecial, "msk") into tV
      if tV is not empty then set the uHitChans of pCtrl to tV
      applyPartFilter pCtrl                  -- no-op unless cat/msk were set above
      put specialValue(pSpecial, "ang") into tV
      if tV is not empty and tV is not 0 then
         b2kMoveTo pCtrl, item 1 of the loc of pCtrl, item 2 of the loc of pCtrl, tV
      end if
   end if
   switch tKind
      case "fan"
         put specialValue(pSpecial, "dir") into tV
         if tV is not empty then set the uFanDir of pCtrl to tV
         put specialValue(pSpecial, "force") into tV
         if tV is not empty then set the uFanForce of pCtrl to tV
         put specialValue(pSpecial, "fscale") into tV
         if tV is not empty then set the uFanScale of pCtrl to tV
         drawFanShape pCtrl
         break
      case "magnet"
         put specialValue(pSpecial, "pol") into tV
         if tV is not empty then set the uMagPolarity of pCtrl to tV
         put specialValue(pSpecial, "force") into tV
         if tV is not empty then set the uMagForce of pCtrl to tV
         put specialValue(pSpecial, "range") into tV
         if tV is not empty then set the uMagRange of pCtrl to tV
         break
      case "bomb"
         put specialValue(pSpecial, "bradius") into tV
         if tV is not empty then set the uBlastRadius of pCtrl to tV
         put specialValue(pSpecial, "bpower") into tV
         if tV is not empty then set the uBlastPower of pCtrl to tV
         if specialValue(pSpecial, "fuse") is "true" then set the uFuseOnRun of pCtrl to true
         put specialValue(pSpecial, "flen") into tV
         if tV is not empty then set the uFuseLen of pCtrl to tV
         if specialValue(pSpecial, "soft") is "true" then set the uSoftBlast of pCtrl to true
         break
      case "laser"
         put specialValue(pSpecial, "ldr") into tV
         if tV is not empty then set the uLaserDir of pCtrl to tV
         drawLaserBeam pCtrl
         break
      case "thruster"
         put specialValue(pSpecial, "tdr") into tV
         if tV is not empty then set the uThrustDir of pCtrl to tV
         put specialValue(pSpecial, "tpw") into tV
         if tV is not empty then set the uThrustPower of pCtrl to tV
         put specialValue(pSpecial, "tsp") into tV
         if tV is not empty then set the uThrustSpin of pCtrl to tV
         set the uThrustLit of pCtrl to false
         break
   end switch
   if tKind is "draw" then                       -- restore a freehand-drawn ground mass + its chain
      put specialValue(pSpecial, "pts") into tV
      if tV is not empty then
         replace "|" with cr in tV
         set the points of pCtrl to tV
         b2kAddChain pCtrl, tV, true             -- closed loop, same as when it was drawn
      end if
   end if
   -- Restore a chosen image collision shape and/or the sensor (trigger-zone) flag.
   -- Both end in a reshape, so set the flags first and reshape ONCE: the rebuilt
   -- shape picks up the new outline (image) and the sensor state, then the
   -- material and collision layer (which a reshape resets) are re-applied.
   local tReshape
   put false into tReshape
   if tKind is "image" then
      put specialValue(pSpecial, "ishp") into tV
      if tV is not empty then
         set the uShape of pCtrl to tV
         put true into tReshape
      end if
   end if
   if specialValue(pSpecial, "sen") is "true" then
      set the uSensor of pCtrl to true
      b2kSetSensor pCtrl, true
      put true into tReshape
   end if
   if tReshape then
      b2kReshape pCtrl, partShape(pCtrl)
      reapplyMaterial pCtrl
      reapplyCollision pCtrl
      applySensorLook pCtrl
   end if
end applyPartSpecial

-- =====================================================================
-- Special-object behaviour, run each frame from on b2kFrame.
-- =====================================================================

-- Fans and magnets push the dynamic parts in/near them. The candidate part
-- list is cached (dynamicParts) so this stays cheap as the scene grows.
on applyFieldForces
   local tFans, tMags, tParts, tP, tPx, tPy, tF, tM
   put gKindList["fan"] into tFans
   put gKindList["magnet"] into tMags
   if tFans is empty and tMags is empty then exit applyFieldForces
   put dynamicParts() into tParts
   if tParts is empty then exit applyFieldForces
   repeat for each line tP in tParts
      if tP is empty then next repeat
      put item 1 of the loc of tP into tPx
      put item 2 of the loc of tP into tPy
      repeat for each line tF in tFans
         if tF is not empty and ptInRect(tF, tPx, tPy) then applyFan tF, tP
      end repeat
      repeat for each line tM in tMags
         if tM is not empty then applyMagnet tM, tP, tPx, tPy
      end repeat
   end repeat
end applyFieldForces

function ptInRect pZone, pX, pY
   local tR
   put the rect of pZone into tR
   return pX >= item 1 of tR and pX <= item 3 of tR and pY >= item 2 of tR and pY <= item 4 of tR
end ptInRect

on applyFan pFan, pPart
   local tForce, tFx, tFy
   put the uFanForce of pFan into tForce
   put 0 into tFx
   put 0 into tFy
   switch the uFanDir of pFan
      case 0
         put tForce into tFx
         break
      case 90
         put tForce into tFy
         break
      case 180
         put -tForce into tFx
         break
      default
         put -tForce into tFy
   end switch
   b2kForce pPart, tFx, tFy
end applyFan

on applyMagnet pMag, pPart, pPx, pPy
   local tMx, tMy, tdx, tdy, tDist, tRange, tPull, tFx, tFy
   put item 1 of the loc of pMag into tMx
   put item 2 of the loc of pMag into tMy
   put the uMagRange of pMag into tRange
   put tMx - pPx into tdx
   put tMy - pPy into tdy
   put sqrt(tdx * tdx + tdy * tdy) into tDist
   if tDist > tRange then exit applyMagnet
   if tDist < kMagnetMinDist then put kMagnetMinDist into tDist
   put (the uMagPolarity of pMag) * (the uMagForce of pMag) * (1 - tDist / tRange) into tPull
   put tPull * tdx / tDist into tFx
   put tPull * tdy / tDist into tFy
   b2kForce pPart, tFx, tFy
end applyMagnet

-- Bombs: light the fuse on Run for any armed for it, then tick all fuses down.
on armFuses
   local tB
   repeat for each line tB in gKindList["bomb"]
      if tB is not empty and the uFuseOnRun of tB is true then set the uFuse of tB to numOr(the uFuseLen of tB, kBombFuseFrames)
   end repeat
end armFuses

on updateBombs
   local tB, tFuse, tBlow
   put empty into tBlow
   repeat for each line tB in gKindList["bomb"]
      if tB is empty then next repeat
      put the uFuse of tB into tFuse
      if tFuse is empty or tFuse <= 0 then next repeat
      subtract 1 from tFuse
      set the uFuse of tB to tFuse
      if tFuse < 28 then
         try
            if (tFuse mod 6) < 3 then set the backgroundColor of tB to "245,80,55"
            else set the backgroundColor of tB to "150,40,40"
         end try
      end if
      if tFuse <= 0 then put tB & cr after tBlow
   end repeat
   repeat for each line tB in tBlow
      detonateBomb tB
   end repeat
end updateBombs

on detonateBomb pBomb
   if pBomb is empty then exit detonateBomb
   if pBomb is not among the lines of gParts then exit detonateBomb   -- already gone
   local tLx, tLy, tRad, tPow
   put item 1 of the loc of pBomb into tLx
   put item 2 of the loc of pBomb into tLy
   put the uBlastRadius of pBomb into tRad
   if tRad is empty then put kBombRadius into tRad
   put the uBlastPower of pBomb into tPow
   if tPow is empty then put kBombPower into tPow
   if the uSoftBlast of pBomb is true then b2kExplodeLegacy tLx, tLy, tRad, tPow   -- old velocity-based feel
   else b2kExplode tLx, tLy, tRad, tPow                                             -- shape-aware native blast
   spawnRing tLx, tLy
   popBalloonsNear tLx, tLy, tRad
   deletePart pBomb
end detonateBomb

-- Any balloon caught in a blast pops (a little ring, then it is removed).
on popBalloonsNear pX, pY, pRadius
   local tBalloon, tBx, tBy, tdx, tdy, tPop, tR2
   put pRadius * pRadius into tR2
   put empty into tPop
   repeat for each line tBalloon in gKindList["balloon"]
      if tBalloon is empty then next repeat
      put item 1 of the loc of tBalloon into tBx
      put item 2 of the loc of tBalloon into tBy
      put tBx - pX into tdx
      put tBy - pY into tdy
      if tdx * tdx + tdy * tdy <= tR2 then put tBalloon & cr after tPop
   end repeat
   repeat for each line tBalloon in tPop
      spawnRing (item 1 of the loc of tBalloon), (item 2 of the loc of tBalloon)
      deletePart tBalloon
   end repeat
end popBalloonsNear

-- An expanding shock ring (purely decorative), ported from the showcase demo.
on spawnRing pX, pY
   add 1 to gRingN
   put pX into gRingX[gRingN]
   put pY into gRingY[gRingN]
   put 0 into gRingF[gRingN]
   create graphic ("cb_ring_" & gRingN)
   set the style of graphic ("cb_ring_" & gRingN) to "oval"
   set the filled of graphic ("cb_ring_" & gRingN) to false
   set the lineSize of graphic ("cb_ring_" & gRingN) to 3
   set the foregroundColor of graphic ("cb_ring_" & gRingN) to "255,170,70"
end spawnRing

on updateRings
   local tI, tName, tFrame, tRad
   if gRingN < 1 then exit updateRings
   repeat with tI = 1 to gRingN
      if gRingF[tI] is empty then next repeat
      put "cb_ring_" & tI into tName
      put gRingF[tI] + 1 into tFrame
      put tFrame into gRingF[tI]
      if tFrame > 16 then
         if there is a graphic tName then delete graphic tName
         put empty into gRingF[tI]
         next repeat
      end if
      put tFrame * 13 into tRad
      if there is a graphic tName then
         set the rect of graphic tName to (gRingX[tI] - tRad), (gRingY[tI] - tRad), (gRingX[tI] + tRad), (gRingY[tI] + tRad)
         set the lineSize of graphic tName to max(1, 5 - (tFrame div 4))
      end if
   end repeat
end updateRings

-- =====================================================================
-- Pressure plates: count resting bodies; on first press, fire the signal.
-- =====================================================================
on plateTouch pPlate, pOther, pDelta
   if pPlate is empty or pOther is empty then exit plateTouch
   if the uKind of pPlate is not "plate" then exit plateTouch
   if b2kBodyType(pOther) is not "dynamic" then exit plateTouch
   local tLoad
   put gPlateLoad[pPlate] + pDelta into tLoad
   if tLoad < 0 then put 0 into tLoad
   put tLoad into gPlateLoad[pPlate]
   if tLoad >= 1 and gPlateState[pPlate] is "up" then platePressed pPlate
   else if tLoad <= 0 and gPlateState[pPlate] is "down" then plateReleased pPlate
end plateTouch

on platePressed pPlate
   put "down" into gPlateState[pPlate]
   try
      set the backgroundColor of pPlate to "120,230,140"
   end try
   put "A pressure plate fired its signal!" into gStatus
   fireEmitter pPlate
   updateHud
end platePressed

on plateReleased pPlate
   put "up" into gPlateState[pPlate]
   try
      set the backgroundColor of pPlate to "150,160,180"
   end try
end plateReleased

-- The plate's signal: arm every bomb (it detonates next frame, safely outside
-- the contact callback) and flip all motors between running and stopped.
on triggerSignal
   local tB
   repeat for each line tB in gKindList["bomb"]
      if tB is not empty then set the uFuse of tB to 1
   end repeat
   toggleAllMotors
end triggerSignal

-- =====================================================================
-- Signal wiring: the Link tool connects a trigger (pressure plate / sensor)
-- to a target (a bomb). A trigger fires ONLY its wired targets; an unwired
-- trigger keeps the old "fire everything" behaviour so it still does something.
-- =====================================================================
function isEmitter pCtrl
   if pCtrl is empty then return false
   return (the uKind of pCtrl is "plate") or (the uKind of pCtrl is "sensor")
end isEmitter

function isReceiver pCtrl
   if pCtrl is empty then return false
   return the uKind of pCtrl is "bomb"
end isReceiver

function nameOf pCtrl
   if pCtrl is empty then return "?"
   if the uPartName of pCtrl is not empty then return the uPartName of pCtrl
   return niceName(the uKind of pCtrl)
end nameOf

-- A click with the Link tool: first pick a trigger, then pick its target.
on handleLinkClick pHit
   if pHit is empty then
      put empty into gWireSrc
      put "Link: click a trigger (a pressure plate or a sensor) to start a wire." into gStatus
      renderBuild
      updateHud
      exit handleLinkClick
   end if
   if gWireSrc is empty then
      if not isEmitter(pHit) then
         put "Wires start at a pressure plate or a sensor. Click one." into gStatus
         updateHud
         exit handleLinkClick
      end if
      put pHit into gWireSrc
      put "Wiring from " & nameOf(pHit) & " — now click a bomb to set off." into gStatus
   else
      if pHit is gWireSrc then
         put empty into gWireSrc
         put "Wire cancelled." into gStatus
      else if not isReceiver(pHit) then
         put "Wire to a bomb (the thing the trigger should set off)." into gStatus
      else
         addWire gWireSrc, pHit
         put "Wired " & nameOf(gWireSrc) & " to " & nameOf(pHit) & "." into gStatus
         put empty into gWireSrc
      end if
   end if
   renderBuild
   updateHud
end handleLinkClick

-- Record a wire (deduped). Edges are "srcCtrl<tab>tgtCtrl" long ids.
on addWire pSrc, pTgt
   if pSrc is empty or pTgt is empty then exit addWire
   local tEdge
   put pSrc & tab & pTgt into tEdge
   if tEdge is among the lines of gWires then exit addWire
   put tEdge & cr after gWires
   if the last char of gWires is return then delete the last char of gWires
end addWire

-- Drop every wire touching a part (called when the part is deleted).
on removeWiresFor pCtrl
   if gWires is empty then exit removeWiresFor
   local tEdge, tKept
   set the itemDelimiter to tab
   put empty into tKept
   repeat for each line tEdge in gWires
      if item 1 of tEdge is pCtrl or item 2 of tEdge is pCtrl then next repeat
      put tEdge & cr after tKept
   end repeat
   if the last char of tKept is return then delete the last char of tKept
   put tKept into gWires
end removeWiresFor

-- A trigger fired: set off its wired targets, or — if it has none — fall back to
-- the legacy global signal so an unwired plate/sensor still does something.
on fireEmitter pEmitter
   local tEdge, tTgt, tFired
   put false into tFired
   set the itemDelimiter to tab
   repeat for each line tEdge in gWires
      if item 1 of tEdge is pEmitter then
         put item 2 of tEdge into tTgt
         if tTgt is not empty and tTgt is among the lines of gParts then
            fireTarget tTgt
            put true into tFired
         end if
      end if
   end repeat
   if not tFired then triggerSignal
end fireEmitter

-- Set off one wired target by kind.
on fireTarget pTgt
   switch the uKind of pTgt
      case "bomb"
         set the uFuse of pTgt to 1          -- detonate next frame, safely outside the contact callback
         break
   end switch
end fireTarget

-- Redraw the signal wires as amber connector lines between parts (build mode).
on drawWires
   deleteByPrefix "cb_wire_"
   if gWires is empty then exit drawWires
   local tEdge, tSrc, tTgt, tN, tName, tRef, tx0, ty0, tx1, ty1
   put 0 into tN
   repeat for each line tEdge in gWires
      set the itemDelimiter to tab
      put item 1 of tEdge into tSrc
      put item 2 of tEdge into tTgt
      if tSrc is empty or tTgt is empty then next repeat
      if tSrc is not among the lines of gParts or tTgt is not among the lines of gParts then next repeat
      set the itemDelimiter to comma
      put item 1 of the loc of tSrc into tx0
      put item 2 of the loc of tSrc into ty0
      put item 1 of the loc of tTgt into tx1
      put item 2 of the loc of tTgt into ty1
      add 1 to tN
      put "cb_wire_" & tN into tName
      create graphic tName
      put the long id of graphic tName into tRef
      set the style of tRef to "line"
      set the lineSize of tRef to 2
      set the foregroundColor of tRef to "232,200,72"
      set the points of tRef to round(tx0) & "," & round(ty0) & cr & round(tx1) & "," & round(ty1)
   end repeat
end drawWires

on toggleAllMotors
   local tI, tSpeed
   put not gMotorsRunning into gMotorsRunning
   if gJN < 1 then exit toggleAllMotors
   repeat with tI = 1 to gJN
      if gJKind[tI] is empty then next repeat
      if gJMotor[tI] is empty or gJMotor[tI] is 0 then next repeat
      if gMotorsRunning then put gJMotor[tI] into tSpeed
      else put 0 into tSpeed
      if gJKind[tI] is "hinge" then b2kMotor gJHandle[tI], tSpeed, kHingeTorque
      else if gJKind[tI] is "wheel" then b2kWheelMotor gJHandle[tI], tSpeed, kWheelTorque
   end repeat
end toggleAllMotors

-- Push every joint's designed motor state (from its marker) onto the live joint.
-- Joints persist across Build<->Run, and a pressure plate can flip motors off
-- mid-run via toggleAllMotors, so each Run re-applies the design — otherwise a
-- plate that killed a motor would leave it dead after the next Build/Run.
on armMotors
   local tI
   if gJN < 1 then exit armMotors
   repeat with tI = 1 to gJN
      if gJKind[tI] is empty then next repeat   -- removed joint: marker is gone
      applyJointMotor tI
   end repeat
end armMotors

-- A bomb hit hard enough arms a one-frame fuse (so it blows outside the callback).
on bombImpactCheck pCtrl
   if pCtrl is empty then exit bombImpactCheck
   if the uKind of pCtrl is not "bomb" then exit bombImpactCheck
   if the uFuse of pCtrl is not empty and the uFuse of pCtrl > 0 then exit bombImpactCheck
   if b2kSpeed(pCtrl) >= kBombImpactSpeed then set the uFuse of pCtrl to 1
end bombImpactCheck

-- =====================================================================
-- Scene-state reset (called on start, clear and teardown)
-- =====================================================================
on resetSceneState
   put empty into gKindList
   put empty into gPlateLoad
   put empty into gPlateState
   put empty into gSensorCount
   put empty into gDynParts
   put true into gDynDirty
   put 0 into gRingN
   put empty into gRingX
   put empty into gRingY
   put empty into gRingF
   put empty into gNameCount
   put empty into gWires
   put empty into gWireSrc
   deleteByPrefix "cb_ring_"
   deleteByPrefix "cb_wire_"
end resetSceneState

on deleteByPrefix pPrefix
   local tI, tName
   repeat with tI = the number of controls of this card down to 1
      put the short name of control tI of this card into tName
      if offset(pPrefix, tName) is 1 then delete control tI of this card
   end repeat
end deleteByPrefix

-- =====================================================================
-- Inspector + selection (plain-language help, live property tweaks)
-- =====================================================================
on selectPart pCtrl
   if pCtrl is empty then exit selectPart
   deselectPart
   deselectJoint
   put pCtrl into gSelPart
   try
      set the uSelFg of pCtrl to the foregroundColor of pCtrl
      set the uSelLine of pCtrl to the lineSize of pCtrl
      set the foregroundColor of pCtrl to "255,255,255"
      set the lineSize of pCtrl to kSelectLine
   end try
   showPartInspector pCtrl
end selectPart

on deselectPart
   if gSelPart is empty then exit deselectPart
   try
      set the foregroundColor of gSelPart to the uSelFg of gSelPart
      set the lineSize of gSelPart to the uSelLine of gSelPart
   end try
   put empty into gSelPart
   clearPropRows
end deselectPart

-- Show the active tool's plain-language help when nothing is selected.
on showInspectorForTool
   local tId
   if gJointTool is not empty then put gJointTool into tId
   else put gTool into tId
   setInspector niceName(tId), (line 2 of toolHelp(tId))
   clearPropRows
end showInspectorForTool

-- Preview a hovered tool's help without disturbing the current selection.
on hoverHelp pId
   setInspector niceName(pId), (line 2 of toolHelp(pId))
end hoverHelp

on restoreInspector
   if gSelJoint is not empty then showJointInspector gSelJoint
   else if gSelPart is not empty then showPartInspector gSelPart
   else showInspectorForTool
end restoreInspector

on setInspector pTitle, pBody
   if there is a field "ui_insp_title" then put pTitle into field "ui_insp_title"
   if there is a field "ui_insp_body" then put pBody into field "ui_insp_body"
end setInspector

-- Rename the selected part. Names label wires and (later) puzzle goals.
on renamePart pCtrl
   if pCtrl is empty or pCtrl is not among the lines of gParts then
      put "Select a part first, then press Rename." into gStatus
      updateHud
      exit renamePart
   end if
   ask "Name this part:" with (the uPartName of pCtrl)
   if it is empty or the result is "Cancel" then exit renamePart
   local tNm
   put it into tNm
   replace tab with space in tNm          -- names are tab-delimited in saves
   replace return with space in tNm
   set the uPartName of pCtrl to tNm
   showPartInspector pCtrl                 -- refresh the title
   put "Renamed to " & quote & tNm & quote & "." into gStatus
   updateHud
end renamePart

-- Show a selected part's name, what it does, and the values you can change.
on showPartInspector pCtrl
   if pCtrl is empty then exit showPartInspector
   local tKind, tKey, tRow, tAvail
   put the uKind of pCtrl into tKind
   local tNm
   put the uPartName of pCtrl into tNm
   if tNm is empty then put niceName(tKind) into tNm
   setInspector ("Selected: " & tNm), (line 2 of toolHelp(tKind))
   clearPropRows
   put partTabs(tKind) into tAvail
   if tAvail is empty then
      setSettingsHint "This part has no adjustable settings."
      exit showPartInspector
   end if
   set the itemDelimiter to comma
   if gInspTab is not among the items of tAvail then put item 1 of tAvail into gInspTab
   refreshInspTabs tAvail
   put 0 into tRow
   repeat for each item tKey in partProps(tKind)
      if propGroup(tKey) is not gInspTab then next repeat
      add 1 to tRow
      if tRow > kPropRows then exit repeat
      showPropRow tRow, propLabel(pCtrl, tKey), tKey
   end repeat
   if tRow > 0 then setSettingsHint empty           -- rows are showing; hide the prompt
   else setSettingsHint "Nothing to adjust on this tab."
   if tKind is "bomb" then setSettingsHint blastPreviewText(pCtrl)   -- live "what it would hit"
end showPartInspector

-- A live preview of a bomb's reach: how many parts currently sit inside its blast
-- radius, found with the Kit's region query b2kOverlapCircle. Refreshes whenever
-- the bomb is selected or its radius is nudged.
function blastPreviewText pBomb
   local tCx, tCy, tR, tP, tN, tPlural
   set the itemDelimiter to comma
   put item 1 of the loc of pBomb into tCx
   put item 2 of the loc of pBomb into tCy
   put numOr(the uBlastRadius of pBomb, kBombRadius) into tR
   put 0 into tN
   repeat for each line tP in b2kOverlapCircle(tCx, tCy, tR)
      if tP is not empty and tP is not pBomb then add 1 to tN
   end repeat
   if tN is 1 then put "part" into tPlural
   else put "parts" into tPlural
   return "Blast radius " & tR & " px — reaches " & tN && tPlural & " right now."
end blastPreviewText

-- The ordered list of adjustable settings shown for each kind of part.
function partProps pKind
   switch pKind
      case "box"
         return "width,height,color,angle,bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material,layer,sensor,filter,active,sleep,launchspeed,launchdir,spinrate"
      case "image"
         return "width,height,imgshape,angle,bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material,layer,sensor,filter,active,sleep,launchspeed,launchdir,spinrate"
      case "ball"
         return "diameter,color,bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material,layer,sensor,filter,active,sleep,launchspeed,launchdir,spinrate"
      case "capsule"
         return "length,thickness,color,angle,bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material,layer,sensor,filter,active,sleep,launchspeed,launchdir,spinrate"
      case "poly"
         return "size,color,angle,bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material,layer,sensor,filter,active,sleep,launchspeed,launchdir,spinrate"
      case "balloon"
         return "diameter,color,bounce,density,friction,gravity"
      case "bomb"
         return "diameter,color,bounce,density,blastradius,blastpower,bombfuse,bombfuselen,bombsoft"
      case "plate"
         return "width,height,color,angle,friction"
      case "sensor"
         return "width,height,color"
      case "draw"
         return "color"
      case "anchor"
         return "width,height,color,bounce,friction"
      case "ramp"
         return "width,height,angle,facing,friction,color"
      case "platform"
      case "hill"
         return "width,height,angle,friction,color"
      case "fan"
         return "fandir,fanforce,fansize,color"
      case "magnet"
         return "magpol,magforce,magrange,color"
      case "laser"
         return "laserdir"
      case "thruster"
         return "width,height,color,angle,bounce,density,friction,gravity,fixedrot,bodytype,material,layer,thrustdir,thrustpower,thrustspin"
   end switch
   return empty
end partProps

-- The human-readable "Name: value" shown on a property row.
function propLabel pCtrl, pKey
   switch pKey
      case "size"
         return "Size: " & (the width of pCtrl) & " px"
      case "width"
         return "Width: " & numOr(the uW of pCtrl, the width of pCtrl) & " px"
      case "height"
         return "Height: " & numOr(the uH of pCtrl, the height of pCtrl) & " px"
      case "length"
         return "Length: " & numOr(the uW of pCtrl, the width of pCtrl) & " px"
      case "thickness"
         return "Thickness: " & numOr(the uH of pCtrl, the height of pCtrl) & " px"
      case "diameter"
         return "Diameter: " & numOr(the uW of pCtrl, the width of pCtrl) & " px"
      case "angle"
         if kindIsTerrain(the uKind of pCtrl) then return "Angle: " & numOr(the uAngle of pCtrl, 0) & " deg"
         return "Angle: " & round(b2kAngle(pCtrl)) & " deg"
      case "facing"
         if the uFlip of pCtrl is true then return "Facing: high on the left"
         return "Facing: high on the right"
      case "color"
         return "Colour (cycle with +/−)"
      case "bounce"
         return "Bounciness: " & bounceLabel(the uBounce of pCtrl)
      case "density"
         return "Weight: " & weightLabel(pCtrl)
      case "friction"
         return "Grip: " & frictionLabel(the uFriction of pCtrl)
      case "gravity"
         return "Gravity: " & gravityLabel(the uGravity of pCtrl)
      case "fixedrot"
         if the uFixedRot of pCtrl is true then return "Spin: locked"
         return "Spin: free to rotate"
      case "bodytype"
         if the uBodyType of pCtrl is "static" then return "Movement: fixed in place"
         if the uBodyType of pCtrl is "kinematic" then return "Movement: moving platform (kinematic)"
         return "Movement: free-moving"
      case "lindamp"
         return "Air drag (move): " & numOr(the uLinDamp of pCtrl, 0)
      case "angdamp"
         return "Air drag (spin): " & numOr(the uAngDamp of pCtrl, 0)
      case "bullet"
         return "Fast-collision: " & yesNo(the uBullet of pCtrl is true)
      case "material"
         return "Material: " & materialNameOf(pCtrl)
      case "layer"
         if numOr(the uLayer of pCtrl, 0) is 0 then return "Collision layer: 0 (hits everything)"
         return "Collision layer: " & (the uLayer of pCtrl) & " (same-layer parts pass through)"
      case "sleep"
         if numOr(the uSleep of pCtrl, 0) is 0 then return "Sleep: never (stays active)"
         return "Sleeps below: " & (the uSleep of pCtrl) & " px/s"
      case "imgshape"
         return "Collision shape: " & numOr(the uShape of pCtrl, "box")
      case "active"
         if the uActive of pCtrl is false then return "In simulation: no (disabled)"
         return "In simulation: yes"
      case "sensor"
         if the uSensor of pCtrl is true then return "Trigger zone (non-solid): yes"
         return "Trigger zone (non-solid): no"
      case "filter"
         return "Collision filter: " & filterSummary(pCtrl)
      case "launchspeed"
         return "Launch speed: " & numOr(the uLaunchSpeed of pCtrl, 0) & " px/s"
      case "launchdir"
         return "Launch angle: " & numOr(the uLaunchDir of pCtrl, 0) & " deg"
      case "spinrate"
         return "Launch spin: " & numOr(the uSpinRate of pCtrl, 0) & " deg/s"
      case "blastradius"
         return "Blast size: " & (the uBlastRadius of pCtrl)
      case "blastpower"
         return "Blast power: " & (the uBlastPower of pCtrl)
      case "bombfuse"
         return "Light fuse on Run: " & yesNo(the uFuseOnRun of pCtrl)
      case "bombfuselen"
         return "Fuse length: " & format("%.1f", numOr(the uFuseLen of pCtrl, kBombFuseFrames) / 60) & " s"
      case "bombsoft"
         if the uSoftBlast of pCtrl is true then return "Blast style: soft (legacy, size-blind)"
         return "Blast style: shape-aware (native)"
      case "fandir"
         return "Direction: " & dirName(the uFanDir of pCtrl)
      case "fanforce"
         return "Strength: " & (the uFanForce of pCtrl)
      case "fansize"
         return "Zone size: " & sizeLabel(the uFanScale of pCtrl)
      case "magpol"
         return "Mode: " & magName(the uMagPolarity of pCtrl)
      case "magforce"
         return "Strength: " & (the uMagForce of pCtrl)
      case "magrange"
         return "Reach: " & (the uMagRange of pCtrl)
      case "laserdir"
         return "Beam angle: " & numOr(the uLaserDir of pCtrl, 0) & "°"
      case "thrustdir"
         return "Thrust angle: " & numOr(the uThrustDir of pCtrl, 270) & "°"
      case "thrustpower"
         return "Thrust power: " & numOr(the uThrustPower of pCtrl, 0)
      case "thrustspin"
         return "Thrust spin: " & numOr(the uThrustSpin of pCtrl, 0)
   end switch
   return pKey
end propLabel

on clearPropRows
   local tI
   repeat with tI = 1 to kPropRows
      hidePropRow tI
   end repeat
   hideInspTabs
   setSettingsHint "Select a part on the stage to adjust its settings here."
end clearPropRows

on hidePropRow pRow
   if there is a field ("ui_prop_lbl_" & pRow) then set the visible of field ("ui_prop_lbl_" & pRow) to false
   if there is a button ("ui_act_prop_dec_" & pRow) then set the visible of button ("ui_act_prop_dec_" & pRow) to false
   if there is a button ("ui_act_prop_inc_" & pRow) then set the visible of button ("ui_act_prop_inc_" & pRow) to false
end hidePropRow

on showPropRow pRow, pLabel, pKey
   if there is a field ("ui_prop_lbl_" & pRow) then
      put pLabel into field ("ui_prop_lbl_" & pRow)
      set the uPropKey of field ("ui_prop_lbl_" & pRow) to pKey
      set the visible of field ("ui_prop_lbl_" & pRow) to true
   end if
   if there is a button ("ui_act_prop_dec_" & pRow) then
      set the uPropKey of button ("ui_act_prop_dec_" & pRow) to pKey
      set the visible of button ("ui_act_prop_dec_" & pRow) to true
   end if
   if there is a button ("ui_act_prop_inc_" & pRow) then
      set the uPropKey of button ("ui_act_prop_inc_" & pRow) to pKey
      set the visible of button ("ui_act_prop_inc_" & pRow) to true
   end if
end showPropRow

-- A +/- click on an inspector property row.
on adjustProp pId
   local tDir
   if char 6 to 8 of pId is "inc" then put 1 into tDir
   else put -1 into tDir
   if gSelJoint is not empty then
      adjustJointProp gSelJoint, (the uPropKey of the target), tDir
      showJointInspector gSelJoint
      exit adjustProp
   end if
   if gSelPart is empty then exit adjustProp
   adjustPartProp gSelPart, (the uPropKey of the target), tDir
   showPartInspector gSelPart
   if gMode is "build" then renderBuild
end adjustProp

on adjustPartProp pCtrl, pKey, pDir
   local tB, tD, tF, tNewDir, tMf, tMr, tFr, tG, tBr, tPow, tFs, tIdx, tPal, tCnt, tLd, tAd, tLs, tSr
   switch pKey
      case "size"
         if pDir > 0 then resizePart pCtrl, 1.15
         else resizePart pCtrl, 0.87
         break
      case "width"
         if kindIsTerrain(the uKind of pCtrl) then
            setPartDimension pCtrl, "w", numOr(the uW of pCtrl, 120) + pDir * kDimStep
         else
            setPartDimension pCtrl, "w", (the width of pCtrl) + pDir * kDimStep
         end if
         break
      case "height"
         if kindIsTerrain(the uKind of pCtrl) then
            setPartDimension pCtrl, "h", numOr(the uH of pCtrl, 26) + pDir * kDimStep
         else
            setPartDimension pCtrl, "h", (the height of pCtrl) + pDir * kDimStep
         end if
         break
      case "length"
         setPartDimension pCtrl, "w", (the width of pCtrl) + pDir * kDimStep
         break
      case "thickness"
         setPartDimension pCtrl, "h", (the height of pCtrl) + pDir * kDimStep
         break
      case "diameter"
         setPartDimension pCtrl, "d", (the width of pCtrl) + pDir * kDimStep
         break
      case "angle"
         if kindIsTerrain(the uKind of pCtrl) then
            setPartAngle pCtrl, numOr(the uAngle of pCtrl, 0) + pDir * 15
         else
            setPartAngle pCtrl, round(b2kAngle(pCtrl)) + pDir * 15
         end if
         break
      case "facing"
         set the uFlip of pCtrl to not (the uFlip of pCtrl is true)
         regenTerrain pCtrl
         break
      case "color"
         put partSwatches() into tPal
         put the number of lines of tPal into tCnt
         put swatchIndexOf(pCtrl, tPal) + pDir into tIdx
         if tIdx < 1 then put tCnt into tIdx
         if tIdx > tCnt then put 1 into tIdx
         set the backgroundColor of pCtrl to (line tIdx of tPal)
         set the uColor of pCtrl to (line tIdx of tPal)
         break
      case "bounce"
         put (the uBounce of pCtrl) + pDir * 0.15 into tB
         if tB < 0 then put 0 into tB
         if tB > 0.9 then put 0.9 into tB
         set the uBounce of pCtrl to tB
         b2kSetBounce pCtrl, tB
         break
      case "density"
         put the uDensity of pCtrl into tD
         if tD is empty then put 1 into tD
         put tD + pDir * 0.3 into tD
         if tD < 0.3 then put 0.3 into tD
         if tD > 3 then put 3 into tD
         set the uDensity of pCtrl to tD
         b2kSetDensity pCtrl, tD
         break
      case "friction"
         put the uFriction of pCtrl into tFr
         if tFr is empty then put 0.4 into tFr
         put tFr + pDir * 0.2 into tFr
         if tFr < 0 then put 0 into tFr
         if tFr > 2 then put 2 into tFr
         set the uFriction of pCtrl to tFr
         b2kSetFriction pCtrl, tFr
         break
      case "gravity"
         put the uGravity of pCtrl into tG
         if tG is empty then put 1 into tG
         put tG + pDir * 0.25 into tG
         if tG < -2 then put -2 into tG
         if tG > 3 then put 3 into tG
         set the uGravity of pCtrl to tG
         b2kSetGravityScale pCtrl, tG
         break
      case "fixedrot"
         set the uFixedRot of pCtrl to not (the uFixedRot of pCtrl is true)
         b2kSetFixedRotation pCtrl, (the uFixedRot of pCtrl is true)
         break
      case "bodytype"
         switch the uBodyType of pCtrl       -- cycle dynamic -> static -> kinematic
            case "static"
               set the uBodyType of pCtrl to "kinematic"
               break
            case "kinematic"
               set the uBodyType of pCtrl to "dynamic"
               break
            default
               set the uBodyType of pCtrl to "static"
         end switch
         b2kSetType pCtrl, (the uBodyType of pCtrl)
         break
      case "lindamp"
         put the uLinDamp of pCtrl into tLd
         if tLd is empty then put 0 into tLd
         put tLd + pDir * 0.25 into tLd
         if tLd < 0 then put 0 into tLd
         if tLd > 5 then put 5 into tLd
         set the uLinDamp of pCtrl to tLd
         b2kSetDamping pCtrl, tLd, empty
         break
      case "angdamp"
         put the uAngDamp of pCtrl into tAd
         if tAd is empty then put 0 into tAd
         put tAd + pDir * 0.25 into tAd
         if tAd < 0 then put 0 into tAd
         if tAd > 5 then put 5 into tAd
         set the uAngDamp of pCtrl to tAd
         b2kSetDamping pCtrl, empty, tAd
         break
      case "bullet"
         set the uBullet of pCtrl to not (the uBullet of pCtrl is true)
         b2kSetBullet pCtrl, (the uBullet of pCtrl is true)
         break
      case "material"
         cycleMaterial pCtrl, pDir
         break
      case "layer"
         set the uLayer of pCtrl to clampRange(numOr(the uLayer of pCtrl, 0) + pDir, 0, 8)
         applyCollisionLayer pCtrl
         break
      case "sleep"
         set the uSleep of pCtrl to clampRange(numOr(the uSleep of pCtrl, 0) + pDir * 10, 0, 200)
         b2kSetSleepThreshold pCtrl, numOr(the uSleep of pCtrl, 0)
         break
      case "imgshape"
         set the itemDelimiter to comma
         put "box,ball,capsule" into tPal
         put itemOffset(numOr(the uShape of pCtrl, "box"), tPal) + pDir into tIdx
         if tIdx < 1 then put the number of items of tPal into tIdx
         if tIdx > the number of items of tPal then put 1 into tIdx
         set the uShape of pCtrl to item tIdx of tPal
         b2kReshape pCtrl, (the uShape of pCtrl)
         reapplyMaterial pCtrl
         reapplyCollision pCtrl             -- reshape resets the filter; restore layer + channels
         break
      case "active"
         if the uActive of pCtrl is false then
            set the uActive of pCtrl to true
            b2kEnable pCtrl
         else
            set the uActive of pCtrl to false
            b2kDisable pCtrl
         end if
         break
      case "sensor"
         set the uSensor of pCtrl to (the uSensor of pCtrl is not true)
         b2kSetSensor pCtrl, (the uSensor of pCtrl is true)
         b2kReshape pCtrl, partShape(pCtrl)
         reapplyMaterial pCtrl
         reapplyCollision pCtrl             -- reshape resets the filter; restore layer + channels
         applySensorLook pCtrl
         break
      case "filter"
         openFilterPanel pCtrl              -- a set of channels needs the popup, not a stepper
         break
      case "launchspeed"
         put numOr(the uLaunchSpeed of pCtrl, 0) + pDir * 50 into tLs
         set the uLaunchSpeed of pCtrl to clampRange(tLs, 0, 1500)
         break
      case "launchdir"
         set the uLaunchDir of pCtrl to ((numOr(the uLaunchDir of pCtrl, 0) + pDir * 15 + 360) mod 360)
         break
      case "spinrate"
         put numOr(the uSpinRate of pCtrl, 0) + pDir * 45 into tSr
         set the uSpinRate of pCtrl to clampRange(tSr, -720, 720)
         break
      case "blastradius"
         put the uBlastRadius of pCtrl into tBr
         if tBr is empty then put kBombRadius into tBr
         put tBr + pDir * 60 into tBr
         if tBr < 60 then put 60 into tBr
         if tBr > 1200 then put 1200 into tBr
         set the uBlastRadius of pCtrl to tBr
         break
      case "blastpower"
         put the uBlastPower of pCtrl into tPow
         if tPow is empty then put kBombPower into tPow
         put tPow + pDir * 600 into tPow
         if tPow < 200 then put 200 into tPow
         if tPow > 30000 then put 30000 into tPow
         set the uBlastPower of pCtrl to tPow
         break
      case "fanforce"
         put (the uFanForce of pCtrl) + pDir * 600 into tF
         if tF < 0 then put 0 into tF
         if tF > 40000 then put 40000 into tF
         set the uFanForce of pCtrl to tF
         break
      case "fandir"
         put ((the uFanDir of pCtrl) + pDir * 90 + 360) mod 360 into tNewDir
         set the uFanDir of pCtrl to tNewDir
         drawFanShape pCtrl
         break
      case "fansize"
         put the uFanScale of pCtrl into tFs
         if tFs is empty then put 1 into tFs
         put tFs + pDir * 0.25 into tFs
         if tFs < 0.5 then put 0.5 into tFs
         if tFs > 2.5 then put 2.5 into tFs
         set the uFanScale of pCtrl to tFs
         drawFanShape pCtrl
         break
      case "magpol"
         set the uMagPolarity of pCtrl to (the uMagPolarity of pCtrl) * -1
         break
      case "magforce"
         put (the uMagForce of pCtrl) + pDir * 800 into tMf
         if tMf < 100 then put 100 into tMf
         if tMf > 50000 then put 50000 into tMf
         set the uMagForce of pCtrl to tMf
         break
      case "magrange"
         put (the uMagRange of pCtrl) + pDir * 80 into tMr
         if tMr < 60 then put 60 into tMr
         if tMr > 1400 then put 1400 into tMr
         set the uMagRange of pCtrl to tMr
         break
      case "laserdir"
         set the uLaserDir of pCtrl to ((numOr(the uLaserDir of pCtrl, 0) + pDir * kLaserStep + 360) mod 360)
         drawLaserBeam pCtrl
         break
      case "thrustdir"
         set the uThrustDir of pCtrl to ((numOr(the uThrustDir of pCtrl, 270) + pDir * kLaserStep + 360) mod 360)
         break
      case "thrustpower"
         set the uThrustPower of pCtrl to clampRange(numOr(the uThrustPower of pCtrl, 0) + pDir * 600, 0, 40000)
         break
      case "thrustspin"
         set the uThrustSpin of pCtrl to clampRange(numOr(the uThrustSpin of pCtrl, 0) + pDir * 800, -40000, 40000)
         break
      case "bombfuse"
         set the uFuseOnRun of pCtrl to not (the uFuseOnRun of pCtrl is true)
         break
      case "bombfuselen"
         set the uFuseLen of pCtrl to clampRange(numOr(the uFuseLen of pCtrl, kBombFuseFrames) + pDir * 30, 15, 900)
         break
      case "bombsoft"
         set the uSoftBlast of pCtrl to not (the uSoftBlast of pCtrl is true)
         break
   end switch
end adjustPartProp

-- Scale a part and re-fit its physics shape on the same body (joints survive).
on resizePart pCtrl, pFactor
   local tKind, tCx, tCy, tW, tH
   put the uKind of pCtrl into tKind
   put item 1 of the loc of pCtrl into tCx
   put item 2 of the loc of pCtrl into tCy
   if tKind is "poly" then
      scaleGraphicPoints pCtrl, pFactor, tCx, tCy
   else
      put round((the width of pCtrl) * pFactor) into tW
      put round((the height of pCtrl) * pFactor) into tH
      if tW < kSizeMin then put kSizeMin into tW
      if tH < kSizeMin then put kSizeMin into tH
      if tW > kSizeMax then put kSizeMax into tW
      if tH > kSizeMax then put kSizeMax into tH
      set the width of pCtrl to tW
      set the height of pCtrl to tH
      set the loc of pCtrl to tCx & "," & tCy
   end if
   set the uW of pCtrl to the width of pCtrl
   set the uH of pCtrl to the height of pCtrl
   if tKind is "hill" then
      rebuildHillChain pCtrl
   else if kindHasBody(tKind) then
      b2kReshape pCtrl, partShape(pCtrl)
      reapplyMaterial pCtrl
      reapplyCollision pCtrl             -- reshape resets the filter; keep layer + channels
   end if
end resizePart

-- Scale a polygon graphic's points around its centre, within the size limits.
on scaleGraphicPoints pCtrl, pFactor, pCx, pCy
   if (the width of pCtrl) * pFactor < kSizeMin then exit scaleGraphicPoints
   if (the width of pCtrl) * pFactor > kSizeMax then exit scaleGraphicPoints
   local tPt, tNew
   put empty into tNew
   repeat for each line tPt in the points of pCtrl
      if tPt is empty then next repeat
      put round(pCx + (item 1 of tPt - pCx) * pFactor) & "," & round(pCy + (item 2 of tPt - pCy) * pFactor) & cr after tNew
   end repeat
   set the points of pCtrl to tNew
end scaleGraphicPoints

-- Which collision shape a kind uses, for b2kReshape.
function shapeOfKind pKind
   switch pKind
      case "ball"
      case "balloon"
      case "bomb"
         return "ball"
      case "capsule"
         return "capsule"
      case "poly"
      case "platform"
      case "ramp"
      case "hill"
         return "poly"
   end switch
   return "box"
end shapeOfKind

-- The collision shape b2kReshape should rebuild for a part: an image uses its
-- chosen uShape (box/ball/capsule); every other kind is fixed by its kind.
function partShape pCtrl
   if the uKind of pCtrl is "image" then return numOr(the uShape of pCtrl, "box")
   return shapeOfKind(the uKind of pCtrl)
end partShape

-- After a reshape the new shape has default material; restore the part's values.
on reapplyMaterial pCtrl
   if the uBounce of pCtrl is not empty then b2kSetBounce pCtrl, (the uBounce of pCtrl)
   if the uDensity of pCtrl is not empty then b2kSetDensity pCtrl, (the uDensity of pCtrl)
   if the uFriction of pCtrl is not empty then b2kSetFriction pCtrl, (the uFriction of pCtrl)
end reapplyMaterial

-- Collision layer 0 (the default) hits everything. Layers 1-8 give a part a
-- shared negative collision group, so parts on the SAME layer pass through each
-- other while still colliding with the ground and parts on other layers.
on applyCollisionLayer pCtrl
   local tL
   put numOr(the uLayer of pCtrl, 0) into tL
   if tL is 0 then b2kSetCollisionGroup pCtrl, 0
   else b2kSetCollisionGroup pCtrl, - tL
end applyCollisionLayer

-- A part flagged as a sensor (trigger zone) is non-solid: bodies pass through it
-- and it fires b2kSensorEnter/Exit instead of colliding. Show that with a
-- translucent fill so it reads as a "ghost" zone, not a solid block.
on applySensorLook pCtrl
   if pCtrl is empty then exit applySensorLook
   try
      if the uSensor of pCtrl is true then set the blendLevel of pCtrl to 45
      else set the blendLevel of pCtrl to 0
   end try
end applySensorLook

-- ---------------------------------------------------------------------
-- Collision category / mask filter (the "Collision filter" popup panel)
-- ---------------------------------------------------------------------
-- A part is ON a set of channels (category) and COLLIDES WITH a set of channels
-- (mask). Two parts touch only when each is on a channel the other collides with.
-- This is independent of the simpler "Collision layer" (a group override). The
-- panel works in channel numbers 1..8; the Kit's filter wants the matching bits.

-- Turn a channel-number list ("1,3") into the bit values b2kLayerBits expects
-- (channel N -> 2^(N-1), so "1,3" -> "1,4").
function channelBits pList
   local tN, tOut
   put empty into tOut
   set the itemDelimiter to comma
   repeat for each item tN in pList
      if tN is empty or tN is not a number then next repeat
      put addItem(tOut, round(2 ^ (tN - 1))) into tOut   -- channel N -> bit 2^(N-1), kept integer
   end repeat
   if tOut is empty then return 0
   return tOut
end channelBits

-- A part's stored channel sets, defaulting to the Box2D default (on channel 1,
-- collides with every channel) when the part has never been customised.
function partCategories pCtrl
   return numOr(the uOnChans of pCtrl, "1")
end partCategories

function partMaskChannels pCtrl
   return numOr(the uHitChans of pCtrl, kAllChannels)
end partMaskChannels

function partFilterCustom pCtrl
   return (the uOnChans of pCtrl is not empty) or (the uHitChans of pCtrl is not empty)
end partFilterCustom

-- Push the part's category/mask into the live shape. A reshape resets the filter,
-- so this is re-run after every reshape (next to applyCollisionLayer).
on applyPartFilter pCtrl
   if pCtrl is empty then exit applyPartFilter
   if not partFilterCustom(pCtrl) then exit applyPartFilter   -- leave Box2D defaults alone
   b2kSetCategory pCtrl, channelBits(partCategories(pCtrl))
   b2kSetMask pCtrl, channelBits(partMaskChannels(pCtrl))
end applyPartFilter

-- Re-apply BOTH collision settings (layer group + category/mask) after a reshape,
-- which always rebuilds the shape with a default filter.
on reapplyCollision pCtrl
   applyCollisionLayer pCtrl
   applyPartFilter pCtrl
end reapplyCollision

-- A compact one-line description for the inspector row.
function filterSummary pCtrl
   if not partFilterCustom(pCtrl) then return "default (hits everything)"
   return "on " & channelText(partCategories(pCtrl)) & " · hits " & channelText(partMaskChannels(pCtrl))
end filterSummary

-- "1,2,3,4,5,6,7,8" -> "all"; a short list stays as-is; empty -> "none".
function channelText pList
   local tSorted
   if pList is empty then return "none"
   put sortedChannels(pList) into tSorted
   if tSorted is kAllChannels then return "all"
   return tSorted
end channelText

-- Add or remove a channel number from a comma list, kept sorted; never returns
-- empty (a part must stay on at least one channel, and collide with at least one).
function toggleChannel pList, pIdx
   local tN, tOut, tFound
   put empty into tOut
   put false into tFound
   set the itemDelimiter to comma
   repeat for each item tN in pList
      if tN is pIdx then
         put true into tFound
      else if tN is not empty then
         put addItem(tOut, tN) into tOut
      end if
   end repeat
   if not tFound then put addItem(tOut, pIdx) into tOut
   if tOut is empty then return pIdx          -- refuse to clear the last channel
   return sortedChannels(tOut)
end toggleChannel

-- Sort a channel-number list ascending and drop blanks/dupes.
function sortedChannels pList
   local tN, tSeen, tOut, tI
   set the itemDelimiter to comma
   repeat for each item tN in pList
      if tN is not empty and tN is a number then put true into tSeen[tN]
   end repeat
   put empty into tOut
   repeat with tI = 1 to kFilterChannels
      if tSeen[tI] is true then put addItem(tOut, tI) into tOut
   end repeat
   return tOut
end sortedChannels

-- A generous palette the Colour setting cycles through.
function partSwatches
   return "92,150,222" & cr & "84,206,142" & cr & "232,182,92" & cr & "214,92,92" & cr \
         & "206,124,206" & cr & "120,200,232" & cr & "236,120,150" & cr & "150,160,180" & cr \
         & "120,90,210" & cr & "240,140,60" & cr & "90,200,170" & cr & "232,232,236"
end partSwatches

function swatchIndexOf pCtrl, pPal
   local tLine, tI
   put 0 into tI
   repeat for each line tLine in pPal
      add 1 to tI
      if tLine is (the uColor of pCtrl) then return tI
   end repeat
   return 0
end swatchIndexOf

-- =====================================================================
-- Inspector tabs, exact-value entry, per-axis sizing, and joint settings
-- =====================================================================

-- Which settings tab a property key belongs to.
function propGroup pKey
   if pKey is among the items of "width,height,length,thickness,diameter,size,imgshape,angle,facing,color" then return "shape"
   if pKey is among the items of "bounce,density,friction,gravity,fixedrot,bodytype,lindamp,angdamp,bullet,material" then return "physics"
   if pKey is among the items of "layer,sensor,filter,active,sleep" then return "collide"
   return "special"   -- launchspeed,launchdir,spinrate, laserdir, and the fan/magnet/bomb keys
end propGroup

-- The tabs that actually have settings for this kind (so empty tabs stay hidden).
function partTabs pKind
   local tKey, tHasShape, tHasPhys, tHasCollide, tHasSpec, tOut
   put false into tHasShape
   put false into tHasPhys
   put false into tHasCollide
   put false into tHasSpec
   set the itemDelimiter to comma
   repeat for each item tKey in partProps(pKind)
      switch propGroup(tKey)
         case "shape"
            put true into tHasShape
            break
         case "physics"
            put true into tHasPhys
            break
         case "collide"
            put true into tHasCollide
            break
         case "special"
            put true into tHasSpec
            break
      end switch
   end repeat
   put empty into tOut
   if tHasShape then put "shape" into tOut
   if tHasPhys then put addItem(tOut, "physics") into tOut
   if tHasCollide then put addItem(tOut, "collide") into tOut
   if tHasSpec then put addItem(tOut, "special") into tOut
   return tOut
end partTabs

-- Append an item to a comma list (small sibling of addKV for ; lists).
function addItem pList, pItem
   if pList is empty then return pItem
   return pList & "," & pItem
end addItem

on selectInspTab pTab
   put pTab into gInspTab
   if gSelPart is not empty then showPartInspector gSelPart
end selectInspTab

-- Show only the tabs a part offers, highlighting the active one.
on refreshInspTabs pAvail
   local tT
   set the itemDelimiter to comma
   repeat for each item tT in "shape,physics,collide,special"
      if there is not a button ("ui_act_tab_" & tT) then next repeat
      if tT is among the items of pAvail then
         set the visible of button ("ui_act_tab_" & tT) to true
         if tT is gInspTab then
            setBtnActive ("ui_act_tab_" & tT), kColAccentGreen
         else
            setBtnIdle ("ui_act_tab_" & tT)
         end if
      else
         set the visible of button ("ui_act_tab_" & tT) to false
      end if
   end repeat
end refreshInspTabs

on hideInspTabs
   local tT
   set the itemDelimiter to comma
   repeat for each item tT in "shape,physics,collide,special"
      if there is a button ("ui_act_tab_" & tT) then set the visible of button ("ui_act_tab_" & tT) to false
   end repeat
end hideInspTabs

-- A custom-property value, or a fallback when it has never been set.
function numOr pV, pDefault
   if pV is empty then return pDefault
   return pV
end numOr

function clampRange pV, pLo, pHi
   if pV < pLo then return pLo
   if pV > pHi then return pHi
   return pV
end clampRange

-- Keep a part dimension within the allowed pixel range.
function clampDim pV
   if pV is empty or pV is not a number then return kSizeMin
   put round(pV) into pV
   if pV < kSizeMin then return kSizeMin
   if pV > kSizeMax then return kSizeMax
   return pV
end clampDim

-- Set ONE axis of a part to an exact pixel size, then re-fit its physics shape on
-- the same body so joints survive. pAxis is "w", "h", or "d" (both, for balls).
on setPartDimension pCtrl, pAxis, pValue
   local tKind, tCx, tCy, tW, tH, tAng
   put the uKind of pCtrl into tKind
   -- Terrain rebuilds its outline from uW/uH directly (its angle lives in the
   -- points, not the body), so it sizes cleanly at any rotation.
   if kindIsTerrain(tKind) then
      put clampRange(pValue, kTerrainMin, kTerrainMax) into pValue
      if pAxis is "h" then set the uH of pCtrl to pValue
      else set the uW of pCtrl to pValue
      regenTerrain pCtrl
      exit setPartDimension
   end if
   put item 1 of the loc of pCtrl into tCx
   put item 2 of the loc of pCtrl into tCy
   -- A rotated graphic's rect is its (inflated) bounding box, so resize in an
   -- upright frame, then restore the angle. Axis-aligned parts skip this entirely.
   put 0 into tAng
   if kindHasBody(tKind) then put round(b2kAngle(pCtrl)) into tAng
   if tAng is not 0 then
      b2kMoveTo pCtrl, tCx, tCy, 0
      renderBuild
   end if
   put numOr(the uW of pCtrl, the width of pCtrl) into tW
   put numOr(the uH of pCtrl, the height of pCtrl) into tH
   put clampDim(pValue) into pValue
   if pAxis is "w" then put pValue into tW
   else if pAxis is "h" then put pValue into tH
   else if pAxis is "d" then
      put pValue into tW
      put pValue into tH
   end if
   set the width of pCtrl to tW
   set the height of pCtrl to tH
   set the loc of pCtrl to tCx & "," & tCy
   set the uW of pCtrl to tW
   set the uH of pCtrl to tH
   if tKind is "hill" then
      rebuildHillChain pCtrl              -- outline carries its own rotation; body stays at 0
   else if kindHasBody(tKind) then
      b2kReshape pCtrl, partShape(pCtrl)
      reapplyMaterial pCtrl
      reapplyCollision pCtrl              -- reshape resets the filter; keep layer + channels
      if tAng is not 0 then b2kMoveTo pCtrl, tCx, tCy, tAng
   end if
end setPartDimension

-- Click a settings value to type an exact number (parts or joints).
on editPropValue pKey
   if pKey is empty then exit editPropValue
   if gSelJoint is not empty then
      editJointValue pKey
      exit editPropValue
   end if
   if gSelPart is empty then exit editPropValue
   if pKey is "filter" then
      openFilterPanel gSelPart
      exit editPropValue
   end if
   set the itemDelimiter to comma
   if pKey is not among the items of kEntryKeys then exit editPropValue
   ask ("Set " & propEditName(gSelPart, pKey) & ":") with currentPropValue(gSelPart, pKey)
   if it is empty or the result is "Cancel" then exit editPropValue
   if it is not a number then
      put "Please type a number." into gStatus
      updateHud
      exit editPropValue
   end if
   applyPropValue gSelPart, pKey, it
   showPartInspector gSelPart
   if gMode is "build" then renderBuild
end editPropValue

-- A readable name for the entry dialog, taken from the row label (before the colon).
function propEditName pCtrl, pKey
   local tL
   put propLabel(pCtrl, pKey) into tL
   if ":" is in tL then return char 1 to (offset(":", tL) - 1) of tL
   return pKey
end propEditName

function currentPropValue pCtrl, pKey
   switch pKey
      case "width"
      case "length"
      case "diameter"
      case "size"
         return numOr(the uW of pCtrl, the width of pCtrl)
      case "height"
      case "thickness"
         return numOr(the uH of pCtrl, the height of pCtrl)
      case "angle"
         if kindIsTerrain(the uKind of pCtrl) then return numOr(the uAngle of pCtrl, 0)
         return round(b2kAngle(pCtrl))
      case "bounce"
         return numOr(the uBounce of pCtrl, 0)
      case "density"
         return numOr(the uDensity of pCtrl, 1)
      case "friction"
         return numOr(the uFriction of pCtrl, 0.4)
      case "gravity"
         return numOr(the uGravity of pCtrl, 1)
      case "lindamp"
         return numOr(the uLinDamp of pCtrl, 0)
      case "angdamp"
         return numOr(the uAngDamp of pCtrl, 0)
      case "launchspeed"
         return numOr(the uLaunchSpeed of pCtrl, 0)
      case "launchdir"
         return numOr(the uLaunchDir of pCtrl, 0)
      case "spinrate"
         return numOr(the uSpinRate of pCtrl, 0)
      case "blastradius"
         return numOr(the uBlastRadius of pCtrl, kBombRadius)
      case "blastpower"
         return numOr(the uBlastPower of pCtrl, kBombPower)
      case "fanforce"
         return numOr(the uFanForce of pCtrl, kFanForce)
      case "fansize"
         return numOr(the uFanScale of pCtrl, 1)
      case "magforce"
         return numOr(the uMagForce of pCtrl, kMagnetForce)
      case "magrange"
         return numOr(the uMagRange of pCtrl, kMagnetRange)
   end switch
   return empty
end currentPropValue

-- Apply an exact typed value to a part (clamped), syncing physics like the steppers.
on applyPropValue pCtrl, pKey, pVal
   switch pKey
      case "width"
      case "length"
         setPartDimension pCtrl, "w", pVal
         break
      case "height"
      case "thickness"
         setPartDimension pCtrl, "h", pVal
         break
      case "diameter"
         setPartDimension pCtrl, "d", pVal
         break
      case "angle"
         setPartAngle pCtrl, pVal
         break
      case "size"
         if (the width of pCtrl) >= 1 then resizePart pCtrl, (clampDim(pVal) / (the width of pCtrl))
         break
      case "bounce"
         put clampRange(pVal, 0, 0.9) into pVal
         set the uBounce of pCtrl to pVal
         b2kSetBounce pCtrl, pVal
         break
      case "density"
         put clampRange(pVal, 0.3, 3) into pVal
         set the uDensity of pCtrl to pVal
         b2kSetDensity pCtrl, pVal
         break
      case "friction"
         put clampRange(pVal, 0, 2) into pVal
         set the uFriction of pCtrl to pVal
         b2kSetFriction pCtrl, pVal
         break
      case "gravity"
         put clampRange(pVal, -2, 3) into pVal
         set the uGravity of pCtrl to pVal
         b2kSetGravityScale pCtrl, pVal
         break
      case "lindamp"
         put clampRange(pVal, 0, 5) into pVal
         set the uLinDamp of pCtrl to pVal
         b2kSetDamping pCtrl, pVal, empty
         break
      case "angdamp"
         put clampRange(pVal, 0, 5) into pVal
         set the uAngDamp of pCtrl to pVal
         b2kSetDamping pCtrl, empty, pVal
         break
      case "launchspeed"
         set the uLaunchSpeed of pCtrl to clampRange(pVal, 0, 1500)
         break
      case "launchdir"
         set the uLaunchDir of pCtrl to ((pVal + 360) mod 360)
         break
      case "spinrate"
         set the uSpinRate of pCtrl to clampRange(pVal, -720, 720)
         break
      case "blastradius"
         set the uBlastRadius of pCtrl to clampRange(pVal, 60, 500)
         break
      case "blastpower"
         set the uBlastPower of pCtrl to clampRange(pVal, 200, 2000)
         break
      case "fanforce"
         set the uFanForce of pCtrl to clampRange(pVal, 0, 3000)
         break
      case "fansize"
         set the uFanScale of pCtrl to clampRange(pVal, 0.5, 2.5)
         drawFanShape pCtrl
         break
      case "magforce"
         set the uMagForce of pCtrl to clampRange(pVal, 100, 4000)
         break
      case "magrange"
         set the uMagRange of pCtrl to clampRange(pVal, 60, 520)
         break
   end switch
end applyPropValue

-- ---- Per-joint inspector --------------------------------------------

-- The on-screen point that selects a joint (its marker bead / link midpoint).
function jointHandleLoc pIndex
   local tVis, tG, tA, tB
   put gJVis[pIndex] into tVis
   put "cb_joint_" & pIndex into tG
   if there is not a graphic tG then return empty
   if tVis is "dot" then return the loc of graphic tG
   if tVis is "rod" then
      put line 1 of the points of graphic tG into tA
      put line 2 of the points of graphic tG into tB
      if tA is empty or tB is empty then return the loc of graphic tG
      return midOf(tA, tB)
   end if
   if gJCa[pIndex] is empty then return empty
   put the loc of gJCa[pIndex] into tA
   if gJCb[pIndex] is empty then put tA into tB
   else put the loc of gJCb[pIndex] into tB
   return midOf(tA, tB)
end jointHandleLoc

function midOf pA, pB
   return round((item 1 of pA + item 1 of pB) / 2) & "," & round((item 2 of pA + item 2 of pB) / 2)
end midOf

-- The live joint whose handle is nearest the click (within kJointHitR), or empty.
function jointUnderClick pX, pY
   local tI, tBest, tBestD, tH, tD
   put empty into tBest
   put empty into tBestD
   if gJN < 1 then return empty
   repeat with tI = 1 to gJN
      if gJKind[tI] is empty then next repeat
      if gJVis[tI] is "none" then next repeat
      put jointHandleLoc(tI) into tH
      if tH is empty then next repeat
      put sqrt((pX - item 1 of tH)^2 + (pY - item 2 of tH)^2) into tD
      if tD <= kJointHitR and (tBest is empty or tD < tBestD) then
         put tI into tBest
         put tD into tBestD
      end if
   end repeat
   return tBest
end jointUnderClick

on selectJoint pIndex
   if pIndex is empty then exit selectJoint
   if gJKind[pIndex] is empty then exit selectJoint
   deselectPart
   deselectJoint
   put pIndex into gSelJoint
   local tG
   put "cb_joint_" & pIndex into tG
   if there is a graphic tG then
      try
         set the uSelLine of graphic tG to the lineSize of graphic tG
         set the uSelFg of graphic tG to the foregroundColor of graphic tG
         set the lineSize of graphic tG to (the lineSize of graphic tG) + 3
         set the foregroundColor of graphic tG to "255,255,255"
      end try
   end if
   showJointInspector pIndex
end selectJoint

on deselectJoint
   if gSelJoint is empty then exit deselectJoint
   local tG
   put "cb_joint_" & gSelJoint into tG
   if there is a graphic tG then
      try
         set the lineSize of graphic tG to the uSelLine of graphic tG
         set the foregroundColor of graphic tG to the uSelFg of graphic tG
      end try
   end if
   put empty into gSelJoint
   clearPropRows
end deselectJoint

-- Show a selected joint's name, what it does, and the values you can change.
on showJointInspector pIndex
   if pIndex is empty then exit showJointInspector
   if gJKind[pIndex] is empty then exit showJointInspector
   local tKind, tKey, tRow, tMk
   put gJKind[pIndex] into tKind
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   setInspector ("Selected: " & niceName(tKind)), (line 2 of toolHelp(tKind))
   clearPropRows
   hideInspTabs
   put 0 into tRow
   set the itemDelimiter to comma
   repeat for each item tKey in jointProps(tKind)
      add 1 to tRow
      if tRow > kPropRows then exit repeat
      showPropRow tRow, jointPropLabel(tMk, tKind, tKey), tKey
   end repeat
   if tRow > 0 then setSettingsHint empty
   else setSettingsHint "This joint has no adjustable settings."
end showJointInspector

-- The ordered list of adjustable settings shown for each kind of joint.
function jointProps pKind
   switch pKind
      case "hinge"
         return "jmotoron,jmotorspeed,jmotorpower,jlimiton,jlimitlo,jlimithi"
      case "slider"
         return "jmotoron,jmotorspeed,jmotorpower,jlimiton,jlimitlo,jlimithi"
      case "wheel"
         return "jmotoron,jmotorspeed,jmotorpower,jspringhz,jspringdamp"
      case "rope"
         return "jminlen,jmaxlen,jspringhz,jspringdamp"
      case "weld"
         return "jspringhz,jspringdamp"
   end switch
   return empty
end jointProps

-- The human-readable "Name: value" shown on a joint property row.
function jointPropLabel pMk, pKind, pKey
   local tUnit
   if pKind is "slider" then put " px/s" into tUnit
   else put " deg/s" into tUnit
   switch pKey
      case "jmotoron"
         return "Motor: " & onOff(the uMotorOn of pMk is true)
      case "jmotorspeed"
         return "Motor speed: " & numOr(the uMotorSpeed of pMk, gMotorSpeed) & tUnit
      case "jmotorpower"
         return "Motor power: " & numOr(the uMotorPower of pMk, motorPowerDefault(pKind))
      case "jlimiton"
         return "Limits: " & onOff(the uLimitOn of pMk is true)
      case "jlimitlo"
         if pKind is "slider" then return "Limit min: " & numOr(the uLimitLo of pMk, -100) & " px"
         return "Limit min: " & numOr(the uLimitLo of pMk, -45) & " deg"
      case "jlimithi"
         if pKind is "slider" then return "Limit max: " & numOr(the uLimitHi of pMk, 100) & " px"
         return "Limit max: " & numOr(the uLimitHi of pMk, 45) & " deg"
      case "jspringhz"
         return "Springiness: " & numOr(the uSpringHz of pMk, 0) & " Hz"
      case "jspringdamp"
         return "Spring damping: " & numOr(the uSpringDamp of pMk, 0.5)
      case "jminlen"
         return "Min length: " & numOr(the uMinLen of pMk, 0) & " px"
      case "jmaxlen"
         return "Max length: " & numOr(the uMaxLen of pMk, 200) & " px"
   end switch
   return pKey
end jointPropLabel

function onOff pFlag
   if pFlag is true then return "on"
   return "off"
end onOff

on adjustJointProp pIndex, pKey, pDir
   local tMk, tV
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   switch pKey
      case "jmotoron"
         set the uMotorOn of tMk to not (the uMotorOn of tMk is true)
         applyJointMotor pIndex
         break
      case "jmotorspeed"
         put numOr(the uMotorSpeed of tMk, gMotorSpeed) + pDir * 30 into tV
         set the uMotorSpeed of tMk to clampRange(tV, kMotorMin, kMotorMax)
         applyJointMotor pIndex
         break
      case "jmotorpower"
         put numOr(the uMotorPower of tMk, motorPowerDefault(gJKind[pIndex])) + pDir * 100 into tV
         set the uMotorPower of tMk to clampRange(tV, 50, 6000)
         applyJointMotor pIndex
         break
      case "jlimiton"
         set the uLimitOn of tMk to not (the uLimitOn of tMk is true)
         applyJointLimit pIndex
         break
      case "jlimitlo"
         if gJKind[pIndex] is "slider" then put numOr(the uLimitLo of tMk, -100) + pDir * 20 into tV
         else put numOr(the uLimitLo of tMk, -45) + pDir * 15 into tV
         set the uLimitLo of tMk to tV
         applyJointLimit pIndex
         break
      case "jlimithi"
         if gJKind[pIndex] is "slider" then put numOr(the uLimitHi of tMk, 100) + pDir * 20 into tV
         else put numOr(the uLimitHi of tMk, 45) + pDir * 15 into tV
         set the uLimitHi of tMk to tV
         applyJointLimit pIndex
         break
      case "jspringhz"
         put numOr(the uSpringHz of tMk, 0) + pDir * 1 into tV
         set the uSpringHz of tMk to clampRange(tV, 0, 15)
         applyJointSpring pIndex
         break
      case "jspringdamp"
         put numOr(the uSpringDamp of tMk, 0.5) + pDir * 0.1 into tV
         set the uSpringDamp of tMk to clampRange(tV, 0, 1)
         applyJointSpring pIndex
         break
      case "jminlen"
         put numOr(the uMinLen of tMk, 0) + pDir * 20 into tV
         set the uMinLen of tMk to clampRange(tV, 0, 800)
         set the uRangeSet of tMk to true
         applyJointRange pIndex
         break
      case "jmaxlen"
         put numOr(the uMaxLen of tMk, 200) + pDir * 20 into tV
         set the uMaxLen of tMk to clampRange(tV, 20, 800)
         set the uRangeSet of tMk to true
         applyJointRange pIndex
         break
   end switch
end adjustJointProp

-- Push the marker's stored motor setting to the live joint (kind-specific call).
on applyJointMotor pIndex
   local tKind, tJ, tMk, tOn, tSpd, tPow
   put gJKind[pIndex] into tKind
   put gJHandle[pIndex] into tJ
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   put (the uMotorOn of tMk is true) into tOn
   put numOr(the uMotorSpeed of tMk, gMotorSpeed) into tSpd
   put numOr(the uMotorPower of tMk, motorPowerDefault(tKind)) into tPow
   switch tKind
      case "hinge"
         if tOn then b2kMotor tJ, tSpd, tPow
         else b2kMotorOff tJ
         break
      case "slider"
         if tOn then b2kSliderMotor tJ, tSpd, tPow
         else b2kSliderMotorOff tJ
         break
      case "wheel"
         if tOn then b2kWheelMotor tJ, tSpd, tPow
         else b2kWheelMotorOff tJ
         break
   end switch
   if tOn then put tSpd into gJMotor[pIndex]
   else put 0 into gJMotor[pIndex]
end applyJointMotor

on applyJointLimit pIndex
   local tKind, tJ, tMk, tOn, tLo, tHi
   put gJKind[pIndex] into tKind
   put gJHandle[pIndex] into tJ
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   put (the uLimitOn of tMk is true) into tOn
   if tKind is "slider" then
      put numOr(the uLimitLo of tMk, -100) into tLo
      put numOr(the uLimitHi of tMk, 100) into tHi
      if tOn then b2kSliderLimit tJ, tLo, tHi
      else b2kSliderLimitOff tJ
   else if tKind is "hinge" then
      put numOr(the uLimitLo of tMk, -45) into tLo
      put numOr(the uLimitHi of tMk, 45) into tHi
      if tOn then b2kHingeLimit tJ, tLo, tHi
      else b2kHingeLimitOff tJ
   end if
end applyJointLimit

on applyJointSpring pIndex
   local tKind, tJ, tMk, tHz, tDamp
   put gJKind[pIndex] into tKind
   put gJHandle[pIndex] into tJ
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   put numOr(the uSpringHz of tMk, 0) into tHz
   put numOr(the uSpringDamp of tMk, 0.5) into tDamp
   switch tKind
      case "rope"
         if tHz > 0 then b2kSpring tJ, tHz, tDamp
         else b2DistanceEnableSpring tJ, false, 0, 0   -- 0 Hz = rigid rope again
         break
      case "weld"
         b2kWeldSpring tJ, tHz, tDamp                  -- 0 Hz = rigid weld
         break
      case "wheel"
         b2kWheelSpring tJ, tHz, tDamp
         break
   end switch
end applyJointSpring

on applyJointRange pIndex
   local tJ, tMk
   put gJHandle[pIndex] into tJ
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   b2kRopeRange tJ, numOr(the uMinLen of tMk, 0), numOr(the uMaxLen of tMk, 200)
end applyJointRange

-- Click a joint value to type an exact number.
on editJointValue pKey
   if gSelJoint is empty then exit editJointValue
   set the itemDelimiter to comma
   if pKey is among the items of "jmotoron,jlimiton" then exit editJointValue   -- toggles only
   local tMk
   put the long id of graphic ("cb_joint_" & gSelJoint) into tMk
   ask ("Set " & jointEditName(pKey) & ":") with jointValueOf(tMk, pKey)
   if it is empty or the result is "Cancel" then exit editJointValue
   if it is not a number then
      put "Please type a number." into gStatus
      updateHud
      exit editJointValue
   end if
   applyJointValue gSelJoint, pKey, it
   showJointInspector gSelJoint
end editJointValue

function jointValueOf pMk, pKey
   switch pKey
      case "jmotorspeed"
         return numOr(the uMotorSpeed of pMk, gMotorSpeed)
      case "jmotorpower"
         return numOr(the uMotorPower of pMk, 1000)
      case "jlimitlo"
         return numOr(the uLimitLo of pMk, 0)
      case "jlimithi"
         return numOr(the uLimitHi of pMk, 0)
      case "jspringhz"
         return numOr(the uSpringHz of pMk, 0)
      case "jspringdamp"
         return numOr(the uSpringDamp of pMk, 0.5)
      case "jminlen"
         return numOr(the uMinLen of pMk, 0)
      case "jmaxlen"
         return numOr(the uMaxLen of pMk, 200)
   end switch
   return empty
end jointValueOf

function jointEditName pKey
   switch pKey
      case "jmotorspeed"
         return "motor speed"
      case "jmotorpower"
         return "motor power"
      case "jlimitlo"
         return "limit minimum"
      case "jlimithi"
         return "limit maximum"
      case "jspringhz"
         return "springiness (Hz)"
      case "jspringdamp"
         return "spring damping (0-1)"
      case "jminlen"
         return "minimum length (px)"
      case "jmaxlen"
         return "maximum length (px)"
   end switch
   return pKey
end jointEditName

on applyJointValue pIndex, pKey, pVal
   local tMk
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   switch pKey
      case "jmotorspeed"
         set the uMotorSpeed of tMk to clampRange(pVal, kMotorMin, kMotorMax)
         applyJointMotor pIndex
         break
      case "jmotorpower"
         set the uMotorPower of tMk to clampRange(pVal, 50, 6000)
         applyJointMotor pIndex
         break
      case "jlimitlo"
         set the uLimitLo of tMk to pVal
         applyJointLimit pIndex
         break
      case "jlimithi"
         set the uLimitHi of tMk to pVal
         applyJointLimit pIndex
         break
      case "jspringhz"
         set the uSpringHz of tMk to clampRange(pVal, 0, 15)
         applyJointSpring pIndex
         break
      case "jspringdamp"
         set the uSpringDamp of tMk to clampRange(pVal, 0, 1)
         applyJointSpring pIndex
         break
      case "jminlen"
         set the uMinLen of tMk to clampRange(pVal, 0, 800)
         set the uRangeSet of tMk to true
         applyJointRange pIndex
         break
      case "jmaxlen"
         set the uMaxLen of tMk to clampRange(pVal, 20, 800)
         set the uRangeSet of tMk to true
         applyJointRange pIndex
         break
   end switch
end applyJointValue

-- Pack a joint's editable settings as "key=value;…" (per-kind) for Save.
function jointSpecial pIndex
   local tKind, tMk, tS
   put gJKind[pIndex] into tKind
   if tKind is empty then return empty
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   put empty into tS
   if tKind is "hinge" or tKind is "slider" or tKind is "wheel" then
      put addKV(tS, "mon=" & (the uMotorOn of tMk is true)) into tS
      put addKV(tS, "msp=" & numOr(the uMotorSpeed of tMk, gMotorSpeed)) into tS
      put addKV(tS, "mpw=" & numOr(the uMotorPower of tMk, motorPowerDefault(tKind))) into tS
   end if
   if tKind is "hinge" or tKind is "slider" then
      put addKV(tS, "lon=" & (the uLimitOn of tMk is true)) into tS
      put addKV(tS, "llo=" & numOr(the uLimitLo of tMk, 0)) into tS
      put addKV(tS, "lhi=" & numOr(the uLimitHi of tMk, 0)) into tS
   end if
   if tKind is "rope" or tKind is "weld" or tKind is "wheel" then
      put addKV(tS, "shz=" & numOr(the uSpringHz of tMk, 0)) into tS
      put addKV(tS, "sdm=" & numOr(the uSpringDamp of tMk, 0.5)) into tS
   end if
   if tKind is "rope" and (the uRangeSet of tMk is true) then
      put addKV(tS, "rng=true") into tS
      put addKV(tS, "rmn=" & numOr(the uMinLen of tMk, 0)) into tS
      put addKV(tS, "rmx=" & numOr(the uMaxLen of tMk, 200)) into tS
   end if
   return tS
end jointSpecial

-- Restore a joint's editable settings (from Load); empty string = leave defaults.
on applyJointSpecial pIndex, pSpecial
   if pSpecial is empty then exit applyJointSpecial
   if gJKind[pIndex] is empty then exit applyJointSpecial
   local tMk, tV
   put the long id of graphic ("cb_joint_" & pIndex) into tMk
   put specialValue(pSpecial, "mon") into tV
   if tV is not empty then set the uMotorOn of tMk to (tV is "true")
   put specialValue(pSpecial, "msp") into tV
   if tV is not empty then set the uMotorSpeed of tMk to tV
   put specialValue(pSpecial, "mpw") into tV
   if tV is not empty then set the uMotorPower of tMk to tV
   put specialValue(pSpecial, "lon") into tV
   if tV is not empty then set the uLimitOn of tMk to (tV is "true")
   put specialValue(pSpecial, "llo") into tV
   if tV is not empty then set the uLimitLo of tMk to tV
   put specialValue(pSpecial, "lhi") into tV
   if tV is not empty then set the uLimitHi of tMk to tV
   put specialValue(pSpecial, "shz") into tV
   if tV is not empty then set the uSpringHz of tMk to tV
   put specialValue(pSpecial, "sdm") into tV
   if tV is not empty then set the uSpringDamp of tMk to tV
   applyJointMotor pIndex
   applyJointLimit pIndex
   applyJointSpring pIndex
   if specialValue(pSpecial, "rng") is "true" then
      set the uRangeSet of tMk to true
      put specialValue(pSpecial, "rmn") into tV
      if tV is not empty then set the uMinLen of tMk to tV
      put specialValue(pSpecial, "rmx") into tV
      if tV is not empty then set the uMaxLen of tMk to tV
      applyJointRange pIndex
   end if
end applyJointSpecial

-- Defaults for a joint marker's editable settings, by joint kind.
function jointLimitLoDefault pKind
   if pKind is "slider" then return -100
   return -45
end jointLimitLoDefault

function jointLimitHiDefault pKind
   if pKind is "slider" then return 100
   return 45
end jointLimitHiDefault

function jointSpringHzDefault pKind
   if pKind is "wheel" then return 5
   return 0
end jointSpringHzDefault

function jointSpringDampDefault pKind
   if pKind is "wheel" then return 0.7
   return 0.5
end jointSpringDampDefault

-- ---- Rotation, material presets, launch, gravity, pause -------------

-- Re-seat a part at an exact angle (degrees), keeping its position. Joints survive.
on setPartAngle pCtrl, pDeg
   local tCx, tCy
   -- Terrain bakes its angle into the points (a static body never re-syncs).
   if kindIsTerrain(the uKind of pCtrl) then
      set the uAngle of pCtrl to ((round(pDeg) mod 360) + 360) mod 360
      regenTerrain pCtrl
      exit setPartAngle
   end if
   if not kindHasBody(the uKind of pCtrl) then exit setPartAngle
   put item 1 of the loc of pCtrl into tCx
   put item 2 of the loc of pCtrl into tCy
   put (((round(pDeg)) mod 360) + 360) mod 360 into pDeg
   b2kMoveTo pCtrl, tCx, tCy, pDeg
   renderBuild
end setPartAngle

-- A material is "friction,density,bounce". Presets give parts a quick feel.
function materialPreset pName
   switch pName
      case "Ice"
         return "0.02,0.9,0.05"
      case "Rubber"
         return "0.9,1,0.85"
      case "Metal"
         return "0.3,2.6,0.05"
      case "Wood"
         return "0.5,0.7,0.2"
   end switch
   return "0.4,1,0.2"        -- Default
end materialPreset

-- Name the preset a part currently matches, or "Custom".
function materialNameOf pCtrl
   local tName, tP, tFr, tD, tB
   put numOr(the uFriction of pCtrl, 0.4) into tFr
   put numOr(the uDensity of pCtrl, 1) into tD
   put numOr(the uBounce of pCtrl, 0.2) into tB
   set the itemDelimiter to comma
   repeat for each item tName in "Default,Ice,Rubber,Metal,Wood"
      put materialPreset(tName) into tP
      if tFr is item 1 of tP and tD is item 2 of tP and tB is item 3 of tP then return tName
   end repeat
   return "Custom"
end materialNameOf

-- Step to the next/previous material preset and apply its values.
on cycleMaterial pCtrl, pDir
   local tOrder, tI, tName, tP
   put "Default,Ice,Rubber,Metal,Wood" into tOrder
   set the itemDelimiter to comma
   put itemOffset(materialNameOf(pCtrl), tOrder) + pDir into tI
   if tI < 1 then put the number of items of tOrder into tI
   if tI > the number of items of tOrder then put 1 into tI
   put item tI of tOrder into tName
   put materialPreset(tName) into tP
   set the uFriction of pCtrl to item 1 of tP
   b2kSetFriction pCtrl, item 1 of tP
   set the uDensity of pCtrl to item 2 of tP
   b2kSetDensity pCtrl, item 2 of tP
   set the uBounce of pCtrl to item 3 of tP
   b2kSetBounce pCtrl, item 3 of tP
end cycleMaterial

-- Apply each part's saved launch velocity and spin (called when Run starts).
on armLaunches
   local tP, tSpeed, tDir, tSpin
   repeat for each line tP in gParts
      if tP is empty then next repeat
      if not kindHasBody(the uKind of tP) then next repeat
      put numOr(the uLaunchSpeed of tP, 0) into tSpeed
      put numOr(the uLaunchDir of tP, 0) into tDir
      put numOr(the uSpinRate of tP, 0) into tSpin
      if tSpeed > 0 then b2kSetVelocity tP, tSpeed * cos(tDir * kPI / 180), - tSpeed * sin(tDir * kPI / 180)
      if tSpin is not 0 then b2kSpin tP, tSpin
   end repeat
end armLaunches

-- World gravity presets (metres/sec^2; screen down is negative y).
on applyGravityMode
   switch gGravityMode
      case "low"
         b2kSetGravity 0, -3.5
         break
      case "zero"
         b2kSetGravity 0, 0
         break
      case "reverse"
         b2kSetGravity 0, 10
         break
      case "sideways"
         b2kSetGravity 9, -4
         break
      default
         b2kSetGravity 0, -10
   end switch
end applyGravityMode

on cycleGravity
   local tOrder, tI
   put "normal,low,zero,reverse,sideways" into tOrder
   set the itemDelimiter to comma
   put itemOffset(gGravityMode, tOrder) + 1 into tI
   if tI < 1 or tI > the number of items of tOrder then put 1 into tI
   put item tI of tOrder into gGravityMode
   applyGravityMode
   refreshGravityLabel
   put "Gravity: " & gravityModeName(gGravityMode) & "." into gStatus
   updateHud
end cycleGravity

on refreshGravityLabel
   if there is a button "ui_act_gravity" then set the label of button "ui_act_gravity" to "Gravity: " & gravityModeName(gGravityMode)
end refreshGravityLabel

-- World feel: a few one-click presets that tune how the whole world responds —
-- how readily things bounce (restitution threshold), how soft/stiff contacts are
-- (contact tuning) and a top speed cap. Cosmetic-but-fun; safe before the world
-- exists (the Kit's world setters no-op until b2kSetup has run).
function worldFeelName pMode
   switch pMode
      case "bouncy"
         return "Bouncy"
      case "floaty"
         return "Floaty"
      case "snappy"
         return "Snappy"
   end switch
   return "Default"
end worldFeelName

on applyWorldFeel
   switch gWorldFeel
      case "bouncy"
         b2kSetRestitutionThreshold 20      -- low threshold: collisions bounce readily
         b2kSetContactTuning 30, 10, 120
         b2kSetMaxSpeed 6000
         break
      case "floaty"
         b2kSetRestitutionThreshold 40
         b2kSetContactTuning 12, 12, 80     -- soft, squishy contacts
         b2kSetMaxSpeed 1500                -- gentle, speed-limited
         break
      case "snappy"
         b2kSetRestitutionThreshold 80      -- only fast hits bounce
         b2kSetContactTuning 60, 8, 160     -- stiff, responsive contacts
         b2kSetMaxSpeed 6000
         break
      default                               -- "default": Box2D's standard feel
         b2kSetRestitutionThreshold 40
         b2kSetContactTuning 30, 10, 120
         b2kSetMaxSpeed 6000
   end switch
end applyWorldFeel

-- The advanced solver toggles default to Box2D's recommended setup.
on setWorldOptionDefaults
   put true into gCCD           -- continuous collision ON: fast bodies don't tunnel through walls
   put true into gSleepOn       -- resting bodies sleep (saves CPU)
   put true into gWarmStart     -- reuse last frame's solution (stabler + faster)
   put 4 into gSubsteps         -- solver sub-steps per step
end setWorldOptionDefaults

-- Push the advanced toggles into the live world (re-applied on every Run).
on applyWorldOptions
   b2kEnableContinuous (gCCD is true)
   b2kEnableSleeping (gSleepOn is true)
   b2kEnableWarmStarting (gWarmStart is true)
   b2kSetSubsteps numOr(gSubsteps, 4)
   b2kSetJointTuning 60, 2       -- a sane default joint stiffness (hz, damping)
end applyWorldOptions

on cycleWorldFeel
   local tOrder, tI
   put "default,bouncy,floaty,snappy" into tOrder
   set the itemDelimiter to comma
   put itemOffset(gWorldFeel, tOrder) + 1 into tI
   if tI < 1 or tI > the number of items of tOrder then put 1 into tI
   put item tI of tOrder into gWorldFeel
   applyWorldFeel
   refreshWorldFeelLabel
   put "World feel: " & worldFeelName(gWorldFeel) & "." into gStatus
   updateHud
end cycleWorldFeel

on refreshWorldFeelLabel
   if there is a button "ui_act_worldfeel" then set the label of button "ui_act_worldfeel" to "Feel: " & worldFeelName(gWorldFeel)
end refreshWorldFeelLabel

function gravityModeName pMode
   switch pMode
      case "low"
         return "Low (moon)"
      case "zero"
         return "Zero-G"
      case "reverse"
         return "Reverse"
      case "sideways"
         return "Sideways"
   end switch
   return "Normal"
end gravityModeName

on togglePause
   if gMode is not "run" then
      put "Pause works while the simulation is running — press Run first." into gStatus
      updateHud
      exit togglePause
   end if
   if b2kIsRunning() then
      b2kPause
      put "Paused. Use Step to advance one frame, or Pause again to resume." into gStatus
   else
      b2kResume
      put "Resumed." into gStatus
   end if
   refreshPauseLabel
   updateHud
end togglePause

on stepOnce
   if gMode is not "run" then
      put "Step works while paused during Run — press Run first." into gStatus
      updateHud
      exit stepOnce
   end if
   if b2kIsRunning() then b2kPause        -- stepping implies a paused sim
   b2kStepOnce
   refreshPauseLabel
   put "Stepped one frame." into gStatus
   updateHud
end stepOnce

on refreshPauseLabel
   if there is not a button "ui_act_pause" then exit refreshPauseLabel
   if gMode is "run" and not b2kIsRunning() then set the label of button "ui_act_pause" to "Resume"
   else set the label of button "ui_act_pause" to "Pause"
end refreshPauseLabel

-- Default motor strength by joint kind (torque for hinge/wheel, force for slider).
function motorPowerDefault pKind
   if pKind is "hinge" then return kHingeTorque
   if pKind is "wheel" then return kWheelTorque
   return 1000
end motorPowerDefault

function frictionLabel pV
   if pV is empty then put 0.4 into pV
   if pV <= 0 then return "none (slippery)"
   if pV < 0.3 then return "low"
   if pV < 0.7 then return "medium"
   if pV < 1.2 then return "high"
   return "very high"
end frictionLabel

function gravityLabel pV
   if pV is empty then put 1 into pV
   if pV < -0.3 then return "strong lift"
   if pV < 0.2 then return "gentle lift"
   if pV < 0.7 then return "floaty"
   if pV < 1.3 then return "normal"
   return "heavy"
end gravityLabel

function sizeLabel pV
   if pV is empty then put 1 into pV
   if pV < 0.8 then return "small"
   if pV < 1.3 then return "normal"
   if pV < 1.9 then return "large"
   return "huge"
end sizeLabel

-- Hovering a palette button previews its help; leaving restores the inspector.
on mouseEnter
   local tName
   put the short name of the target into tName
   if "ui_tool_" is in tName then
      hoverTool the long id of the target
      hoverHelp the uToolId of the target
   else if "ui_joint_" is in tName then
      hoverTool the long id of the target
      hoverHelp the uJointId of the target
   end if
end mouseEnter

on mouseLeave
   local tName
   put the short name of the target into tName
   if "ui_tool_" is in tName or "ui_joint_" is in tName then
      highlightAll                              -- restore the correct idle / selected colour
      restoreInspector
   end if
end mouseLeave

-- Lighten a palette button on hover, but only when it is the resting (idle) tool.
-- "Idle" is derived from the current selection, not the pixel colour, so it never
-- mis-reads an accent and never fights the selected / collapsed styling; mouseLeave
-- repaints everything via highlightAll.
on hoverTool pBtn
   if there is not a button pBtn then exit hoverTool
   local tActive
   if the uToolId of pBtn is not empty then
      put (the uToolId of pBtn is gTool and gJointTool is empty) into tActive
   else
      put (the uJointId of pBtn is gJointTool) into tActive
   end if
   if not tActive then set the backgroundColor of pBtn to kColBtnHover
end hoverTool

-- =====================================================================
-- Plain-language labels, tooltips and help text
-- =====================================================================
function niceName pId
   local tNames
   put "drag=Move / Drag" & cr & "box=Box" & cr & "ball=Ball" & cr & "capsule=Capsule" & cr \
         & "poly=Polygon" & cr & "image=Picture" & cr & "anchor=Anchor" & cr & "delete=Delete" & cr \
         & "duplicate=Duplicate" & cr & "multiply=Multiply" & cr \
         & "balloon=Helium Balloon" & cr & "bomb=Bomb" & cr & "plate=Pressure Plate" & cr \
         & "fan=Fan / Wind" & cr & "magnet=Magnet" & cr & "sensor=Sensor" & cr & "laser=Laser" & cr & "thruster=Thruster" & cr \
         & "platform=Platform" & cr & "ramp=Ramp" & cr & "hill=Hill" & cr & "draw=Draw Terrain" & cr & "car=Car" & cr & "hinge=Hinge Joint" & cr \
         & "weld=Weld Joint" & cr & "servo=Servo Joint" & cr & "rope=Rope Joint" & cr & "slider=Slider Joint" & cr \
         & "wheel=Wheel Joint" & cr & "bridge=Bridge" & cr & "chain=Chain (rope)" into tNames
   local tLine
   set the itemDelimiter to "="
   repeat for each line tLine in tNames
      if item 1 of tLine is pId then
         set the itemDelimiter to comma
         return item 2 of tLine
      end if
   end repeat
   set the itemDelimiter to comma
   return pId
end niceName

-- Small glyphs for the palette. Plain geometric characters that render in the
-- default font everywhere; the text label carries the real meaning.
function toolGlyph pId
   local tGlyphs
   put "drag=✥" & cr & "box=■" & cr & "ball=●" & cr & "capsule=▬" & cr & "poly=◆" & cr \
         & "image=▦" & cr & "anchor=▼" & cr & "delete=✕" & cr & "duplicate=▣" & cr & "multiply=⧉" & cr & "link=↦" & cr & "balloon=◯" & cr & "bomb=◉" & cr \
         & "plate=▭" & cr & "fan=▷" & cr & "magnet=◐" & cr & "sensor=◉" & cr & "laser=↗" & cr & "thruster=▲" & cr \
         & "platform=━" & cr & "ramp=◣" & cr & "hill=∩" & cr & "draw=✎" & cr & "car=⊙" & cr & "hinge=○" & cr & "weld=▰" & cr \
         & "servo=⊕" & cr & "rope=∿" & cr & "slider=↔" & cr & "wheel=◎" & cr & "bridge=◠" & cr & "chain=∾" into tGlyphs
   local tLine
   set the itemDelimiter to "="
   repeat for each line tLine in tGlyphs
      if item 1 of tLine is pId then
         set the itemDelimiter to comma
         return item 2 of tLine
      end if
   end repeat
   set the itemDelimiter to comma
   return "•"
end toolGlyph

-- Line 1 = short tooltip; line 2 = the longer inspector explanation.
function toolHelp pId
   switch pId
      case "drag"
         return "Move parts around (places nothing new)." & cr & "Move tool. In Build mode, drag any part to reposition it. In Run mode, grab and fling parts with the mouse."
      case "box"
         return "Drop a solid box that falls and stacks." & cr & "A box is a solid rectangle. It falls, stacks and tumbles — great for crates, walls and dominoes."
      case "ball"
         return "Drop a ball that rolls and bounces." & cr & "A ball rolls and bounces. Handy for wheels, marbles, and things that trigger pressure plates."
      case "capsule"
         return "Drop a rounded bar (a capsule)." & cr & "A capsule is a bar with rounded ends. It rolls on its ends — useful for rollers, limbs and levers."
      case "poly"
         return "Drop a six-sided block." & cr & "A polygon is a chunky many-sided block. It stacks and tumbles like a box with more character."
      case "image"
         return "Use your own picture as an object." & cr & "Pick an image file and it becomes a physical block that tumbles and spins like any other part."
      case "anchor"
         return "Place a fixed point that never moves." & cr & "An anchor is pinned to the world. Attach joints to it to hold things up — perfect as a motor mount or a pivot."
      case "delete"
         return "Remove a part you click on." & cr & "Delete tool. Click any part to remove it, along with any joints attached to it."
      case "duplicate"
         return "Copy a part you click on." & cr & "Duplicate tool. Click any part to drop an identical copy — same size, colour and settings — then drag it where you want."
      case "multiply"
         return "Make many copies of a part at once." & cr & "Multiply tool. Click any part and choose how many copies to make; they drop into a tidy grid, each identical to the original. Great for crates, dominoes and bricks."
      case "link"
         return "Wire a trigger to a bomb." & cr & "Link tool. Click a pressure plate or sensor, then click a bomb — an amber wire connects them and that trigger now sets off only that bomb. An unwired trigger still sets off everything. Wires show while building."
      case "balloon"
         return "A helium balloon that floats upward." & cr & "A balloon rises on its own. Tie it to a part with a Rope joint to lift that part. A nearby bomb blast pops it."
      case "bomb"
         return "A bomb that explodes and flings parts." & cr & "Detonates on a hard hit, a pressure-plate signal, or a Run-fuse (toggle it below). The blast flings nearby parts outward."
      case "plate"
         return "A switch that triggers when weighed down." & cr & "A pressure plate. When a part rests on it, it fires a signal: any bombs go off and all motors switch on or off. Build chain reactions with it!"
      case "sensor"
         return "A trigger zone that fires when entered." & cr & "A sensor is a non-solid zone — parts pass right through it, but the moment one enters, it fires the same signal as a pressure plate: bombs go off and all motors switch. Great for tripwires and gates."
      case "fan"
         return "A wind zone that blows parts along." & cr & "A fan pushes any part inside its zone in the arrow's direction. Set the direction and strength in the inspector. No body — parts pass through it."
      case "magnet"
         return "A magnet that pulls parts toward it." & cr & "A magnet attracts nearby parts (or repels them). Set attract/repel, strength and reach in the inspector. No body — parts pass through it."
      case "laser"
         return "A ray that draws a beam to whatever it hits." & cr & "A laser casts a ray from its emitter and draws the beam to the first thing it strikes (a wall counts). Set the beam angle in the inspector; while running, select it to read the live hit distance. Shows off the Kit's ray-casting."
      case "thruster"
         return "A self-propelled rocket that thrusts on Run." & cr & "A thruster drives itself: on Run it pops off with an ignition kick, then applies a steady force along its own facing — plus optional spin. Set thrust angle, power and spin in the inspector; lock its rotation for a straight climb or let it tumble. Shows off b2kForce / b2kTorque / b2kPush."
      case "platform"
         return "Place a solid ledge that never moves." & cr & "A platform is fixed scenery — a solid ledge that stays put. Rest parts on it, build floors and steps, or rotate it into an angled shelf. Set its size, angle and grip in the inspector."
      case "ramp"
         return "Place a fixed slope for rolling and sliding." & cr & "A ramp is a fixed wedge. Balls roll down it and parts slide along it. Rotate it for any incline and raise its grip to slow the slide — great for launches and runs."
      case "hill"
         return "Place a smooth rolling mound." & cr & "A hill is fixed scenery built as a smooth chain, so parts roll over it without catching. Make it narrow for a single dome or wide for rolling hills; size and rotate it to shape your landscape."
      case "draw"
         return "Draw your own ground line." & cr & "Press and drag across the play field to sketch a smooth ground contour — bumps, valleys, ramps, anything. On release it becomes solid terrain parts roll along. Drag it to reposition; delete and redraw to change its shape."
      case "car"
         return "Drop a ready-made motor car." & cr & "A complete car: a chassis on two sprung, motorised wheels. Drop it in, press Run and it drives off. Drag the body and the whole car moves with it; tune or reverse each wheel's motor in the joint inspector."
      case "hinge"
         return "Pin two parts so they rotate." & cr & "A hinge is a pin two parts spin around — like an axle or a pendulum. Pin to an Anchor or empty space, switch Motor on, and it drives itself."
      case "weld"
         return "Glue two parts rigidly together." & cr & "A weld locks two parts as one solid piece — they keep their relative position and angle."
      case "servo"
         return "A powered hold between two parts." & cr & "A servo drives one part to keep its position and angle relative to another. Unlike a rigid weld it gives under load and springs back — good for self-righting parts, soft platforms and return-to-home arms. Click part A, then part B."
      case "rope"
         return "Link two parts with a rope." & cr & "A rope keeps two parts from drifting further apart than its length. They can still swing and fall closer together."
      case "slider"
         return "Let one part slide along a line." & cr & "A slider lets one part slide in a straight line relative to another — like a piston or a drawer."
      case "wheel"
         return "Add a springy, spinning wheel." & cr & "A wheel joint carries a wheel with springy suspension and lets it spin freely — switch Motor on to drive a vehicle."
      case "bridge"
         return "Span a plank bridge between two points." & cr & "Bridge tool. Click a part (or empty space), then a second point: a row of hinged planks spans the gap and sags under weight. Anchor the ends to Anchors or the world."
      case "chain"
         return "Hang a flexible segmented rope." & cr & "Chain tool. Click two points and a rope of small hinged links drapes between them. Unlike the rigid Rope joint, it bends, coils and swings — great for swings and tethers."
   end switch
   return niceName(pId) & cr & "Select this tool, then click the stage."
end toolHelp

function actionHelp pId
   switch pId
      case "mode"
         return "Switch between Build (arrange) and Run (simulate)."
      case "reset"
         return "Put every part back where it was when you last pressed Run."
      case "clear"
         return "Remove everything and start with an empty stage."
      case "save"
         return "Save this contraption to a file."
      case "load"
         return "Open a contraption you saved earlier."
      case "recipes"
         return "Load a ready-made example, or run a stress test."
      case "info"
         return "Show the quick how-to guide again."
      case "motor"
         return "When on, new Hinge and Wheel joints get a motor that drives them."
      case "bouncy"
         return "When on, new parts are springy and bounce."
      case "spddn"
         return "Slower motor speed for new motorised joints."
      case "spdup"
         return "Faster motor speed for new motorised joints."
      case "recipeclose"
         return "Close this menu."
      case "filterclose"
         return "Close the collision filter."
      case "worldadv"
         return "Advanced world solver settings (CCD, sleeping, sub-steps…)."
      case "worldclose"
         return "Close the world settings."
   end switch
   if char 1 to 5 of pId is "wopt_" then return "Toggle this world solver setting."
   if char 1 to 9 of pId is "prop_inc_" then return "Increase this value."
   if char 1 to 9 of pId is "prop_dec_" then return "Decrease this value."
   if char 1 to 9 of pId is "filt_cat_" then return "Toggle whether this part is on channel " & (char 10 to -1 of pId) & "."
   if char 1 to 10 of pId is "filt_mask_" then return "Toggle whether this part collides with channel " & (char 11 to -1 of pId) & "."
   return niceName(pId)
end actionHelp

-- Put a clear tooltip on every interactive control.
on applyTooltips
   local tI, tName, tCtrl
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      put the short name of tCtrl into tName
      if "ui_tool_" is in tName then set the tooltip of tCtrl to line 1 of toolHelp(the uToolId of tCtrl)
      else if "ui_joint_" is in tName then set the tooltip of tCtrl to line 1 of toolHelp(the uJointId of tCtrl)
      else if "ui_act_" is in tName then set the tooltip of tCtrl to actionHelp(the uActId of tCtrl)
   end repeat
end applyTooltips

function dirName pDeg
   switch pDeg
      case 0
         return "Right"
      case 90
         return "Down"
      case 180
         return "Left"
   end switch
   return "Up"
end dirName

function magName pPol
   if pPol < 0 then return "Repel (push away)"
   return "Attract (pull in)"
end magName

function yesNo pFlag
   if pFlag is true then return "Yes"
   return "No"
end yesNo

function bounceLabel pV
   if pV is empty or pV <= 0 then return "none"
   if pV < 0.3 then return "low"
   if pV < 0.6 then return "medium"
   return "high"
end bounceLabel

function weightLabel pCtrl
   local tD
   put the uDensity of pCtrl into tD
   if tD is empty then put 1 into tD
   if tD <= 0.4 then return "very light"
   if tD <= 0.8 then return "light"
   if tD < 1.5 then return "normal"
   if tD < 2.5 then return "heavy"
   return "very heavy"
end weightLabel

-- =====================================================================
-- Recipes menu (ready-made examples) + stress test
-- =====================================================================
on buildRecipesMenu
   local tWide, tHigh, tL, tT, tW, tH, tBy
   put the width of this card into tWide
   put the height of this card into tHigh
   put 420 into tW
   put 476 into tH
   put (tWide - tW) div 2 into tL
   put (tHigh - tH) div 2 into tT
   makeBar "ui_recipescrim", 0, 0, tWide, tHigh, "10,11,15"
   set the blendLevel of graphic "ui_recipescrim" to 62
   set the uRecipeMenu of graphic "ui_recipescrim" to true
   makeBar "ui_recipebg", tL, tT, tL + tW, tT + tH, "34,38,48"
   set the uRecipeMenu of graphic "ui_recipebg" to true
   makeLabel "ui_recipe_title", tL + 18, tT + 14, tL + tW - 18, tT + 38, "Example Machines", 15, "236,238,245", true
   set the uRecipeMenu of field "ui_recipe_title" to true
   put tT + 46 into tBy
   put recipeCategory("Launchers", "catapult,cannon,trebuchet,wreckingball", \
         "Catapult,Cannon,Trebuchet,Wrecking Ball", tL, tW, tBy) into tBy
   put recipeCategory("Machines", "crane,cart,fantower,magnetcatch,balloonlift", \
         "Crane,Motor Cart,Fan Tower,Magnet Catch,Balloon Lift", tL, tW, tBy) into tBy
   put recipeCategory("Chain Reactions", "platebomb,dominoes", \
         "Plate → Bomb,Domino Run", tL, tW, tBy) into tBy
   put recipeCategory("Toys & Tests", "swing,cradle,terrainrun,stress", \
         "Pendulum Swing,Newton's Cradle,Terrain Run,Stress (+" & kStressBatch & ")", tL, tW, tBy) into tBy
   makeAction "recipeclose", "Close", tL + tW - 92, tBy + 2, 76, 26
   set the uRecipeMenu of button "ui_act_recipeclose" to true
   hideRecipesMenu
end buildRecipesMenu

-- Lay out one labelled category of recipe buttons in two columns. Returns the
-- next free Y. pIds / pLabels are comma lists; the headers and buttons all carry
-- uRecipeMenu so the whole gallery shows/hides as one.
function recipeCategory pTitle, pIds, pLabels, pL, pW, pY
   local tHdr, tI, tN, tColW, tBx
   put "ui_reccat_" & the number of controls of this card into tHdr   -- a unique, name-safe id
   makeLabel tHdr, pL + 18, pY, pL + pW - 18, pY + 18, pTitle, 11, "150,196,232", true
   set the uRecipeMenu of field tHdr to true
   add 22 to pY
   set the itemDelimiter to comma
   put the number of items of pIds into tN
   put (pW - 44) div 2 into tColW
   repeat with tI = 1 to tN
      if (tI - 1) mod 2 is 0 then put pL + 18 into tBx
      else put pL + 18 + tColW + 8 into tBx
      makeRecipeBtn (item tI of pIds), (item tI of pLabels), tBx, pY, tColW
      if (tI mod 2 is 0) or (tI is tN) then add 30 to pY
   end repeat
   return pY + 8
end recipeCategory

on makeRecipeBtn pId, pLabel, pX, pY, pW
   makeAction pId, pLabel, pX, pY, pW, 28
   set the uRecipeMenu of button ("ui_act_" & pId) to true
end makeRecipeBtn

on toggleRecipesMenu
   if there is a graphic "ui_recipebg" and the visible of graphic "ui_recipebg" then hideRecipesMenu
   else showRecipesMenu
end toggleRecipesMenu

on showRecipesMenu
   setRecipeVisible true
end showRecipesMenu

on hideRecipesMenu
   setRecipeVisible false
end hideRecipesMenu

-- Show/hide the whole recipes panel. Collect the controls FIRST, then change
-- them: setting the layer mid-loop reorders controls and would skip some.
on setRecipeVisible pFlag
   local tI, tCtrl, tList
   put empty into tList
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      if the uRecipeMenu of tCtrl is true then put tCtrl & cr after tList
   end repeat
   repeat for each line tCtrl in tList
      set the visible of tCtrl to pFlag
      if pFlag then set the layer of tCtrl to top
   end repeat
end setRecipeVisible

-- =====================================================================
-- Collision-filter popup: two rows of eight channel toggles (category /
-- mask). Built once with the chrome (hidden), mirroring the recipes menu.
-- =====================================================================
on buildFilterPanel
   local tWide, tHigh, tW, tH, tL, tT, tI, tBx, tColW, tRowY
   put the width of this card into tWide
   put the height of this card into tHigh
   put 360 into tW
   put 286 into tH
   put (tWide - tW) div 2 into tL
   put (tHigh - tH) div 2 into tT
   makeBar "ui_filterscrim", 0, 0, tWide, tHigh, "10,11,15"
   set the blendLevel of graphic "ui_filterscrim" to 62
   set the uFilterMenu of graphic "ui_filterscrim" to true
   makeBar "ui_filterbg", tL, tT, tL + tW, tT + tH, "34,38,48"
   set the uFilterMenu of graphic "ui_filterbg" to true
   makeLabel "ui_filter_title", tL + 18, tT + 14, tL + tW - 18, tT + 36, "Collision Filter", 15, "236,238,245", true
   set the uFilterMenu of field "ui_filter_title" to true
   makeLabel "ui_filter_sub", tL + 18, tT + 38, tL + tW - 18, tT + 58, "", 11, "150,196,232", false
   set the uFilterMenu of field "ui_filter_sub" to true
   -- "On channels" row
   makeLabel "ui_filter_cathdr", tL + 18, tT + 66, tL + tW - 18, tT + 84, "On channels (what this part is):", 11, "210,214,224", true
   set the uFilterMenu of field "ui_filter_cathdr" to true
   put (tW - 36 - 7 * 6) div kFilterChannels into tColW
   put tT + 88 into tRowY
   repeat with tI = 1 to kFilterChannels
      put tL + 18 + (tI - 1) * (tColW + 6) into tBx
      makeAction ("filt_cat_" & tI), tI, tBx, tRowY, tColW, 26
      set the uFilterMenu of button ("ui_act_filt_cat_" & tI) to true
   end repeat
   -- "Collides with" row
   makeLabel "ui_filter_maskhdr", tL + 18, tT + 124, tL + tW - 18, tT + 142, "Collides with channels:", 11, "210,214,224", true
   set the uFilterMenu of field "ui_filter_maskhdr" to true
   put tT + 146 into tRowY
   repeat with tI = 1 to kFilterChannels
      put tL + 18 + (tI - 1) * (tColW + 6) into tBx
      makeAction ("filt_mask_" & tI), tI, tBx, tRowY, tColW, 26
      set the uFilterMenu of button ("ui_act_filt_mask_" & tI) to true
   end repeat
   makeLabel "ui_filter_help", tL + 18, tT + 182, tL + tW - 18, tT + 244, \
         "Two parts collide only when each is on a channel the other collides with. Tip: keep channel 1 on in the lower row so parts still land on the ground.", \
         11, "150,154,166", false
   set the uFilterMenu of field "ui_filter_help" to true
   makeAction "filterclose", "Close", tL + tW - 92, tT + tH - 34, 76, 26
   set the uFilterMenu of button "ui_act_filterclose" to true
   setFilterVisible false
end buildFilterPanel

-- Open the panel for a part: remember it, paint the toggles, show the panel.
on openFilterPanel pCtrl
   if pCtrl is empty then exit openFilterPanel
   put pCtrl into gFilterPart
   refreshFilterPanel
   setFilterVisible true
end openFilterPanel

on hideFilterPanel
   put empty into gFilterPart
   setFilterVisible false
end hideFilterPanel

-- Light each toggle to match the part's current category / mask channels.
on refreshFilterPanel
   local tI, tCats, tMask
   if gFilterPart is empty then exit refreshFilterPanel
   if there is not gFilterPart then
      hideFilterPanel
      exit refreshFilterPanel
   end if
   if there is a field "ui_filter_sub" then
      put ("Editing: " & niceName(the uKind of gFilterPart)) into field "ui_filter_sub"
   end if
   put "," & sortedChannels(partCategories(gFilterPart)) & "," into tCats
   put "," & sortedChannels(partMaskChannels(gFilterPart)) & "," into tMask
   repeat with tI = 1 to kFilterChannels
      setToggle ("ui_act_filt_cat_" & tI), ("," & tI & "," is in tCats)
      setToggle ("ui_act_filt_mask_" & tI), ("," & tI & "," is in tMask)
   end repeat
end refreshFilterPanel

-- A click on a category/mask channel toggle: flip it, apply, repaint. The action
-- id is "filt_cat_<n>" or "filt_mask_<n>"; split off the row and the channel.
on handleFilterToggle pId
   local tRest, tWhich, tIdx
   if gFilterPart is empty then exit handleFilterToggle
   if there is not gFilterPart then
      hideFilterPanel
      exit handleFilterToggle
   end if
   put char 6 to -1 of pId into tRest           -- "cat_3" or "mask_3"
   set the itemDelimiter to "_"
   put item 1 of tRest into tWhich              -- "cat" | "mask"
   put item 2 of tRest into tIdx                -- the channel number
   set the itemDelimiter to comma
   if tIdx is not a number then exit handleFilterToggle
   if tWhich is "cat" then
      set the uOnChans of gFilterPart to toggleChannel(partCategories(gFilterPart), tIdx)
   else
      set the uHitChans of gFilterPart to toggleChannel(partMaskChannels(gFilterPart), tIdx)
   end if
   applyPartFilter gFilterPart
   refreshFilterPanel
   if gSelPart is gFilterPart then showPartInspector gFilterPart
end handleFilterToggle

on setFilterVisible pFlag
   local tI, tCtrl, tList
   put empty into tList
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      if the uFilterMenu of tCtrl is true then put tCtrl & cr after tList
   end repeat
   repeat for each line tCtrl in tList
      set the visible of tCtrl to pFlag
      if pFlag then set the layer of tCtrl to top
   end repeat
end setFilterVisible

-- =====================================================================
-- World · Advanced popup: the solver toggles the Feel presets don't cover
-- (continuous collision, sleeping, warm-starting, sub-steps). Built once
-- with the chrome, hidden, like the recipes and filter popups.
-- =====================================================================
on buildWorldPanel
   local tWide, tHigh, tW, tH, tL, tT, tRy
   put the width of this card into tWide
   put the height of this card into tHigh
   put 340 into tW
   put 250 into tH
   put (tWide - tW) div 2 into tL
   put (tHigh - tH) div 2 into tT
   makeBar "ui_worldscrim", 0, 0, tWide, tHigh, "10,11,15"
   set the blendLevel of graphic "ui_worldscrim" to 62
   set the uWorldMenu of graphic "ui_worldscrim" to true
   makeBar "ui_worldbg", tL, tT, tL + tW, tT + tH, "34,38,48"
   set the uWorldMenu of graphic "ui_worldbg" to true
   makeLabel "ui_world_title", tL + 18, tT + 14, tL + tW - 18, tT + 36, "World · Advanced", 15, "236,238,245", true
   set the uWorldMenu of field "ui_world_title" to true
   put tT + 48 into tRy
   makeAction "wopt_ccd", "Continuous collision: off", tL + 18, tRy, tW - 36, 28
   set the uWorldMenu of button "ui_act_wopt_ccd" to true
   add 36 to tRy
   makeAction "wopt_sleep", "Sleeping: on", tL + 18, tRy, tW - 36, 28
   set the uWorldMenu of button "ui_act_wopt_sleep" to true
   add 36 to tRy
   makeAction "wopt_warm", "Warm starting: on", tL + 18, tRy, tW - 36, 28
   set the uWorldMenu of button "ui_act_wopt_warm" to true
   add 36 to tRy
   makeAction "wopt_sub", "Solver sub-steps: 4", tL + 18, tRy, tW - 36, 28
   set the uWorldMenu of button "ui_act_wopt_sub" to true
   makeAction "worldclose", "Close", tL + tW - 92, tT + tH - 34, 76, 26
   set the uWorldMenu of button "ui_act_worldclose" to true
   setWorldVisible false
end buildWorldPanel

on openWorldPanel
   refreshWorldPanel
   setWorldVisible true
end openWorldPanel

on hideWorldPanel
   setWorldVisible false
end hideWorldPanel

-- Paint each toggle to its current state (and light the ON ones blue).
on refreshWorldPanel
   if there is a button "ui_act_wopt_ccd" then set the label of button "ui_act_wopt_ccd" to "Continuous collision: " & onOff(gCCD)
   if there is a button "ui_act_wopt_sleep" then set the label of button "ui_act_wopt_sleep" to "Sleeping: " & onOff(gSleepOn)
   if there is a button "ui_act_wopt_warm" then set the label of button "ui_act_wopt_warm" to "Warm starting: " & onOff(gWarmStart)
   if there is a button "ui_act_wopt_sub" then set the label of button "ui_act_wopt_sub" to "Solver sub-steps: " & numOr(gSubsteps, 4)
   setToggle "ui_act_wopt_ccd", (gCCD is true)
   setToggle "ui_act_wopt_sleep", (gSleepOn is true)
   setToggle "ui_act_wopt_warm", (gWarmStart is true)
end refreshWorldPanel

-- "on"/"off" for a boolean-ish global.
function onOff pFlag
   if pFlag is true then return "on"
   return "off"
end onOff

-- A click on a world-option toggle: flip it, push it live, repaint.
on handleWorldToggle pId
   switch pId
      case "wopt_ccd"
         put not (gCCD is true) into gCCD
         break
      case "wopt_sleep"
         put not (gSleepOn is true) into gSleepOn
         break
      case "wopt_warm"
         put not (gWarmStart is true) into gWarmStart
         break
      case "wopt_sub"
         put numOr(gSubsteps, 4) + 1 into gSubsteps
         if gSubsteps > 8 then put 1 into gSubsteps
         break
   end switch
   if gMode is "run" then applyWorldOptions      -- take effect immediately while running
   refreshWorldPanel
end handleWorldToggle

on setWorldVisible pFlag
   local tI, tCtrl, tList
   put empty into tList
   repeat with tI = 1 to the number of controls of this card
      put the long id of control tI of this card into tCtrl
      if the uWorldMenu of tCtrl is true then put tCtrl & cr after tList
   end repeat
   repeat for each line tCtrl in tList
      set the visible of tCtrl to pFlag
      if pFlag then set the layer of tCtrl to top
   end repeat
end setWorldVisible

-- A balloon hauls a box up by a rope.
on buildRecipeBalloonLift
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tBaseY, tBox, tBalloon
   put (gArenaL + gArenaR) div 2 into tCx
   put gArenaB - 36 into tBaseY
   put placeBox(tCx, tBaseY, 42, 42, "120,200,232") into tBox
   b2kSetDensity tBox, 0.35              -- light enough for one balloon to lift
   set the uDensity of tBox to 0.35
   put placeBalloon(tCx, tBaseY - 150) into tBalloon
   get connectJoint("rope", tBalloon, tBox, tCx, tBaseY - 80, 0)
   renderBuild
   put "Balloon Lift — press Run: the balloon rises and hauls the box up by its rope." into gStatus
   updateHud
end buildRecipeBalloonLift

-- A dropped ball lands on a plate, which sets off a bomb under a tower.
on buildRecipePlateBomb
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tPlateX, tTowerX, tI, tBomb
   put (gArenaL + gArenaR) div 2 into tCx
   put tCx - 130 into tPlateX
   put tCx + 120 into tTowerX
   get placePlate(tPlateX, gArenaB - 8)
   get placeBall(tPlateX, gArenaT + 60, 40, "232,182,92")
   put placeBomb(tTowerX, gArenaB - 28) into tBomb
   set the uFuseOnRun of tBomb to false        -- this bomb fires from the PLATE, not its own fuse
   repeat with tI = 1 to 4
      get placeBox(tTowerX, gArenaB - 66 - tI * 34, 46, 30, "214,92,92")
   end repeat
   renderBuild
   put "Plate → Bomb — press Run: the ball lands on the plate, the bomb fires, the tower topples." into gStatus
   updateHud
end buildRecipePlateBomb

-- An upward fan juggles a few light balls.
on buildRecipeFanTower
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tFan, tI
   put (gArenaL + gArenaR) div 2 into tCx
   put placeFan(tCx, gArenaB - 84) into tFan
   set the uFanForce of tFan to 1800
   repeat with tI = 1 to 3
      get placeBall(tCx, gArenaT + 40 + tI * 46, 36, "84,206,142")
   end repeat
   renderBuild
   put "Fan Tower — press Run: the upward wind catches the balls and juggles them." into gStatus
   updateHud
end buildRecipeFanTower

-- A magnet gathers scattered balls.
on buildRecipeMagnetCatch
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tCy, tMag, tI
   put (gArenaL + gArenaR) div 2 into tCx
   put (gArenaT + gArenaB) div 2 into tCy
   put placeMagnet(tCx, tCy) into tMag
   set the uMagRange of tMag to 340
   repeat with tI = 1 to 6
      get placeBall(rnd(gArenaL + 50, gArenaR - 50), rnd(gArenaT + 40, gArenaB - 60), 30, "206,124,206")
   end repeat
   renderBuild
   put "Magnet Catch — press Run: the magnet pulls the scattered balls toward it." into gStatus
   updateHud
end buildRecipeMagnetCatch

-- A heavy block drops on one arm of a hinged lever and flings a ball off the other.
on buildRecipeCatapult
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tBaseY, tFulcrum, tArm, tBall, tWeight
   put (gArenaL + gArenaR) div 2 into tCx
   put gArenaB - 70 into tBaseY
   put placeAnchor(tCx, tBaseY) into tFulcrum
   put placeBox(tCx, tBaseY - 16, 200, 14, "180,150,90") into tArm
   set the uDensity of tArm to 0.6
   b2kSetDensity tArm, 0.6
   get connectJoint("hinge", tArm, tFulcrum, tCx, tBaseY - 16, 0)
   put placeBall(tCx - 84, tBaseY - 36, 30, "232,182,92") into tBall
   put placeBox(tCx + 78, tBaseY - 172, 54, 54, "214,92,92") into tWeight
   set the uDensity of tWeight to 2.6
   b2kSetDensity tWeight, 2.6
   renderBuild
   put "Catapult — press Run: the heavy block drops on the right arm and flings the ball off the left." into gStatus
   updateHud
end buildRecipeCatapult

-- A horizontal cannon: a static carriage + barrel (axis-aligned, so the static
-- render is exact — no rotated-static-body gotcha), a heavy ball that fires up
-- the field on Run via the launch system, and a crate stack to knock down. The
-- ball + barrel share a collision layer, so the ball slips clear of the barrel
-- instead of snagging on it as it launches.
on buildRecipeCannon
   if gMode is "run" then toggleMode
   clearAll
   local tX, tBaseY, tBarrel, tBase, tBall, tI
   put gArenaL + 80 into tX
   put gArenaB - 96 into tBaseY
   put placeBox(tX + 18, tBaseY + 34, 66, 30, "92,70,52") into tBase     -- carriage
   set the uBodyType of tBase to "static"
   b2kSetType tBase, "static"
   put placeBox(tX + 30, tBaseY, 96, 34, "70,74,86") into tBarrel        -- barrel
   set the uBodyType of tBarrel to "static"
   b2kSetType tBarrel, "static"
   set the uLayer of tBarrel to 1
   applyCollisionLayer tBarrel
   put placeBall(tX + 88, tBaseY, 26, "40,42,50") into tBall             -- cannonball at the muzzle
   set the uDensity of tBall to 2.6
   b2kSetDensity tBall, 2.6
   set the uLaunchSpeed of tBall to 1150
   set the uLaunchDir of tBall to 18                                      -- across and slightly up
   set the uLayer of tBall to 1
   applyCollisionLayer tBall
   repeat with tI = 0 to 4                                                -- crate stack downrange
      get placeBox(gArenaR - 150, gArenaB - 22 - tI * 30, 46, 28, "200,120,80")
   end repeat
   renderBuild
   put "Cannon — press Run: the ball fires across the field. Knock the crate stack down!" into gStatus
   updateHud
end buildRecipeCannon

-- A trebuchet: a long arm hinged off-centre, a heavy counterweight welded to the
-- short end and a ball resting on the long end. On Run the weight drops, the arm
-- whips round and flings the ball downfield. (Gravity-driven — no motor.)
on buildRecipeTrebuchet
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tBaseY, tPivot, tArm, tWeight, tBall
   put (gArenaL + gArenaR) div 2 - 70 into tCx
   put gArenaB - 150 into tBaseY
   put placeAnchor(tCx, tBaseY) into tPivot
   put placeBox(tCx + 44, tBaseY, 264, 12, "180,150,90") into tArm
   set the uDensity of tArm to 0.5
   b2kSetDensity tArm, 0.5
   get connectJoint("hinge", tArm, tPivot, tCx, tBaseY, 0)
   put placeBox(tCx - 80, tBaseY + 12, 56, 56, "214,92,92") into tWeight
   set the uDensity of tWeight to 4
   b2kSetDensity tWeight, 4
   get connectJoint("weld", tWeight, tArm)
   put placeBall(tCx + 162, tBaseY + 6, 26, "232,182,92") into tBall
   set the uDensity of tBall to 0.8
   b2kSetDensity tBall, 0.8
   renderBuild
   put "Trebuchet — press Run: the counterweight drops and the long arm flings the ball downfield." into gStatus
   updateHud
end buildRecipeTrebuchet

-- A crane: a static mast, a motorised jib that swings, and a load hung from the
-- jib end on a rope so it trails and sways as the jib turns.
on buildRecipeCrane
   if gMode is "run" then toggleMode
   clearAll
   local tX, tBaseY, tTop, tMast, tPivot, tJib, tLoad
   put gArenaL + 150 into tX
   put gArenaB - 30 into tBaseY
   put tBaseY - 210 into tTop
   put placeBox(tX, tBaseY - 110, 26, 220, "92,98,112") into tMast
   set the uBodyType of tMast to "static"
   b2kSetType tMast, "static"
   put placeAnchor(tX, tTop) into tPivot
   put placeBox(tX + 96, tTop, 210, 14, "180,150,90") into tJib
   set the uDensity of tJib to 0.4
   b2kSetDensity tJib, 0.4
   get connectJoint("hinge", tJib, tPivot, tX, tTop, 26)   -- 26 deg/s motor swings the jib
   put placeBall(tX + 184, tTop + 92, 34, "232,182,92") into tLoad
   set the uDensity of tLoad to 2
   b2kSetDensity tLoad, 2
   get connectJoint("rope", tJib, tLoad)
   renderBuild
   put "Crane — press Run: the motorised jib swings and the roped load trails and sways behind it." into gStatus
   updateHud
end buildRecipeCrane

-- A wrecking ball: a static gantry, a heavy ball hung on a rope and given a
-- sideways shove on Run so it swings into a brick wall and knocks it down.
on buildRecipeWreckingBall
   if gMode is "run" then toggleMode
   clearAll
   local tX, tBaseY, tTop, tLeg, tBeam, tPivot, tBall, tI
   put gArenaL + 120 into tX
   put gArenaB - 30 into tBaseY
   put tBaseY - 210 into tTop
   put placeBox(tX, tBaseY - 105, 18, 210, "92,98,112") into tLeg
   set the uBodyType of tLeg to "static"
   b2kSetType tLeg, "static"
   put placeBox(tX + 230, tBaseY - 105, 18, 210, "92,98,112") into tLeg
   set the uBodyType of tLeg to "static"
   b2kSetType tLeg, "static"
   put placeBox(tX + 115, tTop, 260, 16, "92,98,112") into tBeam
   set the uBodyType of tBeam to "static"
   b2kSetType tBeam, "static"
   put placeAnchor(tX + 40, tTop) into tPivot
   put placeBall(tX + 40, tTop + 140, 40, "60,64,74") into tBall
   set the uDensity of tBall to 4.5
   b2kSetDensity tBall, 4.5
   get connectJoint("rope", tPivot, tBall)
   set the uLaunchSpeed of tBall to 540
   set the uLaunchDir of tBall to 0                         -- shove right, into the wall
   repeat with tI = 0 to 5
      get placeBox(gArenaR - 160, gArenaB - 22 - tI * 30, 60, 28, "200,120,80")
   end repeat
   renderBuild
   put "Wrecking Ball — press Run: the ball swings into the brick wall and smashes it down." into gStatus
   updateHud
end buildRecipeWreckingBall

-- Five equal pendulums in a touching row; the raised end ball kicks the chain.
on buildRecipeCradle
   if gMode is "run" then toggleMode
   clearAll
   local tCx, tTopY, tI, tX, tBall, tAnchor, tDiam, tLen
   put (gArenaL + gArenaR) div 2 into tCx
   put gArenaT + 70 into tTopY
   put 38 into tDiam
   put 150 into tLen
   repeat with tI = 1 to 5
      put tCx + (tI - 3) * tDiam into tX
      put placeAnchor(tX, tTopY) into tAnchor
      if tI is 1 then
         put placeBall(tX - 106, tTopY + 106, tDiam, "120,200,232") into tBall   -- raised 45°, same rope length
      else
         put placeBall(tX, tTopY + tLen, tDiam, "120,200,232") into tBall
      end if
      set the uBounce of tBall to 0.92         -- near-elastic, so momentum kicks the far ball out
      b2kSetBounce tBall, 0.92
      set the uDensity of tBall to 2
      b2kSetDensity tBall, 2
      get connectJoint("rope", tBall, tAnchor, tX, tTopY, 0)
   end repeat
   renderBuild
   put "Newton's Cradle — press Run: the raised ball swings down and kicks the far ball out." into gStatus
   updateHud
end buildRecipeCradle

-- A launched ball rolls into a line of standing dominoes (shows off Launch + Run).
on buildRecipeDominoes
   if gMode is "run" then toggleMode
   clearAll
   local tBaseY, tX, tI, tStartX, tBall
   put gArenaB - 6 into tBaseY
   put gArenaL + 90 into tStartX
   repeat with tI = 1 to 12
      put tStartX + tI * 34 into tX
      get placeBox(tX, tBaseY - 34, 12, 60, "206,124,206")
   end repeat
   put placeBall(tStartX - 16, tBaseY - 40, 34, "232,182,92") into tBall
   set the uLaunchSpeed of tBall to 320
   set the uLaunchDir of tBall to 0
   renderBuild
   put "Domino Run — press Run: the ball is launched into the line and the dominoes cascade." into gStatus
   updateHud
end buildRecipeDominoes

-- A ball rolls down a ramp, along a raised ledge and into a hill — the terrain set.
on buildRecipeTerrainRun
   if gMode is "run" then toggleMode
   clearAll
   local tDeckTop, tBall
   put gArenaB - 84 into tDeckTop                               -- shared surface for the pieces
   get placeTerrain("platform", (gArenaL + gArenaR) div 2, tDeckTop + 14, 560, 28)
   get placeTerrain("ramp", gArenaR - 206, tDeckTop - 65, 200, 130)   -- on the deck's right end
   get placeTerrain("hill", gArenaL + 252, tDeckTop - 40, 160, 80)    -- a bump partway along
   put placeBall(gArenaR - 142, tDeckTop - 150, 36, "232,182,92") into tBall
   set the uBounce of tBall to 0
   b2kSetBounce tBall, 0
   set the uLaunchSpeed of tBall to 120
   set the uLaunchDir of tBall to 180                           -- a nudge to start it down-slope
   renderBuild
   put "Terrain Run — press Run: the ball rolls down the ramp, along the ledge and into the hill. Resize, rotate or re-grip any terrain piece in the inspector." into gStatus
   updateHud
end buildRecipeTerrainRun

-- Drop a batch of random bodies and run, to find where the frame rate gives out.
on stressTest
   local tI, tX, tY
   repeat with tI = 1 to kStressBatch
      put rnd(gArenaL + 30, gArenaR - 30) into tX
      put rnd(gArenaT + 30, (gArenaT + gArenaB) div 2) into tY
      if tI mod 2 is 0 then get placeBox(tX, tY, rnd(24, 40), rnd(24, 40), randomColor())
      else get placeBall(tX, tY, rnd(22, 36), randomColor())
   end repeat
   add kStressBatch to gStressCount
   if gMode is "build" then toggleMode
   put "Stress test: " & b2kBodyCount() & " bodies. Watch the fps — press again to push further." into gStatus
   updateHud
end stressTest

-- =====================================================================
-- First-run onboarding overlay (also reachable via the ? button)
-- =====================================================================
on maybeShowOnboarding
   if the uSeenOnboarding of this stack is true then exit maybeShowOnboarding
   startOnboarding
end maybeShowOnboarding

on startOnboarding
   put 1 into gOnbStep
   buildOnboardingOverlay
   showOnboardingStep
end startOnboarding

on buildOnboardingOverlay
   removeOnboarding
   local tWide, tHigh, tL, tT, tW, tH
   put the width of this card into tWide
   put the height of this card into tHigh
   makeBar "ui_onb_scrim", 0, 0, tWide, tHigh, "10,11,15"
   set the blendLevel of graphic "ui_onb_scrim" to 45
   put 470 into tW
   put 220 into tH
   put (tWide - tW) div 2 into tL
   put (tHigh - tH) div 2 into tT
   makeBar "ui_onb_card", tL, tT, tL + tW, tT + tH, "34,38,48"
   makeLabel "ui_onb_title", tL + 22, tT + 18, tL + tW - 22, tT + 44, "Welcome", 15, "236,238,245", true
   makeField "ui_onb_text", tL + 22, tT + 50, tL + tW - 22, tT + tH - 50, 12, "200,206,220"
   makeAction "onbskip", "Skip", tL + 22, tT + tH - 38, 70, 26
   makeAction "onbnext", "Next", tL + tW - 92, tT + tH - 38, 70, 26
end buildOnboardingOverlay

on showOnboardingStep
   local tTitle, tText
   switch gOnbStep
      case 1
         put "Step 1 of 4 — Pick a part" into tTitle
         put "On the left is your toolbox. Click a shape under SHAPES (try Box or Ball), or something fun under SPECIAL like a Balloon or a Bomb." into tText
         break
      case 2
         put "Step 2 of 4 — Drop it on the stage" into tTitle
         put "Click anywhere on the dark stage in the middle to drop your part, then drag parts to arrange them. The panel on the right always explains the selected part." into tText
         break
      case 3
         put "Step 3 of 4 — Connect with joints" into tTitle
         put "Pick a joint under JOINTS (a Hinge is a pin things can spin around), then click part A and part B to link them. Turn on Motor first to make hinges and wheels drive themselves." into tText
         break
      default
         put "Step 4 of 4 — Press Run" into tTitle
         put "Hit Run (top-right) to start gravity and watch your machine move; press it again to keep building. Open Recipes for ready-made examples to explore." into tText
   end switch
   if there is a field "ui_onb_title" then put tTitle into field "ui_onb_title"
   if there is a field "ui_onb_text" then put tText into field "ui_onb_text"
   if gOnbStep >= 4 then set the label of button "ui_act_onbnext" to "Start building"
   else set the label of button "ui_act_onbnext" to "Next"
   raiseOnboarding
end showOnboardingStep

on onboardingNext
   add 1 to gOnbStep
   if gOnbStep > 4 then dismissOnboarding
   else showOnboardingStep
end onboardingNext

on dismissOnboarding
   removeOnboarding
   set the uSeenOnboarding of this stack to true
   put "Have fun! Pick a part on the left and click the stage to begin." into gStatus
   updateHud
end dismissOnboarding

on removeOnboarding
   deleteByPrefix "ui_onb_"
   if there is a button "ui_act_onbnext" then delete button "ui_act_onbnext"
   if there is a button "ui_act_onbskip" then delete button "ui_act_onbskip"
end removeOnboarding

on raiseOnboarding
   local tName
   repeat for each item tName in "ui_onb_scrim,ui_onb_card,ui_onb_title,ui_onb_text,ui_act_onbskip,ui_act_onbnext"
      if there is a control tName then set the layer of control tName to top
   end repeat
end raiseOnboarding
