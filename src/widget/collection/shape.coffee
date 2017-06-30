class cola.Shape extends cola.AbstractItemGroup
	@tagName: "c-shape"
	@CLASS_NAME: "shape"

	@attributes:
		bind:
			readonlyAfterCreate: true
			setter: (bindStr) -> @_bindSetter(bindStr)

	@events:
		beforeChange: null
		afterChange: null

	@directions: ["up", "down", "left", "right", "over", "back"]
	getContentContainer: ()->
		@_createItemsWrap(dom) unless @_doms.wrap
		return @_doms.wrap

	_createItemsWrap: (dom)->
		@_doms ?= {}
		@_doms.wrap = $.xCreate({
			tagName: "div"
			class: "sides"
		})
		dom.appendChild(@_doms.wrap)
		return null

	setCurrentIndex: (index)->
		@_currentIndex = index
		return unless @_dom
		currentDom = @_current
		if @_doms
			sides = $(@_doms.wrap).find(".side")
			if currentDom
				oldIndex = sides.index(currentDom)
				console.log(oldIndex)
				if index == oldIndex then return
			sides.removeClass("active")
			targetDom = sides.eq(index).addClass("active")

		return @

	_parseDom: (dom)->
		parseItem = (node)=>
			@_items = []
			childNode = node.firstElementChild
			while childNode
				@addItem(childNode) if childNode.nodeType == 1
				$fly(childNode).addClass("side")
				childNode = childNode.nextElementSibling
			return
		@_doms ?= {}
		doms = @_doms
		child = dom.firstElementChild
		while child
			if child.nodeType == 1
				if cola.util.hasClass(child, "sides")
					doms.wrap = child
					parseItem(child)
				else if child.nodeName == "TEMPLATE"
					@regTemplate(child)
			child = child.nextElementSibling

		return

	_initDom: (dom)->
		@_createItemsWrap(dom) unless @_doms.wrap

		template = @getTemplate()
		if template
			if @_bind
				$fly(template).attr("c-repeat", @_bind)
			@_doms.wrap.appendChild(template)
			cola.xRender(template, @_scope)

		if @_items
			@_itemsRender()
		shape = @
		setTimeout(()->
			$(dom).shape({
				beforeChange: ()->
					shape.fire("beforeChange", shape, {current: shape._current})
					return
				onChange: (activeDom)->
					shape._current = activeDom
					shape.fire("afterChange", shape, {current: activeDom})
					return
			})
		, 0)
		@setCurrentIndex(0)

		return

	flip: (direction = "right")->
		if @constructor.directions.indexOf(direction) >= 0
			$dom = @get$Dom()
			unless $dom.shape("is animating")
				$dom.shape("flip #{direction}")
		return @

	setNextSide: (selector)->
		return unless @_dom
		@get$Dom().shape("set next side", selector)
		return @

cola.Element.mixin(cola.Shape, cola.TemplateSupport)
cola.Element.mixin(cola.Shape, cola.DataItemsWidgetMixin)

cola.registerWidget(cola.Shape)

