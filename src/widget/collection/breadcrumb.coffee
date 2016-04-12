cola.breadcrumb ?= {}
class cola.breadcrumb.Section extends cola.Widget
	@CLASS_NAME: "section"
	@tagName: "a"
	@attributes:
		text:
			refreshDom: true
		active:
			type: "boolean"
			refreshDom: true
			defaultValue: false
		href:
			refreshDom: true
		target:
			refreshDom: true

	_parseDom: (dom)->
		unless @_text
			text = cola.util.getTextChildData(dom)
			@_text = text if text
		unless @_href
			href = dom.getAttribute("href")
			@_href = href if href
		unless @_target
			target = dom.getAttribute("target")
			@_target = target if target
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		text = @get("text")
		@get$Dom().text(text or "")
		@_classNamePool.toggle("active", @_active)
		$dom = @get$Dom()
		if @_href then $dom.attr("href", @_href) else $dom.removeAttr("href")
		$dom.attr("target", @_target || "")
		return

class cola.Breadcrumb extends cola.Widget
	@tagName: "c-breadcrumb"
	@CHILDREN_TYPE_NAMESPACE: "breadcrumb"
	@CLASS_NAME: "breadcrumb"

	@attributes:
		divider:
			enum: ["chevron", "slash"]
			defaultValue: "chevron"
		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				if oldValue and oldValue isnt value and @_dom
					@get$Dom().removeClass(oldValue)
				@["_size"] = value
				return @

		sections:
			refreshDom: true
			setter: (value)->
				@clear()
				@addSection(section) for section in value
				return @

		currentIndex:
			type: "number"
			setter: (value)->
				@_currentIndex = value
				@setCurrent(value)
			getter: ()->
				if @_current and @_sections
					return @_sections.indexOf(@_current)
				else
					return -1

	@events:
		sectionClick: null
		change: null

	_initDom: (dom)->
		super(dom)
		if @_sections?.length
			for section in @_sections
				@_rendSection(section)
				if section.get("active") then active = section
			if active then @_doChange(active)

		activeSection = (targetDom)=>
			@fire("sectionClick", @, {sectionDom: targetDom})
			@_doChange(targetDom)

		@get$Dom().delegate(">.section", "click", (event)-> activeSection(this, event))

	_parseDom: (dom)->
		return unless dom
		child = dom.firstChild

		while child
			if child.nodeType == 1
				section = cola.widget(child)
				if !section and cola.util.hasClass(child, "section")
					sectionConfig = {dom: child}
					if cola.util.hasClass(child, "active") then sectionConfig.active = true
					section = new cola.breadcrumb.Section(sectionConfig)

				@addSection(section) if section instanceof cola.breadcrumb.Section
			child = child.nextSibling
		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		size = @get("size")
		@_classNamePool.add(size) if size

		return

	_makeDivider: ()->
		divider = @get("divider")
		if divider is "chevron"
			return $.xCreate(
				tagName: "i"
				class: "right chevron icon divider"
			)
		else
			return $.xCreate(
				tagName: "div"
				class: "divider"
				content: "/"
			)

	_rendSection: (section)->
		index = @_sections.indexOf(section)
		@_dividers ?= []

		sectionDom = section.getDom()
		if sectionDom.parentNode isnt @_dom
			if @_dividers.length < index
				divider = @_makeDivider()
				@_dividers.push(divider)
				@_dom.appendChild(divider)
			@_dom.appendChild(section.getDom())
		else if index > 0
			prev = sectionDom.previousElementSibling
			if prev and !cola.util.hasClass(prev, "divider")
				divider = @_makeDivider()
				@_dividers.push(divider)
				section.get$Dom().before(divider)

		return

	_doChange: (section)->
		if section.nodeType is 1
			targetDom = section
		else if section instanceof cola.breadcrumb.Section
			targetDom = section.getDom()
		else
			return

		$(">.section.active", @_dom).each((index, itemDom)->
			if itemDom isnt targetDom
				section = cola.widget(itemDom)
				if section then section.set("active", false) else $fly(itemDom).removeClass("active")
			return
		)

		targetSection = cola.widget(targetDom)
		for s in @_sections
			if s isnt targetSection then s.set("active", false)
		@_current = targetSection
		if targetSection then targetSection.set("active", true) else $fly(targetDom).addClass("active")
		if @_rendered then @fire("change", @, {currentDom: targetDom})
		return

	addSection: (config)->
		return @ if @_destroyed
		@_sections ?= []
		if config instanceof cola.breadcrumb.Section
			section = config
		else if typeof config is "string"
			section = new cola.breadcrumb.Section({text: config})
		else if config.constructor == Object::constructor
			section = new cola.breadcrumb.Section(config)

		if section
			@_sections.push(section)
			@_rendSection(section) if @_dom
			active = section.get("active")
			@_doChange(section) if active

		return @

	removeSection: (section)->
		return @ unless @_sections
		section = @_sections[section] if typeof section is "number"
		@_doRemove(section) if section
		return @

	_doRemove: (section)->
		index = @_sections.indexOf(section)
		if index > -1
			@_sections.splice(index, 1)
			step.remove()
			if index > 0 and @_dividers
				dIndex = index - 1
				divider = @_dividers[dIndex]
				$(divider).remove()
				@_dividers.splice(dIndex, 1)

		return

	clear: ()->
		return @ unless @_sections
		@get$Dom().empty() if @_dom
		@_sections = [] if @_sections.length
		return @

	getSection: (index)->
		sections = @_sections || []
		if typeof index is "number"
			section = sections[index]
		else if typeof index is "string"
			for el in sections
				if index is el.get("text")
					section = el
					break
		return  section

	setCurrent: (section)->
		if section instanceof cola.breadcrumb.Section
			currentSection = section
		else
			currentSection = @getSection(section)

		@_doChange(currentSection) if currentSection
		return @

	getCurrent: ()->
		return @_current

	getCurrentIndex: ()->
		return @_sections.indexOf(@_current) if @_cuurent

	destroy: ()->
		return if @_destroyed
		super()
		delete @_current
		delete @_sections
		delete @_dividers

		return

cola.registerWidget(cola.Breadcrumb)

cola.registerType("breadcrumb", "_default", cola.breadcrumb.Section)
cola.registerType("breadcrumb", "section", cola.breadcrumb.Section)
cola.registerTypeResolver "breadcrumb", (config) ->
	return cola.resolveType("widget", config)