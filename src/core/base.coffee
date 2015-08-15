#IMPORT_BEGIN
if exports?
	cola = require("./util")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.version = "${version}"

uniqueIdSeed = 1

cola.uniqueId = () ->
	return "_id" + (uniqueIdSeed++)

cola.sequenceNo = () ->
	return uniqueIdSeed++

cola._EMPTY_FUNC = () ->

if window?
	(() ->
		cola.browser = {}
		cola.os = {}
		cola.device = {}

		ua = window.navigator.userAgent.toLowerCase()

		if (s = ua.match(/webkit\/([\d.]+)/))
			cola.browser.webkit = s[1] or -1
			if (s = ua.match(/chrome\/([\d.]+)/)) then cola.browser.chrome = parseFloat(s[1]) or -1
			else if (s = ua.match(/version\/([\d.]+).*safari/)) then cola.browser.safari = parseFloat(s[1]) or -1
		else if (s = ua.match(/msie ([\d.]+)/)) then cola.browser.ie = parseFloat(s[1]) or -1
		else if (s = ua.match(/trident/)) then cola.browser.ie = 11
		else if (s = ua.match(/firefox\/([\d.]+)/)) then cola.browser.mozilla = parseFloat(s[1]) or -1
		else if (s = ua.match(/opera.([\d.]+)/)) then cola.browser.opera = parseFloat(s[1]) or -1
		else if (s = ua.match(/qqbrowser\/([\d.]+)/)) then cola.browser.qqbrowser = parseFloat(s[1]) or -1

		if (s = ua.match(/(iphone|ipad).*os\s([\d_]+)/))
			cola.os.ios = parseFloat(s[2]) or -1
			cola.device.pad = s[1] == "ipad"
			cola.device.phone = !cola.device.pad
		else
			if (s = ua.match(/(android)\s+([\d.]+)/))
				cola.os.android = parseFloat(s[1]) or -1
				if(s = ua.match(/micromessenger\/([\d.]+)/)) then cola.browser.weixin = parseFloat(s[1]) or -1
			else if (s = ua.match(/(windows)[\D]*([\d]+)/)) then cola.os.windows = parseFloat(s[1]) or -1

		cola.device.mobile = !!(`("ontouchstart" in window)` and ua.match(/(mobile)/))
		cola.device.desktop = !cola.device.mobile

		if cola.device.mobile and !cola.os.ios
			theshold = 768
			if cola.browser.qqbrowser
				cola.device.pad = document.body.clientWidth >= theshold or document.body.clientHeight >= theshold
			else
				cola.device.pad = window.screen.width >= theshold or window.screen.height >= theshold
			cola.device.phone = !cola.device.pad
		return)()

###
Event
###

colaEventRegistry =
	ready: {}
	settingChange: {}
	exception: {}
	beforeAjaxRequest: {}
	ajaxSuccess: {}
	ajaxError: {}
	beforeRouterSwitch: {}
	routerSwitch: {}

cola.on = (eventName, listener) ->
	i = eventName.indexOf(":")
	if i > 0
		alias = eventName.substring(i + 1)
		eventName = eventName.substring(0, i)

	listenerRegistry = colaEventRegistry[eventName]
	if !listenerRegistry
		throw new cola.I18nException("cola.error.unrecognizedEvent", eventName)

	if typeof listener != "function"
		throw new cola.I18nException("cola.error.invalidListener", eventName)

	listeners = listenerRegistry.listeners
	aliasMap = listenerRegistry.aliasMap
	if listeners
		if alias and aliasMap?[alias] > -1 then cola.off(eventName + ":" + alias)
		listeners.push(listener)
		i = listeners.length - 1
	else
		listenerRegistry.listeners = listeners = [listener]
		i = 0

	if alias
		if !aliasMap
			listenerRegistry.aliasMap = aliasMap = {}
		aliasMap[alias] = i
	return @

cola.off = (eventName, listener) ->
	i = eventName.indexOf(":")
	if i > 0
		alias = eventName.substring(i + 1)
		eventName = eventName.substring(0, i)

	listenerRegistry = colaEventRegistry[eventName]
	if !listenerRegistry then return @

	listeners = listenerRegistry.listeners
	if !listeners or listeners.length == 0 then return @

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

cola.getListeners = (eventName) ->
	listener = colaEventRegistry[eventName]?.listeners
	return if listener?.length then listener else null

cola.fire = (eventName, self, arg = {}) ->
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

cola.ready = (listener) ->
	return @on("ready", listener)

###
Setting
###

setting = {
	defaultCharset: "utf-8"
}

cola.setting = (key, value) ->
	if typeof key == "string"
		if value != undefined
# setting(string, any)
			setting[key] = value
			if cola.getListeners("settingChange")
				cola.fire("settingChange", cola, {key: key})
		else
# setting(string)
			return setting[key]
	else if typeof key == "object"
# setting(object)
		for k, v of key
			setting[k] = v
			if cola.getListeners("settingChange")
				cola.fire("settingChange", cola, {key: k})
	return @

definedSetting = colaSetting? or global?.colaSetting
if definedSetting
	for key, value of definedSetting then cola.setting(key, value)

###
Exception
###

exceptionStack = []

alertException = (ex) ->
	if ex instanceof cola.Exception or ex instanceof Error
		msg = ex.message
	else
		msg = ex + ""
	alert?(msg)
	return

class cola.Exception
	constructor: (@message, @error)->
		if @error then console?.trace?(@error)

		exceptionStack.push(@)
		setTimeout(() =>
			if exceptionStack.indexOf(@) > -1
				cola.Exception.processException(@)
			return
		, 50)

	@processException = (ex) ->
		if cola.Exception.ignoreAll then return

		if ex then cola.Exception.removeException(ex)
		if ex instanceof cola.AbortException then return

		if cola.fire("exception", cola, {exception: ex}) == false then return

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

	@removeException = (ex) ->
		i = exceptionStack.indexOf(ex)
		if i > -1 then exceptionStack.splice(i, 1)
		return

	@safeShowException: (exception) ->
		alertException(exception)
		return

	@showException: (exception) ->
		alertException(exception)
		return

class cola.AbortException extends cola.Exception
	constructor: () ->

class cola.RunnableException extends cola.Exception
	constructor: (@script) ->
		super("[script]")

###
I18N
###

defaultLocale = "zh"

i18nStore = {}

sprintf = (templ, params...) ->
	for param, i in params
		templ = templ.replace(new RegExp("\\{#{i}\\}", "g"), param)
	return templ

cola.i18n = (key, params...) ->
	if typeof key == "string"
# i18n(key, params...)
# read i18n resource
		locale = cola.setting("locale") or defaultLocale
		templ = i18nStore[locale]?[key]
		if templ
			if params.length
				return sprintf.apply(@, [templ].concat(params))
			else
				return templ
		else
			return key
	else
# i18n(bundle, locale)
# load i18n resources from bundle(json)
		bundle = key
		locale = params[0] or defaultLocale
		oldBundle = i18nStore[locale]
		if oldBundle
			for key, str of bundle
				oldBundle[key] = str
		else
			i18nStore[locale] = oldBundle = bundle
		return

class cola.I18nException extends cola.Exception
	constructor: (key, params...) ->
		super(cola.i18n(key, params...))

###
Mothods
###

cola.callback = (callback, success, result) ->
	return unless callback
	if typeof callback == "function"
		if success
			return callback.call(@, result)
	else
		scope = callback.scope or @
		if callback.delay
			setTimeout(() ->
				callback.callback.call(scope, success, result)
				return
			, callback.delay)
			return
		else
			return callback.callback.call(scope, success, result)
