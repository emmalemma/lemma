import snarkdown from 'snarkdown'

export markdown = (md) =>
	parts = md.split(/(?:\r?\n){2,}/)
	return snarkdown(parts[0]) if parts.length is 1
	parts.map (l)->
		if [' ', '\t', '#', '-', '*'].some((ch)-> l.startsWith(ch))
			snarkdown(l)
		else "<p>#{snarkdown(l)}</p>"
	.join('\n\n')
