containerEmptyChildren = []

## 此控件为容器控件超类 Layer、Dialog、Segment等等控件都继承自此类
class cola.AbstractContainer extends cola.Widget
	@attributes:
		content:
			setter: (value)->
				@_setContent(value, "content")
				return @
	_initDom:(dom)->
		super(dom)
		if @_content
			@_render(el, "content") for el in @_content
		return

	_parseDom: (dom)->
		@_content ?= []

		child = dom.firstElementChild
		while child
			if child.nodeType is 1
				widget = cola.widget(child)
				@_content.push(widget) if widget
			child = child.nextElementSibling
		return

	getContentContainer: ()->
		return @getDom()
		
	_clearContent: (target)->
		old = @["_#{target}"]
		if old
			for el in old
				el.destroy() if el instanceof cola.widget
			@["_#{target}"] = []

		@_doms ?= {}
		$(@_doms[target]).empty()if @_doms[target]
		return

	_setContent: (value, target)->
		@_clearContent(target)

		if value instanceof Array
			for el in value
				if typeof el is "string"
					el= {content:el}
				result = cola.xRender(el,@_scope)
				@_addContentElement(result, target) if result
		else
			if typeof el is "string"
				el= {content:el}
			result =cola.xRender(value,@_scope)
			@_addContentElement(result, target)  if result

		return

	_makeContentDom: (target)->
		@_doms ?= {}
		@_doms[target] = @_dom

		return @_dom

	_addContentElement: (element, target)->
		name = "_#{target}"
		@[name] ?= []
		targetList = @[name]

		dom = null
		if element instanceof cola.Widget
			targetList.push(element)
			dom = element.getDom() if @_dom
		else if element.nodeType
			targetList.push(element)
			dom = element

		@_render(dom, target) if dom and @_dom
		return

	_render: (node, target)->
		@_doms ?= {}

		@_makeContentDom(target) unless @_doms[target]
		dom = node

		if node instanceof cola.Widget
			dom = node.getDom()

		@_doms[target].appendChild(dom) if dom.parentNode isnt @_doms[target]
		return

	destroy: ()->
		return if @_destroyed
		if @_content
			for child in @_content
				child.destroy?()
			delete @_content
		super()

		return @

