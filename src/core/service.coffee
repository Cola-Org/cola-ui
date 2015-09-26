#IMPORT_BEGIN
if exports?
	cola = require("./ajax")
	cola = require("./element")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

class cola.AjaxServiceInvoker
	constructor: (@ajaxService, @invokerOptions) ->
		@callbacks = []

	invokeCallback: (success, result) ->
		@invoking = false
		callbacks = @callbacks
		@callbacks = []
		for callback in callbacks
			cola.callback(callback, success, result)
		return

	_internalInvoke: (async = true) ->
		ajaxService = @ajaxService

		invokerOptions = @invokerOptions
		retValue = undefined

		options = {}
		for p, v of invokerOptions
			options[p] = v
		options.async = async

		if options.sendJson
			options.data = JSON.stringify(options.data)

		if ajaxService.getListeners("beforeSend")
			if ajaxService.fire("beforeSend", ajaxService, {options: options}) == false
				return

		jQuery.ajax(options).done( (result) =>
			result = ajaxService.translateResult(result, options)

			@invokeCallback(true, result)
			if ajaxService.getListeners("success")
				ajaxService.fire("success", ajaxService, {options: options, result: result})
			if ajaxService.getListeners("complete")
				ajaxService.fire("complete", ajaxService, {success: true, options: options, result: result})
			retValue = result
			return
		).fail( (xhr) =>
			error = xhr.responseJSON
			@invokeCallback(false, error)
			ajaxService.fire("error", ajaxService, {options: options, xhr: xhr, error: error})
			ajaxService.fire("complete", ajaxService, {success: false, xhr: xhr, options: options, error: error})
			return
		)
		return retValue

	invokeAsync: (callback) ->
		@callbacks.push(callback)
		if @invoking then return false

		@invoking = true
		@_internalInvoke()
		return true

	invokeSync: (callback) ->
		if @invoking
			throw new cola.Exception("Cannot perform synchronized request during an asynchronized request executing. [#{@url}]")
		@callbacks.push(callback)
		return @_internalInvoke(false)

class cola.AjaxService extends cola.Definition
	@ATTRIBUTES:
		url: null
		method: null
		parameter: null
		ajaxOptions: null

	@EVENTS:
		beforeSend: null
		complete: null
		success: null
		error: null

	constructor: (config) ->
		if typeof config is "string"
			config = {
				url: config
			}
		super(config)

	getUrl: () ->
		return @_url

	getInvokerOptions: (context) ->
		options = {}
		ajaxOptions = @_ajaxOptions
		if ajaxOptions
			for p, v of ajaxOptions
				options[p] = v

		options.url = @getUrl(context)
		options.data = @_parameter
		return options

	getInvoker: (context) ->
		return new cola.AjaxServiceInvoker(@, @getInvokerOptions(context))

	translateResult: (result, invokerOptions) ->
		return result

class cola.Provider extends cola.AjaxService
	@ATTRIBUTES:
		pageSize: null
		detectEnd: null

	_evalParamValue: (expr, context) ->
		if expr.charCodeAt(0) == 58 # `:`
			if context
				return cola.Entity._evalDataPath(context, expr.substring(1), true, "never");
			else
				return null
		else
			return expr

	getUrl: (context) ->
		url = @_url
		if url.indexOf(":") > -1
			parts = []
			for part in url.split("/")
				parts.push(@_evalParamValue(part, context))
			url = parts.join("/")
		return url

	getInvokerOptions: (context) ->
		options = super(context)
		parameter = options.data

		if parameter?
			if typeof parameter is "string"
				parameter = @_evalParamValue(parameter, context)
			else if typeof parameter is "object"
				oldParameter = parameter
				parameter = {}
				for p, v of oldParameter
					if typeof v is "string"
						v = @_evalParamValue(v, context)
					parameter[p] = v

		if @_pageSize > 1
			if not parameter?
				parameter = {}
			else if not (parameter instanceof Object)
				parameter = {
					parameter: parameter
				}
			parameter.from = 0
			parameter.limit = @_pageSize + (if @_detectEnd then 1 else 0)

		options.data = parameter
		return options

	translateResult: (result, invokerOptions) ->
		if @_detectEnd and result instanceof Array
			if result.length >= @_pageSize
				result.pop()
			else
				result = {
					$entityCount: (invokerOptions.data.from or 0) + result.length
					$data: result
				}
		return result