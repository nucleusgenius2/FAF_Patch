---@meta

---@class EntityBlueprint : HitBox, Blueprint
--- alternate Unit footprint
---@field AltFootprint? FootprintBlueprint
--- unit average density in tons / m^3 (default is 0.49)
---@field AverageDensity? number
--- list of category names that this entity belongs to
---@field Categories CategoryName[]
--- shape to use for collisions with the entity
---@field CollisionShape CollisionShape
--- the desired maximum number of shooters taking shots at the entity
---@field DesiredShooterCap number
--- Unit footprint. If absent, uses the `SizeX` and `SizeZ` fields.
---@field Footprint? FootprintBlueprint
--- component X,X of inertia tensor
---@field InertiaTensorX number
--- component Y,Y of inertia tensor
---@field InertiaTensorY number
--- component Z,Z of inertia tensor
---@field InertiaTensorZ number
--- height of lifebar in OGrids
---@field LifeBarHeight number
--- vertical offset of the lifebar from the entity
---@field LifeBarOffset number
--- if the life bar is rendered or not
---@field LifeBarRender boolean
--- size of lifebar in OGrids
---@field LifeBarSize number
---@field Lifetime
--- module defining entity's class
---@field ScriptModule FileName
--- name of entity's class
---@field ScriptClass string
--- x offset from center of the entity's selection box
---@field SelectionCenterOffsetX number
--- y offset from center of the entity's selection box
---@field SelectionCenterOffsetY number
--- y offset from center of the entity's selection box
---@field SelectionCenterOffsetZ number
--- how far to reduce the top of the collision box for selection (defaults to 0.5)
---@field SelectionYOffset? number
--- Scale the mesh on the X axis by this much when we perform our mouse over entity test
---@field SelectionMeshScaleX number
--- Scale the mesh on the Y axis by this much when we perform our mouse over entity test
---@field SelectionMeshScaleY number
--- Scale the mesh on the Z axis by this much when we perform our mouse over entity test
---@field SelectionMeshScaleZ number
--- Use this much of the top portion of our mesh for intersection test. Useful for naval stuctures that go deep into water
---@field SelectionMeshUseTopAmount number
--- x size of the entity's selection box
---@field SelectionSizeX number
--- y size of the entity's selection box
---@field SelectionSizeY number
--- z size of the entity's selection box
---@field SelectionSizeZ number
---@field SelectionYOffset
--- Use this to modify the thickness of the rendered selection indicator for the unit
---@field SelectionThickness number
--- name of strategic icon to use for this unit
---@field StrategicIconName string
---@field StrategicIconSize
--- 0 tends to render on top, and 255 on bottom (based on factors such the order the strategic
--- icons were created in and the sort priority of the surrounding icons) 
---@field StrategicIconSortPriority integer
--- Use OOB hit test for this unit when camera is below this zoom level
---@field UseOOBTestZoom number

---@class HitBox
---@field CollisionOffsetX number
---@field CollisionOffsetY number
---@field CollisionOffsetZ number
---@field SizeX number
---@field SizeY number
---@field SizeZ number

---@class FootprintBlueprint
---@field MaxSlope? number
---@field MinWaterDepth? number
---@field OccupancyCaps? number
---@field SizeX? number
---@field SizeZ? number
