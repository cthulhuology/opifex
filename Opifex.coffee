# Opifex.coffee

amqp = require 'amqp'
spawn = (require 'child_process').spawn

Opifex = (Url) ->
	[ proto, user, password, host, port, domain, exchange, queue, key ] = Url.match(
		///([^:]+)://([^:]+):([^@]+)@([^:]+):(\d+)/([^\/]*)/([^\/]+)/([^\/]+)/(.*)///
	)[1...]
	self = (message, headers, info)  ->
		$ = arguments.callee
		[ method, args... ] = JSON.parse message.data.toString()
		$[method]?.apply $, args
	self.connection = amqp.createConnection 
		host: host,
		port: port,
		login: user,
		password: password,
		vhost: '/' 
	self.connection.on 'error', (Message) ->
		console.log "Connection error", Message
	self.connection.on 'end', () ->
		console.log "Connection closed"
	self.connection.on 'ready', () ->
		self.connection.exchange exchange
		self.connection.queue queue, (Queue) -> 
			self.queue = Queue
			self.queue.bind exchange, key
			self.queue.subscribe self
	self.log = (message...) ->
		console.log.apply console, message
	self.run = (command, args...) ->
		proc = spawn(command,args)
		proc.stdout.on 'data', (data) -> console.log "stdout: #{data}"
		proc.stderr.on 'data', (data) -> console.log "stderr: #{data}"
		proc.on 'close', (code) -> console.log "#{command} exited: #{code}"
	self

module.exports = Opifex 

