import TomSelect from "tom-select"


let Combobox = {
  mounted() {
    this.select = this.el.querySelector("select")
    this.setupTom()
  },

  setupTom() {
    let options = JSON.parse(this.el.dataset.options)
    let items = options[0]

    this.tom = new TomSelect(this.select, {
      valueField: 'id',
      labelField: 'name',
      // searchField: 'name',
      loadThrottle: 50,
      options: options,
      load: (query, callback) => {
        this.pushEventTo(this.el, "query", {query}, ({options}, ref) => {
          callback(options)
        })
      },
      searchField: [{field:'label',weight:5},{field:'name',weight:0.5}],
      render: {
        option: function(data, escape) {
          return '<div class="text-sm text-gray-800">' + 
            escape(data.label) + ' - ' + escape(data.name) +
          '</div>';
        },
        item: function(data, escape) {
          return '<div class="text-sm text-gray-800">' + 
            escape(data.label) + ' - ' + escape(data.name) +
          '</div>';
        },
      }
      
    })

  }
}

export default Combobox;