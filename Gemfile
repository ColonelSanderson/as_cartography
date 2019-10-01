ASpaceGems.setup if defined? ASpaceGems

if ENV['RELEASE_BRANCH']
  branch = ENV['RELEASE_BRANCH']
    $stderr.puts("Building with xlsx_streaming_reader=#{branch}; map_validator=#{branch}")

  gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: branch
  gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: branch
else
  xlsx_streaming_reader_ref = nil
  map_validator_ref = nil

  gemfile_lock = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
  gemfile_lock.sources.each do |src|
    next unless src.is_a?(Bundler::Source::Git)

    if src.name == 'xlsx_streaming_reader'
      xlsx_streaming_reader_ref = src.ref
    elsif src.name == 'map_validator'
      map_validator_ref = src.ref
    end
  end

  # If we're running without an explicit branch set, just figure out what
  # version is meant to be loaded by looking at Gemfile.lock.
  if map_validator_ref && xlsx_streaming_reader_ref
    $stderr.puts("xlsx_streaming_reader=#{xlsx_streaming_reader_ref}; map_validator=#{map_validator_ref}")
    gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: xlsx_streaming_reader_ref
    gem "map_validator", git: "https://github.com/hudmol/map_validator.git", tag: map_validator_ref
  else
    raise "Please set the RELEASE_BRANCH environment variable to `qa` or `master` " +
          "to select which versions of xlsx_streaming_reader & map_validator to build with"
  end
end


