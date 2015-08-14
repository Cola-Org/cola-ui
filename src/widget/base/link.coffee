class cola.Link extends cola.AbstractContainer
	@TAG_NAME: "a"
	@ATTRIBUTES:
		href:
			refreshDom: true
		target:
			refreshDom: true

	_setDom: (dom, parseChild)->
		if parseChild and !@_href
			href = dom.getAttribute("href")
			@_href = href if href

		super(dom, parseChild)

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		$dom.attr("href", @_href || "")
		$dom.attr("target", @_target || "")


