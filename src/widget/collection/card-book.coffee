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

	_parseDom: (dom)->

	setCurrent: (name)->
		unless @_dom then return
		$dom = @get$Dom()
		target = $dom.find(">[name='#{name}']")
		if target.length > 0
			index = $(target).index()
			@setCurrentIndex(index)
		return @

	setCurrentIndex: (index)->
		@_currentIndex ?= -1
		arg = {}
		if @_dom
			$dom = $(@_dom)
			children = $dom.find(">.item,>item")
			oldItem = $dom.find(">.item.active,>item.active")[0]
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
			@_currentIndex = index
		return @

cola.registerWidget(cola.CardBook)