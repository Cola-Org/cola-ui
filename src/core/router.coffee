routerRegistry = null
currentRoutePath = null
currentRouteName = null

trimPath = (path) ->
	if path
		if path.charCodeAt(0) == 47 # `/`
			path = path.substring(1)
		if path.charCodeAt(path.length - 1) == 47 # `/`
			path = path.substring(0, path.length - 1)
	return path or ""

# routerDef.path
# routerDef.redirectTo
# routerDef.enter
# routerDef.leave
# routerDef.title
# routerDef.jsUrl
# routerDef.templateUrl
# routerDef.target
# routerDef.model
# routerDef.parentModel

cola.router = (name, config) ->
	if config
		routerRegistry ?= new cola.util.KeyedArray()

		if typeof config == "function"
			routerDef = config
		else
			routerDef = {name: name}
			routerDef[p] = v for p, v of config

		routerDef.path ?= if name is cola.constants.DEFAULT_PATH then "" else name
		routerDef.model ?= name

		path = trimPath(routerDef.path)
		routerDef.pathParts = pathParts = []
		if path
			hasVariable = false
			for part in path.split(/[\/\?\#]/)
				if part.charCodeAt(0) == 58 # `:`
					hasVariable = true
					pathParts.push({
						variable: part.substring(1)
					})
				else
					pathParts.push(part)
			routerDef.hasVariable = hasVariable

		routerRegistry.add(name, routerDef)
		return @
	else
		return routerRegistry?.get(name)

cola.removeRouter = (name) ->
	routerRegistry?.remove(name)
	return

cola.getCurrentRoutePath = () ->
	return currentRouteName

cola.getCurrentRouter = () ->
	return cola.router(currentRouteName)

cola.setRoutePath = (path) ->
	if path and path.charCodeAt(0) == 35 # `#`
		routerMode = "hash"
		path = path.substring(1)

	if routerMode is "hash"
		if path.charCodeAt(0) != 47 # `/`
			path = "/" + path
		window.location.hash = path if window.location.hash != path
	else
		window.history.pushState({
			path: path
		}, null, path)
		_onStateChange(path)
	return

_findRouter = (path) ->
	return null unless routerRegistry

	path or= trimPath(cola.setting("defaultRouterPath"))

	pathParts = if path then path.split(/[\/\?\#]/) else []
	for routerDef in routerRegistry.elements
		if routerDef.pathParts.length != pathParts.length
			continue

		matching = true
		param = {}
		defPathParts = routerDef.pathParts
		for defPart, i in defPathParts
			if typeof defPart == "string"
				if defPart != pathParts[i]
					matching = false
					break
			else
				param[defPart.variable] = pathParts[i]
		if matching then break

	if matching
		routerDef.param = param
		return routerDef
	else
		return null

_switchRouter = (routerDef, path) ->
	if typeof routerDef == "function"
		routerDef()
		return

	if routerDef.redirectTo
		cola.setRoutePath(routerDef.redirectTo)
		return

	eventArg = {
		path: path
		prev: currentRouteName
		next: routerDef.name
	}
	cola.fire("beforeRouterSwitch", cola, eventArg)

	if currentRouteName
		currentRouterDef = cola.router(currentRouteName)
		currentRouteName = null
		if currentRouterDef
			oldModel = currentRouterDef.realModel
			currentRouterDef.leave?(currentRouterDef, oldModel)
			delete currentRouterDef.realModel
			if currentRouterDef.destroyModel then oldModel?.destroy()

	if routerDef.templateUrl
		if routerDef.target
			if routerDef.target.nodeType
				target = routerDef.target
			else
				target = $(routerDef.target)[0]
		if !target
			target = document.getElementsByClassName(cola.constants.VIEW_PORT_CLASS)[0]
			if !target
				target = document.getElementsByClassName(cola.constants.VIEW_CLASS)[0]
				if !target
					target = document.body
		routerDef.targetDom = target
		$fly(target).empty()

	currentRouteName = routerDef?.name

	if typeof routerDef.model == "string"
		model = cola.model(routerDef.model)
	else if routerDef.model instanceof cola.Model
		model = routerDef.model

	if !model
		parentModelName = routerDef.parentModel or cola.constants.DEFAULT_PATH
		parentModel = cola.model(parentModelName)
		if !parentModel then throw new cola.Exception("Parent Model \"#{parentModelName}\" is undefined.")
		model = new cola.Model(routerDef.model, parentModel)
		routerDef.destroyModel = true
	else
		routerDef.destroyModel = false

	routerDef.realModel = model

	if routerDef.templateUrl
		cola.loadSubView(routerDef.targetDom,
			{
				model: model
				htmlUrl: routerDef.templateUrl
				jsUrl: routerDef.jsUrl
				cssUrl: routerDef.cssUrl
				data: routerDef.data
				param: routerDef.param
				callback: () ->
					routerDef.enter?(routerDef, model)
					document.title = routerDef.title if routerDef.title
					return
			})
	else
		routerDef.enter?(routerDef, model)
		document.title = routerDef.title if routerDef.title

	cola.fire("routerSwitch", cola, eventArg)
	return

_getHashPath = () ->
	path = location.hash
	path = path.substring(1) if path

	if path?.charCodeAt(0) == 33 # `!`
		path = path.substring(1)
	path = trimPath(path)
	return path or ""

_onHashChange = () ->
	path = _getHashPath()
	return if path == currentRoutePath
	currentRoutePath = path

	routerDef = _findRouter(path)
	_switchRouter(routerDef, path) if routerDef
	return

_onStateChange = (path) ->
	path = trimPath(path)

	i = path.indexOf("#")
	if i > -1
		path = path.substring(i + 1)
	else
		i = path.indexOf("?")
		if i > -1
			path = path.substring(0, i)

	return if path == currentRoutePath
	currentRoutePath = path

	routerDef = _findRouter(path)
	_switchRouter(routerDef, path) if routerDef
	return

$ () ->
	setTimeout(() ->
		$fly(window).on("hashchange", _onHashChange).on("popstate", () ->
			if not location.hash
				state = window.history.state
				_onStateChange(state?.path or "")
			return
		)
		$(document.body).delegate("a.state", "click", () ->
			href = @getAttribute("href")
			cola.setRoutePath(href) if href
			return false
		)

		path = _getHashPath() or trimPath(cola.setting("defaultRouterPath"))
		routerDef = _findRouter(path)
		if routerDef
			currentRoutePath = path
			_switchRouter(routerDef, path)
		return
	, 0)
	return