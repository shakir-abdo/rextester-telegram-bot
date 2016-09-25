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
}

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

url = process.env.NOW_URL


bot = new Bot token,
	if url?
		web-hook:
			host: '0.0.0.0'
			port: process.env.PORT || 8000
	else
		polling : true

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
	execution = execute match_
	bot.send-chat-action msg.chat.id, 'typing' unless execution.is-rejected!
	execution
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

bot.on-text regex, reply

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
