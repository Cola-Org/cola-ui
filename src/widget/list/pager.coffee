# TODO

_pagesItems = ["firstPage", "prevPage", "info", "nextPage", "lastPage"]
_pageCodeMap =
	"|<": "firstPage"
	"<": "prevPage"
	">": "nextPage"
	">|": "lastPage"

class cola.Pager extends cola.Menu
	@tagName: "c-pager"
	@CLASS_NAME: "ui menu pager secondary"
	@attributes:
		bind:
			setter: (bindStr) -> @_bindSetter(bindStr)

	_getBindItems: ()-> @_getItems()?.items
	constructor: (config) ->
		@_pagerItemMap = {}
		pager = @
		#暂使用此方法获得总页数
		_getPageCount = ()->
			data = pager._getBindItems()
			return parseInt((data.totalEntityCount + data.pageSize - 1) / data.pageSize)
		@_pagerItemConfig =
			firstPage:
				icon: "angle double left"
				class: "page-item"
				click: ()-> pager._getBindItems()?.firstPage()

			prevPage:
				icon: "angle left"
				class: "page-item"
				click: ()->
					data = pager._getBindItems()
					data?.previousPage()
			pageSize:
				$type: "input"
				class: "page-item page-size"
				inputType: "number",
				initDom: (self, arg)->
					self.get$Dom().find("input").attr("min", 0)
					return
				keyDown: (self, arg)->
					k = arg.keyCode
					if k is 190 then event.preventDefault()

				change: (self, arg)->
					value = arg.value
					collection = pager._getBindItems()
					if collection
						if value then value = parseInt(value)
						if value is collection.pageSize then return
						if collection instanceof cola.EntityList
							collection.pageSize = value
							cola.util.flush(collection)
			goto:
				$type: "input"
				class: "goto"

				inputType: "number",
				initDom: (self, arg)->
					self.get$Dom().find("input").attr("min", 0)
					return

				keyDown: (self, arg)->
					k = arg.keyCode
					if k is 190 then event.preventDefault()

				change: (self, arg)->
					value = arg.value
					if value then value = parseInt(value)
					if value is @_targetPageNo then return
					data = pager._getBindItems()
					if data
						pageNo = data.pageNo
						pageCount = _getPageCount()

						if value > pageCount or value < 1
							if value > pageCount then value = pageCount
							if value < 1 then value = 1
							setTimeout(()->
								self.get$Dom().find("input").val(value)
							, 10)
						button = self.get("actionButton")
						setTimeout(()->
							button.set("disabled", value is pageNo)
						, 100)
						pager._targetPageNo = value

				actionButton:
					$type: "Button"
					caption: "Go"
					click: ()->
						if pager._targetPageNo
							data = pager._getBindItems()
							data?.gotoPage(pager._targetPageNo)

			nextPage:
				icon: "angle right"
				class: "page-item"
				click: ()->
					data = pager._getBindItems()
					data?.nextPage()
			lastPage:
				icon: "angle double right"
				class: "page-item"
				click: ()->
					data = pager._getBindItems()
					data?.lastPage()

		super(config)
	_parseDom: (dom)->
		super(dom)
		hasPageItem = false
		for name in _pagesItems

			if @_pagerItemMap[name]
				hasPageItem = true
				break
		unless hasPageItem
			@addItem("pages")
		@_items ?= []



	_parsePageItem: (childNode, right)->
		pageCode = $fly(childNode).attr("page-code")
		unless pageCode then return
		if pageCode is "pages"
			for pageItemKey in _pagesItems
				pageItem = @_pagerItemConfig[pageItemKey]

				if pageItemKey is "firstPage"
					pageItem.dom = childNode
					menuItem = new cola.menu.MenuItem(pageItem)
					if right then @addRightItem(menuItem) else @addItem(menuItem)
					beforeChild = childNode
				else
					if pageItemKey is "info"
						menuItem = new cola.menu.ControlMenuItem()
					else
						menuItem = new cola.menu.MenuItem(pageItem)

					itemDom = menuItem.getDom()
					$fly(beforeChild).after(itemDom)
					itemDom._eachIgnore = true
					if right then @addRightItem(menuItem) else @addItem(menuItem)
					beforeChild = itemDom
				@_pagerItemMap[pageItemKey] = menuItem
		else
			propName = _pageCodeMap[pageCode]
			if propName
				itemConfig = @_pagerItemConfig[propName]
				itemConfig.dom = childNode
				if $(childNode).text()
					delete itemConfig["icon"]
				menuItem = new cola.menu.MenuItem(itemConfig)
				if right then @addRightItem(menuItem) else @addItem(menuItem)
			else if pageCode is "goto"
				propName = "goto"
				itemConfig = {dom: childNode, control: @_pagerItemConfig[pageCode]}
				menuItem = new cola.menu.ControlMenuItem(itemConfig)
				if right then @addRightItem(menuItem) else @addItem(menuItem)
			else if pageCode is "pageSize"
				propName = "pageSize"
				itemConfig = {dom: childNode, control: @_pagerItemConfig[pageCode]}
				menuItem = new cola.menu.ControlMenuItem(itemConfig)
				if right then @addRightItem(menuItem) else @addItem(menuItem)
			else if pageCode is "info"
				propName = "info"
				itemConfig = {dom: childNode}
				menuItem = new cola.menu.MenuItem(itemConfig)
				if right then @addRightItem(menuItem) else @addItem(menuItem)
			@_pagerItemMap[propName] = menuItem
		return

	_parseItems: (node)->
		parseRightMenu = (node)=>
			childNode = node.firstChild
			@_rightItems ?= []
			while childNode
				if childNode.nodeType == 1
					pageCode = $fly(childNode).attr("page-code")
					if pageCode
						@_parsePageItem(childNode, true)
					else
						menuItem = cola.widget(childNode)
						if menuItem
							@addRightItem(menuItem)
						else if cola.util.hasClass(childNode, "item")
							menuItem = new cola.menu.MenuItem({dom: childNode})
							@addRightItem(menuItem)
				childNode = childNode.nextSibling
			return
		childNode = node.firstChild

		while childNode
			if childNode._eachIgnore
				childNode = childNode.nextSibling
				continue
			if childNode.nodeType == 1
				pageCode = $fly(childNode).attr("page-code")
				if pageCode
					@_parsePageItem(childNode)
				else
					menuItem = cola.widget(childNode)
					if menuItem
						@addItem(menuItem)
					else if !@_rightMenuDom and cola.util.hasClass(childNode, "right menu")
						@_rightMenuDom = childNode
						parseRightMenu(childNode)
					else if cola.util.hasClass(childNode, "item")
						menuItem = new cola.menu.MenuItem({dom: childNode})
						@addItem(menuItem)
			childNode = childNode.nextSibling

	_createItem: (config, floatRight)->
		if typeof config is "string"
			if config is "pages"
				for pageItemKey in _pagesItems
					pageItem = @_pagerItemConfig[pageItemKey]
					if pageItemKey is "info"
						menuItem = new cola.menu.ControlMenuItem()
					else
						menuItem = new cola.menu.MenuItem(pageItem)
					if floatRight then @addRightItem(menuItem) else @addItem(menuItem)
					@_pagerItemMap[pageItemKey] = menuItem
			else
				propName = _pageCodeMap[config]
				if propName
					itemConfig = @_pagerItemConfig[propName]
					menuItem = new cola.menu.MenuItem(itemConfig)
				else if config is "goto"
					propName = config
					itemConfig = {control: @_pagerItemConfig[config]}
					menuItem = new cola.menu.ControlMenuItem(itemConfig)
				else if config is "pageSize"
					propName = config
					itemConfig = {control: @_pagerItemConfig[config]}
					menuItem = new cola.menu.ControlMenuItem(itemConfig)

				else if config is "info"
					propName = config
					menuItem = new cola.menu.MenuItem()
				if floatRight then @addRightItem(menuItem) else @addItem(menuItem)

				@_pagerItemMap[propName] = menuItem
			return
		menuItem = null
		if config.constructor == Object.prototype.constructor
			if config.$type
				if config.$type is "dropdown"
					menuItem = new cola.menu.DropdownMenuItem(config)
				else if config.$type is "headerItem"
					menuItem = new cola.menu.HeaderMenuItem(config)
				else
					menuItem = new cola.menu.ControlMenuItem({
						control: config
					})
			else
				menuItem = new cola.menu.MenuItem(config)
		else if config instanceof cola.menu.AbstractMenuItem
			menuItem = config
		return menuItem

	_initDom: (dom)->
		super(dom)
		@pagerItemsRefresh()

	pagerItemsRefresh: () ->
		pager = @
		data = pager._getBindItems()
		hasPrev = false
		hasNext = false
		pageNo = 0
		pageCount = 0
		totalEntityCount = 0
		pageSize = 0
		if data
			pageCount = parseInt((data.totalEntityCount + data.pageSize - 1) / data.pageSize)
			totalEntityCount = data.totalEntityCount
			hasPrev = data.pageNo > 1
			hasNext = pageCount > data.pageNo
			pageNo = data.pageNo
			pageCount = data.pageCount
			pageSize = data.pageSize


		@_pageNo = pageNo
		pager._pagerItemMap["firstPage"]?.get$Dom().toggleClass("disabled", !hasPrev)
		pager._pagerItemMap["prevPage"]?.get$Dom().toggleClass("disabled", !hasPrev)
		pager._pagerItemMap["nextPage"]?.get$Dom().toggleClass("disabled", !hasNext)
		pager._pagerItemMap["lastPage"]?.get$Dom().toggleClass("disabled", !hasNext)
		infoItem = pager._pagerItemMap["info"]
		if infoItem
			infoItemDom = if infoItem.nodeType is 1 then infoItem else  infoItem.getDom()
			$(infoItemDom).addClass("page-item desc").text(cola.resource("cola.pager.info", pageNo, pageCount, totalEntityCount))
		gotoItem = pager._pagerItemMap["goto"]
		if gotoItem
			gotoInput = gotoItem.get("control")
			if gotoInput
				gotoInputControl = cola.widget(gotoInput)
				gotoInputControl?.set("value", pageNo)
				gotoInputControl?.get$Dom().parent().addClass("page-item desc")
		pageSizeItem = pager._pagerItemMap["pageSize"]
		if pageSizeItem
			pageSizeDom = if pageSizeItem.nodeType is 1 then pageSizeItem else  pageSizeItem.getDom()
			descDom = $(pageSizeDom).find(">.page-size-desc")
			$(pageSizeDom).addClass("page-item desc")
			unless descDom.length
				$(pageSizeDom).prepend($.xCreate({
					tagName: "span", class: "page-size-desc",
					content: cola.resource("cola.pager.pageSize")
				}))
			pageSizeInput = pageSizeItem.get("control")
			if pageSizeInput
				cola.widget(pageSizeInput)?.set("value", pageSize)

	_onItemsRefresh: ()-> @pagerItemsRefresh()

	_onItemRefresh: (arg)->
	_onItemInsert: (arg) ->
	_onItemRemove: (arg) ->
	_onItemsLoadingStart: (arg)->
	_onItemsLoadingEnd: (arg)->
	_onCurrentItemChange: (arg)->
		if @_pageNo isnt arg.entityList.pageNo
			@pagerItemsRefresh()

cola.Element.mixin(cola.Pager, cola.DataItemsWidgetMixin)

cola.registerWidget(cola.Pager)
