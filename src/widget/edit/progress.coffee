class cola.Progress extends cola.Widget
	@tagName: "c-progress"
	@CLASS_NAME: "progress"
	@SEMANTIC_CLASS: [
		"left floated", "right floated"
	]

	@attributes:
		total:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_total = value
				@_setting("total", value)
				return

		value:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_value = value
				@progress(value)
				return

		showProgress:
			defaultValue: true
			type: "boolean"
			refreshDom: true

		progressFormat:
			enum: ["percent", "ratio"]
			defaultValue: "percent"
			setter: (value)->
				@_progressFormat = value
				if @_dom then @_setting("label", value)
				return

		ratioText:
			defaultValue: "{percent}%"
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
			type: "boolean"
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
				@_limitValues = value
				@_setting("limitValues", @_limitValues) if @_dom
				return

		precision:
			type: "number"
			refreshDom: true
			defaultValue: 1


	@events:
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
						contextKey: "progress"
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
		return unless @_dom
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

		if @_showProgress
			if @_doms.progress.parentNode isnt @_doms.bar
				@_doms.bar.appendChild(@_doms.progress)
		else
			if @_doms.progress.parentNode
				$(@_doms.progress).remove()

		return

	_setDom: (dom, parseChild)->
		super(dom, parseChild)

		listenState = (eventName, arg)=>
			return @fire(eventName, @, arg)

		@get$Dom().progress({
			total: @get("total")
			label: @_labelFormat
			autoSuccess: @_autoSuccess
			showActivity: @_showActivity
			limitValues: @_limitValues
			precision: @_precision
			text: {
				active: @_activeMessage or ""
				success: @_successMessage or ""
				ratio: @_ratioText
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
		if @_dom then @get$Dom().progress("reset")
		return @

	success: (message = "")->
		if @_dom then @get$Dom().progress("set success", message)
		return @

	warning: (message)->
		if @_dom then @get$Dom().progress("set warning", message)
		return @

	error: (message)->
		if @_dom then @get$Dom().progress("set error", message)
		return @

	progress: (progress)->
		@_value = progress
		if @_dom then @get$Dom().progress("set progress", progress)
		return @

	complete: ()->
		@_value = @_total
		if @_dom then @get$Dom().progress("complete")
		return @

	destroy: ()->
		return if @_destroyed
		@_$dom?.progress("destroy")

		super()
		delete @_doms

		return

cola.registerWidget(cola.Progress)