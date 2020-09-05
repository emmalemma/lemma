IDBVERSION = 7

import {reactive, watch, toRaw} from 'vue'
import {doAsync} from './remoting'

export class LocalDatabase
	@open: (dbname, version, stores = [])->
		new Promise (resolve, reject)->
				request = window.indexedDB.open dbname, version
				request.onerror =-> reject request.error
				request.onsuccess =-> resolve new LocalDatabase request.result
				request.onupgradeneeded =->
					db = request.result
					for store in stores
						try
							db.createObjectStore store
						catch e
							console.warn e
					# resolve new LocalDatabase db

	constructor: (@database)->

	deleteObject: (store, key)->
		new Promise (resolve, reject)=>
				transaction = @database.transaction [store], 'readwrite'
				transaction.onerror =-> reject transaction.error

				try
					store = transaction.objectStore store
				catch e
					reject e

				request = store.delete key
				request.onsuccess =-> resolve request.result
				request.onerror =-> reject request.error

	getObject: (store, key)->
		new Promise (resolve, reject)=>
				transaction = @database.transaction [store]
				transaction.onerror =-> reject transaction.error

				try
					store = transaction.objectStore store
				catch e
					reject e

				request = store.get key
				request.onsuccess =-> resolve request.result
				request.onerror =-> reject request.error

	getKeys: (store)->
		new Promise (resolve, reject)=>
				transaction = @database.transaction [store]
				transaction.onerror =-> reject transaction.error

				try
					store = transaction.objectStore store
				catch e
					reject e

				request = store.getAllKeys()
				request.onsuccess =-> resolve request.result
				request.onerror =-> reject request.error

	getAll: (store)->
		new Promise (resolve, reject)=>
				transaction = @database.transaction [store]
				transaction.onerror =-> reject transaction.error

				try
					store = transaction.objectStore store
				catch e
					reject e

				request = store.getAll()
				request.onsuccess =-> resolve request.result
				request.onerror =-> reject request.error

	setObject: (store, key, object)->
		new Promise (resolve, reject)=>
				transaction = @database.transaction [store], 'readwrite'
				transaction.onerror =-> reject transaction.error

				try
					store = transaction.objectStore store
				catch e
					reject e

				request = store.put object, key
				request.onsuccess =-> resolve request.result
				request.onerror =-> reject request.error

export dbState = (db, store, key, def)->
		shell = reactive
			state: 'pending'
			value: null
			error: null
			save: null
		doAsync ->
			shell.state = 'loading'
			try
				database = await db
				shell.value = await database.getObject store, key
				shell.value ?= def
				shell.state = 'loaded'
				watch (->shell.value), (->shell.state = 'edited'), deep: true
				shell.save =->
					shell.state = 'saving'
					await database.setObject store, key,  toRaw shell.value
					shell.state = 'saved'
			catch e
				shell.error = e.message
				shell.state = 'error'
		shell

export dbStore = (db, store)->
	shell = reactive
		state: 'pending'
	shell.promise = doAsync ->
		shell.state = 'loading'
		try
			database = await db
			shell.state = 'loaded'
			shell.get =(key)-> database.getObject store, key
			shell.getAll =()-> database.getAll store
			shell.keys =->database.getKeys store
			shell.set =(key, value)-> database.setObject store, key, value
			shell.delete =(key)-> database.deleteObject store, key
		catch e
			shell.error = e.message
			shell.state = 'error'
		shell
	shell
