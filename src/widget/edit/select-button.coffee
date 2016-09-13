class cola.SelectButton extends cola.AbstractEditor
	@tagName: "c-select-button"
	@CLASS_NAME: "ui select-button"
	@attributes:
		items:
			expressionType: "repeat"
			setter: (items) ->
				if typeof items is "string"
					items = items.split(/[\,,\;]/)
					for item, i in items
						index = item.indexOf("=")
						if index > 0
							items[i] = {
								key: item.substring(0, index)
								value: item.substring(index + 1)
							}
							if not @_valueProperty or not @_textProperty
								@_valueProperty = "key"
								@_textProperty = "value"

				@_items = items
				unless @_itemsTimestamp == items?.timestamp
					if items then @_itemsTimestamp = items.timestamp
					delete @_itemsIndex
				return
		keyProperty: null
		valueProperty: null

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
		$dom.find(".active").removeClass("active")
		$dom.find("[value='" + value + "']").addClass("active")

	_getItemsDom: ()->
		attrBinding = @_elementAttrBindings?["items"]
		if attrBinding
			if @_valueProperty
				cValue = "item." + @_valueProperty
			else
				cValue = "item"

			if @_keyProperty
				cKey = "item." + @_keyProperty
			else
				cKey = "item"
			raw = attrBinding.expression.raw
			itemsDom = cola.xRender({
				tagName: "div",
				class: "ui buttons",
				content: {
					tagName: "c-button",
					"c-repeat": "item in " + raw,
					"c-caption": cKey
					"c-value": cValue
				}
			}, attrBinding.scope)

		else
			itemsDom = $.xCreate({
				tagName: "div",
				class: "ui buttons"
			})

			for item in @_items
				itemsDom.appendChild($.xCreate({
					class: "ui button",
					value: if @_valueProperty then item[@_valueProperty] else item
					content: if @_keyProperty then item[@_keyProperty] else item
				}))

		return itemsDom

cola.registerWidget(cola.SelectButton)