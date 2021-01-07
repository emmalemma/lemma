export default Config =
	port: 9010
	jwt:
		keys: ['insecure secret']
		algorithm: 'HS512'
	tls:
		certPath: 'C:\\Certbot\\live\\dev.ought.is\\fullchain.pem',
		keyPath: 'C:\\Certbot\\live\\dev.ought.is\\privkey.pem'


export loadConfig = (path)->
	{default: config} = await import(path)
	Config[k] = v for k, v of config
