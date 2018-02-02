class cola.DataType extends cola.Definition

class cola.BaseDataType extends cola.DataType

class cola.StringDataType extends cola.BaseDataType
	toText: (value)->
		return if value? then value + "" else ""

	parse: (text)->
		return text

class cola.NumberDataType extends cola.BaseDataType
	@attributes:
		isInteger: null

	parse: (text)->
		if not text then return 0

		if typeof text is "number"
			if @_isInteger
				n = Math.round(text)
			else
				n = text
		else
			if @_isInteger
				n = Math.round(+text)
			else
				n = +text

		if n < Number.MIN_SAFE_INTEGER
			n = Number.MIN_SAFE_INTEGER
		else if n > Number.MAX_SAFE_INTEGER
			n = Number.MAX_SAFE_INTEGER
		else if isNaN(n)
			n = 0
		return n

class cola.BooleanDataType extends cola.BaseDataType
	parse: (text)->
		if not text then return false
		if typeof text is "boolean" then return text
		if ["TRUE", "ON", "YES", "Y", "1", "T"].indexOf((text + "").toUpperCase()) > -1 then return true
		return false

class cola.DateDataType extends cola.BaseDataType
	parse: (text)->
		if not text then return null
		xDate = new XDate(text)
		return xDate.toDate()

class cola.JSONDataType extends cola.DataType
	toText: (value)->
		return JSON.stringify(value)

	parse: (text)->
		if typeof text is "string"
			return JSON.parse(text)
		else
			return text

###
EntityDataType
###

class cola.EntityDataType extends cola.DataType
	@attributes:
		disableValidators:
			setter: (disabled)->
				for propertyDef in @_properties.elements
					propertyDef.set("disableValidators", disabled)
				return

		properties:
			setter: (properties)->
				@_properties.clear()
				if properties instanceof Array
					for property in properties
						@addProperty(property)
				else
					for property, config of properties
						if config
							if not (config instanceof cola.Property)
								config.property = property
							@addProperty(config)

	@events:
		beforeCurrentChange: null
		currentChange: null

		beforeDataChange: null
		dataChange: null

		entityCreate: null

		beforeEntityRemove: null
		entityRemove: null

		beforeEntityInsert: null
		entityInsert: null

		beforeEntityDelete: null
		entityDelete: null

	constructor: (config)->
		@_properties = new cola.util.KeyedArray()
		super(config)

	addProperty: (property)->
		if not (property instanceof cola.Property)
			if typeof property is "string"
				property = new cola.Property(property: property)
			else
				property = new cola.Property(property)
		else if property._owner and property._owner != @
			throw new cola.Exception("Property(#{property._property}) is already belongs to anthor DataType.")

		if @_properties.get(property._property)
			@removeProperty(property._property)

		@_properties.add(property._property, property)
		@_properties.add(property._property, property)
		property._owner = @
		return property

	removeProperty: (property)->
		if property instanceof cola.Property
			@_properties.remove(property._property)
		else
			property = @_properties.remove(property)
		delete property._owner
		return property

	getProperty: (path)->
		i = path.indexOf(".")
		if i > 0
			part1 = path.substring(0, i)
			part2 = path.substring(i + 1)
			prop = @_getProperty(part1)
			if prop?._dataType
				return prop?._dataType.getProperty(part2)
		else
			return @_getProperty(path)

	_getProperty: (property)->
		if property.charCodeAt(property.length - 1) is 35 # `#`
			property = property.substring(0, property.length - 1)
		return @_properties.get(property)

	getProperties: ()->
		return @_properties

cola.DataType.dataTypeSetter = (dataType)->
	if typeof dataType is "string"
		name = dataType
		scope = @_scope
		if scope
			dataType = scope.dataType(name)
		else
			dataType = cola.DataType.defaultDataTypes[name]
		if not dataType
			throw new cola.Exception("Unrecognized DataType \"#{name}\".")
	else if dataType? and not (dataType instanceof cola.DataType)
		dataType = new cola.EntityDataType(dataType)
	@_dataType = dataType or null
	return

class cola.Property extends cola.Definition
	@attributes:
		property:
			readOnlyAfterCreate: true
		name:
			setter: (name)->
				@_name = name
				@_property ?= name
				return
		owner:
			readOnly: true
		caption: null
		dataType:
			setter: cola.DataType.dataTypeSetter
		description: null

		provider:
			setter: (provider)->
				if provider? and not (provider instanceof cola.Provider)
					provider = new cola.Provider(provider)
				@_provider = provider
				return
		defaultValue: null

		aggregated:
			readOnlyAfterCreate: true
		skipLoading:    # smart, never
			defaultValue: "smart"
			readOnlyAfterCreate: true

		disableValidators:
			setter: (disabled)->
				if @_validators
					for validator in @_validators
						validator.set("disabled", disabled)
				return

		validators:
			setter: (validators)->
				addValidator = (validator)=>
					if not (validator instanceof cola.Validator)
						validator = cola.create("validator", validator, cola.Validator)
					@_validators.push(validator)
					return

				delete @_validators
				if validators
					@_validators = []
					if typeof validators is "string"
						validator = cola.create("validator", validators, cola.Validator)
						addValidator(validator)
					else if validators instanceof Array
						addValidator(validator) for validator in validators
					else
						addValidator(validators)
				return

	@events:
		read: null
		beforeWrite: null
		write: null
		beforeLoad: null
		load: null

cola.DataType.jsonToEntity = (json, dataType, aggregated, pageSize)->
	if aggregated == undefined
		if json instanceof Array
			aggregated = true
		else if typeof json is "object" and json.hasOwnProperty("$data")
			aggregated = json.$data instanceof Array
		else if typeof json is "object" and json.hasOwnProperty("data$")
			aggregated = json.data$ instanceof Array
		else
			aggregated = false

	if aggregated
		entityList = new cola.EntityList(null, dataType)
		if pageSize then entityList.pageSize = pageSize
		entityList.fillData(json)
		return entityList
	else
		if json instanceof Array
			throw new cola.Exception("Unmatched DataType. expect \"Object\" but \"Array\".")
		return new cola.Entity(json, dataType)

cola.DataType.jsonToData = (json, dataType, aggregated, pageSize)->
	if dataType instanceof cola.StringDataType and typeof json isnt "string" or dataType instanceof cola.BooleanDataType and typeof json isnt "boolean" or dataType instanceof cola.NumberDataType and typeof json isnt "number" or dataType instanceof cola.DateDataType and not (json instanceof Date)
		result = dataType.parse(json)
	else if dataType instanceof cola.EntityDataType
		result = cola.DataType.jsonToEntity(json, dataType, aggregated, pageSize)
	else if dataType and typeof json is "object"
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

defaultDataTypes["number"] = defaultDataTypes["float"]