cola.breadcrumb ?= {}
class cola.breadcrumb.Section extends cola.Widget
	@CLASS_NAME: "section"
	@ATTRIBUTES:
		text:
			refreshDom: true
		active:
			refreshDom: true
			defaultValue: false

	_parseDom: (dom)->
		unless @_text
			text = cola.util.getTextChildData(dom)
			@_text = text if text
		return

	_createDom: ()->
		dom = document.createElement("a")
		dom.className = "section"
		return dom

	_doRefreshDom: ()->
		return unless @_dom
		super()
		text = @get("text")
		@get$Dom().text(text)if text
		active = @get("active")
		@_classNamePool.toggle("active", !!active)
		return

class cola.Breadcrumb extends cola.Widget
	@CHILDREN_TYPE_NAMESPACE: "breadcrumb"
	@CLASS_NAME: "breadcrumb"
	@ATTRIBUTES:
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
				for section in value
					if section instanceof cola.breadcrumb.Section
						@addSection(section)
					else if typeof section is "string"
						@addSection(new cola.breadcrumb.Section({text: section}))
					else if section.constructor == Object.prototype.constructor
						@addSection(new cola.breadcrumb.Section(section))
				return @

		currentIndex:
			setter: (value)->
				@["_currentIndex"] = value
				@setCurrent(value)

			getter: ()->
				if @_current and @_sections
					return @_sections.indexOf(@_current)
				else
					return -1

	@EVENTS:
		beforeChange: null
		change: null
	_initDom: (dom)->
		super(dom)

	_setDom: (dom, parseChild)->
		super(dom, parseChild)
		if @_sections?.length
			@_rendSection(section) for section in @_sections
		return

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

				@addSection(section) if section and section instanceof cola.breadcrumb.Section
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
		oldCurrent = @_current
		newCurrent = section

		return if oldCurrent is newCurrent

		arg =
			oldSection: oldCurrent
			newSection: newCurrent

		@fire("beforeChange", @, arg)

		if arg.processDefault is false
			newCurrent.set("active", false)
			return
		oldCurrent.set("active", false) if oldCurrent
		newCurrent.set("active", true)

		@fire("change", @, arg)
		return


	addSection: (section)->
		return @ if @_destroyed
		@_sections ?= []
		if section instanceof cola.breadcrumb.Section
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


cola.registerType("breadcrumb", "_default", cola.breadcrumb.Section)
cola.registerType("breadcrumb", "section", cola.breadcrumb.Section)
cola.registerTypeResolver "breadcrumb", (config) ->
	return cola.resolveType("widget", config)