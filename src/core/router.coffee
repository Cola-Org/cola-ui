routerRegistry = null
currentRoutePath = null
currentRouter = null

trimPath = (path) ->
	if path
		if path.charCodeAt(0) isnt 47 # `/`
			path = "/" + path
		if path.charCodeAt(path.length - 1) == 47 # `/`
			path = path.substring(0, path.length - 1)
	return path || ""

ignoreRouterSettingChange = false
cola.on("settingChange", (self, arg) ->
	return if ignoreRouterSettingChange

	if arg.key is "routerContextPath" or arg.key is "defaultRouterPath"
		path = cola.setting(arg.key)
		tPath = trimPath(path)
		if tPath isnt path
			ignoreRouterSettingChange = true
			cola.setting(arg.key, tPath)
			ignoreRouterSettingChange = false
	return
)

# router.path
# router.name
# router.redirectTo
# router.enter
# router.leave
# router.title
# router.jsUrl
# router.templateUrl
# router.target
# router.parentModel

cola.route = (path, router) ->
	routerRegistry ?= new cola.util.KeyedArray()

	if typeof router == "function"
		router =
			enter: router

	router.path = path = trimPath(path)

	path = path.slice(1)
	if not router.name
		name = path or cola.constants.DEFAULT_PATH
		parts = name.split(/[\/\-]/)
		nameParts = []
		for part, i in parts
			if not part or part.charCodeAt(0) == 58 # `:`
				continue
			nameParts.push(if nameParts.length > 0 then cola.util.capitalize(part) else part)
		router.name = nameParts.join("");

	router.pathParts = pathParts = []
	if path
		hasVariable = false
		for part in path.split("/")
			if part.charCodeAt(0) == 58 # `:`
				optional = part.charCodeAt(part.length - 1) == 63 # `?`
				if optional
					variable = part.substring(1, part.length - 1)
				else
					variable = part.substring(1)
				hasVariable = true
				pathParts.push({
					variable: variable
					optional: optional
				})
			else
				pathParts.push(part)
		router.hasVariable = hasVariable

	routerRegistry.add(router.path, router)
	return router

cola.getCurrentRoutePath = () ->
	return currentRoutePath

cola.getCurrentRouter = () ->
	return currentRouter

cola.setRoutePath = (path, replace, alwaysNotify) ->
	if path and path.charCodeAt(0) == 35 # `#`
		routerMode = "hash"
		path = path.substring(1)
	else
		routerMode = cola.setting("routerMode") or "hash"

	if routerMode is "hash"
		if path.charCodeAt(0) != 47 # `/`
			path = "/" + path
		window.location.hash = path if window.location.hash != path

		if alwaysNotify
			_onHashChange()
	else
		pathRoot = cola.setting("routerContextPath")
		if pathRoot and path.charCodeAt(0) is 47 # `/`
			realPath = cola.util.concatUrl(pathRoot, path)
		else
			realPath = path

		pathname = realPath
		i = pathname.indexOf("?")
		if i >= 0
			pathname = pathname.substring(0, i)
		i = pathname.indexOf("#")
		if i >= 0
			pathname = pathname.substring(0, i)

		if location.pathname isnt pathname
			if replace
				window.history.replaceState({
					path: realPath
				}, null, realPath)
			else
				window.history.pushState({
					path: realPath
				}, null, realPath)

			if location.pathname isnt pathname # 处理 ../ ./ 及 path前缀 等情况
				realPath = location.pathname + location.search + location.hash
				if pathRoot and realPath.indexOf(pathRoot) is 0
					path = realPath.substring(pathRoot.length)

				window.history.replaceState({
					path: realPath
					originPath: path
				}, null, realPath)

			_onStateChange(path)
		else if alwaysNotify
			_onStateChange(pathname)
	return

