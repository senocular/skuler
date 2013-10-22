class SkulerDrawing

	constructor: (element) ->

		# saved drawing context
		@context = element.getContext "2d"

		@palette = []
		@colorIndex = 0

		@clear()


	clear: ->
		canv = @context.canvas
		@context.clearRect 0, 0, canv.width, canv.height

		@context.strokeStyle = "#000"
		@context.lineWidth = 15
		@context.lineCap = "round"
		@context.lineJoin = "round"
		@context.beginPath()


		@stroke = []
		@strokes = []
		@strokeIndex = 0

		@penX = 0
		@penY = 0


	setColorIndex: (colorIndex) ->
		@colorIndex = Utils.clamp colorIndex, 0, @palette.length - 1

	setPalette: (colors) ->
		@palette = (new SkulerColor color for color in colors)


	getColor: ->
		@palette[@colorIndex]


	getColorAt: (index) ->
		@palette[index]


	strokeStart: (@penX, @penY) ->
		@stroke = [@penX, @penY]


	strokeTo: (penX, penY) ->

		@context.beginPath()
		@context.strokeStyle = Utils.toCSSHex @getColor().calculated
		@context.moveTo @penX, @penY
		@context.lineTo penX, penY
		@context.stroke()

		@penX = penX
		@penY = penY
		@stroke.push @penX, @penY


	strokeStop: ->
		if @stroke.length
			@commitStroke @stroke
			@stroke = []


	undo: ->
		return if @stroke.length # not while drawing
		@strokeIndex = Utils.clamp @strokeIndex - 1, 0, @strokes.length 
		@redraw()


	redo: ->
		return if @stroke.length # not while drawing
		@strokeIndex = Utils.clamp @strokeIndex + 1, 0, @strokes.length
		@redraw()


	commitStroke: (stroke) ->
		# SkulerColor referenced for saturation and lightness only
		color = @palette[@colorIndex]
		@strokes.length = @strokeIndex # clears redo stack
		@strokes.push [@colorIndex, color.saturation, color.lightness, stroke]
		@strokeIndex = @strokes.length


	redraw: ->
		canv = @context.canvas
		@context.clearRect 0, 0, canv.width, canv.height

		for strokeInfo, si in @strokes
			break unless si < @strokeIndex

			[index, saturation, lightness, stroke] = strokeInfo

			color = @getColorAt index
			color.adjust saturation, lightness

			@context.beginPath()

			for x, pi in stroke by 2
				y = stroke[pi + 1]

				if pi is 0
					@context.moveTo x, y
				else
					@context.lineTo x, y
				
			@context.strokeStyle = Utils.toCSSHex color.calculated
			@context.stroke()

		@ # do not accumulate and return loop results (just return this)


	getSVG: ->
		lines = ""

		if @strokeIndex && @strokes.length

			group = lastGroup = null;
			lines = '\t<g fill="none" stroke-linejoin="round" stroke-linecap="round" stroke-width="'+@context.lineWidth+'">\n'
			
			for strokeInfo, si in @strokes
				break unless si < @strokeIndex

				[index, saturation, lightness, stroke] = strokeInfo

				color = new SkulerColor @getColorAt(index).base, saturation, lightness
				hex = Utils.toCSSHex color.calculated
				group = '\t\t<g data-index="'+index+'" data-s="'+saturation+'" data-l="'+lightness+'" stroke="'+hex+'" >\n'

				if group isnt lastGroup
					lines += '\t\t</g>\n' if lastGroup?
					lines += group
					lastGroup = group
				lines += '\t\t\t<polyline points="'+stroke.join(",")+'" />\n'

			lines += '\t\t</g>\n' if lastGroup?
			lines += '\t</g>\n'

		canv = @context.canvas
		w = canv.width
		h = canv.height

		'<?xml version="1.0"?>\n' +
			'<svg width="'+w+'" height="'+h+'" viewPort="0 0 '+w+' '+h+'" ' +
			'version="1.1" xmlns="http://www.w3.org/2000/svg">\n' +
			lines +
			'</svg>'


	readSVG: (svgStr) ->
		parser = new DOMParser
		svg = parser.parseFromString svgStr, "text/xml"
		throw new Error "Expected root node to be <svg>." if svg.firstChild.localName isnt "svg"

		lines = svg.querySelectorAll "polyline"

		@strokes = for line in lines
			att = line.parentNode.attributes
			
			index = Utils.clamp parseInt(att.getNamedItem("data-index").nodeValue), 0, 4
			saturation = Utils.clamp Number(att.getNamedItem("data-s").nodeValue), 0, 1
			lightness = Utils.clamp Number(att.getNamedItem("data-l").nodeValue), 0, 1
			points = line.attributes.getNamedItem("points").nodeValue.split(",").map Number

			[index, saturation, lightness, points]

		@strokeIndex = @strokes.length
		@redraw()



class SkulerColor

	constructor: (@base = 0x000000, @saturation = 1, @lightness = 0) ->
		@calculate()


	adjust: (@saturation, @lightness) ->
		@calculate()


	calculate: ->
		@saturation = Utils.clamp @saturation, 0, 1
		@lightness = Utils.clamp @lightness, 0, 1

		s = 1 - @saturation
		l = 255 * @lightness

		r = (@base >> 16) & 0xFF
		g = (@base >> 8) & 0xFF
		b = (@base) & 0xFF
		r = r + (l - r) * s
		g = g + (l - g) * s
		b = b + (l - b) * s

		@calculated = Math.round(r) << 16 | Math.round(g) << 8 | Math.round(b)


window.SkulerDrawing = SkulerDrawing