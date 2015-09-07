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

		@$download = $  "#download"

		@drawing = new SkulerDrawing document.getElementById "canvas"
		@reader = new FileReader

		# event handlers
		@$doc.on "dragover", @handleFileDragOver
		@$doc.on "drop", @handleFileDrop
		@$doc.on "keydown", @handleKeyShortcut

		@$controls.on "mousedown", @handleStartDraw

		@$swatchInteractGroup.on "mousedown", @handleSwatchDown
		@$swatchInteractGroup.on "click", @handleSwatchClick

		@$triInteract.on "mousemove", @handleTriMove

		$("#new").on "click", @handleNew
		$("#undo").on "click", @handleUndo
		$("#redo").on "click", @handleRedo
		@$download.on "click", @handleSetupSaveSVG

		# initial theme
		@setASE 
			name: "Beach Umbrella"
			colors: [0xff2151, 0xff7729, 0xffad29, 0xffebca, 0x1ab58a]


	parseASEFile: (@readFile = @readFile) ->
		@reader.onload = @handleASEFileRead
		@reader.readAsArrayBuffer @readFile 


	parseSVGFile: (@readFile = @readFile) ->
		@reader.onload = @handleSVGFileRead
		@reader.readAsBinaryString @readFile 


	setASE: (@ase) ->
		@drawing.setPalette @ase.colors
		@drawing.redraw()

		@updateViewSwatchPalette()
		@updateViewCurrColor()
		@updateViewTriColorSelect()


	setSL: (s, l) ->
		@drawing.adjustColor s, l

		@updateViewCurrColor()
		@updateViewTriColorSelect()


	setSwatchIndex: (index, showTri = false) ->
		@drawing.setColorIndex index

		if @drawing.colorIndex is index # valid index passed; the change took
			@updateViewCurrColor()
			@updateViewTriColorSelect()
			@updateViewSwatchSelect showTri, $("[data-index=#{index}]")


	createNew: ->
		if confirm "Clear existing drawing and start anew?"
			@drawing.clear()
			@handleStopDraw null # shouldn't be necessary given confurm above


	updateViewSwatchPalette: ->
		for color, i in @drawing.palette
			$("[data-index=#{i}]")
				.css("fill", Utils.toCSSHex color.base)


	updateViewSwatchSelect: (showTri, $fromSwatch) ->
		@$triGroup.css "visibility", if showTri then "visible" else "hidden"

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
		l = 1 - color.lightness

		# from satruation, lightness to x, y
		triBox = @$triInteract[0].getBBox()
		x = triBox.width * si
		y = triBox.height * (l*si + s/2) # compensate for triangle

		@$triLoc.attr("x", x).attr("y", y)
		@$triLocShadow.attr("x", x + 1).attr("y", y + 1)


	updateViewCurrColor: ->
		@$swatchCurrent.css "fill", Utils.toCSSHex @drawing.getColor().calculated


	handleFileDragOver:  (event) ->
		event.originalEvent.dataTransfer.dropEffect = "move"
		event.preventDefault()


	handleFileDrop: (event) =>
		# start file parsing starting with ASE and error on 
		# parsing additional formats
		@parseASEFile event.originalEvent.dataTransfer.files[0] # only take one file
		event.preventDefault()


	handleASEFileRead: (event) =>
		buffer = event.target.result
		try
			@setASE new ASEParser(buffer).parse()
			@readFile = null
		catch err
			# not ASE file, how about SVG?
			@parseSVGFile()


	handleSVGFileRead: (event) =>
		str = event.target.result
		try
			@drawing.readSVG str
		catch err
			# not any recognized file
			alert "Only Kuler ASE and Skuler SVG files are supported"
		finally
			@readFile = null


	handleSetupSaveSVG: (event) =>
		try
			blob = new Blob [@drawing.getSVG()], {type:'text/plain'}
			if navigator.msSaveBlob?
				navigator.msSaveBlob(blob, @$download.attr "download")
			else
				@$download.attr "href", URL.createObjectURL(blob)
			true
		catch err
			# probably not supported
			console.log err
			false


	handleSwatchDown: (event) =>
		$use = $ event.target
		index = parseInt $use.data "index"
		@setSwatchIndex index, true

		@$doc.on "mouseup", @handleSwatchUp
		event.preventDefault()


	handleSwatchUp: (event) =>
		@updateViewSwatchSelect false
		@$doc.off "mouseup", @handleSwatchUp


	handleSwatchClick: (event) =>
		$use = $ event.target
		@drawing.setColorIndex $use.data "index"
		@drawing.getColor().adjust 1, 0

		@updateViewCurrColor()
		@updateViewTriColorSelect()


	handleTriMove: (event) =>
		Utils.mouse.get event

		triBox = @$triInteract[0].getBBox()

		# saturation
		si = Utils.mouse.x/triBox.width # inverted
		s = 1 - si

		# lightness + compensating for triangular shape
		l = 1 - Utils.mouse.y/triBox.height
		l = (l - s/2)/si if si # cannot divide 0 (fully saturated)

		@setSL s, l


	handleStartDraw: (event) =>
		if event.target is @$controls[0]
			Utils.mouse.get event

			@drawing.strokeStart Utils.mouse.x, Utils.mouse.y

			@$controls.on "mousemove", @handleMoveDraw
			@$doc.on "mouseup", @handleStopDraw

			event.preventDefault()
		

	handleMoveDraw: (event) =>
		Utils.mouse.get event

		@drawing.strokeTo Utils.mouse.x, Utils.mouse.y


	handleStopDraw: (event) =>
		@drawing.strokeStop()

		@$controls.off "mousemove", @handleMoveDraw
		@$doc.off "mouseup", @handleStopDraw


	handleNew: (event) =>
		@createNew()

		
	handleUndo: (event) =>
		@drawing.undo()
		@updateViewCurrColor()

		
	handleRedo: (event) =>
		@drawing.redo()
		@updateViewCurrColor()


	handleKeyShortcut: (event) =>
		slOffset = 0.1

		preventsDefault = switch event.keyCode
			when 33 # Page Up
				@setSwatchIndex @drawing.colorIndex - 1
				true

			when 34 # Page Down
				@setSwatchIndex @drawing.colorIndex + 1
				true

			when 37 # LEFT Arrow
				color = @drawing.getColor()
				@setSL color.saturation + slOffset, color.lightness
				true

			when 38 # UP Arrow
				color = @drawing.getColor()
				@setSL color.saturation, color.lightness + slOffset
				true

			when 39 # RIGHT Arrow
				color = @drawing.getColor()
				@setSL color.saturation - slOffset, color.lightness
				true

			when 40 # DOWN Arrow
				color = @drawing.getColor()
				@setSL color.saturation, color.lightness - slOffset
				true

			when 89 # y
				if event.ctrlKey
					@drawing.redo()
					@updateViewCurrColor()
					true

			when 90 # z
				if event.ctrlKey
					@drawing.undo()
					@updateViewCurrColor()
					true

			when 77 # m
				if event.ctrlKey
					@createNew()
					true

			when 188 # , (<)
				@drawing.setPenSize @drawing.penSize - 1
				true

			when 190 # . (>)
				@drawing.setPenSize @drawing.penSize + 1
				true

		event.preventDefault() if preventsDefault


# init
window.skuler = new Skuler
$("#skuler").css "visibility", "visible" # reveal after init
