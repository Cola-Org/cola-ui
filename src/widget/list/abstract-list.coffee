class cola.AbstractList extends cola.ItemsView
	@attributes:
		currentPageOnly:
			type: "boolean"

		autoLoadPage:
			type: "boolean"

		changeCurrentItem:
			type: "boolean"

		pullDown:
			readOnlyAfterCreate: true
		pullUp:
			readOnlyAfterCreate: true

		filterCriteria:
			refreshItems: true

	@events:
		pullStart: null
		pullStep: null
		pullComplete: null
		pullCancel: null
		filterItem:
			singleListener: true

	destroy: () ->
		super()
		delete @_emptyItemDom
		return

	_appendTailDom: (itemsWrapper) ->
		$fly(itemsWrapper).xAppend(
			class: "tail-padding"
			content:
				class: "ui loader"
		)
		return

	_onItemsWrapperScroll: () ->
		realItems = @_realItems
		if not @_currentPageOnly and @_autoLoadPage and not @_loadingNextPage and (realItems == @_realOriginItems or not @_realOriginItems)
			if realItems instanceof cola.EntityList and realItems.pageSize > 0 and (realItems.pageNo < realItems.pageCount or not realItems.pageCountDetermined)
				itemsWrapper = @_doms.itemsWrapper
				if Math.abs((itemsWrapper.scrollTop + itemsWrapper.clientHeight) - itemsWrapper.scrollHeight) < 6
					@_loadingNextPage = true
					$fly(itemsWrapper).find(">.tail-padding >.ui.loader").addClass("active")
					realItems.loadPage(realItems.pageNo + 1, () =>
						@_loadingNextPage = false
						$fly(itemsWrapper).find(">.tail-padding >.ui.loader").removeClass("active")
						return
					)
		return

	_convertItems: (items) ->
		if @getListeners("filterItem")
			arg = {
				filterCriteria: @_filterCriteria
			}
			items = cola.util.filter(items, (item) =>
				arg.item = item
				return @fire("filterItem", @, arg)
			)
		else if @_filterCriteria
			items = cola.util.filter(items, @_filterCriteria)
		return items

	_refreshEmptyItemDom: () ->
		emptyItemDom = @_emptyItemDom = @getTemplate("empty-item")
		if emptyItemDom
			items = @_realItems
			if items instanceof cola.EntityList and items.entityCount is 0 or items instanceof Array and items.length is 0
				$fly(emptyItemDom).show()
				itemsWrapper = @_doms.itemsWrapper
				if emptyItemDom.parentNode isnt itemsWrapper
					$fly(emptyItemDom).addClass("protected")
					cola.xRender(emptyItemDom, @_scope)
					itemsWrapper.appendChild(emptyItemDom)
			else
				$fly(emptyItemDom).hide()
		return

	_doRefreshItems: (itemsWrapper) ->
		super(itemsWrapper)

		if @_pullAction == undefined
			@_pullAction = null
			if @_pullDown
				hasPullAction = true
				pullDownPane = @getTemplate("pull-down-pane")
				pullDownPane ?= $.xCreate(tagName: "div")
				@_doms.pullDownPane = pullDownPane

			if @_pullUp
				hasPullAction = true
				pullUpPane = @getTemplate("pull-up-pane")
				pullUpPane ?= $.xCreate(tagName: "div")
				@_doms.pullUpPane = pullUpPane

			if hasPullAction
				cola.util.delay(@, "createPullAction", 200, @_createPullAction)
		return

	_createPullAction: () ->
		@_pullAction = new cola.PullAction(@_doms.itemsWrapper, {
			pullDownPane: @_doms.pullDownPane
			pullUpPane: @_doms.pullUpPane
			pullStart: (evt, pullPane, pullState) =>
				if @getListeners("pullStart")
					@fire("pullStart", @, {
						event: evt
						pullPane: pullPane
						direction: pullState
					})
				else if pullState == "up" and !@getListeners("pullComplete")
					collection = @_realItems
					if collection instanceof cola.EntityList
						return collection.pageNo < collection.pageCount
			pullStep: (evt, pullPane, pullState, distance, theshold) =>
				@fire("pullStep", @, {
					event: evt
					pullPane: pullPane
					direction: pullState
					distance: distance
					theshold: theshold
				})
			pullComplete: (evt, pullPane, pullState, done) =>
				if @fire("pullComplete", @, {
					event: evt
					pullPane: pullPane
					direction: pullState
					done: done
				}) is false
					return

				if pullState == "down"
					collection = @_realOriginItems or @_realItems
					if collection instanceof cola.EntityList
						collection.flush(done)
					else
						done()
				else if pullState == "up"
					collection = @_realItems
					if collection instanceof cola.EntityList
						collection.nextPage(done)
					else
						done()
				return
			pullCancel: (evt, pullPane, pullState) =>
				@fire("pullCancel", @, {
					event: evt
					pullPane: pullPane
					direction: pullState
				})
		})
		return