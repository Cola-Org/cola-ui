###
    按钮的抽象类
###
class cola.AbstractButton extends cola.Widget
	@ATTRIBUTES:
		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @_size
				@removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@_size = value
				return

		color:
			refreshDom: true
			enum: ["red", "orange", "yellow", "olive", "green", "teal", "blue", "violet", "purple", "pink", "brown",
			       "grey", "black"]
			setter: (value)->
				oldValue = @_color
				@removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@_color = value
				return

		attached:
			refreshDom: true
			defaultValue: ""
			enum: ["left", "right", "top", "bottom", ""]
			setter: (value)->
				oldValue = @_attached
				if oldValue and oldValue isnt value and @_dom
					@removeClass("#{oldValue} attached", true)
				@_attached = value
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		size = @get("size")
		@_classNamePool.add(size) if size

		color = @get("color")
		@_classNamePool.add(color) if color

		attached = @get("attached")
		@_classNamePool.add("#{attached} attached") if attached

		return

class cola.Button extends cola.AbstractButton
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"top attached", "bottom attached", "left attached", "right attached"
	]
	@CLASS_NAME: "button"
	@ATTRIBUTES:
		caption:
			refreshDom: true

		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @_icon
				@_icon = value
				if oldValue and oldValue isnt value and @_dom and @_doms?.iconDom
					$fly(@_doms.iconDom).removeClass(oldValue)
				return

		iconPosition:
			refreshDom: true
			defaultValue: "left"
			enum: ["left", "right"]

		focusable:
			refreshDom: true
			defaultValue: false

		disabled:
			refreshDom: true
			defaultValue: false

		states:
			refreshDom: true
			defaultValue: ""
			enum: ["loading", "active", ""]
			setter: (value)->
				oldValue = @_states
				if oldValue and oldValue isnt value and @_dom then $fly(@_dom).removeClass(oldValue)
				@_states = value
				return

	_parseDom: (dom)->
		unless @_caption
			child = dom.firstChild
			while child
				if child.nodeType == 3
					text = child.textContent
					if text
						@_caption = text
						child.textContent = ""
						break
				child = child.nextSibling

		return

	_refreshIcon: ()->
		return unless @_dom
		$dom = @get$Dom()
		@_classNamePool.remove("right labeled")
		@_classNamePool.remove("left labeled")
		@_classNamePool.remove("labeled")
		@_classNamePool.remove("icon")

		icon = @get("icon")
		iconPosition = @get("iconPosition")
		caption = @get("caption")

		if icon
			if caption
				if iconPosition is "right"
					@_classNamePool.add("right labeled")
				else
					@_classNamePool.add("labeled")
			@_classNamePool.add("icon")
			@_doms.iconDom ?= document.createElement("i")
			iconDom = @_doms.iconDom
			$fly(iconDom).addClass("#{icon} icon")

			$dom.append(iconDom) if iconDom.parentNode isnt @_dom
		else if @_doms.iconDom
			$fly(@_doms.iconDom).remove()

		return

	_doRefreshDom: ()->
		return unless @_dom

		super()

		$dom = @get$Dom()
		classNamePool = @_classNamePool
		caption = @_caption
		captionDom = @_doms.captionDom

		if caption
			unless captionDom
				captionDom = document.createElement("span")
				@_doms.captionDom = captionDom
			$fly(captionDom).text(caption)
			$dom.append(captionDom) if captionDom.parentNode isnt @_dom
		else
			$fly(captionDom).remove() if captionDom

		if @get("focusable") then $dom.attr("tabindex", "0") else  $dom.removeAttr("tabindex")

		@_refreshIcon()
		states = @_states
		if states then classNamePool.add(states)
		classNamePool.toggle("disabled", @_disabled)

		return

cola.buttonGroup = {}

class cola.buttonGroup.Separator extends cola.Widget
	@SEMANTIC_CLASS: []
	@CLASS_NAME: "or"
	@ATTRIBUTES:
		text:
			defaultValue: "or"
			refreshDom: true
	_parseDom: (dom)->
		return unless dom

		# text
		unless @_text
			text = @_dom.getAttribute("data-text")
			@_text = text if text

		return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@get$Dom().attr("data-text", @_text) if @_dom
		return @

