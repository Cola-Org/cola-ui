class cola.Sidebar extends cola.AbstractContainer
	@CLASS_NAME: "ui sidebar"
	@ATTRIBUTES:
		direction:
			defaultValue: "left"
			enum: ["left", "right", "top", "bottom"]
		size:
			defaultValue: 100
		duration:
			type:"number"
			defaultValue: 200
		transition:
			defaultValue: "overlay"
			enum: ["overlay", "push"]
		mobileTransition:
			defaultValue: "overlay"
			enum: ["overlay", "push"]
		closable:
			type:"boolean"
			defaultValue: true

	@EVENTS:
		beforeShow: null
		beforeHide: null
		show: null
		hide: null

	isHidden: ()->
		return false unless @_dom
		return @get$Dom().sidebar("is", "hidden")

	isVisible: ()->
		return false unless @_dom
		return @get$Dom().sidebar("is", "visible")

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.add(@_direction || "left")

	show: (callback)->
		return  if @fire("beforeShow", @, {dom: @_dom}) is false
		$dom = @get$Dom()
		unless @_initialized
			@_initialized = true
			@_setSize()
			$dom.sidebar('setting', {
				duration: @_duration || 200
				transition: @_transition
				closable: false
				mobileTransition: @_mobileTransition
				onShow: ()=> @fire("show", @, {})
				onHide: ()=> @fire("hide", @, {})
			})
		$dom.sidebar("show", callback)

	hide: (callback)->
		return if @fire("beforeHide", @, {dom: @_dom}) is false
		@get$Dom().sidebar("hide", callback)

	_setSize: ()->
		unit = cola.constants.WIDGET_DIMENSION_UNIT
		size = @get("size")
		size = "#{parseInt(size)}#{unit}" if isFinite(size)

		direction = @_direction or "left"
		style = if direction is "left" or direction is "right" then "width" else "height"
		@get$Dom().css(style, size)

		return

class cola.Drawer extends cola.AbstractContainer
	@CLASS_NAME: "ui drawer pushable"
	getPusherDom: ()->
		return unless @_dom
		return $(@_dom).find("> .pusher")[0]
	_initDom: (dom)->
		super(dom)
		pusher = @getPusherDom()
		unless pusher then dom.appendChild($.xCreate({
			tagName: "div"
			class: "pusher"
		}))
		return

	_initPusher: ()->
		@_pusher = @getPusherDom()
		$(@_pusher).on("click", ()=>
			@_hideSidebar()
			event = window.event
			if event
				event.stopImmediatePropagation()
				event.preventDefault()
		)
		return

	_hideSidebar: ()->
		child = @_dom.firstChild
		while child
			if child.nodeType == 1
				widget = cola.widget(child)
				if widget and widget instanceof cola.Sidebar and widget.isVisible()
					widget.hide()

			child = child.nextSibling

	_getFirstSidebar: ()->
		sideDom = $(@_dom).find("> .ui.sidebar")[0]
		return unless sideDom
		return cola.widget(sideDom)

	showSidebar: (id, callback)->
		if id
			if typeof id == "function"
				callback = id
				sidebar = @_getFirstSidebar()
			else
				sidebar = cola.widget(id)
		else
			sidebar = @_getFirstSidebar()

		return unless  sidebar
		sidebarDom = sidebar.getDom()
		if sidebarDom.parentNode isnt @_dom then return
		unless @_pusher
			$(@_dom).find("> .ui.sidebar").sidebar({
				context: @_dom
			})
			@_initPusher()

		sidebar.show(callback)

	hideSidebar: (id, callback)->
		if id
			if typeof id == "function"
				callback = id
				sidebar = @_getFirstSidebar()
			else
				sidebar = cola.widget(id)
		else
			sidebar = @_getFirstSidebar()
		return unless sidebar
		sidebar.hide(callback)
		return @

