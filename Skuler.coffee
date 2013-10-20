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


		@drawing = new SkulerDrawing document.getElementById "canvas"

		# event handlers
		@$doc.on "dragover", @handleFileDragOver
		@$doc.on "drop", @handleFileDrop

		@$controls.on "mousedown", @handleStartDraw

		@$swatchInteractGroup.on "mousedown", @handleSwatchDown
		@$swatchInteractGroup.on "click", @handleSwatchClick

		@$triInteract.on "mousemove", @handleTriMove

		# initial theme
		@setASE 
			name: "Beach Umbrella"
			colors: [0xff2151, 0xff7729, 0xffad29, 0xffebca, 0x1ab58a]


	parseFile: (file) ->
		@reader = new FileReader()
		@reader.onload = @handleFileRead
		@reader.readAsArrayBuffer file 


	setASE: (ase) ->
		for color, i in ase.colors
			$("#swatch-#{i}")
				.data("color", color)
				.css("fill", Utils.toCSSHex color)

		@drawing.setColor new SkulerColor ase.colors[0]
		@updateViewCurrColor()
		@updateViewTriColorSelect()
		@drawing.redraw()


	updateViewSwatchSelect: (visible, $fromSwatch) ->
		console.log "in"
		@$triGroup.css "visibility", if visible then "visible" else "hidden"

		hex = Utils.toCSSHex @drawing.color.base
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
		s = @drawing.color.saturation
		si = 1 - s # inverted
		l = @drawing.color.lightness

		# from satruation, lightness to x, y
		triBox = @$triInteract[0].getBBox()
		x = triBox.width * si
		y = triBox.height * (l*si + s/2) # compensate for triangle

		@$triLoc.attr("x", x).attr("y", y)
		@$triLocShadow.attr("x", 1 + x).attr("y", 1 + y)


	updateViewCurrColor: ->
		@$swatchCurrent.css "fill", Utils.toCSSHex @drawing.color.calculated


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
		@drawing.setColor new SkulerColor parseInt $use.data "color"
		
		@updateViewSwatchSelect true, $use

		@$doc.on "mouseup", @handleSwatchUp

		event.preventDefault()


	handleSwatchUp: (event) =>
		@updateViewSwatchSelect false
		@$doc.off "mouseup", @handleSwatchUp


	handleSwatchClick: (event) =>
		$use = $ event.target.correspondingUseElement
		color = parseInt $use.data "color"
		@drawing.setColor new SkulerColor color, 1, 0

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

		@drawing.color.adjust s, l

		@updateViewCurrColor()
		@updateViewTriColorSelect()


	handleStartDraw: (event) =>
		if event.target is @$controls[0]
			Mouse.get event

			@drawing.strokeStart Mouse.x, Mouse.y

			@$controls.on "mousemove", @handleMoveDraw
			@$doc.on "mouseup", @handleStopDraw
		

	handleMoveDraw: (event) =>
		Mouse.get event

		@drawing.strokeTo Mouse.x, Mouse.y


	handleStopDraw: (event) =>
		@drawing.strokeStop()

		@$controls.off "mousemove", @handleMoveDraw
		@$doc.off "mouseup", @handleStopDraw


class SkulerDrawing

	penX: 0
	penY: 0


	constructor: (element) ->

		# saved drawing context
		@context = element.getContext "2d"
		@context.strokeStyle = "#000"
		@context.lineWidth = 15
		@context.lineCap = "round"
		@context.lineJoin = "round"
		@context.beginPath()

		@palette = [] # TODO

		@stroke = []
		@strokes = []
		@setColor new SkulerColor


	setColor: (@color) ->


	strokeStart: (@penX, @penY) ->
		@stroke = [@penX, @penY]


	strokeTo: (penX, penY) ->

		@context.beginPath()
		@context.strokeStyle = Utils.toCSSHex @color.calculated
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


	commitStroke: (stroke) ->
		@strokes.push [@color, stroke]


	redraw: ->
		canv = @context.canvas
		@context.clearRect 0, 0, canv.width, canv.height

		for strokeInfo in @strokes
			[color, stroke] = strokeInfo
			@context.beginPath()

			for x, i in stroke by 2
				y = stroke[i + 1]

				if i is 0
					@context.moveTo x, y
				else
					@context.lineTo x, y
				
			@context.strokeStyle = Utils.toCSSHex color.calculated
			@context.stroke()

		@ # do not accumulate and return loop results (just return this)


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