IGNORE_NODES = ["SCRIPT", "STYLE", "META", "TEMPLATE"]
ALIAS_REGEXP = new RegExp("\\$default", "g")

cola._mainInitFuncs = []

cola._rootFunc = () ->
	fn = null
	targetDom = null
	modelName = null
	for arg in arguments
		if typeof arg == "function"
			fn = arg
		else if typeof arg == "string"
			modelName = arg
		else if arg?.nodeType or typeof arg == "object" and arg.length > 0
			targetDom = arg

	init = (dom, model, param) ->
		oldScope = cola.currentScope
		cola.currentScope = model
		try
			fn?(model, param)

			if !dom
				viewDoms = document.getElementsByClassName(cola.constants.VIEW_CLASS)
				if viewDoms?.length then dom = viewDoms
			dom ?= document.body

			if dom.length
				doms = dom
				for dom in doms
					cola._renderDomTemplate(dom, model)
			else
				cola._renderDomTemplate(dom, model)
		finally
			cola.currentScope = oldScope
		return

	if cola._suspendedInitFuncs
		cola._suspendedInitFuncs.push(init)
	else
		modelName ?= cola.constants.DEFAULT_PATH
		model = cola.model(modelName)
		model ?= new cola.Model(modelName)

		if cola._mainInitFuncs
			cola._mainInitFuncs.push(
				targetDom: targetDom
				model: model
				init: init
			)
		else
			init(targetDom, model)
	return cola

$ () ->
	initFuncs = cola._mainInitFuncs
	delete cola._mainInitFuncs
	for initFunc in initFuncs
		initFunc.init(initFunc.targetDom, initFunc.model)

	if cola.getListeners("ready")
		cola.fire("ready", cola)
		cola.off("ready")
	return

cola._userDomCompiler =
	$: []

$.xCreate.templateProcessors.push (template) ->
	if template instanceof cola.Widget
		dom = template.getDom()
		dom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
		return dom
	return

$.xCreate.attributeProcessor["c-widget"] = ($dom, attrName, attrValue, context) ->
	return unless attrValue
	if typeof attrValue == "string"
		$dom.attr(attrName, attrValue)
	else if context
		configKey = cola.uniqueId()
		$dom.attr("widget-config", configKey)
		widgetConfigs = context.widgetConfigs
		if !widgetConfigs
			context.widgetConfigs = widgetConfigs = {}
		widgetConfigs[configKey] = attrValue
	return

cola.xRender = (template, model, context) ->
	return unless template

	if template.nodeType
		dom = template
	else if typeof template == "string"
		documentFragment = document.createDocumentFragment()
		div = document.createElement("div")
		div.innerHTML = template
		child = div.firstChild
		while child
			next = child.nextSibling
			documentFragment.appendChild(child)
			child = next
	else
		oldScope = cola.currentScope
		cola.currentScope = model
		try
			context ?= {}
			if template instanceof Array
				documentFragment = document.createDocumentFragment()
				for node in template
					widget = null
					if node instanceof cola.Widget
						widget = node
					else if node.$type
						widget = cola.widget(node, context.namespace)
					if widget
						child = widget.getDom()
						child.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
					else
						child = $.xCreate(node, context)
					documentFragment.appendChild(child)
			else
				if template instanceof cola.Widget
					widget = template
				else if template.$type
					widget = cola.widget(template, context.namespace)
				if widget
					dom = widget.getDom()
					dom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
				else
					dom = $.xCreate(template, context)
		finally
			cola.currentScope = oldScope

	if dom
		cola._renderDomTemplate(dom, model, context)
	else if documentFragment
		cola._renderDomTemplate(documentFragment, model, context)

		if documentFragment.firstChild == documentFragment.lastChild
			dom = documentFragment.firstChild
		else
			dom = documentFragment
	return dom

cola._renderDomTemplate = (dom, scope, context = {}) ->
	_doRrenderDomTemplate(dom, scope, context)
	return

