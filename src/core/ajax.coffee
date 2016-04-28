_toJSON = (data) ->
	if data
		if typeof data is "object"
			if data instanceof cola.Entity or data instanceof cola.EntityList
				data = data.toJSON()
			else if data instanceof Date
				data = cola.util.formatDate(data, cola.setting("defaultSubmitDateFormat"))
			else
				rawData = data
				data = {}
				for p, v of rawData
					data[p] = _toJSON(v)
		else if typeof data is "function"
			data = undefined
	return data

originalAjax = jQuery.ajax
$.ajax = (url, settings) ->
	if typeof url is "object" and not settings
		settings = url

	data = settings.data
	if data
		if typeof data is "object"
			if data instanceof cola.Entity or data instanceof cola.EntityList
				data = data.toJSON()
			else if not (data instanceof FormData)
				rawData = data
				data = {}
				for p, v of rawData
					data[p] = _toJSON(v)
			else if data instanceof Date
				data = _toJSON(data)
		else if typeof data is "function"
			data = undefined
		settings.data = data

	return originalAjax.apply(@, [url, settings])