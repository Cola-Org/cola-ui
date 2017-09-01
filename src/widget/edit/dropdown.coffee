dropdownDialogMargin = 0

cola.findDropDown = (target) ->
	layer = cola.findWidget(target, cola.AbstractLayer)
	while layer and not layer.hasClass("drop-container")
		layer = cola.findWidget(layer, cola.AbstractLayer)
	return layer?._dropdown

class cola.AbstractDropdown extends cola.AbstractInput
	@CLASS_NAME: "input drop"

	@attributes:
		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false
		items:
			expressionType: "repeat"
			setter: (items) ->
				if typeof items is "string"
					items = items.split(/[,;]/)
					for item, i in items
						index = item.indexOf("=")
						if index >= 0
							items[i] =
								key: item.substring(0, index)
								value: item.substring(index + 1)

				if not @_valueProperty and not @_textProperty
					result = cola.util.decideValueProperty(items)
					if result
						@_valueProperty = result.valueProperty
						@_textProperty = result.textProperty

				changed = @_items isnt items or @_itemsTimestamp isnt items?.timestamp

				@_items = items
				if changed
					if items?.timestamp
						@_itemsTimestamp = items.timestamp
					delete @_itemsIndex
				return
		currentItem:
			readOnly: true

		valueProperty: null
		textProperty: null

		openOnActive:
			type: "boolean"
			defaultValue: true
		openMode:
			enum: ["auto", "drop", "dialog", "layer", "sidebar"]
			defaultValue: "auto"
		opened:
			readOnly: true

		dropdownLayer: null
		dropdownWidth: null
		dropdownHeight: null

	@events:
		initDropdownBox: null
		beforeOpen: null
		open: null
		close: null
		selectData: null
		focus: null
		blur: null
		keyDown: null
		keyPress: null
		input:null

	_initDom: (dom) ->
		super(dom)

		if @_useValueContent
			$fly(@_doms.input).xInsertAfter({
				tagName: "div"
				class: "value-content"
				contextKey: "valueContent"
			}, @_doms)

		$fly(dom)
			.attr("tabIndex", 1)
			.delegate(">.icon", "click", () =>
				if  @_finalReadOnly and not @_disabled and not @_opened
					@open()
					return
				if @_opened
					@close()

				else
					if @_disabled then return
					@open()
				return
			).on("keydown", (evt)=>
				arg =
					keyCode: evt.keyCode
					shiftKey: evt.shiftKey
					ctrlKey: evt.ctrlKey
					altKey: evt.altKey
					event: evt
					inputValue: @_doms.input.value


				@fire("keyDown", @, arg)
				if evt.keyCode is 9 then @_closeDropdown()


				if @?_onKeyDown(evt) isnt false and @_dropdownContent
					$(@_dropdownContent).trigger(evt)
				return
			).on("keypress", (evt)=>
				arg =
					keyCode: evt.keyCode
					shiftKey: evt.shiftKey
					ctrlKey: evt.ctrlKey
					altKey: evt.altKey
					event: evt
					inputValue: @_doms.input.value
				if @fire("keyPress", @, arg) == false then return
			)

		$(@_doms.input)
			.on("focus", () => @_doFocus())
			.on("blur", () => @_doBlur())
			.on("input", (evt) =>
				arg =
					event: evt
					inputValue: @_doms.input.value
				@fire("input", @, arg)
			)
			.on("keypress", () => @_inputEdited = true)

		unless @_skipSetIcon
			unless @_icon then @set("icon", "dropdown")

		if @_items and @_valueProperty then @_setValue(@_value)
		return

	_doBlur: ()->
		@fire("blur", @, {})
		return

	_doFocus: ()->
		@_inputEdited = false
		@fire("focus", @, {})
		return

	_parseDom: (dom)->
		return unless dom
		super(dom)
		@_parseTemplates()

		if not @_icon
			child = @_doms.input.nextSibling
			while child
				if child.nodeType is 1 and child.nodeName isnt "TEMPLATE"
					@_skipSetIcon = true
					break
				child = child.nextSibling
		return

	_createEditorDom: () ->
		return $.xCreate(
			tagName: "input"
			type: "text"
			click: (evt) =>
				if @_disabled then return;
				if @_openOnActive
					if @_opened
						input = evt.target
						if input.readOnly then @close()
					else
						@open()
				this.focus();

			input: (evt) =>
				if @_useValueContent
					$valueContent = $fly(@_doms.valueContent)
					if evt.target.value
						$valueContent.hide()
					else
						$valueContent.show()
				return
		)

	_isEditorDom: (node) ->
		return node.nodeName is "INPUT"

	_isEditorReadOnly: () ->
		return cola.device.mobile

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.prop("readonly", @_finalReadOnly or @_isEditorReadOnly() or @_disabled)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		@_setValueContent()
		return

	_setValue: (value) ->
		if @_dom and not @_skipFindCurrentItem
			if not @_itemsIndex
				if @_items and @_valueProperty
					@_itemsIndex = index = {}
					valueProperty = @_valueProperty
					cola.each @_items, (item) ->
						if item instanceof cola.Entity
							key = item.get(valueProperty)
						else
							key = item[valueProperty]
						index[key + ""] = item
						return
					currentItem = index[value + ""]
			else
				currentItem = @_itemsIndex[value + ""]
			@_currentItem = currentItem

		return super(value)

	_setValueContent: () ->
		item = @_currentItem
		if not item?
			if not @_textProperty
				item = @_value
			else
				item = {}
				item[@_textProperty] = @_value

		input = @_doms.input
		if item
			if @_useValueContent
				elementAttrBinding = @_elementAttrBindings?["items"]
				alias = elementAttrBinding?.expression.alias or "item"

				currentItemScope = @_currentItemScope
				if currentItemScope and currentItemScope.data.alias isnt alias
					currentItemScope = null

				if not currentItemScope
					@_currentItemScope = currentItemScope = new cola.ItemScope(@_scope, alias)
				currentItemScope.data.setItemData(item)

				valueContent = @_doms.valueContent
				if not valueContent._inited
					valueContent._inited = true
					ctx =
						defaultPath: alias
					@_initValueContent(valueContent, ctx)
					cola.xRender(valueContent, currentItemScope, ctx)
				$fly(valueContent).show()

			if item instanceof cola.Entity or (typeof item is "object" and not (item instanceof Date))
				text = cola.Entity._evalDataPath(item, @_textProperty or @_valueProperty)
			else
				text = item
			input.value = text or ""
			input.placeholder = ""
			@get$Dom().removeClass("placeholder")
		else
			input.value = ""
			input.placeholder = @_placeholder or ""
			@get$Dom().addClass("placeholder")

			if @_useValueContent
				$fly(@_doms.valueContent).hide()
		return

	_initValueContent: (valueContent, context) ->
		property = @_textProperty or @_valueProperty
		if property
			context.defaultPath += "." + property

		template = @getTemplate("value-content")
		if template
			valueContent.appendChild(template)
		return

	_getFinalOpenMode: () ->
		openMode = @_openMode
		if !openMode or openMode == "auto"
			if cola.device.desktop
				openMode = "drop"
			else if cola.device.phone
				openMode = "layer"
			else # pad
				openMode = "dialog"
		return openMode

	_getTitleContent: ()->
		return cola.xRender({
			tagName: "div"
			class: "box"
			content:
				tagName: "c-titlebar"
				content: [
					{
						tagName: "a"
						icon: "chevron left"
						click: () => @close()
					}
				]
		}, @_scope, {})

	_getContainer: () ->
		if @_container
			@_refreshDropdownContent?()
			return @_container
		else
			@_finalOpenMode = openMode = @_getFinalOpenMode()

			config =
				class: "drop-container"
				dom: $.xCreate(
					content: @_getDropdownContent()
				)
				beforeHide: () =>
					$fly(@_dom).removeClass("opened")
					return
				hide: () =>
					@_opened = false
					return
			@_dropdownContent = config.dom.firstChild

			config.width = @_dropdownWidth if @_dropdownWidth
			config.height = @_dropdownHeight if @_dropdownHeight

			if openMode is "drop"
				config.duration = 200
				config.dropdown = @
				config.ui = config.ui + " " + @_ui
				container = new DropBox(config)
			else if openMode is "layer"
				if openMode is "Sidebar"
					config.animation = "slide up"
					config.height = "50%"

				titleContent = @_getTitleContent()
				$fly(config.dom.firstChild.firstChild).before(titleContent)
				container = new cola.Layer(config)
			else if openMode is "sidebar"
				config.direction = "bottom"
				config.size = document.body.clientHeight / 2
				$fly(config.dom.firstChild.firstChild).before(titleContent)
				container = new cola.Sidebar(config)
			else if openMode is "dialog"
				config.modalOpacity = 0.05
				config.closeable = false
				config.dimmerClose = true
				container = new cola.Dialog(config)
			@_container = container

			container.appendTo(document.body)
			return container

	open: (callback) ->
		if @_finalReadOnly and @_disabled then return

		if @fire("beforeOpen", @) is false then return

		doCallback = () =>
			@fire("open", @)
			callback?()
			return

		container = @_getContainer()
		if container
			container._dropdown = @
			container.on("hide", (self) ->
				delete self._dropdown
				return
			)

			if container instanceof cola.Dialog
				$flexContent = $(@_doms.flexContent)
				$flexContent.height("")

				$containerDom = container.get$Dom()
				$containerDom.removeClass("hidden")
				containerHeight = $containerDom.height()

				clientHeight = document.body.clientHeight
				if containerHeight > (clientHeight - dropdownDialogMargin * 2)
					height = $flexContent.height() - (containerHeight - (clientHeight - dropdownDialogMargin * 2))
					$containerDom.addClass("hidden")
					$flexContent.height(height)
				else
					$containerDom.addClass("hidden")

			@fire("initDropdownBox", @, {dropdownBox: container})

			if container.constructor.events.$has("hide")
				container.on("hide:dropdown", () =>
					@fire("close", @)
					return
				, true)

			container.show?(doCallback)

			@_opened = true
			$fly(@_dom).addClass("opened")
			return true

		return

	close: (selectedData, callback) ->
		if selectedData isnt undefined
			@_selectData(selectedData)
		else if @_inputEdited
			@refresh()

		container = @_getContainer()
		container?.hide?(callback)
		return
	_closeDropdown:()->
		container = @_getContainer()
		container?.hide?()
	_getItemValue: (item) ->
		if @_valueProperty and item
			if item instanceof cola.Entity
				value = item.get(@_valueProperty)
			else
				value = item[@_valueProperty]
		else
			value = item
		return value

	_selectData: (item) ->
		@_inputEdited = false

		value = @_getItemValue(item)
		@_skipFindCurrentItem = true
		if @fire("selectData", @, {data: item}) isnt false
			@_currentItem = item
			@set("value", value)
		@_skipFindCurrentItem = false
		@refresh()
		return

	_doRefreshDom:() ->
		super()
		if not @_dom then return
		$(@_dom).toggleClass("disabled", @_disabled);

