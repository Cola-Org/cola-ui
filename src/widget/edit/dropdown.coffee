dropdownDialogMargin = 0

cola.findDropDown = (target)->
	layer = cola.findWidget(target, cola.AbstractLayer, true)
	while layer and not layer._dropdown
		layer = cola.findWidget(layer, cola.AbstractLayer, true)
	return layer?._dropdown

class cola.AbstractDropdown extends cola.AbstractInput
	@className: "input drop"

	@attributes:
		items:
			refreshDom: true
			expressionType: "repeat"
		#			expressionNegative: true
			setter: (items)->
				if typeof items is "string"
					items = items.split(/[,;]/)
					for item, i in items
						pos = item.indexOf("=")
						if pos >= 0
							items[i] =
								key: item.substring(0, pos)
								value: item.substring(pos + 1)
							if not @_valueProperty and not @_textProperty
								@_valueProperty = "key"
								@_textProperty = "value"

				if not @_acceptUnknownValue and not @_valueProperty and not @_textProperty
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

					if @_value isnt undefined and items
						@_setValue(@_value)
				return
		currentItem:
			readOnly: true

		valueProperty: null
		textProperty: null
		assignment: null
		editable:
			type: "boolean"
			defaultValue: true
		showClearButton:
			type: "boolean"
			defaultValue: true
		openOnActive:
			type: "boolean"
			defaultValue: true
		openMode:
			enum: [ "auto", "drop", "dialog", "layer", "sidebar" ]
			defaultValue: "auto"
		opened:
			readOnly: true

		dropdownLayer: null
		dropdownWidth: null
		dropdownHeight: null
		dropdownTitle: null

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
		input: null

	_initDom: (dom)->
		super(dom)

		if @getTemplate("value-content")
			@_useValueContent = true

		if @_useValueContent
			@_doms.input.value = ""
			$fly(@_doms.input).xInsertAfter({
				tagName: "div"
				class: "value-content"
				contextKey: "valueContent"
			}, @_doms)

		$fly(dom).delegate(">.icon.drop", "click", ()=>
			if @_opened
				if new Date() - @_openTimestamp > 300
					@close()
			else if not @_finalReadOnly
				@open()
			return false
		).on("keypress", (evt)=>
			arg =
				keyCode: evt.keyCode
				shiftKey: evt.shiftKey
				ctrlKey: evt.ctrlKey
				altKey: evt.altKey
				event: evt
				inputValue: @_doms.input.value
			if @fire("keyPress", @, arg) is false
				return false
		).on("mouseenter", (evt)=>
			if @_showClearButton
				clearButton = @_doms.clearButton
				if not clearButton
					@_doms.clearButton = clearButton = $.xCreate({
						tagName: "i"
						class: "icon remove"
						mousedown: ()=>
							@_selectData(null)
							return false
					})
					dom.appendChild(clearButton)

				$fly(clearButton).toggleClass("disabled", !@_doms.input.value)
		)

		$(@_doms.input).on("input", (evt)=>
			value = @_doms.input.value
			arg =
				event: evt
				inputValue: value
			@fire("input", @, arg)
		).on("keypress", ()=> @_inputEdited = true)

		unless @_skipSetIcon
			unless @_icon then @set("icon", "dropdown")

		if @_setValueOnInitDom and @_value isnt undefined
			delete @_setValueOnInitDom
			@_setValue(@_value)
		return

	_onFocus: ()->
		@_inputEdited = false
		super()
		if @_openOnActive and not @_opened and not @_finalReadOnly
			@open()
		if @_useValueContent
			@_showValueTipIfNecessary()
		return

	_onBlur: ()->
		if @_opened and @_finalOpenMode is "drop"
			@close()
		super()
		@_doms.tipDom and cola.util.cacheDom(@_doms.tipDom)
		return

	_onKeyDown: (evt)->
		if evt.keyCode is 27 # ESC
			@close()
		return

	_showValueTipIfNecessary: ()->
		if @_useValueContent and @_doms.valueContent
			valueContent = @_doms.valueContent
			if valueContent.scrollWidth > valueContent.clientWidth
				tipDom = @_doms.tipDom
				if not tipDom
					@_doms.tipDom = tipDom = cola.xCreate({
						class: "dropdown-value-tip"
					})
				if tipDom isnt document.body
					document.body.appendChild(tipDom)

				tipDom.innerHTML = @_doms.valueContent.innerHTML
				rect = $fly(@_dom).offset()
				$fly(tipDom).css(
					left: rect.left + @_dom.offsetWidth / 2
					top: rect.top
					minWidth: @_dom.offsetWidth
				)
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

	_createEditorDom: ()->
		return $.xCreate(
			tagName: "input"
			type: "text"
			click: ()=> this.focus()
		)

	_isEditorDom: (node)->
		return node.nodeName is "INPUT"

	_isEditorReadOnly: ()->
		return not @_editable or (@_filterable and @_useValueContent)

	_refreshIcon: ()->
		super()
		if @_doms.iconDom
			$fly(@_doms.iconDom).addClass("drop")
		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.attr("readOnly", @_finalReadOnly or @_isEditorReadOnly() or null)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		@_setValueContent()
		return

	_setValue: (value)->
		if value isnt undefined
			if not @_dom
				@_setValueOnInitDom = true
			else if not @_skipFindCurrentItem and @_valueProperty
				if not @_items
					attrBinding = @_elementAttrBindings?["items"]
					if attrBinding and @_valueProperty
						@_refreshAttrValue("items")

				if @_items
					if not @_itemsIndex
						if @_items instanceof cola.EntityList
							@_itemsIndex = cola.util.buildIndex(@_items, @_valueProperty)
						else
							@_itemsIndex = index = {}
							valueProperty = @_valueProperty
							cola.each @_items, (item)->
								if item instanceof cola.Entity
									key = item.get(valueProperty)
								else
									key = item[valueProperty]
								index[key + ""] = item
								return

					if @_itemsIndex
						if @_itemsIndex instanceof cola.EntityIndex
							currentItem = @_itemsIndex.find(value)
						else
							currentItem = @_itemsIndex[value + ""]
					@_currentItem = currentItem
				else
					item = @_currentItem = {
						$emptyItem: true
					}
					item[@_valueProperty] = value
					item[@_textProperty] = value
		else
			@_currentItem = {
				$emptyItem: true
			}
		return super(value)

	_setValueContent: ()->
		item = @_currentItem
		if not item?
			if not @_textProperty
				item = @_value
			else
				item = {
					$emptyItem: true
				}
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

			else
				property = @_textProperty or @_valueProperty
				if property
					if item instanceof cola.Entity
						text = cola.Entity._evalDataPath(item, property or "value")
					else if typeof item is "object" and not (item instanceof Date)
						if item.hasOwnProperty(property)
							text = item[property]
						else
							text = cola.Entity._evalDataPath(item, property or "value")
					else
						text = item
					input.value = text or ""
				else
					text = @readBindingValue()
					input.value = text or ""
		else
			if not @_useValueContent
				text = @readBindingValue()
				input.value = text or ""

			if @_useValueContent
				$fly(@_doms.valueContent).hide()

		if item and not item.$emptyItem
			input.placeholder = ""
			@get$Dom().removeClass("placeholder")
		else
			input.placeholder = @_placeholder or ""
			@get$Dom().addClass("placeholder")

		if @_focused and @_useValueContent
			@_showValueTipIfNecessary()
		return

	_initValueContent: (valueContent, context)->
		property = @_textProperty or @_valueProperty or "value"
		if property
			context.defaultPath += "." + property

		template = @getTemplate("value-content")
		if template
			valueContent.appendChild(template)
		return

	_getFinalOpenMode: ()->
		openMode = @_openMode
		if !openMode or openMode is "auto"
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
						click: ()=> @close()
					}
				]
		}, @_scope, {})

	_getContainer: (dontCreate)->
		if @_container
			@_dontRefreshItems = true
			@_refreshDropdownContent?()
			delete @_dontRefreshItems
			return @_container

		else if not dontCreate
			@_finalOpenMode = openMode = @_getFinalOpenMode()

			config =
				class: "drop-container"
				dom: $.xCreate(
					content: @_getDropdownContent()
				)
				beforeHide: ()=>
					$fly(@_dom).removeClass("opened")
					return
				hide: ()=>
					@_opened = false
					return
			@_dropdownContent = config.dom.firstChild

			config.width = @_dropdownWidth if @_dropdownWidth
			config.height = @_dropdownHeight if @_dropdownHeight

			if openMode is "drop"
				config.duration = 200
				config.dropdown = @
				config.class = @_class
				container = new cola.DropBox(config)
			else if openMode is "layer"
				if openMode is "sidebar"
					config.animation = "slide up"
					config.height = "50%"

				titleContent = @_getTitleContent()
				$fly(config.dom.firstChild.firstChild).before(titleContent)
				container = new cola.Layer(config)
			else if openMode is "sidebar"
				config.direction = "bottom"
				config.size = document.documentElement.clientHeight / 2
				$fly(config.dom.firstChild.firstChild).before(titleContent)
				container = new cola.Sidebar(config)
			else if openMode is "dialog"
				config.modalOpacity = 0.05
				config.closeable = false
				config.dimmerClose = true
				if not config.width then config.width = "80%"
				if not config.height then config.height = "80%"

				if @_dropdownTitle
					config.dom = $.xCreate(
						content: [
							{
								class: "header"
								content: @_dropdownTitle
							}
							{
								class: "content"
								content: config.dom
							}
						]
					)

				container = new cola.Dialog(config)
			@_container = container

			container.appendTo(document.body)
			return container
		return

	open: (callback)->
		if @_finalReadOnly then return
		if @fire("beforeOpen", @) is false then return

		doCallback = ()=>
			@fire("open", @)
			cola.callback(callback, true)
			return

		container = @_getContainer()
		if container
			container._dropdown = @
			container._focusParent = @
			container.on("hide", (self)->
				delete self._dropdown
				return
			)

			if container instanceof cola.Dialog
				$flexContent = $(@_doms.flexContent)
				$flexContent.height("")

				$containerDom = container.get$Dom()
				$containerDom.removeClass("hidden")
				containerHeight = $containerDom.height()

				clientHeight = document.documentElement.clientHeight
				if containerHeight > (clientHeight - dropdownDialogMargin * 2)
					height = $flexContent.height() - (containerHeight - (clientHeight - dropdownDialogMargin * 2))
					$containerDom.addClass("hidden")
					$flexContent.height(height)
				else
					$containerDom.addClass("hidden")

			@fire("initDropdownBox", @, { dropdownBox: container })

			if container.constructor.events.$has("hide")
				container.on("hide:dropdown", ()=>
					@fire("close", @)
					return
				, true)

			container.show?(doCallback)

			@_opened = true
			@_openTimestamp = new Date()
			$fly(@_dom).addClass("opened")

			if @_filterable and @_useValueContent
				@_refreshInputValue(null)
			return true
		return

	close: (selectedData, callback)->
		if selectedData isnt undefined
			@_selectData(selectedData)
		else if @_inputEdited
			if @_acceptUnknownValue
				@set("value", @_doms.input.value)
				@post()
			else
				@refresh()

		container = @_getContainer(true)
		container?.hide?(callback)
		return

	_getItemValue: (item)->
		if @_valueProperty and item
			if item instanceof cola.Entity
				value = item.get(@_valueProperty)
			else
				value = item[@_valueProperty]
		else
			value = item
		return value

	_selectData: (item)->
		@_inputEdited = false

		@_skipFindCurrentItem = true
		if @fire("selectData", @, { data: item }) isnt false
			@_currentItem = item
			if @_assignment and @_bindInfo?.writeable

				if @_valueProperty or @_textProperty
					prop = @_valueProperty or @_textProperty
					if item
						if item instanceof cola.Entity
							value = item.get(prop)
						else
							value = item[prop]
					else
						value = null
				arg = { oldValue: @_value, value: value }

				if @fire("beforeChange", @, arg) is false
					@refreshValue()
					return

				if @fire("beforePost", @, arg) is false
					@refreshValue()
					return

				bindEntity = @_scope.get(@_bindInfo.entityPath)
				@_assignment.split(/[,;]/).forEach((part)=>
					pair = part.split("=")
					targetProp = pair[0]
					if targetProp
						sourceProp = pair[1] or targetProp
						if item
							if item instanceof cola.Entity
								value = item.get(sourceProp)
							else
								value = item[sourceProp]
						else
							value = null
						bindEntity.set(targetProp, value)
					return
				)

				@fire("change", @, arg)
				@fire("post", @)
			else
				value = @_getItemValue(item)
				@set("value", value)

		@_skipFindCurrentItem = false
		@refresh()
		return

