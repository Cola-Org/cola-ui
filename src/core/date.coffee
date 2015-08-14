#IMPORT_BEGIN
if exports?
	XDate = require("./../lib/xdate")
	cola = require("./base")
	module?.exports = cola
else
	XDate = @XDate
	cola = @cola
#IMPORT_END

if XDate
	$?(() ->
		XDate.defaultLocale = cola.setting("locale") or defaultLocale
		XDate.locales[defaultLocale] = localeStrings = {}
		localeStrings.monthNames = cola.i18n("cola.date.monthNames").split(",") if cola.i18n("cola.date.monthNames")
		localeStrings.monthNamesShort = cola.i18n("cola.date.monthNamesShort").split(",") if cola.i18n("cola.date.monthNamesShort")
		localeStrings.dayNames = cola.i18n("cola.date.dayNames").split(",") if cola.i18n("cola.date.dayNames")
		localeStrings.dayNamesShort = cola.i18n("cola.date.dayNamesShort").split(",") if cola.i18n("cola.date.dayNamesShort")
		localeStrings.amDesignator = cola.i18n("cola.date.amDesignator") if cola.i18n("cola.date.amDesignator")
		localeStrings.pmDesignator = cola.i18n("cola.date.pmDesignator") if cola.i18n("cola.date.pmDesignator")
		return
	)

	XDate.parsers.push (str) ->
		if str.indexOf("||") < 0 then return

		parts = str.split("||")
		format = parts[0]
		dateStr = parts[1]

		parts =
			y: len: 0, value: 1900
			M: len: 0, value: 1
			d: len: 0, value: 1
			h: len: 0, value: 0
			m: len: 0, value: 0
			s: len: 0, value: 0
		patterns = []

		hasText = false
		inQuota = false
		i = 0
		while i < format.length
			c = format.charAt(i)
			if c == "\""
				hasText = true
				if inQuota == c
					inQuota = false
				else if !inQuota
					inQuota = c
			else if !inQuota and parts[c]
				if parts[c].len == 0 then patterns.push(c)
				parts[c].len++
			else
				hasText = true
			i++

		shouldReturn = false
		if !hasText
			if dateStr.match(/^\d{2,14}$/)
				shouldReturn = true
				start = 0
				for pattern in patterns
					part = parts[pattern]
					if part.len
						digit = dateStr.substring(start, start + part.len)
						part.value = parseInt(digit, 10)
						start += part.len
		else
			digits = dateStr.split(/\D+/)
			if digits[digits.length - 1] == "" then digits.splice(digits.length - 1, 1)
			if digits[0] == "" then digits.splice(0, 1)
			if patterns.length == digits.length
				shouldReturn = true
				for pattern, i in patterns
					parts[pattern].value = parseInt(digits[i], 10)

		if shouldReturn
			return new XDate(parts.y.value, parts.M.value - 1, parts.d.value, parts.h.value, parts.m.value, parts.s.value)
		else
			return