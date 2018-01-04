if XDate
	$?(()->
		XDate.locales[''] = localeStrings = {}
		localeStrings.monthNames = cola.resource("cola.date.monthNames", 6).split(",") if cola.resource("cola.date.monthNames")
		localeStrings.monthNamesShort = cola.resource("cola.date.monthNamesShort").split(",") if cola.resource("cola.date.monthNamesShort")
		localeStrings.dayNames = cola.resource("cola.date.dayNames").split(",") if cola.resource("cola.date.dayNames")
		localeStrings.dayNamesShort = cola.resource("cola.date.dayNamesShort").split(",") if cola.resource("cola.date.dayNamesShort")
		localeStrings.amDesignator = cola.resource("cola.date.amDesignator") if cola.resource("cola.date.amDesignator")
		localeStrings.pmDesignator = cola.resource("cola.date.pmDesignator") if cola.resource("cola.date.pmDesignator")
		return
	)

	XDate.parsers.push (str)->
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
			if c is "\""
				hasText = true
				if inQuota is c
					inQuota = false
				else if not inQuota
					inQuota = c
			else if not inQuota and parts[c]
				if parts[c].len is 0 then patterns.push(c)
				parts[c].len++
			else
				hasText = true
			i++

		shouldReturn = false
		if not hasText
			if dateStr.match(/^\d{2,14}$/)
				shouldReturn = true
				start = 0
				for pattern in patterns
					part = parts[pattern]
					if part.len
						digit = dateStr.substring(start, start + part.len)
						part.value = +digit
						start += part.len
		else
			digits = dateStr.split(/\D+/)
			if digits[digits.length - 1] is "" then digits.splice(digits.length - 1, 1)
			if digits[0] is "" then digits.splice(0, 1)
			if patterns.length is digits.length
				shouldReturn = true
				for pattern, i in patterns
					parts[pattern].value = +digits[i]

		if shouldReturn
			return new XDate(parts.y.value, parts.M.value - 1, parts.d.value, parts.h.value, parts.m.value, parts.s.value)
		else
			return