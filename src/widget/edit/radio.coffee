class cola.RadioGroup extends cola.AbstractEditor
	@tagName: "c-radio-group"
	@CLASS_NAME: "ui radio-group"
	@attributes:
		items:
			expressionType: "repeat"
			setter: (items) ->
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
		$(dom).delegate(">item", "click", ()->
			if selector._readOnly then return
			value = $(this).find("input").attr("value")
			selector._setValue(value);
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
		$(@_dom).find("[value='" + value + "']")[0].checked = true;

	_getItemsDom: ()->
		attrBinding = @_elementAttrBindings?["items"]
		@_name ?= ("name_" + cola.sequenceNo());
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
				tagName: "item",
				"c-repeat": "item in " + raw,
				content: [
					{
						tagName: "input", type: "radio",
						name: @_name, "c-value": cValue
					},
					{
						tagName: "label",
						"c-bind": cText
					}
				]
			}, attrBinding.scope)

		else
			itemsDom = document.createDocumentFragment();
			for item in @_items
				itemsDom.appendChild({
					tagName: "item",
					"c-repeat": "item in " + raw,
					content: [
						{
							tagName: "input", type: "radio",
							name: @_name, value: item.value
						},
						{
							tagName: "label"
						}
					]
				})

		return itemsDom

cola.registerWidget(cola.RadioGroup)