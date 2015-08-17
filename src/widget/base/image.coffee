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

		disabled:
			refreshDom: true
			defaultValue: false


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

		$dom.attr("src", @_src)

		classNamePool.toggle("disabled", @_disabled)

		return

class cola.Avatar extends cola.Image
	@CLASS_NAME: "avatar image"