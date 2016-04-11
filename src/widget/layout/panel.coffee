class cola.Panel extends cola.AbstractContainer
	@CLASS_NAME: "panel"
	@ATTRIBUTES:
		collapsible:
			type: "boolean"
			defaultValue: true
		closable:
			type: "boolean"
			defaultValue: false
		caption:
			refreshDom: true
		icon:
			refreshDom: true
	@TEMPLATES:
		"tools":
			tagName: "div"
	@EVENTS:
		open: null
		collapsedChange: null
		close: null
		beforeOpen: null
		beforeCollapsedChange: null
		beforeClose: null
	collapsedChange: ()->
		$dom = @_$dom
		collapsed = @isCollapsed()
		return @ if @fire("beforeCollapsedChange", @, {}) is false
		$dom.toggleClass("collapsed", !collapsed)
		setTimeout(()=>
			@fire("collapsedChange", @, {})
		, 300);
		return

	isCollapsed: ()->
		return @_$dom?.hasClass("collapsed")

	isClosed: ()->
		return @_$dom?.hasClass("transition hidden")

	open: ()->
		return unless @isClosed()
		@toggle()

	close: ()->
		return if @isClosed()
		@toggle()

	toggle: ()->
		beforeEvt = "beforeOpen"
		onEvt = "open"
		unless @isClosed
			beforeEvt = "beforeClose"
			onEvt = "close"
		if @fire(beforeEvt, @, {}) is false
			return
		@_$dom.transition({animation: 'scale', onComplete: ()=> @fire(onEvt, @, {})})

	getContentContainer: ()->
		return null unless @_dom
		unless @_doms.content
			@_makeContentDom("content")

		return @_doms.content

	_initDom: (dom)->
		@_regDefaultTempaltes()
		super(dom)
		headerContent = $.xCreate({
			tagName: "div"
			class: "content"
		})
		@_doms.icon = $.xCreate({
			tagName: "i"
			class: "panel-icon"
		})
		headerContent.appendChild(@_doms.icon)

		@_doms.caption = $.xCreate({
			tagName: "span"
			class: "caption"
		})
		headerContent.appendChild(@_doms.caption)

		template = @_getTemplate("tools")
		cola.xRender(template, @_scope)
		toolsDom = @_doms.tools = $.xCreate({
			class: "tools"
		})
		toolsDom.appendChild(template)

		nodes = $.xCreate([
			{
				tagName: "i"
				click: ()=>
					@collapsedChange()
				class: "icon chevron down collapse-btn"
			}
			{
				tagName: "i"
				click: ()=>
					@toggle()
				class: "icon close close-btn"
			}
		])
		toolsDom.appendChild(node) for node in nodes
		headerContent.appendChild(toolsDom)


		@_render(headerContent, "header")
		@_makeContentDom("content") unless @_doms.content
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$fly(@_doms.caption).text(@_caption || "")
		if @_icon
			$fly(@_doms.icon).show().removeClass(@_doms.icon._icon)
		else
			$fly(@_doms.icon).hide()

		$fly(@_doms.icon).addClass("icon #{@_icon || ""}")
		@_doms.icon._icon = @_icon
		$fly(@_doms.tools).find(".collapse-btn")[if @_collapsible then "show" else "hide"]()
		$fly(@_doms.tools).find(".close-btn")[if @_closable then "show" else "hide"]()

	_makeContentDom: (target)->
		@_doms ?= {}
		dom = document.createElement("div")
		dom.className = target

		if target is "header"
			$(@_dom).prepend(dom)
		else
			@_dom.appendChild(dom)
		@_doms[target] = dom
		return dom

	_parseDom: (dom)->
		@_doms ?= {}

		_parseChild = (node, target)=>
			childNode = node.firstChild
			while childNode
				if childNode.nodeType == 1
					widget = cola.widget(childNode)
					@_addContentElement(widget or childNode, target)
				childNode = childNode.nextSibling
			return

		child = dom.firstChild
		while child
			if child.nodeType == 1
				if child.nodeName == "TEMPLATE"
					@_regTemplate(child)
				else
					$child = $(child)
					unless $child.hasClass("content")
						child = child.nextSibling
						continue
					@_doms["content"] = child
					_parseChild(child, "content")
					break
			child = child.nextSibling
		return
cola.Element.mixin(cola.Panel, cola.TemplateSupport)


class cola.FieldSet extends cola.Panel
	@CLASS_NAME: "panel fieldset"
class cola.GroupBox extends cola.Panel
	@CLASS_NAME: "panel groupbox"