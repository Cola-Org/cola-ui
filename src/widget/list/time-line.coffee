class cola.TimeLine extends cola.AbstractList
	@CLASS_NAME: "time-line"
	@ATTRIBUTES:
		bind:
			refreshItems: true
			setter: (bindStr) -> @_bindSetter(bindStr)

#	@EVENTS:
#		itemContentClick: null
#		itemLineClick: null
#		itemIconClick: null

	@TEMPLATES:
		"default":
			tagName: "li"
		"content":
			tagName: "div"
			"c-bind": "$default.content"
		"icon":
			tagName: "i"
			class: "'icon'+$default.icon"
		"time":
			tagName: "div"
			"c-bind": "$default.time"

	_createNewItem: (itemType, item) ->
		template = @_getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("item #{itemType}")
		itemDom._itemType = itemType
		for name in ["content", "icon", "time"]
			template = @_getTemplate(name)
			contentDom = @_cloneTemplate(template, true)
			container = $.xCreate({
				tagName: "div"
				class: name
#				click: ()=>
#					@fire("item#{cola.util.capitalize(name)}Click", @, {item: item})
			})
			container.appendChild(contentDom)
			itemDom.appendChild(container)
		if !@_currentItem
			@_setCurrentNode(item)

		return itemDom



