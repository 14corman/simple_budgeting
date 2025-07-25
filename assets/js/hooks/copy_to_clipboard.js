
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.clipboard.writeText(this.el.dataset.copy);
    })
  }
}

export default CopyToClipboard