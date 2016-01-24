# TODO

_pagesItems = ["firstPage", "prevPage", "goto", "nextPage", "lastPage"]
_pageCodeMap =
	"|<": "firstPage"
	"<": "prevPage"
	">": "nextPage"
	">|": "lastPage"
class cola.Pager extends cola.Menu
	@ATTRIBUTES:
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
				click: ()-> pager._getBindItems()?.loadPage(1)

			prevPage:
				icon: "angle left"
				click: ()->
					data = pager._getBindItems()
					if data?.pageNo > 1 then data.loadPage(data.pageNo - 1)

			goto:
				$type: "input"
				class: "goto"
				inputType: "number"
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
							data?.loadPage(pager._targetPageNo)

			nextPage:
				icon: "angle right"
				click: ()->
					data = pager._getBindItems()
					pageCount = _getPageCount()
					if data and data.pageNo < pageCount then data.loadPage(data.pageNo + 1)

			lastPage:
				icon: "angle double right"
				click: ()->
					data = pager._getBindItems()
					if data then data.loadPage(_getPageCount())

		super(config)

	_parseItems: (node)->
		parseRightMenu = (node)=>
			childNode = node.firstChild
			@_rightItems ?= []
			while childNode
				if childNode.nodeType == 1
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
				menuItem = cola.widget(childNode)
				if menuItem
					@addItem(menuItem)
				else if !@_rightMenuDom and cola.util.hasClass(childNode, "right menu")
					@_rightMenuDom = childNode
					parseRightMenu(childNode)
				else if cola.util.hasClass(childNode, "item")
					pageCode = $fly(childNode).attr("page-code")
					if pageCode
						if pageCode is "pages"
							for pageItemKey in _pagesItems
								pageItem = @_pagerItemConfig[pageItemKey]
								if pageItemKey is "firstPage"
									pageItem.dom = childNode
									menuItem = new cola.menu.MenuItem(pageItem)
									@addItem(menuItem)
									beforeChild = childNode
								else
									if pageItem.$type is "input"
										menuItem = new cola.menu.ControlMenuItem({control: pageItem})
									else
										menuItem = new cola.menu.MenuItem(pageItem)

									itemDom = menuItem.getDom()
									$fly(beforeChild).after(itemDom)
									itemDom._eachIgnore = true
									@addItem(menuItem)
									beforeChild = itemDom
								@_pagerItemMap[pageItemKey] = menuItem
						else
							propName = _pageCodeMap[pageCode]
							if propName
								itemConfig = @_pagerItemConfig[propName]
								itemConfig.dom = childNode
								if cola.util.hasContent(childNode)
									delete itemConfig["icon"]
								menuItem = new cola.menu.MenuItem(itemConfig)
								@addItem(menuItem)
							else if pageCode is "goto"
								propName = "goto"
								itemConfig = {dom: childNode, control: @_pagerItemConfig[pageCode]}
								menuItem = new cola.menu.ControlMenuItem(itemConfig)
								@addItem(menuItem)
							@_pagerItemMap[propName] = menuItem
					else
						menuItem = new cola.menu.MenuItem({dom: childNode})
						@addItem(menuItem)
			childNode = childNode.nextSibling
	_createItem: (config, floatRight)->
		if typeof config is "string"
			if config is "pages"
				for pageItemKey in _pagesItems
					pageItem = @_pagerItemConfig[pageItemKey]
					if pageItem.$type is "input"
						menuItem = new cola.menu.ControlMenuItem({control: pageItem})
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
					propName = "goto"
					itemConfig = {control: @_pagerItemConfig[config]}
					menuItem = new cola.menu.ControlMenuItem(itemConfig)
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
	_onItemsRefresh: (arg) ->
		data = @_getBindItems()
		if data
			@_pagerItemMap["firstPage"]?.get$Dom().toggleClass("disabled", data.pageNo is 1)
			@_pagerItemMap["prevPage"]?.get$Dom().toggleClass("disabled", data.pageNo is 1)
			pageCount = parseInt((data.totalEntityCount + data.pageSize - 1) / data.pageSize)
			@_pagerItemMap["nextPage"]?.get$Dom().toggleClass("disabled", pageCount is data.pageNo)
			@_pagerItemMap["lastPage"]?.get$Dom().toggleClass("disabled", pageCount is data.pageNo)
			gotoInput = @_pagerItemMap["goto"]?.get("control")
			if gotoInput
				cola.widget(gotoInput)?.set("value", data.pageNo)
	_onItemRefresh: (arg)->
	_onItemInsert: (arg) ->
	_onItemRemove: (arg) ->
	_onItemsLoadingStart: (arg)->
	_onItemsLoadingEnd: (arg)->
cola.Element.mixin(cola.Pager, cola.DataItemsWidgetMixin)