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
		else if arg instanceof cola.Scope
			model = arg
		else if arg?.nodeType or typeof arg == "object" and arg.length > 0
			targetDom = arg

	init = (dom, model, param) ->
		oldScope = cola.currentScope
		cola.currentScope = model
		try
			if not model._dom
				model._dom = dom
			else
				model._dom = model._dom.concat(dom)
			delete model._$dom

			fn?(model, param)

			if not dom
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
		if not model
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

cola.xRender = (template, model, context) ->
	return unless template

	oldScope = cola.currentScope
	model = model or oldScope

	if template.nodeType
		dom = template
	else if typeof template == "string"
		if template.match(/^\#[\w\-\$]*$/)
			template = cola.util.getGlobalTemplate(template.substring(1))
			dom = null

		if template
			documentFragment = document.createDocumentFragment()
			div = document.createElement("div")
			div.innerHTML = template
			child = div.firstChild
			while child
				next = child.nextSibling
				documentFragment.appendChild(child)
				child = next
	else
		cola.currentScope = model
		try
			context ?= {}
			if template instanceof Array
				documentFragment = document.createDocumentFragment()
				for node in template
					child = null
					for processor in cola.xRender.nodeProcessors
						child = processor(node, context)
						if child then break
					child ?= $.xCreate(node, context)
					documentFragment.appendChild(child) if child
			else
				for processor in cola.xRender.nodeProcessors
					dom = processor(template, context)
					if dom then break
				unless dom then dom = $.xCreate(template, context)
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

cola.xRender.nodeProcessors = []

cola._renderDomTemplate = (dom, scope, context = {}) ->
	_doRenderDomTemplate(dom, scope, context)
	return

_doRenderDomTemplate = (dom, scope, context) ->
	return dom if dom.nodeType == 8
	return dom if dom.nodeType == 1 and
		(dom.hasAttribute(cola.constants.IGNORE_DIRECTIVE) or dom.className.indexOf(cola.constants.IGNORE_DIRECTIVE) >= 0)
	return dom if IGNORE_NODES.indexOf(dom.nodeName) > -1

	if dom.nodeType == 3 # #text
		bindingExpr = dom.nodeValue
		parts = cola._compileText(bindingExpr)
		buildContent(parts, dom, scope) if parts?.length
		return dom
	else if dom.nodeType == 11 # #documentFragment
		child = dom.firstChild
		while child
			child = _doRenderDomTemplate(child, scope, context)
			child = child.nextSibling
		return dom

	initializers = null
	features = null
	removeAttrs = null

	bindingExpr = dom.getAttribute("c-repeat")
	if bindingExpr
		bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
		bindingType = "repeat"
		feature = cola._domFeatureBuilder[bindingType](bindingExpr, bindingType, dom)
		features ?= []
		features.push(feature)
		dom.removeAttribute("c-repeat")
	else
		bindingExpr = dom.getAttribute("c-alias")
		if bindingExpr
			bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
			bindingType = "alias"
			feature = cola._domFeatureBuilder[bindingType](bindingExpr, bindingType, dom)
			features ?= []
			features.push(feature)
			dom.removeAttribute("c-alias")

	for customDomCompiler in cola._userDomCompiler.$
		result = customDomCompiler(scope, dom, null, context)
		if result
			if result instanceof cola._BindingFeature
				features.push(result)
			if typeof result == "function"
				initializers ?= []
				initializers.push(result)

	for attr in dom.attributes
		attrName = attr.name
		if attrName.substring(0, 2) == "c-"
			removeAttrs ?= []
			removeAttrs.push(attrName)

			attrValue = attr.value
			if attrValue and context.defaultPath
				attrValue = attrValue.replace(ALIAS_REGEXP, context.defaultPath)

			if attrValue
				attrName = attrName.substring(2)

				customDomCompiler = cola._userDomCompiler.hasOwnProperty(attrName) and cola._userDomCompiler[attrName]
				if customDomCompiler
					result = customDomCompiler(scope, dom, attr, context)
					if result
						if result instanceof cola._BindingFeature
							features.push(result)
						else if result instanceof Array
							features.push(f) for f in result
						else if typeof result == "function"
							initializers ?= []
							initializers.push(result)
				else
					if attrName.indexOf("on") == 0
						feature = cola._domFeatureBuilder.event(attrValue, attrName, dom)
					else
						builder = cola._domFeatureBuilder.hasOwnProperty(attrName) and cola._domFeatureBuilder[attrName]
						feature = (builder or cola._domFeatureBuilder["$"]).call(cola._domFeatureBuilder, attrValue, attrName, dom)

					if feature
						features ?= []
						if feature  instanceof cola._BindingFeature
							features.push(feature)
						else if feature instanceof Array
							features.push(f) for f in feature

	if removeAttrs
		for removeAttr in removeAttrs
			dom.removeAttribute(removeAttr)

	if features?.length
		domBinding = cola._domBindingBuilder[bindingType or "$"](dom, scope, features)
		defaultPath = scope.data.alias if scope.data.alias

	if not cola.util.userData(dom, cola.constants.DOM_SKIP_CHILDREN)
		childContext = {}
		for k, v of context
			childContext[k] = v
		childContext.inRepeatTemplate = context.inRepeatTemplate or bindingType == "repeat"
		childContext.defaultPath = defaultPath if defaultPath

		child = dom.firstChild
		while child
			child = _doRenderDomTemplate(child, scope, childContext)
			child = child.nextSibling
	else
		cola.util.removeUserData(dom, cola.constants.DOM_SKIP_CHILDREN)

	if initializers
		if context.inRepeatTemplate or bindingType is "repeat"
			cola.util.userData(dom, cola.constants.DOM_INITIALIZER_KEY, initializers)
		else
			for initializer in initializers
				initializer(scope, dom)

	if features?.length
		domBinding.refresh(true) unless context.inRepeatTemplate
		if domBinding instanceof cola._RepeatDomBinding
			tailDom = cola.util.userData(domBinding.dom, cola.constants.REPEAT_TAIL_KEY)
			dom = tailDom or domBinding.dom
	return dom

createContentPart = (part, scope) ->
	if part instanceof cola.Expression
		expression = part
		textNode = document.createElement("span")
		feature = new cola._DomAttrFeature(expression, "text")
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
	dom.parentNode.replaceChild(childNode, dom)
	return

cola._domBindingBuilder =
	$: (dom, scope, features) ->
		return new cola._DomBinding(dom, scope, features)

	repeat: (dom, scope, features) ->
		domBinding = new cola._RepeatDomBinding(dom, scope, features)
		scope = domBinding.scope
		return domBinding

	alias: (dom, scope, features) ->
		domBinding = new cola._AliasDomBinding(dom, scope, features)
		scope = domBinding.scope
		return domBinding

cola._domFeatureBuilder =
	$: (attrValue, attrName, dom) ->
		expression = cola._compileExpression(attrValue)
		if expression
			if attrName == "display"
				feature = new cola._DisplayFeature(expression)
			else if attrName == "options" and dom.nodeName == "SELECT"
				feature = new cola._SelectOptionsFeature(expression)
			else
				feature = new cola._DomAttrFeature(expression, attrName)
		return feature

	repeat: (attrValue) ->
		expression = cola._compileExpression(attrValue, "repeat")
		if expression
			return new cola._RepeatFeature(expression)
		else
			return

	alias: (attrValue) ->
		expression = cola._compileExpression(attrValue, "alias")
		if expression
			return new cola._AliasFeature(expression)
		else
			return

	bind: (attrValue, attrName, dom) ->
		expression = cola._compileExpression(attrValue)
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
			feature = new cola._DomAttrFeature(expression, "text")
		return feature

	style: (attrValue) ->
		return false unless attrValue
		style = cola.util.parseStyleLikeString(attrValue)

		features = []
		for styleProp, styleExpr of style
			expression = cola._compileExpression(styleExpr)
			if expression
				feature = new cola._DomStylePropFeature(expression, styleProp)
				features.push(feature)
		return features

	classname: (attrValue) ->
		return false unless attrValue

		features = []
		try
			expression = cola._compileExpression(attrValue)
			if expression
				feature = new cola._DomClassFeature(expression)
				features.push(feature)
		catch
			classConfig = cola.util.parseStyleLikeString(attrValue)
			for className, classExpr of classConfig
				expression = cola._compileExpression(classExpr)
				if expression
					feature = new cola._DomToggleClassFeature(expression, className)
					features.push(feature)
		return features

	class: () -> @classname.apply(@, arguments)

	resource: (attrValue, attrName, dom) ->
		attrValue = cola.util.trim(attrValue)
		if attrValue
			$fly(dom).text(cola.resource(attrValue))
		return

	watch: (attrValue) ->
		i = attrValue.indexOf(" on ")
		if i > 0
			action = attrValue.substring(0, i)
			pathStr = attrValue.substring(i + 4)
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

	event: (attrValue, attrName) ->
		expression = cola._compileExpression(attrValue)
		if expression
			feature = new cola._EventFeature(expression, attrName.substring(2))
		return feature