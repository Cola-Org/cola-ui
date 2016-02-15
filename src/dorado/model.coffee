cola.DataModel::_createRootData = (rootDataType) ->
	entity = new cola.Entity(null, rootDataType)
	entity.acceptUnknownProperty = true
	entity.alwaysTransferEntity = true
	return entity