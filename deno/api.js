// Generated by CoffeeScript 2.5.1
var AllowedHostnames, HtmlResponse, JsonResponse, NotFound, RequestLogging, abortController,
  indexOf = [].indexOf;

import {
  Oak
} from './deps.js';

import {
  DataStore
} from './datastore.js';

import {
  AuthIdentity
} from './auth.js';

import Config from './config.js';

AllowedHostnames = async function(context, next) {
  var ref;
  if (ref = context.request.url.hostname, indexOf.call(Config.allowedHosts, ref) < 0) {
    context.respond = false;
    console.log('Ignoring request to ', context.request.url.hostname);
    return context.request.serverRequest.conn.close();
  } else {
    return (await next());
  }
};

JsonResponse = async function(context, next) {
  await next();
  if ('json' in context.response) {
    if (context.response.body) {
      console.error({
        json: context.response.json
      });
      throw new Error("Set JSON as well as raw body!");
    }
    context.response.headers.set('Content-Type', 'application/json');
    return context.response.body = JSON.stringify(context.response.json, null, 2);
  }
};

HtmlResponse = async function(context, next) {
  await next();
  if ('html' in context.response) {
    if (context.response.body) {
      console.error({
        html: context.response.html
      });
      throw new Error("Set HTML as well as raw body!");
    }
    context.response.headers.set('Content-Type', 'text/html; charset=utf-8');
    return context.response.body = context.response.html;
  }
};

RequestLogging = async function({request, response}, next) {
  var e;
  console.log(request.method, request.url.href);
  try {
    return (await next());
  } catch (error) {
    e = error;
    console.error("LOG", e.stack);
    return response.status = e.status || 500;
  } finally {
    console.log(request.method, request.url.href, response.status);
  }
};

NotFound = async function(context, next) {
  var e;
  try {
    return (await next());
  } catch (error) {
    e = error;
    console.log('notfound error', e);
    if (context.response.status === 404) {
      context.response.headers.set('Content-Type', 'text/html; charset=utf-8');
      return context.response.body = "<script src='/not_found.js' type='module'></script>";
    }
  }
};

abortController = null;

export var Abort = function() {
  return abortController.abort();
};

export var Api = {
  app: new Oak.Application(),
  router: new Oak.Router(),
  staticStack: [],
  serve: function(path) {
    return this.staticStack.push(async function(context) {
      return (await Oak.send(context, context.request.url.pathname, {
        root: path
      }));
    });
  },
  serveDataObject: function(key, path) {
    var dataStore;
    dataStore = new DataStore(path);
    this.router.get(`/${key}`, async function(context) {
      var objects;
      objects = (await dataStore.readAll());
      return context.response.json = objects;
    });
    this.router.get(`/${key}/:id`, async function(context) {
      var object;
      object = (await dataStore.read(context.params.id));
      return context.response.json = object;
    });
    return this.router.post(`/${key}/:id`, async function(context) {
      var object;
      object = (await context.request.body().value);
      object.state = 'saved';
      await dataStore.write(context.params.id, object);
      return context.response.json = object;
    });
  },
  host: async function(port) {
    var certs, hook, i, len, options, ref;
    this.app.addEventListener('error', function(event) {
      return console.error(event.error);
    });
    if (Config.allowedHosts) {
      this.app.use(AllowedHostnames);
    }
    this.app.use(RequestLogging);
    this.app.use(NotFound);
    this.app.use(JsonResponse);
    this.app.use(HtmlResponse);
    this.app.use(AuthIdentity);
    this.app.use(this.router.routes());
    this.app.use(this.router.allowedMethods());
    ref = this.staticStack;
    for (i = 0, len = ref.length; i < len; i++) {
      hook = ref[i];
      this.app.use(hook);
    }
    abortController = new AbortController();
    this.app.addEventListener('error', function(event) {
      console.error(`${new Date()} Oak uncaught ${event.error.name}`);
      console.error(event.error.stack);
      return abortController.abort();
    });
    certs = Config.tls ? {
      certFile: Config.tls.certPath,
      keyFile: Config.tls.keyPath,
      secure: true
    } : {
      secure: false
    };
    options = Object.assign({
      signal: abortController.signal,
      port: Config.port || 9010,
      secure: true
    }, certs);
    return (await this.app.listen(options));
  }
};
