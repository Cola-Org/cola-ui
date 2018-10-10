class cola.Progress extends cola.Widget
	@tagName: "c-progress"
	@className: "progress"
	@attributes:
		total:
			type: "number"
			defaultValue: 0
			refreshDom: true
		value:
			type: "number"
			defaultValue: 0
			refreshDom: true
		strokeWidth:
			type: "number"
			defaultValue: 5.2
			refreshDom: true
		circle:
			readonlyAfterCreate: true
			type: "boolean"
			defaultValue: false
		animated:
			type: "boolean"
			defaultValue: true
			setter: (animated)->
				@_animated = animated
				@_$dom?.toggleClass("animated", !!animated)
				return

	_initDom: (dom)->
		@_doms ?= {}
		if @_circle
			progressDom = '<svg viewBox="0 0 100 100"><path class="track" d="M 50 50 m 0 -47 a 47 47 0 1 1 0 94 a 47 47 0 1 1 0 -94"></path><path class="progress" d="M 50 50 m 0 -47 a 47 47 0 1 1 0 94 a 47 47 0 1 1 0 -94"></path></svg>'
			$(dom).addClass("circle").append(progressDom).append(document.createElement("text"))
		else
			$(dom).addClass("basic").append($.xCreate([
				{
					tagName: "div", class: "track",
					content: {
						tagName: "div", class: "progress"
					}
				},
				{
					tagName: "text"
				}
			]))
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		value = @_value
		total = @_total || 100

		status = ""
		if value is total
			status = "success"
		else if value > total
			status = "exception"
		pValue = Math.ceil(Math.round(value / total * 10000) / 100)
		progress = pValue + "%"

		if @_circle
			perimeter = 2 * Math.PI * 47
			progressDom = $dom.find(">svg>path.progress")[0]
			trackDom = $dom.find(">svg>path.track")[0]

			trackDom.setAttribute("stroke-width", @_strokeWidth)
			progressDom.setAttribute("stroke-width", @_strokeWidth)
			progressDom.setAttribute("stroke-dasharray", "#{perimeter}px, #{perimeter}px")

			dashOffset = 0

			if status != "exception"
				dashOffset = (1 - value / total) * perimeter + 'px';
			progressDom.setAttribute("stroke-dashoffset", dashOffset)
		else
			$dom.find(">.track>.progress").css("width", if status != "exception" then progress else "100%")
			$dom.hasClass("inline") && $dom.find("text").css("right", if status != "exception" then (100 - pValue) + "%" else "0%")

		$dom.find(">text").text(progress)
		pool = @_classNamePool

		pool.toggle("animated", !!@_animated)
		pool.remove("exception")
		pool.remove("success")
		status && pool.add(status)

		return

	reset: ()->
		oldAnimated = @_animated
		@set("animated", false).set("value", 0).refresh()
		setTimeout(()=>
			@set("animated", oldAnimated)
		, 0)
		return @

	progress: (progress)->
		@set("value", progress)

	complete: ()->
		@set("value", @get("total") || 100)

	destroy: ()->
		return if @_destroyed
		@_$dom?.progress?("destroy")

		super()
		delete @_doms

		return

cola.registerWidget(cola.Progress)


