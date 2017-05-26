class cola.Form extends cola.Widget
	@tagName: "c-form"
	@CLASS_NAME: "form"

	@attributes:
		bind:
			setter: (bindStr) -> @_bindSetter(bindStr)

		defaultCols:
			defaultValue: 3
		fields:
			readOnlyAfterCreate: true

	constructor: (config) ->
		@_messageHolder = new cola.Entity.MessageHolder()
		super(config)

	_initDom: (dom) ->
		super(dom)
		@_$messages = @get$Dom().find("messages, .ui.message").addClass("messages")

		if @_fields
			dataType = @getBindingDataType()
			childDoms = []
			maxCols = @_defaultCols
			defaultFieldCols = 1
			usedCols = maxCols

			for field in @_fields
				if dataType
					propertyDef = dataType.getProperty(field.property)
				if propertyDef
					caption = field.caption or propertyDef.get("caption") or field.property
					propertyType = propertyDef.get("dataType")
				else
					caption = field.caption or field.property
					propertyType = null

				if usedCols + (field.cols or defaultFieldCols) > maxCols
					usedCols = 0
					fieldsDom =
						tagName: "fields"
						class: "cols-" + maxCols
						content: []
					childDoms.push(fieldsDom)

				if field.editContent
					fieldContent = [
						{ tagName: "label", content: caption }
						field.editContent
					]
				else if propertyType instanceof cola.BooleanDataType
					if field.type is "checkbox"
						fieldContent = [
							{ tagName: "label", content: caption }
							{ tagName: "c-checkbox", bind: @_bind + "." + field.property }
						]
					else
						fieldContent = [
							{ tagName: "label", content: caption }
							{ tagName: "c-toggle", bind: @_bind + "." + field.property }
						]
				else if field.type is "date" or propertyType instanceof cola.DateDataType
					fieldContent = [
						{ tagName: "label", content: caption }
						{ tagName: "c-datepicker", bind: @_bind + "." + field.property }
					]
				else if field.type is "textarea"
					fieldContent = [
						{ tagName: "label", content: caption }
						{ tagName: "c-textarea", bind: @_bind  + "." + field.property, height: field.height or "4em" }
					]
				else
					fieldContent = [
						{ tagName: "label", content: caption }
						{ tagName: "c-input", bind: @_bind + "." + field.property }
					]

				usedCols += field.cols or defaultFieldCols
				fieldsDom.content.push(
					tagName: "field"
					class: "cols-" + (field.cols or defaultFieldCols)
					property: field.property
					content: fieldContent
				)

			childDoms.push(
				tagName: "field"
				content:
					tagName: "messages"
			)

			childDoms = $.xCreate(childDoms)
			for childDom in childDoms
				$(dom).append(childDom)
				cola.xRender(childDom)
		return

	setMessages: (messages) ->
		if (messages)
			@_messages = []

			if not (messages instanceof Array)
				messages = [messages]

			for message in messages
				if typeof message is "string"
					@_messages.push(
						type: "error"
						text: message
					)
				else
					@_messages.push(message)
		else
			delete @_messages

		@refreshMessages()
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

		if @_messages?.length
			for message in @_messages
				messageHolder.add("$", message)

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

	_refreshBindingValue: cola._EMPTY_FUNC

cola.Element.mixin(cola.Form, cola.DataWidgetMixin)
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

		if bind and dom.childElementCount is 0
			dom.appendChild($.xCreate(tagName: "label"))
			dom.appendChild($.xCreate(
				tagName: "c-input"
				bind: bind
			))

		@_labelDom = dom.querySelector("label")
		@_messageDom = dom.querySelector("message")

		bind = bind or @_bind
		if bind
			@_bind = null
			@_bindSetter(bind)
			propertyDef = @getBindingProperty()
			if propertyDef
				$label = $fly(@_labelDom)
				$label.text(propertyDef._caption or propertyDef._name)
				if propertyDef._validators
					for validator in propertyDef._validators
						if validator instanceof cola.RequiredValidator
							$label.addClass("required")
							break
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
					@setMessage(keyMessage)
		return

	setMessage: (message) ->
		if typeof message is "string"
			message =
				type: "error"
				text: message

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