// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css"
import "../../../assets/live_phone.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "../../deps/phoenix_html"
import {Socket} from "../../deps/phoenix"
import {LiveSocket} from "../../deps/phoenix_live_view"

// Load and specify the LivePhone Component Hook
import LivePhone from "../../../assets/live_phone"
let Hooks = {}
Hooks.LivePhone = LivePhone

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {
    _csrf_token: csrfToken
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Autofocus on page load
const autofocusedElements = document.querySelectorAll('input');
if (autofocusedElements.length) {
  autofocusedElements[0].focus();
}
