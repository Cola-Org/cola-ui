class cola.RadioButton extends cola.Widget
	@tagName: "c-radio"

	@CLASS_NAME: "checkbox"
	@INPUT_TYPE: "radio"

	@attributes:
		type:
			enum: ["radio", "toggle", "slider"]
			defaultValue: "radio"
			refreshDom: true
			setter: (value)->
				oldValue = @_type
				@_type = value
				if oldValue and @_dom and oldValue isnt value
					$fly(@_dom).removeClass(oldValue)
				return @
		label:
			refreshDom: true
		name:
			refreshDom: true
		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false
		checked:
			type: "boolean"
			refreshDom: true
			defaultValue: false
		value:
			defaultValue: true
			refreshDom: true
		readOnly:
			type: "boolean"
			refreshDom: true
			defaultValue: false

	@_modelValue: false

	_parseDom: (dom)->
		@_doms ?= {}
		@_$dom = $(dom)

		child = dom.firstChild
		while child
			if child.nodeType == 1
				if child.nodeName is "LABEL"
					@_doms.label = child
					@_label ?= cola.util.getTextChildData(child)
				else if child.nodeName is "INPUT"
					nameAttr = child.getAttribute("name")
					if nameAttr then @_name ?= nameAttr
					@_doms.input = child
			child = child.nextSibling

		if !@_doms.label and !@_doms.input
			@_$dom.append($.xCreate([
				{
					tagName: "input"
					type: @constructor.INPUT_TYPE
					contextKey: "input"
					name: @_name or ""
				}
				{
					tagName: "label"
					content: @_label or ""
					contextKey: "label"
				}
			], @_doms))

		unless @_doms.label
			@_doms.label = $.xCreate({
				tagName: "label"
				content: @_label or @_value or ""
			})
			@_$dom.append(@_doms.label)

		unless @_doms.input
			@_doms.input = $.xCreate({
				tagName: "input"
				type: @constructor.INPUT_TYPE
				name: @_name
			})
			$(@_doms.label).before(@_doms.input)
		@_bindToSemantic()
		return

	_createDom: ()->
		return $.xCreate({
			tagName: "DIV"
			class: "ui #{@constructor.CLASS_NAME}"
			content: [
				{
					tagName: "input"
					type: @constructor.INPUT_TYPE
					contextKey: "input"
					name: @_name
				}
				{
					tagName: "label"
					content: @_label or @_value or ""
					contextKey: "label"
				}
			]
		}, @_doms)

	_bindToSemantic: ()->
		@get$Dom().checkbox({
			onChange: ()=> @_changeState()
		})

	_changeState: ()->
		@_checked = @get$Dom().checkbox("is checked")
		if @_checked then @_parent?.set("value", @_value)

	_setDom: (dom, parseChild)->
		@_dom = dom
		unless parseChild
			@_bindToSemantic()
		super(dom, parseChild)

		return

	_refreshEditorDom: ()->
		$dom=@get$Dom()
		if @_checked is $dom.checkbox("is checked") then return
		$dom.checkbox(if @_checked then "check" else "uncheck")
	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_doms ?= {}
		label = @_label or @_value or ""
		$(@_doms.label).text(label)

		readOnly = @get("readOnly")
		@_classNamePool.toggle("read-only", readOnly)
		@_classNamePool.add(@_type)

		$dom = @get$Dom()
		$dom.checkbox(if !!@_disabled then "disable" else "enable")
		$(@_doms.input).attr("name", @_name).attr("value", @_value)
		@_refreshEditorDom()

	toggle: ()->
		state = !!@get("checked")
		@set("checked", !state)
		return @
	remove:()->
		super()
		delete @_parent

	destroy: ()->
		return @ if @_destroyed
		delete @_parent
		super()
		delete @_doms

cola.registerWidget(cola.RadioButton)

emptyRadioGroupItems = []
class cola.RadioGroup extends cola.AbstractEditor
	@tagName: "c-radioGroup"
	@CLASS_NAME: "grouped"

	@attributes:
		name: null
		
		items:
			setter: (items)->
				if typeof items is "string"
					items = items.split(/[\,,\;]/)
					for item, i in items
						index = item.indexOf("=")
						if index > 0
							items[i] = {
								value: item.substring(0, index)
								label: item.substring(index + 1)
							}
				else if items instanceof Array
					for item in items
						item.value ?= item.key
						item.label ?= item.text

				@clear()
				@_addItem(item) for item in items
				return @

		type:
			enum: ["radio", "toggle", "slider"]
			defaultValue: "radio"
			refreshDom: true
			setter: (value)->
				@_type = value
				if @_items
					for item in @_items
						item.set("type", value)
				return @

	constructor: (config) ->
		super(config)
		@_name ?= ((new Date()).getTime() + "")
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		value = @_value
		return unless @_items
		for item in @_items
			if item.get("value") is value
				item.set("checked", true)
				break
		return

	_initDom: (dom)->
		super(dom)
		return unless @_items

		for item in @_items
			itemDom = item.getDom()
			continue if itemDom.parentNode is @_dom
			@_dom.appendChild(itemDom)

		return

	_parseDom: (dom)->
		child = dom.firstChild

		while child
			if child.nodeType == 1
				widget = cola.widget(child)
				@_addItem(widget) if widget and widget instanceof cola.RadioButton
			child = child.nextSibling

		return

	_addItem: (item)->
		return @ if @_destroyed
		@_items ?= []

		if item instanceof cola.RadioButton
			radioBtn = item
		else
			classType = cola.util.getType(item)
			if classType is "number" or classType is "string"
				config = { value: item }
			else
				if item.hasOwnProperty("key")
					config = $.extend(item, null)
					config.label = item.value
					config.value = item.key
				else
					config = item
			radioBtn = new cola.RadioButton(config)

		return unless radioBtn

		radioBtn.set({
			name: @_name,
			type: @_type
		})

		radioBtn._parent = @
		@_items.push(radioBtn)

		if @_dom
			radioDom = radioBtn.getDom()
			radioDom.parentNode isnt @_dom
			@_dom.appendChild(radioDom)

		return @

	addRadioButton: (config)->
		@_addItem(config)
		return @

	getRadioButton: (index)->
		return unless @_items
		if typeof index is "string"
			for item in @_items
				if item.get("value") is index then return
		else
			return @_items[index]
		return null

	removeRadioButton: (index)->

		if index instanceof cola.RadioButton
			radio=index
		else
			radio=getRadioButton(index)
		return @ unless radio

		index=@_items.indexOf(radio)
		@_items.splice(index, 1)

		radio.remove()
		return @

	clear: ()->
		return unless @_items
		for item in @_items
			item.destroy()
		@_items = []

	destroy: ()->
		return @ if @_destroyed
		if @_items
			item.destroy() for item in @_items
			delete @_items
		super()
		return @

cola.registerWidget(cola.RadioGroup)