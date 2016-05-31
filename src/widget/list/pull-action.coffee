SAFE_PULL_EFFECT = cola.os.android and !cola.browser.chrome

class cola.PullAction
	constructor: (@content, options) ->
		@contentWrapper = @content.parentNode
		@options =
			resistance: 2.5
			startTheshold: 10
			pullTheshold: 0.4
		for k, v of options
			@options[k] = v

		pullDownPane = @options.pullDownPane
		if pullDownPane and typeof pullDownPane == "string"
			pullDownPane = document.body.querySelector(pullDownPane)
		if pullDownPane
			@pullDownPane = pullDownPane
			if @content.previousSibling != pullDownPane
				$fly(@content).before(pullDownPane)
			$fly(pullDownPane).addClass("pull-down-pane")
			@pullDownDistance = pullDownPane.offsetHeight
			@contentWrapper.scrollTop = @pullDownDistance

		pullUpPane = @options.pullUpPane
		if pullUpPane and typeof pullUpPane == "string"
			pullUpPane = document.body.querySelector(pullUpPane)
		if pullUpPane
			@pullUpPane = pullUpPane
			if @content.nextSibling != pullUpPane
				$fly(@content).after(pullUpPane)
			$fly(pullUpPane).addClass("pull-up-pane")
			@pullUpDistance = pullUpPane.offsetHeight

		$(@content)
		.on("touchstart", (evt) => @_onTouchStart(evt))
		.on("touchmove", (evt) => @_onTouchMove(evt))
		.on("touchend", (evt) => @_onTouchEnd(evt))

	_getTouchPoint: (evt) ->
		touches = evt.originalEvent.touches
		if !touches.length
			touches = evt.originalEvent.changedTouches
		return touches[0]

	_onTouchStart: (evt) ->
		if @_disabled
			@pullState = null
			@_watchingTouchMove = false
		else
			@_scrollTop = @content.scrollTop
			if @options.pullDownPane and @_scrollTop <= 0
				@pullState = "pre-down"
				@_watchingTouchMove = true
			else if @options.pullUpPane and (@_scrollTop + @content.clientHeight) >= @content.scrollHeight
				@pullState = "pre-up"
				@_watchingTouchMove = true
			else
				@pullState = null
				@_watchingTouchMove = false
		@pullReached = false

		@_panStarted = 0
		if @_watchingTouchMove
			touchPoint = @_getTouchPoint(evt)
			@_touchStartX = touchPoint.pageX
			@_touchStartY = touchPoint.pageY

			# 改善ios下当bounce滚动效果为结束时再次下拉的显示效果
			if cola.os.ios
				if @_scrollTop < 0 or (@_scrollTop + @content.clientHeight) > @content.scrollHeight
					return false
		return

	_onTouchMove: (evt) ->
		return if !@_watchingTouchMove

		touchPoint = @_getTouchPoint(evt)
		distanceX = touchPoint.pageX - @_touchStartX
		distanceY = touchPoint.pageY - @_touchStartY

		if !@_panStarted
			if Math.abs(distanceX) < 20 and (distanceY > 0 and @pullState == "pre-down" or distanceY < 0 and @pullState == "pre-up")
				startTheshold = @options.startTheshold
				if distanceY > startTheshold and @pullState == "pre-down"
					@pullState = "down"
				else distanceY < -startTheshold and if @pullState == "pre-up"
					@pullState = "up"

				if @pullState == "down" or @pullState == "up"
					@_panStarted = new Date()
					pullPane = if @pullState == "down" then @options.pullDownPane else @options.pullUpPane
					if @options.pullStart?(evt, pullPane, @pullState) == false
						@pullState = null
						@_watchingTouchMove = false
						return

				retValue = false

		if @_panStarted
			@_onPanMove(evt, Math.abs(distanceY))

		if retValue == false or @_panStarted
			evt.stopImmediatePropagation()
			return false
		else
			return

	_onPanMove: (evt, distance) ->
		distance = distance / @options.resistance
		@_distance = distance

		if @pullState == "down"
			maxDistance = @pullDownDistance
			pullTheshold = maxDistance * @options.pullTheshold
			reached = distance > pullTheshold
			if distance > maxDistance then distance = maxDistance
			pullPane = @options.pullDownPane
			@contentWrapper.scrollTop = maxDistance - distance
		else if @pullState == "up"
			maxDistance = @pullUpDistance
			pullTheshold = maxDistance * @options.pullTheshold
			reached = distance > pullTheshold
			if distance > maxDistance then distance = maxDistance
			pullPane = @options.pullUpPane
			@contentWrapper.scrollTop = @options.pullUpPane.offsetTop - @contentWrapper.clientHeight + distance

		if pullPane
			@pullReached = reached
			$fly(pullPane).toggleClass("reached", reached)
			@options.pullStep?(evt, pullPane, @pullState, distance, pullTheshold)
		return

	_onTouchEnd: (evt) ->
		return if !@_panStarted

		pullState = @pullState
		if pullState == "down"
			pullPane = @options.pullDownPane
		else if pullState == "up"
			pullPane = @options.pullUpPane
		return unless pullPane

		@_disabled = true
		$fly(pullPane).removeClass("reached")

		if @pullReached
			if @pullState == "down"
				scrollTop = @pullDownDistance * (1 - @options.pullTheshold)
			else
				scrollTop = (@options.pullUpPane.offsetTop - @contentWrapper.clientHeight) + @pullUpDistance * (1 - @options.pullTheshold)

			if SAFE_PULL_EFFECT
				@contentWrapper.scrollTop = scrollTop
			else
				$fly(@contentWrapper).animate({
					scrollTop: scrollTop
				}, {
					duration: 200
				})

			$fly(pullPane).addClass("executing")
			pullAction = @
			@_executePullAction(evt, pullState, () ->
				pullAction._hidePullPane(pullState)
				return
			)
		else
			@options.pullCancel?(evt, pullPane, pullState)
			@_hidePullPane(pullState)
		return

	_executePullAction: (evt, pullState, done) ->
		if @options.pullComplete
			pullPane = if @pullState == "down" then @options.pullDownPane else @options.pullUpPane
			@options.pullComplete(evt, pullPane, pullState, done)
		else
			done()
		return

	_hidePullPane: (pullState) ->
		if pullState == "down"
			pullPane = @options.pullDownPane
		else if pullState == "up"
			pullPane = @options.pullUpPane

		if SAFE_PULL_EFFECT
			@contentWrapper.scrollTop = @pullDownDistance
			@_disabled = false
			$fly(pullPane).removeClass("executing")
		else
			pullAction = @
			$(@contentWrapper).animate({
				scrollTop: @pullDownDistance
			}, {
				duration: 200
				complete: () ->
					pullAction._disabled = false
					$fly(pullPane).removeClass("executing")
					return
			})

		# QQ浏览器只设置scrollTop无法正确的完成刷新
		if cola.os.android and cola.browser.qqbrowser
			contentWrapperStyle = @contentWrapper.style
			if contentWrapperStyle.marginTop
				contentWrapperStyle.marginTop = ""
			else
				contentWrapperStyle.marginTop = "0.001px"
		return