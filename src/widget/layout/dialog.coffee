class cola.Dialog extends cola.Layer
	@tagName: "c-dialog"
	@CLASS_NAME: "dialog transition v-box hidden"

	@attributes:
		context: null
		animation:
			defaultValue: "scale"
			enum: [
				"scale", "drop", "browse right", "browse",
				"slide left", "slide right", "slide up", "slide down",
				"fade left", "fade right", "fade up", "fade down",
				"fly left", "fly right", "fly up", "fly down",
				"swing left", "swing right", "swing up", "swing down",
				"horizontal flip", "vertical flip"
			]
		header:
			setter: (value)->
				@_setContent(value, "header")
				return @

		actions:
			setter: (value)->
				@_setContent(value, "actions")
				return @

		modal:
			type: "boolean"
			defaultValue: true
		closeable:
			type: "boolean"
			defaultValue: true
		modalOpacity:
			type: "number"
			defaultValue: 0.6
		dimmerClose:
			type: "boolean"
			defaultValue: false

	getContentContainer: ()->
		return null unless @_dom
		unless @_doms.content
			@_makeContentDom("content")

		return @_doms.content

	_initDom: (dom)->
		super(dom)
		for container in ["header", "actions"]
			key = "_#{container}"
			if @[key]?.length
				@_render(el, container) for el in @[key]
		return
	_transitionStart: ()->
		$dom = @get$Dom()
		if @_currentAnimation == "show"
			width = $dom.width()
			height = $dom.height()
			pWidth = $(window).width()
			pHeight = $(window).height()
			if height > pHeight then height = pHeight
			if width > pWidth then width = pWidth
			$dom.css({
				left: (pWidth - width) / 2
				top: (pHeight - height) / 2
				zIndex: cola.floatWidget.zIndex()
			})
	_createCloseButton: ()->
		dom = @_closeBtn = $.xCreate({
			tagName: "div"
			class: "ui icon button close-btn"
			content: [
				{
					tagName: "i"
					class: "close icon"
				}
			]
			click: ()=> @hide()
		})
		return dom

	_doRefreshDom: ()->
		return unless @_dom
		super()
		if @get("closeable")
			unless @_closeBtn then @_createCloseButton()
			@_dom.appendChild(@_closeBtn) if @_closeBtn.parentNode isnt @_dom
		else
			$(@_closeBtn).remove()

	_onShow: ()->
		height = @_dom.offsetHeight
		actionsDom = @_doms.actions
		if actionsDom
			actionsHeight = actionsDom.offsetHeight
			headerHeight = 0
			if @_doms.header then headerHeight = @_doms.header.offsetHeight
			minHeight = height - actionsHeight - headerHeight
			$(@_doms.content).css("min-height", "#{minHeight}px")
		super()

	_transition: (options, callback)->
		return false if @fire("before#{cola.util.capitalize(options.target)}", @, {}) is false
		isShow = options.target is "show"
		if isShow then @_currentAnimation = "show" else @_currentAnimation = "hide"
		if @get("modal")
			if isShow then @_showModalLayer() else @_hideModalLayer()

		options.animation = options.animation or @_animation or "scale"

		@_doTransition(options, callback)

	_makeContentDom: (target)->
		@_doms ?= {}
		dom = document.createElement("div")
		dom.className = target

		if target is "content"
			if @_doms["actions"]
				$(@_doms["actions"]).before(dom)
			else
				@_dom.appendChild(dom)
		else if target is "header"
			afterEl = @_doms["content"] || @_doms["actions"]
			if afterEl
				$(afterEl).before(dom)
			else
				@_dom.appendChild(dom)
		else
			@_dom.appendChild(dom)
		flex = if target is "content" then "flex-box" else "box"
		$fly(dom).addClass(flex)
		@_doms[target] = dom

		return dom

	_parseDom: (dom)->
		@_doms ?= {}

		_parseChild = (node, target)=>
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					widget = cola.widget(childNode)
					@_addContentElement(widget or childNode, target)
				childNode = childNode.nextSibling

			return

		child = dom.firstChild
		while child
			if child.nodeType == 1
				if child.nodeName is "I"
					@_doms.icon = child
					@_icon ?= child.className
				else
					$child = $(child)
					for className in ["header", "content", "actions"]
						continue unless $child.hasClass(className)
						@_doms[className] = child
						_parseChild(child, className)
						break
			child = child.nextSibling

		return

	_showModalLayer: ()->
		@_doms ?= {}
		_dimmerDom = @_doms.modalLayer

		unless _dimmerDom
			_dimmerDom = $.xCreate({
				tagName: "Div"
				class: "ui dimmer"
				contextKey: "dimmer"
			})
			if @_dimmerClose
				$(_dimmerDom).on("click", ()=> @hide())
			@_dom.parentNode.appendChild(_dimmerDom)
			@_doms.modalLayer = _dimmerDom
		$(_dimmerDom).css({
			opacity: @get("modalOpacity")
			zIndex: cola.floatWidget.zIndex()
		}).addClass("active")

		return

	_hideModalLayer: ()->
		@_doms ?= {}
		_dimmerDom = @_doms.modalLayer
		$(_dimmerDom).removeClass("active")

cola.registerWidget(cola.Dialog)