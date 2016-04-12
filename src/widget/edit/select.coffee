class cola.Select extends cola.AbstractInput
	@tagName: "c-select"
	@CLASS_NAME: "input select"

	@attributes:
		options:
			setter: (options) ->
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
				value =  optionValue.get("value") or optionValue.get("key") or ""
				text = optionValue.get("text") or optionValue.get("name")
			else
				value =  optionValue.value or optionValue.key or ""
				text = optionValue.text or optionValue.name

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

cola.registerWidget(cola.Select)