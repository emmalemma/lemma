// Generated by CoffeeScript 2.5.1
var continuations, idx, loadWorker, module, processRpc, reactiveIds, reactives, registerContinuation, registerReactive, wrapValue;

module = {};

import {
  isReactive,
  toRaw
} from 'https://esm.sh/@vue/reactivity@3.0.4';

loadWorker = async function(filename) {
  var e;
  try {
    return module = (await import(filename));
  } catch (error) {
    // console.log 'loaded module', module
    e = error;
    console.error('module load error', filename);
    console.error(e);
    throw e;
  }
};

wrapValue = function(result) {
  return {
    raw: result
  };
};

idx = 0;

continuations = {};

registerContinuation = function(fn) {
  var id;
  id = idx += 1;
  continuations[id] = fn;
  return {
    continue: id
  };
};

reactiveIds = new WeakMap();

reactives = {};

registerReactive = function(rx) {
  var id;
  id = reactiveIds.get(rx) || (id = idx += 1, reactiveIds.set(rx, id), id);
  reactives[id] = rx;
  return {
    reactive: id,
    raw: toRaw(rx)
  };
};

processRpc = function(callId, result) {
  result = (function() {
    switch (typeof result) {
      case 'function':
        return registerContinuation(result);
      case 'object':
        if (isReactive(result)) {
          return registerReactive(result);
        } else {
          return wrapValue(result);
        }
        break;
      default:
        return wrapValue(result);
    }
  })();
  return postMessage(['resolve', callId, result]);
};

self.onmessage = async function({
    data: [event, ...args]
  }) {
  var callId, context, continuationId, e, exp, k, raw, rxId, v;
  console.log(event, args);
  try {
    if (event === 'loadWorker') {
      return loadWorker(args[0]);
    } else if (event === 'callExport') {
      [callId, exp, args, context] = args;
      try {
        if (typeof module[exp] === 'function') {
          if (!Array.isArray(args)) {
            args = [args];
          }
          return processRpc(callId, (await module[exp].apply(context, args)));
        } else {
          // if typeof args is 'object'
          // 	module[exp][k] = v for k, v of args
          return postMessage(['resolve', callId, toRaw(module[exp])]);
        }
      } catch (error) {
        e = error;
        console.error(e);
        return postMessage([
          'reject',
          callId,
          {
            message: e.message
          }
        ]);
      }
    } else if (event === 'continuation') {
      [callId, continuationId, args] = args;
      return processRpc(callId, (await continuations[continuationId].apply(identity, args)));
    } else if (event === 'reactive') {
      [callId, rxId, raw] = args;
      for (k in raw) {
        v = raw[k];
        reactives[rxId][k] = v;
      }
      return postMessage([
        'resolve',
        callId,
        {
          done: true
        }
      ]);
    }
  } catch (error) {
    e = error;
    console.error(e);
    throw e;
  }
};
