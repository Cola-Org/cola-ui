class cola.util.KeyedArray
	size: 0

	constructor: ()->
		@elements = []
		@keys = []
		@keyMap = {}

	add: (key, element)->
		if @keyMap.hasOwnProperty(key)
			i = @elements.indexOf(element)
			if i > -1
				@elements.splice(i, 1)
				@keys.splice(i, 1)
		@keyMap[key] = element
		@size = @elements.push(element)
		@keys.push(key)
		return @

	remove: (key)->
		if typeof key == "number"
			i = key
			key = @keys[i]
			element = @elements[i]
			@elements.splice(i, 1)
			@keys.splice(i, 1)
			@size = @elements.length
			delete @keyMap[key]
		else
			element = @keyMap[key]
			delete @keyMap[key]
			if element
				i = @keys.indexOf(key)
				if i > -1
					@elements.splice(i, 1)
					@keys.splice(i, 1)
					@size = @elements.length
		return element

	get: (key)->
		if typeof key == "number"
			return @elements[key]
		else
			return @keyMap[key]

	getIndex: (key)->
		if @keyMap.hasOwnProperty(key)
			return @keys.indexOf(key)
		return -1

	clear: ()->
		@elements = []
		@keys = []
		@keyMap = {}
		@size = 0
		return

	elements: ()->
		return @elements

	each: (fn)->
		keys = @keys
		for element, i in @elements
			if fn.call(this, element, keys[i]) == false
				break
		return