import Chart from 'chart.js/auto';
import { namedColor, ZOOM_OPTIONS, CrosshairPlugin } from './chart_utils';
import zoomPlugin from 'chartjs-plugin-zoom';
Chart.register(zoomPlugin);
// Chart.register(CrosshairPlugin);

var canvas;
var buttons;

function get_labels(el) {
  return JSON.parse(el.dataset.labels);
}

function get_datasets(el) {
  const datasets = JSON.parse(el.dataset.datasets);
  datasets.map(function (dataset, index) {
    dataset["borderColor"] = namedColor(index);
    dataset["fill"] = false;
    dataset["tension"] = 0.4;
    dataset["radius"] = 0;
    dataset["borderWidth"] = 1.4;
  });

  return datasets;
}

function get_animation(data_length) {
  const totalDuration = 10000;
  const delayBetweenPoints = totalDuration / data_length;
  const previousY = (ctx) => ctx.index === 0 ? ctx.chart.scales.y.getPixelForValue(100) : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;
  return {
    x: {
      type: 'number',
      easing: 'linear',
      duration: delayBetweenPoints,
      from: NaN, // the point is initially skipped
      delay(ctx) {
        if (ctx.type !== 'data' || ctx.xStarted) {
          return 0;
        }
        ctx.xStarted = true;
        return ctx.index * delayBetweenPoints;
      }
    },
    y: {
      type: 'number',
      easing: 'linear',
      duration: delayBetweenPoints,
      from: previousY,
      delay(ctx) {
        if (ctx.type !== 'data' || ctx.yStarted) {
          return 0;
        }
        ctx.yStarted = true;
        return ctx.index * delayBetweenPoints;
      }
    }
  };
}

function set_chart(el) {
  const labels = get_labels(el);
  const datasets = get_datasets(el);
  const animation = get_animation(labels.length);
  const config = {
    type: 'line',
    data: {
      labels: labels,
      datasets: datasets
    },
    plugins: [CrosshairPlugin],
    options: {
      animation,
      responsive: true,
      plugins: {
        zoom: ZOOM_OPTIONS,
        legend: {
          display: datasets.length > 1
        },
        title: {
          display: true,
          text: 'Daily values'
        },
        customCrosshair: {
          enabled: true
        }
      },
      interaction: {
        intersect: false,
        // axis: 'xy',
        // mode: 'index'
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: 'Dollars ($)'
          },
          // suggestedMin: -10,
          // suggestedMax: 200
        }
      }
    },
  };

  // Calling destroy first makes sure we do not get an error with the canvas already
  // being initialized due to a page refresh.
  Chart.getChart(canvas)?.destroy();
  const chart = new Chart(canvas, config);

  const actions = [
    {
      name: "Reset Zoom",
      handler(chart) {
        chart.resetZoom("resize");
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

const DailyValuesChart =  {
  mounted() {
    const ctx = this.el;
    canvas = ctx.querySelector("canvas");
    buttons = document.createElement("section");
    buttons.classList.add("flex", "flex-row", "justify-start", "space-x-5", "my-5");
    ctx.appendChild(buttons);
    const chart = set_chart(ctx);
    this.handleEvent("resize_chart", data => {
      chart.resize();
    });
    this.handleEvent("zoom", data => {
      console.log(chart.scales);
      // zoomStart = chart.data.labels.indexOf(data.zoom_start);
      // zoomEnd = chart.data.labels.indexOf(data.zoom_end);
      zoomStart = data.zoom_start;
      zoomEnd = data.zoom_end;
      console.log(zoomStart)
      chart.zoomScale('x', {min: zoomStart, max: zoomEnd});

      chart.update();
      // chart.resize();
    });
  }
}

export default DailyValuesChart;