renderTabs = []
$(window).resize(()->
	for tab in renderTabs
		tab.refreshNavButtons()
	return
)

class cola.Tab extends cola.Widget
	@tagName: "c-tab"
	@CLASS_NAME: "c-tab"

	@attributes:
		direction:
			refreshDom: true
			enum: ["left", "right", "top", "bottom"]
			defaultValue: "top"
			setter: (value)->
				oldValue = @_direction
				if oldValue and oldValue isnt value and @_dom
					@get$Dom().removeClass("#{oldValue}-tab")
				@_direction = value
				return @

		tabs:
			setter: (list)->
				@clear()
				@addTab(tab) for tab in list
				return

		currentTab:
			getter: ()->
				index = @_currentTab
				tab = @getTab(index)
				@_currentTab = tab
				return tab
			setter: (index)->
				@setCurrentIndex(index)
				return @
	@events:
		beforeChange: null
		change: null

	_tabContentRender: (tab)->
		contentsContainer = @getContentsContainer()
		container = tab.get("contentContainer")

		return if container and container.parentNode is contentsContainer
		tagName = if contentsContainer.nodeName is "UL" then "li" else "div"
		container = $.xCreate({
			tagName: tagName
			class: "item"
		})
		contentsContainer.appendChild(container)
		tab.set("contentContainer", container)
		contentDom = tab.getContentDom()
		container.appendChild(contentDom) if contentDom

	_makeControlBtn: ()->
		tabBar = $(@_dom).find(">.tab-bar")
		tabControl = @
		tabBar.prepend($.xCreate({
			tagName: "div"
			class: "pre-button control-button"
		}))
		tabBar.append($.xCreate({
			tagName: "div"
			class: "next-button control-button"
		}))
		tabBar.find(">.next-button").on("click", ()->
			if $(@).hasClass("disabled") then return
			tabControl._doMove(true)
		)
		tabBar.find(">.pre-button").on("click", ()->
			if $(@).hasClass("disabled") then return
			tabControl._doMove(false)
		)
		return

	_getTabButtonsSize: ()->
		$dom = @_$dom or $(@_dom)
		buttons = $dom.find(">.tab-bar>.tabs>.tab-button")
		direction = @_direction
		horizontal = direction is "top" or direction is "bottom"
		lastTab = buttons[buttons.length - 1]
		firstTab = buttons[0]
		if horizontal
			firstLeft = $(firstTab).offset().left
			lastLeft = $(lastTab).offset().left
			return lastLeft + $(lastTab).outerWidth() - firstLeft
		else
			firstTop = $(firstTab).offset().top
			lastTop = $(lastTab).offset().top
			return lastTop + $(lastTab).outerHeight() - firstTop

	refreshNavButtons: ()->
		$dom = @_$dom or $(@_dom)
		buttons = $dom.find(">.tab-bar>.tabs>.tab-button")
		visible = false
		direction = @_direction
		tabsWrap = $dom.find(">.tab-bar>.tabs")
		horizontal = direction is "top" or direction is "bottom"
		tabBar = $dom.find(">.tab-bar")
		style = if horizontal then "left" else "top"
		unless horizontal
			setTimeout(()->
				tabBar.css("width", tabsWrap.width() + "px")
			, 100)


		if buttons.length <= 1
			$dom.find(".control-button").toggleClass("visible", false)
			tabsWrap.css(style, "0px")
			return
		lastTab = buttons[buttons.length - 1]
		firstTab = buttons[0]
		buttonsSize = @_getTabButtonsSize()
		if horizontal
			tabBarWidth = $dom.find(">.tab-bar").innerWidth()
			firstLeft = $(firstTab).offset().left
			visible = tabBarWidth < buttonsSize
		else
			tabBarHeight = $dom.find(">.tab-bar").innerHeight()
			firstTop = $(firstTab).offset().top
			visible = tabBarHeight < buttonsSize

		if visible
			controlButtons = tabBar.find(">.control-button")
			if controlButtons.length < 1 then @_makeControlBtn()
			if horizontal
				oldPosition = tabsWrap.css("left")
				oldPosition = parseInt(oldPosition.replace("px", ""))
				if oldPosition == 0
					tabsWrap.css("left", tabBar.find(">.next-button").width() + "px");
				left = $dom.find(">.tab-bar").offset().left
				lastELeft = $(lastTab).offset().left + $(lastTab).outerWidth()
				tabBar.find(">.next-button").toggleClass("disabled", lastELeft < left + tabBarWidth)
				tabBar.find(">.pre-button").toggleClass("disabled", firstLeft > left)
			else
				oldPosition = tabsWrap.css("top")
				oldPosition = parseInt(oldPosition.replace("px", ""))
				tabsWrap.css("left", "0px");
				if oldPosition == 0
					tabsWrap.css("top", tabBar.find(">.next-button").height() + "px");
				top = $dom.find(">.tab-bar").offset().top

				lastETop = $(lastTab).offset().top + $(lastTab).outerHeight()
				tabBar.find(">.next-button").toggleClass("disabled", lastETop < top + tabBarHeight)
				tabBar.find(">.pre-button").toggleClass("disabled", firstTop > top)

		$dom.find(".control-button").toggleClass("visible", visible)
		unless  visible then  tabsWrap.css(style, "0px")
		return

	_doMove: (next)->
		$dom = @_$dom or $(@_dom)
		direction = @_direction
		horizontal = direction is "top" or direction is "bottom"
		style = if horizontal then "left" else "top"
		size = @_getTabButtonsSize() / $dom.find(">.tab-bar>.tabs>.tab-button").length
		if horizontal then size = size / 2

		tabsWrap = $dom.find(">.tab-bar>.tabs")
		oldPosition = tabsWrap.css(style)
		oldPosition = parseInt(oldPosition.replace("px", ""))
		oldPosition + size
		if next
			tabsWrap.css(style, (oldPosition - size) + "px")
		else
			tabsWrap.css(style, (oldPosition + size) + "px")
		@refreshNavButtons()

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.remove("top-tab")
		@_classNamePool.add("#{@_direction}-tab")
		@refreshNavButtons()
		return

	setCurrentTab: (index)->
		oldTab = @get("currentTab")
		newTab = @getTab(index)
		return true if oldTab is newTab

		arg =
			oldTab: oldTab
			newTab: newTab

		return false if @fire("beforeChange", @, arg) is false

		if oldTab
			oldTab.get$Dom().removeClass("active")
			$(oldTab.get("contentContainer")).removeClass("active")
		if newTab
			newTab.get$Dom().addClass("active")
			container = newTab.get("contentContainer")

			unless container #懒渲染
				@_tabContentRender(newTab)
				container = newTab.get("contentContainer")
			$(container).addClass("active")
		@_currentTab = newTab

		@fire("change", @, arg)
		return true

	_initDom: (dom)->
		super(dom)

		activeExclusive = (targetDom)=>
			tab = cola.widget(targetDom)
			if tab and tab instanceof cola.TabButton
				@setCurrentTab(tab)
			return

		$(dom).delegate("> .tab-bar > .tabs > .tab-button", "click", (event)->
			activeExclusive(this, event)
		)

		return @ unless @_tabs
		@_tabRender(tab) for tab in @_tabs
		@setCurrentTab(@_currentTab or 0)

		renderTabs.push(this)

		setTimeout(()=>
			@refreshNavButtons()
		, 150)
		return @

	destroy: ()->
		return if @_destroyed
		i = renderTabs.indexOf(@)
		if i > -1
			renderTabs.splice(i, 1)
		super()
	_parseTabBarDom: (dom)->
		@_doms ?= {}

		parseTabs = (node)=>
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					tab = cola.widget(childNode)

					name = $(childNode).attr("name")
					if !tab and name
						tab = new cola.TabButton({
							dom: childNode
						})
					tab.set("name", name) if tab and name
					@addTab(tab)if tab and tab instanceof cola.TabButton

				childNode = childNode.nextSibling
			return
		child = dom.firstChild
		while child
			if  child.nodeType == 1 and !@_doms.tabs and cola.util.hasClass(child, "tabs")
				@_doms.tabs = child
				parseTabs(child)
			child = child.nextSibling
		return

	_parseDom: (dom)->
		child = dom.firstChild
		@_doms ?= {}
		_contents = {}

		parseContents = (node)->
			contentNode = node.firstChild

			while contentNode
				if contentNode.nodeType == 1
					name = $(contentNode).attr("name")
					_contents[name] = contentNode
					$(contentNode).addClass("item")
				contentNode = contentNode.nextSibling
			return

		while child
			if child.nodeType == 1
				if !@_doms.contents and cola.util.hasClass(child, "contents")
					@_doms.contents = child
					parseContents(child)
				else if !@_doms.tabs and cola.util.hasClass(child, "tab-bar")
					@_doms.tabBar = child
					@_parseTabBarDom(child)
			child = child.nextSibling

		tabs = @_tabs or []
		for tab in tabs
			name = tab.get("name")

			if name and _contents[name]
				item = _contents[name]
				content = item.children[0]
				tab.set("content", _contents[name])
				tab.set("contentContainer", item)

		return

	getTabBarDom: ()->
		@_doms ?= {}
		unless @_doms.tabBar
			dom = @_doms.tabBar = $.xCreate({
				tagName: "nav"
				class: "tab-bar"
			})
			@_dom.appendChild(dom)
		return @_doms.tabBar

	getTabsContainer: ()->
		@_doms ?= {}
		unless @_doms.tabs
			dom = @_doms.tabs = $.xCreate({
				tagName: "ul"
				class: "tabs"
			})
			@getTabBarDom().appendChild(dom)
		return @_doms.tabs

	getContentsContainer: ()->
		unless @_doms.contents
			dom = @_doms.contents = $.xCreate({
				tagName: "ul"
				class: "contents"
			})
			@_dom.appendChild(dom)

		return  @_doms.contents
	_tabRender: (tab)->
		container = @getTabsContainer()
		dom = tab.getDom()
		if dom.parentNode isnt container
			container.appendChild(dom)
		return

	addTab: (tab)->
		@_tabs ?= []
		if tab.constructor == Object::constructor
			tab = new cola.TabButton(tab)
		return @ if @_tabs.indexOf(tab) > -1
		@_tabs.push(tab)
		tab.set("parent", @)
		@_tabRender(tab)if @_dom
		@refreshNavButtons()

		return @
	getTab: (index)->
		tabs = @_tabs or []
		if typeof index == "string"
			for tab in tabs
				if tab.get("name") is index
					return tab
		else if typeof index == "number"
			return tabs[index]
		else if index instanceof cola.TabButton
			return index
		return null


	removeTab: (tab)->
		index = -1
		if typeof tab is "number"
			index = tab
			obj = @_tabs[index]
		else if tab instanceof cola.TabButton
			index = @_tabs.indexOf(tab)
			obj = tab
		else if typeof tab is "string"
			obj = @getTab(tab)
			index = @_tabs.indexOf(obj)

		if index > -1 and obj
			if @get("currentTab") is obj
				newIndex = if index == (@_tabs.length - 1) then index - 1 else index + 1
				return false unless @setCurrentTab(newIndex)
			@_tabs.splice(index, 1)
			contentContainer = obj.get("contentContainer")
			obj.remove()
			$(contentContainer).remove() if contentContainer?.parentNode is @_doms.contents
		@refreshNavButtons()
		return true

	clear: ()->
		tabs = @_tabs or []
		return @ if tabs.length < 1
		tab.destroy() for tab in tabs
		@_tabs = []

