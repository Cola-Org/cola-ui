# DataType

cola.DataType = dorado.DataType
cola.EntityDataType = dorado.EntityDataType

cola.EntityDataType::ATTRIBUTES.properties =
	path: "propertyDefs"

# Property

cola.Property = dorado.PropertyDef

cola.Property::ATTRIBUTES.caption =
	path: "label"

# Definitions

cola.DataType.jsonToData = cola.DataType.jsonToEntity = (json, dataType, aggregated, pageSize) ->
	dataTypeRepository = cola.getDoradoView()?._dataTypeRepository

	if aggregated and dataType and not dataType instanceOf dorado.AggregationDataType
		dataType = dataTypeRepository.get("[" + dataType._name + "]")

	if pageSize? and dataType and dataType instanceOf dorado.AggregationDataType
		dataType._pageSize = pageSize

	return dorado.DataUtil.convertIfNecessary(json, dataTypeRepository, dataType)

cola.DataType.defaultDataTypes = defaultDataTypes =
	"string": dorado.$String
	"int": dorado.$int
	"float": dorado.$float
	"number": dorado.$float
	"boolean": dorado.$boolean
	"date": dorado.$Date
	"entity": new dorado.EntityDataType({
		name: "entity"
		acceptUnknownProperty: true
	})

cola.DataType.defaultDataTypes.json = cola.DataType.defaultDataTypes.entity