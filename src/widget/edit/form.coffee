class cola.Form extends cola.Widget
	@tagName: "c-form"
	@CLASS_NAME: "form"

	@attributes:
		bind:
			setter: (bindStr)-> @_bindSetter(bindStr)
		dataType:
			setter: cola.DataType.dataTypeSetter

		readOnly:
			setter: (readOnly)->
				@_readOnly = readOnly
				if @_rendered
					@get$Dom().find("field, fields >field").each((i, fieldDom)->
						field = cola.widget(fieldDom)
						field?.refreshReadOnly()
						return
					)
				return
		defaultCols:
			defaultValue: 3
		fields:
			setter: (fields)->
				@_fields = fields

				return unless @_dom
				@_$dom.empty()

				if fields
					dataType = @_getDataType()
					childDoms = []
					maxCols = @_defaultCols
					defaultFieldCols = 1
					usedCols = maxCols

					for field in fields
						if dataType
							propertyDef = dataType.getProperty(field.property)
						if propertyDef
							caption = field.caption or propertyDef.get("caption") or field.property
							propertyType = propertyDef.get("dataType")
							labelUserData = { captionSetted: true }
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
								{ tagName: "label", content: caption, data: labelUserData }
								field.editContent
							]
						else if propertyType instanceof cola.BooleanDataType
							if field.type is "checkbox"
								fieldContent = [
									{ tagName: "label", content: caption, data: labelUserData }
									{ tagName: "c-checkbox", bind: @_bind + "." + field.property }
								]
							else
								fieldContent = [
									{ tagName: "label", content: caption, data: labelUserData }
									{ tagName: "c-toggle", bind: @_bind + "." + field.property }
								]
						else if field.type is "date" or propertyType instanceof cola.DateDataType
							fieldContent = [
								{ tagName: "label", content: caption, data: labelUserData }
								{ tagName: "c-datepicker", bind: @_bind + "." + field.property }
							]
						else if field.type is "textarea"
							fieldContent = [
								{ tagName: "label", content: caption, data: labelUserData }
								{ tagName: "c-textarea", bind: @_bind  + "." + field.property, height: field.height or "4em" }
							]
						else
							fieldContent = [
								{ tagName: "label", content: caption, data: labelUserData }
								{ tagName: "c-input", bind: @_bind + "." + field.property }
							]

						usedCols += field.cols or defaultFieldCols
						fieldsDom.content.push(
							tagName: "field"
							class: "cols-" + (field.cols or defaultFieldCols)
							property: field.property
							content: fieldContent
						)

					childDoms = cola.xCreate(childDoms)
					for childDom in childDoms
						@_$dom.append(childDom)
						cola.xRender(childDom, @_scope)
						childDom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
				return

	constructor: (config)->
		@_messageHolder = new cola.Entity.MessageHolder()
		super(config)

	_getDataType: ()->
		return @_dataType or @getBindingDataType()

	_initDom: (dom)->
		super(dom)
		@_$messages = @get$Dom().find("messages, .ui.message").addClass("messages")
		if @_fields then @set("fields", @_fields)
		return

	setMessages: (messages)->
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

	refreshMessages: ()->
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
			setter: (bindStr)->
				if @_domParsed
					@_bindSetter(bindStr)
				else
					@_bindStr = bindStr
				return

		caption: null
		property: null
		readOnly:
			setter: (readOnly)->
				@_readOnly = readOnly
				@refreshReadOnly()
				return
		type: null
		cols: null

		message:
			readOnly: true
			getter: ()->
				if @_messageDom
					return @_message
				else
					return null

	_getPropertyDef: ()->
		return @_propertyDef if @_propertyDef isnt undefined

		if @_form
			dataType = @_form._getDataType()
			if dataType and @_property
				propertyDef = dataType.getProperty(@_property)
		if not propertyDef and @_bind
			propertyDef = @getBindingProperty()
		return @_propertyDef = propertyDef or null

	_parseDom: (dom)->
		@_domParsed = true

		bind = @_bindStr
		if dom.parentNode
			form = cola.widget(dom.parentNode)
			if not (form instanceof cola.Form)
				form = cola.widget(dom.parentNode.parentNode)

		if form
			@_form = form
			if not bind and @_property
				formBind = form?._bind
				if formBind
					bind = formBind + "." + @_property
				else
					bind = @_property

		if bind then @_bindSetter(bind)

		propertyDef = @_getPropertyDef()
		if propertyDef
			@_applyPropertyDefProperties?(propertyDef)

		if bind and dom.childElementCount is 0
			dom.appendChild($.xCreate(
			  tagName: "label"
			  content: @_caption or ""
			))

			if propertyDef
				propertyType = propertyDef.get("dataType")
				if propertyType instanceof cola.BooleanDataType
					if @_type is "checkbox"
						editContent = { tagName: "c-checkbox", bind: bind }
					else
						editContent = { tagName: "c-toggle", bind: bind }
				else if @_type is "date" or propertyType instanceof cola.DateDataType
					editContent = { tagName: "c-datepicker", bind: bind }
				else if @_type is "textarea"
					editContent = { tagName: "c-textarea", bind: bind }

			editContent ?= { tagName: "c-input", bind: bind }

			editDom = cola.xCreate(editContent)
			dom.appendChild(editDom)
			cola.xRender(editDom, @_scope)

			editDom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")

		@_labelDom = dom.querySelector("label")
		@_messageDom = dom.querySelector("message")
		if @_messageDom
			$fly(@_messageDom).popup({
				position: "bottom center"
			})

		if @_labelDom
			$label = $fly(@_labelDom)
			if not $label.data("labelUserData")
				propertyDef = @_getPropertyDef()
				if propertyDef
					caption = propertyDef.get("caption") or @_property
					if propertyDef._validators
						for validator in propertyDef._validators
							if validator instanceof cola.RequiredValidator
								$(dom).addClass("required")
								break

			if (caption or @_caption) and @_labelDom.innerHTML is ""
				$label.text(caption or @_caption)
		return

	_filterDataMessage: (path, type, arg)->
		return cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or
		  type is cola.constants.MESSAGE_VALIDATION_STATE_CHANGE or @_watchingMoreMessage

	_processDataMessage: (path, type, arg)->
		if @_bindInfo?.writeable
			entity = @_scope.get(@_bindInfo.entityPath)
			if entity instanceof cola.EntityList
				entity = entity.current
			if entity
				keyMessage = entity.getKeyMessage(@_bindInfo.property)
				@setMessage(keyMessage)
		return

	_doRefreshDom: ()->
		@refreshReadOnly()
		@_classNamePool.toggle("readonly", @_finalReadOnly)
		return super()

	refreshReadOnly: ()->
		finalReadOnly = @_readOnly or @_form?._readOnly
		if finalReadOnly != @_finalReadOnly
			@_finalReadOnly = finalReadOnly
			if @_rendered
				@get$Dom().find("input, textarea").each((i, input)=>
					editor = cola.widget(input.parentNode)
					if editor and editor._readOnlyFactor != @_finalReadOnly
						editor._readOnlyFactor.field = @_finalReadOnly
						editor._refreshDom()
					return
				)
		return

	setMessage: (message)->
		if typeof message is "string"
			message =
				type: "error"
				text: message

		@_message = message

		if message
			@get$Dom().addClass(message.type)
			if not @_messageDom
				@_messageDom = document.createElement("message")
				@getDom().appendChild(@_messageDom)
				$fly(@_messageDom).popup({
					position: "bottom center"
				})

		else if @_state
			@get$Dom().removeClass(@_state)

		if @_messageDom
			$message = $fly(@_messageDom)
			if message
				$message.addClass(message.type)
				if $message.hasClass("text")
					$message.text(message.text)
				else
					$message.attr("data-content", message.text)
			else
				$message.removeClass(@_state).empty().attr("data-content", null)

		@_state = message?.type

		@_form?.refreshMessages()
		return

cola.Element.mixin(cola.Field, cola.DataWidgetMixin)
cola.registerWidget(cola.Field)