cola.registerWidget(cola.Tab)

cola.tab ?= {}

class cola.tab.AbstractTabButton extends cola.Widget
	@attributes:
		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @["_icon"]
				@["_icon"] = value
				if oldValue and oldValue isnt value and @_dom and @_doms?.icon
					$fly(@_doms.icon).removeClass(oldValue)
				return

		closeable:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		caption:
			refreshDom: true

		name:
			refreshDom: true

	getCaptionDom: ()->
		@_doms ?= {}
		unless @_doms.caption
			dom = @_doms.caption = document.createElement("div")
			dom.className = "caption"
			@_dom.appendChild(dom)
		return @_doms.caption

	getCloseDom: ()->
		@_doms ?= {}
		tabItem = @
		@_doms._closeBtn ?= $.xCreate({
			tagName: "div"
			class: "close-btn"
			content: {
				tagName: "i"
				class: "close icon"
			}
			click: ()->
				tabItem.close()
				return false
		})
		return @_doms._closeBtn

	_refreshIcon: ()->
		return unless @_dom
		if @_icon
			captionDom = @getCaptionDom()
			@_doms.icon ?= document.createElement("i")
			dom = @_doms.icon
			$fly(dom).addClass("#{@_icon} icon")
			captionDom.appendChild(dom) if dom.parentNode isnt captionDom
		else
			$fly(@_doms.iconDom).remove() if @_doms.iconDom

		return

	_refreshCaption: ()->
		return unless @_dom
		if @_caption
			captionDom = @getCaptionDom()
			@_doms.span ?= document.createElement("span")
			span = @_doms.span
			$(span).text(@_caption)
			captionDom.appendChild(span) if span.parentNode isnt captionDom
		else if @_doms.span
			$(@_doms.span).remove()
		return

	_parseDom: (dom)->
		child = dom.firstChild
		tabItem = @
		@_doms ?= {}
		parseCaption = (node)=>
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					if childNode.nodeName == "SPAN"
						@_doms.span = childNode
						@_caption ?= cola.util.getTextChildData(childNode)
					if childNode.nodeName == "I"
						@_doms.icon = childNode
						@_icon ?= childNode.className
				childNode = childNode.nextSibling
			return

		while child
			if child.nodeType == 1
				if !@_doms.caption and cola.util.hasClass(child, "caption")
					@_doms.caption = child
					parseCaption(child)
				else if !@_doms.closeBtn and cola.util.hasClass(child, "close-btn")
					@_doms._closeBtn = child
					$(child).on("click", ()->
						tabItem.close()
						return false
					)

			child = child.nextSibling

		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_refreshIcon()
		@_refreshCaption()
		if !!@_closeable
			closeDom = @getCloseDom()
			@_dom.appendChild(closeDom) if closeDom.parentNode isnt @_dom
		else if @_doms and @_doms.closeDom
			$(@_doms.closeDom).remove()
		return

	_createCaptionDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			class: "caption"
			contextKey: "caption"
			content: [
				{
					tagName: "i"
					contextKey: "icon"
					class: "icon"
				}
				{
					tagName: "span"
					contextKey: "span"
					content: @_caption or ""
				}
			]
		}, @_doms)
		@_dom.appendChild(dom)

	destroy: ()->
		return if @_destroyed
		super()
		delete @_doms
		return @

class cola.TabButton extends cola.tab.AbstractTabButton
	@tagName: "c-tabButton"
	@CLASS_NAME: "tab-button"
	@parentWidget: cola.Tab

	@attributes:
		content:
			setter: (value)->
				@_content = cola.xRender(value, @_scope)
		contentContainer: null
		parent: null

	@events:
		beforeClose: null
		afterClose: null

	close: ()->
		arg =
			tab: @

		@fire("beforeClose", @, arg)
		return @ if arg.processDefault is false
		@_parent?.removeTab(@)
		@destroy()
		@fire("afterClose", @, arg)
		return @
	getContentDom: ()->
		return @_content

	destroy: ()->
		return if @_destroyed
		super()
		delete @_content
		delete @_contentContainer
		delete @_parent
		return @

cola.registerWidget(cola.TabButton)