IGNORE_NODES = [ "SCRIPT", "STYLE", "META", "TEMPLATE", "OBJECT" ]
ALIAS_REGEXP = new RegExp("\\$default", "g")

cola._mainInitFuncs = []

cola._rootFunc = ()->
	fn = null
	targetDom = null
	modelName = null
	for arg in arguments
		if typeof arg is "function"
			fn = arg
		else if typeof arg is "string"
			modelName = arg
		else if arg instanceof cola.Scope
			model = arg
		else if arg?.nodeType or typeof arg is "object" and arg.length > 0
			targetDom = arg

	init = (dom, model, param)->
		oldScope = cola.currentScope
		cola.currentScope = model
		try
			if not dom
				viewDoms = document.getElementsByClassName(cola.constants.VIEW_CLASS)
				if viewDoms?.length then dom = Array.prototype.slice.call(viewDoms)
			dom ?= document.body

			if not model._doms
				model._doms = if dom instanceof Array then dom else [ dom ]
			else
				if not model._doms instanceof Array
					model._doms = [ model._dom ]
				model._doms.concat(dom)
			delete model._$doms

			fn?(model, param)
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
			for dom in model._doms
				cola._renderDomTemplate(dom, model)
	return cola

cola._init = ()->
	cola.inited = true

	if cola.getListeners("beforeInit")
		cola.fire("beforeInit", cola)
		cola.off("beforeInit")

	initFuncs = cola._mainInitFuncs

	if not initFuncs.length
		cola ()->
		initFuncs = cola._mainInitFuncs

	delete cola._mainInitFuncs

	for initFunc in initFuncs
		initFunc.init(initFunc.targetDom, initFunc.model)

	for initFunc in initFuncs
		model = initFunc.model
		for dom in model._doms
			cola._renderDomTemplate(dom, model)

	if cola.getListeners("ready")
		cola.fire("ready", cola)
		cola.off("ready")
	return

$ ()-> cola._init()

cola._userDomCompiler =
	$: []
	$startContent: []
	$endContent: []

cola.xCreate = $.xCreate

