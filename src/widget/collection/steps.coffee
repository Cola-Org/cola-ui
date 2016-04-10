cola.steps ?= {}
class cola.steps.Step extends cola.Widget
	@CLASS_NAME: "step"
	@ATTRIBUTES:
		icon:
			refreshDom: true
		content:
			refreshDom: true
		states:
			refreshDom: true
			enum: ["completed", "active", ""]
			defaultValue: ""
			setter: (value)->
				oldValue = @_states
				@_states = value
				if @_dom and value isnt oldValue and oldValue
					$fly(@_dom).removeClass(oldValue)
				return @

		disabled:
			type: "boolean"
			defaultValue: false

	_parseDom: (dom)->
		@_doms ?= {}

		parseTitle = (node)=>
			@_doms.title = node
			title = cola.util.getTextChildData(node)
			content = @_content or {}
			if !content.title and title
				@_content ?= {}
				@_doms.titleDom = node
				@_content.title = title

			return

		parseDescription = (node)=>
			@_doms.description = node
			description = cola.util.getTextChildData(node)
			content = @_content or {}
			if description and not content.description
				@_content ?= {}
				@_doms.descriptionDom = node
				@_content.description = description

			return

		parseContent = (node)=>
			content = cola.util.getTextChildData(node)
			@_content = content if not @_content and content
			return

		child = dom.firstChild
		while child
			if child.nodeType == 1
				if child.nodeName is "I"
					@_doms.iconDom = child
					@_icon = child.className unless @_icon
				else
					$child = $(child)
					if $child.hasClass("content")
						@_doms.contentDom = child
						for cc in child.childNodes
							continue if child.nodeType isnt 1
							$cc = $(cc)
							parseTitle(cc) if $cc.hasClass("title")
							parseDescription(cc) if $cc.hasClass("description")

						parseContent(child) unless @_content

					else if $child.hasClass("title")
						parseTitle(child)
					else if $child.hasClass("description")
						parseDescription(child)

			child = child.nextSibling


		parseContent(dom)

		return

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_doms ?= {}
		content = @get("content")
		$dom = @get$Dom()
		$dom.empty()
		icon = @get("icon")

		if icon
			@_doms.iconDom ?= document.createElement("i")
			@_doms.iconDom.className = "#{icon} icon"
			$dom.append(@_doms.iconDom)
		else
			$fly(@_doms.iconDom).remove()

		if content
			@_doms.contentDom ?= document.createElement("div")
			$contentDom = $(@_doms.contentDom)
			$contentDom.addClass("content").empty()

			if typeof content is "string"
				$contentDom.text(content)
			else
				if content.title
					@_doms.titleDom ?= document.createElement("div")
					$fly(@_doms.titleDom).addClass("title").text(content.title)
					$contentDom.append(@_doms.titleDom)

				if content.description
					@_doms.descriptionDom ?= document.createElement("div")
					$fly(@_doms.descriptionDom).addClass("description").text(content.description)
					$contentDom.append(@_doms.descriptionDom)

			$dom.append($contentDom)

		classNamePool = @_classNamePool

		if @_states then classNamePool.add(@_states)
		classNamePool.toggle("disabled", @_disabled)

	destroy: ()->
		return if @_destroyed
		super()
		delete @_doms

