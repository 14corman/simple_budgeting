import TomSelect from "tom-select"
// import _ from 'lodash'


let TomSearchSelect = {
  mounted() {
    this.select = this.el.querySelector("select")

    if (this.select.dataset.tomCreateable === "") {
      this.createable = true
    } else {
      this.createable = false
    }

    this.setupTom()
    this.handleEvent("tom_update", this.handleUpdate.bind(this))
    this.handleEvent("tom_clear", this.handleClear.bind(this))
  },

  setupTom() {
    // let options = JSON.parse(this.el.dataset.options)
    // let items = options[0]

    let options = {}

    if (this.createable) {
      options["create"] = true
      options["plugins"] = ['drag_drop']
    }

  //   plugins: ['drag_drop'],
	// persist: false,

    this.tom = new TomSelect(this.select, {
      ...options,
      selectOnTab: true,
      // sortField:[{field:'$score'},{field:'$order'}], 
      score: function(search) {
        var score = this.getScoreFunction(search);        
        return function(item) {
          let {text: term} = item
          let terms = term.split(" - ")
          
          if (terms.length > 1 && terms[0].toUpperCase() == search.toUpperCase()) {
            return 1.1;
          } else {
            return score(item);
          }
        };
      },
      // valueField: 'id',
      // labelField: 'name',
      // searchField: 'name',
      // options: options,
      // searchField: [{field:'label',weight:5},{field:'name',weight:0.5}],
      // render: {
      //   option: function(data, escape) {
      //     console.log(data)
      //     return '<div class="text-sm text-gray-800">' + 
      //       escape(data.label) + ' - ' + escape(data.name) +
      //     '</div>';
      //   },
      //   item: function(data, escape) {
      //     return '<div class="text-sm text-gray-800">' + 
      //       escape(data.label) + ' - ' + escape(data.name) +
      //     '</div>';
      //   },
      // }
      
    })

  }, 

  handleClear(payload) {
    if (payload.id != this.el.id) {
      return 
    }

    this.tom.clear()
  },

  handleUpdate(payload) {
    if (payload.id != this.el.id) {
      return 
    }

    // this.tom.clear()
    this.tom.clearOptions()
    payload.options.forEach(option => {
      if (typeof option === 'object') {
        this.tom.addOption(option)
      } else {
        this.tom.addOption({value: option, text: option})
      }
    })
    
    if (payload.value != this.tom.getValue()) {
      this.tom.addItem(payload.value, true)
    }


    // console.log(this.tom.addOptions(payload.options, false))
  }
}

export default TomSearchSelect;