cola._jsCache = {}

cola.loadSubView = (targetDom, context) ->
	$fly(targetDom).addClass("loading")

	# collect urls
	htmlUrl = context.htmlUrl

	if context.jsUrl
		jsUrls = []
		if typeof context.jsUrl is "string"
			originJsUrls = context.jsUrl.split("|")
		else
			originJsUrls = context.jsUrl

		for jsUrl in originJsUrls
			jsUrl = _compileResourceUrl(jsUrl, htmlUrl, ".js")
			if jsUrl
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
				cssUrls.push(cssUrl)

	# load
	context.suspendedInitFuncs = []

	deferreds = []
	if htmlUrl
		deferreds.push(_loadHtml(targetDom, context, htmlUrl))

	jsDeferreds = []
	if jsUrls?.length
		jsUrls.forEach (jsUrl) ->
			jsDeferreds.push(_loadJs(context, jsUrl))

		deferreds.push($.when.apply($, jsDeferreds).done(()->
			for args, i in arguments
				result = args[0]
				continue unless result
				if typeof result is "string"
					script = result
					scriptElement = $.xCreate(
						tagName: "script"
						language: "javascript"
						type: "text/javascript"
						charset: cola.setting("defaultCharset")
					)
					scriptElement.text = script
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
								cola._jsCache[jsUrls[i]] = context.suspendedInitFuncs.slice(oldLen)
					catch e
					# do nothing
				else
					initFuncs = result
					Array.prototype.push.apply(context.suspendedInitFuncs, initFuncs)
			return
		))

	cssUrls?.forEach (cssUrl) ->
		deferreds.push(_loadCss(context, cssUrl))

	$.when.apply($, deferreds).done(()->
		$fly(targetDom).removeClass("loading")

		if targetDom.hasAttribute(cola.constants.IGNORE_DIRECTIVE)
			hasIgnoreDirective = true
			targetDom.removeAttribute(cola.constants.IGNORE_DIRECTIVE)

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
		return
	).fail(()->
		error = arguments[0]
		if cola.callback(context.callback, false, error) isnt false
			if error._url
				errorMessage = error.statusText
				throw new cola.Exception("Failed to load resource from [#{error._url}]. " + errorMessage)
			else
				throw new cola.Exception(error)
		return
	)
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

_loadHtml = (targetDom, context, url) ->
	return $.ajax(url, {
		cache: true
		timeout: context.timeout
	}).done((html)->
		$(targetDom).html(html)
		return
	).fail((xhr)->
		xhr._url = url
		return
	)

_loadJs = (context, url) ->
	initFuncs = cola._jsCache[url]
	if initFuncs
		return $.Deferred((dfd)->
			dfd.resolve([initFuncs])
			return
		)
	else
		return $.ajax(url, {
			dataType: "text"
			cache: true
			timeout: context.timeout
		}).fail((xhr)->
			xhr._url = url
			return
		)

_cssCache = {}

_loadCss = (context, url) ->
	return $.Deferred (dfd) ->
		linkElement = _cssCache[url]
		if linkElement
			refNum = +linkElement.getAttribute("_refNum") or 1
			linkElement.setAttribute("_refNum", (refNum + 1) + "")
			dfd.resolve(linkElement)
		else
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
				dfd.resolve(linkElement)
				return
			).on("readystatechange", (evt) ->
				if evt.target?.readyState is "complete"
					clearTimeout(timeoutTimerId) if timeoutTimerId
					$fly(@).off("readystatechange")
					dfd.resolve(linkElement)
				return
			).one("error", (evt) ->
				clearTimeout(timeoutTimerId) if timeoutTimerId
				# 如果css装载失败不阻止SubView的继续渲染
				dfd.resolve(linkElement)
				return
			)

			head = document.querySelector("head") or document.documentElement
			linkElement.setAttribute("_refNum", "1");
			head.appendChild(linkElement)
			_cssCache[url] = linkElement
		return

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