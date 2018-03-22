###
    按钮的抽象类
###

class cola.Button extends cola.Widget
	@tagName: "c-button"
	@className: "button"
	@attributes:
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
			defaultValue: true

		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		state:
			refreshDom: true
			defaultValue: ""
			enum: ["loading", "active", ""]
			setter: (value)->
				oldValue = @_state
				if oldValue and oldValue isnt value and @_dom then $fly(@_dom).removeClass(oldValue)
				@_state = value
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

		if not @_disabled && @get$Dom().hasClass("disabled")
			@_disabled = true
		return

	_refreshIcon: ()->
		return unless @_dom
		icon = @get("icon")
		iconPosition = @get("iconPosition")
		caption = @get("caption")

		if icon
			@_doms.iconDom ?= document.createElement("i")
			iconDom = @_doms.iconDom
			$fly(iconDom).addClass("#{icon} icon")
			if iconDom.parentNode isnt @_dom
				unless @_doms.captionDom
					@_dom.appendChild(iconDom)
					return
				if iconPosition is "right"
					$fly(@_doms.captionDom).after(iconDom)
				else
					$fly(@_doms.captionDom).before(iconDom)

		else if @_doms.iconDom
			@_classNamePool.remove("icon")
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

		@_refreshIcon()
		state = @_state
		if state then classNamePool.add(state)
		classNamePool.toggle("disabled", @_disabled)
		return

cola.registerWidget(cola.Button)

cola.buttonGroup = {}

class cola.buttonGroup.Separator extends cola.Widget
	@tagName: "separator"
	@parentWidget: cola.ButtonGroup

	@semanticClass: []
	@className: "or"

	@attributes:
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
cola.registerWidget(cola.buttonGroup.Separator)

cola.buttonGroup.emptyItems = []
class cola.ButtonGroup extends cola.Widget
	@tagName: "c-buttonGroup"


	@CHILDREN_TYPE_NAMESPACE: "button-group"
	@className: "buttons"

	@attributes:

		mutuallyExclusive:
			type: "boolean"
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
						button.set("state", "")
					else
						$(itemDom).removeClass("active")
				return
			)

			targetBtn = cola.widget(targetDom)
			if targetBtn
				targetBtn.set("state", "active")
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


	_doRefreshDom: ()->
		return unless @_dom
		super()
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

cola.registerWidget(cola.ButtonGroup)

cola.registerType("button-group", "_default", cola.Button)
cola.registerType("button-group", "separator", cola.buttonGroup.Separator)
cola.registerTypeResolver "button-group", (config)->
	return cola.resolveType("widget", config)