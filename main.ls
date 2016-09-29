#!./node_modules/.bin/lsc

require! {
	'node-telegram-bot-api': 'Bot'
	'request-promise'
	'lodash'
	'bluebird': 'Promise'
	'./langs.json'
	'./compiler-args.json'
	'./help'
	'./tips'
	'./emoji.json'
}

Promise.config do
	cancellation: true

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

url = process.env.NOW_URL

msgs = {}


bot = new Bot token,
	if url?
		web-hook:
			host: '0.0.0.0'
			port: process.env.PORT || 8000
	else
		polling : true

(me) <- bot.get-me!.then

botname = me.username

help bot, botname

function format
	lodash it
	.pickBy! # ignore empty values
	.map (val, key) ->
		"""
		*#key*: ```
		#{val.trim!}
		```
		"""
	.join '\n'

regex = //^/
	([\w.#+]+) # language
	(?:@(#botname))?
	\s+
	([\s\S]+?) # code
	(?:
		\s+
		/stdin
		\s+
		([\s\S]+) # stdin
	)?
$//i

reply = (msg, match_) ->
	if verbose
		console.log msg
	execution = execute match_
	bot.send-chat-action msg.chat.id, 'typing' unless execution.is-rejected!
	reply = execution
	.tap ->
		it.Tip = tips.process-output it or tips.process-input msg
	.then format
	.then (result) ->
		bot.send-message do
			msg.chat.id
			result
			reply_to_message_id: msg.message_id
			parse_mode: 'Markdown'
	.catch quiet: true, -> throw it if msg.chat.type == 'private'
	.catch (e) ->
		bot.send-message do
			msg.chat.id
			e.to-string!
			reply_to_message_id: msg.message_id
	msgs[[msg.chat.id, msg.message_id]] = {reply} unless execution.is-rejected!

bot.on-text regex, reply

bot.on 'edited_message_text', (msg) ->
	match_ = regex.exec msg.text
	if not match_
		return

	context = msgs[[msg.chat.id, msg.message_id]]
	if not context or context.reply.is-rejected!
		return reply msg, match_

	context.edit?.cancel!


	execution = execute match_
		.tap ->
			it.Tip = tips.process-output it or tips.process-input msg
		.then format

	processing = context.reply.then (old-msg) ->
		bot.edit-message-text do
			"#{emoji.hourglass}Processing your edit..."
			chat_id: old-msg.chat.id
			message_id: old-msg.message_id
		.catch -> old-msg

	context.edit = Promise.join processing, execution
		.spread (old-msg, result) ->
			bot.edit-message-text do
				result
				chat_id: old-msg.chat.id
				message_id: old-msg.message_id
				parse_mode: 'Markdown'
			.catch ->
				msgs[[msg.chat.id, msg.message_id]] =
					reply: bot.send-message do
						msg.chat.id
						result
						reply_to_message_id: msg.message_id
						parse_mode: 'Markdown'
		.catch (e) ->
			processing.then (old-msg) ->
				bot.edit-message-text do
					e.to-string!
					chat_id: old-msg.chat.id
					message_id: old-msg.message_id
			.catch ->
				msgs[[msg.chat.id, msg.message_id]] =
					reply: bot.send-message do
						msg.chat.id
						e.to-string!
						reply_to_message_id: msg.message_id


function execute [, lang, name, code, stdin]
	lang-id = langs[lang.to-lower-case!]
	if typeof lang-id != 'number'
		error = new Error "Unknown language: #lang."
		error.quiet = not name
		return Promise.reject error

	request-promise do
		method: 'POST'
		url: 'http://rextester.com/rundotnet/api'
		form:
			LanguageChoice: lang-id
			Program: code
			Input: stdin
			CompilerArgs: compiler-args[lang-id] || ''
		json: true

	.promise!


if url?
	bot.set-web-hook "#url/#token"

console.info 'Bot started.'
