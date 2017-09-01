class cola.Select extends cola.AbstractInput
	@tagName: "c-select"
	@CLASS_NAME: "input select"

	@attributes:
		options:
			setter: (options) ->
				if typeof options is "string"
					options = options.split(/[,;]/)
					for item, i in options
						index = item.indexOf("=")
						if index >= 0
							options[i] =
								value: item.substring(0, index)
								text: item.substring(index + 1)
						else
							options[i] =
								value: null
								text: item

				return unless options instanceof Array or options instanceof cola.EntityList
				@_options = options
				select = @_doms?.input
				@_refreshSelectOptions(select) if select
				return

	_createEditorDom: ()->
		return $.xCreate({
			tagName: "select"
			class: "editor"
		})

	_isEditorDom: (node)->
		return node.nodeName is "SELECT"

	_parseDom: (dom) ->
		super(dom)
		if !@_icon
			child = @_doms.input.nextSibling
			while child
				if child.nodeType == 1 and child.nodeName != "TEMPLATE"
					skipSetIcon = true
					break
				child = child.nextSibling
			if not skipSetIcon
				@set("icon", "dropdown")
		return

	_initDom: (dom) ->
		@_refreshSelectOptions(@_doms.input) if @_options

		$(@_doms.input).on("change", ()=>
			readOnly = @_readOnly
			if !readOnly
				value = $(@_doms.input).val()
				@set("value", value)
			return
		)
		return

	_refreshSelectOptions: (select) ->
		options = select.options
		if @_options instanceof cola.EntityList
			options.length = @_options.entityCount
		else
			options.length = @_options.length

		cola.each @_options, (optionValue, i) =>
			option = options[i]
			if cola.util.isSimpleValue(optionValue)
				value = null
				text = optionValue
			else if optionValue instanceof cola.Entity
				if optionValue.hasValue("key")
					value = optionValue.get("key") or ""
					text = optionValue.get("value")
				else
					value =  optionValue.get("value") or ""
					text = optionValue.get("text")
			else
				if optionValue.hasOwnProperty("key")
					value = optionValue.key or ""
					text = optionValue.value
				else
					value =  optionValue.value or ""
					text = optionValue.text

			$option = $fly(option)
			if !value?
				$option.removeAttr("value")
			else
				$option.attr("value", value)
				if value is "" and not text
					text = @_placeholder
			$option.text(text or "")
			return
		return

	_refreshInputValue: (value) ->
		super(value)
		cola.util.toggleClass(@_doms.input, "placeholder", !value? or value is "")
		return
	_doRefreshDom: ()->
		return unless @_dom
		super()
		$(@_doms.input).prop("disabled", @_readOnly)

cola.registerWidget(cola.Select)