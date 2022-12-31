---@meta

-- the game can add arbitrary caps, so these are just the ones hardcoded into the engine

---@alias EngineCommandCap
---| "RULEUCC_Move"
---| "RULEUCC_Stop"
---| "RULEUCC_Attack"
---| "RULEUCC_Guard"
---| "RULEUCC_Patrol"
---| "RULEUCC_RetaliateToggle"
---| "RULEUCC_Repair"
---| "RULEUCC_Capture"
---| "RULEUCC_Transport"
---| "RULEUCC_CallTransport"
---| "RULEUCC_Nuke"
---| "RULEUCC_Tactical"
---| "RULEUCC_Teleport"
---| "RULEUCC_Ferry"
---| "RULEUCC_SiloBuildTactical"
---| "RULEUCC_SiloBuildNuke"
---| "RULEUCC_Sacrifice"
---| "RULEUCC_Pause"
---| "RULEUCC_Overcharge"
---| "RULEUCC_Dive"
---| "RULEUCC_Reclaim"
---| "RULEUCC_SpecialAction"
---| "RULEUCC_Dock"
---| "RULEUCC_Script"
---| "RULEUCC_Invalid"

---@alias EngineToggleCap
---| "RULEUTC_ShieldToggle"
---| "RULEUTC_WeaponToggle"
---| "RULEUTC_JammingToggle"
---| "RULEUTC_IntelToggle"
---| "RULEUTC_ProductionToggle"
---| "RULEUTC_StealthToggle"
---| "RULEUTC_GenericToggle"
---| "RULEUTC_SpecialToggle"
---| "RULEUTC_CloakToggle"

---@alias UnitMotionType
---| "RULEUMT_None"
---| "RULEUMT_Land"
---| "RULEUMT_Air"
---| "RULEUMT_Water"
---| "RULEUMT_Biped"
---| "RULEUMT_SurfacingSub"
---| "RULEUMT_Amphibious"
---| "RULEUMT_Hover"
---| "RULEUMT_AmphibiousFloating"
---| "RULEUMT_Special"

---@alias UnitBuildRestriction
---| "RULEUBR_None"
---| "RULEUBR_Bridge"
---| "RULEUBR_OnMassDeposit"
---| "RULEUBR_OnHydrocarbonDeposit"

---@alias WeaponBallisticArc
---| "RULEUBA_None"
---| "RULEUBA_LowArc"
---| "RULEUBA_HighArc"

---@alias WeaponTargetType
---| "RULEWTT_Unit"
---| "RULEWTT_Projectile"
---| "RULEWTT_Prop"

---@alias LayerEnum
---| "LAYER_Air"
---| "LAYER_Land"
---| "LAYER_Orbit"
---| "LAYER_Seabed"
---| "LAYER_Sub"
---| "LAYER_Water"

---@alias Layer
---| "Land"
---| "Seabed"
---| "Sub"
---| "Water"
---| "Air"
---| "Orbital"

---@alias WeaponRangeCategory
---| "UWRC_Undefined"
---| "UWRC_DirectFire"
---| "UWRC_IndirectFire"
---| "UWRC_AntiAir"
---| "UWRC_AntiNavy"
---| "UWRC_Countermeasure"

---@alias VisionMode
---| 'Intel'
---| 'Never'
---| 'Always'

---@alias IntelType
---| "None"
---| "Vision"
---| "WaterVision"
---| "Radar"
---| "Sonar"
---| "Omni"
---| "RadarStealthField"
---| "SonarStealthField"
---| "CloakField"
---| "Jammer"
---| "Spoof"
---| "Cloak"
---| "RadarStealth"
---| "SonarStealth"

---@alias ImpactType
---| "Invalid"
---| "Terrain"
---| "Water"
---| "Air"
---| "Underwater"
---| "Projectile"
---| "ProjectileUnderwater"
---| "Prop"
---| "Shield"
---| "Unit"
---| "UnitAir"
---| "UnitUnderwater"

---@alias CollisionShape
---| "Box"
---| "Sphere"
---| "None"

---@alias AllianceType
---| 'Enemy'
---| 'Ally' 
---| 'Neutral'

