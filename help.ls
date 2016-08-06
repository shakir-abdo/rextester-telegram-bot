require!  {
	'./langs.json'
	'lodash'
}

help-text = """Execute code.

Usage: <code>
/&lt;language&gt; ```
    code
```
/stdin ```
    stdin
```
</code>
<code>/stdin</code> is optional.
/languages (or /langs) for list of languages

"""

module.exports = (bot) ->
	bot.on-text /^[\/!]lang(uage)?s(@rextester_bot)?$/, (msg) ->
		lodash langs
		.keys!
		.sortBy!
		.map -> "`#it`"
		.join ', '
		|> bot.send-message msg.chat.id, _,
			parse_mode: 'Markdown'


	bot.on-text /^[\/!]help(@rextester_bot)?$/, (msg) ->
		bot.send-message msg.chat.id, help-text,
			parse_mode: 'HTML'
