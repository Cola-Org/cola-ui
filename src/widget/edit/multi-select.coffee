class cola.MultiSelect extends cola.CustomDropdown
	@CLASS_NAME: "ui tag-editor"
	@tagName: "c-multiSelect"
	@events:
		renderItem: null

	_setValueContent: ()->
		value = @_value
		values = []
		if value
			values = value.split(",")
		$(@_dom).find(".tag").remove()
		$input = $(@_dom).find(">input")
		for val in values
			itemDom = $.xCreate({
				tagName: "div", class: "tag",
				content: [
					{
						tagName: "span",
						content: val
					},
					{
						tagName: "i",
						"c-onclick": "removeItem(item)",
						class: "delete-icon",
						content: "×"
					}
				]
			})
			$(itemDom).data({
				item: val
			})
			@fire("renderItem", @, {itemDom: itemDom, item: val, value: value})
			$input.before(itemDom)

	removeItem: (item)->
		if item.nodeType
			data = $(item).data().item
			value = @_value
			values = value.split(",")
			newValues = [];
			for val in values
				if val == data then continue;
				newValues.push(val)
			newValue = newValues.join(",")
			@_set("value", newValue)

	_selectData: (item) ->
		@_inputEdited = false
		cValue = @_value
		values = cValue.split(",")
		for val in values
			if val == item then return;
		values.push(item);
		value = values.join(",")
		@_skipFindCurrentItem = true
		if @fire("selectData", @, {item: item, oldValue: cValue, value: value}) isnt false
			@_currentItem = item
			@set("value", value)
		@_skipFindCurrentItem = false
		@refresh()
		return

	_initDom: (dom)->
		super(dom)
		multiSelect = @
		$(dom).delegate(".tag", "click", ()->
			multiSelect.removeItem(@)
		)


cola.registerWidget(cola.MultiSelect)