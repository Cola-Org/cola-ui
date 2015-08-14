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
			defaultValue:"left"
			setter: (value)->
				oldValue = @["_direction"]
				if oldValue and @_dom and oldValue isnt value
					@get$Dom().removeClass(oldValue)

				@["_direction"] = value
				return

		active:
			refreshDom: true
			defaultValue: false

		instant:
			refreshDom: true
			defaultValue: false

		disabled:
			refreshDom: true
			defaultValue: false

		visibleContent:
			refreshDom: true
			setter: (value)->
				oldValue = @["_visibleContent"]
				oldValue?.destroy?()
				delete @["_visibleContent"]
				delete @["_visibleContentDom"]
				@_visibleContent = @_getContent(value)
				@_refreshContent("visible") if @_dom
				return

		hiddenContent:
			refreshDom: true
			setter: (value)->
				oldValue = @["_hiddenContent"]
				oldValue?.destroy?()
				delete @["_hiddenContent"]
				delete @["_hiddenContentDom"]
				@_hiddenContent = @_getContent(value)
				@_refreshContent("hidden") if @_dom
				return

	_setDom: (dom, parseChild)->
		super(dom, parseChild)

		@_refreshContent("visible") if @_visibleContent
		@_refreshContent("hidden") if @_hiddenContent

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

	_getContent: (value)->
		content = null
		if typeof value is "string"
			content = $.xCreate(
				tagName: "SPAN"
				content: value
			)
		else if value.constructor == Object.prototype.constructor
			if value.$type
				content = cola.widget(value)
			else
				content = $.xCreate(value)
		else
			content = value

		return content

	_getContentDom: (context)->
		content = @get("#{context}Content")
		return unless content
		domKey = "_#{context}ContentDom"
		unless  @[domKey]
			if content instanceof cola.Widget
				@[domKey] = content.getDom()
			else if content.nodeType is 1
				@[domKey] = content

		return @[domKey]

	_refreshContent: (context)->
		contentDom = @_getContentDom(context)
		return unless contentDom

		parentNode = contentDom.parentNode
		@_doms ?= {}
		domKey = "#{context}Content"
		if parentNode
			if  parentNode is @_doms[domKey]
				return
			else if parentNode is @_dom
				$(contentDom).addClass("#{context} content")
				return

		unless @_doms[domKey]
			@_doms[domKey] = $.xCreate({
				tagName: "div"
				class: "#{context} content"
			})

		@get$Dom().append(@_doms[domKey]) if @_doms[domKey].parentNode isnt @_dom

		$(@_doms[domKey]).empty().append(contentDom)
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