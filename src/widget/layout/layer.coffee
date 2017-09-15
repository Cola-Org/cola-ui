_removeTranslateStyle = (element)->
	for prefix in ['Moz', 'Webkit', 'O', 'ms']
		element.style[prefix + "Transform"] = ""
	element.style.transform = ""
class cola.AbstractLayer extends cola.AbstractContainer
	@tagName: "c-layer"

	@attributes:
		duration:
			defaultValue: 300

		visible:
			type: "boolean"
			readOnly: true
			getter: () ->
				return @isVisible()

		lazyRender:
			type: "boolean"

	@events:
		show: null
		hide: null
		beforeShow: null
		beforeHide: null

	_onShow: ()->
	_onHide: ()->
	_zIndex: ()->
		@get$Dom().css({
			zIndex: cola.floatWidget.zIndex()
		})
	_transition: (options, callback)->
		return false if @fire("before#{cola.util.capitalize(options.target)}", @, {}) is false
		@_doTransition(options, callback)
		return @
	_doTransition: (options, callback)->
	show: (options = {}, callback)->

		return @ if !@_dom or @isVisible()

		if @_lazyRender and not @_contentRendered
			@_contentRendered = true
			cola.xRender(@_dom, @_scope)

		if typeof options == "function"
			callback = options
			options = {}

		options.target = "show"
		@_zIndex()
		@_transition(options, callback)
		return @

	hide: (options = {}, callback)->
		return @ if !@_dom or !@isVisible()
		if typeof options == "function"
			callback = options
			options = {}

		options.target = "hide"

		@_transition(options, callback)
		return @

	toggle: ()->
		return @[if @isVisible() then "hide" else "show"].apply(@, arguments)

	isVisible: ()->
		return  @get$Dom().transition("stop all").hasClass("visible")

class cola.Layer extends cola.AbstractLayer
	@CLASS_NAME: "layer transition hidden"
	@attributes:
		animation:
			defaultValue: "slide left"
			enum: [
				"none", "scale", "drop", "browse right", "browse",
				"slide left", "slide right", "slide up", "slide down",
				"fade left", "fade right", "fade up", "fade down",
				"fly left", "fly right", "fly up", "fly down",
				"swing left", "swing right", "swing up", "swing down",
				"horizontal flip", "vertical flip"
			]
	@SLIDE_ANIMATIONS: ["slide left", "slide right", "slide up", "slide down"]
	_transitionStart: (type)->
	_doTransition: (options, callback)->
		layer = @
		onComplete = ->
			if typeof callback == "function"
				callback.call(layer)
			if options.target is "show" then layer._onShow() else layer._onHide()
			layer.fire(options.target, layer, {})
			return null

		if options.animation == "none"
			@get$Dom().transition(options.target)
			onComplete()
			return @
		animation = options.animation or @_animation or "slide left"
		duration = options.duration or @_duration or 300
		if @constructor.SLIDE_ANIMATIONS.indexOf(animation) < 0
			@get$Dom().transition({
				animation: animation
				duration: duration
				onComplete: onComplete
				queue: true
				onStart: ()=> @_transitionStart()
			})
		else
			$dom = @get$Dom()
			width = $dom.width()
			height = $dom.height()
			isHorizontal = animation is "slide left" or animation is "slide right"
			if animation is "slide left"
				x = width
				y = 0
			else if animation is "slide right"
				x = -width
				y = 0
			else if animation is "slide up"
				x = 0
				y = height
			else
				x = 0
				y = -height
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
			@_transitionStart(options.target)
		return

cola.registerWidget(cola.Layer)