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

cola.defaultAction.is = (value) ->
	return !!value

cola.defaultAction.bool = cola.defaultAction.is

cola.defaultAction.not = (value) ->
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

cola.defaultAction.filter = (collection, criteria, params...) ->
	return collection unless collection and criteria

	if cola.util.isSimpleValue(criteria)
		caseSensitive = params[0]
		if !caseSensitive then criteria = (criteria + "").toLowerCase()
		criteria =
			"$": {
				value: criteria
				caseSensitive: caseSensitive
				strict: params[1]
			}

	if typeof criteria == "object"
		for prop, propFilter of criteria
			if typeof propFilter == "string"
				criteria[prop] = {
					value: propFilter.toLowerCase()
				}
			else
				if cola.util.isSimpleValue(propFilter)
					criteria[prop] = {
						value: propFilter
					}
				if !propFilter.strict
					propFilter.value = if propFilter.value then propFilter.value + "" else ""
				if !propFilter.caseSensitive and typeof propFilter.value == "string"
					propFilter.value = propFilter.value.toLowerCase()

		filtered = []
		filtered.$origin = collection.$origin or collection
		cola.each collection, (item) ->
			matches = false

			if cola.util.isSimpleValue(item)
				if criteria.$
					matches = _matchValue(v, criteria.$)
			else
				for prop, propFilter of criteria
					if prop == "$"
						if item instanceof cola.Entity
							data = item._data
						else
							data = item

						for p, v of data
							if _matchValue(v, propFilter)
								matches = true
								break
						if matches then break
					else if item instanceof cola.Entity
						if _matchValue(item.get(prop), propFilter)
							matches = true
							break
					else
						if _matchValue(item[prop], propFilter)
							matches = true
							break
			if matches
				filtered.push(item)
			return
		return filtered
	else if typeof criteria == "function"
		filtered = []
		filtered.$origin = collection.$origin or collection
		cola.each collection, (item) ->
			filtered.push(item) if criteria(item, params...)
			return
		return filtered
	else
		return collection

cola.defaultAction.sort = (collection, comparator, caseSensitive) ->
	return null unless collection
	return collection if not comparator? or comparator == "$none"

	if collection instanceof cola.EntityList
		origin = collection
		collection = collection.toArray()
		collection.$origin = origin

	if comparator
		if comparator == "$reverse"
			return collection.reverse();
		else if typeof comparator == "string"
			comparatorProps = []
			for part in comparator.split(",")
				c = part.charCodeAt(0)
				propDesc = false
				if c == 43 # `+`
					prop = part.substring(1)
				else if c == 45 # `-`
					prop = part.substring(1)
					propDesc = true
				else
					prop = part
				comparatorProps.push(prop: prop, desc: propDesc)

			comparator = (item1, item2) ->
				for comparatorProp in comparatorProps
					value1 = null
					value2 = null
					prop = comparatorProp.prop
					if prop
						if prop == "$random"
							return Math.random() * 2 - 1
						else
							if item1 instanceof cola.Entity
								value1 = item1.get(prop)
							else if cola.util.isSimpleValue(item1)
								value1 = item1
							else
								value1 = item1[prop]
							if !caseSensitive and typeof value1 == "string"
								value1 = value1.toLowerCase()

							if item2 instanceof cola.Entity
								value2 = item2.get(prop)
							else if cola.util.isSimpleValue(item2)
								value2 = item2
							else
								value2 = item2[prop]
							if !caseSensitive and typeof value2 == "string"
								value2 = value2.toLowerCase()

							result = 0
							if !value1? then result = -1
							else if !value2? then result = 1
							else if value1 > value2 then result = 1
							else if value1 < value2 then result = -1
							if result != 0
								return if comparatorProp.desc then (0 - result) else result
					else
						result = 0
						if !item1? then result = -1
						else if !item2? then result = 1
						else if item1 > item2 then result = 1
						else if item1 < item2 then result = -1
						if result != 0
							return if comparatorProp.desc then (0 - result) else result
				return 0
	else
		comparator = (item1, item2) ->
			result = 0
			if !caseSensitive
				if typeof item1 == "string" then item1 = item1.toLowerCase()
				if typeof item2 == "string" then item2 = item2.toLowerCase()
			if !item1? then result = -1
			else if !item2? then result = 1
			else if item1 > item2 then result = 1
			else if item1 < item2 then result = -1
			return result

	comparatorFunc = (item1, item2) ->
		return comparator(item1, item2)
	return collection.sort(comparatorFunc)

cola.defaultAction.top = (collection, top = 1) ->
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