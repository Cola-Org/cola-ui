class cola.Menu extends cola.Widget
	@tagName: "c-menu"
	@CLASS_NAME: "ui menu"
	@CHILDREN_TYPE_NAMESPACE: "menu"
	@SEMANTIC_CLASS: ["top fixed", "right fixed", "bottom fixed", "left fixed"]

	@attributes:
		items:
			setter: (value)->
				@clearItems() if @["_items"]
				@addItem(item) for item in value if value
		showActivity:
			type: "boolean"
			defaultValue: false

		rightItems:
			setter: (value)->
				@clearRightItems() if @["_rightItems"]
				@addRightItem(item) for item in value if value

		centered:
			type: "boolean"
			defaultValue: false

	@events:
		itemClick: null

	_parseItems: (node)->
		parseRightMenu = (node)=>
			childNode = node.firstElementChild
			@_rightItems ?= []
			while childNode
				if childNode.nodeType == 1
					menuItem = cola.widget(childNode)
					if menuItem
						@addRightItem(menuItem)
					else if cola.util.hasClass(childNode, "item")
						menuItem = new cola.menu.MenuItem({dom: childNode})
						@addRightItem(menuItem)
				childNode = childNode.nextElementSibling
			return
		childNode = node.firstElementChild
		while childNode
			if childNode.nodeType == 1
				menuItem = cola.widget(childNode)
				if menuItem
					@addItem(menuItem)
				else if !@_rightMenuDom and cola.util.hasClass(childNode, "right menu")
					@_rightMenuDom = childNode
					parseRightMenu(childNode)
				else if cola.util.hasClass(childNode, "item")
					menuItem = new cola.menu.MenuItem({dom: childNode})
					@addItem(menuItem)
			childNode = childNode.nextElementSibling

	_parseDom: (dom)->
		@_items ?= []
		container = $(dom).find(">.container")
		if container.length
			@_centered = true
			@_containerDom = container[0]
			@_parseItems(@_containerDom)
		else
			@_parseItems(dom)
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$(@_containerDom).toggleClass("ui container", !!@_centered)
		if @_isSubMemu then @_classNamePool.remove("ui")

		return

	_initDom: (dom)->
		menuItems = @_items
		rightMenuItems = @_rightItems
		menu = @
		if menuItems
			container = @_getItemsContainer()
			for item in menuItems
				itemDom = item.getDom()
				if itemDom.parentNode isnt container
					container.appendChild(itemDom)
		if rightMenuItems
			unless @_rightMenuDom
				@_rightMenuDom = @_createRightMenu()
				dom.appendChild(@_rightMenuDom)
			for item in rightMenuItems
				rItemDom = item.getDom()
				if rItemDom.parentNode isnt @_rightMenuDom
					@_rightMenuDom.appendChild(rItemDom)

		$(dom).prepend($.xCreate({
			tagName: "div"
			class: "left-items"
		})).hover(()-> menu._bindToSemantic()).delegate(">.item,.right.menu>.item", "click", ()-> menu._setActive(this))

		setTimeout(()->
			menu._bindToSemantic()
			return
		, 300)
		return

	_bindToSemantic: ()->
		if @_parent instanceof cola.menu.MenuItem then return
		$dom = @get$Dom()
		$dom.find(">.dropdown.item,.right.menu>.dropdown.item").each((index, item)=>
			$item = $(item)
			if $item.hasClass("c-dropdown") then return
			$item.addClass("c-dropdown")
			$item.find(".dropdown.item").addClass("c-dropdown")
			$item.dropdown({
				on: "hover"
			})
		)
		return
	_setDom: (dom, parseChild)->
		super(dom, parseChild)
		if @_activeItem then @_setActive(@_activeItem.getDom())
		return

	setActiveItem: (item)->
		unless item.get("active")
			item.set("active", true)
		@_activeItem = item
		if @_rendered then @_setActive(item.getDom())
		return

	getActiveItem: ()->
		return @_activeItem

	_setActive: (itemDom)->
		if @_parent and @_parent instanceof cola.menu.DropdownMenuItem then return

		return unless @_showActivity
		$(">a.item:not(.dropdown),.right.menu>a.item:not(.dropdown)", @_dom).each(()->
			if itemDom is @
				$fly(@).addClass("active")
			else
				$fly(@).removeClass("active").find(".item").removeClass("active")
			return
		)

		return if $fly(itemDom).hasClass("dropdown")

		if $(">.menu", itemDom).length and !@_isSubMemu then $fly(itemDom).removeClass("active")
		return

	_getItemsContainer: ()->
		if @_centered
			unless @_containerDom
				@_containerDom = $.xCreate({tagName: "div", class: "container"})
				@_dom.appendChild(@_containerDom)

		return @_containerDom or @_dom
	getParent: ()-> @_parent
	onItemClick: (event, item)->
		parentMenu = @getParent()
		arg =
			item: item
			event: event
		@fire("itemClick", @, arg)
		return unless parentMenu
		if parentMenu instanceof cola.menu.AbstractMenuItem or parentMenu instanceof cola.Menu or parentMenu instanceof cola.Button
			parentMenu.onItemClick(event, item)

		return

	_createItem: (config, floatRight)->
		menuItem = null
		if config.constructor == Object.prototype.constructor
			if config.$type
				if config.$type is "dropdown"
					menuItem = new cola.menu.DropdownMenuItem(config)
				else
					menuItem = new cola.menu.MenuItem({
						content: config,
						type: "container"
					})
			else
				menuItem = new cola.menu.MenuItem(config)
		else if config instanceof cola.menu.AbstractMenuItem
			menuItem = config
		return menuItem

	addItem: (config)->
		menuItem = @_createItem(config)
		return unless menuItem
		menuItem._parent = @
		@_items ?= []
		@_items.push(menuItem)
		active = menuItem.get("active")
		if active then @_activeItem = menuItem
		if @_dom
			container = @_getItemsContainer()
			itemDom = menuItem.getDom()
			if itemDom.parentNode isnt container
				if @_rightMenuDom
					$(@_rightMenuDom).before(itemDom)
				else
					container.appendChild(itemDom)
		return itemDom

	addRightItem: (config)->
		menuItem = @_createItem(config, true)
		return @ unless menuItem
		menuItem._parent = @
		@_rightItems ?= []
		@_rightItems.push(menuItem)
		active = menuItem.get("active")
		if active then @_activeItem = menuItem

		if @_dom
			container = @_getItemsContainer()
			itemDom = menuItem.getDom()

			unless @_rightMenuDom
				@_rightMenuDom = @_createRightMenu()

				container.appendChild(@_rightMenuDom)
			@_rightMenuDom.appendChild(itemDom) if itemDom.parentNode isnt @_rightMenuDom

		return itemDom

	clearItems: ()->
		menuItems = @_items
		if menuItems?.length
			item.destroy() for item in menuItems
			@_items = []
		return @

	clearRightItems: ()->
		menuItems = @_rightItems
		if menuItems?.length
			item.destroy() for item in menuItems
			@_rightItems = []
		return @

	_doRemove: (array, item)->
		index = array.indexOf(item)
		if index > -1
			array.splice(index, 1)
			item.destroy()
		return

	removeItem: (item)->
		menuItems = @_items
		return @ unless menuItems

		item = menuItems[item] if typeof item is "number"
		@_doRemove(menuItems, item) if item

		return @

	removeRightItem: (item)->
		menuItems = @_rightItems
		return @ unless menuItems

		item = menuItems[item] if typeof item is "number"
		@_doRemove(menuItems, item) if item

		return @

	getItem: (index)->
		return @_items?[index]

	getRightItem: (index)->
		return @_rightItems?[index]

	_createRightMenu: ()->
		return $.xCreate(
			{
				tagName: "DIV"
				class: "right menu"
			}
		)
	destroy: ()->
		return if @_destroyed
		super()
		delete @_activeItem
		@clearRightItems()
		@clearItems()
		delete @_containerDom
		return @

