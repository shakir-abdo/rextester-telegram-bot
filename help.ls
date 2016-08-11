require!  {
	'./langs.json'
	'lodash'
}

help-text = """Execute code.

Usage: ```
/<language>
    <code>

/stdin
    <stdin>

```
`/stdin <stdin>` is optional.
/languages (or /langs) for list of languages

"""

module.exports = (bot) ->
	bot.on-text /^[\/!]lang(uage)?s(@rextester_bot)?\s*$/, (msg) ->
		lodash langs
		.keys!
		.sortBy!
		.map -> "`#it`"
		.join ', '
		|> bot.send-message msg.chat.id, _,
			parse_mode: 'Markdown'


	bot.on-text /^[\/!]help(@rextester_bot)?\s*$/, (msg) ->
		bot.send-message msg.chat.id, help-text,
			parse_mode: 'Markdown'
