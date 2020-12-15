// Generated by CoffeeScript 2.5.1
var harnesses, hostWorker, onWorkerError, onWorkerMessage, requests;

harnesses = {};

requests = {};

import {
  reactive
} from 'https://esm.sh/@vue/reactivity@3.0.4';

import {
  Api
} from './api.js';

hostWorker = function(target) {
  return Api.router.post(`/${target}/:exportName`, async function(context) {
    var e, request, response, result, rid;
    ({request, response} = context);
    rid = request.serverRequest.conn.rid;
    // console.log context.params, harnesses
    harnesses[target].postMessage([
      'callExport',
      rid,
      context.params.exportName,
      (await request.body().value),
      {
        identity: context.identity,
        headers: context.request.headers
      }
    ]);
    try {
      result = (await new Promise(function(resolve, reject) {
        return requests[rid] = {resolve, reject};
      }));
    } catch (error1) {
      e = error1;
      response.status = 500;
      result = e;
    }
    return response.json = result;
  });
};

Api.router.post("/workers/:target/continuation/:id", async function(context) {
  var e, request, response, result, rid;
  ({request, response} = context);
  rid = request.serverRequest.conn.rid;
  harnesses[context.params.target].postMessage(['continuation', rid, context.params.id, (await request.body().value), context.identity]);
  try {
    result = (await new Promise(function(resolve, reject) {
      return requests[rid] = {resolve, reject};
    }));
  } catch (error1) {
    e = error1;
    response.status = 500;
    result = e;
  }
  return response.json = result;
});

Api.router.post("/workers/:target/reactive/:id", async function(context) {
  var e, request, response, result, rid;
  ({request, response} = context);
  rid = request.serverRequest.conn.rid;
  // console.log context.params, harnesses
  harnesses[context.params.target].postMessage(['reactive', rid, context.params.id, (await request.body().value), context.identity]);
  try {
    result = (await new Promise(function(resolve, reject) {
      return requests[rid] = {resolve, reject};
    }));
  } catch (error1) {
    e = error1;
    response.status = 500;
    result = e;
  }
  return response.json = result;
});

onWorkerMessage = function({
    data: [event, callId, result]
  }) {
  console.log([event, callId, result]);
  if (event === 'resolve') {
    requests[callId].resolve(result);
  } else if (event === 'reject') {
    requests[callId].reject(result);
  }
  return delete requests[callId];
};

onWorkerError = function(error) {
  console.error('worker error');
  console.error(error);
  return error.preventDefault();
};

export var serveWorkers = async function({path, matches}) {
  var entry, harness, i, len, ref, results, target, worker_file, worker_files;
  worker_files = [];
  ref = Deno.readDir(path);
  for await (entry of ref) {
    if (entry.name.match(matches)) {
      worker_files.push(`${path}/${entry.name}`);
    }
  }
  results = [];
  for (i = 0, len = worker_files.length; i < len; i++) {
    worker_file = worker_files[i];
    console.log('loading worker', worker_file);
    target = worker_file.match(/([^\/\\]+)\.[a-z]+$/)[1];
    hostWorker(target);
    harness = harnesses[target] = new Worker(new URL('harness.js', import.meta.url).href, {
      type: 'module',
      deno: true
    });
    harness.postMessage(['loadWorker', `file:///${Deno.cwd()}/${worker_file}`]);
    harness.onmessage = onWorkerMessage;
    results.push(harness.onerror = onWorkerError);
  }
  return results;
};
