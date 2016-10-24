DEFAULT_DATE_DISPLAY_FORMAT = "yyyy-MM-dd"
DEFAULT_DATE_INPUT_FORMAT = "yyyyMMdd"
DEFAULT_TIME_DISPLAY_FORMAT = "HH:mm:ss"
DEFAULT_TIME_INPUT_FORMAT = "HHmmss"
isIE11 = (/Trident\/7\./).test(navigator.userAgent)

class cola.AbstractInput extends cola.AbstractEditor
	@CLASS_NAME: "input"
	@SEMANTIC_CLASS: [
		"left floated", "right floated",
		"corner labeled", "right labeled",
		"left icon", "left action"
	]

	@attributes:
		name: null
		value:
			setter: (value) ->
				if @_dataType
					value = @_dataType.parse(value)
				return @_setValue(value)

		dataType:
			setter: (dataType) ->
				return cola.DataType.dataTypeSetter.call(@, dataType)

		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@["_size"] = value
				return

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
			enum: ["left", "right"]
			setter: (value)->
				oldValue = @["_iconPosition"]
				@["_iconPosition"] = value
				if oldValue and oldValue isnt value and oldValue is "left" and @_dom
					$removeClass(@_dom, "left icon", true)
				return

		corner:
			setter: (value)->
				oldValue = @["_corner"]
				oldValue?.destroy()
				delete @["_corner"]
				if value
					if value instanceof cola.Corner
						@["_corner"] = value
					else if value.$type is "Corner"
						@["_corner"] = cola.widget(value)
				return
		label:
			refreshDom: true
			setter: (value)->
				oldValue = @["_label"]
				oldValue?.destroy()
				delete @["_label"]
				if value
					if value instanceof cola.Label
						@["_label"] = value
					else if value.$type
						@["_label"] = cola.widget(value)
					else
						delete @["_label"]

				return

		labelPosition:
			refreshDom: true
			defaultValue: "left"
			enum: ["left", "right"]
		actionButton:
			refreshDom: true
			setter: (value)->
				oldValue = @["_actionButton"]
				oldValue?.destroy()
				delete @["_actionButton"]
				if value
					if value instanceof cola.Button
						@["_actionButton"] = value
					else if value.$type is "Button"
						@["_actionButton"] = cola.widget(value)
				return

		buttonPosition:
			refreshDom: true
			defaultValue: "right"
			enum: ["left", "right"]


	destroy: ()->
		unless @_destroyed
			super()
			delete @_doms
			delete @["_corner"]
			delete @["_actionButton"]
			delete @["_label"]
		return

	_bindSetter: (bindStr) ->
		super(bindStr)
		dataType = @getBindingDataType()
		if dataType then cola.DataType.dataTypeSetter.call(@, dataType)
		return

	_parseDom: (dom)->
		return  unless dom
		@_doms ?= {}
		inputIndex = -1
		buttonIndex = 0
		labelIndex = 0
		childConfig = {}
		for child,index in dom.childNodes
			continue if child.nodeType isnt 1
			widget = cola.widget(child)
			if widget
				if widget instanceof cola.Corner
					childConfig.corner = @_corner = widget
				else if widget instanceof cola.Label
					labelIndex = index
					childConfig.label = @_label = widget
				else if widget instanceof cola.Button
					buttonIndex = index
					childConfig.actionButton = @_actionButton = widget
			else
				if child.nodeName is "I"
					@_doms.iconDom = child
					@_icon = child.className

				else if @_isEditorDom(child)
					inputIndex = index
					@_doms.input = child

		if childConfig.label and inputIndex > -1 and labelIndex > inputIndex and !config.labelPosition
			@_labelPosition = "right"

		if childConfig.actionButton and inputIndex > -1 and buttonIndex < inputIndex and !config.buttonPosition
			@_buttonPosition = "left"

		if inputIndex is -1
			inputDom = @_doms.input = @_createEditorDom()

			if childConfig.label
				$labelDom = childConfig.label.get$Dom()
				if @_labelPosition is "right"
					$labelDom.before(inputDom)
				else
					$labelDom.after(inputDom)
			else if childConfig.actionButton
				$actionButtonDom = childConfig.actionButton.get$Dom()
				if @_buttonPosition is "left"
					$actionButtonDom.after(inputDom)
				else
					$actionButtonDom.before(inputDom)
			else if childConfig.corner
				childConfig.corner.get$Dom().before(inputDom)
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

	_refreshCorner: ()->
		corner = @get("corner")
		return unless corner
		cornerDom = corner.getDom()
		if cornerDom.parentNode isnt @_dom then @_dom.appendChild(cornerDom)

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

		labelDom = label.getDom()
		rightLabeled = labelPosition is "right"
		@_classNamePool.add(if rightLabeled then "right labeled" else "labeled")
		if rightLabeled then @_dom.appendChild(labelDom) else $(@_doms.input).before(labelDom)

		return

	_refreshButton: ()->
		actionButton = @get("actionButton")
		buttonPosition = @get("buttonPosition")
		@_classNamePool.remove("left action")
		@_classNamePool.remove("action")
		return unless actionButton
		btnDom = actionButton.getDom()
		leftAction = buttonPosition is "left"
		@_classNamePool.add(if leftAction then "left action" else "action")

		if leftAction then $(@_doms.input).before(btnDom) else @_dom.appendChild(btnDom)
		return

	_refreshIcon: ()->
		icon = @get("icon")
		iconPosition = @get("iconPosition")

		classNamePool = @_classNamePool

		classNamePool.remove("left icon")
		classNamePool.remove("icon")

		if icon
			@_doms.iconDom ?= document.createElement("i")
			iconDom = @_doms.iconDom
			$(iconDom).addClass("#{icon} icon")
			leftIcon = iconPosition is "left"
			classNamePool.add(if leftIcon then "left icon" else "icon")

			if leftIcon then $(@_doms.input).before(iconDom) else @_dom.appendChild(iconDom)
		else
			$(@_doms.iconDom).remove() if @_doms.iconDom

		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.prop("readOnly", @_finalReadOnly)
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

	_refreshInputValue: (value) ->
		$fly(@_doms.input).val(if value? then value + "" or "")
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		# 当需要根据绑定的数据模型确定readOnly状态时，此处的逻辑会变的更复杂
		@_finalReadOnly = !!@get("readOnly")

		@_refreshIcon()
		@_refreshButton()
		@_refreshCorner()
		@_refreshLabel()
		@_refreshInput()
		return

	focus: () ->
		@_doms.input?.focus();
		return

