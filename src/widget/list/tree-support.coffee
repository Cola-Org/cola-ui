_getEntityId = cola.Entity._getEntityId

class cola.CascadeBind extends cola.Element
	@attributes:
		expression:
			setter: (expression) ->
				if expression
					expression = cola._compileExpression(@_scope, expression, "repeat")
					if not expression?.repeat
						throw new cola.Exception("\"#{bindStr}\" is not a repeat expression.")
				@_expression = expression
				return

		recursive: null
		recursiveExpression:
			setter: (expression) ->
				if expression
					@_recursive = true
					expression = cola._compileExpression(@_scope, expression, "repeat")
					if not expression?.repeat
						throw new cola.Exception("\"#{bindStr}\" is not a repeat expression.")
				@_recursiveExpression = expression
				return

		child:
			setter: (child) ->
				if child and not (child instanceof cola.CascadeBind)
					child = new @constructor(@_widget, child)
				@_child = child
				return

		hasChild: null
		hasChildProperty: null

		template: null

	constructor: (widget, config) ->
		@_widget = widget
		super(config)

	_wrapChildItems: (parentNode, recursiveItems, originRecursiveItems, childItems, originChildItems) ->
		nodes = []
		nodeType = @constructor.NODE_TYPE

		nodeCache = parentNode._nodeMap
		nodeMap = {}

		if recursiveItems
			cola.each recursiveItems, (item) =>
				if nodeCache
					id = _getEntityId(item)
					if id
						node = nodeCache[id]
						if node?._bind == @
							delete nodeCache[id]
						else
							node = null

				node ?= new nodeType(@, item)
				node._parent = parentNode
				nodeMap[node._id] = node
				nodes.push(node)
				return

		if childItems
			cola.each childItems, (item) =>
				if nodeCache
					id = _getEntityId(item)
					if id
						node = nodeCache[id]
						if node?._bind == @
							delete nodeCache[id]
						else
							node = null

				node ?= new nodeType(@_child, item)
				node._parent = parentNode
				node._scope = parentNode._scope
				nodes.push(node)
				return

		for id, node of nodeCache
			node.destroy()

		parentNode._nodeMap = nodeMap
		parentNode._children = nodes
		delete parentNode._hasChild

		itemsScope = parentNode._itemsScope
		if itemsScope
			if recursiveItems
				nodes.$origin = originRecursiveItems or recursiveItems
			if childItems
				nodes.$origin = originChildItems or childItems
			itemsScope._setItems.call(itemsScope, nodes)
		return

	retrieveChildNodes: (parentNode, callback, dataCtx) ->
		isRoot = not parentNode._parent
		hasChild = false
		funcs = []
		if @_recursive or isRoot
			dataCtx ?= {}
			if isRoot
				expression = @_expression
			else
				expression = @_recursiveExpression or @_expression
			items = expression.evaluate(parentNode._scope, "async", dataCtx)
			if items == undefined and dataCtx.unloaded
				recursiveLoader = dataCtx.providerInvokers?[0]
				if recursiveLoader
					funcs.push((callback) -> recursiveLoader.invokeAsync(callback))
			else
				recursiveItems = items
				originRecursiveItems = items.$origin if items instanceof Array
				if recursiveItems
					if recursiveItems instanceof cola.EntityList
						hasChild = recursiveItems.entityCount > 0
					else
						hasChild = recursiveItems.length > 0

		if @_child and not isRoot
			dataCtx ?= {}
			items = @_child._expression.evaluate(parentNode._scope, "async", dataCtx)
			if items == undefined and dataCtx.unloaded
				childLoader = dataCtx.providerInvokers?[0]
				if childLoader
					funcs.push((callback) -> childLoader.invokeAsync(callback))
			else
				childItems = items
				originChildItems = items.$origin if items instanceof Array
				hasChild = true

		if funcs.length
			cola.util.waitForAll(funcs, {
				scope: @
				complete: (success, result) ->
					if success
						hasChild = false
						if @_recursive or isRoot
							if isRoot
								expression = @_expression
							else
								expression = @_recursiveExpression or @_expression

							recursiveItems = expression.evaluate(parentNode._scope, "never")
							originRecursiveItems = recursiveItems.$origin if recursiveItems instanceof Array
							if recursiveItems
								if recursiveItems instanceof cola.EntityList and recursiveItems.entityCount > 0
									hasChild = true
								else if recursiveItems.length > 0
									hasChild = true

						if @_child and not isRoot
							childItems = @_child._expression.evaluate(parentNode._scope, "never")
							originChildItems = childItems.$origin if childItems instanceof Array
							if recursiveItems
								if childItems instanceof cola.EntityList and childItems.entityCount > 0
									hasChild = true
								else if childItems.length > 0
									hasChild = true

						@_wrapChildItems(parentNode, recursiveItems, originRecursiveItems, childItems,
							originChildItems)
						parentNode._hasChild = hasChild

						parentNode._itemsScope.onItemsRefresh?()
						if callback then cola.callback(callback, true)
					else
						if callback then cola.callback(callback, false, result)
					return
			})
		else
			@_wrapChildItems(parentNode, recursiveItems, originRecursiveItems, childItems, originChildItems)
			parentNode._hasChild = hasChild
			parentNode._itemsScope.onItemsRefresh?()
			if callback then cola.callback(callback, true)
		return

	hasChildItems: (parentScope) ->
		if @_recursive
			dataCtx = {}

			isRoot = not parentNode._parent
			if isRoot
				expression = @_expression
			else
				expression = @_recursiveExpression or @_expression

			items = expression.evaluate(parentScope, "never", dataCtx)
			if not dataCtx.unloaded
				if items
					if items instanceof cola.EntityList
						hasChild = items.entityCount > 0
					else
						hasChild = items.length > 0
					return true if hasChild
			else
				return true

		if @_child
			dataCtx = {}
			items = @_child._expression.evaluate(parentScope, "never", dataCtx)
			if not dataCtx.unloaded
				if items
					if items instanceof cola.EntityList
						hasChild = items.entityCount > 0
					else
						hasChild = items.length > 0
					return true if hasChild
			else
				return true
		return false

