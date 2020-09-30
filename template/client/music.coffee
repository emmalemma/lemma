import {ref, local, remote, delay, cms, reactive, persist, toRaw, watch} from 'ur'

import music from './music.json'

notes =  music.tracks[0].notes

ticks = []
tickMap = {}
for note in notes
	tick = tickMap[note.ticks] ?= {ticks: note.ticks, notes: []}
	tick.notes.push note.midi

ticks = (v for k, v of tickMap)
ticks.sort (a, b)->
	if a.ticks < b.ticks then -1 else 1

console.log ticks

marks = {}
for tick, idx in ticks
	marks[0] ?= {}
	marks[0][idx] ?= {}
	marks[0][idx][note - 40] = true for note in tick.notes

export Music = ()->
	svgᴿ = ref null
	# onMounted -> svgᴿ.value.setAttribute 'preserveAspectRatio', "xMidYMin"

	points = ->
		p = ''
		for i in [0..6]
			theta = Math.PI / 2 + Math.PI * 2 * i / 6
			p += "#{Math.cos theta},#{Math.sin theta} "
		p
	major = 20
	minor = major * 0.8660254
	offset = x: 30, y: 30
	count = 12 * 5 - 1
	notes = [0..count]
	noteCounts = [3,2,3,2,3,3,2,3,2,3,2,3,3]
	marksᴿ = ref marks #remote store: 'global', id: 'musicMarks', value: {}

	activeMusicᴿ = ref null

	musicPreferences = local store: 'global', id: "musicPreferences"
	musicChoices = remote store: 'global', id: "musicChoices"

	state = reactive mode: 'music'

	modes =
		music:
			major: major = 5
			minor: major * 0.8660254

	diatoniccoords = [
		[3, 0]
		[2, 0]
		[3, 1]
		[2, 1]
		[3, 2]
		[4, 3]
		[3, 3]
		[4, 4]
		[3, 4]
		[4, 5]
		[3, 5]
		[4, 6]
		[5, 7]
	]

	chromaticCoords = [
		[3,0]
		[2,0]
		[3,1]
		[2,1]
		[3,2]
		[2,2]
		[3,3]
		[2,3]
		[3,4]
		[2,4]
		[3,5]
		[2,5]
		[3,6]
	]

	coords = chromaticCoords

	diatonicRotation = 16.11
	chromaticRotation = 30
	laneRotation = chromaticRotation

	diatonicOffset = q: 2, r: 7
	chromaticOffset = q:0, r:6
	octaveOffset = chromaticOffset

	(el$, child, {el, label, input, span, svg, g, rect, polygon})->
		label ->
			input type: 'radio', name: 'paper', value: 'music', onChange: ({target: {value}})->state.mode = value
			span 'Music'
		label ->
			input type: 'radio', name: 'paper', value: 'keyboard', onChange: ({target: {value}})->state.mode = value
			span 'Keyboard'
		if state.mode is 'keyboard'
			el.keyboards ->
				for keyboardIdx in [1..6]
					el.spacer
					el 'svg', ref: svgᴿ, viewBox: "0 0 #{major * count * (85/88)} #{major * 9.3}", preserveAspectRatio:"xMidYMin", ->
						el 'g.keyboard', ->
							totalOffset = 0
							for noteIdx in notes
								noteCount = noteCounts[noteIdx % 12]
								if noteCount is 2
									localOffset = 2
									totalOffset -= 1
								else if noteCount is 3
									localOffset = 0
									totalOffset += 1
								for dupeIdx in [1..noteCount] then do (keyboardIdx, noteIdx, dupeIdx)->
									el 'g', transform: "translate(#{minor*noteIdx}, #{major*dupeIdx*6/2 + (totalOffset + localOffset) * major * 3/2}) scale(#{major}) ",  ->
										el 'polygon.hex', class: {mark: marks[keyboardIdx]?[noteIdx]?[dupeIdx]}, points: points(), onClick: ->
											marks[keyboardIdx] ?= {}
											dupeMarks = marks[keyboardIdx][noteIdx] ?= {}
											dupeMarks[dupeIdx] = not dupeMarks[dupeIdx]
		else if state.mode is 'music'
			{minor, major} = modes.music
			el.music ->
				svg ->
					staff = 0
					g.staff ->
						for row in [75, 30]
							for ys in [0..4]
								rect.liner x: -100, y:row+108*ys, height: 18, width: 2000
						for lane in [0..200]
							g.lane transform: "translate(#{lane*major*8}, 600) scale(2) rotate(#{laneRotation})", ->
								for note in [0..68]
									coord = coords[note % 12]
									octave = Math.floor note / 12
									[q, r] = coord
									q += octave * octaveOffset.q
									r += octave * octaveOffset.r
									highlight = if note % 12 in [0, 7]#[4,11]
										true

									g note: "#{note}", coord: coord, transform: "translate(#{major * (Math.sqrt(3) * q  +  Math.sqrt(3)/2 * -r)}, #{-1 * 3/2 * r * major}) scale(#{major}) rotate(#{60})" ,->
										polygon.hex class: {mark: marksᴿ.value[staff]?[lane]?[note], highlight}, points: points(), onClick: do (staff, lane, note)-> ->
											console.log 'setting mark', staff, lane, note
											marksᴿ.value[staff] ?= {}
											marksᴿ.value[staff][lane] ?= {}
											marksᴿ.value[staff][lane][note] = not marksᴿ.value[staff][lane][note]
											console.log 'marksᴿ.value', marksᴿ.value
										# el 'text', transform: "scale(0.05)", note.toString()
			console.log 'render done'