cola.Element.mixin(cola.AbstractDropdown, cola.TemplateSupport)

class DropBox extends cola.Layer
	@CLASS_NAME: "drop-box transition"
	@attributes:
		dropdown: null

	show: (options, callback) ->
		$dom = @get$Dom()
		dropdownDom = @_dropdown._doms.input
		unless @_height
			$dom.css("height", "")

		$dom.removeClass("hidden")
		boxWidth = $dom.width()
		boxHeight = $dom.height()
		$dom.addClass("hidden")

		rect = $fly(dropdownDom).offset()
		clientWidth = document.body.offsetWidth
		clientHeight = document.body.clientHeight
		scrollTop = document.body.scrollTop
		bottomSpace = Math.abs(clientHeight - rect.top - dropdownDom.clientHeight - scrollTop)

		if bottomSpace >= boxHeight
			direction = "down"
		else
			topSpace = rect.top - scrollTop
			if topSpace > bottomSpace
				direction = "up"
				if boxHeight > topSpace then height = topSpace
			else
				direction = "down"
				if boxHeight > bottomSpace then height = bottomSpace

		if direction == "down"
			top = rect.top + dropdownDom.clientHeight
		else
			top = rect.top - (height or boxHeight)

		left = rect.left
		if boxWidth > dropdownDom.offsetWidth
			if boxWidth + rect.left > clientWidth
				left = clientWidth - boxWidth
				if left < 0 then left = 0

		if height then $dom.css("height", height)
		$dom
		.removeClass(if direction == "down" then "direction-up" else "direction-down").addClass("direction-" + direction)
		.toggleClass("x-over", boxWidth > dropdownDom.offsetWidth)
		.css("left", left).css("top", top)
		.css("min-width", dropdownDom.offsetWidth)
		.css("max-width", document.body.clientWidth)

		@_animation = "fade"

		super(options, callback)

		return

	_onShow: () ->
		super()
		@_bodyListener = (evt) =>
			target = evt.target
			unless @_dropdown then return
			dropdownDom = @_dropdown._dom
			dropContainerDom = @_dom
			while target
				if target == dropdownDom or target == dropContainerDom
					inDropdown = true
					break
				target = target.parentNode

			if not inDropdown
				@_dropdown.close()
			return
		$fly(document.body).on("click", @_bodyListener)
		return

	hide: (options, callback) ->
		$fly(document.body).off("click", @_bodyListener)
		super(options, callback)
		return

