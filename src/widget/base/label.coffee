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
				oldValue = @["_size"]
				if oldValue and oldValue isnt value and @_dom
					@get$Dom().removeClass(oldValue)
				@["_size"] = value
				return

		text:
			refreshDom: true

		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @["_icon"]
				@["_icon"] = value
				if  oldValue isnt value and @_dom and @_doms?.iconDom
					$iconDom = $(@_doms.iconDom)
					$iconDom.removeClass(oldValue)
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
				oldValue = @["_color"]
				@get$Dom().removeClass(oldValue)  if oldValue and oldValue isnt value and @_dom
				@["_color"] = value
				return

		attached:
			refreshDom: true
			defaultValue: ""
			enum: ["left top", "left bottom", "right top", "right bottom", "top", "bottom"]
			setter: (value)->
				oldValue = @["_attached"]
				$removeClass(@_dom, "#{oldValue} attached", true) if oldValue and @_dom
				@["_attached"] = value
				return


	_setDom: (dom, parseChild)->
		@_doms ?= {}
		super(dom, parseChild)

	_parseDom: (dom)->
		return unless dom

		# 解析text
		unless @_text
			text = cola.util.getTextChildData(dom)
			@_text = text if text

		@get$Dom().empty()

	_refreshIcon: ()->
		return unless @_dom
		$dom = @get$Dom()
		@_doms ?= {}
		icon = @get("icon")
		iconPosition = @get("iconPosition")
		if icon
			@_doms.iconDom ?= document.createElement("i")
			iconDom = @_doms.iconDom
			$(iconDom).addClass("#{icon} icon")

			if iconPosition is "left" and @_doms.textDom
				$(@_doms.textDom).before(iconDom)
			else
				$dom.append(iconDom)
		else if  @_doms.iconDom
			$(@_doms.iconDom).remove()
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		$dom = @get$Dom()
		classNamePool = @_classNamePool
		text = @get("text") or ""
		textDom = @_doms.textDom
		if text
			unless textDom
				textDom = document.createElement("span")
				@_doms.textDom = textDom
			$(textDom).text(text)
			$dom.append(textDom)
		else
			$(textDom).remove() if textDom

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
		detail:null
	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_doms ?= {}
		if @_image
			unless @_doms.image
				@_doms.image=$.xCreate({
					tagName:"img"
					src:@_image
				})
			if @_doms.image.parentNode isnt @_dom then @get$Dom().prepend(@_doms.image)
			$fly(@_doms.image).attr("src",@_image)
		else
			if @_doms.image then $fly(@_doms.image).remove()
		detailDom=$(".detail",@_dom)
		if @_detail

			if detailDom.length >0
				detailDom.text(@_detail)
			else
				detailDom=$.xCreate({
					tagName:"div"
					class:"detail"
					content:@_detail
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
				oldValue = @["_pointing"]
				@get$Dom().removeClass(oldValue) if oldValue and @_dom
				@["_pointing"] = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		pointing = @get("pointing")
		@_classNamePool.add(pointing) if pointing and @_dom

class cola.Tag extends cola.Label
	@CLASS_NAME: "tag label"


class cola.Corner extends cola.Label
	@CLASS_NAME: "corner label"
	@ATTRIBUTES:
		position:
			enum: ["left", "right"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_position"]
				if oldValue and oldValue isnt value and @_dom
					$dom = @get$Dom()
					$dom.removeClass(oldValue) if oldValue is "left"
				@["_position"] = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		position = @get("position")
		@_classNamePool.add(position) if position is "left"

class cola.Ribbon extends cola.Label
	@CLASS_NAME: "ribbon label"
	@ATTRIBUTES:
		position:
			enum: ["left", "right"]
			setter: (value)->
				oldValue = @["_position"]
				return if oldValue is value
				if oldValue is "right" and @_dom
					cola.util.removeClass(@_dom, "right ribbon", true)
					@get$Dom().addClass("ribbon")
				@["_position"] = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		position = @get("position")
		if position is "right"
			@_classNamePool.remove("ribbon")
			@_classNamePool.add("right ribbon")
