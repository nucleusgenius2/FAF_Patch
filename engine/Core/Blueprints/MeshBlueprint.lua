---@meta

---@class MeshBlueprint : Blueprint
---@field LODs MeshBlueprintLod[]  List of LOD info
---@field IconFadeInZoom number    Zoom level at which to start fading in the strategic icon. Higher values increase how zoomed out you must be for the icon to appear.
---@field SortOrder number         Sort order of mesh we render smallest to largest
---@field UniformScale number      Uniform scale factor
---@field StraddleWater boolean    Render both above and below the water.

---@class MeshBlueprintLod
---@field MeshName FileName       Name of mesh to use for this LOD
---@field AlbedoName FileName     Name of the albedo to use for this LOD
---@field NormalsName FileName    Name of the normal map to use for this LOD
---@field SpecularName FileName   Name of the specular map to use for this LOD
---@field LookupName FileName     Name of the lookup map to use for this LOD
---@field SecondaryName FileName  Name of the secondary map to use for this LOD
---@field ShaderName? string      Name of the shader group to use for this LOD    
---@field TextureName? FileName
---@field LODCutoff number        Zoom level at which this guy starts fading out (higher value increases how zoomed out you must be)
---@field Scrolling? boolean      True if this requires texture scrolling in the shader
---@field Occlude? boolean        True if this may occlude other meshes (for silhouette generation)
---@field Silhouette? boolean     True if this can generate a silhouette if blocked by an occluder

-- TODO: `Shader` is present in some blueprints, but isn't used