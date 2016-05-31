class cola.Divider extends cola.AbstractContainer
	@tagName: "c-divider"
	@CLASS_NAME: "divider"

	@attributes:
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

cola.registerWidget(cola.Divider)