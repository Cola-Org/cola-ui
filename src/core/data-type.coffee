#IMPORT_BEGIN
if exports?
	XDate = require("./../lib/xdate")
	cola = require("./expression")
	require("./date")
	module?.exports = cola
else
	XDate = @XDate
	cola = @cola
#IMPORT_END

class cola.DataType extends cola.Element
	@ATTRIBUTES:
		name:
			readOnlyAfterCreate: true

	constructor: (config) ->
		if config?.name
			@_name = config.name
			delete config.name
			scope = config?.scope or cola.currentScope
			if scope and DataType.autoRegister
				scope.data.regDataType(@)
		super(config)

class cola.BaseDataType extends cola.DataType

class cola.StringDataType extends cola.BaseDataType
	toText: (value) ->
		return if value? then value + "" else ""

	parse: (text) ->
		return text

class cola.NumberDataType extends cola.BaseDataType
	@ATTRIBUTES:
		isInteger: null

	parse: (text) ->
		if !text then return 0

		if typeof text == "number"
			if @_isInteger
				return Math.round(text)
			else
				return text

		if @_isInteger
			n = Math.round(parseInt(text, 10))
		else
			n = parseFloat(text, 10)
		return if isNaN(n) then 0 else n

class cola.BooleanDataType extends cola.BaseDataType
	parse: (text) ->
		if !text then return false
		if typeof text == "boolean" then return text
		if ["true", "on", "yes", "y", "1"].indexOf((text + "").toLowerCase()) > -1 then return true
		return false

class cola.DateDataType extends cola.BaseDataType
	parse: (text) ->
		if !text then return new Date(NaN)
		xDate = new XDate(text)
		return xDate.toDate()

class cola.JSONDataType extends cola.DataType
	toText: (value) ->
		return JSON.stringify(value)

	parse: (text) ->
		return JSON.parse(text)

###
EntityDataType
###

class cola.EntityDataType extends cola.DataType
	@ATTRIBUTES:
		readOnly: null

		properties:
			setter: (properties) ->
				@_properties.clear()
				if properties instanceof Array
					for property in properties
						@addProperty(property)
				else
					for name, config of properties
						if config
							if not (property instanceof cola.Property)
								config.name = name
							@addProperty(config)

	@EVENTS:
		beforeCurrentChange: null
		currentChange: null

		beforeDataChange: null
		dataChange: null

		beforeEntityInsert: null
		entityInsert: null

		beforeEntityDelete: null
		entityDelete: null

	constructor: (config) ->
		@_properties = new cola.util.KeyedArray()
		super(config)

	addProperty: (property) ->
		if not (property instanceof cola.Property)
			if typeof property.compute == "function"
				property = new cola.ComputeProperty(property)
			else
				property = new cola.BaseProperty(property)
		else if property._owner and property._owner != @
			throw new cola.I18nException("cola.error.objectNotFree", "Property(#{property._name})", "DataType")

		if @_properties.get(property._name)
			@removeProperty(property._name)

		@_properties.add(property._name, property)
		property._owner = @
		return property

	removeProperty: (property) ->
		if property instanceof cola.Property
			@_properties.remove(property._name)
		else
			property = @_properties.remove(property)
		delete property._owner
		return property

	getProperty: (name) ->
		i = name.indexOf(".")
		if i > 0
			part1 = name.substring(0, i)
			part2 = name.substring(i + 1)
			prop = @_getProperty(part1)
			if prop?._dataType
				return prop?._dataType.getProperty(part2)
		else
			return @_getProperty(name)

	_getProperty: (name) ->
		return @_properties.get(name)

	getProperties: () ->
		return @_properties

cola.DataType.dataTypeSetter = (dataType) ->
	if typeof dataType == "string"
		name = dataType
		scope = @_scope
		if scope
			dataType = scope.dataType(name)
		else
			dataType = cola.DataType.defaultDataTypes[name]
		if not dataType
			throw new cola.I18nException("cola.error.unrecognizedDataType", name)
	else if dataType? and not (dataType instanceof cola.DataType)
		dataType = new cola.EntityDataType(dataType)
	@_dataType = dataType or null
	return

class cola.Property extends cola.Element
	@ATTRIBUTES:
		name:
			readOnlyAfterCreate: true
		owner:
			readOnly: true
		caption: null
		dataType:
			setter: cola.DataType.dataTypeSetter
		description: null

	constructor: (config) ->
		super(config)

class cola.BaseProperty extends cola.Property
	@ATTRIBUTES:
		provider:
			setter: (provider) ->
				if provider? and !(provider instanceof cola.Provider)
					provider = new cola.Provider(provider)
				@_provider = provider
				return
		defaultValue: null
		readOnly: null
		required: null
		aggregated:
			readOnlyAfterCreate: true
		validators:
			setter: (validators) ->

				addValidator = (validator) =>
					if not (validator instanceof cola.Validator)
						validator = cola.create("validator", validator, cola.Validator)
					@_validators.push(validator)
					if validator instanceof cola.RequiredValidator and not @_required
						@_required = true
					return

				delete @_validators
				if validators
					@_validators = []
					if typeof validators is "string"
						validator = cola.create("validator", validators, cola.Validator)
						@_validators.push(validator)
					else if validators instanceof Array
						addValidator(validator) for validator in validators
					else
						addValidator(validators)
				return
		rejectInvalidValue: null

	@EVENTS:
		beforeWrite: null
		write: null
		beforeLoad: null
		loaded: null

class cola.ComputeProperty extends cola.Property
	@ATTRIBUTES:
		delay: null
		watchingDataPath: null

	@EVENTS:
		compute:
			singleListener: true

	compute: (entity) ->
		return @fire("compute", @, {entity: entity})

cola.DataType.jsonToEntity = (json, dataType, aggregated) ->
	if aggregated == undefined
		if json instanceof Array
			aggregated = true
		else if typeof json == "object" and json.hasOwnProperty("$data")
			aggregated = json.$data instanceof Array
		else
			aggregated = false

	if aggregated
		return new cola.EntityList(dataType, json)
	else
		if json instanceof Array
			throw new cola.I18nException("cola.error.unmatchedDataType", "Object", "Array")
		return new cola.Entity(dataType, json)

cola.DataType.jsonToData = (json, dataType, aggregated) ->
	if dataType instanceof cola.StringDataType and typeof json != "string" or dataType instanceof cola.BooleanDataType and typeof json != "boolean" or dataType instanceof cola.NumberDataType and typeof json != "number" or dataType instanceof cola.DateDataType and !(json instanceof Date)
		result = dataType.parse(json)
	else if dataType instanceof cola.EntityDataType
		result = cola.DataType.jsonToEntity(json, dataType, aggregated)
	else if dataType and typeof json == "object"
		result = dataType.parse(json)
	else
		result = json
	return result

cola.DataType.defaultDataTypes = defaultDataTypes =
	"string": new cola.StringDataType(name: "string")
	"int": new cola.NumberDataType(name: "int", isInteger: true)
	"float": new cola.NumberDataType(name: "float")
	"boolean": new cola.BooleanDataType(name: "boolean")
	"date": new cola.DateDataType(name: "date")
	"json": new cola.JSONDataType(name: "json")
	"entity": new cola.EntityDataType(name: "entity")

defaultDataTypes["number"] = defaultDataTypes["int"]

cola.DataType.autoRegister = true