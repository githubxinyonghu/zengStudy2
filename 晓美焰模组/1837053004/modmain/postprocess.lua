local PostProcessorEffects = GLOBAL.PostProcessorEffects
local SamplerEffects = GLOBAL.SamplerEffects
local resolvefilepath = GLOBAL.resolvefilepath
local SamplerSizes = GLOBAL.SamplerSizes
local SamplerColourMode = GLOBAL.SamplerColourMode
local SamplerEffectBase = GLOBAL.SamplerEffectBase
local UniformVariables = GLOBAL.UniformVariables

local path = MODROOT.."shaders/homura_timepauseblast.ksh"
table.insert(Assets, Asset("SHADER", path))

AddModShadersInit(function()
	local PostProcessor = GLOBAL.PostProcessor

	-- 常量: 环宽
	-- 变量: [1][2]圆心 [3]外径（畸变和灰色的边界） [4]灰度系数（用于恢复）
	UniformVariables.HOMURA_TIMEPAUSEBLAST = PostProcessor:AddUniformVariable("HOMURA_TIMEPAUSEBLAST", 4)

	PostProcessorEffects.HomuraShader = PostProcessor:AddPostProcessEffect(path)

	PostProcessor:SetEffectUniformVariables(PostProcessorEffects.HomuraShader, UniformVariables.HOMURA_TIMEPAUSEBLAST)
end)

local path = MODROOT.."shaders/homura_blast.ksh"
table.insert(Assets, Asset("SHADER", path))

AddModShadersInit(function()
	local PostProcessor = GLOBAL.PostProcessor

	-- 变量: [1][2]圆心 [3]外径 [4]内径
	UniformVariables.HOMURA_BLAST = PostProcessor:AddUniformVariable("HOMURA_BLAST", 4)

	PostProcessorEffects.HomuraBlast = PostProcessor:AddPostProcessEffect(path)

	PostProcessor:SetEffectUniformVariables(PostProcessorEffects.HomuraBlast, UniformVariables.HOMURA_BLAST)
end)

local path = MODROOT.."shaders/homura_sniper.ksh"
table.insert(Assets, Asset("SHADER", path))

AddModShadersInit(function()
	local PostProcessor = GLOBAL.PostProcessor

	-- 常量: 放大率, 暗度
	-- 变量: [1][2]圆心 [3]外径
	UniformVariables.HOMURA_FOCUS = PostProcessor:AddUniformVariable("HOMURA_FOCUS", 4)

	local BLUR_LEVEL = "high" -- high, low, none

	if BLUR_LEVEL ~= "none" then
		local SIZE = 0.5
		SamplerEffects.HomuraSE_BaseH = PostProcessor:AddSamplerEffect("shaders/blurh.ksh", SamplerSizes.Relative, SIZE, SIZE, SamplerColourMode.RGB, SamplerEffectBase.PostProcessSampler)
	    PostProcessor:SetEffectUniformVariables(SamplerEffects.HomuraSE_BaseH, UniformVariables.SAMPLER_PARAMS)

	    SamplerEffects.HomuraSE_BaseV = PostProcessor:AddSamplerEffect("shaders/blurv.ksh", SamplerSizes.Relative, SIZE, SIZE, SamplerColourMode.RGB, SamplerEffectBase.Shader, SamplerEffects.HomuraSE_BaseH)
	    PostProcessor:SetEffectUniformVariables(SamplerEffects.HomuraSE_BaseV, UniformVariables.SAMPLER_PARAMS)
	else
		SamplerEffects.HomuraSE_BaseV = PostProcessor:AddSamplerEffect("shaders/postprocess_none.ksh", SamplerSizes.Relative, 1.0, 1.0, SamplerColourMode.RGB, SamplerEffectBase.PostProcessSampler)
	end

	local blursampler = SamplerEffects.HomuraSE_BaseV

	if BLUR_LEVEL == "high" then
		local SIZE = 1.0
		local last = blursampler
		for i = 1, 1 do
			last = PostProcessor:AddSamplerEffect("shaders/blurh.ksh", SamplerSizes.Relative, SIZE, SIZE, SamplerColourMode.RGB, SamplerEffectBase.Shader, last)
			PostProcessor:SetEffectUniformVariables(last, UniformVariables.SAMPLER_PARAMS)
			SamplerEffects["HomuraSE_MidLayer_H"..i] = last
			last = PostProcessor:AddSamplerEffect("shaders/blurv.ksh", SamplerSizes.Relative, SIZE, SIZE, SamplerColourMode.RGB, SamplerEffectBase.Shader, last)
			PostProcessor:SetEffectUniformVariables(last, UniformVariables.SAMPLER_PARAMS)
			SamplerEffects["HomuraSE_MidLayer_V"..i] = last
		end
		blursampler = last
	end

    PostProcessor:SetSamplerEffectFilter(blursampler, FILTER_MODE.LINEAR, FILTER_MODE.LINEAR, MIP_FILTER_MODE.NONE)
    PostProcessorEffects.HomuraSniper = PostProcessor:AddPostProcessEffect(path)
    PostProcessor:AddSampler(PostProcessorEffects.HomuraSniper, SamplerEffectBase.Shader, blursampler)

    PostProcessor:SetEffectUniformVariables(PostProcessorEffects.HomuraSniper, UniformVariables.HOMURA_FOCUS)
end)

AddModShadersSortAndEnable(function()
	local PostProcessor = GLOBAL.PostProcessor

	PostProcessor:SetPostProcessEffectAfter(PostProcessorEffects.HomuraShader, PostProcessorEffects.Lunacy)
	PostProcessor:SetPostProcessEffectAfter(PostProcessorEffects.HomuraSniper, PostProcessorEffects.HomuraShader)
	PostProcessor:SetPostProcessEffectAfter(PostProcessorEffects.HomuraBlast, PostProcessorEffects.HomuraSniper)
    
	PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HomuraShader, true)
	PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HomuraBlast, true)
    PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HomuraSniper, false)

	PostProcessor:SetUniformVariable(UniformVariables.HOMURA_TIMEPAUSEBLAST, 0, 0, 0, 0)
	PostProcessor:SetUniformVariable(UniformVariables.HOMURA_FOCUS, 0, 0, 0, 0)
	PostProcessor:SetUniformVariable(UniformVariables.HOMURA_BLAST, 0, 0, 0, 0)
end)

-- 接口
HOMURA_GLOBALS.BLAST = GetModConfigData("blast")

function HOMURA_GLOBALS.SetShaderParams(...)
	if PostProcessor ~= nil then
		PostProcessor:SetUniformVariable(UniformVariables.HOMURA_TIMEPAUSEBLAST, ...)
	end
end

function HOMURA_GLOBALS.SetFocusParams(...)
	if PostProcessor ~= nil then
		PostProcessor:SetUniformVariable(UniformVariables.HOMURA_FOCUS, ...)
	end
end

function HOMURA_GLOBALS.SetFocusEnabled(val)
	if PostProcessor ~= nil then
		PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HomuraSniper, val)
	end
end

function HOMURA_GLOBALS.SetBowBlastParams(...)
	if PostProcessor ~= nil then
		PostProcessor:SetUniformVariable(UniformVariables.HOMURA_BLAST, ...)
	end
end

GLOBAL.bb = HOMURA_GLOBALS.SetBowBlastParams