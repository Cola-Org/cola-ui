class cola.Layer extends cola.AbstractContainer
	@CLASS_NAME: "layer transition hidden"
	@ATTRIBUTES:
		animation:
			defaultValue: "slide left"
			enum: [
				"scale", "drop", "browse right", "browse",
				"slide left", "slide right", "slide up", "slide down",
				"fade left", "fade right", "fade up", "fade down",
				"fly left", "fly right", "fly up", "fly down",
				"swing left", "swing right", "swing up", "swing down",
				"horizontal flip", "vertical flip"
			]

		duration:
			defaultValue: 300

		visible:
			readOnly: true
			getter: () ->
				return @isVisible()

	@EVENTS:
		show: null
		hide: null
		beforeShow: null
		beforeHide: null

	_onShow:()->
	_onHide:()->
	_initDom:()->
	_doTransition:(options, callback)->
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

		@get$Dom().transition({
			animation: options.animation or @_animation or "slide left"
			duration: options.duration or @_duration or 300
			onComplete: onComplete
			queue: true
		})

		return

	_transition: (options, callback)->
		arg = {}
		@fire("before#{cola.util.capitalize(options.target)}", @, {})
		return false if arg.processDefault is false
		@_doTransition(options, callback)
		return @

	show: (options = {}, callback)->
		return @ if !@_dom or @isVisible()
		if typeof options == "function"
			callback = options
			options = {}

		options.target = "show"

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

	isVisible: ()->
		return  @get$Dom().transition("stop all").transition("is visible")
