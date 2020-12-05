// Generated by CoffeeScript 2.5.1
(function() {
  var loadWorker, module;

  module = {};

  loadWorker = async function(filename) {
    var e;
    try {
      return module = (await import(filename));
    } catch (error) {
      e = error;
      console.error('module load error', filename);
      console.error(e);
      throw e;
    }
  };

  self.onmessage = async function({
      data: [event, ...args]
    }) {
    var callId, e, exp, result;
    try {
      if (event === 'loadWorker') {
        return loadWorker(args[0]);
      } else if (event === 'callExport') {
        [callId, exp, args] = args;
        try {
          console.log('calling', module, exp, args);
          result = (await module[exp].apply(module[exp], args));
          return postMessage(['resolve', callId, result]);
        } catch (error) {
          e = error;
          return postMessage(['reject', callId, e]);
        }
      }
    } catch (error) {
      e = error;
      console.error(e);
      throw e;
    }
  };

}).call(this);
