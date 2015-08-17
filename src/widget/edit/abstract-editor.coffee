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
		if jQuery.find.matchesSelector(fieldDom, ".field")
			$formDom = $fly(fieldDom).closest(".ui.form")
		else
			fieldDom = null
		@_fieldDom = fieldDom or null
		@_formDom = $formDom[0] or null

		if fieldDom
			cola.util.addClass(fieldDom, @_state)

		if @_formDom
			if not $formDom.data("_colaFormInited")
				inline = $formDom.find(">.ui.message").length is 0
				$formDom.data("_colaFormInited", true).data("_setting.inline", inline).form(
					on: "_disabled"
					inline: inline
				)
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
			if @_formDom
				keyMessage = arg.entity.getKeyMessage(arg.property)
				@set("state", keyMessage?.type)

				if @_formDom
					classPool = new cola.ClassNamePool(@_formDom.className)
					topKeyMessage = arg.entity.getKeyMessage()
					classPool.remove("info").remove("warning").remove("error")
					if topKeyMessage?.type
						classPool.add(topKeyMessage.type)
					@_formDom.className = classPool.join()

				$formDom = $fly(@_formDom)
				if not $formDom.data("_setting.inline")	# Semantic UI的BUG导致无法通过get settings获得settings
					errors = []
					messages = arg.entity.findMessages(null, "error")
					if messages
						errors.push(m.text) for m in messages
					$formDom.form("add errors", errors)
				else
					editorDom = @_$dom.find("input, textarea, select")[0]
					if editorDom
						editorDom.id or= cola.uniqueId()
						if keyMessage?.type is "error"
							$formDom.form("add prompt", editorDom.id, keyMessage.text)
						else
							$formDom.form("remove prompt", {identifier: editorDom.id})
		else
			value = @_readBindingValue()
			if @_dataType
				value = @_dataType.parse(value)
			@_modelValue = value
			if @_setValue(value)
				cola.util.delay(@, "refreshDom", 50, @_refreshDom)
			return

cola.Element.mixin(cola.AbstractEditor, cola.DataWidgetMixin)
