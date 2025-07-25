/*
 * Catch a Ctrl+Enter keypress and trigger the form to submit.
 *
 */
const CtrlEnterSubmits = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.ctrlKey && e.key === 'Enter') {
        let form = e.target.closest('form');
        form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));
        e.stopPropagation();
        e.preventDefault();
      }
    })
  }
}

export default CtrlEnterSubmits
