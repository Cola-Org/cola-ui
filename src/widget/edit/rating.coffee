class cola.Rating extends cola.Widget
	@CLASS_NAME: "rating"
	@ATTRIBUTES:
		rating:
			type: "number"
			defaultValue: 0
			refreshDom: true

		maxRating:
			type: "number"
			refreshDom: true
			defaultValue: 1
			setter: (value)->
				@_maxRating = value
				@_refreshRating = true
		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				@get$Dom().removeClass(oldValue) if oldValue and oldValue isnt value and @_dom
				@["_size"] = value
				return

	@EVENTS:
		rate: null
	_fireRate: ()->
		cola.util.cancelDelay(@, "_fireRate")
		@fire("rate", @, {rating: @_rating})
	_doRefreshRating: ()->
		@_refreshRating = false
		rating = @get("rating")
		maxRating = @get("maxRating")
		@_rating = rating = maxRating if rating > maxRating
		@get$Dom().empty().rating({
			initialRating: rating
			maxRating: maxRating
			onRate: (value)=>
				if value isnt @_rating
					@set("rating", value)
					cola.util.delay(@, "_fireRate", 50, @_fireRate)
		}).rating(if @_disabled then "disable" else "enable")
		return
	_initDom: (dom)-> @_doRefreshRating()
	_doRefreshDom: ()->
		return unless @_dom
		super()
		if @_refreshRating
			@_doRefreshRating()
		else
			$dom = @get$Dom()
			$dom.rating(if @_disabled then "disable" else "enable")
			if $dom.rating("get rating") != @_rating
				$dom.rating("set rating", @_rating)
		return
	clear: ()->
		@set("rating", 0)
		return @


cola.Element.mixin(cola.Rating, cola.DataWidgetMixin)