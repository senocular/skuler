class SkulerDrawing

	@MAX_PEN_SIZE: 5
	@START_PEN_SIZE: 3

	constructor: (element) ->

		# saved drawing context
		@context = element.getContext "2d"

		@palette = []
		@colorIndex = 0

		@stroke = []
		@strokes = []
		@strokeIndex = 0

		@penSize = SkulerDrawing.START_PEN_SIZE;

		@clear()


	clear: ->
		canv = @context.canvas
		@context.clearRect 0, 0, canv.width, canv.height

		@context.strokeStyle = "#000"
		@context.lineCap = "round"
		@context.lineJoin = "round"

		@strokeStop()

		@stroke = []
		@strokes = []
		@strokeIndex = 0

		@penX = 0
		@penY = 0


	setPalette: (colors) ->
		@strokeStart() if @isStroking()
		@palette = (new SkulerColor color for color in colors)


	setColorIndex: (colorIndex) ->
		@strokeStart() if @isStroking()
		@colorIndex = Utils.clamp colorIndex, 0, @palette.length - 1


	setPenSize: (size) ->
		@strokeStart() if @isStroking()
		@penSize = Utils.clamp size, 1, SkulerDrawing.MAX_PEN_SIZE


	adjustColor: (s, l) ->
		@strokeStart() if @isStroking()
		@getColor().adjust s, l


	getColor: ->
		@palette[@colorIndex]


	getColorAt: (index) ->
		@palette[index]


	getLineWidth: (size = @penSize) ->
		Math.pow 2, size + 1


	getStrokeStyle: (color = null) ->
		color = @getColor() unless color?
		Utils.toCSSHex color.calculated


	strokeStart: (@penX = @penX, @penY = @penY) ->
		@strokeStop()
		@stroke = [@penX, @penY]


	strokeTo: (penX, penY) ->
		@context.beginPath()
		@context.strokeStyle = @getStrokeStyle()
		@context.lineWidth = @getLineWidth()
		@context.moveTo @penX, @penY
		@context.lineTo penX, penY
		@context.stroke()

		@penX = penX
		@penY = penY
		@stroke.push @penX, @penY


	strokeStop: ->
		if @isStroking()
			@commitStroke @stroke
			@stroke = []


	isStroking: ->
		@stroke.length


	undo: ->
		@strokeStop()
		@strokeIndex = Utils.clamp @strokeIndex - 1, 0, @strokes.length 
		@redraw()


	redo: ->
		@strokeStop()
		@strokeIndex = Utils.clamp @strokeIndex + 1, 0, @strokes.length
		@redraw()


	commitStroke: (stroke) ->
		# SkulerColor referenced for saturation and lightness only
		color = @palette[@colorIndex]
		@strokes.length = @strokeIndex # clears redo stack
		@strokes.push [@colorIndex, color.saturation, color.lightness, stroke, @penSize]
		@strokeIndex = @strokes.length


	redraw: ->
		canv = @context.canvas
		@context.clearRect 0, 0, canv.width, canv.height

		for strokeInfo, si in @strokes
			break unless si < @strokeIndex

			[index, saturation, lightness, stroke, size] = strokeInfo

			color = @getColorAt index
			color.adjust saturation, lightness

			@context.beginPath()
			@context.strokeStyle = @getStrokeStyle color
			@context.lineWidth = @getLineWidth size

			for x, pi in stroke by 2
				y = stroke[pi + 1]

				if pi is 0
					@context.moveTo x, y
				else
					@context.lineTo x, y
				
			@context.stroke()

		@ # do not accumulate and return loop results (just return this)


	getSVG: ->
		lines = ""

		if @strokeIndex && @strokes.length

			group = lastGroup = null;
			lines = '\t<g fill="none" stroke-linejoin="round" stroke-linecap="round">\n'
			
			for strokeInfo, si in @strokes
				break unless si < @strokeIndex

				[index, saturation, lightness, stroke, size] = strokeInfo

				color = new SkulerColor @getColorAt(index).base, saturation, lightness
				hex = @getStrokeStyle color
				group = '\t\t<g data-index="'+index+'" data-s="'+saturation+'" data-l="'+lightness+
					'" stroke="'+hex+'" stroke-width="'+@getLineWidth(size)+'">\n'

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
			
			index = Utils.clamp parseInt(att.getNamedItem("data-index").nodeValue), 0, @palette.length - 1
			saturation = Utils.clamp Number(att.getNamedItem("data-s").nodeValue), 0, 1
			lightness = Utils.clamp Number(att.getNamedItem("data-l").nodeValue), 0, 1
			points = line.attributes.getNamedItem("points").nodeValue.split(",").map Number
			size = parseInt att.getNamedItem("stroke-width").nodeValue
			size = Utils.clamp Math.round(Math.log(size)/Math.LN2 - 1), 1, SkulerDrawing.MAX_PEN_SIZE

			[index, saturation, lightness, points, size]

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