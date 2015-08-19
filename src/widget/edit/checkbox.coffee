class cola.AbstractCheckbox extends cola.AbstractEditor
	@CLASS_NAME: "checkbox"
	@INPUT_TYPE: "checkbox"

	@ATTRIBUTES:
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
			getter: ()-> return @_value == @_onValue
			setter: (state)->
				checked = !!state
				value = if checked then @get("onValue") else @get("offValue")
				@_setValue(value)
				return @

		value:
			defaultValue: false
			refreshDom: true
			setter: (value)-> @_setValue(value)

	@_modelValue: false
	_parseDom: (dom)->
		@_doms ?= {}
		@_$dom ?= $(dom)

		child = dom.firstChild
		while child
			if child.nodeType == 1
				if child.nodeName is "LABEL"
					@_doms.label = child
					@_label ?= cola.util.getTextChildData(child)
				else if child.nodeName is "INPUT"
					nameAttr = child.getAttribute("name")
					@_name ?= nameAttr if nameAttr
					@_doms.input = child
			child = child.nextSibling

		if !@_doms.label and !@_doms.input
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

	_bindToSemantic: ()->
		@get$Dom().checkbox({
			onChange: ()=> @_setValue(@_getValue())
		})

	_setDom: (dom, parseChild)->
		@_dom = dom
		unless parseChild
			@_bindToSemantic()
		super(dom, parseChild)

		return

	_refreshEditorDom: ()->
		@get$Dom().checkbox(if @_value == @_onValue then "check" else "uncheck")

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_doms ?= {}
		label = @get("label") or ""
		$(@_doms.label).text(label)

		readOnly = @get("readOnly")
		@_classNamePool.toggle("read-only", readOnly)

		$dom = @get$Dom()
		$dom.checkbox(if !!@_disabled then "disable" else "enable")

		@_refreshEditorDom()

	_getValue: ()->
		return if @get$Dom().checkbox("is checked") then @get("onValue") else @get("offValue")

	toggle: ()->
		state = !!@get("checked")
		@set("checked", !state)
		return @

class cola.Checkbox extends cola.AbstractCheckbox
	@ATTRIBUTES:
		indeterminateValue: null

		triState:
			type: "boolean"
			defaultValue: false

	_getValue: ()->
		if @_triState and !@get$Dom().checkbox("is determinate")
			return @get("indeterminateValue")
		return super()

	_refreshEditorDom: ()->
		if @_triState and @_value isnt @_onValue and  @_value isnt @_offValue
			@get$Dom().checkbox("indeterminate")
			return
		super()


class cola.Toggle extends cola.AbstractCheckbox
	@CLASS_NAME: "toggle checkbox"

class cola.Slider extends cola.AbstractCheckbox
	@CLASS_NAME: "slider checkbox"


