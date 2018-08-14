class cola.TimeLine extends cola.AbstractList
	@tagName: "c-timeLine"
	@className: "time-line"

	@attributes:
		bind:
			refreshItems: true
			setter: (bindStr)-> @_bindSetter(bindStr)

#	@events:
#		itemContentClick: null
#		itemLineClick: null
#		itemIconClick: null

	@templates:
		"default":
			tagName: "li"
		"content":
			tagName: "div"
			"c-bind": "$default.content"
		"icon":
			tagName: "i"
			"c-class": "'icon '+$default.icon"
		"label":
			tagName: "div"
			"c-bind": "$default.label"

	_createNewItem: (itemType, item)->
		template = @getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("item #{itemType}")
		itemDom._itemType = itemType
		for name in ["content", "icon", "label"]
			template = @getTemplate(name)
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

cola.registerWidget(cola.TimeLine)
