#IMPORT_BEGIN
if exports?
	cola = require("./element")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.registerTypeResolver "validator", (config)->
	return unless config and config.$type
	return cola[cola.util.capitalize(config.$type) + "Validator"]

cola.registerTypeResolver "validator", (config)->
	if typeof config == "function"
		return cola.CustomValidator

class cola.Validator extends cola.Definition
	@attributes:
		message: null
		messageType:
			defaultValue: "error"
			enum: ["error", "warn", "info"]
		disabled: null
		validateEmptyValue: null

	_getDefaultMessage: (data)->
		return "\"#{data}\" is not a valid value."

	_parseValidResult: (result, data)->
		if typeof result is "boolean"
			if result
				result = null
			else
				text = @_message
				if not text? then text = @_getDefaultMessage(data)
				result = {type: @_messageType, text: text}
		else if result and typeof result is "string"
			result = {type: @_messageType, text: result}
		return result

	validate: (data, entity)->
		if not @_validateEmptyValue
			return unless data? and data isnt ""
		result = @_validate(data, entity)
		return @_parseValidResult(result, data)

class cola.RequiredValidator extends cola.Validator
	@attributes:
		validateEmptyValue:
			defaultValue: true
		trim:
			defaultValue: true

	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.required", data)

	_validate: (data)->
		if not (typeof data is "string") then return data?
		if @_trim then data = cola.util.trim(data)
		return !!data

class cola.NumberValidator extends cola.Validator
	@attributes:
		min: null
		minInclude:
			defaultValue: true
		max: null
		maxInclude:
			defaultValue: true

	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.number", data)

	_validate: (data)->
		result = true
		if @_min?
			result = if @_minInclude then (data >= @_min) else (data > @_min)
		if result and @_max?
			result = if @_maxInclude then (data <= @_max) else (data < @_max)
		return result

class cola.LengthValidator extends cola.Validator
	@attributes:
		min: null
		max: null

	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.length", data)

	_validate: (data)->
		if typeof data is "string" or typeof data is "number"
			result = true
			len = (data + "").length
			if @_min?
				result = len >= @_min
			if result and @_max?
				result = len <= @_max
			return result
		return true

class cola.RegExpValidator extends cola.Validator
	@attributes:
		regExp: null
		mode:
			defaultValue: "white"
			enum: ["white", "black"]

	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.regExp", data)

	_validate: (data)->
		regExp = @_regExp
		if regExp and typeof data is "string"
			if not regExp instanceof RegExp
				regExp = new RegExp(regExp)
			result = true
			result = !!data.match(regExp)
			if @_mode is "black"
				result = not result
			return result
		return true

class cola.EmailValidator extends cola.Validator
	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.email", data)

	_validate: (data)->
		if typeof data is "string"
			return !!data.match(/^([a-z0-9]*[-_\.]?[a-z0-9]+)*@([a-z0-9]*[-_]?[a-z0-9]+)+[\.][a-z]{2,3}([\.][a-z]{2})?$/i)
		return true

class cola.UrlValidator extends cola.Validator
	_getDefaultMessage: (data)->
		return cola.resource("cola.validator.error.email", data)

	_validate: (data)->
		if typeof data is "string"
			return !!data.match(/^(https?:\/\/(?:www\.|(?!www))[^\s\.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,})/i)
		return true

class cola.AsyncValidator extends cola.Validator
	@attributes:
		async:
			defaultValue: true

	validate: (data, entity, callback)->
		if entity instanceof Function
			callback = entity
			entity = undefined

		if not @_validateEmptyValue
			return unless data? and data isnt ""
		if @_async
			result = @_validate(data, entity, {
				complete: (success, result)=>
					if success
						result = @_parseValidResult(result)
					cola.callback(callback, success, result)
					return
			})
		else
			result = @_validate(data, entity)
			result = @_parseValidResult(result)
			cola.callback(callback, true, result)
		return result

class cola.AjaxValidator extends cola.AsyncValidator
	@attributes:
		url: null
		method: null
		ajaxOptions: null
		data: null

	_validate: (data, entity, callback)->
		url = @_url.replace("{{data}}", data)
		if url is @_url
			sendData = @_data
			if not sendData? or sendData is "{{data}}"
				sendData = data
			else if typeof sendData is "object"
				realSendData = {}
				for p, v of sendData
					if v is "{{data}}" then v = data
					realSendData[p] = v
				sendData = realSendData

		options =
			async: !!callback
			url:  url
			data: sendData
			method: @_method

		if @_ajaxOptions
			for p, v of @_ajaxOptions
				if not options.hasOwnProperty(p)
					options[p] = v

		$.ajax(options).done((result)=>
			if callback
				return cola.callback(callback, true, result)
			else
				return result
		).fail((error)=>
			if callback
				return cola.callback(callback, false, error)
			else
				return error
		)

class cola.CustomValidator extends cola.AsyncValidator
	@attributes:
		async:
			defaultValue: false
		validateEmptyValue:
			defaultValue: true
		func: null

	constructor: (config)->
		if typeof config is "function"
			super()
			@set(
				func: config
				async: cola.util.parseFunctionArgs(config).length > 2
			)
		else
			super(config)

	_validate: (data, entity, callback)->
		if @_async and callback
			if @_func
				@_func(data, entity, callback)
			else
				cola.callback(callback, true)
			return
		else
			return @_func?(data, entity)