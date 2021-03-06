-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local table = _G.table
local GetAchievementInfo = _G.GetAchievementInfo
local GetAchievementLink = _G.GetAchievementLink
local ipairs = _G.ipairs
local strfind = _G.strfind
local strupper = _G.strupper
local gsub = _G.gsub

local name = ...
local LazyCurve = LibStub('AceAddon-3.0'):GetAddon(name)
if not LazyCurve then return end

LazyCurve.utils = LazyCurve.utils or {}
LazyCurve.utils.achievement = LazyCurve.utils.achievement or {}
LazyCurve.utils.achievement.achievementKeywordMap = {}

function LazyCurve.utils.achievement:IsAchievementEarned(achievementId)
    if LazyCurve.DB.enableSimulation and LazyCurve.DB.simulatedAchievements[achievementId] then
        return true
    end
    local _, _, _, completed, _ = GetAchievementInfo(achievementId);
    return completed or false
end

function LazyCurve.utils.achievement:GetHighestEarnedAchievement(activityTable, applyMythicThreshold)
    local ret = {}

    if self:IsAchievementEarned(activityTable.achievements.edge) then
        return {activityTable.achievements.edge}
    end

    if self:IsAchievementEarned(activityTable.achievements.curve) then
        table.insert(ret, activityTable.achievements.curve)
    end

    local earnedMythic = self:GetHighestEarnedMythicAchievement(activityTable, applyMythicThreshold)
    if earnedMythic then
        table.insert(ret, earnedMythic)
    end

    if #ret == 0 then
        if self:IsAchievementEarned(activityTable.achievements.normal) then
            ret = {activityTable.achievements.normal}
        end
    end

    return ret
end

function LazyCurve.utils.achievement:GetHighestEarnedMythicAchievement(activityTable, applyMythicThreshold)
    local earnedMythic
    local threshold = -1
    if applyMythicThreshold then
        threshold = LazyCurve.DB.mythicThreshold
        if threshold == 0 then threshold = 999 end
    end
    for i, achievementId in ipairs(activityTable.achievements.mythic) do
        if i >= threshold and  self:IsAchievementEarned(achievementId) then
            earnedMythic = achievementId
        end
    end
    return earnedMythic
end

function LazyCurve.utils.achievement:BuildAchievementKeywordMap()
    local map = {}
    for _, module in LazyCurve:IterateModules() do
        for _, activityTable in ipairs(LazyCurve.utils.module:GetModuleInfoTable(module)) do
            if activityTable.isLatest then
                map.curve = activityTable.achievements.curve
                map.edge = activityTable.achievements.edge
            end

            local activityNames = {
                activityTable.shortName,
                activityTable.alternativeKeyword,
            }

            for _, activityName in ipairs(activityNames) do
                map[activityName .. 'normal'] = activityTable.achievements.normal
                map[activityName .. 'curve'] = activityTable.achievements.curve
                map[activityName .. 'edge'] = activityTable.achievements.edge
                map[activityName .. 'mythic'] = self:GetHighestEarnedMythicAchievement(activityTable) or activityTable.achievements.edge
            end
        end
    end
    self.achievementKeywordMap = map
end

function LazyCurve.utils.achievement:GetAchievementKeywordMap()
    if not self.achievementKeywordMap then
        self:BuildAchievementKeywordMap()
    end

    return self.achievementKeywordMap
end

function LazyCurve.utils.achievement:ReplaceKeywordWithAchievementLink(message, keyword, achievementId)
    keyword = strupper(keyword)
    if strfind(message, keyword) then
        local found, _ = strfind(message, keyword)
        while(found ~= nil) do
            message, _ = gsub(message, keyword, GetAchievementLink(achievementId))
            found, _ = strfind(message, keyword)
        end
    end
    return message
end
