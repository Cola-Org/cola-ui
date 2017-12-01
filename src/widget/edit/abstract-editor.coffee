class cola.AbstractEditor extends cola.Widget
	@attributes:
		value:
			refreshDom: true
			setter: (value)-> @_setValue(value)
		bind:
			refreshDom: true
			setter: (bindStr)-> @_bindSetter(bindStr)
		readOnly:
			refreshDom: true
			type: "boolean"
			defaultValue: false
		state:
			setter: (state)->
				oldState = @_state
				if oldState != state
					dom = @_dom
					if dom and oldState
						cola.util.removeClass(dom, oldState)

					@_state = state

					if dom and state
						cola.util.addClass(dom, state)
				return

	@events:
		beforePost: null
		post: null
		beforeChange: null
		change: null

	_initDom: (dom)->
		if @_state
			cola.util.addClass(dom, @_state)

		if not @_bind
			fieldDom = dom.parentNode
			if fieldDom?.nodeName is "FIELD"
				field = @_field = cola.widget(fieldDom)
				if field
					if field._bind or field._property
						bind = field._bind
						if not bind and field._form
							bind = field._form._bind + "." + field._property
						@set("bind", bind)
						if field._finalReadOnly
@_readOnlyFactor ?= {}
					@_readOnlyFactor.field= field._finalReadOnly
						return
		return

	_setValue: (value)->
		return false if @_value is value
		arg = {oldValue: @_value, value: value}

		if not @_modelSetValue
			return if @fire("beforeChange", @, arg) is false
			@_value = value
			@fire("change", @, arg)
		else
			@_value = value

		if value isnt @_modelValue and @_rendered
			@post()

		@onSetValue?(value)

		return true

	post: ()->
		if @fire("beforePost", @) is false
			@refreshValue()
			return @

		@_post()
		@fire("post", @)
		return @

	_post: ()->
		@writeBindingValue(@_value)
		return

	_filterDataMessage: (path, type, arg)->
		return cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or
		  type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or @_watchingMoreMessage

	_processDataMessage: (path, type, arg)->
		if type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE
			if @_bindInfo?.writeable
				entity = @_scope.get(@_bindInfo.entityPath)
				if entity instanceof cola.EntityList
					entity = entity.current
				if entity
					keyMessage = entity.getKeyMessage?(@_bindInfo.property)
					@set("state", keyMessage?.type)

		if type isnt cola.constants.MESSAGE_VALIDATION_STATE_CHANGE and type < cola.constants.MESSAGE_LOADING_START
			@_modelSetValue = true
			if @refreshValue()
				cola.util.delay(@, "refreshDom", 0, @_refreshDom)
			@_modelSetValue = false

		return

	refreshValue: ()->
		ctx = {}
		value = @readBindingValue(ctx)

		@_readOnlyFactor ?= {}
		if @_readOnlyFactor.model != ctx.readOnly
			shouldRefresh = true
			@_readOnlyFactor.model = ctx.readOnly
		if value? and @_dataType
			value = @_dataType.parse(value)
		@_modelValue = value

		changed = @_setValue(value)
		if shouldRefresh
			@_refreshDom()

		return changed

	_doRefreshDom: () ->
		return unless @_dom

		@_finalReadOnly = !!@get("readOnly")
		if not @_finalReadOnly and @_readOnlyFactor
			for factor, readOnly of @_readOnlyFactor
				if readOnly
					@_finalReadOnly = true
					break

		return super()

cola.Element.mixin(cola.AbstractEditor, cola.DataWidgetMixin)
