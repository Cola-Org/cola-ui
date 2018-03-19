

class cola.Segment extends cola.AbstractContainer
	@tagName: "c-segment"
	@className: "segment"
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"top attached", "bottom attached", "left attached", "right attached",
		"very basic",
		"left aligned", "right aligned", "center aligned",
		"vertical segment", "horizontal segment"
	]

	@attributes:
		textAlign:
			refreshDom: true
			enum: ["left", "right", "center"]
			setter: (value)->
				oldValue = @["_textAlign"]
				cola.util.removeClass(@_dom, "#{oldValue} aligned",
					true) if oldValue and @_dom and oldValue isnt value
				@["_textAlign"] = value
				return

		attached:
			refreshDom: true
			enum: ["left", "right", "top", "bottom"]
			setter: (value)->
				oldValue = @["_attached"]
				$removeClass(@_dom, "#{oldValue} attached", true) if oldValue and @_dom and oldValue isnt value
				@["_attached"] = value
				return

		color:
			refreshDom: true
			enum: ["black", "yellow", "green", "blue", "orange", "purple", "red", "pink", "teal"]
			setter: (value)->
				oldValue = @["_color"]
				@["_color"] = value
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		classNamePool = @_classNamePool

		color = @get("color")
		classNamePool.add(color) if color

		attached = @get("attached")
		classNamePool.add("#{attached} attached") if attached


		textAlign = @get("textAlign")
		classNamePool.add("#{textAlign} aligned") if textAlign

		return

cola.registerWidget(cola.Segment)