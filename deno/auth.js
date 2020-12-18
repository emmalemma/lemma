// Generated by CoffeeScript 2.5.1
var makeToken, readToken;

import {
  jwt,
  uuid
} from './deps.js';

import Config from './config.js';

readToken = async function(token) {
  return (await jwt.verify(token, Config.jwt.keys[0], Config.jwt.algorithm));
};

makeToken = async function(payload) {
  return (await jwt.create({
    alg: Config.jwt.algorithm,
    typ: 'jwt'
  }, payload, Config.jwt.keys[0]));
};

export var assignId = async function(context, id) {
  var payload, token;
  token = (await makeToken(payload = {
    guid: id
  }));
  return context.cookies.set('Identity', token, {
    domain: context.request.url.hostname,
    // expires: new Date payload.exp * 1000
    httpOnly: true,
    overwrite: true,
    secure: true,
    sameSite: 'strict'
  });
};

export var destroyId = function(context) {
  return context.cookies.delete('Identity', {
    domain: context.request.url.hostname
  });
};

export var AuthIdentity = async function(context, next) {
  var payload, token;
  token = context.cookies.get('Identity');
  if (token) {
    payload = (await readToken(token));
  }
  if (!payload) {
    payload = {
      guid: uuid.v4.generate()
    };
    assignId(context, payload.guid);
  }
  context.identity = {
    guid: payload.guid
  };
  return next();
};
