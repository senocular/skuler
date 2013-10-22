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

class Utils

	@toCSSHex: (num) ->
		"#" + ("00000" + num.toString 16).substr -6


	@clamp: (num, min, max) -> 
		return min if num < min
		return max if num > max
		num

	@mouse: Mouse


window.Utils = Utils