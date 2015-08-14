#IMPORT_BEGIN
if exports?
	cola = require("./element")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.registerTypeResolver "validator", (config) ->
	return unless config and config.$type
	return cola[$.camelCase(config.$type) + "Validator"]

cola.registerTypeResolver "validator", (config) ->
	if typeof config == "function"
		return cola.CustomValidator
	else if config?.action
		return cola.ActionValidator

class cola.Validator extends cola.Element
	@ATTRIBUTES:
		disabled: null

	validate: () ->
		return if @_disabled
		return @_validate.apply(@, arguments)

class cola.CustomValidator extends cola.Element
	@ATTRIBUTES:
		func: null

	constructor: (config) ->
		if typeof config == "function"
			@set("func", config)
		else
			super(config)

	_validate: () ->
		return @_func?.apply(@, arguments)

class cola.RequireValidator extends cola.Validator
	@ATTRIBUTES:
		trim:
			defaultValue: true

	_validate: (data) ->
		return

class cola.NumberValidator extends cola.Validator
	@ATTRIBUTES:
		min: null
		minInclude:
			defaultValue: true
		max: null
		maxInclude:
			defaultValue: true

	_validate: (data) ->
		return

class cola.LengthValidator extends cola.Validator
	@ATTRIBUTES:
		min: null
		max: null

	_validate: (data) ->
		return

class cola.RegExpValidator extends cola.Validator
	@ATTRIBUTES:
		regExp: null
		mode:
			defaultValue: "white"
			enum: ["white", "black"]

	_validate: (data) ->
		return

class cola.EmailValidator extends cola.Validator
	_validate: (data) ->
		return

class cola.AsyncValidator extends cola.Validator
	@ATTRIBUTES:
		defaultValue: true

class cola.ActionValidator extends cola.AsyncValidator
	@ATTRIBUTES:
		action: null
		async:
			getter: () ->
				return @_action?.get("async")

	_validate: (data, callback) ->
		if @_action
			action = @_action
			parameter = action.get("parameter")
			if parameter
				if cola.util.isSimpleValue(parameter)
					oldParameter = parameter
					parameter = {
						data: data
						parameter: oldParameter
					}
				else
					parameter.data = data
			else
				parameter = {
					data: parameter
				}

			action.set("parameter", parameter).execute({
				scope: @
				callback: (success, result) ->
					cola.callback(callback, success, result)
					return
			})
		else
			cola.callback(callback, true, null)
		return