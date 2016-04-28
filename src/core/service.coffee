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

		if @_beforeSend then @_beforeSend(options)

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
	@attributes:
		url: null
		method: null
		parameter: null
		ajaxOptions: null

	@events:
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
		options.method = @_method if @_method
		options.data = @_parameter
		return options

	getInvoker: (context) ->
		return new cola.AjaxServiceInvoker(@, @getInvokerOptions(context))

	translateResult: (result, invokerOptions) ->
		return result

class cola.ProviderInvoker extends cola.AjaxServiceInvoker

	#pageSize
	#pageNo
	#detectEnd

	_replaceSysParams: (options) ->
		url = options.originUrl or options.url
		matches = url.match(/{{\$[\w-]+}}/g)
		if matches
			options.originUrl ?= url
			for match in matches
				name = match.substring(2, match.length - 1)
				if name
					url = url.replace(match, @[name] or "")
					options.url = url
					changed = true

		data = options.originData or options.data
		if data
			for p, v of data
				if typeof v is "string"
					if v.charCodeAt(0) is 123 and v.match(/^{{\$[\w-]+}}$/) # `{`
						options.originData ?= $.extend(data, null)
						data[p] = @[v.substring(2, v.length - 1)]
						changed = true
		return changed

	applyPagingParameters: (options) ->
		if not @_replaceSysParams(options)
			if not options.data? then options.data = {}
			if cola.setting("pagingParamStyle") is "from"
				options.data.from = @from
				options.data.limit = @limit + (if @detectEnd then 1 else 0)
			else
				options.data.pageSize = @pageSize
				options.data.pageNo = @pageNo
		return

	_beforeSend: (options) ->
		if not @pageNo >= 1 then @pageNo = 1
		@from = @pageSize * (@pageNo - 1)
		@limit = @pageSize
		@applyPagingParameters(options) if @pageSize
		return

_SYS_PARAMS = ["$pageNo", "$pageSize", "$from", "$limit"]

class _ExpressionDataModel extends cola.AbstractDataModel
	constructor: (model, @entity) ->
		super(model)

	get: (path, loadMode, context) ->
		if path.charCodeAt(0) is 64 # `@`
			return @entity.get(path.substring(1))
		else
			return @model.parent?.data.get(path, loadMode, context)

	set: cola._EMPTY_FUNC
	_processMessage: cola._EMPTY_FUNC
	getDataType: cola._EMPTY_FUNC
	getProperty: cola._EMPTY_FUNC
	flush: cola._EMPTY_FUNC

class _ExpressionScope extends cola.SubScope
	constructor: (@parent, @entity) ->
		@data = new _ExpressionDataModel(@, @entity)
		@action = @parent.action

class cola.Provider extends cola.AjaxService
	@attributes:
		loadMode:	# lazy、manual
			defaultValue: "lazy"
		pageSize: null
		detectEnd: null

	getUrl: (context) ->
		url = @_url
		matches = url.match(/{{.+}}/g)
		if matches
			context.expressionScope ?= new _ExpressionScope(@_scope, context.data)
			for match in matches
				url = url.replace(match, @_evalParamValue(match, context))
		return url

	getInvoker: (context) ->
		provider = new cola.ProviderInvoker(@, @getInvokerOptions(context))
		provider.pageSize = @_pageSize
		provider.detectEnd = @_detectEnd
		return provider

	_evalParamValue: (expr, context) ->
		if expr.charCodeAt(0) is 123	# `{`
			if expr.match(/^{{.+}}$/)
				expression = expr.substring(2, expr.length - 2)
				if _SYS_PARAMS.indexOf(expression) < 0
					expression = cola._compileExpression(expression)
					if expression
						return expression.evaluate(context.expressionScope, "never")
		return expr

	getInvokerOptions: (context) ->
		options = super(context)
		parameter = options.data

		if parameter?
			context.expressionScope ?= new _ExpressionScope(@_scope, context.data)

			if typeof parameter is "string"
				parameter = @_evalParamValue(parameter, context)
			else
				if typeof parameter is "function"
					parameter = parameter(@, context);

				if typeof parameter is "object"
					oldParameter = parameter
					parameter = {}
					for p, v of oldParameter
						if typeof v is "string"
							v = @_evalParamValue(v, context)
						parameter[p] = v

		if not parameter?
			parameter = {}
		else if not (parameter instanceof Object)
			parameter = {
				parameter: parameter
			}

		options.data = parameter
		return options

	translateResult: (result, invokerOptions) ->
		if @_detectEnd and result instanceof Array
			if result.length >= @_pageSize
				result = result.slice(0, @_pageSize)
			else
				result = {
					$entityCount: (invokerOptions.data.from or 0) + result.length
					$data: result
				}
		return result