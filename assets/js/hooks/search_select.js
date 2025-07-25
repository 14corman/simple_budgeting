// import _ from 'lodash'

let Select = {
  mounted(){

    this.handleEvent("selected", data => {
      if (data.id !== this.el.id) return
      
      this.el.querySelector('input[type="text"]').value = data.term
      this.el.querySelector('input[type="hidden"]').value = data.value
      this.el.querySelector('input').dispatchEvent(
        new Event("input", {bubbles: true}))
    });

    this.el.querySelectorAll("#" + this.el.id + "_dropdown > li").forEach((item) => {
      item.addEventListener("mouseover", event => {
        this.pushEventTo(this.el, "change_index", event.target.dataset.index);
      });
    });
  },
};

export default Select;
