#!./node_modules/.bin/lsc
# add langs.json

require! {
	'node-telegram-bot-api': 'Bot'
	'http'
	'querystring'
	'json-stream'
	'lodash'
	'./token.json'
	'./langs.json'
}

bot = new Bot token,
	polling: true

bot.onText //
		^
		[/!#]
		([a-zA-Z.#+-]+) # language
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
		console.log msg
		lang-id = langs[lang.toLowerCase!]
		if lang-id == void
			if name or msg.chat.type == 'private'
				bot.send-message msg.chat.id, "Unknown language: `#lang`.",
					reply_to_message_id: msg.message_id
					parse_mode: 'Markdown'
			return

		http.request do
			method: 'POST'
			hostname: 'rextester.com'
			path: '/rundotnet/api'
			headers:
				'Content-Type': 'application/x-www-form-urlencoded'
			(res) ->
				res
				.pipe json-stream!
				.on 'data', ->
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

		.end querystring.stringify do
			LanguageChoice: lang-id
			Program: code
			Input: stdin
			CompilerArgs: ''
