class cola.TreeNode extends cola.Node
	@attributes:
		expanded:
			getter: () ->
				if @_expanded? then return @_expanded

				prop = @_bind._expandedProperty
				if prop and @_data
					if @_data instanceof cola.Entity
						return @_data.get(prop, "never")
					else
						return @_data[prop]
				return
			setter: (expanded) ->
				@_expanded = expanded
				if expanded then @_widget.expand(@) else @_widget.collapse(@)
				return

		hasExpanded: null
		checked:
			getter: () ->
				prop = @_bind._checkedProperty
				if prop and @_data
					if @_data instanceof cola.Entity
						return @_data.get(prop, "never")
					else
						return @_data[prop]
				return
			setter: (checked) ->
				prop = @_bind._checkedProperty
				if prop and @_data
					if @_data instanceof cola.Entity
						@_data.set(prop, checked)
					else
						@_data[prop] = checked
				return

class cola.TreeNodeBind extends cola.CascadeBind
	@NODE_TYPE: cola.TreeNode

	@attributes:
		textProperty: null
		expandedProperty: null
		checkedProperty: null
		autoCheckChildren:
			defaultValue: true

class cola.Tree extends cola.AbstractList
	@tagName: "c-tree"
	@CLASS_NAME: "items-view tree"

	@attributes:
		bind:
			refreshItems: true
			setter: (bind) ->
				if bind and not (bind instanceof cola.TreeNodeBind)
					bind = new cola.TreeNodeBind(@, bind)

				@_bind = bind

				if bind
					@_itemsScope.setExpression(bind._expression)
				return

		currentNode:
			readOnly: true

		currentItemAlias:
			setter: (alias) ->
				if @_currentItemAlias
					@_scope.set(@_currentItemAlias, null)
				@_currentItemAlias = alias
				if alias
					@_scope.set(alias, @_currentNode?._data)
				return

		autoCollapse: null
		autoExpand: null
		lazyRenderChildNodes:
			defaultValue: true

	@events:
		beforeCurrentNodeChange: null
		currentNodeChange: null

	@TEMPLATES:
		"default":
			tagName: "ul"
			content:
				tagName: "div"
				class: "tree node"
				content: [
					{
						tagName: "div"
						class: "expand-button"
					}
				]
		"checkable":
			tagName: "ul"
			content:
				tagName: "div"
				class: "tree node"
				content: [
					{
						tagName: "div"
						class: "expand-button"
					},
					{
						tagName: "div"
						"c-widget":
							$type: "checkbox"
							class: "node-checkbox"
							triState: true
					}
				]
		"node":
			tagName: "span"
			"c-bind": "$default"

	_initDom: (dom) ->
		super(dom)
		$fly(dom).attr("tabIndex", 1)
		$fly(@_doms.itemsWrapper)
		.delegate(".expand-button", "click", (evt) => @_expandButtonClick(evt))
		.delegate(".tree.item", "click", (evt) =>
			if @_autoExpand
				itemDom = @_findItemDom(evt.currentTarget)
				return false unless itemDom
				node = cola.util.userData(itemDom, "item")
				return false unless node

				if node.get("expanded")
					@collapse(node)
				else if node.get("hasChild") isnt false
					@expand(node)
				return false
			return false
		)

		itemsScope = @_itemsScope
		@_rootNode = new cola.TreeNode(@_bind)
		@_rootNode._scope = @_scope
		@_rootNode._itemsScope = itemsScope

		itemsScope.onMessage = (path, type, arg) =>
			if type is cola.constants.MESSAGE_REFRESH
				if itemsScope.isParentOfTarget(path)
					@_refreshItems()
					return true
				else
					node = @findNode(arg.entityList or arg.entity)
					if node
						node._scope?.processMessage(null, path, type, arg)
						if node.get("expanded")
							@_prepareChildNode(node, true)
					return true

			else if type is cola.constants.MESSAGE_PROPERTY_CHANGE
				node = @findNode(arg.entity)
				if node
					node._scope?.processMessage(null, path, type, arg)
					if arg.value and arg.value instanceof cola.EntityList or
					  arg.oldValue and arg.oldValue instanceof cola.EntityList
						if node.get("expanded")
							@_prepareChildNode(node, true)
					return true
				else if itemsScope.isParentOfTarget(path)
					@_refreshItems()
					return true

			else if type is cola.constants.MESSAGE_INSERT
				parentNode = @findNode(arg.entityList.parent)
				if parentNode then @_prepareChildNode(parentNode, parentNode.get("expanded"))
				return true

			else if type is cola.constants.MESSAGE_REMOVE
				node = @findNode(arg.entity)
				if node then @_removeNode(node)
				return true

			return

		if @_bind
			@_itemsRetrieved = true
			@_bind.retrieveChildNodes(@_rootNode)
			itemsScope._retrieveItems = (dataCtx) => @_bind.retrieveChildNodes(@_rootNode, null, dataCtx)
		return

	_setCurrentItemDom: (currentItemDom)->
		return unless currentItemDom
		node = cola.util.userData(currentItemDom, "item")
		if node then @_setCurrentNode(node)

	setCurrentItem: (item) ->
		node = @findNode(item)
		@_setCurrentNode(node)
		return node

	_setCurrentNode: (node) ->
		return if @_currentNode == node

		eventArg =
			oldCurrent: @_currentNode
			newCurrent: node

		if @fire("beforeCurrentNodeChange", @, eventArg) == false
			return

		if @_currentNode
			itemDom = @_itemDomMap[@_currentNode._id]
			$fly(itemDom).removeClass("current") if itemDom

		@_currentNode = node

		if @_currentItemAlias
			@_scope.set(@_currentItemAlias, node?._data)

		if node
			itemDom = @_itemDomMap[node._id]
			if itemDom and @_highlightCurrentItem
				$fly(itemDom).addClass("current")

		@fire("currentNodeChange", @, eventArg)
		return

	_getItemType: (node) ->
		if node?.isDataWrapper
			itemType = node._data?._itemType
		else
			itemType = node._itemType

		if not itemType and node._bind._checkedProperty
			itemType = "checkable"
		return itemType or "default"

	_createNewItem: (itemType, node) ->
		template = @getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("tree item " + itemType)
		itemDom._itemType = itemType

		nodeDom = itemDom.firstChild
		if nodeDom and cola.util.hasClass(nodeDom, "node")
			template = @getTemplate("node-" + itemType, "node")
			if template
