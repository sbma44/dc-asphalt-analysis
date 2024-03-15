import mapboxgl from 'mapbox-gl';
import {MapMouseEvent} from 'mapbox-gl';
import circle from '@turf/circle';
import {point} from '@turf/helpers'
import {precomputed} from './precomputed';
import {MapboxAccessToken} from './secrets';
import { rangeMax, rangeMin, rangeStep, center, calculateDistance } from './config';

import 'mapbox-gl/dist/mapbox-gl.css';
import './style.css'

declare global {
  interface Window {
    map: mapboxgl.Map;
  }
}

function fadeOut(element:HTMLElement):void {
  let op = 1;  // initial opacity
  function decreaseOpacity() {
    if (op <= 0){
      element.style.display = 'none'; // Optionally hide the element after fade out
    } else {
      op -= 0.01; // Decreasing the opacity
      element.style.opacity = op.toString();
      requestAnimationFrame(decreaseOpacity);
    }
  }
  requestAnimationFrame(decreaseOpacity);
}

function showTooltip(event:Event):void {
  const slider = event.target as HTMLInputElement;
  const tooltip = document.getElementById('tooltip');
  const value = parseInt(slider!.value);

  // Update the tooltip value and show it
  document.getElementById('tooltipValue')!.textContent = `${calculateDistance(value).toFixed(2)}km`;
  tooltip!.classList.remove('hidden');

  // Position the tooltip above the slider thumb
  const sliderWidth = slider!.offsetWidth;
  const tooltipWidth = tooltip!.offsetWidth - 30;
  const thumbRatio = parseInt(slider!.value) / 100;
  const thumbPosition = thumbRatio * sliderWidth - (tooltipWidth / 2) + (thumbRatio * 20) - 10;
  tooltip!.style.left = `${thumbPosition}px`;

  // Hide the tooltip when not dragging
  slider!.onmouseup = slider!.ontouchend = () => {
      tooltip!.classList.add('hidden');
  };
}

