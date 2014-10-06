# oauthd
# Copyright (C) 2014 Webshell SAS
#
# NEW LICENSE HERE

Q = require 'q'

Path = require 'path'
async = require "async"

# request FIX
qs = require 'request/node_modules/qs'

exports.init = (env) ->
	defer = Q.defer()
	startTime = new Date
	env = env || {}
	# Env is the global environment object. It is usually the 'this' (or @) in other modules
	


	coreModule = require './core'
	dataModule = require './data'
	
	coreModule(env).initEnv() #inits env
	coreModule(env).initConfig() #inits env.config
	coreModule(env).initUtilities() # initializes env, env.utilities, ...
	
	dataModule(env) # initializes env.data
	
	coreModule(env).initOAuth() # might be exported in plugin later
	coreModule(env).initPluginsEngine()

	oldstringify = qs.stringify
	qs.stringify = ->
		result = oldstringify.apply(qs, arguments)
		result = result.replace /!/g, '%21'
		result = result.replace /'/g, '%27'
		result = result.replace /\(/g, '%28'
		result = result.replace /\)/g, '%29'
		result = result.replace /\*/g, '%2A'
		return result

	

	env.pluginsEngine.init (process.cwd(), res) ->
		if not env.plugins.auth
			console.log "No " + "auth".red + " plugin found"
			console.log "You need to install an " + "auth".red + " plugin to run the server"
			defer.reject()
			process.exit()

		# start server
		console.log "oauthd start server"
		exports.server = server = require('./server')(env)

		async.series [
			env.data.providers.getList,
			server.listen
		], (err) ->
			if err
				console.error 'Error while initialisation', err.stack.toString()
				env.pluginsEngine.data.emit 'server', err
				defer.reject err
			else
				console.log 'Server is ready (load time: ' + Math.round(((new Date) - startTime) / 10) / 100 + 's)', (new Date).toGMTString()
				defer.resolve()

		return defer.promise

	
