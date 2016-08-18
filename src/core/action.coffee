#IMPORT_BEGIN
if exports?
	cola = require("./model")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

defaultActionTimestamp = 0

cola.defaultAction = (name, fn) ->
	return unless name

	if typeof name is "string" and typeof fn is "function"
		cola.defaultAction[name] = fn
	else if typeof name is "object"
		for n of name
			cola.defaultAction[n] = name[n] if name.hasOwnProperty(n)
	defaultActionTimestamp = cola.uniqueId()
	return

class cola.Chain
	constructor: (data) ->
		@_data = data
		if cola.Chain::timestamp isnt defaultActionTimestamp
			cola.Chain::timestamp = defaultActionTimestamp

			for name of cola.defaultAction
				if not cola.Chain::[name] and cola.defaultAction.hasOwnProperty(name) and name isnt "chain"
					do (name) ->
						cola.Chain::[name] = (args...) ->
							@_data = cola.defaultAction[name](@_data, args...)
							return @

cola.defaultAction.chain = (data) -> new cola.Chain(data)

cola.defaultAction["default"] = (value, defaultValue = "") -> value or defaultValue

cola.defaultAction["int"] = (value) -> parseInt(value, 10) or 0
cola.defaultAction["float"] = (value) -> parseFloat(value) or 0

cola.defaultAction["is"] = (value) -> !!value
cola.defaultAction["bool"] = cola.defaultAction.is
cola.defaultAction["not"] = (value) -> not value

cola.defaultAction.isEmpty = (value) ->
	if value instanceof Array
		return value.length is 0
	else if value instanceof cola.EntityList
		return value.entityCount is 0
	else if typeof value is "string"
		return value is ""
	else
		return !value

cola.defaultAction.isNotEmpty = (value) -> not cola.defaultAction.isEmpty(value)

cola.defaultAction.len = (value) ->
	if not value
		return 0
	if value instanceof Array
		return value.length
	if  value instanceof cola.EntityList
		return value.entityCount
	return 0

cola.defaultAction["upperCase"] = (value) -> value?.toUpperCase()
cola.defaultAction["lowerCase"] = (value) -> value?.toLowerCase()
cola.defaultAction["capitalize"] = (value) -> cola.util.capitalize(value)

cola.defaultAction.resource = (key, params...) -> cola.resource(key, params...)

_matchValue = (value, propFilter) ->
	if propFilter.strict
		if !propFilter.caseSensitive and typeof propFilter.value == "string"
			return (value + "").toLowerCase() == propFilter.value
		else
			return value == propFilter.value
	else
		if !propFilter.caseSensitive
			return (value + "").toLowerCase().indexOf(propFilter.value) > -1
		else
			return (value + "").indexOf(propFilter.value) > -1

cola.defaultAction.filter = (collection, criteria, option) ->
	criteria = cola._trimCriteria(criteria, option)
	return cola.util.filter(collection, criteria, option)
	
cola.defaultAction.sort = cola.util.sort

cola.defaultAction["top"] = (collection, top = 1) ->
	return null unless collection
	return collection if top < 0
	items = []
	items.$origin = collection.$origin or collection

	i = 0
	cola.each collection, (item) ->
		i++
		items.push(item)
		return i < top
	return items

cola.defaultAction.formatDate = cola.util.formatDate

cola.defaultAction.formatNumber = cola.util.formatNumber

cola.defaultAction.format = cola.util.format

cola.defaultAction.propertyCaption = (path) ->
	caption = ""
	i = path.indexOf(".")
	if i > 0
		dataType = path.substring(0, i)
		property = path.substring(i + 1)
		dataType = @.definition(dataType)
		if dataType
			property = dataType.getProperty(property)
			if property
				caption = property._caption or property._property
	return caption

_numberWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen"]
cola.defaultAction.number2Word = (number) -> _numberWords[number]

cola.defaultAction.backgroundImage = (url) -> if url then "url(#{url})" else "none"