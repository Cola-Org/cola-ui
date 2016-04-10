class cola.Divider extends cola.AbstractContainer
	@CLASS_NAME: "divider"
	@ATTRIBUTES:
		direction:
			enum: ["vertical", "horizontal", ""]
			defaultValue: ""
			refreshDom: true
			setter: (value)->
				oldValue = @_direction
				@_direction = value
				if @_dom and oldValue and oldValue isnt value
					@removeClass(oldValue)
				return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		if @_direction then @_classNamePool.add(@_direction)
		return

cola.defineWidget("c-divider", cola.ButtonGroup)