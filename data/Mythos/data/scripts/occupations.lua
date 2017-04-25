-- @see Page 41 "Alternate Ways"

-- 职业
OCCUPATIONS = {}

local function getname(name)
    return GetString("OCCUPATIONS", name)["NAME"]
end

local Occupation = Class(function(self, name, skills, n_opt_skills, ...)
    if name == nil then
        error("Invalid argument 'name': nil!")
    end
    if type(name) == "function" then
        name = name()
    end
    if type(name) == "string" then
        self.name = getname(name)
    elseif type(name) == "table" and #name > 1 then
        for i, v in ipairs(name) do
            if self.name == nil then
                self.name = getname(v)
            else
                self.name = self.name .. "/" .. getname(v)
            end
        end
    else
        error("Invalid argument 'name': unsupported type '"..type(name).."'!")
    end

    if skills == nil then
        error("Invalid argument 'skills': nil!")
    end
    local opt_skills = {...}
    self._SetSkills = function(cmp)
        cmp.name = self.name
        cmp.skills = skills

        if n_opt_skills then
            cmp.n_opt_skills = n_opt_skills
            cmp.opt_skills = {}
        end

        cmp.AddOptionalSkill = function(self, skill)
            if self.opt_skills == nil then
                return false
            end
            if not self:CanHaveSkill(skill) then
                return false
            end
            table.insert(self.opt_skills, skill)
            return true
        end
        cmp.RemoveOptionalSkill = function(self, skill)
            if self.opt_skills == nil then return end
            table.remove(self.opt_skills, skill)
        end
        cmp.CanHaveSkill = function(self, name)
            for i, v in ipairs(self.skills) do
                if name == v then
                    return true
                end
            end
            if self.n_opt_skills and #self.opt_skills < self.n_opt_skills then
                -- no scope is specified
                -- any skill is optional
                if #opt_skills == 0 then
                    return true
                -- a scope is specified
                -- only skills in the scope are optional
                elseif #opt_skills == 1 then
                    assert(type(opt_skills[1]) == "table", "Invalid argument!")
                    for i, v in ipairs(opt_skills[1]) do
                        if name == v then
                            return true
                        end
                    end
                else
                    -- TODO
                    error("Unsupported operation!")
                    --[[
                    -- ZEALOT
                    if #opt_skills != 2 then error("Unsupported operation!") end
                    local t = opt_skills[1]
                    local n = opt_skills[2]
                    assert(type(t) == "table", "Invalid argument!")
                    assert(type(n) == "number", "Invalid argument!")
                    assert(n != 1, "Unsupported operation!")
                    --]]
                end
            end
            return false
        end
    end
end)

local pk = table.pack
Occupation("ANTIQUARIAN",
    pk("ART","BARGAIN","CRAFT","HISTORY","LIBRARY_USE","OTHER_LANGUAGE","SPOT_HIDDEN"),
    1)
Occupation("ARTIST",
    pk("ART","CRAFT","FAST_TALK","HISTORY","PHOTOGRAPHY","PSYCHOLOGY","SPOT_HIDDEN"),
    1)
Occupation("ATHLETE",
    pk("CLIMB","DODGE","JUMP","MARTIAL_ARTS","RIDE","SWIM","THROW"),
    1)
Occupation("AUTHOR",
    pk("HISTORY","LIBRARY_USE","OccupationULT","OTHER_LANGUAGE","OWN_LANGUAGE","PERSUADE","PSYCHOLOGY"),
    1)
Occupation("CLERGYMAN",
    pk("ACCOUNTING","HISTORY","LIBRARY_USE","LISTEN","OTHER_LANGUAGE","PERSUADE","PSYCHOLOGY"),
    1)
Occupation("CRIMINAL",
    pk("BARGAIN","DISGUISE","FAST_TALK","HANDGUN","LOCKSMITH","SNEAK","SPOT_HIDDEN"),
    1)
Occupation("DILETTANTE",
    pk("ART","CRAFT","CREDIT_RATING","OTHER_LANGUAGE","RIDE","SHOTGUN"),
    2)
Occupation("DOCTOR_OF_MEDICINE",
    pk("BIOLOGY","CREDIT_RATING","FIRST_AID","LATIN","MEDICINE","PHARMACY","PSYCHOANALYSIS","PSYCHOLOGY"),
    1)
Occupation("DRIFTER",
    pk("BARGAIN","FAST_TALK","HIDE","LISTEN","NATURAL_HISTORY","PSYCHOLOGY","SNEAK"),
    1)
