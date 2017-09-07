class cola.Sidebar extends cola.AbstractLayer
	@tagName: "c-sidebar"
	@CLASS_NAME: "ui sidebar"

	@attributes:
		direction:
			defaultValue: "left"
			refreshDom: true
			enum: ["left", "right", "top", "bottom"]

		size:
			defaultValue: 200
			refreshDom: true

		modal:
			type: "boolean"
			defaultValue: true
		modalOpacity:
			type: "number"
			defaultValue: 0.6
		dimmerClose:
			type: "boolean"
			defaultValue: true

	_doTransition: (options, callback)->

		$(window.document.body).toggleClass("hide-overflow", options.target is "show")

		if @get("modal")
			if options.target is "show"
				@_showModalLayer()
				@_zIndex()
			else @_hideModalLayer()
		sidebar = @
		onComplete = ->
			if typeof callback == "function"
				callback.call(sidebar)
			if options.target is "show" then sidebar._onShow() else sidebar._onHide()
			sidebar.fire(options.target, sidebar, {})
			return null

		direction = @_direction


		duration = options.duration or @_duration or 300

		$dom = @get$Dom()
		width = $dom.width()
		height = $dom.height() || $dom.outerHeight()

		isHorizontal = direction is "left" or direction is "right"
		if direction is "left"
			x = -width
			y = 0
		else if direction is "right"
			x = width
			y = 0
		else if direction is "top"
			x = 0
			y = -height
		else
			x = 0
			y = height
		isShow = options.target is "show"
		if isShow then cola.Fx.translateElement(@_dom, x, y)
		configs =
			duration: duration
			complete: ()=>
				if not isShow then $dom.removeClass("visible").addClass("hidden")
				_removeTranslateStyle(@_dom)
				onComplete()

		if isHorizontal
			configs.x = if isShow then 0 else x
			configs.y = 0
		else
			configs.y = if isShow then 0 else y
			configs.x = 0

		$dom.removeClass("hidden").addClass("visible").transit(configs)

		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_setSize()
		@_classNamePool.add(@_direction || "left")
	_setSize: ()->
		unit = cola.constants.WIDGET_DIMENSION_UNIT
		size = @get("size")
		size = "#{+size}#{unit}" if isFinite(size)

		direction = @_direction or "left"
		style = if direction is "left" or direction is "right" then "width" else "height"
		#		@get$Dom().css("cssText", "#{style}: #{size}!important")
		cola.util.style(@_dom, style, size, "important");

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
			$(_dimmerDom).css("position", "fixed")
			container = @_context or @_dom.parentNode
			container.appendChild(_dimmerDom)
			@_doms.modalLayer = _dimmerDom

		$(_dimmerDom).css({
			opacity: 0
			zIndex: cola.floatWidget.zIndex()
		}).addClass("active").transit({opacity: @_modalOpacity})

		return

	_hideModalLayer: ()->
		@_doms ?= {}
		_dimmerDom = @_doms.modalLayer

		$(_dimmerDom).transit({
				opacity: 0
				complete: ()->

					$(_dimmerDom).removeClass("active").css({
						zIndex: 0
					})
			}
		)
	isVisible: ()->return if @_dom then @get$Dom().hasClass("visible") else false

cola.registerWidget(cola.Sidebar)