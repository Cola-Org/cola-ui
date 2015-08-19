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
		state:
			setter: (state) ->
				oldState = @_state
				if oldState != state
					dom = @_dom
					if dom and oldState
						cola.util.removeClass(dom, oldState)
						cola.util.removeClass(@_fieldDom, oldState) if @_fieldDom

					@_state = state

					if dom and state
						cola.util.addClass(dom, state)
						cola.util.addClass(@_fieldDom, state) if @_fieldDom
				return

	@EVENTS:
		beforePost: null
		post: null
		beforeChange: null
		change: null

	_initDom: (dom) ->
		if @_state
			cola.util.addClass(dom, @_state)

		fieldDom = dom.parentNode
		if fieldDom and not jQuery.find.matchesSelector(fieldDom, ".field")
			fieldDom = null
		@_fieldDom = fieldDom
		return

	_setValue: (value) ->
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

	_filterDataMessage: (path, type, arg) ->
		return cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or type == cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or @_watchingMoreMessage

	_processDataMessage: (path, type, arg) ->
		if type == cola.constants.MESSAGE_VALIDATION_STATE_CHANGE
			if @_formDom == undefined
				if @_fieldDom
					$formDom = $fly(@_fieldDom).closest(".ui.form")
				@_formDom = $formDom?[0] or null

			if @_formDom
				form = cola.widget(@_formDom)
				if form and form instanceof cola.Form
					keyMessage = arg.entity.getKeyMessage(arg.property)
					form.setFieldMessages(@, keyMessage)
		else
			value = @_readBindingValue()
			if @_dataType
				value = @_dataType.parse(value)
			@_modelValue = value
			if @_setValue(value)
				cola.util.delay(@, "refreshDom", 50, @_refreshDom)
			return

cola.Element.mixin(cola.AbstractEditor, cola.DataWidgetMixin)