class cola.Steps extends cola.Widget
	@CHILDREN_TYPE_NAMESPACE: "steps"
	@CLASS_NAME: "steps"
	@SEMANTIC_CLASS: ["tablet stackable", "left floated", "right floated"]
	@ATTRIBUTES:
		size:
			enum: ["mini", "tiny", "small", "medium", "large", "big", "huge", "massive"]
			refreshDom: true
			setter: (value)->
				oldValue = @["_size"]
				if oldValue and oldValue isnt value and @_dom
					@get$Dom().removeClass(oldValue)
				@["_size"] = value
				return

		steps:
			refreshDom: true
			setter: (value)->
				@clear()
				for step in value
					if step instanceof cola.steps.Step
						@addStep(step)
					else if  step.constructor == Object.prototype.constructor
						@addStep(new cola.steps.Step(step))
				return

		currentIndex:
			type: "number"
			setter: (value)->
				@["_currentIndex"] = value
				@setCurrent(value)
			getter: ()->
				if @_current and @_steps
					return @_steps.indexOf(@_current)
				else
					return -1
		autoComplete:
			type: "boolean"
			defaultValue: true

	@EVENTS:
		beforeChange: null
		change: null
		complete: null


	_doRefreshDom: ()->
		return unless @_dom
		super()
		size = @get("size")
		@_classNamePool.add(size) if size
	_doRemove: (step)->
		index = @_steps.indexOf(step)
		if index > -1
			@_steps.splice(index, 1)
			step.remove()
		return

	_setDom: (dom, parseChild)->
		super(dom, parseChild)

		return unless @_steps?.length

		for step in @_steps
			stepDom = step.getDom()
			step.appendTo(@_dom) if stepDom.parentNode isnt @_dom

		return

	_parseDom: (dom)->
		return unless dom

		@_steps ?= []

		child = dom.firstChild
		while child
			if child.nodeType == 1
				step = cola.widget(child)
				@addStep(step) if step and step instanceof cola.steps.Step
			child = child.nextSibling
		return

	_doChange: (index)->
		oldCurrent = @_current
		if index > -1 and index < @_steps.length
			newCurrent = @_steps[index]

		return if oldCurrent is newCurrent

		arg =
			oldCurrent: oldCurrent
			newCurrent: newCurrent

		if @fire("beforeChange", @, arg) is false
			newCurrent.set("states", "") if newCurrent
			return
		@_current = newCurrent;

		oldCurrent.set("states", "") if oldCurrent
		newCurrent.set("states", "active") if newCurrent
		if index >= @_steps.length
			@fire("complete", @, {})
		@fire("change", @, arg)

		@_doComplete(index)

		return

	getStep: (index)->
		return  @_steps?[index]

	setCurrent: (step)->
		currentIndex = step
		if typeof step is "string"
			for el,index in @_steps
				if step is el.get("content")
					currentIndex = index
					break
		else if step instanceof cola.steps.Step
			currentIndex = @_steps.indexOf(step)

		@_doChange(currentIndex)
		return @

	_doComplete: (index)->
		if @_autoComplete
			completeIndex = index - 1
			while completeIndex > -1
				@_steps[completeIndex].set("states", "completed")
				completeIndex--

			dIndex = index + 1
			while dIndex < @_steps.length
				@_steps[dIndex].set("states", "")
				dIndex++

	getCurrent: ()->
		return @_current

	add: ()->
		for arg in arguments
			step = arg
			if step instanceof cola.steps.Step
				@addStep(step)
			else if step.constructor == Object.prototype.constructor
				@addStep(new cola.steps.Step(step))
		return @

	addStep: (step)->
		return @ if @_destroyed
		@_steps ?= []
		if step.constructor == Object::constructor
			step = new cola.steps.Step(step)

		return @ unless step instanceof cola.steps.Step
		return @ if @_steps.indexOf(step) > -1
		@_steps.push(step)
		if @_dom
			stepDom = step.getDom()
			step.appendTo(@_dom) if stepDom.parentNode isnt @_dom

		states = step.get("states")
		@_doChange(@_steps.length-1) if states == "active"
		return @

	removeStep: (step)->
		return @ unless @_steps
		step = @_steps[step] if typeof step is "number"
		@_doRemove(step) if step
		return @

	clear: ()->
		return @ unless @_steps
		@get$Dom().empty() if @_dom
		@_steps = [] if @_steps.length
		return @

	next: ()->
		currentIndex = @get("currentIndex")
		@setCurrent(++currentIndex)
		return @
	complete: ()->
		@setCurrent(@_steps.length)
	previous: ()->
		currentIndex = @get("currentIndex")
		@setCurrent(--currentIndex)
		return @

	goTo: (index)->
		@setCurrent(index)
		return @
	getStepIndex: (step)->
		return @_steps?.indexOf(step)

cola.defineWidget("c-steps", cola.Steps)

cola.registerType("steps", "_default", cola.steps.Step)
cola.registerType("steps", "Step", cola.steps.Step)
cola.registerTypeResolver "steps", (config) ->
	return cola.resolveType("widget", config)