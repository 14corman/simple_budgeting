import { getRelativePosition } from 'chart.js/helpers';

export const CHART_COLORS = {
  red: 'rgb(212, 55, 55)',
  orange: 'rgb(199, 108, 17)',
  yellow: 'rgb(181, 184, 3)',
  green: 'rgb(46, 179, 57)',
  light_blue: 'rgb(37, 183, 202)',
  blue: 'rgb(43, 148, 218)',
  purple: 'rgb(137, 83, 245)',
  pink: 'rgb(233, 46, 223)',
  grey: 'rgb(120, 122, 124)'
};

export const NAMED_COLORS = [
  CHART_COLORS.red,
  CHART_COLORS.orange,
  CHART_COLORS.yellow,
  CHART_COLORS.green,
  CHART_COLORS.light_blue,
  CHART_COLORS.blue,
  CHART_COLORS.purple,
  CHART_COLORS.pink,
  CHART_COLORS.grey,
];

export const ZOOM_OPTIONS = {
  zoom: {
    // wheel: {
    //   enabled: true, // Enable zooming with mouse wheel
    // },
    pinch: {
      enabled: true
    },
    drag: {
      enabled: true, // Enable click-and-drag to zoom
      borderColor: 'rgba(255, 0, 0, 0.5)', // Optional: Customize drag box color
      borderWidth: 1, // Optional: Customize drag box border width
      backgroundColor: 'rgba(255, 0, 0, 0.1)', // Optional: Customize drag box background
    },
    mode: 'x', // 'x', 'y', or 'xy' for zooming direction
  },
  pan: {
    enabled: true, // Enable panning after zooming
    modifierKey: 'ctrl',
    mode: 'x', // 'x', 'y', or 'xy' for panning direction
  }
};

export function namedColor(index) {
  return NAMED_COLORS[index % NAMED_COLORS.length];
}

const getOrCreateTooltip = (chart) => {
  let leftTooltipEl = chart.canvas.parentNode.querySelector('div .left-tooltip');
  let bottomTooltipEl = chart.canvas.parentNode.querySelector('div .bottom-tooltip');

  if (!leftTooltipEl) {
    leftTooltipEl = document.createElement('div');
    leftTooltipEl.style.background = 'rgba(0, 0, 0, 0.7)';
    leftTooltipEl.style.borderRadius = '3px';
    leftTooltipEl.style.color = 'white';
    leftTooltipEl.style.opacity = 1;
    leftTooltipEl.style.pointerEvents = 'none';
    leftTooltipEl.style.position = 'absolute';
    leftTooltipEl.style.transform = 'translate(-50%, 0)';
    leftTooltipEl.style.transition = 'all .1s ease';
    leftTooltipEl.classList.add("left-tooltip");

    bottomTooltipEl = document.createElement('div');
    bottomTooltipEl.style.background = 'rgba(0, 0, 0, 0.7)';
    bottomTooltipEl.style.borderRadius = '3px';
    bottomTooltipEl.style.color = 'white';
    bottomTooltipEl.style.opacity = 1;
    bottomTooltipEl.style.pointerEvents = 'none';
    bottomTooltipEl.style.position = 'absolute';
    bottomTooltipEl.style.transform = 'translate(-50%, 0)';
    bottomTooltipEl.style.transition = 'all .1s ease';
    bottomTooltipEl.classList.add("bottom-tooltip");

    chart.canvas.parentNode.appendChild(leftTooltipEl);
    chart.canvas.parentNode.appendChild(bottomTooltipEl);
  }

  return {leftTooltipEl, bottomTooltipEl};
};

let crosshair;
export const CrosshairPlugin = {
  id: 'customCrosshair',
  events: ['mousemove'],
  beforeDatasetsDraw: (chart, args, options) => {
    if(crosshair && options.enabled) {
      const {ctx} = chart;
      ctx.save();

      crosshair.forEach((line, index) => {
        ctx.beginPath();
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 15]);
        ctx.strokeStyle = "rgba(102, 102, 102, 1)";
        ctx.moveTo(line.startX, line.startY);
        ctx.lineTo(line.endX, line.endY);
        ctx.stroke();
      });

      ctx.restore();
    }
  },
  afterEvent: (chart, args) => {
    const {chartArea: {left, right, top, bottom}} = chart;

    let tooltips = getOrCreateTooltip(chart);

    const x = args.event.x;
    const y = args.event.y;
    if(!args.inChartArea && crosshair) {
      crosshair = undefined;
      args.changed = true;
      tooltips.leftTooltipEl.style.opacity = 0;
      tooltips.bottomTooltipEl.style.opacity = 0;
    } else if(args.inChartArea) {
      crosshair = [
        {
          startX: x,
          startY: top,
          endX: x,
          endY: bottom
        },
        {
          startX: left,
          startY: y,
          endX: right,
          endY: y
        }
      ];

      const rect = chart.canvas.getBoundingClientRect();
      const xPosition = rect.left + window.scrollX;
      const yPositionTop = rect.top + window.scrollY;
      const yPositionBottom = rect.bottom + window.scrollY;

      tooltips.leftTooltipEl.style.left = xPosition + 'px';
      tooltips.leftTooltipEl.style.top = yPositionTop + y + 'px';

      tooltips.bottomTooltipEl.style.left = xPosition + x + 'px';
      tooltips.bottomTooltipEl.style.top = yPositionBottom  + 'px';

      const canvasPosition = getRelativePosition(args.event, chart);
      const dataX = chart.scales.x.getValueForPixel(canvasPosition.x);
      const dataY = chart.scales.y.getValueForPixel(canvasPosition.y);

      tooltips.leftTooltipEl.innerHTML = "$" + Math.round(dataY * 100) / 100;
      tooltips.bottomTooltipEl.innerHTML = chart.data.labels[dataX];

      tooltips.leftTooltipEl.style.opacity = 1;
      tooltips.bottomTooltipEl.style.opacity = 1;
      args.changed = true;
    }
  },
  defaults: {
    enabled: true
  }
};