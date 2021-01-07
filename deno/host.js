// Generated by CoffeeScript 2.5.1
var rollup;

import {
  Api
} from './api.js';

import {
  serveWorkers,
  serveApis
} from './workers.js';

import {
  serveBundles,
  runRollup
} from './bundler.js';

import {
  loadConfig
} from './config.js';

import Config from './config.js';

serveWorkers({
  path: './server',
  matches: /_worker\.js$/
});

serveApis({
  path: './server',
  matches: /_api\.js$/
});

serveBundles({
  path: './public'
});

rollup = runRollup();

Api.serve('./public');

(async function() {
  var arg, i, len, m, ref;
  ref = Deno.args;
  for (i = 0, len = ref.length; i < len; i++) {
    arg = ref[i];
    if (m = arg.match(/--config=(.+)/)) {
      await loadConfig(`file:///${Deno.cwd()}/${m[1]}`);
    }
  }
  console.log('Listening on', Config.port);
  await Api.host();
  console.log('Listen server exited.');
  // console.log 'Closing rollup.'
  // rollup.close()
  console.log('Closing Deno.');
  return Deno.exit(1);
})();
