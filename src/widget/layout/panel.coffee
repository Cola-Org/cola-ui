class cola.Panel extends cola.AbstractContainer
	@className: "panel"
	@tagName: "c-panel"
	@attributes:
		collapsible:
			type: "boolean"
			defaultValue: true
		caption:
			refreshDom: true
		icon:
			refreshDom: true
	@templates:
		"tools":
			tagName: "div"
	@events:
		collapsedChange: null
		beforeCollapsedChange: null

	collapsedChange: (fn)->
		$dom = @_$dom
		collapsed = @isCollapsed()
		return @ if @fire("beforeCollapsedChange", @, {}) is false
		initialHeight = @get("height")
		unless initialHeight
			currentHeight = $dom.outerHeight()
			$dom.css("height", "initial")
			height = $dom.outerHeight()
			$dom.css("height", currentHeight)

		$dom.toggleClass("collapsed", !collapsed)
		headerHeight = $(@_doms.header).outerHeight()

		dfd = $.Deferred()
		$dom.transit({
			duration: 300,
			height: if collapsed then height or @get("height") else headerHeight
			complete: ()=>
				if collapsed and not initialHeight then $dom.css("height", "initial")
				fn?()
				@fire("collapsedChange", @, {})
				dfd.resolve()
		})
		return dfd

	isCollapsed: ()->
		return @_$dom?.hasClass("collapsed")

	collapse: (fn)->
		if @isCollapsed()
			fn?()
			return $.Deferred().resolve()
		return @collapsedChange(fn)

	expand: (fn)->
		if not @isCollapsed()
			fn?()
			return $.Deferred().resolve()
		return @collapsedChange(fn)

	toggle: (fn)-> @collapsedChange(fn)

	getContentContainer: ()->
		return null unless @_dom
		unless @_doms.content
			@_makeContentDom("content")

		return @_doms.content

	_initDom: (dom)->
		@_regDefaultTemplates()
		super(dom)

		if not @_doms.header
			@_doms.header = $.xCreate({
				tagName: "div"
				class: "header"
			})
			if @_dom.firstElementChild
				@_dom.insertBefore(@_doms.header, @_dom.firstElementChild)
			else
				@_doms.appendChild(@_doms.header)

		headerContent = @_doms.headerContent
		if not headerContent
			@_doms.headerContent = headerContent = $.xCreate({
				tagName: "div"
				class: "content"
			})
			@_doms.header.appendChild(headerContent)

		if not @_doms.icon
			@_doms.icon = $.xCreate({
				tagName: "i"
				class: "panel-icon"
			})
		headerContent.appendChild(@_doms.icon) if @_doms.icon.parentNode isnt headerContent

		if not @_doms.caption
			@_doms.caption = $.xCreate({
				tagName: "span"
				class: "caption"
			})
		headerContent.appendChild(@_doms.caption) if @_doms.caption.parentNode isnt headerContent

		template = @getTemplate("tools")
		cola.xRender(template, @_scope)
		toolsDom = @_doms.tools = $.xCreate({
			class: "tools"
		})
		toolsDom.appendChild(template)

		nodes = $.xCreate([
			{
				tagName: "i"
				click: ()=> @collapsedChange()
				class: "icon chevron down collapse-btn"
			}
		])
		toolsDom.appendChild(node) for node in nodes
		headerContent.appendChild(toolsDom)

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
		return

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
			childNode = node.firstElementChild
			while childNode
				if childNode.nodeType is 1
					widget = cola.widget(childNode)
					@_addContentElement(widget or childNode, target)
				childNode = childNode.nextElementSibling
			return

		child = dom.firstElementChild
		while child
			if child.nodeName is "TEMPLATE"
				@regTemplate(child)
			else
				$child = $(child)
				if $child.hasClass("header")
					@_doms["header"] = child
					@_doms["headerContent"] = $child.find(">.content")[0]
					@_doms["icon"] = $child.find(".icon")[0]
					@_doms["caption"] = $child.find(".caption")[0]
				else if $child.hasClass("content")
					@_doms["content"] = child
					_parseChild(child, "content")
			child = child.nextElementSibling
		return

cola.Element.mixin(cola.Panel, cola.TemplateSupport)

class cola.FieldSet extends cola.Panel
	@className: "panel fieldset"
	@tagName: "c-fieldset"

class cola.GroupBox extends cola.Panel
	@className: "panel groupbox"
	@tagName: "c-groupbox"

cola.registerWidget(cola.Panel)
cola.registerWidget(cola.FieldSet)
cola.registerWidget(cola.GroupBox)
