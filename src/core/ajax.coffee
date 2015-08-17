_toJSON = (data) ->
	if data
		if typeof data is "object"
			if data instanceof cola.Entity or data instanceof cola.EntityList
				data = data.toJSON()
			else
				rawData = data
				data = {}
				for p, v of rawData
					data[p] = _toJSON(v)
		else if typeof data is "function"
			data = undefined
	return data

cola.ajax = (options, callback) ->
	realOptions = {}
	realOptions[p] = v for p, v of options
	if cola.fire("beforeAjaxRequest", cola, realOptions) == false then return

	realOptions.data = _toJSON(realOptions.data)

	success = realOptions.success
	realOptions.success = (result, status, xhr) ->
		if cola.getListeners("ajaxSuccess")
			arg =
				result: result
				status: status
				xhr: xhr
			if cola.fire("ajaxSuccess", cola, arg) == false then return
		cola.callback(callback, true, result)
		success?(result, status, xhr)
		return

	error = realOptions.error
	realOptions.error = (xhr, status, ex) ->
		if cola.getListeners("ajaxError")
			arg =
				xhr: xhr
				status: status
				error: ex
			if cola.fire("ajaxError", cola, arg) == false then return
			ex = arg.error
		cola.callback(callback, false, ex)
		error?(xhr, status, ex)
		return

	$.ajax(realOptions)
	return @

cola.get = (options, callback) ->
	options.method = "get"
	return cola.ajax(options, callback)

cola.post = (options, callback) ->
	options.method = "post"
	return cola.ajax(options, callback)