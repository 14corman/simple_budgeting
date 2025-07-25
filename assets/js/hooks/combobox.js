// import _ from 'lodash'

const Combobox = {
  mounted(){
    //  new Event("submit", {bubbles: true, cancelable: true})


    const search = this.el.querySelector("[data-combobox-search]")
    const input = this.el.querySelector('input[type="hidden"]')

    const filter = _.debounce((e) => {
      
      if (input.value !== "") {
        input.value = ""
        input.dispatchEvent(new Event("input", {bubbles: true}))
      }

      window.liveSocket.execJS(search, search.getAttribute("data-combobox-filter"))
    }, 200)


    search.addEventListener("input", filter)

    this.handleEvent("selected", data => {
      if (data.id !== this.el.id) return
      
      input.value = data.value

      input.dispatchEvent(new Event("input", {bubbles: true}))
    })
  }
}

export default Combobox