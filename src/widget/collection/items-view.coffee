_getEntityId = cola.Entity._getEntityId

class cola.ItemsView extends cola.Widget

	@attributes:
		allowNoCurrent:
			type: "boolean"
			defaultValue: true
		currentItem:
			getter: ()->
				if @_currentItemDom
					item = cola.util.userData(@_currentItemDom, "item")
				return item
			setter: (currentItem)->
				if currentItem
					currentItemDom = @_itemDomMap[_getEntityId(currentItem)]
				@_setCurrentItemDom(currentItemDom)
				return

		currentPageOnly: null

		highlightCurrentItem:
			type: "boolean"
			defaultValue: true

		focusable:
			defaultValue: true
		transition:
			type: "boolean"

	@events:
		getItemTemplate: null
		renderItem: null
		itemClick: null
		itemDoubleClick: null
		itemPress: null

	_doSet: (attr, attrConfig, value)->
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
		child = dom.firstElementChild
		while child
			next = child.nextElementSibling
			nodeName = child.nodeName
			if not itemsWrapper and nodeName is "UL"
				itemsWrapper = child
			else if nodeName == "TEMPLATE"
				@regTemplate(child)
			else
				dom.removeChild(child)
			child = next

		if not itemsWrapper
			itemsWrapper = document.createElement("ul")
			dom.appendChild(itemsWrapper)
		@_doms.itemsWrapper = itemsWrapper
		return

	_initDom: (dom)->
		@_regDefaultTemplates()
		@_templateContext ?= {}

		$itemsWrapper = $fly(@_doms.itemsWrapper)
		$itemsWrapper.addClass("items")
			.delegate(".item", "click", (evt)=> @_onItemClick(evt))
			.delegate(".item", "dblclick", (evt)=> @_onItemDoubleClick(evt))

		if @_onItemsWrapperScroll
			$itemsWrapper.on("scroll", (evt)=>
				@_onItemsWrapperScroll(evt)
				return true
			)

		if @_focusable then @get$Dom().attr("tabIndex", 1).on("keydown", (evt)=> @_onKeyDown(evt))
		return

	getItems: ()->
		return @_realItems

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.toggle("highlight-current", @_highlightCurrentItem)
		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_refreshItems()
		return

	_getItemType: (item)->
		type = @fire("getItemTemplate", @, {item: item})
		return type if type

		if item?.isDataWrapper
			return item._data?._itemType or "default"
		else
			return item._itemType or "default"

	_onItemsRefresh: ()->
		return @_refreshItems()

	_onItemInsert: (arg)->
		if @_realItems is arg.entityList
			@_refreshEmptyItemDom()

			item = arg.entity
			itemsScope = arg.itemsScope
			itemType = @_getItemType(item)
			itemsWrapper = @_doms.itemsWrapper
			insertMode = arg.insertMode

			insertMode = arg.insertMode
			if not insertMode or insertMode is "end"
				index = arg.entityList.entityCount
			else if insertMode is "begin"
				index = 1
			else if insertMode is "before"
				refItemScope = itemsScope.getItemScope(arg.refEntity)
				index = refItemScope?.data.getIndex()
			else if insertMode is "after"
				refItemScope = itemsScope.getItemScope(arg.refEntity)
				index = refItemScope?.data.getIndex() + 1

			if not insertMode or insertMode is "end" or not itemsWrapper.firstChild
				itemDom = @_createNewItem(itemType, item)
				$itemDom = $(itemDom).addClass(cola.constants.REPEAT_ITEM_OUT_CLASS)
				@_refreshItemDom(itemDom, item, null, index)
				$fly(itemsWrapper).append(itemDom)
			else if insertMode is "begin"
				itemDom = @_createNewItem(itemType, item)
				$itemDom = $(itemDom).addClass(cola.constants.REPEAT_ITEM_OUT_CLASS)
				@_refreshItemDom(itemDom, item, null, index)
				$fly(itemsWrapper.firstChild).before(itemDom)
			else if @_itemDomMap
				refEntityId = _getEntityId(arg.refEntity)
				if refEntityId
					refDom = @_itemDomMap[refEntityId]?
					if refDom
						itemDom = @_createNewItem(itemType, item)
						$itemDom = $(itemDom).addClass(cola.constants.REPEAT_ITEM_OUT_CLASS)
						@_refreshItemDom(itemDom, item, null, index)
						if insertMode is "before"
							$fly(refDom).before(itemDom)
						else
							$fly(refDom).after(itemDom)

			if itemDom and @_transition
				setTimeout(()->
					$itemDom.removeClass(cola.constants.REPEAT_ITEM_OUT_CLASS)
					return
				, 50);

			if insertMode isnt "end"
				for id, iScope of itemsScope.itemScopeMap
					i = iScope.data.getIndex()
					if i >= index and iScope.data.getItemData() isnt entity
						iScope.data.setIndex(i + 1)
		else
			@_itemsRetrieved = false
			@_refreshItems()
		return

	_onItemRemove: (arg)->
		itemId = _getEntityId(arg.entity)
		if itemId
			itemDom = @_itemDomMap[itemId]
			delete @_itemDomMap[itemId]
			if itemDom
				$itemDom = $(itemDom)
				if @_transition
					$itemDom.attr(cola.constants.REPEAT_ITEM_REMOVED_KEY, true)
						.one("transitionend", ()->$itemDom.remove())
						.addClass(cola.constants.REPEAT_ITEM_OUT_CLASS)
				else
					$itemDom.remove()
				@_currentItemDom = null if itemDom is @_currentItemDom

			if arg.scope
				index = arg.scope.data.getIndex?()
				if index <= arg.entityList.entityCount
					for id, iScope of itemsScope.itemScopeMap
						i = iScope.data.getIndex?()
						if i > index then iScope.data.setIndex(i - 1)

		@_refreshEmptyItemDom()
		return

	_showLoadingTip: ()->
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

	_hideLoadingTip: ()->
		@_$loaderContainer?.removeClass("active")
		return

	_doItemsLoadingStart: (arg)->
		@_showLoadingTip()
		return

	_doItemsLoadingEnd: (arg)->
		@_hideLoadingTip()
		return

	_setCurrentItemDom: (currentItemDom)->
		if @_currentItemDom
			$fly(@_currentItemDom).removeClass(cola.constants.REPEAT_ITEM_CURRENT_CLASS)
		@_currentItemDom = currentItemDom
		if currentItemDom
			$fly(currentItemDom).addClass(cola.constants.REPEAT_ITEM_CURRENT_CLASS)
		return

	_getFirstItemDom: ()->
		itemDom = @_doms.itemsWrapper.firstElementChild
		while itemDom
			if itemDom._itemType then return itemDom
			itemDom = itemDom.nextElementSibling
		return

	_getLastItemDom: ()->
		itemDom = @_doms.itemsWrapper.lastChild
		while itemDom
			if itemDom._itemType then return itemDom
			itemDom = itemDom.previousSibling
		return

	_getPreviousItemDom: (itemDom)->
		while itemDom
			itemDom = itemDom.previousSibling
			if itemDom?._itemType then return itemDom
		return

	_getNextItemDom: (itemDom)->
		while itemDom
			itemDom = itemDom.nextElementSibling
			if itemDom?._itemType then return itemDom
		return

	_onCurrentItemChange: (arg)->
		if arg.current and @_itemDomMap
			itemId = _getEntityId(arg.current)
			if itemId
				currentItemDom = @_itemDomMap[itemId]
				if not currentItemDom
					@_refreshItems()
					return
		@_setCurrentItemDom(currentItemDom)
		return

	refreshItems: ()-> @_refreshItems()

	_refreshItems: ()->
		if not @_dom
			@_refreshItemsScheduled = true
			return

		return if @_duringRefreshItems
		@_duringRefreshItems = true
		@_doRefreshItems(@_doms.itemsWrapper)
		delete @_duringRefreshItems
		return

	_doRefreshItems: (itemsWrapper)->
		@_itemDomMap ?= {}

		ret = @_getItems()
		items = ret.items
		@_realItems = items
		@_realOriginItems = ret.originItems

		documentFragment = null
		nextItemDom = itemsWrapper.firstElementChild
		currentItem = items?.current

		if @_currentItemDom
			if not currentItem
				currentItem = cola.util.userData(@_currentItemDom, "item")
			$fly(@_currentItemDom).removeClass(cola.constants.REPEAT_ITEM_CURRENT_CLASS)
			delete @_currentItemDom
		@_currentItem = currentItem

		@_refreshEmptyItemDom?()

		lastItem = null
		if items
			cola.each(items, (item, i)=>
				lastItem = item
				itemType = @_getItemType(item)

				if nextItemDom
					while nextItemDom
						if nextItemDom._itemType is itemType and
						  not nextItemDom.getAttribute?(cola.constants.REPEAT_ITEM_REMOVED_KEY)
							break
						else
							_nextItemDom = nextItemDom.nextElementSibling
							if not cola.util.hasClass(nextItemDom, "protected")
								itemsWrapper.removeChild(nextItemDom)
							nextItemDom = _nextItemDom
					itemDom = nextItemDom
					if nextItemDom
						nextItemDom = nextItemDom.nextElementSibling
				else
					itemDom = null

				if itemDom
					@_refreshItemDom(itemDom, item, null, i + 1)
				else
					itemDom = @_createNewItem(itemType, item)
					@_refreshItemDom(itemDom, item, null, i + 1)
					documentFragment ?= document.createDocumentFragment()
					documentFragment.appendChild(itemDom)
				return
			, {currentPage: @_currentPageOnly})

		if nextItemDom
			itemDom = nextItemDom
			while itemDom
				nextItemDom = itemDom.nextElementSibling
				if not cola.util.hasClass(itemDom, "protected")
					itemsWrapper.removeChild(itemDom)
					delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
				itemDom = nextItemDom

		delete @_currentItem
		if @_currentItemDom
			$fly(@_currentItemDom).addClass(cola.constants.REPEAT_ITEM_CURRENT_CLASS)

		if documentFragment
			itemsWrapper.appendChild(documentFragment)

		if not @_currentPageOnly and @_autoLoadPage and (items is @_realOriginItems or not @_realOriginItems) and items instanceof cola.EntityList and items.pageSize > 0
			currentPageNo = lastItem?._page?.pageNo
			if currentPageNo and (currentPageNo < items.pageCount or not items.pageCountDetermined)
				if not @_loadingNextPage and itemsWrapper.scrollHeight is itemsWrapper.clientHeight and itemsWrapper.scrollTop is 0
					@_showLoadingTip()
					items.loadPage(currentPageNo + 1, ()=>
						@_hideLoadingTip()
						return
					)
				else
					@_appendTailDom?(itemsWrapper)
		return

	_getItemScope: (parentScope, alias, item)->
		itemScope = new cola.ItemScope(parentScope, alias)
		cola.currentScope = itemScope
		itemScope.data.setItemData(item, true)
		return itemScope

	_refreshItemDom: (itemDom, item, parentScope = @_itemsScope, index)->
		if item is @_currentItem
			@_currentItemDom = itemDom
		else if not @_currentItemDom and not @_allowNoCurrent
			@_currentItemDom = itemDom

		if item?.isDataWrapper
			originItem = item
			alias = originItem._alias
			item = item._data
		else
			originItem = item
			alias = item?._alias

		if typeof item is "object"
			itemId = _getEntityId(item)

		if not alias
			alias = originItem?._alias
			alias ?= @_alias
		@_templateContext.defaultPath = @_getDefaultBindPath?(originItem) or alias

		itemScope = cola.util.userData(itemDom, "scope")
		oldScope = cola.currentScope

		if not itemScope
			itemScope = @_getItemScope(parentScope, alias, item)
			itemScope.data.setIndex(index, true)
			cola.util.userData(itemDom, "scope", itemScope)
			cola.util.userData(itemDom, "item", originItem)
			@_doRefreshItemDom?(itemDom, item, itemScope)
			cola.xRender(itemDom, itemScope, @_templateContext)
		else
			cola.currentScope = itemScope
			if itemScope.data.getItemData() isnt item
				if itemDom._itemId and @_itemDomMap[itemDom._itemId] is itemDom
					delete @_itemDomMap[itemDom._itemId]

				if itemScope.data.alias isnt alias
					throw new cola.Exception("Repeat alias mismatch. Expect \"#{itemScope.alias}\" but \"#{alias}\".")

				cola.util.userData(itemDom, "item", originItem)
				itemScope.data.setItemData(item)
				itemScope.data.setIndex(index, true)

			@_doRefreshItemDom?(itemDom, item, itemScope)

		if @getListeners("renderItem")
			@fire("renderItem", @, {
				item: originItem
				dom: itemDom
				scope: itemScope
			})
		cola.currentScope = oldScope

		if itemId
			itemDom._itemId = itemId
			@_itemDomMap[itemId] = itemDom
		return itemScope

	refreshItem: (item)->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_refreshItemDom(itemDom, item, @_itemsScope)
		return

	_onItemRefresh: (arg)->
		item = arg.entity
		if typeof item is "object"
			@refreshItem(item)
		return

	getItemByItemDom: (itemDom)->
		return null unless itemDom
		return cola.util.userData(itemDom, "item")

	_findItemDom: (target)->
		while target
			if target._itemType
				itemDom = target
				break
			target = target.parentNode
		return itemDom

	_onKeyDown: (evt)->
		switch evt.keyCode
			when 38 # up
				if @_currentItemDom
					itemDom = @_getPreviousItemDom(@_currentItemDom)
				else
					itemDom = @_getFirstItemDom()
				@_setCurrentItemDom(itemDom) if itemDom
				return false
			when 40 # down
				if @_currentItemDom
					itemDom = @_getNextItemDom(@_currentItemDom)
				else
					itemDom = @_getFirstItemDom()
				@_setCurrentItemDom(itemDom) if itemDom
				return false

	_onItemClick: (evt)->
		itemDom = evt.currentTarget
		return unless itemDom

		item = cola.util.userData(itemDom, "item")
		if item
			if @_changeCurrentItem and item.parent instanceof cola.EntityList
				item.parent.setCurrent(item)
			else
				@_setCurrentItemDom(itemDom)

		@fire("itemClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_onItemDoubleClick: (evt)->
		itemDom = evt.currentTarget
		return unless itemDom
		item = cola.util.userData(itemDom, "item")
		@fire("itemDoubleClick", @, {
			event: evt
			item: item
			dom: itemDom
		})
		return

	_bindEvent: (eventName)->
		if eventName == "itemPress"
			@_on("press", (self, arg)=>
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