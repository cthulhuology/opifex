# Opifex.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#
amqp = require 'amqp'

Opifex = (Url) ->
	[ proto, user, password, host, port, domain, exchange, key, queue, dest, path ] = Url.match(
		///([^:]+)://([^:]+):([^@]+)@([^:]+):(\d+)/([^\/]*)/([^\/]+)/([^\/]+)/([^\/]*)/*([^\/]*)/*([^\/]*)///
	)[1...]
	dest ||= exchange # for publish only
	path ||= key # for publish only, NB: you can not send to # or * routes
	self = (message, headers, info)  ->
		$ = arguments.callee
		[ method, args... ] = JSON.parse message.data.toString()
		$.key = info.routingKey
		$.exchange = info.exchange
		$.queue = info.queue
		$[method]?.apply $, args
	self.exchanges = {}
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
		self.connection.exchange exchange, { durable: false, type: 'topic', autoDelete: true }, (Exchange) ->
			self.exchange = Exchange
		self.connection.queue queue, (Queue) ->
			self.queue = Queue
			self.queue.bind exchange, key
			self.queue.subscribe self
	self.send = (msg) ->
		if self[dest]
			self[dest].publish(path,msg)
		else
			self.connection.exchange dest, { durable: false, type: 'topic', autoDelete: true }, (Exchange) ->
				self[dest] = Exchange
				Exchange?.publish(path,msg)
	self

module.exports = Opifex

