class cola.Image extends cola.Widget
	@CLASS_NAME: "image"
	@TAG_NAME: "img"
	@ATTRIBUTES:
		src:
			refreshDom: true
		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@["_size"] = value
				return

		states:
			refreshDom: true
			defaultValue: ""
			enum: ["disabled", "hidden", ""]
			setter: (value)->
				oldValue = @["_states"]
				if oldValue and oldValue isnt value and @_dom then $fly(@_dom).removeClass(oldValue)
				@["_states"] = value
				return @

	_parseDom: (dom)->
		return unless dom

		# 解析src
		unless @_src
			src = dom.getAttribute("src")
			@_src = src if src

	_doRefreshDom: ()->
		return unless @_dom
		super()

		$dom = @get$Dom()
		classNamePool = @_classNamePool

		size = @get("size")
		classNamePool.add(size) if size

		src = @get("src")
		$dom.attr("src", src)

		if @_states then classNamePool.add(@_states)

		return

class cola.Avatar extends cola.Image
	@CLASS_NAME: "avatar image"