# copy assets to priv/assets (not using webpack)
# but we need assets for browser tests
assets_dir = Path.join(File.cwd!(), "assets")
priv_dir = Path.join(File.cwd!(), "priv/assets/js")
phoenix_dir = Path.join(File.cwd!(), "deps/phoenix/priv/static")
liveview_dir = Path.join(File.cwd!(), "deps/phoenix_live_view/priv/static")
System.cmd("mkdir", ["-p", priv_dir])
System.cmd("cp", ["-r", assets_dir <> "/live_phone.js", priv_dir <> "/live_phone.js"])
System.cmd("cp", ["-r", phoenix_dir <> "/phoenix.js", priv_dir <> "/phoenix.js"])
System.cmd("cp", ["-r", liveview_dir <> "/phoenix_live_view.js", priv_dir <> "/live_view.js"])

# start test endpoint
LivePhoneTestApp.Application.start()

# start hound for frontend testing
Application.ensure_all_started(:hound)

# start tests but exclude skip and browser by default
ExUnit.start(exclude: [:skip, :browser])
