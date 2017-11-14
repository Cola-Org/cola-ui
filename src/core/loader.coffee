cola._jsCache = {}

cola.loadSubView = (targetDom, context) ->
	loadingUrls = []
	failed = false

	resourceLoadCallback = (success, result, url) ->
		if success
			if not failed
				i = loadingUrls.indexOf(url)
				if i > -1 then loadingUrls.splice(i, 1)
				if loadingUrls.length is 0
					$fly(targetDom).removeClass("loading")

					if targetDom.hasAttribute(cola.constants.IGNORE_DIRECTIVE)
						hasIgnoreDirective = true
						targetDom.removeAttribute(cola.constants.IGNORE_DIRECTIVE)

					for scriptHolder in context.scriptHolders
						scriptElement = $.xCreate(
							tagName: "script"
							language: "javascript"
							type: "text/javascript"
							charset: cola.setting("defaultCharset")
						)
						scriptElement.text = scriptHolder.script
						cola._suspendedInitFuncs = context.suspendedInitFuncs
						try
							if not context.suspendedInitFuncs
								oldLen = 0
							else
								oldLen = context.suspendedInitFuncs.length

							try
								head = document.querySelector("head") or document.documentElement
								head.appendChild(scriptElement)
							finally
								delete cola._suspendedInitFuncs

								if context.suspendedInitFuncs?.length > oldLen
									cola._jsCache[scriptHolder.url] = context.suspendedInitFuncs.slice(oldLen)
						catch e
							# do nothing

					if context.suspendedInitFuncs.length
						model = context.model
						for initFunc in context.suspendedInitFuncs
							initFunc(targetDom, context.model, context.param)
					else
						cola(targetDom, context.model)
					cola._renderDomTemplate(targetDom, model)

					if hasIgnoreDirective
						targetDom.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")

					if cola.getListeners("ready")
						cola.fire("ready", cola)
						cola.off("ready")

					cola.callback(context.callback, true)
		else if not failed
			failed = true
			error = result
			if cola.callback(context.callback, false, error) != false
				if error.xhr
					errorMessage = error.status + " " + error.message
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
		if typeof context.jsUrl is "string"
			originJsUrls = context.jsUrl.split("|")
		else
			originJsUrls = context.jsUrl

		for jsUrl in originJsUrls
			jsUrl = _compileResourceUrl(jsUrl, htmlUrl, ".js")
			if jsUrl
				loadingUrls.push(jsUrl)
				jsUrls.push(jsUrl)

	if context.cssUrl
		cssUrls = []
		if typeof context.cssUrl is "string"
			originCssUrls = context.cssUrl.split("|")
		else
			originCssUrls = context.cssUrl

		for cssUrl in originCssUrls
			cssUrl = _compileResourceUrl(cssUrl, htmlUrl, ".css")
			if cssUrl
				loadingUrls.push(cssUrl)
				cssUrls.push(cssUrl)

	# load
	context.scriptHolders = []
	context.suspendedInitFuncs = []

	index = 0;
	if htmlUrl
		_loadHtml(targetDom, htmlUrl, context, {
			complete: (success, result) ->
				resourceLoadCallback(success, result, htmlUrl)
		}, index++)

	jsUrls?.forEach (jsUrl) ->
		_loadJs(context, jsUrl, {
			complete: (success, result) -> resourceLoadCallback(success, result, jsUrl)
		}, index++)

	cssUrls?.forEach (cssUrl) ->
		_loadCss(context, cssUrl, {
			complete: (success, result) -> resourceLoadCallback(success, result, cssUrl)
		}, index++)
	return

cola.unloadSubView = (targetDom, context) ->
	$fly(targetDom).empty()

	htmlUrl = context.htmlUrl
	if context.cssUrl
		cssUrls = []
		if typeof context.cssUrl is "string"
			cssUrls = context.cssUrl.split("|")
		else
			cssUrls = context.cssUrl

		for cssUrl in cssUrls
			cssUrl = _compileResourceUrl(cssUrl, htmlUrl, ".css")
			if cssUrl then _unloadCss(cssUrl)
	return

_compileResourceUrl = (resUrl, htmlUrl, suffix) ->
	if resUrl is "$"
		defaultRes = true
	else if resUrl.indexOf("$.") == 0
		defaultRes = true
		suffix = resUrl.substring(1)

	if defaultRes
		resUrl = null
		if htmlUrl
			i = htmlUrl.indexOf("?")
			if i > 0 then htmlUrl = htmlUrl.substring(0, i)

			i = htmlUrl.lastIndexOf(".")
			resUrl = (if i > 0 then htmlUrl.substring(0, i) else htmlUrl) + suffix
	return resUrl

_loadHtml = (targetDom, url, context, callback) ->
	$.ajax(url, {
		timeout: context.timeout
	}).done((html) ->
		$(targetDom).html(html)
		cola.callback(callback, true)
		return
	).fail((xhr, status, message) ->
		cola.callback(callback, false, {
			xhr: xhr
			status: status
			message: message
		})
		return
	)
	return

_loadJs = (context, url, callback, index) ->
	initFuncs = cola._jsCache[url]
	if initFuncs
		Array.prototype.push.apply(context.suspendedInitFuncs, initFuncs)
		cola.callback(callback, true)
	else
		context.scriptHolders.push({
			url: url
		})
		$.ajax(url, {
			dataType: "text"
			cache: true
			async: false	# TODO DELETE ME
			timeout: context.timeout
		}).done((script) ->
			for scriptHolder in context.scriptHolders
				if scriptHolder.url is url
					scriptHolder.script = script
					break
			cola.callback(callback, true)
			return
		).fail((xhr, status, message) ->
			cola.callback(callback, false, {
				xhr: xhr
				status: status
				message: message
			})
			return
		)
	return

_cssCache = {}

_loadCss = (context, url, callback, index) ->
	linkElement = _cssCache[url]
	if not linkElement
		linkElement = $.xCreate(
			tagName: "link"
			rel: "stylesheet"
			type: "text/css"
			charset: cola.setting("defaultCharset")
			href: url
		)

		if context.timeout
			timeoutTimerId = setTimeout(() ->
				$fly(linkElement).remove()
				cola.callback(callback, false, {
					status: "timeout"
				})
				return
			, context.timeout)

		$(linkElement).one("load", () ->
			clearTimeout(timeoutTimerId) if timeoutTimerId
			cola.callback(callback, true)
			return
		).on("readystatechange", (evt) ->
			if evt.target?.readyState is "complete"
				clearTimeout(timeoutTimerId) if timeoutTimerId
				$fly(this).off("readystatechange")
				cola.callback(callback, true)
			return
		).one("error", (evt) ->
			clearTimeout(timeoutTimerId) if timeoutTimerId
			cola.callback(callback, false, evt)
			return
		)

		head = document.querySelector("head") or document.documentElement
		linkElement.setAttribute("_refNum", "1");
		head.appendChild(linkElement)
		_cssCache[url] = linkElement
		return true
	else
		refNum = +linkElement.getAttribute("_refNum") or 1
		linkElement.setAttribute("_refNum", (refNum + 1) + "")
		cola.callback(callback, true)
		return false

_unloadCss = (url) ->
	linkElement = _cssCache[url]
	if linkElement
		refNum = +linkElement.getAttribute("_refNum") or 1
		if refNum > 1
			linkElement.setAttribute("_refNum", (refNum - 1) + "")
		else
			delete _cssCache[url]
			$fly(linkElement).remove()
	return