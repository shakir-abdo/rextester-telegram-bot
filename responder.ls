require! {
	'bluebird': Promise
	'lodash'
	'./emoji.json'
}

module.exports = class Responder
	(@bot) ->
		@msgs = {}

	_get-context: (msg) ->
		@msgs[[msg.chat.id, msg.message_id]] ?= {}

	_respond: (msg, reply, content, options) ->
		s = content.to-string!
		context = @_get-context msg
		(reply || Promise.reject!)
		.then (old-msg) ~>
			@bot.edit-message-text do
				s
				lodash.assign do
					chat_id: old-msg.chat.id
					message_id: old-msg.message_id
					options
		.catch ~>
			if not content.quiet or msg.chat.type == 'private'
				context.reply = @bot.send-message do
					msg.chat.id
					s
					lodash.assign do
						reply_to_message_id: msg.message_id
						options


	_preparing: Promise.coroutine (msg, reply, promise) ->*
		old-msg = yield reply if reply

		return unless promise.is-pending!

		if old-msg
			yield @bot.edit-message-text do
				"#{emoji.hourglass}Processing your edit..."
				chat_id: old-msg.chat.id
				message_id: old-msg.message_id
		else
			yield @bot.send-chat-action msg.chat.id, 'typing'


	respond-when-ready: (msg, promise, res-options, err-options) ->
		context = @_get-context msg

		context.edit?.cancel!
		context.reply = null if context.reply?.is-rejected!

		reply = context.reply

		process = Promise.join do
			promise
			@_preparing msg, reply, promise .catch-return!
		.spread (res) ~> @_respond msg, reply, res, res-options
		.catch  (err) ~> @_respond msg, reply, err, err-options

		if context.reply?
			context.edit  = process
		else
			context.reply = process
