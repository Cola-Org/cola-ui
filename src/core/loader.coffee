cola.loadSubView = (targetDom, context) ->
	loadingUrls = []
	failed = false

	resourceLoadCallback = (success, result, url) ->
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
			error = result
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
				if cssUrl
					loadingUrls.push(cssUrl)
					cssUrls.push(cssUrl)
		else
			cssUrl = _compileResourceUrl(context.cssUrl, htmlUrl, ".css")
			if cssUrl
				loadingUrls.push(cssUrl)
				cssUrls.push(cssUrl)

	# load
	context.suspendedInitFuncs = []

	if htmlUrl
		_loadHtml(targetDom, htmlUrl, undefined, {
			complete: (success, result) ->
				resourceLoadCallback(success, result, htmlUrl)
		})

	if jsUrls
		for jsUrl in jsUrls
			_loadJs(context, jsUrl, {
				complete: (success, result) -> resourceLoadCallback(success, result, jsUrl)
			})

	if cssUrls
		for cssUrl in cssUrls
			_loadCss(cssUrl, {
				complete: (success, result) -> resourceLoadCallback(success, result, cssUrl)
			})
	return

cola.unloadSubView = (targetDom, context) ->
	$fly(targetDom).empty()

	htmlUrl = context.htmlUrl
	if context.cssUrl
		if context.cssUrl instanceof Array
			for cssUrl in context.cssUrl
				cssUrl = _compileResourceUrl(cssUrl, htmlUrl, ".css")
				if cssUrl then _unloadCss(cssUrl)
		else
			cssUrl = _compileResourceUrl(context.cssUrl, htmlUrl, ".css")
			if cssUrl then _unloadCss(cssUrl)
	return

_compileResourceUrl = (resUrl, htmlUrl, suffix) ->
	if resUrl == "$"
		defaultRes = true
	else if resUrl.indexOf("$.") == 0
		defaultRes = true
		suffix = resUrl.substring(2)

	if defaultRes
		resUrl = null
		if htmlUrl
			i = htmlUrl.lastIndexOf(".")
			resUrl = (if i > 0 then htmlUrl.substring(0, i) else htmlUrl) + suffix
	return resUrl

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

_loadCss = (url, callback) ->
	if not _cssCache[url]
		linkElement = $.xCreate(
			tagName: "link"
			rel: "stylesheet"
			type: "text/css"
			charset: cola.setting("defaultCharset")
			href: url
		)

		if not (cola.os.android and cola.os.version < 4.4)
			$(linkElement).one("load", () ->
				cola.callback(callback, true)
				return
			).on("readystatechange", (evt) ->
				if evt.target?.readyState is "complete"
					cola.callback(callback, true)
					$fly(this).off("readystatechange")
				return
			).one("error", () ->
				cola.callback(callback, false)
				return
			)

		head = document.querySelector("head") or document.documentElement
		head.appendChild(linkElement)
		_cssCache[url] = linkElement

		if cola.os.android and cola.os.version < 4.4
			cola.callback(callback, true)
	else
		cola.callback(callback, true)
	return

_unloadCss = (url) ->
	if _cssCache[url]
		$fly(_cssCache[url]).remove()
		delete _cssCache[url]
	return