function numberWithCommas(x:number) {
  return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function applyFilter(dist:number):void {
  window.map?.setFilter('residential', ['all',
    ['<=', ['get', 'distance_m'], ['literal', Math.floor(dist * 1000)]],
    ['in', ['get', 'res_type'], ['literal', ['RESIDENTIAL', 'MIXED USE']]],
  ]);
  window.map?.setFilter('residential aura', ['all',
    ['<=', ['get', 'distance_m'], ['literal', Math.floor(dist * 1000)]],
    ['>', ['get', 'res_count'], ['literal', 1]],
    ['in', ['get', 'res_type'], ['literal', ['RESIDENTIAL', 'MIXED USE']]],
  ]);
  window.map?.setFilter('nonresidential', ['all',
    ['<=', ['get', 'distance_m'], ['literal', Math.floor(dist * 1000)]],
    ['==', ['get', 'res_type'], ['literal', 'NONRESIDENTIAL']],
  ]);
  window.map?.setFilter('schools', ['all',
    ['!=', ['get', 'grades'], ['literal', 'Adult']],
    ['<=', ['get', 'dist_from_plant_m'], ['literal', Math.floor(dist * 1000)]],
  ]);
}

function updateStats(dist:number):void {
  let pi = 0;
  while ((pi < precomputed.length) && (precomputed[pi][0] < (1000 * dist)))
    pi++;
  'schools enrollment units'.split(' ').forEach((id, i) => {
    document.getElementById(id)!.textContent = numberWithCommas(precomputed[pi - 1][i + 1]);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  mapboxgl.accessToken = MapboxAccessToken;
  window.map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/sbma44/cltbo5qzq00f501qqg0yrhy8m',
      center: center,
      zoom: 13,
      maxZoom: 20,
      hash: true,
      attributionControl: true
  });

  window.map.on('load', () => {
    const initialDist = calculateDistance(parseInt(document.getElementById('slider')!.getAttribute('value')!));
    window.map.addSource('circle', { type: 'geojson', data: circle(point([center.lng, center.lat]), initialDist) });
    window.map.addLayer({
        'id': 'radius',
        'type': 'fill',
        'source': 'circle',
        'paint': {
            'fill-color': 'yellow',
            'fill-opacity': 0.3,
        }
    }, 'admin-0-boundary-disputed');

    const popup = new mapboxgl.Popup({
      closeButton: false,
      closeOnClick: false,
      offset: 20,
      'anchor': 'bottom'
    });

    // school hover
    window.map.on('mouseenter', 'schools', (e: MapMouseEvent & { features?: mapboxgl.MapboxGeoJSONFeature[] | undefined; } & mapboxgl.EventData) => {
      // Change the cursor style as a UI indicator.
      window.map.getCanvas().style.cursor = 'pointer';

      // Copy coordinates array.
      const coordinates = (e.features![0].geometry as GeoJSON.Point).coordinates.slice();
      const description = `<strong>${e.features![0]?.properties?.name}</strong><br/>${e.features![0]?.properties?.grades} &ndash; ${e.features![0]?.properties?.enrollment} students`;

      // Ensure that if the map is zoomed out such that multiple
      // copies of the feature are visible, the popup appears
      // over the copy being pointed to.
      while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
          coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
      }

      // Populate the popup and set its coordinates
      // based on the feature found.
      popup.setLngLat(new mapboxgl.LngLat(coordinates[0], coordinates[1])).setHTML(description).addTo(window.map);
    });
    window.map.on('mouseleave', 'schools', () => {
        window.map.getCanvas().style.cursor = '';
        popup.remove();
    });

    // multi-unit hover
    window.map.on('mouseenter', 'residential aura', (e: MapMouseEvent & { features?: mapboxgl.MapboxGeoJSONFeature[] | undefined; } & mapboxgl.EventData) => {
      // Change the cursor style as a UI indicator.
      const coordinates = (e.features![0].geometry as GeoJSON.Point).coordinates.slice();
      const description = `<strong>${e.features![0]?.properties?.address}</strong><br/>${e.features![0]?.properties?.res_count} units`;

      // Ensure that if the map is zoomed out such that multiple
      // copies of the feature are visible, the popup appears
      // over the copy being pointed to.
      while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
        coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
      }

      // Populate the popup and set its coordinates
      // based on the feature found.
      popup.setLngLat(new mapboxgl.LngLat(coordinates[0], coordinates[1])).setHTML(description).addTo(window.map);
    });
    window.map.on('mouseleave', 'residential aura', () => {
        window.map.getCanvas().style.cursor = '';
        popup.remove();
    });

    new mapboxgl.Marker()
      .setLngLat(center)
      .addTo(window.map);


    let sliderHasBeenUsed = false;
    document.getElementById('slider')!.addEventListener('input', function(e: Event) {
      showTooltip(e);

      if(!sliderHasBeenUsed) {
        sliderHasBeenUsed = true;
        fadeOut(document.getElementById('banner')!);
      }

      const target = e.target as HTMLInputElement;
      const dist = calculateDistance(parseInt(target.value));

      updateStats(dist);

      const newCircle = circle(point([center.lng, center.lat]), dist);
      (window.map!.getSource('circle') as mapboxgl.GeoJSONSource).setData(newCircle);
    });

    document.getElementById('slider')!.addEventListener('change', function(e: Event) {
      const target = e.target as HTMLInputElement;
      const dist = calculateDistance(parseInt(target.value));
      applyFilter(dist);
    });

    const sliderValue = parseInt(document.getElementById('slider')!.getAttribute('value')!);
    const dist = calculateDistance(sliderValue);
    applyFilter(dist);
    updateStats(dist);
  });
});

document.addEventListener('DOMContentLoaded', () => {
  const slider = document.getElementById('slider')!;
  slider.setAttribute('min', rangeMin.toString());
  slider.setAttribute('max', rangeMax.toString());
  slider.setAttribute('step', rangeStep.toString());
  // console.log(document.getElementById('slider')!.getAttribute('value'));
});