cola.xRender = (template, model, context)->
	return unless template

	oldScope = cola.currentScope
	model = model or oldScope

	if template.nodeType
		dom = template
	else if typeof template is "string"
		if template.match(/^\#[\w\-\$]*$/)
			template = cola.util.getGlobalTemplate(template.substring(1))
			dom = null

		if template
			documentFragment = document.createDocumentFragment()
			div = document.createElement("div")
			div.innerHTML = template
			child = div.firstElementChild
			while child
				next = child.nextElementSibling
				documentFragment.appendChild(child)
				child = next
	else
		cola.currentScope = model
		try
			context ?=
				xRender: true

			if template instanceof Array
				documentFragment = document.createDocumentFragment()
				for node in template
					child = $.xCreate(node, context)
					documentFragment.appendChild(child) if child
			else
				dom = $.xCreate(template, context)
		finally
			cola.currentScope = oldScope

	# 处理xRender的顶层节点中包含c-repeat的情况
	if dom and not dom.parentNode and dom.getAttribute("c-repeat")
		documentFragment = document.createDocumentFragment()
		documentFragment.appendChild(dom)
		dom = null

	if dom
		cola._renderDomTemplate(dom, model, context)
	else if documentFragment
		cola._renderDomTemplate(documentFragment, model, context)

		if documentFragment.firstChild is documentFragment.lastChild
			dom = documentFragment.firstChild
		else
			dom = documentFragment
	return dom

cola._renderDomTemplate = (dom, scope, context = {})->
	if _doRenderDomTemplate(dom, scope, context)
		$(dom).removeClass(cola.constants.SHOW_ON_READY_CLASS)
			.find("." + cola.constants.SHOW_ON_READY_CLASS).removeClass(cola.constants.SHOW_ON_READY_CLASS)
	return

_doRenderDomTemplate = (dom, scope, context)->
	return if dom.nodeType is 8 or dom.nodeName is "SVG"
	return if dom.nodeType is 1 and
	  (dom.hasAttribute(cola.constants.IGNORE_DIRECTIVE) or dom.className.indexOf?(cola.constants.IGNORE_DIRECTIVE) >= 0)
	return if IGNORE_NODES.indexOf(dom.nodeName) > -1

	if dom.nodeType is 3 # text
		bindingExpr = dom.nodeValue
		parts = cola._compileText(scope, bindingExpr)
		buildContent(parts, dom, scope) if parts?.length
		return dom

	else if dom.nodeType is 1 # element
		if dom.className?.indexOf and not dom._ignoreLazyClass
			if dom.className.indexOf(cola.constants.LAZY_CLASS) >= 0 and
			  dom.className.split(' ').indexOf(cola.constants.LAZY_CLASS) >= 0
				$(dom).on "visibilityChange", (evt, data)->
					return unless data.visible
					if not dom._rendered
						dom._rendered = true
						dom._ignoreLazyClass = true
						cola._renderDomTemplate(dom, scope)
					else if data.visible
						cola.util._unfreezeDom(dom)
					else
						cola.util._freezeDom(dom)
					return

				if dom.offsetWidth is 0 and dom.offsetHeight is 0
					return
				else
					dom._rendered = true
			else if dom.className.indexOf(cola.constants.LAZY_CONTENT_CLASS) >= 0 and
			  dom.className.split(' ').indexOf(cola.constants.LAZY_CONTENT_CLASS) >= 0
				cola.util.userData(dom, cola.constants.DOM_SKIP_CHILDREN, true)
				$(dom).on "visibilityChange", (evt, data)->
					return unless data.visible
					if not dom._contentRendered
						dom._contentRendered = true
						cola.util.removeUserData(dom, cola.constants.DOM_SKIP_CHILDREN)
						dom._ignoreLazyClass = true
						cola._renderDomTemplate(dom, scope)
					else if data.visible
						child = dom.firstChild
						while child
							cola.util._unfreezeDom(child)
							child = child.nextSibling
					else
						child = dom.firstChild
						while child
							cola.util._freezeDom(child)
							child = child.nextSibling
					return

	else if dom.nodeType is 11 # documentFragment
		child = dom.firstElementChild
		while child
			child = _doRenderDomTemplate(child, scope, context) or child
			child = child.nextElementSibling
		return dom

	initializers = null
	features = null
	removeAttrs = null

	bindingExpr = dom.getAttribute("c-repeat")
	if bindingExpr
		bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
		bindingType = "repeat"
		feature = cola._domFeatureBuilder[bindingType](scope, bindingExpr, bindingType, dom)
		features ?= []
		features.push(feature)
		dom.removeAttribute("c-repeat")
	else
		bindingExpr = dom.getAttribute("c-alias")
		if bindingExpr
			bindingExpr = bindingExpr.replace(ALIAS_REGEXP, context.defaultPath)
			bindingType = "alias"
			feature = cola._domFeatureBuilder[bindingType](scope, bindingExpr, bindingType, dom)
			features ?= []
			features.push(feature)
			dom.removeAttribute("c-alias")

	for customDomCompiler in cola._userDomCompiler.$
		result = customDomCompiler(scope, dom, context)
		if result
			if result instanceof cola._BindingFeature
				features.push(result)
			if typeof result is "function"
				initializers ?= []
				initializers.push(result)

	for attr in dom.attributes
		attrName = attr.name
		if attrName.substring(0, 2) is "c-"
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
						else if typeof result is "function"
							initializers ?= []
							initializers.push(result)
				else
					if attrName.indexOf("on") is 0
						feature = cola._domFeatureBuilder.event(scope, attrValue, attrName, dom)
					else
						builder = cola._domFeatureBuilder.hasOwnProperty(attrName) and cola._domFeatureBuilder[attrName]
						feature = (builder or cola._domFeatureBuilder["$"]).call(cola._domFeatureBuilder, scope, attrValue, attrName, dom)

					if feature
						features ?= []
						if feature instanceof cola._BindingFeature
							features.push(feature)
						else if feature instanceof Array
							features.push(f) for f in feature

	if removeAttrs
		for removeAttr in removeAttrs
			dom.removeAttribute(removeAttr)

	if features?.length
		domBinding = cola._domBindingBuilder[bindingType or "$"](dom, scope, features, context)
		defaultPath = scope.data.alias if scope.data.alias

	if domBinding?.scope
		oldScope = scope
		scope = domBinding.scope

	if initializers
		if context.inRepeatTemplate or bindingType is "repeat"
			cola.util.userData(dom, cola.constants.DOM_INITIALIZER_KEY, initializers)
		else
			for initializer in initializers
				initializer(scope, dom)

	if not cola.util.userData(dom, cola.constants.DOM_SKIP_CHILDREN)
		childContext = {}
		for k, v of context
			childContext[k] = v

		childContext.inRepeatTemplate = context.inRepeatTemplate or bindingType is "repeat"
		childContext.defaultPath = defaultPath if defaultPath

		if cola._userDomCompiler.$startContent.length
			for customDomCompiler in cola._userDomCompiler.$startContent
				customDomCompiler(scope, dom, context, childContext)

		child = dom.firstElementChild
		while child
			child = _doRenderDomTemplate(child, scope, childContext) or child
			child = child.nextElementSibling

		if cola._userDomCompiler.$endContent.length
			for customDomCompiler in cola._userDomCompiler.$endContent
				customDomCompiler(scope, dom, context, childContext)

	if oldScope
		scope = oldScope

	if features?.length
		if not context.inRepeatTemplate
			domBinding.refresh(true)

		if domBinding instanceof cola._RepeatDomBinding
			tailDom = cola.util.userData(domBinding.dom, cola.constants.REPEAT_TAIL_KEY)
			dom = tailDom or domBinding.dom
	return dom

createContentPart = (part, scope)->
	if part instanceof cola.Expression
		expression = part
		textNode = document.createElement("span")
		feature = new cola._DomAttrFeature(expression, "text")
		domBinding = new cola._DomBinding(textNode, scope, feature)
		domBinding.refresh()
	else
		textNode = document.createTextNode(part)
	return textNode

buildContent = (parts, dom, scope)->
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
	$: (dom, scope, features, context)->
		forceInit = not context?.inRepeatTemplate
		return new cola._DomBinding(dom, scope, features, forceInit)

	repeat: (dom, scope, features, context)->
		forceInit = not context?.inRepeatTemplate
		domBinding = new cola._RepeatDomBinding(dom, scope, features, forceInit)
		scope = domBinding.scope
		return domBinding

	alias: (dom, scope, features, context)->
		forceInit = not context?.inRepeatTemplate
		domBinding = new cola._DomBinding(dom, scope, features, forceInit)
		scope = domBinding.scope
		return domBinding

cola._domFeatureBuilder =
	$: (scope, attrValue, attrName, dom)->
		if attrName is "display"
			feature = new cola._DisplayFeature(attrValue)
		else if attrName is "options" and dom.nodeName is "SELECT"
			feature = new cola._SelectOptionsFeature(attrValue)
		else
			feature = new cola._DomAttrFeature(attrValue, attrName)
		return feature

	repeat: (scope, attrValue)->
		return new cola._RepeatFeature(attrValue, "repeat")

	alias: (scope, attrValue)->
		return new cola._AliasFeature(attrValue, "alias")

	bind: (scope, attrValue, attrName, dom)->
		nodeName = dom.nodeName
		if nodeName is "INPUT"
			type = dom.type
			if type is "checkbox"
				feature = new cola._CheckboxFeature(attrValue)
			else if type is "radio"
				feature = new cola._RadioFeature(attrValue)
			else
				feature = new cola._TextBoxFeature(attrValue)
		else if nodeName is "SELECT"
			feature = new cola._SelectFeature(attrValue)
		else if nodeName is "TEXTAREA"
			feature = new cola._TextBoxFeature(attrValue)
		else
			feature = new cola._DomAttrFeature(attrValue, "text")
		return feature

	style: (scope, attrValue)->
		return false unless attrValue
		style = cola.util.parseStyleLikeString(attrValue)

		features = []
		for styleProp, styleExpr of style
			if styleExpr
				feature = new cola._DomStylePropFeature(styleExpr, styleProp)
				features.push(feature)
		return features

	classname: (scope, attrValue)->
		return false unless attrValue

		features = []
		try
			cola._compileExpression(scope, attrValue)
			feature = new cola._DomClassFeature(attrValue)
			features.push(feature)
		catch
		# do nothing

		if not features.length
			classConfig = cola.util.parseStyleLikeString(attrValue)
			for className, classExpr of classConfig
				feature = new cola._DomToggleClassFeature(classExpr, className)
				features.push(feature)
		return features

	class: ()-> @classname.apply(@, arguments)

	resource: (scope, attrValue, attrName, dom)->
		attrValue = cola.util.trim(attrValue)
		if attrValue
			$fly(dom).text(cola.resource(attrValue))
		return

	watch: (scope, attrValue)->
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

	event: (scope, attrValue, attrName)->
		parts = attrName.substring(2).split(".")
		return new cola._EventFeature(attrValue, parts[0], parts.slice(1))