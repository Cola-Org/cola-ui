isIE11 = (/Trident\/7\./).test(navigator.userAgent)

class cola.AbstractInput extends cola.AbstractEditor
	@CLASS_NAME: "input"
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"corner labeled", "right labeled",
		"left icon", "left action"
	]

	@attributes:
		name:
			readOnlyAfterCreate: true
		value:
			setter: (value)->
				if @_dataType
					value = @_dataType.parse(value)
				return @_setValue(value)

		dataType:
			setter: (dataType)->
				return cola.DataType.dataTypeSetter.call(@, dataType)

		placeholder:
			refreshDom: true

		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @["_icon"]
				@["_icon"] = value
				if oldValue and oldValue isnt value and @_dom and @_doms?.iconDom
					$iconDom = $(@_doms.iconDom)
					$iconDom.removeClass(oldValue)
				return

		iconPosition:
			refreshDom: true
			defaultValue: "right"
			enum: [ "left", "right" ]
			setter: (value)->
				oldValue = @["_iconPosition"]
				@["_iconPosition"] = value
				if oldValue and oldValue isnt value and oldValue is "left" and @_dom
					$removeClass(@_dom, "left icon", true)
				return

		corner:
			getter: ()->
				return if @["_corner"] then cola.widget(@["_corner"]) else null
			setter: (value)->
				oldValue = @["_corner"]
				if oldValue then cola.widget(oldValue)?.destroy()
				delete @["_corner"]
				if value
					if value.$type?.toLowerCase() is "corner"
						value = cola.widget(value)
					if value instanceof cola.Corner
						@["_corner"] = value.getDom()
				return
		label:
			refreshDom: true
			getter: ()->
				return if @["_label"] then cola.widget(@["_label"]) else null
			setter: (value)->
				oldValue = @["_label"]
				if oldValue then cola.widget(oldValue)?.destroy()
				delete @["_label"]
				if value
					if value.$type?.toLowerCase() is "label"
						value = cola.widget(value)
					if value instanceof cola.Label
						@["_label"] = value.getDom()
				return

		labelPosition:
			refreshDom: true
			defaultValue: "left"
			enum: [ "left", "right" ]
		actionButton:
			refreshDom: true
			getter: ()->
				return if @["_actionButton"] then cola.widget(@["_actionButton"]) else null
			setter: (value)->
				oldValue = @["_actionButton"]
				if oldValue then cola.widget(oldValue)?.destroy()
				delete @["_actionButton"]
				if value
					if value.$type?.toLowerCase() is "button"
						value = cola.widget(value)
					if value instanceof cola.Label
						@["_actionButton"] = value.getDom()
				return

		buttonPosition:
			refreshDom: true
			defaultValue: "right"
			enum: [ "left", "right" ]

	destroy: ()->
		unless @_destroyed
			super()
			delete @_doms
			delete @["_corner"]
			delete @["_actionButton"]
			delete @["_label"]
		return

	_bindSetter: (bindStr)->
		super(bindStr)
		dataType = @getBindingDataType()
		if dataType then cola.DataType.dataTypeSetter.call(@, dataType)
		return

	_parseDom: (dom)->
		return unless dom

		@_doms ?= {}
		inputIndex = -1
		buttonIndex = 0
		labelIndex = 0
		childConfig = {}
		for child, index in dom.childNodes
			continue if child.nodeType isnt 1
			childTagName = child.tagName
			if childTagName is "C-CORNER"
				childConfig.corner = @_corner = child
			else if childTagName is "C-LABEL"
				labelIndex = index
				childConfig.label = @_label = child
			else if childTagName is "C-BUTTON"
				buttonIndex = index
				childConfig.actionButton = @_actionButton = child
			else if childTagName is "I"
				@_doms.iconDom = child
				@_icon = child.className
			else if @_isEditorDom(child)
				inputIndex = index
				@_doms.input = child

		if childConfig.label and inputIndex > -1 and labelIndex > inputIndex and not config.labelPosition
			@_labelPosition = "right"

		if childConfig.actionButton and inputIndex > -1 and buttonIndex < inputIndex and not config.buttonPosition
			@_buttonPosition = "left"

		if inputIndex is -1
			inputDom = @_doms.input = @_createEditorDom()

			if childConfig.label
				$labelDom = $fly(childConfig.label)
				if @_labelPosition is "right"
					$labelDom.before(inputDom)
				else
					$labelDom.after(inputDom)
			else if childConfig.actionButton
				$actionButtonDom = $fly(childConfig.actionButton)
				if @_buttonPosition is "left"
					$actionButtonDom.after(inputDom)
				else
					$actionButtonDom.before(inputDom)
			else if childConfig.corner
				$fly(childConfig.corner).before(inputDom)
			else
				@get$Dom().append(inputDom)

		return @

	_createEditorDom: ()->
		return $.xCreate({
			tagName: "input"
			type: "text"
		})

	_isEditorDom: (node)->
		return node.nodeName is "INPUT"

	_createDom: ()->
		className = @constructor.CLASS_NAME
		@_doms ?= {}
		inputDom = @_doms.input = @_createEditorDom()

		dom = $.xCreate({
			tagName: "DIV",
			class: "ui #{className}"
		}, @_doms)
		dom.appendChild(inputDom)

		return dom

	fire: (eventName, self, arg)->
		if eventName is "keyDown" or eventName is "keyPress"
			arg.inputValue = $(@_doms.input).val()
		return super(eventName, self, arg)

	_initDom: (dom)->
		super(dom)

		if @_doms.input
			$(@_doms.input).on("change", ()=>
				@_postInput()
				return
			).on("focus", ()=> cola._setFocusWidget(@)
			).on("blur", ()=> cola._setFocusWidget(null)
			).on("keypress", (event)=>
				arg =
					keyCode: event.keyCode
					shiftKey: event.shiftKey
					ctrlKey: event.ctrlKey
					altKey: event.altKey
					event: event

				if @fire("keyPress", @, arg) == false then return false
				if event.keyCode is 13 and isIE11 then @_postInput()
			)
		return

	_onKeyDown: (evt)->
		if evt.altKey and evt.keyCode is 18 and isIE11 then @_postInput()
		return

	_onFocus: ()->
		@_inputFocused = true
		@_refreshInput()
		return

	_onBlur: ()->
		@_inputFocused = false
		@_refreshInput()

		if (not @_value? or @_value is "") and @_bindInfo?.writeable
			propertyDef = @getBindingProperty()
			if propertyDef?._required and propertyDef._validators
				entity = @_scope.get(@_bindInfo.entityPath)
				entity.validate(@_bindInfo.property) if entity
		return

	_refreshCorner: ()->
		corner = @get("corner")
		return unless corner
		if corner.parentNode isnt @_dom then @_dom.appendChild(corner)

		@_classNamePool.remove("labeled")
		@_classNamePool.add("corner labeled")

		return

	_refreshLabel: ()->
		return unless @_dom

		label = @get("label")
		labelPosition = @get("labelPosition")

		@_classNamePool.remove("right labeled")
		@_classNamePool.remove("labeled")
		return unless label

		rightLabeled = labelPosition is "right"
		@_classNamePool.add(if rightLabeled then "right labeled" else "labeled")
		if rightLabeled
			labelWidget = cola.widget(label)
			if labelWidget
				@_dom.appendChild(labelWidget.getDom())
			else
				@_dom.appendChild(label)
		else
			$(@_doms.input).before(label)

		return

	_refreshButton: ()->
		btnDom = $(@_dom).find(">c-button");

		if btnDom.length > 0
			actionButton = btnDom[0]
		buttonPosition = @get("buttonPosition")
		@_classNamePool.remove("left action")
		@_classNamePool.remove("action")
		return unless actionButton

		leftAction = buttonPosition is "left"
		@_classNamePool.add(if leftAction then "left action" else "action")

		if leftAction then $(@_doms.input).before(actionButton) else @_dom.appendChild(actionButton)
		return

	_refreshIcon: ()->
		icon = @get("icon")
		iconPosition = @get("iconPosition")

		classNamePool = @_classNamePool

		classNamePool.remove("left icon")
		classNamePool.remove("icon")

		iconDom = @_doms.iconDom
		if icon
			@_doms.iconDom ?= iconDom = document.createElement("i")
			$fly(iconDom).addClass("#{icon} icon")
			leftIcon = iconPosition is "left"
			classNamePool.add(if leftIcon then "left icon" else "icon")

			if leftIcon then $(@_doms.input).before(iconDom) else @_dom.appendChild(iconDom)
		else if iconDom
			$fly(iconDom).remove()
			delete @_doms.iconDom

		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.attr("readonly", @_finalReadOnly or null)
		@get("actionButton")?.set("disabled", @_finalReadOnly)

		dataType = @_dataType
		if dataType and not @_inputType
			inputType = "text"
			align = "left"
			if dataType instanceof cola.NumberDataType
				inputType = "number"
				align = "right"
			$inputDom.prop("type", inputType).css("text-align", align)

		@_refreshInputValue(@_value)
		return

	_refreshInputValue: (value)->
		@_doms.input.value = if value? then value + "" else ""
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_refreshIcon()
		#@_refreshButton()
		#@_refreshCorner()
		#@_refreshLabel()
		@_refreshInput()

		@_classNamePool.toggle("readonly", !!@_finalReadOnly)
		return

	focus: ()->
		@_doms.input?.focus()
		return

	_postInput: ()->
		if not @_finalReadOnly
			value = @_doms.input.value
			if value is "" then value = null
			dataType = @_dataType
			if dataType
				if @_inputType == "text"
					inputFormat = @_inputFormat
					if dataType instanceof cola.DateDataType
						inputFormat ?= cola.setting("defaultDateInputFormat")
						value = inputFormat + "||" + value
				value = dataType.parse(value)
			@set("value", value)
		return