cola.buttonGroup.emptyItems = []
class cola.ButtonGroup extends cola.AbstractButton
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"top attached", "bottom attached", "left attached", "right attached"
	]
	@CHILDREN_TYPE_NAMESPACE: "button-group"
	@CLASS_NAME: "buttons"
	@ATTRIBUTES:
		fluid:
			refreshDom: true
			attrName: "c-fuild"
			defaultValue: false

		mutuallyExclusive:
			refreshDom: true
			defaultValue: true

		items:
			setter: (value)->
				@clear()
				if value instanceof Array
					@addItem(item) for item in value
				return

	_setDom: (dom, parseChild)->
		super(dom, parseChild)

		if @_items?.length
			for item in @_items
				itemDom = item.getDom()
				item.appendTo(@_dom) if itemDom.parentNode isnt dom

		activeExclusive = (targetDom)=>
			return unless  @_mutuallyExclusive
			return if cola.util.hasClass(targetDom, "disabled") or cola.util.hasClass(targetDom,
				"loading") or cola.util.hasClass(targetDom, "active")
			$(">.ui.button.active", @_dom).each((index, itemDom)->
				if itemDom isnt targetDom
					button = cola.widget(itemDom)
					if button
						button.set("states", "")
					else
						$(itemDom).removeClass("active")
				return
			)

			targetBtn = cola.widget(targetDom)
			if targetBtn
				targetBtn.set("states", "active")
			else
				$fly(targetDom).addClass("active")

			return

		@get$Dom().delegate(">.ui.button", "click", (event)->
			activeExclusive(this, event)
		)

	_parseDom: (dom)->
		return unless dom

		child = dom.firstChild
		while child
			if child.nodeType == 1
				widget = cola.widget(child)
				if widget
					@addItem(widget) if widget instanceof cola.Button or widget instanceof cola.buttonGroup.Separator
			child = child.nextSibling

		return

	_resetFluid: ()->
		return unless @_dom

		$dom = @get$Dom()
		attrName = @constructor.ATTRIBUTES.fluid.attrName
		oldFluid = $dom.attr(attrName)
		newFluid = 0
		items = @_items or []

		for item in items
			newFluid++ if item instanceof cola.Button

		unless newFluid is oldFluid
			@_classNamePool.remove("#{oldFluid}") if oldFluid

		fluid = @get("fluid")
		if !!fluid
			@_classNamePool.add("#{newFluid}")
			@_classNamePool.add("fluid")
			$dom.attr(attrName, newFluid)

		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_resetFluid()
		return

	addItem: (item)->
		return @ if @_destroyed
		@_items ?= []

		itemObj = null
		if item instanceof cola.Widget
			itemObj = item
		else if item.$type
			if item.$type is "Separator" or item.$type is "-"
				delete item["$type"]
				itemObj = new cola.buttonGroup.Separator(item)
			else
				itemObj = cola.widget(item)
		else if typeof item == "string"
			itemObj = new cola.buttonGroup.Separator({text: item})

		if itemObj
			@_items.push(itemObj)

			if @_dom
				itemDom = itemObj.getDom()
				if itemDom.parentNode isnt @_dom
					@get$Dom().append(itemDom)
					cola.util.delay(@, "refreshDom", 50, @_refreshDom)

		return @

	add: ()->
		@addItem(arg) for arg in arguments
		return @

	removeItem: (item)->
		return @ unless @_items
		index = @_items.indexOf(item)
		if index > -1
			@_items.splice(index, 1)
			item.remove()
			cola.util.delay(@, "refreshDom", 50, @_refreshDom)
		return @

	destroy: ()->
		return if @_destroyed
		if @_items
			item.destroy() for item in @_items
			delete @_items
		super()
		return

	clear: ()->
		if @_items?.length
			item.destroy() for item in @_items
			@_items = []
			cola.util.delay(@, "refreshDom", 50, @_refreshDom)
		return

	getItem: (index)->
		return @_items?[index]

	getItems: ()->
		return @_items or cola.buttonGroup.emptyItems

cola.registerType("button-group", "_default", cola.Button)
cola.registerType("button-group", "Separator", cola.buttonGroup.Separator)
cola.registerTypeResolver "button-group", (config) ->
	return cola.resolveType("widget", config)