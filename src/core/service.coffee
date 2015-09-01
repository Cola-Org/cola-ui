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
		options.success = (result) =>
			@invokeCallback(true, result)
			if ajaxService.getListeners("success")
				ajaxService.fire("success", ajaxService, {options: options, result: result})
			if ajaxService.getListeners("complete")
				ajaxService.fire("complete", ajaxService, {success: true, options: options, result: result})
			retValue = result
			return
		options.error = (error) =>
			ajaxService.fire("error", ajaxService, {options: options, error: error})
			ajaxService.fire("complete", ajaxService, {success: false, options: options, error: error})
			@invokeCallback(false, error)
			return

		if options.sendJson
			options.data = JSON.stringify(options.data)

		if ajaxService.getListeners("beforeSend")
			if ajaxService.fire("beforeSend", ajaxService, {options: options}) == false
				return

		cola.ajax(options)
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
		sendJson: null
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
		options.sendJson = @_sendJson
		if options.sendJson and !options.method
			options.method = "post"
		return options

	getInvoker: (context) ->
		return new cola.AjaxServiceInvoker(@, @getInvokerOptions(context))

class cola.Provider extends cola.AjaxService
	@ATTRIBUTES:
		pageSize: null

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

		data = {}
		if @_pageSize > 1
			data.from = 0
			data.limit = @_pageSize
		data.parameter = parameter if parameter?
		options.data = data
		return options

class cola.Resolver extends cola.AjaxService
	@ATTRIBUTES:
		sendJson:
			defaultValue: true