class cola.Node extends cola.Element
	isDataWrapper: true

	@attributes:
		bind:
			readOnly: true
		alias: null
		data: null
		hasChild:
			getter: () ->
				return true if @_children?.length > 0
				return @_hasChild if @_hasChild?

				bind = @_bind
				return bind._hasChild if bind._hasChild?

				prop = bind._hasChildProperty
				if prop and @_data
					if @_data instanceof cola.Entity
						return @_data.get(prop, "never")
					else
						return @_data[prop]

				if @_scope
					if bind._recursive
						dataCtx = {}
						items = bind._expression.evaluate(@_scope, "never", dataCtx)
						if dataCtx.unloaded then return
						if not items then return false
						if items instanceof cola.EntityList
							return items.entityCount > 0
						else
							return items.length > 0
					if bind._child
						dataCtx = {}
						items = bind._child._expression.evaluate(@_scope, "never", dataCtx)
						if dataCtx.unloaded then return
						if not items then return false
						if items instanceof cola.EntityList
							return items.entityCount > 0
						else
							return items.length > 0
				return

		parent:
			readOnly: true
		children:
			readOnly: true

	constructor: (bind, data) ->
		super()
		@_bind = bind
		@_alias = bind._expression?.alias
		@_widget = bind._widget

		@_data = data
		if typeof data == "object"
			@_id = cola.Entity._getEntityId(data)
		else
			@_id = cola.uniqueId()

		@_widget?._onNodeAttach?(@)

	destroy: () ->
		if @_children
			for child in @_children
				child.destroy()
		@_widget?._onNodeDetach?(@)
		return

	remove: () ->
		if @_parent
			parent = @_parent
			i = parent._children.indexOf(@)
			if i > -1
				parent._children.splice(i, 1)
			delete parent._nodeMap[@_id]
		@destroy()
		return

cola.TreeSupportMixin =
	constructor: () ->
		@_nodeMap = {}

	_onNodeAttach: (node) ->
		@_nodeMap[node._id] = node
		return

	_onNodeDetach: (node) ->
		delete @_nodeMap[node._id]
		return

