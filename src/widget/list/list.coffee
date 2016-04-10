SAFE_SLIDE_EFFECT = cola.os.android and !cola.browser.chrome
SLIDE_ANIMATION_SPEED = 200
LIST_SIZE_PREFIXS = ["small", "medium", "large", "xlarge", "xxlarge"]

_createGroupArray = () ->
	groups = []
	groups._grouped = true
	return groups

class cola.ListView extends cola.AbstractList
	@CLASS_NAME: "items-view list-view"

	_columnsChanged: true

	@ATTRIBUTES:
		items:
			expressionType: "repeat"
			refreshItems: true
			setter: (items) ->
				return if @_items == items
				@_set("bind", undefined)
				@_items = items
				return
			getter: () ->
				return @_realItems or @_items

		bind:
			refreshItems: true
			setter: (bindStr) ->
				@_set("items", undefined)
				return @_bindSetter(bindStr)
		textProperty:
			refreshItems: true

		columns:
			refreshItems: true
			defaultValue: "row"
			setter: (columns) ->
				@_columns = columns
				@_columnsChanged = true
				return
		itemWidth: null
		itemHeight: null

		group:
			refreshItems: true
		groupCollapsible:
			type: "boolean"
			defaultValue: true
		indexBar:
			refreshItems: true

		itemSlide:
			enum: ["none", "left", "right", "both"]
			defaultValue: "none"
			setter: (value) ->
				@_itemSlide = value
				if value
					if value == "left"
						left = true
					else if value == "right"
						right = true
					else
						left = true
						right = true
					@_leftItemSlide = left
					@_rightItemSlide = right

	@EVENTS:
		getGroupString: null
		itemSlideStart: null
		itemSlideStep: null
		itemSlideComplete: null
		itemSlideCancel: null
		itemSlidePaneInit: null
		itemSlidePaneShow: null
		itemSlidePaneHide: null

	@TEMPLATES:
		"default":
			tagName: "li"
			"c-bind": "$default"
		"group":
			tagName: "ul"
			content:
				tagName: "ul"
		"group-header":
			tagName: "li"
			"c-bind": "group.name"

	destroy: () ->
		super()
		delete @_topGroupDom
		clearInterval(@_indexBarRelocateTimer) if @_indexBarRelocateTimer
		delete @_itemSlidePane
		delete @_slideItemDom
		return

	_initDom: (dom) ->
		super(dom)
		$fly(@_doms.itemsWrapper).delegate(".group-header", "click", (evt) => @_onGroupHeaderClick(evt))
		cola.util.delay(@, "initItemSlide", 200, @_initItemSlide)
		return

	_getItems: () ->
		if @_items
			return {items: @_items}
		else
			return super()

	_groupItems: (items) ->
		groups = _createGroupArray()
		currentGroup = null

		hasGetGroupStringEvent = @getListeners("getGroupString")
		list = @
		cola.each items, (item) ->
			if hasGetGroupStringEvent
				eventArg =
					item: item
					result: null
				list.fire("getGroupString", list, eventArg)
				groupString = eventArg.result
			else
				groupString = null
				groupProp = list.group
				if groupProp and typeof groupProp == "string"
					if item instanceof cola.Entity
						groupString = item.get(groupProp)
					else if typeof item == "object"
						groupString = item?[groupProp]
					else if item
						groupString = item + ""

			if groupString == currentGroup?.name
				currentGroup.items.push(item)
			else
				if currentGroup
					groups.push(currentGroup)
				currentGroup =
					_itemType: "group"
					_alias: "group"
					name: groupString or "#"
					items: [item]
			return

		if currentGroup
			groups.push(currentGroup)
		return groups

	_convertItems: (items) ->
		items = super(items)
		if @_group and items
			items = @_groupItems(items)
		return items

	_doRefreshDom: (dom) ->
		return unless @_dom

		if @_columnsChanged
			delete @_columnsChanged

			classNames = ["items"]
			columns = @_columns or "row"
			columns = columns.split(" ")
			i = 0
			for column in columns
				if column == "" then continue
				if column == "row"
					classNames.push(LIST_SIZE_PREFIXS[i] + "-row-list")
				else
					classNames.push(LIST_SIZE_PREFIXS[i] + "-block-grid-" + column)
				i++
				if i >= LIST_SIZE_PREFIXS.length then break

			itemsWrapper = @_doms.itemsWrapper
			if @_group
				@_columnsClassNames = classNames
				itemsWrapper.className = "items"
			else
				itemsWrapper.className = classNames.join(" ")

		super(dom)

		@_classNamePool.toggle("has-index-bar", !!@_indexBar)
		return

	_refreshItems: () ->
		super()

		if @_dom
			if !@_group
				@_doms.floatGroupHeaderWrapper?.style.display = "none"

			if @_indexBar and @_group and @_realItems
				@_refreshIndexBar()
			else if @_doms.indexBar
				$fly(@_doms.indexBar).hide()

			if !cola.os.mobile and !@_indexBarRelocateTimer
				itemsWrapper = @_doms.itemsWrapper
				dom = @_dom
				@_indexBarRelocateTimer = setInterval(() ->
					$fly(dom).toggleClass("v-scroll", itemsWrapper.scrollHeight > itemsWrapper.clientHeight)
					return
				, 500)
		return

	_getDefaultBindPath: (item) ->
		if @_textProperty
			return (item._alias or @_alias) + "." + @_textProperty

	_createNewItem: (itemType, item) ->
		template = @_getTemplate(itemType)
		if template
			itemDom = @_cloneTemplate(template)
		else
			itemDom = document.createElement("li")
			itemDom.setAttribute("c-bind", "$default")

		if itemType == "group"
			klass = "list group"
		else if itemType == "group-header"
			klass = "list group-header"
			if @_groupCollapsible
				klass += " collapsible"
		else
			klass = "list item " + itemType

		itemDom._itemType = itemType

		$itemDom = $fly(itemDom)
		$itemDom.addClass(klass)
		if @_itemWidth then $itemDom.width(@_itemWidth)
		if @_itemHeight then $itemDom.height(@_itemHeight)
		return itemDom

	_refreshItemDom: (itemDom, item, parentScope) ->
		if itemDom._itemType == "group"
			return @_refreshGroupDom(itemDom, item, parentScope)
		else
			return super(itemDom, item, parentScope)

	_refreshGroupDom: (groupDom, group, parentScope = @_itemsScope) ->
		groupId = cola.Entity._getEntityId(group)

		groupScope = cola.util.userData(groupDom, "scope")
		if !groupScope
			groupDom._itemScope = groupScope = new cola.ItemScope(parentScope, group._alias)
			parentScope.regItemScope(groupId, groupScope)
			groupScope.data.setTargetData(group, true)
			cola.util.userData(groupDom, "scope", groupScope)
			cola.util.userData(groupDom, "item", group)
		else
			oldGroup = cola.util.userData(groupDom, "item")
			if oldGroup != groupScope.data.getTargetData()
				delete groupDom._itemId if groupDom._itemId
				groupScope.data.setTargetData(group)
				cola.util.userData(groupDom, "item", group)

		if groupId
			groupDom._itemId = groupId
			@_itemDomMap[groupId] = groupDom
		else
			delete groupDom._itemId

		if !groupDom._headerCreated
			groupDom._headerCreated = true
			itemsWrapper = groupDom.firstChild
			groupHeaderDom = @_createNewItem("group-header", group)
			@_templateContext.defaultPath = group._alias
			cola.xRender(groupHeaderDom, groupScope, @_templateContext)
			groupDom.insertBefore(groupHeaderDom, itemsWrapper)
			cola.util.userData(groupHeaderDom, "item", group)
		else
			itemsWrapper = groupDom.lastChild

		documentFragment = null
		currentItemDom = itemsWrapper.firstChild
		for item in group.items
			itemType = @_getItemType(item)

			itemDom = null
			if currentItemDom
				while currentItemDom
					if currentItemDom._itemType == itemType
						break
					else
						nextItemDom = currentItemDom.nextSibling
						groupDom.removeChild(currentItemDom)
						currentItemDom = nextItemDom
				if currentItemDom
					itemDom = currentItemDom
					currentItemDom = currentItemDom.nextSibling

			if itemDom
				@_refreshItemDom(itemDom, item)
			else
				itemDom = @_createNewItem(itemType, item)
				@_refreshItemDom(itemDom, item)
				documentFragment ?= document.createDocumentFragment()
				documentFragment.appendChild(itemDom)

		if currentItemDom
			itemDom = currentItemDom
			while itemDom
				nextItemDom = itemDom.nextSibling
				itemsWrapper.removeChild(itemDom)
				delete @_itemDomMap[itemDom._itemId] if itemDom._itemId
				itemDom = nextItemDom

		if @_columnsClassNames
			itemsWrapper.className = @_columnsClassNames.join(" ")
		else
			itemsWrapper.className = "items"

		if documentFragment
			itemsWrapper.appendChild(documentFragment)
		return

	_onItemInsert: (arg) ->
		if @_group
			@_refreshItems()
		else
			super(arg)
		return

	_onItemRemove: (arg) ->
		if @_group
			@_refreshItems()
		else
			super(arg)
		return

	_onItemsWrapperScroll: () ->
		super()

		return unless @_group
		scrollTop = @_doms.itemsWrapper.scrollTop

		if scrollTop <= 0
			@_doms.floatGroupHeaderWrapper?.style.display = "none"
			return

		topGroupDom = @_findTopGroupDom(scrollTop)
		if topGroupDom
			if topGroupDom.offsetTop == scrollTop
				@_doms.floatGroupHeaderWrapper?.style.display = "none"
				return

			group = cola.util.userData(topGroupDom, "item")
			floatGroupHeader = @_getFloatGroupHeader(group)

			gap = 1
			nextOffsetTop = topGroupDom.nextSibling?.offsetTop
			if nextOffsetTop > 0 and nextOffsetTop - scrollTop - gap < @_floatGroupHeaderHeight
				offset = @_floatGroupHeaderHeight - (nextOffsetTop - scrollTop - gap)
				floatGroupHeader.style.top = (@_floatGroupHeaderDefaultTop - offset) + "px"
				@_floatGroupHeaderMoved = true
			else if @_floatGroupHeaderMoved
				floatGroupHeader.style.top = @_floatGroupHeaderDefaultTop + "px"
				delete @_floatGroupHeaderMoved
		return

	_getFloatGroupHeader: (group) ->
		floatGroupHeaderWrapper = @_doms.floatGroupHeaderWrapper
		if !floatGroupHeaderWrapper
			groupScope = new cola.ItemScope(@_itemsScope, group._alias)
			groupScope.data.setTargetData(group, true)
			floatGroupHeader = @_createNewItem("group-header", group)
			cola.util.userData(floatGroupHeader, "scope", groupScope)
			@_templateContext.defaultPath = group._alias
			cola.xRender(floatGroupHeader, groupScope)

			floatGroupHeaderWrapper = $.xCreate({
				tagName: "ul"
				class: "items float-group-header"
				content: floatGroupHeader
			})
			@_dom.appendChild(floatGroupHeaderWrapper)
			@_doms.floatGroupHeaderWrapper = floatGroupHeaderWrapper

			@_floatGroupHeaderDefaultTop = @_doms.pullDownPane?.offsetHeight or 0
			@_floatGroupHeaderHeight = floatGroupHeaderWrapper.offsetHeight
			floatGroupHeaderWrapper.style.top = @_floatGroupHeaderDefaultTop + "px"
		else
			floatGroupHeader = floatGroupHeaderWrapper.firstChild
			groupScope = cola.util.userData(floatGroupHeader, "scope")
			groupScope.data.setTargetData(group)
			if floatGroupHeaderWrapper.style.display == "none"
				floatGroupHeaderWrapper.style.display = ""
		return floatGroupHeaderWrapper

	_findTopGroupDom: (scrollTop) ->
		groups = @_realItems
		return unless groups?.length

		currentGroupDom = @_topGroupDom or @_doms.itemsWrapper.firstChild
		currentGroupDomTop = currentGroupDom.offsetTop
		if currentGroupDomTop <= scrollTop
			groupDom = currentGroupDom.nextSibling
			while groupDom
				groupDomOffsetTop = groupDom.offsetTop
				if groupDomOffsetTop > scrollTop
					groupDom = groupDom.previousSibling
					@_topGroupDom = groupDom if @_topGroupDom != groupDom
					break
				groupDom = groupDom.nextSibling
		else
			groupDom = currentGroupDom.previousSibling
			while groupDom
				groupDomOffsetTop = groupDom.offsetTop
				if groupDomOffsetTop <= scrollTop
					@_topGroupDom = groupDom
					break
				groupDom = groupDom.previousSibling
		return groupDom

	_onGroupHeaderClick: (evt) ->
		itemDom = evt.currentTarget
		item = cola.util.userData(itemDom, "item")
		groupDom = itemDom.parentNode
		if !item._collapsed
			item._collapsed = true
			$fly(itemDom).addClass("collapsed")
			$fly(groupDom).css("overflow", "hidden").animate({
				height: itemDom.offsetHeight
			}, {
				duration: 150
				easing: "swing"
			})
		else
			item._collapsed = false
			$fly(itemDom).removeClass("collapsed")
			$fly(groupDom).animate({
				height: groupDom.scrollHeight
			}, {
				duration: 150
				easing: "swing"
				complete: () ->
					groupDom.style.height = ""
					groupDom.style.overflow = ""
					return
			})
		return false

	_createPullAction: () ->
		super()
		if @_doms.indexBar
			indexBar = @_doms.indexBar
			if @_pullAction.pullDownDistance and $fly(indexBar).css("position") == "absolute"
				indexBar.style.marginTop = @_pullAction.pullDownDistance + "px"
				indexBar.style.marginBottom = -@_pullAction.pullDownDistance + "px"
		return

	_refreshIndexBar: () ->
		list = @
		indexBar = @_doms.indexBar

		if !indexBar
			goIndex = (target, animate) ->
				indexDom = target
				while indexDom and indexDom != indexBar
					if indexDom._groupIndex >= 0
						break
					indexDom = indexDom.parentNode

				if indexDom?._groupIndex >= 0
					timestamp = new Date()
					if !list._currentIndex or list._currentIndex != indexDom._groupIndex and timestamp - list._currentIndexTimestamp > 100
						list._currentIndex = indexDom._groupIndex
						list._currentIndexTimestamp = timestamp

						currentIndexDom = indexBar.querySelector(".current")
						$fly(currentIndexDom).removeClass("current") if currentIndexDom
						$fly(indexDom).addClass("current")

						group = list._realItems[indexDom._groupIndex]
						groupId = cola.Entity._getEntityId(group)
						if groupId
							groupDom = list._itemDomMap[groupId]
							if groupDom
								itemsWrapper = list._doms.itemsWrapper
								if animate
									$(itemsWrapper).animate({
										scrollTop: groupDom.offsetTop
									}, {
										duration: 150
										easing: "swing"
										queue: true
									})
								else
									itemsWrapper.scrollTop = groupDom.offsetTop
				return

			clearCurrent = () ->
				setTimeout(() ->
					currentIndexDom = indexBar.querySelector(".current")
					$fly(currentIndexDom).removeClass("current") if currentIndexDom
					return
				, 300)
				return

			@_doms.indexBar = indexBar = $.xCreate({
				tagName: "div"
				class: "index-bar"
				mousedown: (evt) -> goIndex(evt.target, true)
				mouseup: clearCurrent
				touchstart: (evt) -> goIndex(evt.target, true)
				touchmove: (evt) ->
					touch = evt.originalEvent.touches[0]
					target = document.elementFromPoint(touch.pageX, touch.pageY);
					goIndex(target, true)
					return false
				touchend: clearCurrent
			})
			@_dom.appendChild(indexBar)
		else
			$fly(indexBar).show()

		documentFragment = null
		currentItemDom = indexBar.firstChild
		groups = @_realItems
		for group, i in groups
			if currentItemDom
				itemDom = currentItemDom
				currentItemDom = currentItemDom.nextSibling
			else
				itemDom = $.xCreate({
					tagName: "div"
					class: "index"
					content: "^span"
				})
				documentFragment ?= document.createDocumentFragment()
				documentFragment.appendChild(itemDom)
			$fly(itemDom.firstChild).text(group.name)
			itemDom._groupIndex = i

		if documentFragment
			indexBar.appendChild(documentFragment)
		else
			while currentItemDom
				nextDom = currentItemDom.nextSibling
				indexBar.removeChild(currentItemDom)
				currentItemDom = nextDom
		return

	_initItemSlide: () ->
		leftSlidePaneTemplate = @_getTemplate("slide-left-pane")
		rightSlidePaneTemplate = @_getTemplate("slide-right-pane")
		return unless leftSlidePaneTemplate or rightSlidePaneTemplate

		itemsWrapper = @_doms.itemsWrapper
		if @_itemSlide and @_itemSlide != "none"
			$fly(itemsWrapper)
			.on("touchstart", (evt) => @_onItemsWrapperTouchStart(evt))
			.on("touchmove", (evt) => @_onItemsWrapperTouchMove(evt))
			.on("touchend", (evt) => @_onItemsWrapperTouchEnd(evt))

		itemScope = new cola.ItemScope(@_itemsScope, @_alias)
		@_templateContext.defaultPath = @_alias

		if leftSlidePaneTemplate
			$fly(leftSlidePaneTemplate).addClass("item-slide-pane protected").css("left", "100%").click(()=>
				if @_itemSlideState is "waiting"
					@hideItemSlidePane()
				return
			)
			cola.xRender(leftSlidePaneTemplate, itemScope, @_templateContext)
			cola.util.userData(leftSlidePaneTemplate, "scope", itemScope)
			cola._ignoreNodeRemoved = true
			itemsWrapper.appendChild(leftSlidePaneTemplate)
			cola._ignoreNodeRemoved = false

		if rightSlidePaneTemplate
			$fly(rightSlidePaneTemplate).addClass("item-slide-pane protected").css("right", "100%").click(()=>
				if @_itemSlideState is "waiting"
					@hideItemSlidePane()
				return
			)
			cola.xRender(rightSlidePaneTemplate, itemScope, @_templateContext)
			cola.util.userData(rightSlidePaneTemplate, "scope", itemScope)
			cola._ignoreNodeRemoved = true
			itemsWrapper.appendChild(rightSlidePaneTemplate)
			cola._ignoreNodeRemoved = false
		return

	_getTouchPoint: (evt) ->
		touches = evt.originalEvent.touches
		if !touches.length
			touches = evt.originalEvent.changedTouches
		return touches[0]

	_onItemsWrapperTouchStart: (evt) ->
		@_start = new Date

		return unless @_itemSlide and (!@_itemSlideState or @_itemSlideState == "closed" or @_itemSlideState == "ignore")

		itemDom = @_findItemDom(evt.target)
		if itemDom
			return if itemDom.offsetWidth < @_doms.itemsWrapper.clientWidth * 0.6 # 此逻辑用于判断List当前是否不处于“行模式”
			item = cola.util.userData(itemDom, "item")
		return unless item

		if @getListeners("itemSlideStart")
			arg =
				event: evt
				item: item
			if @fire("itemSlideStart", @, arg) == false
				return
		else
			if @_getItemType(item) == "group"
				return

		@_slideItemDom = itemDom
		@_itemSlideState = null

		touch = evt.originalEvent.touches[0]
		@_touchStartX = touch.pageX
		@_touchStartY = touch.pageY
		@_touchTimestamp = new Date()
		return

	_initItemSlidePane: (itemDom, direction) ->
		item = cola.util.userData(itemDom, "item")
		if direction != @_itemSlideDirection
			oldSlidePane = @_itemSlidePane
			if oldSlidePane
				$fly(oldSlidePane).hide()
				if !SAFE_SLIDE_EFFECT
					$fly(oldSlidePane).css("transform", "")

			@_itemSlideDirection = direction

			@_itemSlidePane = slidePane = @_getTemplate("slide-" + direction + "-pane")
			if slidePane
				itemScope = cola.util.userData(slidePane, "scope")
				itemScope.data.setTargetData(item)

				if @getListeners("itemSlidePaneInit")
					@fire("itemSlidePaneInit", @, {
						item: item
						direction: direction
						slidePane: slidePane
					})

				if direction == "left" and @_maxDistanceAdjust == undefined and @_indexBar
					indexBar = @_doms.indexBar
					if indexBar
						@_maxDistanceAdjust = indexBar.offsetWidth + parseInt($fly(indexBar).css("right"))
					else
						@_maxDistanceAdjust = 0

				$fly(slidePane).css({
					height: itemDom.offsetHeight
					top: itemDom.offsetTop
					"pointer-events": "none"
				}).show()

				@_maxSlideDistance = slidePane.offsetWidth
				if direction == "left"
					@_maxSlideDistance += (@_maxDistanceAdjust or 0)
			else
				@_maxSlideDistance = itemDom.offsetWidth
		else
			slidePane = @_itemSlidePane
		return slidePane

	_onItemsWrapperTouchMove: (evt) ->
		return unless @_itemSlide
		if @_itemSlideState == "prevent"
			evt.stopImmediatePropagation()
			return false
		return unless !@_itemSlideState or @_itemSlideState == "slide"

		touchPoint = @_getTouchPoint(evt)
		@_touchLastX = touchPoint.pageX
		@_touchLastY = touchPoint.pageY
		distanceX = @_touchLastX - @_touchStartX
		distanceY = @_touchLastY - @_touchStartY
		timestamp = new Date()

		itemDom = @_slideItemDom
		if !@_itemSlideState
			if Math.abs(distanceX) > 5 and Math.abs(distanceX) > Math.abs(distanceY)
				@_itemSlideState = "slide"
				@_itemSlideDirection = null

				# Chrome下会出现文字渲染重叠的现象
				if cola.browser.chrome
					itemDom.style.opacity = 0.999
			else
				@_itemSlideState = "ignore"
				return

		@_touchMoveSpeed = distanceX / (timestamp - @_touchLastTimstamp)
		@_touchLastTimstamp = timestamp

		if distanceX > 0
			direction = "right"
			factor = 1
		else
			direction = "left"
			factor = -1

		if itemDom.firstChild and itemDom.firstChild == itemDom.lastChild
			slideDom = itemDom.firstChild
		else
			slideDom = itemDom

		slidePane = @_initItemSlidePane(itemDom, direction)
		if slidePane
			if Math.abs(distanceX) <= @_maxSlideDistance
				@_currentSlideDistance = distanceX
			else
				@_currentSlideDistance = @_maxSlideDistance * factor

			if !SAFE_SLIDE_EFFECT
				translate = "translate(#{@_currentSlideDistance}px,0)"
				$fly(slideDom).css("transform", translate)
				$fly(slidePane).css("transform", translate)

			if @getListeners("itemSlideStep")
				item = cola.util.userData(itemDom, "item")
				@fire("itemSlideStep", @, {
					event: evt
					item: item
					direction: direction
					distance: distanceX
					speed: @_touchMoveSpeed
				})

		evt.stopImmediatePropagation()
		return false

	_onItemsWrapperTouchEnd: (evt) ->
		return unless @_itemSlideState == "slide"

		currentDistance = @_currentSlideDistance
		return if currentDistance == 0

		itemDom = @_slideItemDom
		maxDistance = @_maxSlideDistance
		opened = false
		if Math.abs(currentDistance) == maxDistance
			opened = true
		else if Math.abs(currentDistance) / maxDistance > 0.5
			opened = true
			openAnimate = true
		else if Math.abs(@_touchMoveSpeed) > 5
			opened = true
			openAnimate = true

		# Chrome下会出现文字渲染重叠的现象
		if cola.browser.chrome
			itemDom.style.opacity = ""

		direction = @_itemSlideDirection
		if opened
			@fire("itemSlideComplete", @, {
				event: evt
				item: cola.util.userData(itemDom, "item")
				direction: direction
				distance: @_currentSlideDistance
				speed: @_touchMoveSpeed
			})
		else
			@fire("itemSlideCancel", @, {
				direction: direction
				event: evt
				item: cola.util.userData(itemDom, "item")
			})


		if itemDom.firstChild and itemDom.firstChild == itemDom.lastChild
			slideDom = itemDom.firstChild
		else
			slideDom = itemDom

		if direction == "left"
			if !SAFE_SLIDE_EFFECT
				$(slideDom).transit({
					x: 0
					duration: SLIDE_ANIMATION_SPEED * 2
				})
		else
			$(slideDom).transit({
				x: maxDistance
				duration: SLIDE_ANIMATION_SPEED
			})

		if opened
			slidePane = @_itemSlidePane
			if slidePane
				@_showItemSlidePane(itemDom, direction, slidePane, openAnimate)
			else
				@_itemSlideState = "closed"
		else
			@_hideItemSlidePane(false)
		return

	_showItemSlidePane: (itemDom, direction, slidePane, openAnimate) ->
		$fly(@_doms.itemsWrapper).dimmer({
			opacity: 0.0001
			duration: 0
			closable: false
		}).dimmer("show").find(">.ui.dimmer").on("touchstart.hide", () =>
			if @_itemSlideState is "waiting"
				@hideItemSlidePane()
			return
		);

		$slidePane = $(slidePane)
		if openAnimate or SAFE_SLIDE_EFFECT
			factor = if direction == "left" then -1 else 1
			$slidePane.show().transit({
				x: @_maxSlideDistance * factor
				duration: SLIDE_ANIMATION_SPEED
				complete: () =>
					$slidePane.css("pointer-events", "")
					@_onItemSlidePaneShow(direction, slidePane, itemDom)
					return
			})
		else
			$slidePane.css("pointer-events", "")
			@_onItemSlidePaneShow(direction, slidePane, itemDom)
		return

	_hideItemSlidePane: (opened, animation) ->
		@_itemSlideState = "closing"

		itemDom = @_slideItemDom
		slidePane = @_itemSlidePane
		direction = @_itemSlideDirection

		if direction == "right"
			if itemDom.firstChild and itemDom.firstChild == itemDom.lastChild
				slideDom = itemDom.firstChild
			else
				slideDom = itemDom
			$(slideDom).transit({
				x: 0
				duration: SLIDE_ANIMATION_SPEED
			})

		$fly(@_doms.itemsWrapper).dimmer("hide");

		if slidePane
			$(slidePane).transit({
				x: 0
				duration: if animation then SLIDE_ANIMATION_SPEED else 0
				complete: () =>
					$fly(slidePane).hide()
					delete @_itemSlidePane
					@_onItemSlidePaneHide(opened, direction, slidePane, itemDom)
					return
			})
		else
			@_onItemSlidePaneHide(opened, direction, slidePane, itemDom)
		return

	_onItemSlidePaneShow: (direction, slidePane, itemDom) ->
		@_itemSlideState = "waiting"

		@fire("itemSlidePaneShow", @, {
			item: cola.util.userData(itemDom, "item")
			direction: direction
			slidePane: slidePane
		})
		return

	_onItemSlidePaneHide: (opened, direction, slidePane, itemDom) ->
		@_itemSlideDirection = null
		@_itemSlideState = "closed"
		@_slideItemDom = null

		if opened
			@fire("itemSlidePaneHide", @, {
				item: cola.util.userData(itemDom, "item")
				direction: direction
				slidePane: slidePane
			})
		return

	showItemSlidePane: (item, direction) ->
		entityId = cola.Entity._getEntityId(item)
		itemDom = @_itemDomMap[entityId]
		slidePane = @_initItemSlidePane(itemDom, direction)
		if slidePane
			@_slideItemDom = itemDom
			@_showItemSlidePane(itemDom, direction, slidePane, true)
		return

	hideItemSlidePane: (animation) ->
		@_hideItemSlidePane(true, animation)
		return

cola.defineWidget("c-listView", cola.ListView)