class cola.Input extends cola.AbstractInput
	@tagName: "c-input"
	@CLASS_NAME: "input"

	@attributes:
		displayFormat: null
		inputFormat: null
		inputType:
			defaultValue: "text"
		postOnInput:
			type: "boolean"
			defaultValue: false

	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null

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
		doPost = ()=>
			readOnly = @_readOnly
			if !readOnly
				value = $(@_doms.input).val()
				dataType = @_dataType
				if dataType
					if @_inputType == "text"
						inputFormat = @_inputFormat
						if dataType instanceof cola.DateDataType
							inputFormat ?= DEFAULT_DATE_INPUT_FORMAT
							value = inputFormat + "||" + value
					value = dataType.parse(value)
				@set("value", value)
			return

		$(@_doms.input).on("change", ()=>
			doPost()
			return
		).on("focus", ()=>
			@_inputFocused = true
			@_refreshInputValue(@_value)
			@addClass("focused") if not @_finalReadOnly
			@fire("focus", @)
			return
		).on("blur", ()=>
			@_inputFocused = false
			@removeClass("focused")
			@_refreshInputValue(@_value)
			@fire("blur", @)

			if not @_value? or @_value is "" and @_bindInfo?.writeable
				propertyDef = @getBindingProperty()
				if propertyDef?._required and propertyDef._validators
					entity = @_scope.get(@_bindInfo.entityPath)
					entity.validate(@_bindInfo.property) if entity
			return
		).on("input", ()=>
			if @_postOnInput then doPost()
			return
		).on("keydown", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altKey: event.altKey
				event: event
			@fire("keyDown", @, arg)
		).on("keypress", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altKey: event.altKey
				event: event
			if @fire("keyPress", @, arg)== false then return

			if event.keyCode is 13 && isIE11 then doPost()

		)
		return

	_refreshInputValue: (value) ->
		inputType = @_inputType
		if inputType == "text"
			format = if @_inputFocused then @_inputFormat else @_displayFormat
			if typeof value == "number"
				if format
					value = formatNumber(format, value)
			else if value instanceof Date
				if not format
					format = if @_inputFocused then DEFAULT_DATE_INPUT_FORMAT else DEFAULT_DATE_DISPLAY_FORMAT
				value = (new XDate(value)).toString(format)
		else
			if value instanceof Date
				if inputType is "date"
					format = DEFAULT_DATE_DISPLAY_FORMAT
				else if inputType is "time"
					format = DEFAULT_TIME_DISPLAY_FORMAT
				else
					format = ISO_FORMAT_STRING
				value = (new XDate(value)).toString(format)
		return super(value)

cola.registerWidget(cola.Input)