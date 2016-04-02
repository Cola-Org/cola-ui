ACTIVE_PINCH_REG = /^pinch/i
ACTIVE_ROTATE_REG = /^rotate/i
PAN_VERTICAL_EVENTS = ["panUp", "panDown"]
SWIPE_VERTICAL_EVENTS = ["swipeUp", "swipeDown"]

###
    ClassName池对象
    用于刷新组件时频繁的编辑class name提高性能
###
class cola.ClassNamePool
	constructor: (domClass, semanticList = []) ->
		@elements = []
		domClass = if domClass then (" #{domClass} ").replace(cola.constants.CLASS_REG, " ") else " "

		semanticList.forEach((name)=>
			klass = " #{name} "
			if domClass.indexOf(klass) > -1
				domClass = domClass.replace(klass, " ")
				@add(name)
			return
		)

		$.trim(domClass).split(" ").forEach((klass)=>
			@add(klass)
			return
		)

	add: (className)->
		return unless className
		index = @elements.indexOf(className)
		return if index > -1
		@elements.push(className)

	remove: (className)->
		i = @elements.indexOf(className)
		if i > -1 then @elements.splice(i, 1)
		return @

	destroy: ()->
		delete @["elements"]

	join: ()->
		return @elements.join(" ")

	toggle: (className, status)->
		if !!status then @add(className) else @remove(className)
		return


_destroyRenderableElement = (node, data) ->
	element = data[cola.constants.DOM_ELEMENT_KEY]
	if not element? _destroyed
		element._domRemoved = true
		element.destroy()
	return

###
    可渲染元素
###
class cola.RenderableElement extends cola.Element
	@TAG_NAME: "DIV"
	@EVENTS:
		initDom: null
		refreshDom: null
	constructor: (config)->
		if config
			dom = config.dom
			delete config.dom if dom
		@_doms ?= {}
		super(config)
		@_setDom(dom, true) if dom

	_initDom: (dom)-> return # 此方法主要负责初始化内部Dom
	_parseDom: (dom)-> return # 此方法主要负责解析dom 子类应覆写此方法
	_setDom: (dom, parseChild)->
		return unless dom
		@_dom = dom
		cola.util.userData(dom, cola.constants.DOM_ELEMENT_KEY, @)
		cola.util.onNodeRemoved(dom, _destroyRenderableElement)
		if parseChild then @_parseDom(dom)
		@_initDom(dom)
		arg =
			dom: dom, returnValue: null
		@fire("initDom", @, arg)
		@_refreshDom()
		@_rendered = true
		return

	_createDom: ()->
		dom = document.createElement(@constructor.TAG_NAME or "div")
		className = @constructor.CLASS_NAME or ""
		dom.className = "ui #{className}"
		return dom

	_doSet: (attr, attrConfig, value) ->
		if attrConfig?.refreshDom and @_dom
			cola.util.delay(@, "refreshDom", 50, @_refreshDom)
		return super(attr, attrConfig, value)

	_doRefreshDom: ()->
		cola.util.cancelDelay(@, "_refreshDom")

		return unless @_dom
		@_classNamePool.add("ui")
		className = @constructor.CLASS_NAME
		if className
			names = $.trim(className).split(" ")
			@_classNamePool.add(name) for name in names

		@_resetDimension()

		return

	_refreshDom: ()->
		return unless @_dom or not @_destroyed
		@_classNamePool = new cola.ClassNamePool(@_dom.className, @constructor.SEMANTIC_CLASS)

		@_doRefreshDom()

		newClassName = $.trim(@_classNamePool.join())
		@_dom.className = newClassName
		@_classNamePool.destroy()
		delete @["_classNamePool"]

		return

	_resetDimension: ()->
		return

	getDom: ()->
		return null if @_destroyed
		unless @_dom
			dom = @_createDom()
			@_setDom(dom)
		return @_dom

	get$Dom: ()-># 将获得jQuery或zepto 实例
		return null if @_destroyed
		@_$dom ?= $(@getDom())
		return @_$dom

	refresh: ()->
		return @ unless @_dom
		@_refreshDom()

		arg =
			dom: @_dom, returnValue: null
		@fire("refreshDom", @, arg)

		return @

	appendTo: (parentNode)->
		$(parentNode).append(@_dom) if parentNode and @getDom()
		return @

	remove: ()->
		@get$Dom().remove()
		return @

	destroy: ()->
		return if @_destroyed
		cola.util.cancelDelay(@, "refreshDom")
		if @_dom
			@remove() if not @_domRemoved
			delete @_dom
			delete @_$dom
		super()
		@_destroyed = true
		return

	addClass: (value, continuous)->
		if continuous
			cola.util.addClass(@_dom, value, true)
		else
			@get$Dom().addClass(value)
		return @

	removeClass: (value, continuous)->
		if continuous
			cola.util.removeClass(@_dom, value, true)
		else
			@get$Dom().removeClass(value)
		return @

	toggleClass: (value, state, continuous)->
		if continuous
			cola.util.toggleClass(@_dom, value, state, true)
		else
			@get$Dom().toggleClass(value, state)
		return @

	hasClass: (value, continuous)->
		if continuous
			return cola.util.hasClass(@_dom, value, true)
		else
			return @get$Dom().hasClass(value)