class cola.Input extends cola.AbstractInput
	@tagName: "c-input"
	@CLASS_NAME: "input"

	@attributes:
		displayFormat: null
		inputFormat: null
		inputType:
			defaultValue: "text"
		maxLength:
			refreshDom: true
			type: "number"
		postOnInput:
			type: "boolean"
		selectOnFocus:
			type: "boolean"
			defaultValue: true
	@events:
		keyPress: null
		input:null

	_createEditorDom: ()->
		config =
			tagName: "input",
			type: @_inputType or "text"
		if @_inputType == "number"
			config.style =
				"text-align": "right"
		return $.xCreate(config)

	_isEditorDom: (node)->
		return node.nodeName is "INPUT"

	_initDom: (dom)->
		super(dom)

		input = @_doms.input
		$(input).on("input", ()=>
			arg = {
				inputValue: $(input).val(),
				value: this.get("value")
			}
			@fire("input", @, arg)
			if @_postOnInput then @_postInput()
			return
		)
		return

	_onFocus: ()->
		super()
		if @_selectOnFocus
			@_doms.input?.select()
		return

	_refreshInputValue: (value)->
		inputType = @_inputType
		if inputType is "text"
			format = if @_focused then @_inputFormat else @_displayFormat
			if value instanceof Date
				if not format
					format = if @_focused then cola.setting("defaultDateTimeFormat") else cola.setting("defaultDateFormat")
				value = (new XDate(value)).toString(format)
			else if isFinite(value)
				if format
					value = formatNumber(format, value)
		else
			if value instanceof Date
				if inputType is "date"
					format = cola.setting("defaultDateFormat")
				else if inputType is "time"
					format = cola.setting("defaultTimeFormat")
				else
					format = cola.setting("defaultDateFormat")
				value = (new XDate(value)).toString(format)
		return super(value)

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$input = $(@_doms.input)
		if @_maxLength
			$input.attr("maxlength", @_maxLength)
		else
			$input.removeAttr("maxlength")

cola.registerWidget(cola.Input)