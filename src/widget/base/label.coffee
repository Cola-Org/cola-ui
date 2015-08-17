class cola.Label extends cola.Widget
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"left top attached", "right top attached", "right bottom attached", "left bottom attached",
		"top attached", "bottom attached",
		"left ribbon", "right ribbon", "center aligned"
	]
	@CLASS_NAME: "label"
	@ATTRIBUTES:
		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @_size
				if oldValue and oldValue isnt value and @_dom
					@removeClass(oldValue)
				@_size = value
				return

		text:
			refreshDom: true

		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @_icon
				@_icon = value
				if  oldValue isnt value and @_dom and @_doms?.iconDom
					$fly(@_doms.iconDom).removeClass(oldValue)
				return

		iconPosition:
			refreshDom: true
			defaultValue: "left"
			enum: ["left", "right"]

		horizontal:
			defaultValue: false
			refreshDom: true

		color:
			refreshDom: true
			enum: ["black", "yellow", "green", "blue", "orange", "purple", "red", "pink", "teal"]
			setter: (value)->
				oldValue = @_color
				@removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@_color = value
				return

		attached:
			refreshDom: true
			defaultValue: ""
			enum: ["left top", "left bottom", "right top", "right bottom", "top", "bottom", ""]
			setter: (value)->
				oldValue = @_attached
				@removeClass("#{oldValue} attached", true) if oldValue and @_dom
				@_attached = value
				return

	_parseDom: (dom)->
		return unless dom

		# 解析text
		unless @_text
			text = cola.util.getTextChildData(dom)
			@_text = text if text

		@get$Dom().empty()

	_refreshIcon: ()->
		return unless @_dom
		@_doms ?= {}
		icon = @_icon
		iconPosition = @_iconPosition
		if icon
			@_doms.iconDom ?= document.createElement("i")
			iconDom = @_doms.iconDom
			$(iconDom).addClass("#{icon} icon")

			if iconPosition is "left" and @_doms.textDom
				$(@_doms.textDom).before(iconDom)
			else
				@_dom.appendChild(iconDom)
		else if @_doms.iconDom
			cola.detachNode(@_doms.iconDom)
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		classNamePool = @_classNamePool
		text = @_text or ""
		textDom = @_doms.textDom
		if text
			unless textDom
				textDom = document.createElement("span")
				@_doms.textDom = textDom
			$fly(textDom).text(text)
			@_dom.appendChild(textDom)
		else
			if textDom then cola.detachNode(textDom)

		size = @get("size")
		classNamePool.add(size) if size

		color = @get("color")
		classNamePool.add(color) if color

		@_refreshIcon()

		attached = @get("attached")
		classNamePool.add("#{attached} attached") if attached

		return

class cola.ImageLabel extends cola.Label
	@CLASS_NAME: "image label"
	@ATTRIBUTES:
		image: null
		iconPosition:
			refreshDom: true
			defaultValue: "right"
			enum: ["left", "right"]
		detail: null
	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_doms ?= {}
		if @_image
			unless @_doms.image
				@_doms.image = $.xCreate({
					tagName: "img"
					src: @_image
				})
			if @_doms.image.parentNode isnt @_dom then @get$Dom().prepend(@_doms.image)
			$fly(@_doms.image).attr("src", @_image)
		else
			if @_doms.image then cola.detachNode(@_doms.image)
		detailDom = $(".detail", @_dom)
		if @_detail
			if detailDom.length > 0
				detailDom.text(@_detail)
			else
				detailDom = $.xCreate({
					tagName: "div"
					class: "detail"
					content: @_detail
				})
				@_dom.appendChild(detailDom)
		else
			detailDom.remove()

class cola.PointingLabel extends cola.Label
	@CLASS_NAME: "pointing label"
	@ATTRIBUTES:
		pointing:
			refreshDom: true
			defaultValue: "top"
			enum: ["left", "right", "top", "bottom"]
			setter: (value)->
				oldValue = @_pointing
				@removeClass(oldValue) if oldValue and @_dom
				@_pointing = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		if @_pointing then @_classNamePool.add(@_pointing)

class cola.Tag extends cola.Label
	@CLASS_NAME: "tag label"


class cola.Corner extends cola.Label
	@CLASS_NAME: "corner label"
	@ATTRIBUTES:
		position:
			enum: ["left", "right"]
			defaultValue: "right"
			refreshDom: true
			setter: (value)->
				oldValue = @_position
				if oldValue and oldValue isnt value and @_dom
					@removeClass(oldValue)
				@_position = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.add(@_position)

class cola.Ribbon extends cola.Label
	@CLASS_NAME: "ribbon label"
	@ATTRIBUTES:
		position:
			enum: ["left", "right"]
			defaultValue: "left"
			setter: (value)->
				oldValue = @_position
				return if oldValue is value
				if oldValue is "right" and @_dom
					@removeClass("right ribbon", true)
					@addClass("ribbon")
				@_position = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		position = @_position
		if position is "right"
			@_classNamePool.remove("ribbon")
			@_classNamePool.add("right ribbon")
