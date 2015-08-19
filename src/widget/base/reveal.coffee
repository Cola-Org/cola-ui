###
Reveal 组件
###

class cola.Reveal extends cola.Widget
	@CLASS_NAME: "ui reveal"
	@ATTRIBUTES:
		type:
			refreshDom: true
			defaultValue: "fade"
			enum: ["fade", "move", "rotate"]
			setter: (value)->
				oldValue = @["_type"]
				if oldValue and @_dom and oldValue isnt value
					@get$Dom().removeClass(oldValue)

				@["_type"] = value
				return

		direction:
			refreshDom: true
			enum: ["left", "right", "up", "down"]
			defaultValue: "left"
			setter: (value)->
				oldValue = @["_direction"]
				if oldValue and @_dom and oldValue isnt value
					@get$Dom().removeClass(oldValue)

				@["_direction"] = value
				return

		active:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		instant:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		visibleContent:
			refreshDom: true
			setter: (value)->
				@_setContent(value, "visibleContent")
				return @

		hiddenContent:
			refreshDom: true
			setter: (value)->
				@_setContent(value, "hiddenContent")
				return @

	_initDom: (dom)->
		super(dom)
		for container in ["visibleContent", "hiddenContent"]
			key = "_#{container}"
			if @[key]?.length
				@_render(el, container) for el in @[key]
		return

	_parseDom: (dom)->
		return unless dom
		@_doms ?= {}
		child = dom.firstChild

		while child
			if child.nodeType == 1
				widget = cola.widget(child)
				if widget
					widget$Dom = widget.get$Dom()
					@_visibleContent = widget if widget$Dom.has("visible content")
					@_hiddenContent = widget if widget$Dom.has("hidden content")
				else
					$child = $(child)
					@_doms.visibleContent = widget if $child.has("visible content")
					@_doms.hiddenContent = widget if $child.has("hidden content")

			child = child.nextSibling

	_clearContent: (target)->
		old = @["_#{target}"]
		if old
			for el in old
				el.destroy() if el instanceof cola.widget
			@["_#{target}"] = []

		@_doms ?= {}
		$fly(@_doms[target]).empty() if @_doms[target]
		return

	_setContent: (value, target)->
		@_clearContent(target)

		if value instanceof Array
			for el in value
				result = cola.xRender(el, @_scope)
				@_addContentElement(result, target) if result
		else
			result = cola.xRender(value, @_scope)
			@_addContentElement(result, target)  if result

		return

	_makeContentDom: (target)->
		@_doms ?= {}
		if not @_doms[target]
			@_doms[target] = document.createElement("div")
			@_doms[target].className = "#{if target is "visibleContent" then "visible" else "hidden"} content"
			@_dom.appendChild(@_doms[target])

		return @_doms[target]

	_addContentElement: (element, target)->
		name = "_#{target}"
		@[name] ?= []
		targetList = @[name]
		targetList.push(element)

		@_render(element, target) if element and @_dom
		return

	_render: (node, target)->
		@_doms ?= {}

		@_makeContentDom(target) unless @_doms[target]
		dom = node

		if node instanceof cola.Widget
			dom = node.getDom()

		@_doms[target].appendChild(dom) if dom.parentNode isnt @_doms[target]
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		classNamePool = @_classNamePool
		["active", "instant", "disabled"].forEach((property)=>
			value = @get(property)
			classNamePool.toggle(property, !!value)
		)
		type = @get("type")
		classNamePool.add(type) if type

		direction = @get("direction")
		classNamePool.add(direction) if direction

		return
	_getContentContainer: (target)->
		return unless @_dom
		@_makeContentDom(target) unless @_doms[target]
		return @_doms[target]

	getVisibleContentContainer: ()-> return @_getContentContainer("visible")
	getHiddenContentContainer: ()-> return @_getContentContainer("hidden")