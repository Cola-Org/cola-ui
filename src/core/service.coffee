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
		invokerOptions = @invokerOptions
		retValue = undefined

		options = {}
		for p, v of invokerOptions
			options[p] = v
		options.async = async
		options.success = (result) =>
			@invokeCallback(true, result)
			retValue = result
			return
		options.error = (error) =>
			@invokeCallback(false, error)
			return

		if options.sendJson
			options.data = JSON.stringify(options.data)

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
			throw new cola.I18nException("cola.error.getResultDuringAjax", @url)
		@callbacks.push(callback)
		return @_internalInvoke(false)

class cola.AjaxService extends cola.Element
	@ATTRIBUTES:
		url: null
		sendJson: null
		method: null
		parameter: null
		ajaxOptions: null

	getUrl: () ->
		return @_url

	getInvokerOptions: () ->
		options = {}
		ajaxOptions = @_ajaxOptions
		if ajaxOptions
			for p, v of ajaxOptions
				options[p] = v

		options.url = @getUrl()
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
		pageNo:
			defaultValue: 1

	_evalParamValue: (expr, context) ->
		if expr.charCodeAt(0) == 58 # `:`
			if context
				return cola.Entity._evalDataPath(context, expr.substring(1), true, "never");
			else
				return null
		else
			return expr

	getInvokerOptions: (context) ->
		options = super()
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
		data.from = @_pageSize * (@_pageNo - 1) if @_pageSize > 1 and @_pageNo > 1
		data.limit = @_pageSize if @_pageSize > 1
		data.parameter = parameter if parameter?
		options.data = data
		return options

class cola.Resolver extends cola.AjaxService
	@ATTRIBUTES:
		sendJson:
			defaultValue: true