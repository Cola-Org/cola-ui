class cola.Progress extends cola.Widget
	@CLASS_NAME: "progress"
	@SEMANTIC_CLASS: [
		"left floated", "right floated"
	]
	@ATTRIBUTES:
		total:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_total = if isFinite(value) then parseFloat(value) else value
				@_setting("total", @_total) if @_dom
				return

		value:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_value = value
				@progress(value) if @_dom
				return

		labelFormat:
			enum: ["percent", "ratio"]
			defaultValue: "percent"
			setter: (value)->
				@_labelFormat = value
				@_setting("label", value) if @_dom
				return

		ratioText:
			setter: (value)->
				@_ratioText = value
				@_settingText() if @_dom
				return

		activeMessage:
			refreshDom: true
			setter: (value)->
				@_activeMessage = value
				@_settingText() if @_dom
				return

		successMessage:
			refreshDom: true
			setter: (value)->
				@_successMessage = value
				@_settingText() if @_dom
				return

		autoSuccess:
			defaultValue: true

			setter: (value)->
				@_autoSuccess = !!value
				@_setting("autoSuccess", @_autoSuccess) if @_dom
				return

		showActivity:
			type: "boolean"
			defaultValue: true
			setter: (value)->
				@_showActivity = !!value
				@_setting("showActivity", @_showActivity) if @_dom
				return

		limitValues:
			type: "boolean"
			defaultValue: true
			setter: (value)->
				@_limitValues = !!value
				@_setting("limitValues", @_limitValues) if @_dom
				return

		precision:
			type: "number"
			refreshDom: true
			defaultValue: 1

		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@["_size"] = value
				return

		color:
			refreshDom: true
			enum: ["black", "yellow", "green", "blue", "orange", "purple", "red", "pink", "teal"]
			setter: (value)->
				oldValue = @["_color"]
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@["_color"] = value
				return

	@EVENTS:
		change: null
		success: null
		active: null
		error: null
		warning: null

	_initDom: (dom)->
		@_doms ?= {}
		$(dom).empty().append(
			$.xCreate([
				{
					tagName: "div"
					class: "bar"
					content: {
						tagName: "div"
						class: "progress"
					}
					contextKey: "bar"
				}
				{
					tagName: "div"
					class: "label"
					contextKey: "label"
				}
			], @_doms)
		)

	_setting: (name, value)->
		@get$Dom().progress("setting", name, value) if @_dom
		return

	_settingText: ()->
		@_setting("text", {
			active: @_activeMessage or ""
			success: @_successMessage or ""
			ratio: @_ratioText or "{percent}%"
		})
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		@_doms ?= {}
		if @_activeMessage or @_successMessage
			$dom.append(@_doms.label) if !@_doms.label.parentNode
		else
			$(@_doms.label).remove() if @_doms.label.parentNode

		size = @get("size")
		@_classNamePool.add(size) if size

		color = @get("color")
		@_classNamePool.add(color) if color

		attached = @get("attached")
		@_classNamePool.add("#{attached} attached") if attached
		return

	_setDom: (dom, parseChild)->
		super(dom, parseChild)

		listenState = (eventName, arg)=>
			return @fire(eventName, @, arg)

		@get$Dom().progress({
			total: @get("total")
			label: @_labelFormat
			autoSuccess: !!@_autoSuccess
			showActivity: !!@_showActivity
			limitValues: !!@_limitValues
			precision: @_precision
			text: {
				active: @_activeMessage or ""
				success: @_successMessage or ""
				ratio: @_ratioText or "{percent}%"
			}
			onChange: (percent, value, total)->
				arg =
					percent: percent
					value: value
					total: total
				listenState("change", arg)

			onSuccess: (total)->
				arg =
					total: total
				listenState("success", arg)

			onActive: (value, total)->
				arg =
					value: value
					total: total
				listenState("active", arg)

			onWarning: (value, total)->
				arg =
					value: value
					total: total
				listenState("warning", arg)

			onError: (value, total)->
				arg =
					value: value
					total: total
				listenState("error", arg)
		})

		@progress(@_value)

		return


	reset: ()->
		@get$Dom().progress("reset") if @_dom
		return @

	success: (message = "")->
		@get$Dom().progress("set success", message) if @_dom
		return @

	warning: (message)->
		@get$Dom().progress("set warning", message) if @_dom
		return @

	error: (message)->
		@get$Dom().progress("set error", message) if @_dom
		return @

	progress: (progress)->
		@_value = progress
		@get$Dom().progress("set progress", progress) if @_dom
		return @

	complete: ()->
		@_value = @_total
		@get$Dom().progress("complete") if @_dom
		return @

	destroy: ()->
		return if @_destroyed
		@_$dom?.progress("destroy")

		super()
		delete @_doms

		return
#cola.Element.mixin(cola.Progress, cola.DataWidgetMixin)



