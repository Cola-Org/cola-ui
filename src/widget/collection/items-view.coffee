

_getEntityId = cola.Entity._getEntityId

class cola.ItemsView extends cola.Widget
	@ATTRIBUTES:
		allowNoCurrent:
			type:"boolean"
			defaultValue: true
		currentItem:
			getter: () ->
				if @_currentItemDom
					item = cola.util.userData(@_currentItemDom, "item")
				return item
			setter: (currentItem) ->
				if currentItem
					currentItemDom = @_itemDomMap[_getEntityId(currentItem)]
				@_setCurrentItemDom(currentItemDom)
				return

		highlightCurrentItem:
			type: "boolean"

	@EVENTS:
		getItemTemplate: null
		renderItem: null
		itemClick: null
		itemDoubleClick: null
		itemPress: null

	_doSet: (attr, attrConfig, value) ->
		if attrConfig?.refreshItems
			attrConfig.refreshDom = true
			@_refreshItemsScheduled = true
		return super(attr, attrConfig, value)

	_createDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			content:
				tagName: "ul"
				contextKey: "itemsWrapper"
		}, @_doms)
		return dom

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}
		child = dom.firstChild
		while child
			next = child.nextSibling
			nodeName = child.nodeName
			if !itemsWrapper and nodeName == "UL"
				itemsWrapper = child
			else if nodeName == "TEMPLATE"
				@_regTemplate(child)
			else
				dom.removeChild(child)
			child = next

		if !itemsWrapper
			itemsWrapper = document.createElement("ul")
			dom.appendChild(itemsWrapper)
		@_doms.itemsWrapper = itemsWrapper
		return

	_initDom: (dom) ->
		@_regDefaultTempaltes()
		@_templateContext ?= {}

		$itemsWrapper = $fly(@_doms.itemsWrapper)
		$itemsWrapper.addClass("items")
		.delegate(".item", "click", (evt) => @_onItemClick(evt))
		.delegate(".item", "dblclick", (evt) => @_onItemDoubleClick(evt))

		if @_onItemsWrapperScroll
			$itemsWrapper.on("scroll", (evt) =>
				@_onItemsWrapperScroll(evt)
				return true
			)

		@_$dom = $(dom)
		return

	getItems: () ->
		return @_realItems

	_doRefreshDom: ()->
		return unless @_dom
		super()
		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_refreshItems()
		return

	_getItemType: (item) ->
		type = @fire("getItemTemplate", @, { item: item })
		return type if type

		if item?.isDataWrapper
			return item._data?._itemType or "default"
		else
			return item._itemType or "default"

	_onItemsRefresh: () ->
		return @_refreshItems()

	_onItemInsert: (arg) ->
		if @_realItems == @_realOriginItems
			@_refreshEmptyItemDom()

			item = arg.entity
			itemType = @_getItemType(item)
			itemsWrapper = @_doms.itemsWrapper
			insertMode = arg.insertMode
			if !insertMode or insertMode == "end"
				itemDom = @_createNewItem(itemType, item)
				@_refreshItemDom(itemDom, item)
				$fly(itemsWrapper).append(itemDom)
			else if insertMode == "begin"
				itemDom = @_createNewItem(itemType, item)
				@_refreshItemDom(itemDom, item)
				$fly(itemsWrapper.firstChild).before(itemDom)
			else if @_itemDomMap
				refEntityId = _getEntityId(arg.refEntity)
				if refEntityId
					refDom = @_itemDomMap[refEntityId]?
					if refDom
						itemDom = @_createNewItem(itemType, item)
						@_refreshItemDom(itemDom, item)
						if insertMode == "before"
							$fly(refDom).before(itemDom)
						else
							$fly(refDom).after(itemDom)
		else
			@_refreshItems()
		return

	_onItemRemove: (arg) ->
		itemId = _getEntityId(arg.entity)
		if itemId
			arg.itemsScope.unregItemScope(itemId)

			itemDom = @_itemDomMap[itemId]
			delete @_itemDomMap[itemId]
			if itemDom
				$fly(itemDom).remove()
				@_currentItemDom = null if itemDom == @_currentItemDom

		@_refreshEmptyItemDom()
		return

	_showLoadingTip: () ->
		$loaderContainer = @_$loaderContainer
		if not $loaderContainer
			$itemsWrapper = $fly(@_doms.itemsWrapper)
			$itemsWrapper.xAppend(
				class: "loader-container protected"
				content:
					class: "ui loader"
			)
			@_$loaderContainer = $loaderContainer = $itemsWrapper.find(">.loader-container");
		else
			$loaderContainer.remove()
			$loaderContainer.appendTo(@_doms.itemsWrapper)

		$loaderContainer.addClass("active")
		return

	_hideLoadingTip: () ->
		@_$loaderContainer?.removeClass("active")
		return

	_onItemsLoadingStart: (arg) ->
		@_showLoadingTip()
		return

	_onItemsLoadingEnd: (arg) ->
		@_hideLoadingTip()
		return

	_setCurrentItemDom: (currentItemDom) ->
		if @_currentItemDom
			$fly(@_currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS)
		@_currentItemDom = currentItemDom
		if currentItemDom and @_highlightCurrentItem
			$fly(currentItemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)
		return

	_onCurrentItemChange: (arg) ->
		if arg.current and @_itemDomMap
			itemId = _getEntityId(arg.current)
			if itemId
				currentItemDom = @_itemDomMap[itemId]
				if not currentItemDom
					@_refreshItems()
					return
		@_setCurrentItemDom(currentItemDom)
		return

	_refreshItems: () ->
		if !@_dom
			@_refreshItemsScheduled = true
			return
		@_doRefreshItems(@_doms.itemsWrapper)

	_doRefreshItems: (itemsWrapper) ->
		@_itemDomMap ?= {}

		ret = @_getItems()
		items = ret.items
		#		isSameItems = (@_realOriginItems or @_realItems) is (ret.originItems or items)
		@_realOriginItems = ret.originItems

		if @_convertItems and items
			items = @_convertItems(items)
		@_realItems = items

		if items
			documentFragment = null
			nextItemDom = itemsWrapper.firstChild
			currentItem = items.current

			if @_currentItemDom
				if !currentItem
					currentItem = cola.util.userData(@_currentItemDom, "item")
				$fly(@_currentItemDom).removeClass(cola.constants.COLLECTION_CURRENT_CLASS)
				delete @_currentItemDom
			@_currentItem = currentItem

			@_itemsScope.resetItemScopeMap()

			@_refreshEmptyItemDom?()

			lastItem = null
			cola.each(items, (item) =>
				lastItem = item
				itemType = @_getItemType(item)

				if nextItemDom
					while nextItemDom
						if nextItemDom._itemType == itemType
							break
						else
							_nextItemDom = nextItemDom.nextSibling
							if not cola.util.hasClass(nextItemDom, "protected")
								itemsWrapper.removeChild(nextItemDom)
							nextItemDom = _nextItemDom
					itemDom = nextItemDom
					if nextItemDom
						nextItemDom = nextItemDom.nextSibling
				else
					itemDom = null

				if itemDom
					@_refreshItemDom(itemDom, item)
				else
					itemDom = @_createNewItem(itemType, item)
					@_refreshItemDom(itemDom, item)
					documentFragment ?= document.createDocumentFragment()
					documentFragment.appendChild(itemDom)
				return
			, { currentPage: @_currentPageOnly })

			if nextItemDom
				itemDom = nextItemDom
				while itemDom
					nextItemDom = itemDom.nextSibling
					if not cola.util.hasClass(itemDom, "protected")
						itemsWrapper.removeChild(itemDom)
						delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
					itemDom = nextItemDom

			delete @_currentItem
			if @_currentItemDom and @_highlightCurrentItem
				$fly(@_currentItemDom).addClass(cola.constants.COLLECTION_CURRENT_CLASS)

			if documentFragment
				itemsWrapper.appendChild(documentFragment)

			if not @_currentPageOnly and @_autoLoadPage and (items is @_realOriginItems or not @_realOriginItems) and items instanceof cola.EntityList and items.pageSize > 0
				currentPageNo = lastItem?._page?.pageNo
				if currentPageNo and (currentPageNo < items.pageCount or not items.pageCountDetermined)
					if not @_loadingNextPage and itemsWrapper.scrollHeight == itemsWrapper.clientHeight and itemsWrapper.scrollTop = 0
						@_showLoadingTip()
						items.loadPage(currentPageNo + 1, () =>
							@_hideLoadingTip()
							return
						)
					else
						$fly(itemsWrapper).xAppend(
							class: "tail-padding"
							content:
								class: "ui loader"
						)
		return


	_refreshItemDom: (itemDom, item, parentScope = @_itemsScope) ->
		if item == @_currentItem
			@_currentItemDom = itemDom
		else if !@_currentItemDom and !@_allowNoCurrent
			@_currentItemDom = itemDom

		if item?.isDataWrapper
			originItem = item
			item = item._data
		else
			originItem = item

		if typeof item == "object"
			itemId = _getEntityId(item)

		alias = item._alias
		if !alias
			alias = originItem?._alias
			alias ?= @_alias
		@_templateContext.defaultPath = @_getDefaultBindPath?(originItem) or alias

		itemScope = cola.util.userData(itemDom, "scope")
		oldScope = cola.currentScope
		try
			if !itemScope
				itemScope = new cola.ItemScope(parentScope, alias)
				cola.currentScope = itemScope
				itemScope.data.setTargetData(item, true)
				cola.util.userData(itemDom, "scope", itemScope)
				cola.util.userData(itemDom, "item", originItem)
				@_doRefreshItemDom?(itemDom, item, itemScope)
				cola.xRender(itemDom, itemScope, @_templateContext)
			else
				cola.currentScope = itemScope
				if itemScope.data.getTargetData() != item
					delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
					if itemScope.data.alias != alias
						throw new cola.Exception("Repeat alias mismatch. Expect \"#{itemScope.alias}\" but \"#{alias}\".")
					cola.util.userData(itemDom, "item", originItem)
					itemScope.data.setTargetData(item)
				@_doRefreshItemDom?(itemDom, item, itemScope)
			parentScope.regItemScope(itemId, itemScope) if itemId

			if @getListeners("renderItem")
				@fire("renderItem", @, {
					item: originItem
					dom: itemDom
					scope: itemScope
				})
		finally
			cola.currentScope = oldScope

		if itemId
			itemDom._itemId = itemId
			@_itemDomMap[itemId] = itemDom
		return itemScope

	refreshItem: (item) ->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_doRefreshItemDom?(itemDom, item, @_itemsScope)
		return

	_onItemRefresh: (arg) ->
		item = arg.entity
		if typeof item == "object"
			@refreshItem(item)
		return

	_findItemDom: (target) ->
		while target
			if target._itemType
				itemDom = target
				break
			target = target.parentNode
		return itemDom

	_onItemClick: (evt) ->
		itemDom = evt.currentTarget
		return unless itemDom

		item = cola.util.userData(itemDom, "item")
		if itemDom._itemType == "default"
			if item
				if @_changeCurrentItem and item._parent instanceof cola.EntityList
					item._parent.setCurrent(item)
				else
					@_setCurrentItemDom(itemDom)

		@fire("itemClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_onItemDoubleClick: (evt) ->
		itemDom = evt.currentTarget
		return unless itemDom
		item = cola.util.userData(itemDom, "item")
		@fire("itemDoubleClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_bindEvent: (eventName) ->
		if eventName == "itemPress"
			@_on("press", (self, arg) =>
				itemDom = @_findItemDom(arg.event.target)
				if itemDom
					arg.itemDom = itemDom
					arg.item = cola.util.userData(itemDom, "item")
					@fire("itemPress", list, arg)
				return
			)
			return
		else
			return super(eventName)

cola.Element.mixin(cola.ItemsView, cola.TemplateSupport)
cola.Element.mixin(cola.ItemsView, cola.DataItemsWidgetMixin)