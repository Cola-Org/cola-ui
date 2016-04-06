cola.tab ?= {}
class cola.tab.AbstractTabButton extends cola.Widget
	@TAG_NAME: "li"
	@CLASS_NAME: "tab-button"
	@ATTRIBUTES:
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
	@ATTRIBUTES:
		content:
			setter: (value)->
				@_content = cola.xRender(value, @_scope)
		contentContainer: null
		parent: null

	@EVENTS:
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

class cola.Tab extends cola.Widget
	@CLASS_NAME: "c-tab"
	@TAG_NAME: "div"
	@ATTRIBUTES:
		direction:
			refreshDom: true
			enum: ["left", "right", "top", "bottom"]
			defaultValue: "top"
			setter: (value)->
				oldValue = @_direction
				if oldValue and oldValue isnt value and @_dom
					@get$Dom().removeClass("#{oldValue}-bar")
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
	@EVENTS:
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
	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.remove("top-bar")
		@_classNamePool.add("#{@_direction}-bar")

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
		return @

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
		return true

	clear: ()->
		tabs = @_tabs or []
		return @ if tabs.length < 1
		tab.destroy() for tab in tabs
		@_tabs = []

