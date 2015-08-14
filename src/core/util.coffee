#IMPORT_BEGIN
if exports?
	cola = require("./keyed-array")
	module?.exports = cola
else
	cola = @cola
#IMPORT_END

cola.util.trim = (text) ->
	return if text? then String.prototype.trim.call(text) else ""

cola.util.capitalize = (text) ->
	return text unless text
	return text.charAt(0).toUpperCase() + text.slice(1);

cola.util.isSimpleValue = (value) ->
	if value == null or value == undefined then return false
	type = typeof value
	return type != "object" and type != "function" or type instanceof Date

cola.util.parseStyleLikeString = (styleStr, headerProp) ->
	return false unless styleStr

	style = {}
	parts = styleStr.split(";")
	for part, i in parts
		j = part.indexOf(":")
		if j > 0
			styleProp = @trim(part.substring(0, j))
			styleExpr = @trim(part.substring(j + 1))
			if styleProp and styleExpr
				style[styleProp] = styleExpr
		else
			part = @trim(part)
			if not part then continue
			if i == 0 and headerProp
				style[headerProp] = part
			else
				style[part] = true

	#	if invalid
	#		throw new cola.I18nException("cola.error.invalidFormat", styleStr)
	return style

cola.util.isCompatibleType = (baseType, type) ->
	if type == baseType then return true
	while type.__super__
		type = type.__super__.constructor
		if type == baseType then return true
	return false

cola.util.delay = (owner, name, delay, fn) ->
	cola.util.cancelDelay(owner, name)
	owner["_timer_" + name] = setTimeout(() ->
		fn.call(owner)
		return
	, delay)
	return

cola.util.cancelDelay = (owner, name) ->
	key = "_timer_" + name
	timerId = owner[key]
	if timerId
		delete owner[key]
		clearTimeout(timerId)
	return

cola.util.waitForAll = (funcs, callback) ->
	if !funcs or !funcs.length
		cola.callback(callback, true)

	completed = 0
	total = funcs.length
	procedures = {}
	for func in funcs
		id = cola.uniqueId()
		procedures[id] = true

		func({
			id: id
			callback: (success) ->
				return if disabled
				if success
					if procedures[@id]
						delete procedures[@id]
						completed++
						if completed == total
							cola.callback(callback, true)
							disabled = true
				else
					cola.callback(callback, false)
					disabled = true
				return
		})
	return