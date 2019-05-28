ASpaceGems.setup if defined? ASpaceGems

gem "roo", "2.8.2"

if ENV['RELEASE_BRANCH'] == 'qa'
  $stderr.puts "Using map_validator qa release"
  gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: "qa"
else
  $stderr.puts "Using map_validator master release"
  gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: "master"
end


