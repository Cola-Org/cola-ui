class cola.CardBook extends cola.AbstractItemGroup
	@tagName: "c-cardBook"
	@CLASS_NAME: "card-book"

	@events:
		beforeChange: null
		change: null

	_initDom: (dom)->
		super(dom)
		if @_items then @_itemsRender()
		return

	setCurrentIndex: (index)->
		@_currentIndex ?= -1
		arg = {}
		if @_dom
			$dom = $(@_dom)
			children = $dom.find(">.item")
			oldItem = $dom.find(">.item.active")[0]
			if children.length > index
				newItem = children[index]
				if newItem == oldItem then return
				@_currentIndex = index
				arg =
					oldItem: oldItem
					newItem: newItem
				return @ if @fire("beforeChange", @, arg) is false
				@_currentIndex = index
				if oldItem then $(oldItem).removeClass("active")
				if newItem then $(newItem).addClass("active")
				@fire("change", @, arg)
		else
			@_currentIndex=index
		return @

cola.registerWidget(cola.CardBook)