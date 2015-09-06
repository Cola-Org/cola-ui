cola.loadSubView = (targetDom, context) ->
	loadingUrls = []
	failed = false

	resourceLoadCallback = (success, context, url) ->
		if success
			if not failed
				i = loadingUrls.indexOf(url)
				if i > -1 then loadingUrls.splice(i, 1)
				if loadingUrls.length == 0
					$fly(targetDom).removeClass("loading")
					if context.suspendedInitFuncs.length
						for initFunc in context.suspendedInitFuncs
							initFunc(targetDom, context.model, context.param)
					else
						cola(targetDom, context.model)

					if cola.getListeners("ready")
						cola.fire("ready", cola)
						cola.off("ready")

					cola.callback(context.callback, true)
		else
			failed = true
			error = context
			if cola.callback(context.callback, false, error) != false
				if error.xhr
					errorMessage = error.status + " " + error.statusText
				else
					errorMessage = error.message
				throw new cola.Exception("Failed to load resource from [#{url}]. " + errorMessage)
		return

	$fly(targetDom).addClass("loading")

	# collect urls
	htmlUrl = context.htmlUrl
	if htmlUrl
		loadingUrls.push(htmlUrl)

	if context.jsUrl
		jsUrls = []
		if context.jsUrl instanceof Array
			for jsUrl in context.jsUrl
				jsUrl = _compileResourceUrl(jsUrl, htmlUrl, ".js")
				if jsUrl
					loadingUrls.push(jsUrl)
					jsUrls.push(jsUrl)
		else
			jsUrl = _compileResourceUrl(context.jsUrl, htmlUrl, ".js")
			if jsUrl
				loadingUrls.push(jsUrl)
				jsUrls.push(jsUrl)

	if context.cssUrl
		cssUrls = []
		if context.cssUrl instanceof Array
			for cssUrl in context.cssUrl
				cssUrl = _compileResourceUrl(cssUrl, htmlUrl, ".css")
				if cssUrl then cssUrls.push(cssUrl)
		else
			cssUrl = _compileResourceUrl(context.cssUrl, htmlUrl, ".css")
			if cssUrl then cssUrls.push(cssUrl)

	# load
	context.suspendedInitFuncs = []

	if htmlUrl
		_loadHtml(targetDom, htmlUrl, undefined, {
			complete: (success, result) -> resourceLoadCallback(success, (if success then context else result), htmlUrl)
		})

	if jsUrls
		for jsUrl in jsUrls
			_loadJs(context, jsUrl, {
				complete: (success, result) -> resourceLoadCallback(success, (if success then context else result),
					jsUrl)
			})

	if cssUrls
		_loadCss(cssUrl) for cssUrl in cssUrls
	return

_compileResourceUrl = (jsUrl, htmlUrl, suffix) ->
	if jsUrl == "$"
		jsUrl = null
		if htmlUrl
			i = htmlUrl.lastIndexOf(".")
			jsUrl = (if i > 0 then htmlUrl.substring(0, i) else htmlUrl) + suffix
	return jsUrl

_loadHtml = (targetDom, url, data, callback) ->
	$(targetDom).load(url, data,
		(response, status, xhr) ->
			if status == "error"
				cola.callback(callback, false, {
					xhr: xhr
					status: xhr.status
					statusText: xhr.statusText
				})
			else
				cola.callback(callback, true)
			return
	)
	return

_jsCache = {}

_loadJs = (context, url, callback) ->
	initFuncs = _jsCache[url]
	if initFuncs
		Array.prototype.push.apply(context.suspendedInitFuncs, initFuncs)
		cola.callback(callback, true)
	else
		$.ajax(url, {
			dataType: "text"
			cache: true
		}).done((script) ->
			scriptElement = $.xCreate(
				tagName: "script"
				language: "javascript"
				type: "text/javascript"
				charset: cola.setting("defaultCharset")
			)
			scriptElement.text = script
			cola._suspendedInitFuncs = context.suspendedInitFuncs
			try
				try
					head = document.querySelector("head") or document.documentElement
					head.appendChild(scriptElement)
				finally
					delete cola._suspendedInitFuncs
					_jsCache[url] = context.suspendedInitFuncs
				cola.callback(callback, true)
			catch e
				cola.callback(callback, false, e)
			return
		).fail((xhr) ->
			cola.callback(callback, false, {
				xhr: xhr
				status: xhr.status
				statusText: xhr.statusText
			})
			return
		)
	return

_cssCache = {}

_loadCss = (url) ->
	if not _cssCache[url]
		linkElement = $.xCreate(
			tagName: "link"
			rel: "stylesheet"
			type: "text/css"
			charset: cola.setting("defaultCharset")
			href: url
		)
		head = document.querySelector("head") or document.documentElement
		head.appendChild(linkElement)
		_cssCache[url] = true
	return