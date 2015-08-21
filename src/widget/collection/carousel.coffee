class cola.Carousel extends cola.AbstractItemGroup
	@CLASS_NAME: "carousel"

	@ATTRIBUTES:
		bind:
			readonlyAfterCreate: true
			setter: (bindStr) -> @_bindSetter(bindStr)
		orientation:
			defaultValue: "horizontal"
			enum: ["horizontal", "vertical"]
	@EVENTS:
		change: null

	getContentContainer: ()->
		@_createItemsWrap(dom) unless @_doms.wrap
		return @_doms.wrap

	_parseDom: (dom)->
		parseItem = (node)=>
			@_items = []
			childNode = node.firstChild
			while childNode
				@addItem(childNode) if childNode.nodeType == 1
				childNode = childNode.nextSibling
			return

		doms = @_doms
		child = dom.firstChild
		while child
			if child.nodeType == 1
				if cola.util.hasClass(child, "items-wrap")
					doms.wrap = child
					parseItem(child)
				else if !doms.indicators and cola.util.hasClass(child, "indicators")
					doms.indicators = child
				else if child.nodeName == "TEMPLATE"
					@_regTemplate(child)
			child = child.nextSibling

		@_createIndicatorContainer(dom) unless doms.indicators
		@_createItemsWrap(dom) unless doms.wrap
		return

	_createIndicatorContainer: (dom)->
		@_doms ?= {}
		@_doms.indicators = $.xCreate({
			tagName: "div"
			class: "indicators indicators-#{@_orientation}"
			contextKey: "indicators"
		})
		dom.appendChild(@_doms.indicators)
		return null

	_createItemsWrap: (dom)->
		@_doms ?= {}
		@_doms.wrap = $.xCreate({
			tagName: "div"
			class: "items-wrap"
			contextKey: "wrap"
		})
		dom.appendChild(@_doms.wrap)
		return null

	_initDom: (dom)->
		@_createIndicatorContainer(dom) unless @_doms.indicators
		@_createItemsWrap(dom) unless @_doms.wrap

		template = @_getTemplate()
		if template
			if @_bindStr
				$fly(template).attr("c-repeat", @_bindStr)
			@_doms.wrap.appendChild(template)
			cola.xRender(template, @_scope)

		if @_items
			@_itemsRender()
			@refreshIndicators()

		@setCurrentIndex(0)
		carousel = @
		setTimeout(()->
			carousel._scroller = new Swipe(carousel._dom, {
				vertical: carousel._orientation == "vertical",
				disableScroll: true,
				callback: (pos)->
					carousel.setCurrentIndex(pos)
					return
			})
		, 0)

		return

	setCurrentIndex: (index)->
		@fire("change", @, {index: index})
		@_currentIndex = index
		if @_dom
			if @_doms.indicators
				try
					$(".active", @_doms.indicators).removeClass("active")
					activeSpan = @_doms.indicators.children[index]
					activeSpan?.className = "active"
				catch e
			if @_scroller
				pos = @_scroller.getPos()
				if pos isnt index then @_scroller.setPos(index)
		return @

	refreshIndicators: ()->
		itemsCount = @_items.length
		return unless @_doms.indicators
		indicatorCount = @_doms.indicators.children.length

		if indicatorCount < itemsCount
			i = indicatorCount
			while i < itemsCount
				span = document.createElement("span")
				@_doms.indicators.appendChild(span)
				i++
		else if indicatorCount > itemsCount
			i = itemsCount
			while i < indicatorCount
				$(@_doms.indicators.firstChild).remove()
				i++
		@_currentIndex ?= -1
		currentIndex = @_currentIndex
		$("span", @_doms.indicators).removeClass("active")
		if currentIndex != -1
			jQuery("span:nth-child(" + (currentIndex + 1) + ")", @_doms.indicators).addClass("indicator-active")

		return @

	next: ()->
		@_scroller?.next()
		return @

	previous: ()->
		@_scroller?.prev()
		return @

	refreshItems: ()->
		super()
		@_scroller?.refresh()
		@refreshIndicators()
		@setCurrentIndex(0)
		return @

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.add("carousel-#{@_orientation}")

		@refreshIndicators()
		return

	_onItemsRefresh: (arg) -> @_itemDomsChanged()
	_onItemInsert: (arg) -> @_itemDomsChanged()
	_onItemRemove: (arg) -> @_itemDomsChanged()

	_itemDomsChanged: () ->
		setTimeout(()=>
			@_parseDom(@_dom)
			return
		, 0)
		return

cola.Element.mixin(cola.Carousel, cola.TemplateSupport)
cola.Element.mixin(cola.Carousel, cola.DataItemsWidgetMixin)