class cola.Link extends cola.AbstractContainer
	@TAG_NAME: "a"
	@ATTRIBUTES:
		href:
			refreshDom: true
		target:
			refreshDom: true

	_setDom: (dom, parseChild)->
		if parseChild
			unless @_href
				href = dom.getAttribute("href")
				@_href = href if href
			unless @_target
				target = dom.getAttribute("target")
				@_target = target if target
		super(dom, parseChild)

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$dom = @get$Dom()
		if @_href
			$dom.attr("href", @_href)
		else
			$dom.removeAttr("href")
		$dom.attr("target", @_target || "")


