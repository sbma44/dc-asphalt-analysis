import { rangeMax, rangeMin, rangeStep, calculateDistance } from './config.ts';

let i = rangeMin;
while(i <= rangeMax) {
    console.log(Math.round(calculateDistance(i) * 1000.0));
    i += rangeStep;
}