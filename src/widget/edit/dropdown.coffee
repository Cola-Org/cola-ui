dropdownDialogMargin = 0

cola.findDropDown = (target) ->
	if target instanceof cola.Widget
		target = target.getDom()
	while target
		if $fly(target).hasClass("drop-container")
			dropContainer = cola.widget(target)
			return dropContainer?._dropdown
		target = target.parentNode
	return

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
					items = items.split(/[\,,\;]/)
					for item, i in items
						index = item.indexOf("=")
						if index > 0
							items[i] = {
								name: item.substring(0, index)
								value: item.substring(index + 1)
							}

				@_items = items
				unless @_itemsTimestamp == items?.timestamp
					if items then @_itemsTimestamp = items.timestamp
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
		beforeOpen: null
		open: null
		close: null
		selectData: null

	_initDom: (dom) ->
		super(dom)
		$fly(@_doms.input).xInsertAfter({
			tagName: "div"
			class: "value-content"
			contextKey: "valueContent"
		}, @_doms)

		$fly(dom).delegate(">.icon", "click", () =>
			if @_opened
				@close()
			else
				if @_disabled then return
				@open()
			return
		)

		valueContent = @_doms.valueContent
		$(@_doms.input).on("focus", () ->
			$fly(valueContent).addClass("placeholder")
			return
		).on("blur", () ->
			$fly(valueContent).removeClass("placeholder")
			return
		)

		unless @_skipSetIcon
			unless @_icon then @set("icon", "dropdown")
		return

	_parseDom: (dom)->
		return unless dom
		super(dom)
		@_parseTemplates()

		if !@_icon
			child = @_doms.input.nextSibling
			while child
				if child.nodeType == 1 and child.nodeName != "TEMPLATE"
					@_skipSetIcon = true
					break
				child = child.nextSibling

		return

	_createEditorDom: () ->
		dropdown=@
		return $.xCreate(
			tagName: "input"
			type: "text"
			click: (evt) =>
				if dropdown._disabled then return;
				if @_openOnActive
					if @_opened
						input = evt.target
						if input.readOnly then @close()
					else
						@open()
				return
			input: (evt) =>
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
		$inputDom.prop("readOnly", @_finalReadOnly or @_isEditorReadOnly())
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		@_setValueContent()
		return

	_setValue: (value) ->
		if not @_skipFindCurrentItem
			if not @_itemsIndex
				if @_items and value and @_valueProperty
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
		input = @_doms.input
		input.value = ""
		item = @_currentItem
		if not item?
			if not @_textProperty
				item = @_value
			else
				item = {}
				item[@_textProperty] = @_value

		if item
			input.placeholder = ""

			elementAttrBinding = @_elementAttrBindings?["items"]
			alias = elementAttrBinding?.expression.alias or "item"

			currentItemScope = @_currentItemScope
			if currentItemScope and currentItemScope.data.alias != alias
				currentItemScope = null

			if !currentItemScope
				@_currentItemScope = currentItemScope = new cola.ItemScope(@_scope, alias)
			currentItemScope.data.setTargetData(item)

			valueContent = @_doms.valueContent
			if !valueContent._inited
				valueContent._inited = true
				ctx =
					defaultPath: alias
				@_initValueContent(valueContent, ctx)
				cola.xRender(valueContent, currentItemScope, ctx)
			$fly(valueContent).show()
		else
			input.placeholder = @_placeholder or ""
			$fly(@_doms.valueContent).hide()
		return

	_initValueContent: (valueContent, context) ->
		property = @_textProperty or @_valueProperty
		if  property
			context.defaultPath += "." + property

		template = @getTemplate("value-content")
		if template
			if template instanceof Array
				for t in template
					valueContent.appendChild(t)
			else
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

	_getContainer: () ->
		if @_dropdownLayer
			layer = @_dropdownLayer
			if not (layer instanceof cola.Widget)
				layer = cola.widget(layer)
				if layer instanceof cola.Widget
					@set("dropdownLayer", layer)
				else
					layer = null
			if layer
				layer.on("beforeHide", () =>
					$fly(@_dom).removeClass("opened")
					return
				, true).on("hide", () =>
					@_opened = false
					return
				, true);
			return layer
		else
			return @_container if @_container

			@_finalOpenMode = openMode = @_getFinalOpenMode()

			config =
				class: "drop-container"
				dom: $.xCreate(
					tagName: "div"
					content: @_getDropdownContent()
				)
				beforeHide: () =>
					$fly(@_dom).removeClass("opened")
					return
				hide: () =>
					@_opened = false
					return

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

				ctx = {}
				titleContent = cola.xRender({
					tagName: "div"
					class: "box"
					content:
						tagName: "div"
						"c-widget":
							$type: "titleBar"
							items: [
								icon: "chevron left"
								click: () => @close()
							]
				}, @_scope, ctx)
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
		return if @fire("beforeOpen", @) == false

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

			if container instanceof DropBox
				container.show(@, doCallback)
			else if container instanceof cola.Layer
				container.show(doCallback)
			else if container instanceof cola.Sidebar
				container.show(doCallback)
			else if container instanceof cola.Dialog
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

				container.show(doCallback)
			@_opened = true
			$fly(@_dom).addClass("opened")
		return

	close: (selectedData, callback) ->
		if selectedData != undefined
			@_selectData(selectedData)

		container = @_getContainer()
		if container
			container.hide(callback)
		return

	_selectData: (item) ->
		if @_valueProperty and item
			if item instanceof cola.Entity
				value = item.get(@_valueProperty)
			else
				value = item[@_valueProperty]
		else
			value = item

		@_currentItem = item
		@_skipFindCurrentItem = true
		@set("value", value)
		@fire("selectData", @, { data: item })
		@_skipFindCurrentItem = false
		@refresh()
		return

cola.Element.mixin(cola.AbstractDropdown, cola.TemplateSupport)

class DropBox extends cola.Layer
	@CLASS_NAME: "drop-box transition"
	@attributes:
		dropdown: null

	show: (options, callback) ->
		$dom = @get$Dom()
		dropdownDom = @_dropdown._doms.input

		$dom.css("height", "").removeClass("hidden")
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
			.css("max-width",document.body.clientWidth)

		@_animation = "fade"

		super(options, callback)

		return

	_onShow: () ->
		super()
		@_bodyListener = (evt) =>
			target = evt.target
			dropdownDom = @_dropdown._dom
			dropContainerDom = @_dom
			while target
				if target == dropdownDom or target == dropContainerDom
					inDropdown = true
					break
				target = target.parentNode

			if !inDropdown
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
				tagName: "div"
				contextKey: "list"
				"c-widget": "listView"
				style: "height:100%;overflow:auto"

		"filterable-list":
			tagName: "div"
			class: "v-box",
			style: "height:100%"
			content: [
				{
					tagName: "div"
					class: "box filter-container"
					content:
						tagName: "div"
						contextKey: "filterInput"
						"c-widget": "input;icon:search;width:100%"
				}
				{
					tagName: "div"
					contextKey: "flexContent"
					class: "flex-box list-container"
					style: "min-height:2em"
					content:
						tagName: "div"
						contextKey: "list"
						"c-widget": "listView"
				}
			]

	_initValueContent: (valueContent, context) ->
		super(valueContent, context)
		if !valueContent.firstChild
			template = @getTemplate()
			if template
				valueContent.appendChild(@_cloneTemplate(template))
		return
		
	_initDom:(dom)->
		@_regDefaultTempaltes()
		super(dom)

	open: () ->
		super()
		list = @_list
		if list and @_currentItem isnt list.get("currentItem")
			list.set("currentItem", @_currentItem)

		if @_opened and @_filterable
			inputDom = @_doms.input
			$fly(inputDom).on("input.filterItem", () => @_onInput(inputDom.value))
		return

	close: (selectedValue) ->
		if @_filterable
			$fly(@_doms.input).off("input.filterItem")
		return super(selectedValue)

	_onInput: (value) ->
		cola.util.delay(@, "filterItems", 300, () ->
			@_list.set("filterCriteria", value)
			return
		)
		return

	_getDropdownContent: () ->
		if !@_dropdownContent
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
						if name == "default" then hasDefaultTemplate = true
						list.regTemplate(name, templ)
			if !hasDefaultTemplate
				list.regTemplate("default", {
					tagName: "li"
					"c-bind": "$default"
				})

			list.on("itemClick", () => @close(list.get("currentItem")))

			if @_doms.filterInput
				@_filterInput = cola.widget(@_doms.filterInput)
				inputDom = @_filterInput._doms.input
				$fly(inputDom).on("input", () => @_onInput(inputDom.value))

		attrBinding = @_elementAttrBindings?["items"]
		list = @_list
		list._textProperty = @_textProperty or @_valueProperty
		if attrBinding
			list.set("bind", attrBinding.expression.raw)
		else
			list.set("items", @_items)
		list.refresh()
		return template

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
		return true

	_getDropdownContent: () ->
		if !@_dropdownContent
			if @_content
				dropdownContent = @_content
			else
				dropdownContent = @getTemplate()
			@_dropdownContent = cola.xRender(dropdownContent, @_scope)
		return @_dropdownContent

cola.registerWidget(cola.CustomDropdown)