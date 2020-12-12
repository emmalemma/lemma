// Generated by CoffeeScript 2.5.1
import {
  Api
} from './api.js';

import {
  serveWorkers
} from './workers.js';

import {
  serveBundles,
  watchBundle
} from './bundler.js';

serveWorkers({
  path: '.',
  matches: /_worker\.js$/
});

serveBundles({
  path: './public'
});

Api.serve('./public');

(async function() {
  await watchBundle();
  console.log('Listening on', 9010);
  return Api.host(9010);
})();
