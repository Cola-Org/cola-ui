cola.ajax = (options, callback) ->
	realOptions = {}
	realOptions[p] = v for p, v of options
	if cola.fire("beforeAjaxRequest", cola, options) == false then return

	success = options.success
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

	error = options.error
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