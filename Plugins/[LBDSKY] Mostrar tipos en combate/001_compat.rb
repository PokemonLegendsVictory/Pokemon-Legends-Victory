class Battle::FakeBattler
 def effects; return {}; end
 def pbTypes(withExtraType = false); return @pokemon.types; end
end