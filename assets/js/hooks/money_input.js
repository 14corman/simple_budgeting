/*

*/

// import _ from 'lodash'

const MoneyInput = {
  mounted(){
    this.handleEvent("changed", data => {
      if (data.id !== this.el.id) return
      this.el.querySelector('input[type="tel"]').value = data.value;
      
      this.el.querySelector('input').dispatchEvent(
        new Event("input", {bubbles: true}))

      return false;
    })
  }
}

export default MoneyInput;