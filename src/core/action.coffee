#IMPORT_BEGIN
if exports?
	cola = require("./model")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.defaultAction = {}

cola.defaultAction["default"] = (value, defaultValue = "") ->
	return value or defaultValue

cola.defaultAction["int"] = (value) ->
	return parseInt(value, 10) or 0

cola.defaultAction["float"] = (value) ->
	return parseFloat(value) or 0

cola.defaultAction["is"] = (value) ->
	return !!value

cola.defaultAction["bool"] = cola.defaultAction.is

cola.defaultAction["not"] = (value) ->
	return not value

cola.defaultAction.isEmpty = (value) ->
	if value instanceof Array
		return value.length is 0
	else if value instanceof cola.EntityList
		return value.entityCount is 0
	else if typeof value is "string"
		return value is ""
	else
		return !value

cola.defaultAction.isNotEmpty = (value) ->
	return not cola.defaultAction.isEmpty(value)

cola.defaultAction.len = (value) ->
	if not value
		return 0
	if value instanceof Array
		return value.length
	if  value instanceof cola.EntityList
		return value.entityCount
	return 0

cola.defaultAction["upperCase"] = (value) ->
	return value?.toUpperCase()

cola.defaultAction["lowerCase"] = (value) ->
	return value?.toLowerCase()

cola.defaultAction.resource = (key, params...) ->
	return cola.resource(key, params...)

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

cola.defaultAction.filter = cola._filterCollection

cola.defaultAction.sort = cola._sortCollection

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

cola.defaultAction.formatDate = (date, format) ->
	return "" unless date?
	if not (date instanceof XDate)
		date = new XDate(date)
	return date.toString(format)

cola.defaultAction.formatNumber = (number, format) ->
	return "" unless number?
	return number if isNaN(number)
	return formatNumber(format, number)