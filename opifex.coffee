# opifex.coffee
#
# © 2013 David J. Goehrig <dave@dloh.org>
#

amqp = require 'amqp'

Opifex = (Url) ->
	console.log Url
	self = (method, args...) ->
		$ = arguments.callee
		$[method]?.apply $, args
	self.connection = ((connection) -> () -> connection)(amqp.createConnection({ url: Url }))
	self

module.exports = { 'Opifex' : Opifex }
