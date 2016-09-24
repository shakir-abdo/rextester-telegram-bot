exports.process-input = (msg) ->
	| msg.entities.1?.type not in ['pre', 'code']
		=> "Wrap your code in triple backticks to display it in monospace."

exports.process-output = (o) ->
	| o.Errors or o.Result == ""
		=> "Mistake? Edit your message, I'll adjust my response."
