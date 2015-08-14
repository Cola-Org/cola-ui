class cola.AbstractEditor extends cola.Widget
	@ATTRIBUTES:
		value:
			refreshDom: true
			setter: (value)-> @_setValue(value)
		bind:
			refreshDom: true
			setter: (bindStr) -> @_bindSetter(bindStr)
		readOnly:
			refreshDom: true
			defaultValue: false

	@EVENTS:
		beforePost: null
		post: null
		beforeChange: null
		change: null

	_setValue: (value)->
		return false if @_value is value
		arg = {oldValue: @_value, value: value}
		return if @fire("beforeChange", @, arg) is false
		@_value = value
		@fire("change", @, arg)
		@post() if value isnt @_modelValue
		return true

	post: ()->
		return @ if @fire("beforePost", @) is false
		@_post()
		@fire("post", @)
		return @

	_post: ()->
		@_writeBindingValue(@_value)
		return

	_processDataMessage: (path, type, arg) ->
		value = @_readBindingValue()
		if @_dataType
			value = @_dataType.parse(value)
		@_modelValue = value
		if @_setValue(value)
			cola.util.delay(@, "refreshDom", 50, @_refreshDom)
		return

cola.Element.mixin(cola.AbstractEditor, cola.DataWidgetMixin)
