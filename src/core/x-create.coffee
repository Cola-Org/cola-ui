# detect IE
oldIE = `!-[1,]`

$.xCreate = xCreate = (template, context)->

	isSimpleValue = (value)->
		if value == null then return true
		type = typeof value
		return type isnt "object" and type isnt "function" or value instanceof Date

	if template instanceof Array
		elements = []
		for part in template
			element = xCreate(part, context)
			elements.push(element) if element?
		return elements

	if xCreate.templateProcessors.length
		for templateProcessor in xCreate.templateProcessors
			element = templateProcessor(template, context)
			return element if element?

	if typeof template is "object" and template.nodeType
		el = template
	else
		if typeof template is "string"
			if template.charAt(0) is '^'
				template = tagName: template.substring(1)
			else
				return document.createTextNode(template)

		tagName = template.tagName or "DIV"
		tagName = tagName.toUpperCase();

		if oldIE and tagName is "INPUT" and template.type
			el = document.createElement("<" + tagName + " type=\"" + template.type + "\"/>")
		else
			el = document.createElement(tagName)

		$el = $(el)
		setAttrs(el, $el, template, context);

		content = template.content
		if content?
			if isSimpleValue(content)
				if typeof content is "string" and content.charAt(0) is '^'
					appendChild(el, document.createElement(content.substring(1)))
				else
					$el.text(content)
			else
				if content instanceof Array
					for part in content
						if isSimpleValue(part)
							if typeof part is "string" and part.charAt(0) is '^'
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
	data: (el, attrName, attrValue, context)->
		$fly(el).data(attrValue)
		return

	style: (el, attrName, attrValue, context)->
		if typeof attrValue is "string"
			el.style = attrValue
		else if attrValue != null
			$fly(el).css(attrValue)
		return

setAttrs = (el, $el, attrs, context)  ->
	defaultAttributeProcessor = xCreate.attributeProcessor["$"]

	for attrName of attrs
		attrValue = attrs[attrName]
		if attrValue is undefined then continue

		attributeProcessor = xCreate.attributeProcessor[attrName]
		if attributeProcessor
			if attributeProcessor(el, attrName, attrValue, context) isnt true
				continue

		switch attrName
			when "tagName", "nodeName", "content", "html"
				continue
			when "contextKey"
				if context instanceof Object and attrValue and typeof attrValue is "string"
					context[attrValue] = el
			when "data"
				if typeof attrValue is "object" and not (attrValue instanceof Date)
					for k, v of attrValue
						$el.data(k, v)
				else
					$el.attr("data", attrValue)
			when "classname"
				$el.attr("class", attrValue)
			else
				if defaultAttributeProcessor
					if defaultAttributeProcessor(el, attrName, attrValue, context) isnt true
						continue

				if typeof attrValue is "function"
					$el.on(attrName, attrValue)
				else
					if typeof attrValue is "boolean"
						attrValue = attrValue + ""
					el.setAttribute(attrName, attrValue)
	return

appendChild = (parentEl, el)->
	if parentEl.nodeName is "TABLE" and el.nodeName is "TR"
		tbody;
		if parentEl and parentEl.tBodies[0]
			tbody = parentEl.tBodies[0]
		else
			tbody = parentEl.appendChild(document.createElement("tbody"))
		parentEl = tbody
	parentEl.appendChild(el)

createNodeForAppend = (template, context)->
	result = xCreate(template, context)
	return null unless result

	if result instanceof Array
		fragment = document.createDocumentFragment()
		for element in result
			fragment.appendChild(element)
		result = fragment
	return result

$.fn.xAppend = (template, context)->
	result = createNodeForAppend(template, context)
	if not result then return null
	return @append(result)

$.fn.xInsertBefore = (template, context)->
	result = createNodeForAppend(template, context)
	if not result then return null
	return @before(result)

$.fn.xInsertAfter = (template, context)->
	result = createNodeForAppend(template, context)
	if not result then return null
	return @after(result)