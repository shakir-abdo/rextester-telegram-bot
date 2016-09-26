require!  {
	'./langs.json'
	'./emoji.json'
	'lodash'
}

help-text = """Execute code.

Usage: `/<language> <code> [/stdin <stdin>]`

/languages (or /langs) for list of languages.
"""

tab = "\n\n#{emoji.bulb}Hit Tab instead of Enter to autocomplete command without sending it right away."

module.exports = (bot) ->
	bot.on-text /^[\/!]lang(uage)?s(@rextester_bot)?\s*$/, (msg) ->
		lodash langs
		.keys!
		.sortBy!
		.map -> "`#it`"
		.join ', '
		|> bot.send-message msg.chat.id, _,
			parse_mode: 'Markdown'


	bot.on-text //^/(\S+)(@rextester_bot)?\s*$//, (msg, [, command]) ->
		if command == 'help' or langs.has-own-property command.to-lower-case!
			bot.send-message do
				msg.chat.id
				# string.repeat bool <=> if bool then string else ""
				help-text + tab.repeat command != 'help'
				parse_mode: 'Markdown'
