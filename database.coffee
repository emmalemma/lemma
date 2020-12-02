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

	constructor: (@database)->

	transactionStoreRequest: (store, mode, requester)->
		new Promise (resolve, reject)=>
			transaction = @database.transaction [store], mode
			transaction.onerror =-> reject transaction.error

			try
				request = requester transaction.objectStore store
			catch e
				reject e

			request.onsuccess =-> resolve request.result
			request.onerror =-> reject request.error

	deleteObject: (store, key)->
		@transactionStoreRequest store, 'readwrite', (transaction)-> transaction.delete key

	getObject: (store, key)->
		@transactionStoreRequest store, 'readonly', (transaction)-> transaction.get key

	getKeys: (store)->
		@transactionStoreRequest store, 'readonly', (transaction)-> transaction.getAllKeys()

	getAll: (store)->
		@transactionStoreRequest store, 'readonly', (transaction)-> transaction.getAll()

	setObject: (store, key, object)->
		@transactionStoreRequest store, 'readwrite', (transaction)-> transaction.put object, key