_doRrenderDomTemplate = (dom, scope, context) ->
	return dom if dom.nodeType == 8
	return dom if dom.nodeType == 1 and dom.hasAttribute(cola.constants.IGNORE_DIRECTIVE)
	return dom if IGNORE_NODES.indexOf(dom.nodeName) > -1

	if dom.nodeType == 3 # #text
		bindingExpr = dom.nodeValue
		parts = cola._compileText(bindingExpr)
		buildContent(parts, dom, scope) if parts?.length
		return dom
	else if dom.nodeType == 11 # #documentFragment
		child = dom.firstChild
		while child
			child = _doRrenderDomTemplate(child, scope, context)
			child = child.nextSibling
		return dom

	initializers = null
	features = null
	removeAttrs = null

	bindingExpr = dom.getAttribute("c-repeat")
	if bindingExpr
		bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
		dom.removeAttribute("c-repeat")
		expression = cola._compileExpression(bindingExpr, "repeat")
		if expression
			bindingType = "repeat"
			feature = buildRepeatFeature(expression)
			features ?= []
			features.push(feature)
	else
		bindingExpr = dom.getAttribute("c-alias")
		if bindingExpr
			bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
			dom.removeAttribute("c-alias")
			bindingType = "alias"
			expression = cola._compileExpression(bindingExpr, "alias")
			if expression
				feature = buildAliasFeature(expression)
				features ?= []
				features.push(feature)

	bindingExpr = dom.getAttribute("c-bind")
	if bindingExpr
		bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
		dom.removeAttribute("c-bind")
		expression = cola._compileExpression(bindingExpr)
		if expression
			feature = buildBindFeature(expression, dom)
			features ?= []
			features.push(feature)

	for attr in dom.attributes
		attrName = attr.name
		if attrName.substring(0, 2) == "c-"
			removeAttrs ?= []
			removeAttrs.push(attrName)

			attrValue = attr.value
			if attrValue and context.defaultPath
				attrValue = attrValue.replace(ALIAS_REGEXP, context.defaultPath)

			attrName = attrName.substring(2)
			if attrName == "style"
				newFeatures = buildStyleFeature(attrValue)
				features = if features then features.concat(newFeatures) else newFeatures
			else if attrName == "class"
				newFeatures = buildClassFeature(attrValue)
				features = if features then features.concat(newFeatures) else newFeatures
			else
				customDomCompiler = cola._userDomCompiler[attrName]
				if customDomCompiler
					result = customDomCompiler(scope, dom, context)
					if result
						if result instanceof cola._BindingFeature
							features.push(result)
						if typeof result == "function"
							initializers ?= []
							initializers.push(result)
				else
					if attrName.substring(0, 2) == "on"
						feature = buildEvent(scope, dom, attrName.substring(2), attrValue)
					else if attrName == "resource"
						feature = buildResourceFeature(scope, dom, attrValue)
					else if attrName == "watch"
						feature = buildWatchFeature(scope, dom, attrValue)
					else
						feature = buildAttrFeature(dom, attrName, attrValue)

					if feature
						features ?= []
						features.push(feature)

	for customDomCompiler in cola._userDomCompiler.$
		result = customDomCompiler(scope, dom, context)
		if result
			if result instanceof cola._BindingFeature
				features.push(result)
			if typeof result == "function"
				initializers ?= []
				initializers.push(result)

	if removeAttrs
		for removeAttr in removeAttrs
			dom.removeAttribute(removeAttr)

	childContext = {}
	for k, v of context
		childContext[k] = v
	childContext.inRepeatTemplate = context.inRepeatTemplate or bindingType == "repeat"
	childContext.defaultPath = defaultPath if defaultPath

	child = dom.firstChild
	while child
		child = _doRrenderDomTemplate(child, scope, childContext)
		child = child.nextSibling

	if features?.length
		if bindingType == "repeat"
			domBinding = new cola._RepeatDomBinding(dom, scope, features)
			scope = domBinding.scope
			defaultPath = scope.data.alias
		else if bindingType == "alias"
			domBinding = new cola._AliasDomBinding(dom, scope, features)
			scope = domBinding.scope
			defaultPath = scope.data.alias
		else
			domBinding = new cola._DomBinding(dom, scope, features)
		domBinding = null if not domBinding.feature

	if initializers
		if context.inRepeatTemplate or (domBinding and domBinding instanceof cola._RepeatDomBinding)
			cola.util.userData(dom, cola.constants.DOM_INITIALIZER_KEY, initializers)
		else
			for initializer in initializers
				initializer(scope, dom)

	if domBinding
		domBinding.refresh(true) unless context.inRepeatTemplate
		if domBinding instanceof cola._RepeatDomBinding
			tailDom = cola.util.userData(domBinding.dom, cola.constants.REPEAT_TAIL_KEY)
			dom = tailDom or domBinding.dom
	return dom

