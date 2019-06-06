ASpaceGems.setup if defined? ASpaceGems

if ENV['RELEASE_BRANCH'] == 'qa'
  $stderr.puts "Using map_validator qa release"
  gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: "qa"
  gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: "qa"
else
  $stderr.puts "Using map_validator master release"
  gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: "master"
  gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: "master"
end