Occupation("ENGINEER",
    pk("CHEMISTRY","ELECTR_REPAIR","GEOLOGY","LIBRARY_USE","MECH_REPAIR","OPR_HVY_MCH","PHYSICS"),
    1)
Occupation("ENTERTAINER",
    pk("ART","CREDIT_RATING","DISGUISE","DODGE","FAST_TALK","LISTEN","PSYCHOLOGY"),
    1)
Occupation(function() return pk("FARMER", "FORESTER") end,
    pk("CRAFT","ELECTR_REPAIR","FIRST_AID","MECH_REPAIR","NATURAL_HISTORY","OPR_HVY_MCH","TRACK"),
    1)
Occupation(function() if COC_ERA == 2000 then return "HACKER" else return "CONSULTANT" end end,
    pk("COMPUTER_USE","ELECTR_REPAIR","ELECTRONICS","FAST_TALK","LIBRARY_USE","OTHER_LANGUAGE","PHYSICS"),
    1)
Occupation("JOURNALIST",
    pk("FAST_TALK","HISTORY","LIBRARY_USE","OWN_LANGUAGE","PERSUADE","PHOTOGRAPHY","PSYCHOLOGY"),
    1)
Occupation("LAWYER",
    pk("BARGAIN","CREDIT_RATING","FAST_TALK","LAW","LIBRARY_USE","PERSUADE","PSYCHOLOGY"),
    1)
Occupation("MILITARY_OFFICER",
    pk("ACCOUNTING","BARGAIN","CREDIT_RATING","LAW","NAVIGATE","PERSUADE","PSYCHOLOGY"),
    1)
Occupation("MISSIONARY",
    pk("ART","CRAFT","FIRST_AID","MECH_REPAIR","MEDICINE","NATURAL_HISTORY","PERSUADE"),
    1)
Occupation("MUSICIAN",
    pk("ART","BARGAIN","CRAFT","FAST_TALK","LISTEN","PERSUADE","PSYCHOLOGY"),
    1)
Occupation("PARAPSYCHOLOGIST",
    pk("ANTHROPOLOGY","HISTORY","LIBRARY_USE","OCCULT","OTHER_LANGUAGE","PHOTOGRAPHY","PSYCHOLOGY"),
    1)
Occupation("PILOT",
    pk("ASTRONOMY","ELECTR_REPAIR","MECH_REPAIR","NAVIGATE","OPR_HVY_MCH","PHYSICS","PILOT"),
    1)
Occupation("POLICE_DETECTIVE",
    pk("BARGAIN","FAST_TALK","LAW","LISTEN","PERSUADE","PSYCHOLOGY","SPOT_HIDDEN"),
    1)
Occupation("POLICEMAN",
    pk("DODGE","FAST_TALK","FIRST_AID","GRAPPLE","LAW","PSYCHOLOGY"),
    2,
    pk("BARGAIN","DRIVE_AUTO","MARTIAL_ARTS","RIDE","SPOT_HIDDEN")
Occupation("PROFESSOR",
    pk("BARGAIN","CREDIT_RATING","LIBRARY_USE","OTHER_LANGUAGE","PERSUADE","PSYCHOLOGY"),
    2,
    pk("ANTHROPOLOGY","ARCHAEOLOGY","ASTRONOMY","BIOLOGY","CHEMISTRY","ELECTRONICS","GEOLOGY","HISTORY","LAW","MEDICINE","NATURAL_HISTORY","PHYSICS")
Occupation("SOLDIER",
    pk("DODGE","FIRST_AID","HIDE","LISTEN","MECH_REPAIR","RIFLE","SNEAK"),
    1)
if COC_ERA == 2000 then
Occupation("SPOKESPERSON",
    pk("CREDIT_RATING","DISGUISE","DODGE","FAST_TALK","PERSUADE","PSYCHOLOGY"),
    1)
end
Occupation("TRIBAL_MEMBER",
    pk("BARGAIN","LISTEN","NATURAL_HISTORY","OCCULT","SPOT_HIDDEN","SWIM","THROW"),
    1)
Occupation("ZEALOT",
    pk("CONCEAL","HIDE","LIBRARY_USE","PERSUADE","PSYCHOLOGY"),
    2,
    pk("CHEMISTRY","ELECTR_REPAIR","LAW","PHARMACY","RIFLE"),
    1)












