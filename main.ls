#!./node_modules/.bin/lsc

require! {
	'node-telegram-bot-api': 'Bot'
	'request-promise'
	'lodash'
	'./langs.json'
	'./compiler-args.json'
	'./help'
	'./tips'
}

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

bot = new Bot token,
	polling: true

help bot

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
	([a-zA-Z1-9.#\_+-]+) # language
	(?:@(rextester_bot))? # bot's name, hardcoded for simplicity
	\s+
	([\s\S]+?) # code
	(?:
		\s+
		/stdin
		\s+
		([\s\S]+) # stdin
	)?
$//

reply = (msg, match_) ->
	if verbose
		console.log msg
	bot.send-chat-action msg.chat.id, 'typing'
	execute match_
	.tap ->
		it.Tip = tips.process-output it or tips.process-input msg
	.then format
	.then (result) ->
		bot.send-message do
			msg.chat.id
			result
			reply_to_message_id: msg.message_id
			parse_mode: 'Markdown'
	.catch (e) ->
		bot.send-message do
			msg.chat.id
			e.to-string!
			reply_to_message_id: msg.message_id

bot.on-text regex, reply

function execute [, lang, name, code, stdin]
	lang-id = langs[lang.to-lower-case!]
	if lang-id == void
		return Promise.reject new Error "Unknown language: #lang."

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


console.info 'Bot started.'