buildAliasFeature = (expression) ->
	return new cola._AliasFeature(expression)

buildRepeatFeature = (expression) ->
	return new cola._RepeatFeature(expression)

buildBindFeature = (expression, dom) ->
	nodeName = dom.nodeName
	if nodeName == "INPUT"
		type = dom.type
		if type == "checkbox"
			feature = new cola._CheckboxFeature(expression)
		else if type == "radio"
			feature = new cola._RadioFeature(expression)
		else
			feature = new cola._TextBoxFeature(expression)
	else if nodeName == "SELECT"
		feature = new cola._SelectFeature(expression)
	else if nodeName == "TEXTAREA"
		feature = new cola._TextBoxFeature(expression)
	else
		feature = new cola._DomAttrFeature(expression, "text", false)
	return feature

createContentPart = (part, scope) ->
	if part instanceof cola.Expression
		expression = part
		textNode = document.createElement("span")
		feature = new cola._TextNodeFeature(expression)
		domBinding = new cola._DomBinding(textNode, scope, feature)
		domBinding.refresh()
	else
		textNode = document.createTextNode(part)
	return textNode

buildContent = (parts, dom, scope) ->
	if parts.length == 1
		childNode = createContentPart(parts[0], scope)
	else
		childNode = document.createDocumentFragment()
		for part in parts
			partNode = createContentPart(part, scope)
			childNode.appendChild(partNode)
	cola._ignoreNodeRemoved = true
	dom.parentNode.replaceChild(childNode, dom)
	cola._ignoreNodeRemoved = false
	return

buildStyleFeature = (styleStr) ->
	return false unless styleStr
	style = cola.util.parseStyleLikeString(styleStr)

	features = []
	for styleProp, styleExpr of style
		expression = cola._compileExpression(styleExpr)
		if expression
			feature = new cola._DomAttrFeature(expression, styleProp, true)
			features.push(feature)
	return features

buildClassFeature = (classStr) ->
	return false unless classStr
	classConfig = cola.util.parseStyleLikeString(classStr)

	features = []
	for className, classExpr of classConfig
		expression = cola._compileExpression(classExpr)
		if expression
			feature = new cola._DomClassFeature(expression, className, true)
			features.push(feature)
	return features

buildAttrFeature = (dom, attr, expr) ->
	expression = cola._compileExpression(expr)
	if expression
		if attr == "display"
			feature = new cola._DisplayFeature(expression)
		else if attr == "options" and dom.nodeName == "SELECT"
			feature = new cola._SelectOptionsFeature(expression)
		else
			feature = new cola._DomAttrFeature(expression, attr, false)
	return feature

buildResourceFeature = (scope, dom, expr) ->
	expr = cola.util.trim(expr)
	if expr
		$fly(dom).text(cola.resource(expr))
	return

buildWatchFeature = (scope, dom, expr) ->
	i = expr.indexOf(" on ")
	if i > 0
		action = expr.substring(0, i)
		pathStr = expr.substring(i + 4)
		if pathStr
			paths = []
			for path in pathStr.split(",")
				path = cola.util.trim(path)
				paths.push(path) if path
			if paths.length
				feature = new cola._WatchFeature(action, paths)

	if not feature
		throw new cola.Exception("\"#{expr}\" is not a valid watch expression.")
	return feature

buildEvent = (scope, dom, event, expr) ->
	expression = cola._compileExpression(expr)
	if expression
		feature = new cola._EventFeature(expression, event)
	return feature