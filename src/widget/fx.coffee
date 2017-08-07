do() ->
	docStyle = window.document.documentElement.style
	translate3d = false

	if window.opera && Object.prototype.toString.call(opera) == '[object Opera]'
		engine = 'presto'
	else if 'MozAppearance' of docStyle
		engine = 'gecko'
	else if 'WebkitAppearance' of docStyle
		engine = 'webkit'
	else if typeof navigator.cpuClass == 'string'
		engine = 'trident'

	vendorPrefix = {
		trident: 'ms'
		gecko: 'Moz'
		webkit: 'Webkit'
		presto: 'O'
	}[engine]
	cssPrefix = {trident: '-ms-', gecko: '-moz-', webkit: '-webkit-', presto: '-o-'}[engine]
	helperElem = document.createElement("div")
	perspectiveProperty = vendorPrefix + "Perspective"
	transformProperty = vendorPrefix + "Transform"
	transformStyleName = cssPrefix + "transform"
	transitionProperty = vendorPrefix + "Transition"
	transitionStyleName = cssPrefix + "transition"
	transitionEndProperty = vendorPrefix.toLowerCase() + "TransitionEnd"

	translate3d = true if helperElem.style[perspectiveProperty] != undefined

	getTranslate = (element)->
		result =
			left: 0
			top: 0
		return result if element == null or element.style == null
		transform = element.style[transformProperty]
		matches = /translate\(\s*(-?\d+(\.?\d+?)?)px,\s*(-?\d+(\.\d+)?)px\)\s*translateZ\(0px\)/g.exec(transform)
		if matches
			result.left = +matches[1]
			result.top = +matches[3]
		return result

	cancelTranslateElement = (element)->
		return if element == null or element.style == null
		transformValue = element.style[transformProperty];
		if transformValue
			transformValue = transformValue.replace(/translate\(\s*(-?\d+(\.?\d+?)?)px,\s*(-?\d+(\.\d+)?)px\)\s*translateZ\(0px\)/g,
			  "")
			element.style[transformProperty] = transformValue

	translateElement = (element, x, y)->
		return if x == null and y == null
		return if element == null or element.style == null
		return if !element.style[transformProperty] and x == 0 and y == 0

		if x == null or y == null
			translate = getTranslate(element)
			x ?= translate.left
			y ?= translate.top
		cancelTranslateElement(element)
		value = ' translate(' + (if x then (x + 'px') else '0px') + ',' + (if y then  (y + 'px') else '0px') + ')'
		value += ' translateZ(0px)'if translate3d
		element.style[transformProperty] += value
		return element

	cola.Fx =
		transitionEndProperty: transitionEndProperty
		translate3d: translate3d
		transformProperty: transformProperty
		transformStyleName: transformStyleName
		transitionProperty: transitionProperty
		transitionStyleName: transitionStyleName
		perspectiveProperty: perspectiveProperty
		getElementTranslate: getTranslate,
		translateElement: translateElement,
		cancelTranslateElement: cancelTranslateElement