---@alias EnumColor
---| "AliceBlue"            #F7FBFF
---| "AntiqueWhite"         #FFEBD6
---| "Aqua"                 #00FFFF
---| "Aquamarine"           #7BFFD6
---| "Azure"                #F7FFFF
---| "Beige"                #F7F7DE
---| "Bisque"               #FFE7C6
---| "Black"                #000000
---| "BlanchedAlmond"       #FFEBCE
---| "Blue"                 #0000FF
---| "BlueViolet"           #8C28E7
---| "Brown"                #A52829
---| "BurlyWood"            #DEBA84
---| "CadetBlue"            #5A9EA5
---| "Chartreuse"           #7BFF00
---| "Chocolate"            #D66918
---| "Coral"                #FF7D52
---| "CornflowerBlue"       #6396EF
---| "Cornsilk"             #FFFBDE
---| "Crimson"              #DE1439
---| "Cyan"                 #00FFFF
---| "DarkBlue"             #00008C
---| "DarkCyan"             #008A8C
---| "DarkGoldenrod"        #BD8608
---| "DarkGray"             #ADAAAD
---| "DarkGreen"            #006500
---| "DarkKhaki"            #BDB66B
---| "DarkMagenta"          #8C008C
---| "DarkOliveGreen"       #526929
---| "DarkOrange"           #FF8E00
---| "DarkOrchid"           #9C30CE
---| "DarkRed"              #8C0000
---| "DarkSalmon"           #EF967B
---| "DarkSeaGreen"         #8CBE8C
---| "DarkSlateBlue"        #4A3C8C
---| "DarkSlateGray"        #294D4A
---| "DarkTurquoise"        #00CFD6
---| "DarkViolet"           #9400D6
---| "DeepPink"             #FF1494
---| "DeepSkyBlue"          #00BEFF
---| "DimGray"              #6B696B
---| "DodgerBlue"           #1892FF
---| "Firebrick"            #B52021
---| "FloralWhite"          #FFFBF7
---| "ForestGreen"          #218A21
---| "Fuchsia"              #FF00FF
---| "Gainsboro"            #DEDFDE
---| "GhostWhite"           #FFFBFF
---| "Gold"                 #FFD700
---| "Goldenrod"            #DEA621
---| "Gray"                 #848284
---| "Green"                #008200
---| "GreenYellow"          #ADFF29
---| "Honeydew"             #F7FFF7
---| "HotPink"              #FF69B5
---| "IndianRed"            #CE5D5A
---| "Indigo"               #4A0084
---| "Ivory"                #FFFFF7
---| "Khaki"                #F7E78C
---| "Lavender"             #E7E7FF
---| "LavenderBlush"        #FFF3F7
---| "LawnGreen"            #7BFF00
---| "LemonChiffon"         #FFFBCE
---| "LightBlue"            #ADDBE7
---| "LightCoral"           #F78284
---| "LightCyan"            #E7FFFF
---| "LightGoldenrodYellow" #FFFBD6
---| "LightGray"            #D6D3D6
---| "LightGreen"           #94EF94
---| "LightPink"            #FFB6C6
---| "LightSalmon"          #FFA27B
---| "LightSeaGreen"        #21B2AD
---| "LightSkyBlue"         #84CFFF
---| "LightSlateGray"       #738A9C
---| "LightSteelBlue"       #B5C7DE
---| "LightYellow"          #FFFFE7
---| "Lime"                 #00FF00
---| "LimeGreen"            #31CF31
---| "Linen"                #FFF3E7
---| "Magenta"              #FF00FF
---| "Maroon"               #840000
---| "MediumAquamarine"     #63CFAD
---| "MediumBlue"           #0000CE
---| "MediumOrchid"         #BD55D6
---| "MediumPurple"         #9471DE
---| "MediumSeaGreen"       #39B273
---| "MediumSlateBlue"      #7B69EF
---| "MediumSpringGreen"    #00FB9C
---| "MediumTurquoise"      #4AD3CE
---| "MediumVioletRed"      #C61484
---| "MidnightBlue"         #181873
---| "MintCream"            #F7FFFF
---| "MistyRose"            #FFE7E7
---| "Moccasin"             #FFE7B5
---| "NavajoWhite"          #FFDFAD
---| "Navy"                 #000084
---| "OldLace"              #FFF7E7
---| "Olive"                #848200
---| "OliveDrab"            #6B8E21
---| "Orange"               #FFA600
---| "OrangeRed"            #FF4500
---| "Orchid"               #DE71D6
---| "PaleGoldenrod"        #EFEBAD
---| "PaleGreen"            #9CFB9C
---| "PaleTurquoise"        #ADEFEF
---| "PaleVioletRed"        #DE7194
---| "PapayaWhip"           #FFEFD6
---| "PeachPuff"            #FFDBBD
---| "Peru"                 #CE8639
---| "Pink"                 #FFC3CE
---| "Plum"                 #DEA2DE
---| "PowderBlue"           #B5E3E7
---| "Purple"               #840084
---| "Red"                  #FF0000
---| "RosyBrown"            #BD8E8C
---| "RoyalBlue"            #4269E7
---| "SaddleBrown"          #8C4510
---| "Salmon"               #FF8273
---| "SandyBrown"           #F7A663
---| "SeaGreen"             #298A52
---| "SeaShell"             #FFF7EF
---| "Sienna"               #A55129
---| "Silver"               #C6C3C6
---| "SkyBlue"              #84CFEF
---| "SlateBlue"            #6B59CE
---| "SlateGray"            #738294
---| "Snow"                 #FFFBFF
---| "SpringGreen"          #00FF7B
---| "SteelBlue"            #4282B5
---| "Tan"                  #D6B68C
---| "Teal"                 #008284
---| "Thistle"              #DEBEDE
---| "Tomato"               #FF6142
---| "Turquoise"            #42E3D6
---| "Violet"               #EF82EF
---| "Wheat"                #F7DFB5
---| "White"                #FFFFFF
---| "WhiteSmoke"           #F7F7F7
---| "Yellow"               #FFFF00
---| "YellowGreen"          #9CCF31
---| "transparent"          #00000000
