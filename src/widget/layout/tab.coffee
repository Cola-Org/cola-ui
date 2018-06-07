renderTabs = []
$(window).resize(()->
	for tab in renderTabs
		tab.refreshNavButtons()
	return
)

class cola.Tab extends cola.Widget
	@tagName: "c-tab"
	@className: "c-tab"

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
				@_tabConfigs = list

				return

		currentTab:
			getter: ()->
				index = @_currentTab
				tab = @getTab(index)
				@_currentTab = tab
				return tab
			setter: (index)->
				@setCurrentTab(index)
				return @
	@events:
		beforeChange: null
		change: null
	_tabContentRender: (tab)->
		contentsContainer = @getContentsContainer()
		container = tab.get("contentContainer")

		return if container and container.parentNode is contentsContainer

		container = $.xCreate({
			tagName: "content",
			name: tab.get("name")
		})
		contentsContainer.appendChild(container)
		tab.set("contentContainer", container)
		contentDom = tab.getContentDom()
		container.appendChild(contentDom) if contentDom

	_makeControlBtn: ()->
		tabBar = $(@_dom).find(">nav")
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

	getTabIndex: (tabButton)->
		dom = tabButton.getDom();
		pDom = $(dom).parent()
		index = -1;
		for item,i in pDom.find("tab")
			if item == dom then return i
		return index;

	_getTabButtonsSize: ()->
		$dom = @_$dom or $(@_dom)
		buttons = $dom.find(">nav>tabs>tab")
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

	refreshNavButtons: (width)->
		$dom = @_$dom or $(@_dom)
		buttons = $dom.find(">nav>tabs>tab")
		visible = false
		direction = @_direction
		tabsWrap = $dom.find(">nav>tabs")
		horizontal = direction is "top" or direction is "bottom"
		tabBar = $dom.find(">nav")
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
			tabBarWidth = $dom.find(">nav").innerWidth()
			firstLeft = $(firstTab).offset().left
			visible = tabBarWidth < buttonsSize
		else
			tabBarHeight = $dom.find(">nav").innerHeight()
			firstTop = $(firstTab).offset().top
			visible = tabBarHeight < buttonsSize

		if visible
			controlButtons = tabBar.find(">.control-button")
			if controlButtons.length < 1 then @_makeControlBtn()
			if horizontal
				oldPosition = tabsWrap.css("left")
				oldPosition = +oldPosition.replace("px", "")
				if oldPosition == 0
					tabsWrap.css("left", tabBar.find(">.next-button").width() + "px");
				left = $dom.find(">nav").offset().left
				lastELeft = $(lastTab).offset().left + $(lastTab).outerWidth()
				tabBar.find(">.next-button").toggleClass("disabled", lastELeft < left + tabBarWidth)
				tabBar.find(">.pre-button").toggleClass("disabled", firstLeft > left)
			else
				oldPosition = tabsWrap.css("top")
				oldPosition = +oldPosition.replace("px", "")
				tabsWrap.css("left", "0px");
				if oldPosition == 0
					tabsWrap.css("top", tabBar.find(">.next-button").height() + "px");
				top = $dom.find(">nav").offset().top

				lastETop = $(lastTab).offset().top + $(lastTab).outerHeight()
				tabBar.find(">.next-button").toggleClass("disabled", lastETop < top + tabBarHeight)
				tabBar.find(">.pre-button").toggleClass("disabled", firstTop > top)

		$dom.find(".control-button").toggleClass("visible", visible)
		if oldPosition < 0 && width
			position = oldPosition + width
			tabsWrap.css(style, (if position > 0 then 0 else position) + "px")
		unless  visible then  tabsWrap.css(style, "0px")
		return

	_doMove: (next)->
		$dom = @_$dom or $(@_dom)
		direction = @_direction
		horizontal = direction is "top" or direction is "bottom"
		style = if horizontal then "left" else "top"
		size = @_getTabButtonsSize() / $dom.find(">nav>tabs>tab").length
		if horizontal then size = size / 2

		tabsWrap = $dom.find(">nav>tabs")
		oldPosition = tabsWrap.css(style)
		oldPosition = +oldPosition.replace("px", "")
		if next
			size = -1 * size

		buttons = $dom.find(">nav>tabs>tab")
		direction = @_direction
		horizontal = direction is "top" or direction is "bottom"
		lastTab = buttons[buttons.length - 1]
		firstTab = buttons[0]
		$tabBar = $dom.find(">nav")
		tabBarOffset = $tabBar.offset()
		controlBtn = $tabBar.find(".next-button")
		if horizontal
			firstLeft = $(firstTab).offset().left + size
			lastLeft = $(lastTab).offset().left + size
			lastWidth = $(lastTab).outerWidth()
			if next
				l = tabBarOffset.left + $tabBar.outerWidth() - controlBtn.outerWidth()
				if lastLeft + lastWidth < l
					size = size + l - (lastLeft + lastWidth)
			else
				l = tabBarOffset.left + controlBtn.outerWidth()
				if firstLeft > l
					size = size - (firstLeft - l)
		else
			firstTop = $(firstTab).offset().top + size
			lastTop = $(lastTab).offset().top + size
			lastHeight = $(lastTab).outerHeight()
			if next
				t = tabBarOffset.top + $tabBar.outerHeight() - controlBtn.outerHeight()
				if lastTop + lastHeight < t
					size = size + t - (lastTop + lastHeight)
			else
				t = tabBarOffset.top + controlBtn.outerHeight()
				if firstTop > t
					size = size - (firstTop - t)
		tabsWrap.css(style, (oldPosition + size) + "px")
		@refreshNavButtons()

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.remove("top-tab")
		@_classNamePool.add("#{@_direction}-tab")
		list = @_tabConfigs
		@_tabConfigs = null

		if list
			@addTab(tab) for tab in list
			if list.length > 0
				@setCurrentTab(list[0].name)

		@refreshNavButtons()

		return
	_getTabContentDom: (tab)->
		contents = @getContentsContainer()
		content = $(contents).find(">content[name='" + tab._name + "']")
		if content.length > 0
			return content[0]
	getCurrentTab: ()->
		unless @_dom then return
		$tabDom = @get$Dom().find(">nav>tabs>tab.active")
		if $tabDom.length > 0
			return cola.widget($tabDom[0])
	setCurrentTab: (index)->
		oldTab = @getCurrentTab()
		newTab = @getTab(index)
		return true if oldTab is newTab

		arg =
			oldTab: oldTab
			newTab: newTab

		return false if @fire("beforeChange", @, arg) is false
		if oldTab
			oldTab.get$Dom().removeClass("active")
			$(@_getTabContentDom(oldTab)).removeClass("active")

		if newTab
			newTab.get$Dom().addClass("active")
			container = @_getTabContentDom(newTab)

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

		$(dom).delegate("> nav > tabs > tab", "click", (event)->
			activeExclusive(this, event)
		)
		renderTabs.push(this)
		return @ unless @_tabs
		@_tabRender(tab) for tab in @_tabs
		@setCurrentTab(@_currentTab or 0)
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

	getTabBarDom: ()->
		@_doms ?= {}
		unless @_doms.tabBar
			$tabs = $(@_dom).find(">nav")
			if $tabs.length > 0
				dom = $tabs[0]
			else
				dom = @_doms.tabBar = $.xCreate({
					tagName: "nav"
					class: "tab-bar"
				})
				@_dom.appendChild(dom)
		return @_doms.tabBar || dom

	getTabsContainer: ()->
		@_doms ?= {}
		unless @_doms.tabs
			barDom = @getTabBarDom()
			$tabs = $(barDom).find(">tabs")
			if $tabs.length
				dom = $tabs[0]
			unless dom
				dom = $.xCreate({
					tagName: "tabs"
					class: "tabs"
				})
				barDom.appendChild(dom)
			@_doms.tabs = dom
		return @_doms.tabs

	getContentsContainer: ()->
		$contents = $(@_dom).find(">contents")
		if $contents.length
			return $contents[0]

		dom = $.xCreate({
			tagName: "contents"
			class: "contents"
		})

		@_dom.appendChild(dom)

		return dom

	_tabRender: (tab)->
		container = @getTabsContainer()
		dom = tab.getDom()
		if dom.parentNode isnt container
			container.appendChild(dom)
		contentDom = tab.getContentDom()
		if not contentDom?.parentNode
			d = $.xCreate({
				tagName: "content",
				name: tab.get("name")
			})
			tab.set("contentContainer", d)
			@getContentsContainer().appendChild(d)
			contentDom && d.appendChild(contentDom)

		return

	addTab: (tab)->
		if tab.constructor == Object::constructor
			tab = new cola.TabButton(tab)
		tab.set("parent", @)

		@_tabRender(tab)if @_dom
		@refreshNavButtons()

		return tab

	getTab: (index)->
		tabs = @getTabsContainer()
		tabButtonDom = null

		if typeof index == "string"
			$tabDom = $(tabs).find(">tab[name='" + index + "']")
			if $tabDom.length > 0
				tabButtonDom = $tabDom[0]

		else if typeof index == "number"
			$tabDom = $(tabs).find(">tab")
			if index < $tabDom.length
				tabButtonDom = $tabDom[index]
		else if index instanceof cola.TabButton
			return index
		if tabButtonDom
			return cola.widget(tabButtonDom)

		return null

	removeTab: (tab)->
		if tab instanceof cola.TabButton
			obj = tab
		else if typeof tab is "string"
			obj = @getTab(tab)
		if obj

			if @get("currentTab") is obj

				tabDom = obj._dom;
				sibling = $(tabDom).parent().find(">tab,>.tab-button")
				index = sibling.index(tabDom);

				if index > 0
					targetDom = sibling[index - 1]
				else if index < sibling.length - 1
					targetDom = sibling[index + 1]

				if targetDom
					targetTab = cola.widget(targetDom)
					return false unless @setCurrentTab(targetTab)
			contentContainer = obj.get("contentContainer")
			unless contentContainer
				contentContainer = @_getTabContentDom(obj);
			if obj
				width = obj.get$Dom().outerWidth()
				obj.remove()

			$(contentContainer).remove()
		@refreshNavButtons(width)
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
		child = dom.firstElementChild
		tabItem = @
		@_doms ?= {}
		parseCaption = (node)=>
			childNode = node.firstElementChild
			while childNode
				if childNode.nodeType == 1
					if childNode.nodeName == "SPAN"
						@_doms.span = childNode
						@_caption ?= cola.util.getTextChildData(childNode)
					if childNode.nodeName == "I"
						@_doms.icon = childNode
						@_icon ?= childNode.className
				childNode = childNode.nextElementSibling
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

			child = child.nextElementSibling

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

		if @_name then @get$Dom().attr("name", @_name)
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
	@tagName: "tab"
	@className: "tab-button"
	@parentWidget: cola.Tab

	@attributes:
		content:
			setter: (value)->
				if typeof value is "string"
					@_content = cola.xRender({content: value}, @_scope)
				else
					@_content = cola.xRender(value, @_scope)

		contentContainer: null
		parent: null

	@events:
		beforeClose: null
		close: null

	constructor: (config)->
		config.name ?= cola.uniqueId()
		super(config)

	close: ()->
		arg =
			tab: @

		processDefault = @fire("beforeClose", @, arg)
		return @ if processDefault is false

		tab = cola.findWidget(@_dom, cola.Tab, true)
		tab.removeTab(@);

		@destroy()
		@fire("close", @, arg)
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