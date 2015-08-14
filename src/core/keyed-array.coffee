#IMPORT_BEGIN
if exports?
	cola = require("./namespace")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

class cola.util.KeyedArray
	size: 0

	constructor: () ->
		@elements = []
		@keyMap = {}

	add: (key, element) ->
		if @keyMap.hasOwnProperty(key)
			i = @elements.indexOf(element)
			if i > -1 then @elements.splice(i, 1)
		@keyMap[key] = element
		@size = @elements.push(element)
		return @

	remove: (key) ->
		if typeof key == "number"
			i = key
			element = @elements[i]
			@elements.splice(i, 1)
			@size = @elements.length
			if element
				for key of @keyMap
					if @keyMap[key] == element
						delete @keyMap[key]
						break
		else
			element = @keyMap[key]
			delete @keyMap[key]
			if element
				i = @elements.indexOf(element)
				if i > -1
					@elements.splice(i, 1)
					@size = @elements.length
		return element

	get: (key) ->
		if typeof key == "number"
			return @elements[key]
		else
			return @keyMap[key]

	getIndex: (key) ->
		element = @keyMap[key]
		if element
			return @elements.indexOf(element)
		return -1

	clear: () ->
		@elements = []
		@keyMap = {}
		@size = 0
		return

	elements: () ->
		return @elements

	each: (fn) ->
		for element in @elements
			if fn.call(this, element) == false
				break
		return