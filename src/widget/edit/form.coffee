oldErrorTemplate = $.fn.form.settings.templates.error
$.fn.form.settings.templates.error = (errors) ->
	if errors.length is 1 and errors[0]?.form instanceof cola.Form
		errors = errors[0].form._errors
	return oldErrorTemplate.call(@, errors)

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
				if @_dom
					STATES = @constructor.STATES
					classPool = new cola.ClassNamePool(@_dom.className)
					for p, cls of STATES
						classPool.remove(cls)
					if state then classPool.add(STATES[state])
					@_dom.className = classPool.join()
				return

	@STATES:
		"error": "error"
		"warning": "warning"
		"info": "success"

	constructor: (config) ->
		@_messageHolder = new cola.Entity.MessageHolder()
		@_errors = []
		super(config)

	_initDom: (dom) ->
		$dom = $(dom)
		$dom.addClass(@_state) if @_state

		@_inline = $dom.find(".ui.message").length is 0
		cola.ready () =>
			$dom.xAppend(
				tagName: "input"
				type: "hidden"
				"data-validate": "__mockField"
			).form(
				on: "_disabled"
				revalidate: false
				inline: @_inline
				fields:
					__mockField:
						identifier: "__mockField"
						rules: [
							{
								type: "empty"
								prompt:
									form: @
									search: () -> -1
									replace: () -> @
							}
						]
			)
			return
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
		state = null
		keyMessage = @_messageHolder.getKeyMessage()
		type = keyMessage?.type
		if type is "error" and !@_inline
			errors = @_errors
			errors.length = 0

			messages = @_messageHolder.findMessages(null, type)
			if messages
				for m in messages
					if m.text
						errors.push(m.text)

			if errors.length > 0
				@_$dom.form("add errors", errors)
				state = type
			else
				@_$dom.find(".error.message").empty()

		@_$dom.form("set value", "__mockField", if type is "error" then "" else "mockValue")
		@set("state", state)
		return

	_resetEntityMessages: () ->
		messageHolder = @_messageHolder
		messageHolder.clear("fields")
		entity = @_getEntity()
		if entity
			messages = entity.findMessages()
			if messages
				for message in messages
					messageHolder.add("fields", message)
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
		if @_inline
			editorDom = editor._$dom.find("input, textarea, select")[0]
			if editorDom
				editorDom.id or= cola.uniqueId()
				if message?.type is "error" and message.text
					@_$dom.form("add prompt", editorDom.id, message.text)
				else
					@_$dom.form("remove prompt", editorDom.id)
		else
			@_resetEntityMessages()
			@_refreshState()
		return

cola.Element.mixin(cola.Form, cola.DataWidgetMixin)

cola.registerWidget(cola.Form)