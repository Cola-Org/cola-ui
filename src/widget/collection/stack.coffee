#TODO 关于touchEnd在此控件之外触发的情况 后续解决
class cola.Stack extends cola.Widget
	@CLASS_NAME: "stack"
	@EVENTS:
		change: null
		beforeChange: null
	@duration: 200

	_initDom: (dom)->
		@_doms ?= {}
		itemsWrap = @getItemsWrap()

		unless @_doms.prevItem
			@_doms.prevItem = $.xCreate({class: "prev item"})
			$fly(itemsWrap).prepend(@_doms.prevItem)
		unless @_doms.currentItem
			@_doms.currentItem = $.xCreate({class: "current item"})
			$fly(@_doms.prevItem).after(@_doms.currentItem)

		unless @_doms.nextItem
			@_doms.nextItem = $.xCreate({class: "next item"})
			$fly(@_doms.currentItem).after(@_doms.nextItem)

		@_prevItem = @_doms.prevItem
		@_currentItem = @_doms.currentItem
		@_nextItem = @_doms.nextItem

		$fly(@_currentItem).css({display: "block"})
	_parseDom: (dom)->
		parseItem = (node)=>
			@_items = []
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					if $fly(childNode).hasClass("prev")
						@_doms.prevItem = childNode
					else if $fly(childNode).hasClass("current")
						@_doms.currentItem = childNode
					else if $fly(childNode).hasClass("next")
						@_doms.nextItem = childNode
				childNode = childNode.nextSibling
			return

		doms = @_doms
		child = dom.firstChild
		while child
			if child.nodeType == 1
				if cola.util.hasClass(child, "items-wrap")
					doms.wrap = child
					parseItem(child)
			child = child.nextSibling

	getItemContainer: (key)-> @["_#{key}Item"]
	getItemsWrap: ()->
		unless @_doms.itemsWrap
			wrap = $.xCreate({class: "items-wrap"})
			@_doms.itemsWrap = wrap
			@_dom.appendChild(wrap)
		return @_doms.itemsWrap

	_setDom: (dom, parseChild)->
		super(dom, parseChild)
		stack = @
		$(dom).on("touchstart", (evt) -> stack._onTouchStart(evt))
		.on("touchmove", (evt) -> stack._onTouchMove(evt))
		.on("touchend", (evt) -> stack._onTouchEnd(evt))

	_getTouchPoint: (evt) ->
		touches = evt.originalEvent.touches
		if !touches.length
			touches = evt.originalEvent.changedTouches
		return touches[0]

	_onTouchStart: (evt) ->
		@_touchStart = true
		touch = evt.originalEvent.touches[0]
		@_touchStartX = touch.pageX
		@_touchStartY = touch.pageY
		@_moveTotal = 0
		@_touchTimestamp = new Date()
		evt.stopImmediatePropagation()
		return @

	_onTouchMove: (evt) ->
		return unless @_touchStart
		touchPoint = @_getTouchPoint(evt)
		@_touchLastX = touchPoint.pageX
		@_touchLastY = touchPoint.pageY
		distanceX = @_touchLastX - @_touchStartX
		distanceY = @_touchLastY - @_touchStartY
		timestamp = new Date()

		@_touchMoveSpeed = distanceX / (timestamp - @_touchLastTimstamp)
		@_touchLastTimstamp = timestamp
		if distanceX < 0
			direction = "left"
			factor = 1
		else
			direction = "right"
			factor = -1
		@_touchDirection = direction
		@_factor = factor
		width = @_currentItem.clientWidth
		@_distanceX = Math.abs(distanceX)
		@_moveTotal = ( @_moveTotal || 0 ) + Math.abs(distanceX)

		return if @_moveTotal < 8
		$fly(@_currentItem).css("transform", "translate(#{distanceX}px,0)")
		if direction is "left"
			$fly(@_prevItem).css("display", "none")
			$fly(@_nextItem).css({
				transform: "translate(#{width + distanceX}px,0)"
				display: "block"
			})
		else
			$fly(@_nextItem).css("display", "none")
			$fly(@_prevItem).css({
				transform: "translate(#{factor * width + distanceX}px,0)"
				display: "block"
			})
		evt.stopImmediatePropagation()
		return false

	_onTouchEnd: (evt) ->
		return unless @_touchStart
		duration = @constructor.duration
		width = @_currentItem.clientWidth
		@_touchStart = false
		restore = ()=>
			$(@_currentItem).transit({
				x: 0
				duration: duration
			})

			if @_touchDirection == "left"
				$(@_nextItem).transit({
					x: width
					duration: duration
				})
			else
				$(@_prevItem).transit({
					x: -1 * width
					duration: duration
				})
			return

		if @_moveTotal < 8
			restore()
			return
		arg =
			current: @_currentItem
			prev: @_prevItem
			next: @_nextItem
			action: "over"
		if @_distanceX > width / 3
			if @_touchDirection == "left"
				if @fire("beforeChange", @, arg) is false
					restore()
					return
				$(@_currentItem).transit({
					x: -1 * width
					duration: duration
				})
				$(@_nextItem).transit({
					x: 0
					duration: duration
				})
				@_doNext()
			else
				arg.action = "back"
				if @fire("beforeChange", @, arg) is false
					restore()
					return
				$(@_currentItem).transit({
					x: width
					duration: duration
				})
				$(@_prevItem).transit({
					x: 0
					duration: duration
				})
				@_doPrev()
		else
			restore()


		return

	next: ()->
		if @_animating then return
		arg =
			current: @_currentItem
			prev: @_prevItem
			next: @_nextItem
			action: "over"
		if @fire("beforeChange", @, arg) is false then return


		@_animating = true
		width = @_currentItem.clientWidth
		stack = @
		duration = @constructor.duration
		$fly(@_nextItem).css({
			transform: "translate(#{width}px,0)"
			display: "block"
		})

		$(@_currentItem).transit({
			x: -1 * width
			duration: duration * 2
			complete: ()->
				stack._animating = false
				$(stack._currentItem).css("display", "none")
				stack._doNext()
		})

		$(@_nextItem).transit({
			x: 0
			duration: duration * 2
		})

		return @
	prev: ()->
		if @_animating then return
		arg =
			current: @_currentItem
			prev: @_prevItem
			next: @_nextItem
			action: "back"
		if @fire("beforeChange", @, arg) is false then return

		@_animating = true
		width = @_currentItem.clientWidth
		stack = @
		duration = @constructor.duration
		$fly(@_prevItem).css({
			transform: "translate(-#{width}px,0)"
			display: "block"
		})

		$(@_currentItem).transit({
			x: width
			duration: duration * 2
			complete: ()->
				$(stack._currentItem).css("display", "none")
				stack._animating = false
				stack._doPrev()
		})

		$(@_prevItem).transit({
			x: 0
			duration: duration * 2
		})

		return @

	_doNext: ()->
		prevItem = @_prevItem
		currentItem = @_currentItem
		nextItem = @_nextItem

		@_prevItem = currentItem
		@_nextItem = prevItem
		@_currentItem = nextItem

		@fire("change", @, {
			current: @_currentItem
			prev: @_prevItem
			next: @_nextItem
			action: "over"
		})

		return null

	_doPrev: ()->
		prevItem = @_prevItem
		currentItem = @_currentItem
		nextItem = @_nextItem

		@_prevItem = nextItem
		@_nextItem = currentItem
		@_currentItem = prevItem

		@fire("change", @, {
			current: @_currentItem
			prev: @_prevItem
			next: @_nextItem
			action: "back"
		})
		return null

cola.defineWidget("c-stack", cola.Stack)