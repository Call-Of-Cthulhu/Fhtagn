
MELEE_WEAPONS = {}
RANGE_WEAPONS = {}

Weapon = Class(function(self, name, odds, damage, hnd, rng, att, hp)
    self.name = name
    self.odds = odds
    self.damage = self.damage
end)

function AddMelee(weapon)
    if weapon == nil then return end
    table.insert(MELEE_WEAPONS, weapon)
    weapon.ismelee = true
end

function AddRange(weapon)
    if weapon == nil then return end
    table.insert(RANGE_WEAPONS, weapon)
    weapon.isrange = true
end

-- @see Page 64-65 "Weapon Table"
AddMelee(Weapon("FIST",    50, "1d3+db",  1, "touch", 1))
AddMelee(Weapon("GRAPPLE", 25, "special", 2, "touch", 1))
AddMelee(Weapon("HEAD",    10, "1d4+db",  0, "touch", 1))
AddMelee(Weapon("KICK",    25, "1d6+db",  0, "touch", 1))
