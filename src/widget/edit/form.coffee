class cola.Form extends cola.Widget
	@tagName: "c-form"
	@CLASS_NAME: "form"

	@attributes:
		bind:
			setter: (bindStr) -> @_bindSetter(bindStr)
		state:
			setter: (state) ->
				return if @_state is state
				@_state = state
				if @_$dom
					@_$dom.removeClass("error warning info").addClass(state)
				return

	constructor: (config) ->
		@_messageHolder = new cola.Entity.MessageHolder()
		super(config)

	_initDom: (dom) ->
		$dom = $(dom)
		$dom.addClass(@_state) if @_state
		return

	_filterDataMessage: (path, type, arg) ->
		return type is cola.constants.MESSAGE_REFRESH or type is cola.constants.MESSAGE_CURRENT_CHANGE or type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE

	_processDataMessage: (path, type, arg) ->
		entity = @_bindInfo.expression.evaluate(@_scope, "never")
		if entity and entity instanceof cola.Entity
			@_resetEntityMessages()
		else
			entity = null
		@_entity = entity
		@_refreshState()
		return

	_getEntity: () ->
		return @_entity if @_entity
		return @_scope.get()

	_refreshState: () ->
		return unless @_$dom

		keyMessage = @_messageHolder.getKeyMessage()
		state = keyMessage?.type

		messageCosons = []
		messages = @_messageHolder.findMessages(null, state)
		if messages
			for m in messages
				if m.text
					messageCosons.push(
						tagName: "li"
						content: m.text
					)

		$messages = @_$dom.find("messages, .ui.message")
		$messages.empty()
		if messageCosons.length > 0
			$messages.xAppend({
				tagName: "ul"
				class: "list"
				content: messageCosons
			})

		@set("state", state)
		return

	_resetEntityMessages: () ->
		return unless @_$dom

		messageHolder = @_messageHolder
		messageHolder.clear()
		entity = @_getEntity()
		if entity
			messages = entity.findMessages()
			if messages
				for message in messages
					messageHolder.add("$", message)
		return

	setMessages: (messages) ->
		messageHolder = @_messageHolder
		messageHolder.clear()
		if messages
			for message in messages
				messageHolder.add("$", message)
		@_refreshState()
		return

	setFieldMessages: (editor, message) ->
		$message = editor._$dom.closest(".field").find("message")
		$message.removeClass("error warning info")
		if message
			$message.addClass(message.type).text(message.text)
		else
			$message.empty()

		@_resetEntityMessages()
		@_refreshState()
		return

cola.Element.mixin(cola.Form, cola.DataWidgetMixin)

cola.registerWidget(cola.Form)