# copy assets to priv/assets (not using webpack)
# but we need assets for browser tests
System.cmd(Path.join(File.cwd!(), "copy-static.sh"), [], cd: File.cwd!())

# start test endpoint
LivePhoneTestApp.Application.start()

# start hound for frontend testing
Application.ensure_all_started(:hound)

# start tests but exclude skip and browser by default
ExUnit.start(exclude: [:skip, :browser])
