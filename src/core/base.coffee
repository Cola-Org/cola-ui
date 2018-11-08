cola.version = "${version}"

uniqueIdSeed = 1

cola.uniqueId = ()->
	return "_id" + (uniqueIdSeed++)

cola.sequenceNo = ()->
	return uniqueIdSeed++

cola._EMPTY_FUNC = ()->

if window?
	do()->
		cola.browser = {}
		cola.os = {}
		cola.device = {}

		ua = window.navigator.userAgent.toLowerCase()

		if (s = ua.match(/webkit\/([\d.]+)/))
			cola.browser.webkit = s[1] or -1
			if (s = ua.match(/chrome\/([\d.]+)/)) then cola.browser.chrome = +s[1] or -1
			else if (s = ua.match(/version\/([\d.]+).*safari/)) then cola.browser.safari = +s[1] or -1
		else if (s = ua.match(/msie ([\d.]+)/)) then cola.browser.ie = +s[1] or -1
		else if (s = ua.match(/trident/)) then cola.browser.ie = 11
		else if (s = ua.match(/firefox\/([\d.]+)/)) then cola.browser.mozilla = +s[1] or -1
		else if (s = ua.match(/opera.([\d.]+)/)) then cola.browser.opera = +s[1] or -1

		if (s = ua.match(/(iphone|ipad).*os\s([\d_]+)/))
			cola.os.ios = +s[2] or -1
			cola.device.pad = s[1] == "ipad"
			cola.device.phone = !cola.device.pad
		else
			if (s = ua.match(/(android)\s+([\d.]+)/))
				cola.os.android = +s[1] or -1
			else if (s = ua.match(/(windows)[\D]*([\d]+)/)) then cola.os.windows = +s[1] or -1

		if (s = ua.match(/micromessenger\/([\d.]+)/)) then cola.browser.weixin = +s[1] or -1

		cola.device.mobile = !!(`("ontouchstart" in window)` and ua.match(/(mobile)/))
		cola.device.desktop = not cola.device.mobile

		if cola.device.mobile and not cola.os.ios
			theshold = 768
			if cola.browser.qqbrowser
				cola.device.pad = (window.screen.width / 2) >= theshold or (window.screen.height / 2) >= theshold
			else
				cola.device.pad = window.screen.width >= theshold or window.screen.height >= theshold
			cola.device.phone = not cola.device.pad

		if window.outerWidth - window.innerWidth > 40 or window.outerHeight - window.innerHeight > 100
			cola.consoleOpened = true
		return

###
Event
###

colaEventRegistry =
	beforeInit: {}
	ready: {}
	settingChange: {}
	exception: {}
	beforeRouterSwitch: {}
	routerSwitch: {}

cola.on = (eventName, listener)->
	i = eventName.indexOf(":")
	if i > 0
		alias = eventName.substring(i + 1)
		eventName = eventName.substring(0, i)

	listenerRegistry = colaEventRegistry[eventName]
	if !listenerRegistry
		throw new cola.Exception(cola.resource("cola.error.unrecognizedEvent", eventName))

	if typeof listener isnt "function"
		throw new cola.Exception("Invalid event listener.")

	listeners = listenerRegistry.listeners
	aliasMap = listenerRegistry.aliasMap
	if listeners
		if alias and aliasMap?[alias] > -1 then cola.off(eventName + ":" + alias)
		listeners.push(listener)
		i = listeners.length - 1
	else
		listenerRegistry.listeners = listeners = [ listener ]
		i = 0

	if alias
		if not aliasMap
			listenerRegistry.aliasMap = aliasMap = {}
		aliasMap[alias] = i
	return @

cola.off = (eventName, listener)->
	i = eventName.indexOf(":")
	if i > 0
		alias = eventName.substring(i + 1)
		eventName = eventName.substring(0, i)

	listenerRegistry = colaEventRegistry[eventName]
	if not listenerRegistry then return @

	listeners = listenerRegistry.listeners
	if not listeners or listeners.length is 0 then return @

	i = -1
	if alias
		aliasMap = listenerRegistry.aliasMap
		i = aliasMap?[alias]

		if i > -1
			delete aliasMap?[alias]
			listeners.splice(i, 1)
	else if listener
		i = listeners.indexOf(listener)
		if i > -1
			listeners.splice(i, 1)

			aliasMap = listenerRegistry.aliasMap
			if aliasMap
				for alias of aliasMap
					if aliasMap[alias] == listener
						delete aliasMap[alias]
						break
	else
		delete listenerRegistry.listeners
		delete listenerRegistry.aliasMap
	return @

cola.getListeners = (eventName)->
	listener = colaEventRegistry[eventName]?.listeners
	return if listener?.length then listener else null

