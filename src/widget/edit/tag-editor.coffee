cola.TagEditor = cola.defineWidget({
	tagName: "c-tag-editor",
	attributes: {
		bind: null,
		items: null,
		keyProperty: null,
		valueProperty: null,
		readOnly: null
	},
	events: {
		createItemDom: null,
		keyDown: null,
		input: null,
		removeItem: null,
		addItem: null
	},
	template: {
		class: "ui tag-editor",
		content: [{
			class: "tag",
			"c-repeat": "item in @bind",
			"c-watch": "initItemDom on item",
			content: [
				{
					tagName: "span"
				},
				{
					tagName: "i",
					"c-onclick": "removeItem(item)",
					class: "delete-icon",
					content: "×"
				}
			]
		}, {
			tagName: "input"
		}]
	},
	_refreshDom: ()->
		readOnly = !!@_readOnly
		@_dom && $(@_dom).toggleClass("read-only", readOnly)
		input = $(@_dom).find("input")[0]
		input.readOnly = readOnly

	initDom: (dom)->
		tagEditor = @
		$(dom).on("click", ()->
			$(@).find("input").focus()
		)
		$input = $(dom).find("input")
		@_doms ?= {}
		@_doms.input = dom

		$input.on("focus", ()->
			tagEditor._showDropBox()
		).on("input", (evt)->
			inputValue = $(@).val()
			tagEditor.fire("input", tagEditor, {
				inputValue: inputValue,
				input: @
			})
		)

	removeItem: (item)->
		if item
			result = @fire("removeItem", @, {
				item: item
			})

			if result is false then return

			item.remove()
		return

	_onKeyDown: (evt) ->
		tagEditor = @
		selectedItems = tagEditor._scope.get(tagEditor._bind)
		inputValue = $(this).val()
		if evt.keyCode == 8
			if !inputValue && selectedItems
				last = selectedItems.last()
				last && tagEditor.removeItem(last)

		if evt.keyCode == 46 && selectedItems
			selectedItems.empty()

		if tagEditor.isOpended()
			$tagsDom = $(tagEditor._dropBox._dom).find(".tag-items")
			$current = $tagsDom.find(">li.current")
			if evt.keyCode == 40
				if $current.length
					$next = $current.next()
					if $next.length
						$next.addClass("current")
					else
						$tagsDom.find(">li").first().addClass("current")

					$current.removeClass("current")
				else
					$tagsDom.find(">li").first().addClass("current")

			else if evt.keyCode == 38
				if $current.length
					$prev = $current.prev()
					if $prev.length
						$prev.addClass("current")
					else
						$tagsDom.find(">li").last().addClass("current")

					$current.removeClass("current")
				else
					$tagsDom.find(">li").last().addClass("current")


			else if evt.keyCode == 13
				$current.length && $current.trigger("click")
				return

		return

	open: ()->
		@_showDropBox()

	isOpended: ()->
		if @_dropBox
			return @_dropBox.isVisible()

		return false

	_showDropBox: ()->
		if !!@_readOnly then return
		dropBox = @_getDropBox()
		content = @_getDropContent()
		dropBox.get$Dom().empty().append(content)
		dropBox.show()

	resetData: ()->
		dropBox = @_getDropBox()
		content = @_getDropContent()
		dropBox.get$Dom().empty().append(content)

	_getDropBox: ()->
		tagEditor = @

		unless @_dropBox
			@_dropBox = new cola.DropBox({
				beforeHide: (self, arg)->
					tagEditor.get$Dom().removeClass("opened")
				hide: (self, arg)->
					tagEditor._opened = false
			})
			@_dropBox._context = @
			@_dropBox._dropdown = @
			document.body.appendChild(@_dropBox.getDom())
		return @_dropBox

	_getDropContent: ()->
		valueProperty = @_valueProperty || "value"
		keyProperty = @_keyProperty || "key"
		selection = @_scope.get(@_items)
		selectedItems = @_scope.get(@_bind)
		mapping = {}
		tagEditor = @
		template = []

		selectedItems && selectedItems.each((item)->
			mapping[item.get(keyProperty)] = true
		)
		selection.each((item)->
			key = item.get(keyProperty)
			if mapping[key]
				return

			template.push({
				tagName: "li",
				key: item.get(keyProperty),
				content: item.get(valueProperty),
				click: ()->
					tagEditor.close(item)

			})
		)
		return $.xCreate({
			tagName: "ul",
			class: "tag-items",
			content: template
		})

	initItemDom: (dom, scope)->
		text = scope.get("item").get(@_valueProperty || "value")
		$(dom).find("span").empty().text(text)

	close: (item)->
		if item
			selectedItems = @_scope.get(@_bind)
			selectedItems.insert(item.toJSON())

			@fire("addItem", @, {
				item: item
			})

		@_getDropBox().hide()
		$(@_dom).find("input").val(null)

})