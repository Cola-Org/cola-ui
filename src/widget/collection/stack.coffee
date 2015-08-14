#TODO 关于touchEnd在此控件之外触发的情况 后续解决
class cola.Stack extends cola.Widget
	@CLASS_NAME: "stack"
	@EVENTS:
		change: null
	@duration: 200
	_createDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			content: [{
				tagName: "div"
				class: "items-wrap"
				contextKey: "itemsWrap"
				content: [
					{
						tagName: "div"
						class: "item black prev"
						contextKey: "prevItem"
					}
					{
						tagName: "div"
						class: "item blue current"
						contextKey: "currentItem"
						style: {
							display: "block"
						}
					}
					{
						tagName: "div"
						class: "item green next"
						contextKey: "nextItem"
					}
				]
			}]
		}, @_doms)

		@_prevItem = @_doms.prevItem
		@_currentItem = @_doms.currentItem
		@_nextItem = @_doms.nextItem

		return dom
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
		if @_moveTotal < 8 then return
		if @_distanceX > width / 3
			if @_touchDirection == "left"
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
		@_touchStart = false

		return

	next: ()->
		if @_animating then return
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
		})
		return null