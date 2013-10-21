class Skuler

	constructor: ->

		# saved dom (jquery) references
		@$doc = $ document
		@$controls = $ "#controls" # svg element

		@$triGroup = $ "#tri-group"
		@$triColor1 = $ "#tri-base-color1"
		@$triColor2 = $ "#tri-base-color1"
		@$triInteract = $ "#tri-interact"
		@$triLoc = $ "#tri-loc"
		@$triLocShadow = $ "#tri-loc-shadow"

		@$swatchGroup = $ "#swatch-group"
		@$swatchIndicator = $ "#swatch-indicator"
		@$swatchInteractGroup = $ "#swatch-interact-group"
		@$swatchCurrent = $ "#swatch-current"

		@$svgCode = $ "#svg-code"


		@drawing = new SkulerDrawing document.getElementById "canvas"

		# event handlers
		@$doc.on "dragover", @handleFileDragOver
		@$doc.on "drop", @handleFileDrop

		@$controls.on "mousedown", @handleStartDraw

		@$swatchInteractGroup.on "mousedown", @handleSwatchDown
		@$swatchInteractGroup.on "click", @handleSwatchClick

		@$triInteract.on "mousemove", @handleTriMove

		$("#new").on "click", @handleNew
		$("#undo").on "click", @handleUndo
		$("#redo").on "click", @handleRedo
		$("#svg").on "click", @handleSVG

		# initial theme
		@setASE 
			name: "Beach Umbrella"
			colors: [0xff2151, 0xff7729, 0xffad29, 0xffebca, 0x1ab58a]


	parseFile: (file) ->
		@reader = new FileReader()
		@reader.onload = @handleFileRead
		@reader.readAsArrayBuffer file 


	setASE: (@ase) ->

		@drawing.setPalette @ase.colors
		@drawing.redraw()

		@updateViewSwatchPalette()
		@updateViewCurrColor()
		@updateViewTriColorSelect()


	updateViewSVGCode: ->
		@$svgCode.text @drawing.getSVG()


	updateViewSwatchPalette: ->
		for color, i in @drawing.palette
			$("[data-index=#{i}]")
				.css("fill", Utils.toCSSHex color.base)


	updateViewSwatchSelect: (visible, $fromSwatch) ->
		@$triGroup.css "visibility", if visible then "visible" else "hidden"

		hex = Utils.toCSSHex @drawing.getColor().base
		@$triColor1.css "stopColor", hex
		@$triColor2.css "stopColor", hex

		if $fromSwatch?
			swatchesY = @$swatchGroup[0].transform.baseVal.getItem(0).matrix.f
			swatchY = $fromSwatch[0].y.baseVal.value
			swatchH = $fromSwatch[0].getBBox().height
			triH = @$triInteract[0].getBBox().height

			triY = swatchesY + swatchY + (swatchH/2) - (triH/2)
			@$triGroup[0].transform.baseVal.getItem(0).matrix.f = triY

			@$swatchIndicator[0].y.baseVal.value = swatchY


	updateViewTriColorSelect: ->
		color = @drawing.getColor()
		s = color.saturation
		si = 1 - s # inverted
		l = color.lightness

		# from satruation, lightness to x, y
		triBox = @$triInteract[0].getBBox()
		x = triBox.width * si
		y = triBox.height * (l*si + s/2) # compensate for triangle

		@$triLoc.attr("x", x).attr("y", y)
		@$triLocShadow.attr("x", 1 + x).attr("y", 1 + y)


	updateViewCurrColor: ->
		@$swatchCurrent.css "fill", Utils.toCSSHex @drawing.getColor().calculated


	handleFileDragOver:  (event) ->
		event.originalEvent.dataTransfer.dropEffect = "move"
		event.preventDefault()


	handleFileDrop: (event) =>
		@parseFile event.originalEvent.dataTransfer.files[0] # only take one file
		event.preventDefault()


	handleFileRead: (event) =>
		buffer = event.target.result
		@setASE new ASEParser(buffer).parse()


	handleSwatchDown: (event) =>
		$use = $ event.target.correspondingUseElement
		@drawing.setColorIndex $use.data "index"
		
		@updateViewCurrColor()
		@updateViewTriColorSelect()
		@updateViewSwatchSelect true, $use

		@$doc.on "mouseup", @handleSwatchUp

		event.preventDefault()


	handleSwatchUp: (event) =>
		@updateViewSwatchSelect false
		@$doc.off "mouseup", @handleSwatchUp


	handleSwatchClick: (event) =>
		$use = $ event.target.correspondingUseElement
		@drawing.setColorIndex $use.data "index"
		@drawing.getColor().adjust 1, 0

		@updateViewCurrColor()
		@updateViewTriColorSelect()


	handleTriMove: (event) =>
		Mouse.get event

		triBox = @$triInteract[0].getBBox()

		# saturation
		si = Mouse.x/triBox.width # inverted
		s = 1 - si

		# lightness + compensating for triangular shape
		l = Mouse.y/triBox.height
		l = (l - s/2)/si if si # cannot divide 0 (fully saturated)

		@drawing.getColor().adjust s, l

		@updateViewCurrColor()
		@updateViewTriColorSelect()


	handleStartDraw: (event) =>
		if event.target is @$controls[0]
			Mouse.get event

			@drawing.strokeStart Mouse.x, Mouse.y

			@$controls.on "mousemove", @handleMoveDraw
			@$doc.on "mouseup", @handleStopDraw

			event.preventDefault()
		

	handleMoveDraw: (event) =>
		Mouse.get event

		@drawing.strokeTo Mouse.x, Mouse.y


	handleStopDraw: (event) =>
		@drawing.strokeStop()

		@$controls.off "mousemove", @handleMoveDraw
		@$doc.off "mouseup", @handleStopDraw


	handleNew: (event) =>
		@drawing.clear() if confirm "Clear existing drawing and start anew?"
		@updateViewSVGCode()

		
	handleUndo: (event) =>
		@drawing.undo()
		@updateViewSVGCode()

		
	handleRedo: (event) =>
		@drawing.redo()
		@updateViewSVGCode()

		
	handleSVG: (event) =>
		@updateViewSVGCode()
		@$svgCode.slideToggle "fast"


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


	setColorIndex: (@colorIndex) ->


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

			color = @getColorAt(index)
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
		
		if @strokes.length

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


class SkulerSwatch

	constructor: (@color, @index) ->


class SkulerColor

	calculated: 0x000000


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


class Utils

	@toCSSHex: (num) ->
		"#" + ("00000" + num.toString 16).substr -6


	@clamp: (num, min, max) -> 
		return min if num < min
		return max if num > max
		num


class Mouse

	@x: 0
	@y: 0


	@get: (event, elem) ->
		elem = event.currentTarget if not elem?
		
		if event.touches
			# touch events
			if event.touches.length
				@x = parseInt event.touches[0].pageX
				@y = parseInt event.touches[0].pageY
			
		else
			# mouse events
			@x = parseInt event.clientX
			@y = parseInt event.clientY

		rect = elem.getBoundingClientRect()
		@x += elem.scrollLeft - elem.clientLeft - rect.left
		@y += elem.scrollTop - elem.clientTop - rect.top
		@


window.skuler = new Skuler
$("#skuler").css "visibility", "visible" # reveal on init