#IMPORT_BEGIN
if exports?
	cola = require("./entity")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.registerTypeResolver "action", (config) ->
	return unless config and config.$type
	return cola[cola.util.capitalize(config.$type) + "Action"]

cola.registerTypeResolver "action", (config) ->
	if config?.url then return cola.AjaxAction
	return cola.Action

class cola.Action extends cola.Element
	@ATTRIBUTES:
		name:
			readOnly: true
		parameter: null
		result: null
		confirmMesssage: null
		successMesssage: null

	@EVENTS:
		beforeExecute: null
		afterExecute: null
		success: null
		failure: null

	@confirmExecuting: (scope, message, callback) ->
		callback.call(scope) if prompt(message)
		return

	@showSuccessMessage: (scope, message, callback) ->
		alert(message)
		callback?.call(scope)
		return

	_internalExecute: () ->
		try
			result = @_execute.apply(@)

			@set("result", result)
			@fire("success", @, {result: result})

			if @_successMesssage
				cola.Action.showSuccessMessage(@, @_successMesssage)
		catch ex
			if @fire("failure", @, {exception: ex}) == false
				cola.Exception.removeException(ex)

		@fire("afterExecute", @)
		return result

	execute: () ->
		if @_confirmMesssage
			cola.Action.confirmExecuting(@, @_confirmMesssage, () ->
				if @fire("beforeExecute", @) == false then return
				@_internalExecute.apply(@)
				return
			)
		else
			if @fire("beforeExecute", @) == false then return
			@_internalExecute.apply(@)
		return

class cola.AsyncAction extends cola.Action

	@ATTRIBUTES:
		async:
			defaultValue: true
		executingMesssage: null

	@showExecutingMessage: (scope, message) ->
		return 1

	@hideExecutingMessage: (scope, messageId) ->
		return

	_internalExecute: (callback) ->
		if @async or !!callback
			if @_executingMesssage
				messageId = cola.AsyncAction.showExecutingMessage(@, @_executingMesssage)

			innerCallback = (success, result) ->
				if messageId
					cola.AsyncAction.hideExecutingMessage(@, messageId)

				if success
					@set("result", result)
					@fire("success", @, {result: result})

					if @_successMesssage
						cola.Action.showSuccessMessage(@, @_successMesssage)
				else
					if @fire("failure", @, {exception: result}) == false
						cola.Exception.removeException(result)

				if callback
					cola.callback(callback, success, result)
				@fire("afterExecute", @)

			if @getListeners("execute")
				@fire("execute", @, {
					scope: @
					callback: innerCallback
				})
			else
				@_execute(innerCallback)
			return
		else
			return super()

class cola.AjaxAction extends cola.AsyncAction
	@ATTRIBUTES:
		url: null
		sendJson: null
		method: null
		ajaxOptions: null

	_getData: () ->
		return @_parameter

	_execute: (callback) ->
		options = {}
		ajaxOptions = @_ajaxOptions
		if ajaxOptions
			for p, v of ajaxOptions
				options[p] = v

		options.async = @_async
		options.url = @getUrl()
		options.data = @_getData()
		options.sendJson = @_sendJson
		options.method = @_method

		if options.sendJson and !options.method
			options.method = "post"

		invoker = new cola.AjaxServiceInvoker(@, options)
		if @_async
			return invoker.invokeAsync(callback)
		else
			return invoker.invokeSync(callback)

class cola.UpdateAction extends cola.AjaxAction
	@ATTRIBUTES:
		data: null
		dataFilter:
			defaultValue: "all"
			enum: ["all", "dirty", "child-dirty", "dirty-tree"]

	@FILTER:
		"dirty": (data) ->
			if data instanceof cola.EntityList
				filtered = []
				data.each (entity) ->
					if entity.state != cola.Entity.STATE_NONE
						filtered.push(entity)
					return
			else if data.state != cola.Entity.STATE_NONE
				filtered = data
			return filtered

		"child-dirty": (data) ->
			return data

		"dirty-tree": (data) ->
			return data

	_getData: () ->
		if @_cacheData?.timestamp == @_timestamp
			data = @_cacheData.data
			delete @_cacheData
			return data

		data = @_data
		if data
			if !(data instanceof cola.Entity or data instanceof cola.EntityList)
				if typeof data == "string"
					data = @_scope.get(data)
					if data and !(data instanceof cola.Entity or data instanceof cola.EntityList)
						invalidSubmitData = true
				else
					invalidSubmitData = true

			if invalidSubmitData
				throw new cola.I18nException("cola.error.invalidSubmitData")

			filter = cola.UpdateAction.FILTER[@_dataFilter]
			data = if filter then filter(data) else data

		data = {
			data: @_scope.get()
			parameter: @_parameter
		}
		@_cacheData = {
			data: data
			timestamp: @_timestamp
		}
		return data

	@showNoDataMessage: (message) ->
		alert(message)
		return

	execute: (callback) ->
		@_timestamp = cola.sequenceNo()
		data = @_getData()
		if !data?
			cola.UpdateAction.showNoDataMessage(cola.i18n("cola.warn.noDataToSubmit"))
			return
		else
			return super(callback)