class cola.SelectButton extends cola.AbstractEditor
	@tagName: "c-select-button"
	@CLASS_NAME: "ui select-button buttons"
	@attributes:
		items:
			expressionType: "repeat"
			setter: (items) ->
				if typeof items is "string"
					items = items.split(/[\,,\;]/)
					for item, i in items
						index = item.indexOf("=")
						if index >= 0
							items[i] = {
								key: item.substring(0, index)
								value: item.substring(index + 1)
							}

				if not @_valueProperty and not @_textProperty
					result = cola.util.decideValueProperty(items)
					if result
						@_valueProperty = result.valueProperty
						@_textProperty = result.textProperty

				@_items = items
				unless @_itemsTimestamp == items?.timestamp
					if items then @_itemsTimestamp = items.timestamp
					delete @_itemsIndex
				return

		valueProperty: null
		textProperty: null

	_initDom: (dom)->
		super(dom)
		selector = @
		$(dom).delegate(".ui.button", "click", ()->
			if selector._readOnly then return
			value = $(this).attr("value")
			selector._setValue($(this).attr("value"));
			selector._select(value)
		)

	_doRefreshDom: ()->
		super()
		itemsDom = @_getItemsDom()
		if itemsDom
			$fly(@_dom).empty()
			$fly(@_dom).append(itemsDom)
		value = @_value
		@_select(value)

	_select: (value)->
		$dom = $(@_dom)
		$dom.find(".positive").removeClass("positive")
		$dom.find("[value='" + value + "']").addClass("positive")

	_getItemsDom: ()->
		attrBinding = @_elementAttrBindings?["items"]
		if attrBinding
			if @_textProperty
				cText = "item." + @_textProperty
			else
				cText = "item"

			if @_valueProperty
				cValue = "item." + @_valueProperty
			else
				cValue = "item"
			raw = attrBinding.expression.raw
			itemsDom = cola.xRender({
				tagName: "c-button",
				"c-repeat": "item in " + raw,
				"c-caption": cText
				"c-value": cValue
			}, attrBinding.scope)

		else
			itemsDom = document.createDocumentFragment();
			for item in @_items
				itemsDom.appendChild($.xCreate({
					class: "ui button",
					value: if @_valueProperty then item[@_valueProperty] else item
					content: if @_textProperty then item[@_textProperty] else item
				}))

		return itemsDom

cola.registerWidget(cola.SelectButton)