cola.registerWidget(cola.Menu)

cola.menu ?= {}

class cola.menu.AbstractMenuItem extends cola.AbstractContainer
	@attributes:
		parent: null
		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false
		active:
			type: "boolean"
			defaultValue: false
			setter: (value)->
				oldValue = @_active
				@_active = value
				if oldValue isnt value and value then @onActive(@)
			getter: ()->
				if !@_active and @_rendered
					@_active = @get$Dom().hasClass("active")
				return @_active

	onItemClick: (event, item)->
		parentMenu = @_parent
		if parentMenu instanceof cola.Menu then parentMenu.onItemClick(event, item)
		return

	onActive: (item)->
		parentMenu = @_parent
		if parentMenu instanceof cola.Menu then parentMenu.setActiveItem(item)

	getParent: ()-> @_parent
	hasSubMenu: ()->return !!this._subMenu
	_doRefreshDom: ()->
		return unless @_dom
		super()
		classNamePool = @_classNamePool
		classNamePool.toggle("disabled", @_disabled)

		return

	destroy: ()->
		return if @_destroyed
		super()
		delete @_parent

class cola.menu.MenuItem extends cola.menu.AbstractMenuItem
	@tagName: "a,item"
	@parentWidget: cola.Menu

	@CLASS_NAME: "item"

	@attributes:
		caption:
			refreshDom: true
		icon:
			refreshDom: true
		href:
			refreshDom: true
		target:
			refreshDom: true
		type: null
		items:
			setter: (value)-> @_resetSubMenu(value)
			getter: ()->return @_subMenu?.get("items")

	_parseDom: (dom)->
		child = dom.firstElementChild
		@_doms ?= {}
		while child
			if child.nodeType == 1
				subMenu = cola.widget(child)
				if subMenu instanceof cola.Menu
					@_subMenu = subMenu
					subMenu._isSubMemu = true
				else if child.nodeName == "I"
					@_doms.iconDom = child
					@_icon ?= child.className
				else if cola.util.hasClass(child, "caption")
					@_doms.captionDom = child

			child = child.nextElementSibling

		unless @_doms.captionDom
			@_doms.captionDom = $.xCreate({
				tagName: "span",
				content: @_caption or ""
			})
			if @_doms.iconDom
				$fly(@_doms.iconDom).after(@_doms.captionDom)
			else
				$fly(dom).prepend(@_doms.captionDom)

		return
	fire: (eventName, self, arg)->
		if @_$dom and eventName is "click" and@_$dom.hasClass("disabled") then return
		super(eventName, self, arg)
	_initDom: (dom)->
		super(dom)
		@_$dom ?= $(dom)
		@_$dom.click((event)=>
			if @_subMenu then return
			if @_$dom.hasClass("disabled") then return false
			return @onItemClick(event, @)
		)
		if @_subMenu
			subMenuDom = @_subMenu.getDom()
			if subMenuDom.parentNode isnt dom then dom.appendChild(subMenuDom)
		return

	_setDom: (dom, parseChild)->
		if parseChild
			unless @_href
				href = dom.getAttribute("href")
				@_href = href if href
			unless @_target
				target = dom.getAttribute("target")
				@_target = target if target

		super(dom, parseChild)

	_createDom: ()->
		icon = @get("icon") or ""
		caption = @get("caption") or ""
		tagName = if @_type is "container" then "item" else "a"

		return $.xCreate({
			tagName: tagName,
			class: @constructor.CLASS_NAME,
			content: [
				{
					tagName: "span",
					content: caption,
					contextKey: "captionDom"
				}
			]
		}, @_doms)

	_refreshIcon: ()->
		$dom = @get$Dom()
		if @_icon and not @_caption
			@_classNamePool.add("icon")
		if @_icon
			if not @_doms.iconDom
				@_doms.iconDom = $.xCreate({
					tagName: "i"
					class: "icon"
				})
			if @_doms.iconDom.parentNode isnt @_dom then $dom.prepend(@_doms.iconDom)
			$fly(@_doms.iconDom).addClass(@_icon)
		else
			$fly(@_doms.iconDom).remove()

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		$dom.find(">.ui.menu").removeClass("ui")
		@_refreshIcon()
		$fly(@_doms.captionDom).text(@_caption or "")

		if @_subMenu
			subMenuDom = @_subMenu.getDom()
			if subMenuDom.parentNode isnt @_dom then @_dom.appendChild(subMenuDom)
		if @_href
			$dom.attr("href", @_href)
		else
			$dom.removeAttr("href")
		$dom.attr("target", @_target || "")
		return

	_resetSubMenu: (config)->
		@_subMenu?.destroy()
		if config
			@_subMenu = new cola.Menu({
				items: config
			})
			@_subMenu._parent = @
			@_subMenu._isSubMemu = true
		else
			delete @_subMenu

	destroy: ()->
		return if @_destroyed
		@_subMenu?.destroy()
		super()