_findRouter = (path) ->
	return null unless routerRegistry

	path ?= cola.setting("defaultRouterPath")
	path = trimPath(path).slice(1)

	pathParts = if path then path.split(/[\/\?\#]/) else []
	for router in routerRegistry.elements
		defPathParts = router.pathParts
		gap = defPathParts.length - pathParts.length
		unless gap == 0 or gap == 1 and defPathParts.length > 0 and defPathParts[defPathParts.length - 1].optional then continue

		matching = true
		param = {}
		for defPart, i in defPathParts
			if typeof defPart == "string"
				if defPart != pathParts[i]
					matching = false
					break
			else
				if i >= pathParts.length and not defPart.optional
					matching = false
					break
				param[defPart.variable] = pathParts[i]

		if matching then break

	if matching
		router.param = param
		return router
	else
		return null

cola.createRouterModel = (router) ->
	if router.parentModel instanceof cola.Scope
		parentModel = router.parentModel
	else
		parentModelName = router.parentModel or cola.constants.DEFAULT_PATH
		parentModel = cola.model(parentModelName)
	if !parentModel then throw new cola.Exception("Parent Model \"#{parentModelName}\" is undefined.")
	return new cola.Model(router.name, parentModel)

_switchRouter = (router, path) ->
	if router.redirectTo
		cola.setRoutePath(router.redirectTo)
		return

	eventArg = {
		path: path
		prev: currentRouter
		next: router
	}
	if cola.fire("beforeRouterSwitch", cola, eventArg) is false then return

	if currentRouter
		currentRouter.leave?(currentRouter)
		if currentRouter.targetDom
			cola.unloadSubView(currentRouter.targetDom, {
				cssUrl: currentRouter.cssUrl
			})
			oldModel = cola.util.removeUserData(currentRouter.targetDom, "_model")
			oldModel?.destroy()

	if router.templateUrl
		if router.target
			if router.target.nodeType
				target = router.target
			else
				target = $(router.target)[0]
		if !target
			target = document.getElementsByClassName(cola.constants.VIEW_PORT_CLASS)[0]
			if !target
				target = document.getElementsByClassName(cola.constants.VIEW_CLASS)[0]
				if !target
					target = document.body
		router.targetDom = target
		$fly(target).empty()

	currentRouter = router

	if router.templateUrl
		model = cola.createRouterModel(router)
		eventArg.nextModel = model
		cola.util.userData(router.targetDom, "_model", model)
		cola.loadSubView(router.targetDom, {
			model: model
			htmlUrl: router.templateUrl
			jsUrl: router.jsUrl
			cssUrl: router.cssUrl
			data: router.data
			param: router.param
			callback: () ->
				router.enter?(router, model)
				document.title = router.title if router.title
				return
		})
	else
		router.enter?(router, null)
		document.title = router.title if router.title

	cola.fire("routerSwitch", cola, eventArg)
	return

_getHashPath = () ->
	path = location.hash
	path = path.substring(1) if path

	if path?.charCodeAt(0) == 33 # `!`
		path = path.substring(1)
	return trimPath(path)

_onHashChange = () ->
	return if (cola.setting("routerMode") or "hash") isnt "hash"

	path = _getHashPath()
	return if path is currentRoutePath
	currentRoutePath = path

	router = _findRouter(path)
	_switchRouter(router, path) if router
	return

_onStateChange = (path) ->
	return if cola.setting("routerMode") isnt "state"

	path = trimPath(path)
	i = path.indexOf("#")
	if i > -1
		path = path.substring(i + 1)

	if path.charCodeAt(0) is 47 # `/`
		routerContextPath = cola.setting("routerContextPath")
		if routerContextPath and path.indexOf(routerContextPath) is 0
			path = path.slice(routerContextPath.length)

	return if path is currentRoutePath
	currentRoutePath = path

	i = path.indexOf("?")
	if i > -1
		path = path.substring(0, i)

	router = _findRouter(path)
	_switchRouter(router, path) if router
	return

$ () ->
	setTimeout(() ->
		$fly(window).on("hashchange", _onHashChange).on("popstate", () ->
			if not location.hash
				state = window.history.state
				_onStateChange(state?.path or (location.pathname + location.search + location.hash))
			return
		)
		$(document.body).delegate("a.state", "click", () ->
			href = @getAttribute("href")
			if href
				target = @getAttribute("target")
				if not target or target is "_self"
					cola.setRoutePath(href)
					return false
		)

		path = _getHashPath()
		if path
			router = _findRouter(path)
			if router then _switchRouter(router, path)
		else
			path = cola.setting("defaultRouterPath")
			router = _findRouter(path)
			if router then cola.setRoutePath(path + location.search, true, true)
		return
	, 0)
	return