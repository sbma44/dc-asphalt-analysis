import mapboxgl from 'mapbox-gl';

export const rangeMin = 0;
export const rangeMax = 100;
export const rangeStep = 0.5;
export const center = new mapboxgl.LngLat(-76.9988, 38.9174);
export const range = 5;
export const minimumDistance = 0.1;

export function calculateDistance(val:number):number {
    return ((range - minimumDistance) * (val / 100)) + minimumDistance;
}
