# Opifex.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#
amqp = require 'amqp'

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
		vhost: domain || '/' 
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
	self

module.exports = Opifex 