###
Dorado 基础组件
###
class cola.Widget extends cola.RenderableElement
	@CLASS_NAME: "control"
	@SEMANTIC_CLASS: ["left floated", "right floated"]

	@ATTRIBUTES:
		display:
			defaultValue: true
			refreshDom: true
			type: "boolean"

		float:
			refreshDom: true
			enum: ["left", "right", ""]
			defaultValue: ""
			setter: (value)->
				oldValue = @["_float"]
				cola.util.removeClass(@_dom, "#{oldValue} floated",
					true) if @_dom and oldValue and oldValue isnt value
				@["_float"] = value
				return

		class:
			refreshDom: true
			setter: (value)->
				oldValue = @["_class"]
				@get$Dom().removeClass(oldValue) if oldValue and @_dom and oldValue isnt value
				@["_class"] = value
				return

		popup:
			setter: (value)->
				options = {}

				if typeof value is "string"
					options.content = value
				else if value.constructor == Object.prototype.constructor and value.tagName
					options.html = $.xCreate(value)
				else if value.nodeType is 1
					options.html = value
				else
					options = value

				@_popup = options

				@get$Dom().popup(@_popup) if @_dom
				return

		dimmer:
			setter: (value)->
				@_dimmer ?= {}
				@_dimmer[k] = v for k,v of value
				return

		height:
			refreshDom: true
		width:
			refreshDom: true

	@EVENTS:
		click:
			$event: "click"
		dblClick:
			$event: "dblclick"
		mouseDown:
			$event: "mousedown"
		mouseUp:
			$event: "mouseup"
		tap:
			hammerEvent: "tap"

		press:
			hammerEvent: "press"

		panStart:
			hammerEvent: "panstart"
		panMove:
			hammerEvent: "panmove"
		panEnd:
			hammerEvent: "panend"
		panCancel:
			hammerEvent: "pancancel"
		panLeft:
			hammerEvent: "panleft"
		panRight:
			hammerEvent: "panright"
		panUp:
			hammerEvent: "panup"
		panDown:
			hammerEvent: "pandown"

		pinchStart:
			hammerEvent: "pinchstart"
		pinchMove:
			hammerEvent: "pinchmove"
		pinchEnd:
			hammerEvent: "pinchend"
		pinchCancel:
			hammerEvent: "pinchcancel"
		pinchIn:
			hammerEvent: "pinchin"
		pinchOut:
			hammerEvent: "pinchout"

		rotateStart:
			hammerEvent: "rotatestart"
		rotateMove:
			hammerEvent: "rotatemove"
		rotateEnd:
			hammerEvent: "rotateend"
		rotateCancel:
			hammerEvent: "rotatecancel"

		swipeLeft:
			hammerEvent: "swipeleft"
		swipeRight:
			hammerEvent: "swiperight"
		swipeUp:
			hammerEvent: "swipeup"
		swipeDown:
			hammerEvent: "swipedown"
	_setDom: (dom, parseChild)->
		return unless dom
		super(dom, parseChild)

		for eventName of @constructor.EVENTS
			@_bindEvent(eventName) if @getListeners(eventName)

		$(dom).popup(@_popup) if @_popup

		return

	_on: (eventName, listener, alias) ->
		super(eventName, listener, alias)
		@_bindEvent(eventName) if @_dom
		return @

	fire: (eventName, self, arg) ->
		return unless @_eventRegistry

		eventConfig = @constructor.EVENTS[eventName]

		return if @constructor.ATTRIBUTES.hasOwnProperty("disabled") and @get("disabled") and eventConfig and (eventConfig.$event or eventConfig.hammerEvent)

		@["_hasFireTapEvent"] = eventName is "tap" if !@["_hasFireTapEvent"]
		return if eventName is "click" and @["_hasFireTapEvent"]

		return super(eventName, self, arg)

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_classNamePool.add("#{@_float} floated") if @_float
		@_classNamePool.toggle("display-none", !!!@_display)

		if !@_rendered and @_class
			@_classNamePool.add(name) for name in @_class.split(" ")

		return

	_bindEvent: (eventName)->
		return unless @_dom
		@_bindedEvents ?= {}
		return if @_bindedEvents[eventName]

		$dom = @get$Dom()
		eventConfig = @constructor.EVENTS[eventName]

		if eventConfig?.$event
			$dom.on(eventConfig.$event, (evt)=>
				arg =
					dom: @_dom, event: evt, returnValue: null
				return @fire(eventName, @, arg)
			)
			@_bindedEvents[eventName] = true
			return

		if eventConfig?.hammerEvent
			@_hammer ?= new Hammer(@_dom, {})
			@_hammer.get("pinch").set({enable: true}) if ACTIVE_PINCH_REG.test(eventName)
			@_hammer.get("rotate").set({enable: true}) if ACTIVE_ROTATE_REG.test(eventName)
			@_hammer.get("pan").set({direction: Hammer.DIRECTION_ALL}) if PAN_VERTICAL_EVENTS.indexOf(eventName) >= 0
			@_hammer.get("swipe").set({direction: Hammer.DIRECTION_ALL}) if SWIPE_VERTICAL_EVENTS.indexOf(eventName) >= 0
			@_hammer.on(eventConfig.hammerEvent, (evt)=>
				arg =
					dom: @_dom, event: evt, returnValue: null, eventName: eventName
				return @fire(eventName, @, arg)
			)

			@_bindedEvents[eventName] = true
			return

		return

	_resetDimension: ()->
		$dom = @get$Dom()
		unit = cola.constants.WIDGET_DIMENSION_UNIT

		height = @get("height")
		height = "#{parseInt(height)}#{unit}" if isFinite(height)
		$dom.css("height", height) if height

		width = @get("width")
		width = "#{parseInt(width)}#{unit}" if isFinite(width)
		$dom.css("width", width) if width

		return

	showDimmer: (options = {})->
		return @ unless @_dom

		content = options.content
		content = @_dimmer.content if !content and @_dimmer


		if content
			if typeof content is "string"
				dimmerContent = $.xCreate({
					tagName: "div"
					content: content
				})
			else if content.constructor == Object.prototype.constructor and content.tagName
				dimmerContent = $.xCreate(content)
			else if content.nodeType is 1
				dimmerContent = content

		@_dimmer ?= {}

		for k,v of options
			@_dimmer[k] = v unless k is "content"

		$dom = @get$Dom()
		dimmer = $dom.dimmer("get dimmer")

		if dimmerContent
			if dimmer
				$(dimmer).empty()
			else
				$dom.dimmer("create")
			$dom.dimmer("add content", dimmerContent)

		$dom.dimmer(@_dimmer)
		$dom.dimmer("show")

		return @

	hideDimmer: ()->
		return @ unless @_dom
		@get$Dom().dimmer("hide")
		return @

	destroy: ()->
		return if @_destroyed
		if @_dom
			delete @_hammer
			delete @_bindedEvents
			delete @_parent
			delete @_doms

		super()
		@_destroyed = true

		return

cola.floatWidget =
	_zIndex: 1100
	zIndex: ()-> return ++cola.floatWidget._zIndex