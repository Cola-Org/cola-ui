containerEmptyChildren = []

## 此控件为容器控件超类 Layer、Dialog、Segment等等控件都继承自此类
class cola.AbstractContainer extends cola.Widget
	@ATTRIBUTES:
		content:
			setter: (value)->
				@_setInternal(value, "content")
				return @
	_initDom:(dom)->
		@_doms?={}
		if @_content
			@_makeInternalDom("content") unless @_doms?.content
			@_render(el, "content") for el in @_content
		return

	_parseDom: (dom)->
		@_content ?= []

		child = dom.firstChild
		while child
			if child.nodeType == 1
				widget = cola.widget(child)
				@_content.push(widget) if widget
			child = child.nextSibling

		return

	getContentContainer: ()->
		return @getDom()

	_parseContentElement: (element)->
		result = null
		if typeof element == "string"
			result = $.xCreate({
				tagName: "SPAN"
				content: element
			})
		else if element.constructor == Object.prototype.constructor and element.$type
			widget = cola.widget(element)
			result = widget
		else if element instanceof cola.Widget
			result = element
		else if element.nodeType == 1
			result = element
		else
			result = $.xCreate(element)

		return result

	_clearInternal: (target)->
		old = @["_#{target}"]
		if old
			for el in old
				el.destroy() if el instanceof cola.widget
			@["_#{target}"] = []

		@_doms ?= {}
		$(@_doms[target]).empty()if @_doms[target]
		return

	_setInternal: (value, target)->
		@_clearInternal(target)

		if value instanceof Array
			for el in value
				result = @_parseContentElement(el)
				@_addInternalElement(result, target) if result
		else
			result = @_parseContentElement(value)
			@_addInternalElement(result, target)  if result

		return

	_makeInternalDom: (target)->
		@_doms ?= {}
		@_doms[target] = @_dom

		return @_dom

	_addInternalElement: (element, target)->
		name = "_#{target}"
		@[name] ?= []
		targetList = @[name]

		dom = null
		if element instanceof cola.Widget
			targetList.push(element)
			dom = element.getDom() if @_dom
		else if element.nodeType == 1
			targetList.push(element)
			dom = element

		@_render(dom, target) if dom and @_dom
		return

	_render: (node, target)->
		@_doms ?= {}

		@_makeInternalDom(target) unless @_doms[target]
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

