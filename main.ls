#!./node_modules/.bin/lsc

require! {
	'node-telegram-bot-api': 'Bot'
	'request-promise'
	'lodash'
	'./langs.json'
	'./compiler-args.json'
	'./help'
}

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

bot = new Bot token,
	polling: true

help bot

bot.onText //
		^
		[/!#]
		([a-zA-Z1-9.#\_+-]+) # language
		(?:@(rextester_bot))? # bot's name, hardcoded for simplicity
		\s+
		# ```
			([\s\S]+?) # code
		# ```
		(?:
			\s+
			[/!]stdin
			\s+
			# ```
				([\s\S]+) # stdin
			# ```
		)?
		$
	//, (msg, [, lang, name, code, stdin]) ->
		if verbose
			console.log msg
		lang-id = langs[lang.toLowerCase!]
		if lang-id == void
			if name or msg.chat.type == 'private'
				bot.send-message msg.chat.id, "Unknown language: `#lang`.",
					reply_to_message_id: msg.message_id
					parse_mode: 'Markdown'
			return

		request-promise do
			method: 'POST'
			url: 'http://rextester.com/rundotnet/api'
			form:
				LanguageChoice: lang-id
				Program: code
				Input: stdin
				CompilerArgs: compiler-args[lang-id] || ''

		.then JSON.parse
		.then ->
			lodash it
			.pickBy! # ignore empty values
			.map (val, key) ->
				"""
				*#key*: ```
				#{val.trim!}
				```
				"""
			.join '\n'
			|> bot.send-message msg.chat.id, _,
				reply_to_message_id: msg.message_id
				parse_mode: 'Markdown'
		.catch (e) ->
			bot.send-message msg.chat.id, e.to-string!,
				reply_to_message_id: msg.message_id

if verbose
	console.log 'Bot started.'
