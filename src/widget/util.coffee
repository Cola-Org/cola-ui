do()->
	escape = (text)->
		return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
	isStyleFuncSupported = !!CSSStyleDeclaration.prototype.getPropertyValue
	unless isStyleFuncSupported
		CSSStyleDeclaration::getPropertyValue = (a)->return this.getAttribute(a)
		CSSStyleDeclaration::setProperty = (styleName, value, priority)->
			this.setAttribute(styleName, value)
			priority = if typeof priority != 'undefined' then priority else ''
			if priority != ''
				rule = new RegExp(escape(styleName) + '\\s*:\\s*' + escape(value) +'(\\s*;)?', 'gmi')
				this.cssText =
					this.cssText.replace(rule, styleName + ': ' + value + ' !' + priority + ';')
		CSSStyleDeclaration::removeProperty = (a)-> this.removeAttribute(a)
		CSSStyleDeclaration::getPropertyPriority = (styleName)->
			rule = new RegExp(escape(styleName) + '\\s*:\\s*[^\\s]*\\s*!important(\\s*;)?', 'gmi')
			return if rule.test(this.cssText) then 'important' else ''
cola.util.addClass = (dom, value, continuous)->
	unless !!continuous
		$(dom).addClass(value)
		return cola.util

	if dom.nodeType is 1
		className = if dom.className then (" #{dom.className} ").replace(cola.constants.CLASS_REG, " ") else " "
		if className.indexOf(" #{value} ") < 0
			className += "#{value} "
			dom.className = $.trim(className)

	return cola.util

cola.util.removeClass = (dom, value, continuous)->
	unless !!continuous
		$(dom).removeClass(value)
		return cola.util

	if dom.nodeType is 1
		className = if dom.className then (" #{dom.className} ").replace(cola.constants.CLASS_REG, " ") else " "
		if className.indexOf(" #{value} ") >= 0
			className = className.replace(" #{value} ", " ")
			dom.className = $.trim(className)

	return cola.util

cola.util.toggleClass = (dom, value, stateVal, continuous)->
	unless !!continuous
		$(dom).toggleClass(value, !!stateVal)
		return

	if dom.nodeType is 1
		if !!stateVal then @_addClass(dom, value, true) else @_removeClass(dom, value, true)

	return cola.util

cola.util.hasClass = (dom, className)->
	names = className.split(/\s+/g)
	domClassName = if dom.className then (" #{dom.className} ").replace(cola.constants.CLASS_REG, " ") else " "
	for name in names
		return false if domClassName.indexOf(" #{name} ") < 0
	return true
cola.util.style = (dom, styleName, value, priority)->
	style = dom.style
	if typeof styleName != 'undefined'
		if typeof  value != 'undefined'
			priority = if typeof priority != 'undefined' then priority else ''
			style.setProperty(styleName, value, priority)
		else
			style.getPropertyValue(styleName)
	else
		return style
cola.util.getTextChildData = (dom)->
	child = dom.firstChild
	while child
		return child.textContent if child.nodeType == 3
		child = child.nextSibling

	return null

cola.util.eachNodeChild = (node, fn)->
	return cola.util if !node or !fn

	child = node.firstChild
	while child
		break if fn(child) == false
		child = child.nextSibling

	return cola.util
cola.util.hasContent = (dom)->
	child = dom.firstChild
	while child
		if child.nodeType == 3 or child.nodeType == 1
			return true
		child = child.nextSibling
	return false


cola.util.getScrollerRender = (element)->
	helperElem = document.createElement("div")
	perspectiveProperty = cola.Fx.perspectiveProperty
	transformProperty = cola.Fx.transformProperty
	if helperElem.style[perspectiveProperty] != undefined
		return (left, top, zoom)->
			element.style[transformProperty] = 'translate3d(' + (-left) + 'px,' + (-top) + 'px,0) scale(' + zoom + ')'
			return

	else if helperElem.style[transformProperty] != undefined
		return  (left, top, zoom)->
			element.style[transformProperty] = 'translate(' + (-left) + 'px,' + (-top) + 'px) scale(' + zoom + ')'
			return
	else
		return (left, top, zoom)->
			element.style.marginLeft = if left then  (-left / zoom) + 'px' else ''
			element.style.marginTop = if  top then  (-top / zoom) + 'px' else ''
			element.style.zoom = zoom || ''
			return

cola.util.getType = do ->
	classToType = {}
	for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
		classToType["[object " + name + "]"] = name.toLowerCase()

	(obj) ->
		strType = Object::toString.call(obj)
		classToType[strType] or "object"

cola.util.typeOf = (obj, type)->
	return cola.util.getType(obj) is type

cola.util.getDomRect = (dom)->
	rect = dom.getBoundingClientRect()
	if isNaN(rect.height) then rect.height = rect.bottom - rect.top
	if isNaN(rect.width) then rect.width = rect.right - rect.left
	return rect