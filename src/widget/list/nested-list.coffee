class cola.NestedListNode extends cola.Node
	@ATTRIBUTES:
		title:
			readOnly: true
			getter: () ->
				prop = @_bind._titleProperty
				if prop
					if @_data instanceof cola.Entity
						title = @_data.get(prop)
					else
						title = @_data[prop]
				return title or "#Unknown"

class cola.NestedListBind extends cola.CascadeBind
	@NODE_TYPE = cola.NestedListNode
	@ATTRIBUTES:
		titleProperty: null

class cola.NestedList extends cola.Widget
	@CLASS_NAME: "nested-list"

	@ATTRIBUTES:
		bind:
			setter: (bind) ->
				if bind and !(bind instanceof cola.NestedListBind)
					bind = new cola.NestedListBind(@, bind)
				@_bind = bind
				@_rootNode.set("bind", bind) if @_rootNode
				return

		autoSplit:
			type: "boolean"
			defaultValue: true
		navBarWidth:
			defaultValue: "280px"
		showTitleBar:
			type: "boolean"
			defaultValue: true
		title: null
		layerIndex:
			readOnly: true
			getter: () -> @_layerIndex
		splited:
			readOnly: true
			getter: () -> @_autoSplit and @_largeScreen

	@EVENTS:
		getItemTemplate: null
		itemClick: null
		renderItem: null
		initLayer: null
		topLayerChange: null

	_initDom: (dom) ->
		if @_autoSplit
			if cola.device.pad
				@_largeScreen = true
			else if cola.device.desktop
				@_largeScreen = document.body.clientWidth > 480

		@_doms ?= {}
		layer = @_createLayer(0)
		@_layers = [layer]
		@_layerIndex = 0
		@_initLayer(layer, null, 0)

		if @_autoSplit and @_largeScreen
			$fly(dom).xAppend([
				{
					tagName: "div"
					class: "nav"
					style:
						width: @_navBarWidth
						height: "100%"
						float: "left"
						overflow: "hidden"
					content: layer.container
				}
				{
					tagName: "div"
					class: "detail"
					style:
						marginLeft: @_navBarWidth
						height: "100%"
						position: "relative"
						overflow: "hidden"
					contextKey: "detailContainer"
				}
			], @_doms)
		else
			@_doms.detailContainer = dom
			layer.container.appendTo(dom)

		itemsScope = layer.list._itemsScope
		@_rootNode = new cola.NestedListNode(@_bind)
		@_rootNode._scope = @_scope
		@_rootNode._itemsScope = itemsScope

		if @_bind
			@_itemsRetrieved = true
			nestedList = @
			@_bind.retrieveChildNodes(nestedList._rootNode, () ->
				if nestedList._autoSplit and nestedList._largeScreen
					children = nestedList._rootNode._children
					firstNode = children?[0]
					if firstNode?._scope
						nestedList._showLayer(1, children?[0])
				return
			)
			itemsScope._retrieveItems = (dataCtx) -> nestedList._bind.retrieveChildNodes(nestedList._rootNode, null, dataCtx)

		@fire("topLayerChange", @, {
			index: 0
		})
		return

	_parseDom: (dom)->
		return unless dom
		child = dom.firstChild
		while child
			@_regTemplate(child) if child.nodeName == "TEMPLATE"
			child = child.nextSibling
		return

	_createLayer: (index) ->
		highlightCurrentItem = (@_autoSplit and @_largeScreen and index == 0)
		useLayer = index > (if @_autoSplit and @_largeScreen then 1 else 0)

		hjson =
			tagName: "div"
			style:
				height: "100%"
			contextKey: "container"
			"c-widget": if useLayer then "layer" else "widget"
			content:
				tagName: "div"
				class: "v-box"
				style:
					height: "100%"

		listConfig =
			$type: "listView"
			class: @_ui
			highlightCurrentitem: true
			allowNoCurrent: not highlightCurrentItem
			highlightCurrentItem: highlightCurrentItem
			height: "100%"
			userData: index
			getItemTemplate: (self, arg) => @_onGetItemTemplate(self, arg)
			renderItem: (self, arg) => @_onRenderItem(self, arg)
			itemClick: (self, arg) => @_onItemClick(self, arg)

		if @_showTitleBar
			if useLayer
				menuItemsConfig = [{
					icon: "chevron left"
					click: () => @back()
				}]
			else
				menuItemsConfig = undefined

			hjson.content.content = [
				{
					tagName: "div"
					class: "box title-box"
					content:
						tagName: "div"
						contextKey: "titleBar"
						"c-widget":
							$type: "titleBar"
							class: @_ui
							items: menuItemsConfig
				},
				{
					tagName: "div"
					class: "flex-box list-box"
					content:
						tagName: "div"
						contextKey: "list"
						"c-widget": listConfig
				}
			]
		else
			hjson.content.content = {
				tagName: "div"
				contextKey: "list"
				"c-widget": listConfig
			}

		ctx = {}
		new cola.xRender(hjson, @_scope, ctx)

		list = cola.widget(ctx.list)
		oldRefreshItemDom = list._refreshItemDom
		list._refreshItemDom = (itemDom, node, parentScope) ->
			itemScope = oldRefreshItemDom.apply(@, arguments)
			node._scope = itemScope
			return itemScope

		if ctx.container
			container = cola.widget(ctx.container)
		else
			container = list

		if @_templates
			for name, template of @_templates
				list._templates[name] = template

		layer = {
			itemsScope: list._itemsScope
			titleBar: cola.widget(ctx.titleBar)
			list: list
			container: container
		}
		return layer

	_initLayer: (layer, parentNode, index) ->
		layer.titleBar?.set("title", if parentNode then parentNode.get("title") else @_title)
		@fire("initLayer", @, {
			parentNode: parentNode
			parentItem: parentNode?._data
			index: index
			list: layer.list
			titleBar: layer.titleBar
		})
		return

	_getLayerInfo: (layer) ->
		return {
			index: layer.index
			parentNode: layer.parentNode
			parentItem: layer.parentNode?._data
			title: layer.parentNode?.get("title")
			titleBar: layer.titleBar
			list: layer.list
			nodes: layer.list.get("items")
		}

	_showLayer: (index, parentNode, callback) ->
		if index <= @_layerIndex
			i = index
			while i <= @_layerIndex
				@_hideLayer(i == @_layerIndex)
			@_layerIndex = index - 1

		if index >= @_layers.length
			layer = @_createLayer(index)
			@_layers.push(layer)
			layer.container.appendTo(@_doms.detailContainer)
		else
			layer = @_layers[index]

		list = layer.list
		itemsScope = list._itemsScope
		itemsScope.setParent(parentNode._scope)
		parentNode._itemsScope = itemsScope
		parentNode._bind.retrieveChildNodes(parentNode, () =>
			if parentNode._children
				@_initLayer(layer, parentNode, index)
				if layer.container instanceof cola.Layer
					layer.container.show()
				@_layerIndex = index
				layer.parentNode = parentNode
				@fire("topLayerChange", @, @_getLayerInfo(layer))
			callback?(wrapper?)
			return
		)
		itemsScope._retrieveItems = (dataCtx) -> parentNode._bind.retrieveChildNodes(parentNode, null, dataCtx)
		return

	_hideLayer: (animation) ->
		layer = @_layers[@_layerIndex]
		delete layer.list._itemsScope._retrieveItems
		options = {}
		if !animation then options.animation = "none"
		if layer.container instanceof cola.Layer
			layer.container.hide(options, () ->
				layer.titleBar?.set("rightItems", null)
				return
			)
		else
			layer.titleBar?.set("rightItems", null)
		delete layer.parentNode
		@_layerIndex--

		previousLayer = @_layers[@_layerIndex]
		@fire("topLayerChange", @, @_getLayerInfo(previousLayer))
		return

	back: () ->
		if @_layerIndex > (if @_autoSplit and @_largeScreen then 1 else 0)
			@_hideLayer(true)
			return true
		else
			return false

	_onGetItemTemplate: (self, arg) ->
		node = arg.item
		return @fire("getItemTemplate", @, { item: node._data })

	_onItemClick: (self, arg) ->
		node = arg.item
		retValue = @fire("itemClick", @, {
			node: node
			item: node._data
			bind: node._bind
		})
		if retValue != false
			@_showLayer(self.get("userData") + 1, arg.item, (hasChild) =>
				if !hasChild
					@fire("leafItemClick", @, {
						node: node
						item: node._data
					})
				return
			)
		return

	_onRenderItem: (self, arg) ->
		node = arg.item
		hasChild = node.get("hasChild")
		if !hasChild? and node._scope
			hasChild = node._bind.hasChildItems(node._scope)
		$fly(arg.dom).toggleClass("has-child", !!hasChild)

		if @getListeners("renderItem")
			@fire("renderItem", @, {
				node: node
				item: node._data
				dom: arg.dom
			})
		return

	getLayer: (index) ->
		layer = @_layers[index]
		return if layer then @_getLayerInfo(layer) else null

	getTopLayer: () ->
		return @getLayer(@_layerIndex)

cola.Element.mixin(cola.NestedList, cola.TemplateSupport)