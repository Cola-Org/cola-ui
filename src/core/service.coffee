class cola.ProviderInvoker

	constructor: (@ajaxService, @invokerOptions)->
		@callbacks = []

	invokeCallback: (success, result)->
		@invoking = false
		@deferred = null
		callbacks = @callbacks
		@callbacks = []
		for callback in callbacks
			cola.callback(callback, success, result)
		return

	_replaceSysParams: (options)->
		url = options.originUrl or options.url
		matches = url.match(/{{\$[\w-]+}}/g)
		if matches
			options.originUrl ?= url
			for match in matches
				name = match.substring(3, match.length - 2)
				if name
					url = url.replace(match, (@[name] + "") or "")
					options.url = url
					changed = true

		data = options.originData or options.data
		if data
			for p, v of data
				if typeof v is "string"
					if v.charCodeAt(0) is 123 and v.match(/^{{\$[\w-]+}}$/) # `{`
						options.originData ?= $.extend({}, data)
						data[p] = @[v.substring(3, v.length - 2)]
						changed = true
		return changed

	applyPagingParameters: (options)->
		if not @_replaceSysParams(options)
			if not options.data? then options.data = {}
			if cola.setting("pagingParamStyle") is "from"
				options.data.from = @from
				options.data.limit = @limit + (if @detectEnd then 1 else 0)
			else
				options.data.pageSize = @pageSize
				options.data.pageNo = @pageNo
		return

	_beforeSend: (options)->
		if not @pageNo >= 1 then @pageNo = 1
		@from = @pageSize * (@pageNo - 1)
		@limit = @pageSize
		if @pageSize
			@applyPagingParameters(options)
		else
			@_replaceSysParams(options)
		return

	_internalInvoke: (async = true)->
		ajaxService = @ajaxService

		invokerOptions = @invokerOptions

		options = {}
		for p, v of invokerOptions
			options[p] = v
		options.async = async

		if options.sendJson
			options.data = JSON.stringify(options.data)

		if ajaxService.getListeners("beforeSend")
			if ajaxService.fire("beforeSend", ajaxService, {options: options}) == false
				return $.Deferred()

		if @_beforeSend then @_beforeSend(options)

		@invoking = true
		@deferred = retValue = $.ajax(options).done( (result)=>
			if ajaxService.getListeners("response")
				arg = {options: options, result: result}
				ajaxService.fire("response", ajaxService, arg)
				result = arg.result

			retValue = ajaxService.translateResult(result, options)

			@invokeCallback(true, result)

			if @parentData
				if @property
					data = @parentData.get(@property)
				else
					data = @parentData

			if ajaxService.getListeners("success")
				ajaxService.fire("success", ajaxService, {options: options, result: retValue, data: data })
			if ajaxService.getListeners("complete")
				ajaxService.fire("complete", ajaxService, {success: true, options: options, result: retValue, data: data })
			return
		).fail( (xhr, status, message)=>
			console.error(xhr.responseJSON)

			error =
				xhr: xhr
				status: status
				message: message
				data: xhr.responseJSON

			ret = @invokeCallback(false, error)
			retValue = ret if ret isnt undefined
			return retValue if retValue is false

			ret = ajaxService.fire("error", ajaxService, {options: options, xhr: xhr, error: error})
			retValue = ret if ret isnt undefined
			return retValue if retValue is false

			ret = ajaxService.fire("complete", ajaxService, {success: false, xhr: xhr, options: options, error: error})
			retValue = ret if ret isnt undefined
			return
		)
		return retValue

	invokeAsync: (callback)->
		@callbacks.push(callback)
		if @invoking
			return @deferred
		return @_internalInvoke()

	invokeSync: (callback)->
		if @invoking
			throw new cola.Exception("Cannot perform synchronized request during an asynchronized request executing. [#{@url}]")
		@callbacks.push(callback)
		return @_internalInvoke(false)

class cola.Provider extends cola.Definition
	@attributes:
		url: null
		method: null
		sendJson: null
		parameter: null
		timeout: null
		ajaxOptions: null
		loadMode:	# lazy、manual
			defaultValue: "lazy"
		pageSize: null
		detectEnd: null

	@events:
		beforeExecute: null
		beforeSend: null
		response: null
		complete: null
		success: null
		error: null

	constructor: (config)->
		if typeof config is "string"
			config = {
				url: config
			}
		super(config)

	getUrl: (context)->
		url = @_url
		matches = url.match(/{{[^{{}}]+}}/g)
		if matches
			context.expressionScope ?= new _ExpressionScope(@_scope, context.expressionData)
			for match in matches
				url = url.replace(match, @_evalParamValue(match, context))
		return url

	_evalParamValue: (expr, context)->
		if expr.charCodeAt(0) is 123	# `{`
			if expr.match(/^{{[^{{}}]+}}$/)
				expression = expr.substring(2, expr.length - 2)
				if cola.constants._SYS_PARAMS.indexOf(expression) < 0
					expression = cola._compileExpression(context.expressionScope, expression)
					if expression
						return expression.evaluate(context.expressionScope, "never")
		return expr

	getInvokerOptions: (context)->
		options = {}
		ajaxOptions = @_ajaxOptions
		if ajaxOptions
			for p, v of ajaxOptions
				options[p] = v

		options.url = @getUrl(context)
		options.method = @_method if @_method
		options.timeout = @_timeout if @_timeout

		if @_sendJson
			options.sendJson = true
			options.method = "POST" if not options.method
			options.contentType = "application/json" if not options.contentType

		if @_parameter instanceof cola.Entity or @_parameter instanceof cola.EntityList
			parameter = @_parameter.toJSON(nullValue: false)
		else
			parameter = @_parameter

		if parameter?
			context.expressionScope ?= new _ExpressionScope(@_scope, context.expressionData)

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
		# options.dataType ?= "json"
		return options

	translateResult: (result, invokerOptions)->
		# Spring MVC+Ajax在分页模式下，null的返回会自动处理为""
		if result is "" and @_pageSize > 0
			result = null

		if @_detectEnd and result instanceof Array
			if result.length >= @_pageSize
				result = result.slice(0, @_pageSize)
			else
				result = {
					$entityCount: (invokerOptions.data.from or 0) + result.length
					$data: result
				}
		return result

	getInvoker: (context)->
		@fire("beforeExecute", @, {
			context: context
		})

		invoker = new cola.ProviderInvoker(@, @getInvokerOptions(context))
		invoker.parentData = context.parentData
		invoker.property = context.property
		invoker.pageSize = @_pageSize
		invoker.detectEnd = @_detectEnd
		return invoker

class _ExpressionDataModel extends cola.AbstractDataModel
	constructor: (model, @entity)->
		super(model)

	get: (path, loadMode, context)->
		if path.charCodeAt(0) is 64 # `@`
			return @entity.get(path.substring(1))
		else
			return @model.parent?.data.get(path, loadMode, context)

	set: cola._EMPTY_FUNC
	processMessage: cola._EMPTY_FUNC
	getDataType: cola._EMPTY_FUNC
	getProperty: cola._EMPTY_FUNC
	flush: cola._EMPTY_FUNC

class _ExpressionScope extends cola.SubScope
	constructor: (@parent, @entity)->
		@data = new _ExpressionDataModel(@, @entity)
		@action = @parent.action