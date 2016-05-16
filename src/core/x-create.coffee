# detect IE
oldIE = `!-[1,]`

$.xCreate = xCreate = (template, context) ->
	if template instanceof Array
		elements = []
		for part in template
			element = xCreate(part, context)
			elements.push(element) if element?
		return elements

	if xCreate.templateProcessors.length
		for templateProcessor in xCreate.templateProcessors
			element = templateProcessor(template)
			return element if element?

	if typeof template == "string"
		if template.charAt(0) == '^'
			template = tagName: template.substring(1)
		else
			return document.createTextNode(template)

	tagName = template.tagName or "DIV"
	tagName = tagName.toUpperCase();

	if oldIE and tagName.toUpperCase() == "INPUT" and template.type
		el = document.createElement("<" + tagName + " type=\"" + template.type + "\"/>")
	else
		el = document.createElement(tagName)

	$el = $(el)
	setAttrs(el, $el, template, context);

	content = template.content
	if content?
		if typeof content == "string"
			if content.charAt(0) == '^'
				appendChild(el, document.createElement(content.substring(1)))
			else
				$el.text(content)
		else
			if content instanceof Array
				for part in content
					if typeof part == "string"
						if part.charAt(0) == '^'
							appendChild(el, document.createElement(part.substring(1)))
						else
							appendChild(el, document.createTextNode(part))
					else
						child = xCreate(part, context)
						appendChild(el, child) if child?
			else if content.nodeType
				appendChild(el, content)
			else
				child = xCreate(content, context)
				appendChild(el, child) if child?
	else if template.html
		$el.html( template.html)
	return el

xCreate.templateProcessors = []

xCreate.attributeProcessor =
	data: ($el, attrName, attrValue, context) ->
		$el.data(attrValue)
		return

	style: ($el, attrName, attrValue, context) ->
		if typeof attrValue == "string"
			$el.attr("style", attrValue)
		else if attrValue != null
			$el.css(attrValue)
		return

setAttrs = (el, $el, attrs, context)  ->
	for attrName of attrs
		attrValue = attrs[attrName]

		attributeProcessor = xCreate.attributeProcessor[attrName]
		if attributeProcessor
			attributeProcessor($el, attrName, attrValue, context)
		else
			switch attrName
				when "tagName", "nodeName", "content", "html"
					continue
				when "contextKey"
					if context instanceof Object and attrValue and typeof attrValue == "string"
						context[attrValue] = el
				when "data"
					if context instanceof Object and attrValue and typeof attrValue == "string"
						context[attrValue] = el
				when "classname"
					$el.attr("class", attrValue)
				else
					if typeof attrValue == "function"
						$el.on(attrName, attrValue)
					else
						$el.attr(attrName, attrValue)
	return

appendChild = (parentEl, el) ->
	if parentEl.nodeName == "TABLE" and el.nodeName == "TR"
		tbody;
		if parentEl and parentEl.tBodies[0]
			tbody = parentEl.tBodies[0]
		else
			tbody = parentEl.appendChild(document.createElement("tbody"))
		parentEl = tbody
	parentEl.appendChild(el)

createNodeForAppend = (template, context) ->
	result = xCreate(template, context)
	return null unless result

	if result instanceof Array
		fragment = document.createDocumentFragment()
		for element in result
			fragment.appendChild(element)
		result = fragment
	return result

$.fn.xAppend = (template, context) ->
	result = createNodeForAppend(template, context)
	if !result then return null
	return @append(result)

$.fn.xInsertBefore = (template, context) ->
	result = createNodeForAppend(template, context)
	if !result then return null
	return @before(result)

$.fn.xInsertAfter = (template, context) ->
	result = createNodeForAppend(template, context)
	if !result then return null
	return @after(result)