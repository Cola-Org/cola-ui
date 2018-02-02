class cola.Image extends cola.Widget
	@tagName: "c-img"

	@CLASS_NAME: "image"
	@attributes:
		src:
			refreshDom: true
		disabled:
			type: "boolean"
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