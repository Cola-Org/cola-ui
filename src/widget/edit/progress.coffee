class cola.Progress extends cola.Widget
	@tagName: "c-progress"
	@CLASS_NAME: "progress"
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
	@events:
		change: null

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
	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		value = @_value
		total = @_total || 100

		status = ""
		if value == total
			status = "success"
		else if value > total
			status = "exception"


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

		$dom.find(">text").text(Math.ceil(Math.round(value / total * 10000) / 100) + "%")
		pool = @_classNamePool

		pool.remove("exception")
		pool.remove("success")
		status && pool.add(status)

		return

	reset: ()->

	progress: (progress)->

	complete: ()->

	destroy: ()->
		return if @_destroyed
		@_$dom?.progress("destroy")

		super()
		delete @_doms

		return

cola.registerWidget(cola.Progress)


