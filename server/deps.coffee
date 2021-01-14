import {Application, Router, send} from "https://deno.land/x/oak@v6.4.1/mod.ts"
Oak = {Application, Router, send}

import * as fs from "https://deno.land/std@0.80.0/fs/mod.ts"

import * as jwt from "https://deno.land/x/djwt@v2.0/mod.ts";
export {jwt}

import * as uuid from "https://deno.land/std@0.80.0/uuid/mod.ts";
export {uuid}

export {Oak, fs}
