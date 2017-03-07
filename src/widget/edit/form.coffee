class cola.Form extends cola.Widget
	@tagName: "c-form"
	@CLASS_NAME: "form"

	@attributes:
		bind: null

	constructor: (config) ->
		@_messageHolder = new cola.Entity.MessageHolder()
		super(config)

	_initDom: (dom) ->
		super(dom)
		@_$messages = @get$Dom().find("messages, .ui.message").addClass("messages")
		return

	refreshMessages: () ->
		return unless @_$messages.length

		messageHolder = @_messageHolder
		messageHolder.clear()

		fieldDoms = @_dom.querySelectorAll("field")
		for fieldDom in fieldDoms
			field = cola.widget(fieldDom)
			if field?._message
				messageHolder.add("$", field?._message)

		keyMessage = messageHolder.getKeyMessage()
		state = keyMessage?.type

		messageCosons = []
		messages = messageHolder.findMessages(null, state)
		if messages
			for m in messages
				if m.text
					messageCosons.push(
						tagName: "li"
						content: m.text
					)

		@_$dom.removeClass("error warning success").addClass(state)
		@_$messages.removeClass("error warning success").addClass(state).empty()
		if messageCosons.length > 0
			@_$messages.xAppend({
				tagName: "ul"
				class: "list"
				content: messageCosons
			})
		return

cola.registerWidget(cola.Form)


class cola.Field extends cola.Widget
	@tagName: "field"
	@CLASS_NAME: "field"

	@attributes:
		bind:
			setter: (bindStr) ->
				if @_domParsed
					@_bindSetter(bindStr)
				else
					@_bind = bindStr
				return

		property: null
		message:
			readOnly: true
			getter: () ->
				if @_messageDom
					return @_message
				else

	_parseDom: (dom) ->
		@_domParsed = true

		if not @_bind and @_property
			if dom.parentNode
				if dom.parentNode.nodeName is "C-FORM"
					@_formDom = dom.parentNode
				else if dom.parentNode.parentNode?.nodeName is "C-FORM"
					@_formDom = dom.parentNode.parentNode

			if @_formDom
				@_form = cola.widget(@_formDom)
				formBind = @_form?._bind
				if formBind
					bind = formBind + "." + @_property
				else
					bind = @_property
				@set("bind", bind)

		@_messageDom = dom.querySelector("message")
		if @_messageDom and @_bind
			@_bind = null
			@_bindSetter(@_bind)
		return

	_filterDataMessage: (path, type, arg) ->
		return type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or cola.constants.MESSAGE_REFRESH

	_processDataMessage: (path, type, arg) ->
		if type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or cola.constants.MESSAGE_REFRESH
			if @_bindInfo?.writeable
				entity = @_scope.get(@_bindInfo.entityPath)
				if entity instanceof cola.EntityList
					entity = entity.current
				if entity
					keyMessage = entity.getKeyMessage(@_bindInfo.property)
					@setMessages(keyMessage)
		return

	setMessages: (message) ->
		@_message = message

		if @_messageDom
			$message = $fly(@_messageDom)
			$message.removeClass("error warning success")
			if message
				$message.addClass(message.type).text(message.text)
			else
				$message.empty()

		@_form?.refreshMessages()
		return

cola.Element.mixin(cola.Field, cola.DataWidgetMixin)
cola.registerWidget(cola.Field)