cola.Element.mixin(cola.AbstractDropdown, cola.TemplateSupport)

class cola.DropBox extends cola.Layer
	@tagName: "c-drop-box"
	@className: "drop-box transition"
	@attributes:
		height:
			setter: (height)->
				@_maxHeight = height
				return
		dropdown: null

		focusable:
			defaultValue: true

	resize: (opened)->
		dom = @getDom()
		$dom = @get$Dom()
		dropdownDom = @_dropdown._doms.input
		if not cola.util.isVisible(dropdownDom)
			@hide()
			return

		# 防止因改变高度导致滚动条自动还原到初始位置
		if opened
			boxWidth = dom.offsetWidth
			boxHeight = dom.offsetHeight
		else
			if @_maxHeight
				$dom.css("max-height", @_maxHeight)
			$dom.css("height", "")

			$dom.removeClass("hidden")
			boxWidth = $dom.width()
			boxHeight = $dom.height()
			$dom.addClass("hidden")

		rect = $fly(dropdownDom).offset()
		clientWidth = document.documentElement.clientWidth - 6
		clientHeight = document.documentElement.clientHeight - 6
		bottomSpace = Math.abs(document.documentElement.scrollTop + clientHeight - rect.top - dropdownDom.clientHeight)

		if bottomSpace >= boxHeight
			direction = "down"
		else
			topSpace = rect.top - document.documentElement.scrollTop - 6
			if topSpace > bottomSpace
				direction = "up"
				if boxHeight > topSpace then height = topSpace
			else
				direction = "down"
				if boxHeight > bottomSpace then height = bottomSpace

		if opened
			if height
				$dom.css("height", height)
			else
				if dom.firstElementChild is dom.lastElementChild
					if dom.firstElementChild.offsetHeight < dom.clientHeight
						$dom.css("height", "auto")

			if direction is "down"
				top = rect.top + dropdownDom.clientHeight
			else
				top = rect.top - dom.offsetHeight + 2

		left = rect.left
		if boxWidth > dropdownDom.offsetWidth
			if boxWidth + rect.left > clientWidth
				left = clientWidth - boxWidth
				if left < 0 then left = 0

		if opened
			$dom.removeClass(if direction is "down" then "direction-up" else "direction-down")
				.addClass("direction-" + direction)
				.toggleClass("x-over", boxWidth > dropdownDom.offsetWidth)
				.css("left", left).css("top", top)

		$dom.css("min-width", dropdownDom.offsetWidth || 80)
			.css("max-width", document.documentElement.clientWidth)
		return

	show: (options, callback)->
		@resize()
		@_animation = "fade"

		super(options, callback)
		@resize(true)

		@_resizeTimer = setInterval(()=>
			@resize(true)
			return
		, 300)
		return

	hide: (options, callback)->
		if @_resizeTimer
			clearInterval(@_resizeTimer)
			delete @_resizeTimer
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

	@templates:
		"default":
			tagName: "li"
			"c-bind": "$default"
		"list":
			tagName: "div"
			contextKey: "flexContent"
			content:
				tagName: "c-listview"
				contextKey: "list"
				allowNoCurrent: true
				changeCurrentItem: true
				highlightCurrentItem: true
				transition: true
				style: "overflow:auto"
			keydown: (evt)->
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
						allowNoCurrent: true
						changeCurrentItem: true
						highlightCurrentItem: true
						transition: true
				}
			]
			keydown: (evt)->
				if not @_disableKeyBubble
					@_disableKeyBubble = true
					$fly(@).find(">.flex-box >c-listview").trigger(evt)
					@_disableKeyBubble = false
				return true

	_initDom: (dom)->
		@_regDefaultTemplates()

		inputDom = @_doms.input
		$fly(inputDom).on("input", ()=>
			@_inputDirty = true
			@_onInput(inputDom.value)
			return
		)

		super(dom)

		if @_filterable and @_useValueContent
			$fly(dom).addClass("filterable").xAppend(
				contextKey: "filterInput"
				tagName: "input"
				text: "input"
				type: "text",
				class: "filter-input"
				focus: ()=> cola._setFocusWidget(@)
				input: (evt)=>
					if @_useValueContent
						$valueContent = $fly(@_doms.valueContent)
						if evt.target.value
							$valueContent.hide()
						else
							$valueContent.show()

					@_onInput(@_doms.filterInput.value)
					return
			, @_doms)
		return

	_refreshInputValue: (value)->
		super(if @_useValueContent then null else value)
		return

	open: ()->
		if super()
			list = @_list
			if list and @_currentItem isnt list.get("currentItem")
				list.set("currentItem", @_currentItem)

			if @_opened and @_filterable
				if @_list.get("filterCriteria") isnt null
					@_list.set("filterCriteria", null).refresh()
			return true
		return

	_onInput: (value)->
		cola.util.delay(@, "filterItems", 150, ()->
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
					firstItem = items?[0]
					if firstItem
						if filterProperty
							exactlyMatch = cola.Entity._evalDataPath(firstItem, filterProperty) is value
						else
							exactlyMatch = firstItem is value
					if exactlyMatch
						currentItemDom = @_list._getFirstItemDom()

				@_list._setCurrentItemDom(currentItemDom)
			else
				item = items and cola.util.find(items, criteria)
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

	_getSelectData: ()->
		return @_list?.get("currentItem") or null

	_onKeyDown: (evt)->
		if evt.keyCode is 13 # Enter
			@close(@_getSelectData())
			return false
		else if evt.keyCode is 27 # ESC
			@close(@_currentItem or null)
		else if evt.keyCode is 38 or evt.keyCode is 40 # UP, DOWN
			@_list?._onKeyDown(evt)
		return

	_selectData: (item)->
		@_inputDirty = false
		@_doms.filterInput?.value = ""
		return super(item)

	_onBlur: ()->
		if @_inputDirty
			@close(@_getSelectData())
		@_doms.filterInput?.value = ""
		return super()

	_getDropdownContent: ()->
		if not @_dropdownContent
			if @_filterable and @_finalOpenMode isnt "drop"
				templateName = "filterable-list"
			else
				templateName = "list"
			template = @getTemplate(templateName)
			@_dropdownContent = template = cola.xRender(template, @_scope)

			@_list = list = cola.widget(@_doms.list)
			if @_templates
				templ = @_templates["item-content"] or @_templates["value-content"]
				if templ
					list.regTemplate("default", templ)
					hasDefaultTemplate = true

			if not hasDefaultTemplate
				list.regTemplate("default", {
					tagName: "li"
					"c-bind": "$default"
				})

			list.on("itemClick", (self, arg)=>
				@close(self.getItemByItemDom(arg.dom))
				return
			).on("click", ()-> false)

		@_refreshDropdownContent()
		return template

	_refreshDropdownContent: ()->
		attrBinding = @_elementAttrBindings?["items"]
		list = @_list
		list._textProperty = @_textProperty or @_valueProperty

		if attrBinding
#			if not @_dontRefreshItems
#				@_refreshAttrValue("items")
			list.set("bind", attrBinding.expression.raw)
		else
			list.set("items", @_items)

		list.refresh()

cola.registerWidget(cola.Dropdown)

class cola.CustomDropdown extends cola.AbstractDropdown
	@tagName: "c-custom-dropdown"

	@attributes:
		content: null

	@templates:
		"default":
			tagName: "div"
			content: "<Undefined>"

	_isEditorReadOnly: ()->
		return true

	_getDropdownContent: ()->
		if not @_dropdownContent
			if @_content
				dropdownContent = @_content
			else
				dropdownContent = @getTemplate()
			@_dropdownContent = cola.xRender(dropdownContent, @_scope)
		return @_dropdownContent

cola.registerWidget(cola.CustomDropdown)

class cola.ComboBox extends cola.Dropdown
	@tagName: "c-combo-box"

	@attributes:
		postOnInput:
			type: "boolean"

	@events:
		keyPress: null
		input:null

	constructor: (config)->
		@_acceptUnknownValue = true
		super(config)

	_initDom: (dom)->
		super(dom)

		input = @_doms.input
		$(input).on("input", ()=>
			arg = {
				inputValue: input.value,
				value: this.get("value")
			}
			@fire("input", @, arg)
			if @_postOnInput then @set("value", input.value)
			return
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

	fire: (eventName, self, arg)->
		if eventName is "keyDown" or eventName is "keyPress"
			arg.inputValue = @_doms.input.value
		return super(eventName, self, arg)

	_setValueContent: ()->
		ctx = {}
		value = @readBindingValue(ctx)
		input = @_doms.input
		input.value = value or ""

		if value
			input.placeholder = ""
			@get$Dom().removeClass("placeholder")
		else
			input.placeholder = @_placeholder or ""
			@get$Dom().addClass("placeholder")
		return

	_getSelectData: ()->
		items = @_list?.get("items")
		if items
			if items instanceof Array
				if items.length is 1 then item = items[0]
			else if items instanceof cola.EntityList
				if items.entityCount is 1 then item = items.current

		value = @_doms.input.value
		matchProperty = @_filterProperty or @_textProperty or @_valueProperty
		if matchProperty
			if item instanceof cola.Entity
				if item.get(matchProperty) is value
					return item
			else if typeof item is "object"
				if item[matchProperty] is value
					return item

		if value
			if @_valueProperty or @_textProperty
				item = {
					$emptyItem: true
				}
				item[@_valueProperty] = value
				item[@_textProperty] = value
				return item
		return undefined

cola.registerWidget(cola.ComboBox)