cola.fire = (eventName, self, arg = {})->
	listeners = colaEventRegistry[eventName]?.listeners
	if listeners
		for listener in listeners
			argsMode = listener._argsMode
			if not listener._argsMode
				argsMode = cola.util.parseListener(listener)
			if argsMode == 1
				retValue = listener.call(@, self, arg)
			else
				retValue = listener.call(@, arg, self)
			if retValue == false then return false
	return true

cola.ready = (listener)->
	return @on("ready", listener)

###
Setting
###

setting = {
	defaultCharset: "utf-8"
	defaultNumberFormat: "#,##0.##"
	defaultDateFormat: "yyyy-MM-dd"
	defaultDateInputFormat: "yyyy-MM-dd"
	defaultTimeFormat: "HH:mm:ss"
	defaultTimeInputFormat: "HH:m:mss"
	defaultDateTimeFormat: "yyyy-MM-dd HH:mm:ss"
	defaultDateTimeInputFormat: "yyyy-MM-dd HH:mm:ss"
	defaultSubmitDateFormat: "yyyy-MM-dd'T'HH:mm:ss.fffzzz"
}

cola.setting = (key, value)->
	if typeof key == "string"
		if value != undefined
			# setting(string, any)
			setting[key] = value
			if cola.getListeners("settingChange")
				cola.fire("settingChange", cola, { key: key })
		else
			# setting(string)
			return setting[key]
	else if typeof key == "object"
		# setting(object)
		for k, v of key
			setting[k] = v
			if cola.getListeners("settingChange")
				cola.fire("settingChange", cola, { key: k })
	return @

do()->
	definedSetting = colaSetting? or global?.colaSetting
	if definedSetting
		cola.setting(key, value) for key, value of definedSetting

###
Exception
###

exceptionStack = []

class cola.Exception
	constructor: (@message, @error)->
		if @error then console?.error?(@error)

		exceptionStack.push(@)
		setTimeout(()=>
			if exceptionStack.indexOf(@) > -1
				cola.Exception.processException(@)
			return
		, 50)

	@processException = (ex)->
		if cola.Exception.ignoreAll then return

		if ex then cola.Exception.removeException(ex)
		if ex instanceof cola.AbortException then return

		if cola.fire("exception", cola, { exception: ex }) is false then return

		if ex instanceof cola.RunnableException
			eval("var fn = function(){#{ex.script}}")
			scope = if window? then window else @
			fn.call(scope)
		else
			if cola.Exception.ignoreAll then return
			try
				if document?.body
					if ex.showException
						ex.showException()
					else
						cola.Exception.showException(ex)
				else
					if ex.safeShowException
						ex.safeShowException()
					else
						cola.Exception.safeShowException(ex)
			catch ex2
				cola.Exception.removeException(ex2)
				if ex2.safeShowException
					ex2.safeShowException()
				else
					cola.Exception.safeShowException(ex2)
		return

	@removeException = (ex)->
		i = exceptionStack.indexOf(ex)
		if i > -1 then exceptionStack.splice(i, 1)
		return

	@safeShowException: (ex)->
		if ex instanceof cola.Exception or ex instanceof Error
			msg = ex.message
		else
			msg = ex + ""
			alert?(msg)
		return

	@showException: (ex)-> @safeShowException(ex)

class cola.AbortException extends cola.Exception
	constructor: ()->

class cola.RunnableException extends cola.Exception
	constructor: (@script)->
		super("[script]")

###
I18N
###

resourceStore = {}

sprintf = (templ, params...)->
	for param, i in params
		templ = templ.replace(new RegExp("\\{#{i}\\}", "g"), param)
	return templ

cola.resource = (key, params...)->
	if typeof key == "string"
		# resource(key, params...)
		# read resource resource
		templ = resourceStore[key]
		if templ?
			if params.length
				return sprintf.apply(@, [ templ ].concat(params))
			else
				return templ
		else
			return params?[0] or key
	else
		# resource(bundle)
		# load resource resources from bundle(json format)
		bundle = key
		resourceStore[key] = str for key, str of bundle
		return

class cola.ResourceException extends cola.Exception
	constructor: (key, params...)->
		super(cola.resource(key, params...))

###
Methods
###

cola.callback = (callback, success, result)->
	return unless callback
	if success is undefined
		success = true

	if typeof callback == "function"
		if success
			return callback.call(@, result)
	else
		scope = callback.scope or @
		if callback.delay
			setTimeout(()->
				callback.complete.call(scope, success, result)
				return
			, callback.delay)
			return
		else
			return callback.complete.call(scope, success, result)

###
Lang
###
Date.prototype.toJSON = ()->
	cola.util.formatDate(@, cola.setting("defaultSubmitDateFormat"))