cola.registerWidget(cola.menu.MenuItem)

class cola.menu.DropdownMenuItem extends cola.menu.MenuItem
	@tagName: "dropdown-item"
	@parentWidget: cola.Menu

	@CLASS_NAME: "dropdown item"

	@attributes:
		icon:
			refreshDom: true
			defaultValue: "dropdown"

	_createDom: ()->
		caption = @get("caption") or ""

		return $.xCreate({
			tagName: "DIV",
			class: @constructor.CLASS_NAME,
			content: [
				{
					tagName: "span"
					content: caption
					contextKey: "captionDom"
				}
				{
					tagName: "i",
					class: "dropdown icon"
					contextKey: "iconDom"
				}
			]
		}, @_doms)

	_refreshIcon: ()->
		unless @_doms.iconDom
			@_doms.iconDom = document.createElement("i")
			@_dom.appendChild(@_doms.iconDom)
		@_doms.iconDom.className = "#{@_icon or "dropdown"} icon"

cola.registerWidget(cola.menu.DropdownMenuItem)

class cola.TitleBar extends cola.Menu
	@tagName: "c-titlebar"
	@CLASS_NAME: "menu title-bar"
	@CHILDREN_TYPE_NAMESPACE: "menu"

	@attributes:
		title:
			refreshDom: true

	_parseDom: (dom)->
		child = dom.firstElementChild
		@_doms ?= {}
		while child
			if child.nodeType == 1
				if !@_doms.title and cola.util.hasClass(child, "title")
					@_doms.title = child
					@_title ?= cola.util.getTextChildData(child)
					break
			child = child.nextElementSibling

		super(dom)

		firstChild = dom.firstChild
		if @_doms.title and dom.firstChild isnt @_doms.title
			$(@_doms.title).remove()
			$(firstChild).before(@_doms.title)

		return

	_doRefreshDom: ()->
		return unless  @_dom
		super()
		@_doms ?= {}
		if @_title
			unless @_doms.title
				@_doms.title = $.xCreate({
					tagName: "div"
					class: "title"
				})
				@get$Dom().prepend(@_doms.title)
			$(@_doms.title).text(@_title)
		else
			$(@_doms.title).empty()

		return null

cola.registerWidget(cola.TitleBar)

cola.registerType("menu", "_default", cola.menu.MenuItem)
cola.registerType("menu", "item", cola.menu.MenuItem)
cola.registerType("menu", "dropdownItem", cola.menu.DropdownMenuItem)

cola.registerTypeResolver "menu", (config) ->
	return cola.resolveType("widget", config)




