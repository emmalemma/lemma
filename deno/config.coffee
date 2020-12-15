export default Config = {}

export loadConfig = (path)->
	{default: config} = await import(path)
	Config[k] = v for k, v of config
