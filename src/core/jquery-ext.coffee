cola.ready ()->
	$fly(window).resize ()->
		cola.util.delay(domObserver, "windowResize", 300, ()->
			if domObserver.sizingObserverCount
				domObserver.mutationHandler([])
			return
		)
		return
	return

domObserver =
	VISIBILITY: 1
	SIZING: 2

	observingDomCount: 0
	doms: {}

	visibilityObserverCount: 0
	sizingObserverCount: 0

	mutationHandler: (records)->
		shouldCheckVisible = false
		for record in records
			if record.type is "attributes" and (record.attributeName is "style" or record.attributeName is "class")
				shouldCheckVisible = true
				break

		if not shouldCheckVisible and domObserver.sizingObserverCount is 0
			return

		for id, holder of domObserver.doms
			dom = holder.dom
			originWidth = dom._originWidth
			originHeight = dom._originHeight
			dom._originHeight = width = dom.offsetWidth
			dom._originHeight = height = dom.offsetHeight
			visible = !!(width or height)

			if holder.scopes & domObserver.VISIBILITY
				if visible isnt !!(originWidth or originHeight)
					$fly(dom).trigger("visibilityChange", {
						visible: visible
					})

			if visible and holder.scopes & domObserver.SIZING
				if width isnt originWidth or height isnt originHeight
					$fly(dom).trigger("sizingChange", {
						originWidth: originWidth
						originHeight: originHeight
						width: width
						height: height
					})
		return

	observe: (dom, type)->
		id = dom.getAttribute(cola.constants.DOM_USER_DATA_KEY)
		if not id
			id = cola.uniqueId()
			dom.setAttribute(cola.constants.DOM_USER_DATA_KEY, id)

		holder = domObserver.doms[id]
		if not holder
			domObserver.doms[id] = holder =
				dom: dom
				scopes: type
			domObserver.observingDomCount++

			dom._originWidth = dom.offsetWidth
			dom._originHeight = dom.offsetHeight
		else
			if not (holder.scopes & type)
				holder.scopes += type

		if type is domObserver.VISIBILITY
			domObserver.visibilityObserverCount++
		else if type is domObserver.SIZING
			domObserver.sizingObserverCount++

		if domObserver.observingDomCount is 1 and not domObserver.mutationObserver
			domObserver.mutationObserver = new MutationObserver(domObserver.mutationHandler)
			domObserver.mutationObserver.observe(document.body, {
				subtree: true
				attributes: true
				childList: true
				characterData: true
			})
		return

	unobserve: (dom, type)->
		id = dom.getAttribute(cola.constants.DOM_USER_DATA_KEY)
		holder = domObserver.doms[id]
		if not holder and holder.scopes & type
			holder.scopes -= type

			if type is domObserver.VISIBILITY
				@visibilityObserverCount--
			else if type is domObserver.SIZING
				@sizingObserverCount--

			if holder.scopes is 0
				delete domObserver.doms[id]

				domObserver.observingDomCount--
				if domObserver.observingDomCount is 0 and domObserver.mutationObserver
					domObserver.mutationObserver.disconnect()
					delete domObserver.mutationObserver
		return

jQuery.event.special.visibilityChange =
	setup: (data, namespaces, eventHandler)->
		return unless @nodeType is 1
		domObserver.observe(@, domObserver.VISIBILITY)
		return

	teardown: (namespaces)->
		return unless @nodeType is 1
		domObserver.unobserve(@, domObserver.VISIBILITY)
		return

jQuery.event.special.sizingChange =
	setup: (data, namespaces, eventHandler)->
		return unless @nodeType is 1
		domObserver.observe(@, domObserver.SIZING)
		return

	teardown: (namespaces)->
		return unless @nodeType is 1
		domObserver.unobserve(@, domObserver.SIZING)
		return