#				if template instanceof Array
#					span = document.createElement("span")
#					span.appendChild(templ) for templ in template
#					template = span
#					@regTemplate("node-" + itemType, template)
				contentDom = @_cloneTemplate(template)
				$fly(contentDom).addClass("node-content")
				nodeDom.appendChild(contentDom)
		return itemDom

	_getDefaultBindPath: (node) ->
		textProperty = node._bind._textProperty
		if textProperty
			return (node._alias) + "." + textProperty

	_refreshItemDom: (itemDom, node, parentScope) ->
		nodeScope = cola.util.userData(itemDom, "scope")
		# TODO 尝试修复新增节点数据时父节点自动收缩的bug
		if nodeScope and nodeScope.data.getTargetData() isnt node.get("data")
			collapsed = true

		nodeScope = super(itemDom, node, parentScope)
		node._scope = nodeScope

		if not itemDom._binded
			itemDom._binded = true
			if itemDom._itemType == "checkable"
				checkboxDom = itemDom.querySelector(".node-checkbox")
				if checkboxDom
					tree = @
					checkbox = cola.widget(checkboxDom)
					# TODO 尝试修复Checkbox 默认第三态的bug
					dataPath = nodeScope.data.alias + "." + node._bind._checkedProperty
					checkedPropValue = nodeScope.get(dataPath)
					if typeof checkedPropValue == "undefined"
						nodeScope.set(dataPath, false)
					checkbox.set(
						bind: dataPath
						click: () -> tree._onCheckboxClick(node)
					)

		if not @_currentNode
			@_setCurrentNode(node)
		else if node is @_currentNode and @_highlightCurrentItem
			$fly(itemDom).addClass("current")

		if not collapsed and node.get("expanded")
			if node._hasExpanded
				@_refreshChildNodes(itemDom, node)
			else
				@expand(node)
		else
			if node._hasExpanded
				if collapsed then @collapse(node, true)
			else if not @_lazyRenderChildNodes
				@_prepareChildNode(node, false)

			nodeDom = itemDom.firstChild
			$fly(nodeDom).toggleClass("leaf", node.get("hasChild") == false)

		return nodeScope

	_refreshChildNodes: (parentItemDom, parentNode, hidden) ->
		nodesWrapper = parentItemDom.lastChild
		if not $fly(nodesWrapper).hasClass("child-nodes")
			nodesWrapper = $.xCreate(
				tagName: "ul"
				class: "child-nodes"
				style:
					display: if hidden then "hidden" else ""
					padding: 0
					margin: 0
					overflow: "hidden"
			)
			parentItemDom.appendChild(nodesWrapper)

		itemsScope = parentNode._itemsScope
		itemsScope.resetItemScopeMap()

		documentFragment = null
		currentItemDom = nodesWrapper.firstChild
		if parentNode._children
			for node in parentNode._children
				itemType = @_getItemType(node)

				if currentItemDom
					while currentItemDom
						if currentItemDom._itemType == itemType
							break
						else
							nextItemDom = currentItemDom.nextSibling
							nodesWrapper.removeChild(currentItemDom)
							currentItemDom = nextItemDom
					itemDom = currentItemDom
					if currentItemDom
						currentItemDom = currentItemDom.nextSibling
				else
					itemDom = null

				if itemDom
					@_refreshItemDom(itemDom, node, itemsScope)
				else
					itemDom = @_createNewItem(itemType, node)
					@_refreshItemDom(itemDom, node, itemsScope)
					documentFragment ?= document.createDocumentFragment()
					documentFragment.appendChild(itemDom)

		if currentItemDom
			itemDom = currentItemDom
			while itemDom
				nextItemDom = itemDom.nextSibling
				nodesWrapper.removeChild(itemDom) if $fly(itemDom).hasClass("item")
				itemDom = nextItemDom

		if documentFragment
			nodesWrapper.appendChild(documentFragment)
		return

	_onItemClick: (evt) ->
		itemDom = evt.currentTarget
		return unless itemDom

		node = cola.util.userData(itemDom, "item")
		@_setCurrentNode(node)
		return super(evt)

	_expandButtonClick: (evt)->
		buttonDom = evt.currentTarget
		return unless buttonDom

		itemDom = @_findItemDom(buttonDom)
		return unless itemDom

		node = cola.util.userData(itemDom, "item")
		return unless node

		node.set("expanded", not node.get("expanded"))

		evt.stopPropagation()
		return false

	findNode: (entity)->
		itemId = cola.Entity._getEntityId(entity)
		return unless itemId

		itemDom = @_itemDomMap[itemId]
		return if itemDom then  cola.util.userData(itemDom, "item") else null

	_prepareChildNode: (node, expand, noAnimation, callback) ->
		itemDom = @_itemDomMap[node._id]
		return unless itemDom

		tree = @
		itemsScope = node._itemsScope
		if not itemsScope
			node._itemsScope = itemsScope = new cola.ItemsScope(node._scope)
			itemsScope.alias = node._alias
			itemsScope._retrieveItems = (dataCtx) -> node._bind.retrieveChildNodes(node, null, dataCtx)
			itemsScope.onItemsRefresh = () ->
				itemDom = tree._itemDomMap[node._id]
				tree._refreshChildNodes(itemDom, node) if itemDom
				return
			itemsScope.onItemInsert = () -> @onItemsRefresh()
			itemsScope.onItemRemove = (arg) -> tree._onItemRemove(arg)

		nodeDom = itemDom.firstChild
		$fly(nodeDom).addClass("expanding") if expand
		node._bind.retrieveChildNodes(node, () ->
			$fly(nodeDom).removeClass("expanding") if expand
			if node._children
				tree._refreshChildNodes(itemDom, node, true)
				$fly(nodeDom).addClass("expanded") if expand

				$nodesWrapper = $fly(itemDom.lastChild)
				if expand and $nodesWrapper.hasClass("child-nodes")
					if noAnimation
						$nodesWrapper.show()
					else
						$nodesWrapper.slideDown(150)
			else
				$fly(nodeDom).addClass("leaf")
			node._expanded = true if expand
			node._hasExpanded = true

			callback?.call(tree)
			return
		)
		return

	expand: (node, noAnimation = true) ->
		@_prepareChildNode(node, true, noAnimation, () =>
			if @_autoCollapse and node._parent?._children
				for brotherNode in node._parent._children
					if brotherNode isnt node and brotherNode.get("expanded")
						@collapse(brotherNode)
		)
		return

	collapse: (node, noAnimation = true) ->
		itemDom = @_itemDomMap[node._id]
		return unless itemDom

		if @_currentNode
			parent = @_currentNode._parent
			while parent
				if parent == node
					@_setCurrentNode(node)
					break
				parent = parent._parent

		$fly(itemDom.firstChild).removeClass("expanded")
		$nodesWrapper = $fly(itemDom.lastChild)
		if $nodesWrapper.hasClass("child-nodes")
			if noAnimation
				$nodesWrapper.hide()
			else
				$nodesWrapper.slideUp(150)

		node._expanded = false
		return

	_refreshItems: () ->
		if @_currentNode
			itemDom = @_itemDomMap[@_currentNode._id]
			delete @_currentNode
			$fly(itemDom).removeClass("current") if itemDom
		return super()

	_removeNode: (node) ->
		if node
			if @_currentNode.data == node.data
				children = node._parent._children
				i = children.indexOf(node)
				if i < children.length - 1
					newCurrentNode = children[i + 1]
				else if i > 0
					newCurrentNode = children[i - 1]
				else if node._parent != @_rootNode
					newCurrentNode = node._parent
				@_setCurrentNode(newCurrentNode) if newCurrentNode

			itemDom = @_itemDomMap[node._id]
			if itemDom then $fly(itemDom).remove()

			node.remove()
		return

	_onCurrentItemChange: null

	_resetNodeAutoCheckedState: (node) ->
		if node._bind._checkedProperty and node._bind._autoCheckChildren
			if not @_autoChecking then @_autoCheckingParent = true;
			if @_autoCheckingParent
				@_autoCheckingChildren = false
				checkedCount = 0
				checkableCount = 0
				halfCheck = false
				for child in node._children
					if child._bind._checkedProperty
						checkableCount++
						c = child.get("checked")
						if c == true
							checkedCount++
						else if c == null
							halfCheck = true

				if checkableCount
					@_autoChecking = true
					c = undefined
					if not halfCheck
						if checkedCount == 0
							c = false
						else if checkedCount == checkableCount
							c = true
					node.set("checked", c)
					@_nodeCheckedChanged(node, false, true)
					@_autoChecking = false
		return

	_nodeCheckedChanged: (node, processChildren, processParent) ->
		if processChildren and node._children and node._bind._autoCheckChildren
			if not @_autoChecking then @_autoCheckingChildren = true
			if @_autoCheckingChildren
				@_autoCheckingParent = false
				@_autoChecking = true
				checked = node.get("checked")
				for child in node._children
					if child._bind._checkedProperty
						oldChecked = child.get("checked")
						if oldChecked != checked
							child.set("checked", checked)
							@_nodeCheckedChanged(child, true, false)
				@_autoChecking = false

		if processParent and node._parent
			@_resetNodeAutoCheckedState(node._parent)
		return

	_onCheckboxClick: (node) ->
		@_nodeCheckedChanged(node, true, true)
		return

	getCheckedNodes: () ->
		nodes = []

		collectCheckNodes: (node) ->
			if node._bind._checkedProperty and node.get("checked")
				nodes.push(node)
			if node._children
				for child in node._children
					collectCheckNodes(child)
			return

		if @_rootNode
			for child in @_rootNode._children
				collectCheckNodes(child)
		return nodes

cola.Element.mixin(cola.Tree, cola.TreeSupportMixin)

cola.registerWidget(cola.Tree)