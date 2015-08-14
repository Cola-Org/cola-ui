
cola.shape ?= {}
class cola.shape.Side extends cola.Widget
	@ATTRIBUTES:
		content:
			refreshDom: true
			setter: (value)->
				@["_content"]?.destroy?()
				@["_content"] = value
				@_refreshContent() if @_dom
				return

		active:
			defaultValue: false

	_createDom: ()->
		dom = document.createElement("div")
		dom.className = "side"
		return dom

	_refreshContent: ()->
		content = @_content
		dom=null
		if content instanceof cola.Widget
			dom=content.getDom()
		else if content.constructor == Object.prototype.constructor
			if content.$type
				content = @_content = cola.widget(content)
				content.appendTo(@_dom)
			else
				@get$Dom().append($.xCreate(content))
		else if content.nodeType == 1
			@get$Dom().append(content)

		return

	getDom: ()->
		return if @_destroyed
		unless @_dom
			super()
			@_refreshContent() if @_content

		return @_dom

	destroy: ()->
		unless @_destroyed
			delete @_dom
			delete @_$dom
			delete @_content
			super()
		@_destroyed = true
		return

class cola.Shape extends cola.Widget
	@CLASS_NAME: "ui shape"
	@ATTRIBUTES:
		sides:
			setter: (sides)->
				@clear()
				@addSide(config) for config in sides
				return

		currentIndex:
			setter: (sides)->
				@clear()
				@addSide(config) for config in sides
				return

	@EVENTS:
		beforeChange: null
		afterChange: null

	addSide: (config)->
		@_sides ?= []
		side = null

		if config instanceof cola.Widget
			side = new cola.shape.Side({
				content: config
			})
		else if config.constructor == Object.prototype.constructor
			if config.$type or config.tagName
				side = new cola.shape.Side({
					content: config
				})
			else if config.tagName
				side = new cola.shape.Side(config)

		@_sides.push(side) if side
		if @_dom and side
			$(@_doms.sides).append(side.getDom())

		return @

	removeSide: (side)->
		index = side

		if side instanceof cola.shape.Side
			index = @_sides.indexOf(side)

		if index > -1
			@_sides.splice(index, 1)
			side.remove()

		return

	clear: ()->
		return unless @_sides
		side.destroy() for side in @_sides
		@_sides = []
		$(@_doms.sides).empty()
		return @

	_createDom: ()->
		return $.xCreate({
			tagName: "div"
			class: @constructor.CLASS_NAME
			content: [
				{
					tagName: "div"
					class: "sides"
					contextKey: "sides"
				}
			]
		}, @_doms)

	getDom: ()->
		return null if @_destroyed
		unless @_dom
			@_doms ?= {}
			super()

			$sidesDom = $(@_doms.sides)
			if @_sides
				current = null

				for side in @_sides
					$sidesDom.append(side.getDom())
					current = side if !!side.get("active")

				current ?= @_sides[0]
				current.get$Dom().addClass("active")

			@get$Dom().shape({
				beforeChange: ()=>
					@fire("beforeChange", @, {current: @_current})
					return

				onChange: ()=>
					@_current = null
					for side in @_sides
						side.get$Dom().hasClass("active")
						@_current = side
						break

					@fire("afterChange", @, {current: @_current})
					return

			})


		return @_dom

	getSide: (index)->
		return @_sides?[index]

	getSideDom: (index)->
		return @_sides?[index]?.getDom()

	flipUp: ()->
		@get$Dom().shape("flip up")
		return @

	flipDown: ()->
		@get$Dom().shape("flip down")
		return @

	flipRight: ()->
		@get$Dom().shape("flip right")
		return @

	flipLeft: ()->
		@get$Dom().shape("flip left")
		return @

	flipOver: ()->
		@get$Dom().shape("flip over")
		return @

	flipBack: ()->
		@get$Dom().shape("flip back")
		return @

	flip: (flip)->
		@get$Dom().shape("flip #{flip}")
		return @

	setNextSide: (selector)->
		@get$Dom().shape("set next side", selector)
		return @



