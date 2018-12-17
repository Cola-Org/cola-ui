cola.TagEditor = cola.defineWidget({
	tagName: "c-tag-editor"
	attributes:
		bind: null,
		items: null,
		keyProperty: null,
		valueProperty: null,
		readOnly: null
		focusable:
			defaultValue: true

	events:
		createItemDom: null,
		keyDown: null,
		input: null,
		removeItem: null,
		addItem: null

	template:
		class: "ui tag-editor"
		content: [
			{
				class: "tag"
				"c-repeat": "item in @bind"
				"c-watch": "initItemDom on item"
				content: [
					{
						tagName: "span"
					}
					{
						tagName: "i"
						"c-onclick": "removeItem(item)"
						class: "delete-icon"
						content: "×"
					}
				]
			}
			{
				tagName: "input"
				contextKey: "input"
			}
		]

	_refreshDom: ()->
		readOnly = !!@_readOnly
		@_dom && $(@_dom).toggleClass("readonly", readOnly)
		input = $(@_dom).find("input")[0]
		input.readOnly = readOnly
		return

	initDom: (dom)->
		tagEditor = @

		@get$Dom().click(()->
			tagEditor._showDropBox()
		)

		@get$Dom("input").on("focus", ()->
			cola._setFocusWidget(tagEditor)
		).on("input", ()->
			inputValue = $(@).val()
			tagEditor.fire("input", tagEditor, {
				inputValue: inputValue,
				input: @
			})

			if tagEditor._filterTimerId
				clearTimeout(tagEditor._filterTimerId)
			tagEditor._filterTimerId = setTimeout(()->
				delete tagEditor._filterTimerId
				tagEditor._widgetModel.set("refreshTimestamp", new Date())
			, 300)
		)
		return

	removeItem: (item)->
		if item
			result = @fire("removeItem", @, {
				item: item
			})
			if result is false then return
			item.remove()
		return

	_onKeyDown: (evt)->
		tagEditor = @
		selectedItems = tagEditor._scope.get(tagEditor._bind)
		inputValue = $(@_doms.input).val()
		if evt.keyCode is 8
			if !inputValue && selectedItems
				last = selectedItems.last()
				last && tagEditor.removeItem(last)

		if evt.keyCode is 46 && selectedItems
			selectedItems.empty()

		if tagEditor.isOpended()
			$tagsDom = $(tagEditor._dropBox._dom).find(".tag-items")
			$current = $tagsDom.find(">li.current")
			if evt.keyCode is 40
				if $current.length
					$next = $current.next()
					if $next.length
						$next.addClass("current")
					else
						$tagsDom.find(">li").first().addClass("current")

					$current.removeClass("current")
				else
					$tagsDom.find(">li").first().addClass("current")

			else if evt.keyCode is 38
				if $current.length
					$prev = $current.prev()
					if $prev.length
						$prev.addClass("current")
					else
						$tagsDom.find(">li").last().addClass("current")

					$current.removeClass("current")
				else
					$tagsDom.find(">li").last().addClass("current")


			else if evt.keyCode is 13
				$current.length && $current.trigger("click")
				return

		return

	focus: ()->
		@_doms.input?.focus()
		return

	_onFocus: ()->
		@_showDropBox()
		return

	_onBlur: ()->
		if @_filterTimerId
			clearTimeout(@_filterTimerId)
			delete @_filterTimerId
		@close()

	open: ()->
		@_showDropBox()
		return

	isOpended: ()->
		if @_dropBox
			return @_dropBox.isVisible()
		return false

	_showDropBox: ()->
		if !!@_readOnly then return
		dropBox = @_getDropBox()
		if not dropBox.get("visible")
			@_widgetModel.set("refreshTimestamp", new Date())
			if dropBox.getDom().childNodes.length is 0
				content = cola.xRender(@_getDropContent(), @_widgetModel)
				dropBox.get$Dom().empty().append(content)
			dropBox.show()
		return

	_getDropBox: ()->
		tagEditor = @

		unless @_dropBox
			@_dropBox = new cola.DropBox({
				beforeHide: ()->
					tagEditor.get$Dom().removeClass("opened")
				hide: ()->
					tagEditor._opened = false
			})
			@_dropBox._context = @
			@_dropBox._dropdown = @
			document.body.appendChild(@_dropBox.getDom())
		return @_dropBox

	_getDropContent: ()->
		return $.xCreate(
			tagName: "ul"
			class: "tag-items"
			content:
				tagName: "li"
				"c-repeat": "item in filter(items) on items,refreshTimestamp"
				"c-key": "item." + (@_keyProperty || "key")
				"c-bind": "item." + (@_valueProperty || "value")
				"c-onclick": "close(item)"
		)

	filter: (items, filterValue)->
		return [] unless items

		keyProperty = @_keyProperty or "key"
		valueProperty = @_valueProperty or "value"
		map = {}
		selectedItems = @_scope.get(@_bind)
		selectedItems && selectedItems.each((item)->
			if item instanceof cola.Entity
				key = item.get(keyProperty)
			else
				key = item[keyProperty]
			map[key] = true
		)

		filterValue = $(@_doms.input).val()
		return cola.util.filter(items, (item)->
			if item instanceof cola.Entity
				key = item.get(keyProperty)
			else
				key = item[keyProperty]
			if map[key]
				return false

			if item instanceof cola.Entity
				value = item.get(valueProperty) + ""
			else
				value = item[valueProperty] + ""
			if filterValue and value and value.indexOf(filterValue) < 0
				return false

			return true
		)

	initItemDom: (dom, scope)->
		text = scope.get("item").get(@_valueProperty or "value")
		$(dom).find("span").empty().text(text)
		return

	close: (item)->
		if item
			selectedItems = @_scope.get(@_bind)
			selectedItems.insert(item.toJSON())

			@fire("addItem", @, {
				item: item
			})

		@_getDropBox().hide()
		$(@_dom).find("input").val(null)
		return

})