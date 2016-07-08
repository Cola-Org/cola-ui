class cola.Carousel extends cola.AbstractItemGroup
	@tagName: "c-carousel"
	@CLASS_NAME: "carousel"
	
	@attributes:
		bind:
			readonlyAfterCreate: true
			setter: (bindStr) ->
				if bindStr then delete @_item
				@_bindSetter(bindStr)
				return
		orientation:
			defaultValue: "horizontal"
			enum: ["horizontal", "vertical"]
		controls:
			defaultValue: true
		pause:
			defaultValue: 3000
	
	@events:
		change: null
		beforeChange: null

	getContentContainer: ()->
		@_createItemsWrap(@_dom) unless @_doms.wrap
		return @_doms.wrap
	
	_parseDom: (dom)->
		parseItem = (node)=>
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					@_items = [] unless @_items
					@addItem(childNode)
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
					@regTemplate(child)
			child = child.nextSibling
		if doms.indicators
			@refreshIndicators()
		else
			@_createIndicatorContainer(dom)
		@_createItemsWrap(dom) unless doms.wrap
		return
	
	_createIndicatorContainer: (dom)->
		@_doms ?= {}
		
		@_doms.indicators = $.xCreate({
			tagName: "div"
			class: "indicators indicators-#{@_orientation}"
			contextKey: "indicators"
		})
		carousel = @
		dom.appendChild(@_doms.indicators)
		
		$(@_doms.indicators).delegate(">span", "click", ()->
			carousel.goTo($fly(@).index())
		)
		
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
		
		template = @getTemplate()
		if template
			if @_bind
				$fly(template).attr("c-repeat", @_bind)
			@_doms.wrap.appendChild(template)

			cola.xRender(template, @_scope)
		
		if @_getDataItems().items
			@_itemsRender()
			@refreshIndicators()
		
		@setCurrentIndex(0)
		carousel = @
		setTimeout(()->
			carousel._scroller = new Swipe(carousel._dom, {
				vertical: carousel._orientation == "vertical",
				disableScroll: false,
				continuous: false,
				callback: (pos)->
					carousel.setCurrentIndex(pos)
					return
			})
		, 0)

		if cola.device.desktop and @_controls
			dom.appendChild($.xCreate({
				tagName: "div"
				class: "controls"
				content: [
					{
						tagName: "A"
						class: "prev"
						click: ()=>
							@replay()
							carousel.previous()
					}
					{
						tagName: "A"
						class: "next"
						click: ()=>
							@replay()
							carousel.next()
					}
				]
			}))
		return
	
	_getDataItems: () ->
		if @_bind
			return @_getItems()
		else
			return {items: @_items};

	setCurrentIndex: (index)->
		if @fire("beforeChange", @, {index: index}) is false then return;

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
				if pos isnt index then @_scroller.slide(index)
		@fire("change", @, {index: index})
		return @
	
	refreshIndicators: ()->
		items = @_getDataItems().items
		if items
			itemsCount = if items instanceof cola.EntityList then items.entityCount else items.length
		else
			itemsCount = 0
		
		return unless @_doms?.indicators

		$(@_doms.indicators).find(">span").remove();
		indicatorCount = 0
		if indicatorCount < itemsCount
			i = indicatorCount
			while i < itemsCount
				span = document.createElement("span")
				if i > 0
					$($(@_doms.indicators).find(">span")[i - 1]).before(span)
				else
					$fly(@_doms.indicators).prepend(span)
				i++
		@_currentIndex ?= -1
		currentIndex = @_currentIndex
		$("span", @_doms.indicators).removeClass("active")
		if currentIndex != -1
			jQuery("span:nth-child(" + (currentIndex + 1) + ")", @_doms.indicators).addClass("indicator-active")
		
		return @

	next: ()->
		items = @_getDataItems().items
		if items and @_scroller
			@_scroller.next()
		return @

	previous: ()->
		items = @_getDataItems().items
		if items and @_scroller
			@_scroller.prev()
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
			@_items = [];

			@_parseDom(@_dom)

			return
		, 0)
		return
	
	play: (pause)->
		if @_interval then clearInterval(@_interval)
		carousel = @
		if pause then @_pause = pause
		@_interval = setInterval(()->
			carousel.next()
		, @_pause)
		return @
	
	replay: ()->
		if @_interval then @play()
	
	pause: ()->
		if @_interval then clearInterval(@_interval)
		return @
	
	goTo: (index = 0)->
		@replay()
		@setCurrentIndex(index)

cola.Element.mixin(cola.Carousel, cola.TemplateSupport)
cola.Element.mixin(cola.Carousel, cola.DataItemsWidgetMixin)

cola.registerWidget(cola.Carousel)