class cola.Dropdown extends cola.AbstractDropdown
	@tagName: "c-dropdown"

	@attributes:
		filterable:
			readOnlyAfterCreate: true
			defaultValue: true
		filterValue:
			readOnly: true
		filterProperty: null
		filterInterval:
			defaultValue: 300

	@events:
		filterItem: null

	@TEMPLATES:
		"default":
			tagName: "li"
			"c-bind": "$default"
		"list":
			tagName: "div"
			contextKey: "flexContent"
			content:
				tagName: "c-listview"
				contextKey: "list"
				allowNoCurrent: false
				changeCurrentItem: false
				highlightCurrentItem: true
				style: "overflow:auto"
			keydown: (evt) ->
				if not @_disableKeyBubble
					@_disableKeyBubble = true
					$fly(@).find(">c-listview").trigger(evt)
					@_disableKeyBubble = false
				return true

		"filterable-list":
			tagName: "div"
			class: "v-box"
			content: [
				{
					tagName: "div"
					class: "box filter-container"
					content:
						tagName: "c-input"
						contextKey: "input"
						class: "fluid"
						icon: "search"
				}
				{
					tagName: "div"
					contextKey: "flexContent"
					class: "flex-box list-container"
					style: "min-height:2em"
					content:
						tagName: "c-listview"
						contextKey: "list"
						allowNoCurrent: false
						changeCurrentItem: false
						highlightCurrentItem: true
				}
			]
			keydown: (evt) ->
				if not @_disableKeyBubble
					@_disableKeyBubble = true
					$fly(@).find(">.flex-box >c-listview").trigger(evt)
					@_disableKeyBubble = false
				return true

	_initDom: (dom)->
		if @_filterable then $fly(dom).addClass("filterable")
		@_regDefaultTemplates()

		inputDom = @_doms.input
		$fly(inputDom).on("input", () => @_onInput(inputDom.value))

		super(dom)

	open: () ->
		if super()
			list = @_list
			if list and @_currentItem isnt list.get("currentItem")
				list.set("currentItem", @_currentItem)

			if @_opened and @_filterable
				if @_list.get("filterCriteria") isnt null
					@_list.set("filterCriteria", null).refresh()
			return true
		return

	_onInput: (value) ->
		@_inputDirty = true
		cola.util.delay(@, "filterItems", 150, () ->
			return unless @_list

			criteria = value
			if @_opened and @_filterable
				filterProperty = @_filterProperty or @_textProperty
				if not value
					if filterProperty
						criteria = {}
						criteria[filterProperty] = value
				@_list.set("filterCriteria", criteria).refresh()

			items = @_list.getItems()

			currentItemDom = null

			if @_filterable
				if value isnt null
					exactlyMatch
					firstItem = items[0]
					if firstItem
						if filterProperty
							exactlyMatch = cola.Entity._evalDataPath(firstItem, filterProperty) is value
						else
							exactlyMatch = firstItem is value
					if exactlyMatch
						currentItemDom = @_list._getFirstItemDom()

				@_list._setCurrentItemDom(currentItemDom)
			else
				item = cola.util.find(items, criteria)
				if item
					entityId = cola.Entity._getEntityId(item)
					if entityId
						@_list.set("currentItem", item)
					else
						@_list._setCurrentItemDom(currentItemDom)
				else
					@_list._setCurrentItemDom(null)

			return
		)
		return

	_onKeyDown: (evt) ->
		if evt.keyCode is 13 # Enter
			@close(@_list?.get("currentItem") or null)
			return false
		else if evt.keyCode is 27 # ESC
			@close(@_currentItem or null)
		return

	_selectData: (item) ->
		@_inputDirty = false
		return super(item)

	_doBlur: ()->
		if @_inputDirty
			@close(@_list?.get("currentItem") or null)
		return super()

	_getDropdownContent: () ->
		if not @_dropdownContent
			if @_filterable and @_finalOpenMode isnt "drop"
				templateName = "filterable-list"
			else
				templateName = "list"
			template = @getTemplate(templateName)
			@_dropdownContent = template = cola.xRender(template, @_scope)

			@_list = list = cola.widget(@_doms.list)
			if @_templates
				for name, templ of @_templates
					if ["list", "filterable-list", "value-content"].indexOf(name) < 0
						if name is "default" then hasDefaultTemplate = true
						list.regTemplate(name, templ)
			if not hasDefaultTemplate
				list.regTemplate("default", {
					tagName: "li"
					"c-bind": "$default"
				})

			list.on("itemClick", () => @close(list.get("currentItem")))

		@_refreshDropdownContent?()
		return template

	_refreshDropdownContent: () ->
		attrBinding = @_elementAttrBindings?["items"]
		list = @_list
		list._textProperty = @_textProperty or @_valueProperty
		if attrBinding
			list.set("bind", attrBinding.expression.raw)
		else
			list.set("items", @_items)
		list.refresh()

cola.registerWidget(cola.Dropdown)

class cola.CustomDropdown extends cola.AbstractDropdown
	@tagName: "c-customDropdown"

	@attributes:
		content: null

	@TEMPLATES:
		"default":
			tagName: "div"
			content: "<Undefined>"
		"value-content":
			tagName: "div"
			"c-bind": "$default"

	_isEditorReadOnly: () ->
		return false

	_getDropdownContent: () ->
		if not @_dropdownContent
			if @_content
				dropdownContent = @_content
			else
				dropdownContent = @getTemplate()
			@_dropdownContent = cola.xRender(dropdownContent, @_scope)
		return @_dropdownContent

cola.registerWidget(cola.CustomDropdown)
cola.DropBox = DropBox