class cola.CardBook extends cola.AbstractItemGroup
	@tagName: "c-cardBook"
	@CLASS_NAME: "card-book"

	@events:
		beforeChange: null
		change: null

	_parseDom: (dom)->
		child = dom.firstChild
		while child
			if child.nodeType == 1
				if cola.util.hasClass(child, "item")
					@addItem(child) if child.nodeType == 1
			child = child.nextSibling
		return null

	_initDom: (dom)->
		super(dom)
		if @_items then @_itemsRender()
		return

	setCurrentIndex: (index)->
		@_currentIndex ?= -1
		return @ if @_currentIndex == index
		arg = {}

		if @_currentIndex > -1
			oldItem = @_items[@_currentIndex]
			oldItemDom = @getItemDom(@_currentIndex)
		if index > -1
			newItem = @_items[index]
			newItemDom = @getItemDom(index)

		arg =
			oldItem: oldItem
			newItem: newItem

		return @ if @fire("beforeChange", @, arg) is false

		$(oldItemDom).removeClass("active") if oldItemDom
		$(newItemDom).addClass("active") if newItemDom
		@_currentIndex = index

		@fire("change", @, arg)
		return @

cola.registerWidget(cola.CardBook)