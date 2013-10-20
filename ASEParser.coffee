###
Wrapper for DataView (readonly) that also tracks
position while reading a buffer along with some
string reading convenience methods.
###
class DataViewReader

	constructor: (buffer) ->
		@data = new DataView buffer
		@position = 0
		@littleEndian = false
	

	getInt8: ->
		result = @data.getInt8(@position)
		@position += 1
		result
	

	getUint8: ->
		result = @data.getUint8(@position)
		@position += 1
		result
	

	getInt16: ->
		result = @data.getInt16 @position, @littleEndian
		@position += 2
		result
	

	getUint16: ->
		result = @data.getUint16 @position, @littleEndian
		@position += 2
		result
	

	getInt32: ->
		result = @data.getInt32 @position, @littleEndian
		@position += 4
		result
	

	getUint32: ->
		result = @data.getUint32 @position, @littleEndian
		@position += 4
		result
	

	getFloat32: ->
		result = @data.getFloat32 @position, @littleEndian
		@position += 4
		result
	

	getFloat64: ->
		result = @data.getFloat64 @position, @littleEndian
		@position += 8
		result
	

	getString8: (len) ->
		len = @getUint8() if len == undefined
		str = ""
		str += String.fromCharCode @getUint8() while len--
		str
	

	getString16: (len) ->
		len = @getUint16() if len == undefined
		str = ""
		str += String.fromCharCode @getUint16() while len--
		str
	

	seek: (offset, relative) ->
		@position = if relative then @position + offset else offset
	


###
Very basic, Kuler-compatible ASE parser.
Supports ASE 1.0 with RGB colors. It provides an
object with the color group name and an array of
colors for each color in the group (5 for Kuler).
###
class ASEParser

	@FILE_SIG = "ASEF"
	@COLOR_MODE = "RGB"
	@TAG_GROUP_HEAD = 0xC001
	@TAG_COLOR = 0x0001
	@TAG_GROUP_TAIL = 0xC002


	constructor: (buffer) ->
		@reader = new DataViewReader buffer
		@tagId = 0 # current tag id
		@tagSize = 0 # current tag size in bytes
		@tagPos = 0 # current tag position
	

	parse: ->
		# beginning of file with header info
		@_parseHeader()

		# data to be extracted from file
		name = ""
		colors = []

		# iterate through the tags of the file

		eof = false
		while @_nextTag()

			switch @tagId 

				when ASEParser.TAG_GROUP_HEAD
					# name comes from the header of the group 
					@_startTag()
					name = @_parseGroupHead()

				when ASEParser.TAG_COLOR
					# multiple color tags will follow group head
					@_startTag()
					colors.push @_parseColor()

				when ASEParser.TAG_GROUP_TAIL
					# end of the group means we bail
					eof = true

				else
					console.log @tagId, @tagPos, @tagSize
					throw new Error "Unexpected tag encountered while reading file." 
				
			# works with startTag to ensure data
			# is read from tag boundaries
			@_endTag()
			break if eof
		
		{name, colors}
	

	_nextTag: ->
		@tagId = @reader.getUint16()
	

	_parseHeader: ->
		sig = @reader.getString8 4
		if sig isnt ASEParser.FILE_SIG
			throw new Error "Unrecognized file signature. Expected #{ASEParser.FILE_SIG}."
		
		versMinor = @reader.getUint8()
		versMajor = @reader.getUint8()
		if versMajor isnt 1 or versMinor isnt 0
			throw new Error "Unrecognized file version. Expected 1.0." 
		
		@reader.seek 6, true # remainder of header
	

	_startTag: ->
		@tagSize = @reader.getUint32()
		@tagPos = @reader.position
	

	_endTag: ->
		if @tagSize
			@reader.seek @tagPos + @tagSize 
			@tagSize = 0
		
	
	_parseGroupHead: ->
		@reader.getString16()
	

	_parseColor: ->
		name = @reader.getString16() # ignored

		mode = @reader.getString8 4 
		if mode.substring(0,3) isnt ASEParser.COLOR_MODE
			throw new Error "Unrecognized color mode. Expected #{ASEParser.COLOR_MODE}."
		
		r = 255 * @reader.getFloat32()
		g = 255 * @reader.getFloat32()
		b = 255 * @reader.getFloat32()
		Math.round(r) << 16 | Math.round(g) << 8 | Math.round(b)


window.ASEParser = ASEParser;