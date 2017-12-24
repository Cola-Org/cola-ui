class cola.AbstractCheckbox extends cola.AbstractEditor
	@tagName: "c-checkbox"
	@CLASS_NAME: "checkbox"
	@INPUT_TYPE: "checkbox"

	@attributes:
		label:
			refreshDom: true
		name:
			refreshDom: true
		onValue:
			defaultValue: true

		offValue:
			defaultValue: false

		disabled:
			refreshDom: true
			type: "boolean"
			defaultValue: false

		checked:
			refreshDom: true
			type: "boolean"
			defaultValue: false
			getter: ()->
				if @_value is @_onValue
					return true
				else if @_value is @_offValue
					return false
				else
					return undefined
			setter: (state)->
				checked = !!state
				value = if checked then @_onValue else @_offValue
				@_setValue(value)
				return @

		value:
			defaultValue: false
			refreshDom: true
			setter: (value)-> @_setValue(value)

	_modelValue: false

	_parseDom: (dom)->
		@_doms ?= {}
		@_$dom ?= $(dom)

		child = dom.firstElementChild
		while child
			if child.nodeType is 1
				if child.nodeName is "LABEL"
					@_doms.label = child
					@_label ?= cola.util.getTextChildData(child)
				else if child.nodeName is "INPUT"
					nameAttr = child.getAttribute("name")
					@_name ?= nameAttr if nameAttr
					@_doms.input = child
			child = child.nextElementSibling

		if not @_doms.label and not @_doms.input
			@_$dom.append($.xCreate([
				{
					tagName: "input"
					type: @constructor.INPUT_TYPE
					contextKey: "input"
					name: @_name or ""
				}
				{
					tagName: "label"
					content: @_label or ""
					contextKey: "label"
				}
			], @_doms))

		unless @_doms.label
			@_doms.label = $.xCreate({
				tagName: "label"
				content: @_label or ""
			})
			@_$dom.append(@_doms.label)

		unless @_doms.input
			@_doms.input = $.xCreate({
				tagName: "input"
				type: @constructor.INPUT_TYPE
				name: @_name or ""
			})
			$(@_doms.label).before(@_doms.input)
		@_bindToSemantic()
		return

	_createDom: ()->
		return $.xCreate({
			tagName: "DIV"
			class: "ui #{@constructor.CLASS_NAME}"
			content: [
				{
					tagName: "input"
					type: @constructor.INPUT_TYPE
					contextKey: "input"
					name: @get("name") or ""
				}
				{
					tagName: "label"
					content: @_label or ""
					contextKey: "label"
				}
			]
		}, @_doms)

	_initDom: (dom)->
		super(dom)
		$(@_doms.input)
			.attr("tabIndex", null)
			.on("focus", (evt)=> @onFocus(evt))
			.on("blur", (evt)=> @onBlur(evt))
		return

	focus: ()->
		@_doms.input?.focus()
		return

	_bindToSemantic: ()->
		@get$Dom().checkbox(
			onChange: ()=> @_setValue(@_getValue())
		)
		return

	_setDom: (dom, parseChild)->
		@_dom = dom
		unless parseChild
			@_bindToSemantic()
		super(dom, parseChild)

		return

	_refreshEditorDom: ()->
		@get$Dom().checkbox(if @_value is @_onValue then "check" else "uncheck")
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_doms ?= {}
		label = @get("label") or ""
		$(@_doms.label).text(label)

		@_classNamePool.toggle("readonly", @_finalReadOnly)
		@_classNamePool.toggle("read-only", @_finalReadOnly)

		$dom = @get$Dom()
		$dom.checkbox(if !!@_disabled then "disable" else "enable")

		@_refreshEditorDom()
		return

	_getValue: ()->
		return if @get$Dom().checkbox("is checked") then @get("onValue") else @get("offValue")

	toggle: ()->
		state = !!@get("checked")
		@set("checked", not state)
		return @

class cola.Checkbox extends cola.AbstractCheckbox
	@attributes:
		indeterminateValue: null

		triState:
			type: "boolean"
			defaultValue: false

	_getValue: ()->
		if @_triState and not @get$Dom().checkbox("is determinate")
			return @get("indeterminateValue")
		return super()

	_refreshEditorDom: ()->
		if @_triState and @_value isnt @_onValue and @_value isnt @_offValue
			@get$Dom().checkbox('set indeterminate')
			return
		return super()

cola.registerWidget(cola.Checkbox)

class cola.Toggle extends cola.AbstractCheckbox
	@tagName: "c-toggle"

	_initDom: (dom)->
		$fly(dom).addClass("no-transmit").on("mousedown", ()=>
			@get$Dom().removeClass("no-transmit")
			cola.util.delay(@, "onColumnChange", 500, ()=>
				if not @_destroyed
					@get$Dom().addClass("no-transmit")
				return
			)
			return
		)
		return super(dom)

	_doRefreshDom: ()->
		return unless @_dom
		super()
		unless @hasClass("slider") then @_classNamePool.add("toggle")

cola.registerWidget(cola.Toggle)


