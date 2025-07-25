import Chart from 'chart.js/auto'
import { CHART_COLORS } from './chart_utils'

var info_type = "budget";
var chart_type = "doughnut";
var canvas = document.createElement("canvas");
var buttons = document.createElement("section");
var asterix = document.createElement("label");

function labels(el) {
  let temp_labels;
  let temp_datasets;
  if(info_type === "budget") {
    temp_labels = JSON.parse(el.dataset.budget_labels);
    temp_datasets = JSON.parse(el.dataset.budget_dataset);
  } else {
    temp_labels = JSON.parse(el.dataset.account_labels);
    temp_datasets = JSON.parse(el.dataset.account_dataset);
  }

  temp_labels = temp_labels.filter(function (label, index) {
    if(chart_type === "doughnut")
      return temp_datasets[0]["data"][index] > 0.0;
    else
      return true;
  });

  return temp_labels
}

function datasets(el) {
  let temp_datasets;
  if(info_type === "budget")
    temp_datasets = JSON.parse(el.dataset.budget_dataset);
  else
    temp_datasets = JSON.parse(el.dataset.account_dataset);

  temp_datasets.map(function (dataset, index) {
    dataset["backgroundColor"] = Object.values(CHART_COLORS);
    if(chart_type === "doughnut")
      dataset["data"] = dataset["data"].filter((value) => value > 0.0);
  });

  return temp_datasets;
}

function set_chart(el) {
  var title;
  if(info_type === "budget")
    title = "Budget Amounts";
  else
    title = "Account Amounts";

  title = chart_type === "doughnut" ? title.concat("*") : title;

  const config = {
    type: chart_type,
    data: {
      labels: labels(el),
      datasets: datasets(el)
    },
    options: {
      responsive: true,
      aspectRatio: 2,
      interaction: {
        mode: 'nearest',
        axis: 'xy',
        intersect: false
      },
      plugins: {
        legend: {
          position: 'top',
          display: chart_type === "doughnut"
        },
        title: {
          display: true,
          text: title
        },
      }
    }
  };

  // Calling destroy first makes sure we do not get an error with the canvas already
  // being initialized due to a page refresh.
  Chart.getChart(canvas)?.destroy();
  const chart = new Chart(canvas, config);
  asterix.innerHTML = chart_type === "doughnut" ? "* negative and $0.0 values are removed" : "";

  const actions = [
    {
      name: chart_type === "doughnut" ? 'Switch to bar chart' : 'Switch to pie chart',
      handler(chart) {
        if(chart_type === "doughnut") {
          chart_type = "bar";
        } else {
          chart_type = "doughnut";
        }

        chart.destroy();
        buttons.innerHTML = '';
        chart = set_chart(el);
        chart.update();
      }
    },
    {
      name: info_type === "budget" ? 'Switch to accounts' : 'Switch to budgets',
      handler(chart) {
        if(info_type === "budget") {
          info_type = "account";
        } else {
          info_type = "budget";
        }

        chart.destroy();
        buttons.innerHTML = '';
        chart = set_chart(el);
        chart.update();
      }
    },
  ]

  actions.forEach((a, i) => {
    let button = document.createElement("button");
    button.id = "button"+i;
    button.innerText = a.name;
    button.onclick = () => a.handler(chart);
    button.classList.add("simple_budgeting", "primary", "button");
    buttons.appendChild(button);
  });

  return chart;
}

const OverallBar =  {
  mounted() {
    const ctx = this.el;
    buttons.classList.add("flex", "flex-row", "justify-center", "space-x-5", "my-5");
    asterix.classList.add("text-sm", "text-center");
    ctx.appendChild(canvas);
    ctx.appendChild(buttons);
    ctx.appendChild(asterix);
    set_chart(ctx);
  }
}

export default OverallBar;