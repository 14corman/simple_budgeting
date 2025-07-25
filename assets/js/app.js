// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
// import copy from 'copy-to-clipboard'

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import SearchSelect from "./hooks/search_select"
import Combobox from "./hooks/combobox"
import CopyToClipboard from './hooks/copy_to_clipboard'
import TomSelectCombobox from "./hooks/tom-select"
import TomSearchSelect from "./hooks/tom-search-select"
import MoneyInput from "./hooks/money_input"
import OverallBar from "./hooks/overall_bar_chart"
import DailyValuesChart from "./hooks/daily_values_chart"
import CtrlEnterSubmits from "./hooks/ctrl_enter_submits"
import * as BrowserTimezone from "./hooks/browser_timezone"

let Hooks = {}
Hooks.SearchSelect = SearchSelect
Hooks.Combobox = Combobox
Hooks.CopyToClipboard = CopyToClipboard
Hooks.TomSelectCombobox = TomSelectCombobox
Hooks.TomSearchSelect = TomSearchSelect
Hooks.MoneyInput = MoneyInput
Hooks.OverallBar = OverallBar
Hooks.DailyValuesChart = DailyValuesChart
Hooks.CtrlEnterSubmits = CtrlEnterSubmits
Hooks.BrowserTimezone = BrowserTimezone

let AllHooks = {
  ...Hooks
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: AllHooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
// window.copy = copy

window.addEventListener("phx:js-exec", ({detail}) => {
  document.querySelectorAll(detail.to).forEach(el => {
      liveSocket.execJS(el, el.getAttribute(detail.attr))
  })
})

