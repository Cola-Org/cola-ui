class cola.Select extends cola.AbstractInput
	@CLASS_NAME: "input"
	@ATTRIBUTES:
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
			if !skipSetIcon
				@set("icon", "dropdown")
		return

	_initDom: (dom) ->
		@_refreshSelectOptions(@_doms.input) if @_options
		return

	_refreshSelectOptions: (select) ->
		options = select.options
		if @_options instanceof cola.EntityList
			options.length = @_options.entityCount
		else
			options.length = @_options.length

		cola.each @_options, (optionValue, i) ->
			option = options[i]
			if cola.util.isSimpleValue(optionValue)
				$fly(option).removeAttr("value").text(optionValue)
			else if optionValue instanceof cola.Entity
				$fly(option).attr("value", optionValue.get("value") or optionValue.get("key")).text(optionValue.get("text") or optionValue.get("name"))
			else
				$fly(option).attr("value", optionValue.value or optionValue.key).text(optionValue.text or optionValue.name)
			return
		return