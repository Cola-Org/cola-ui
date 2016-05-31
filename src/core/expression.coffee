#IMPORT_BEGIN
if exports?
	jsep = require("./../lib/jsep")
	cola = require("./element")
	module?.exports = cola
else
	jsep = @jsep
	cola = @cola
#IMPORT_END

cola._compileText = (text) ->
	p = 0
	s = 0
	while (s = text.indexOf("{{", p)) > -1
		exprStr = digestExpression(text, s + 2)
		if exprStr
			if s > p
				if !parts then parts = []
				parts.push(text.substring(p, s))

			expr = cola._compileExpression(exprStr, if exprStr.indexOf(" in ") > 0 then "repeat" else undefined)
			if !parts then parts = [expr] else parts.push(expr)
			p = s + exprStr.length + 4
		else
			break

	if parts
		if p < text.length - 1
			parts.push(text.substring(p))
		return parts
	else
		return null

digestExpression = (text, p) ->
	s = p
	len = text.length
	endBracket = 0
	while p < len
		c = text.charCodeAt(p)
		if c is 125 && !quota    # `}`
			if endBracket is 1
				return text.substring(s, p - 1)
			endBracket++
		else
			endBracket = 0
			if c is 39 or c is 34    # `'` or `"`
				if quota
					if quota is c then quota = false
				else
					quota = c
		p++
	return

cola._compileExpression = (exprStr, specialType) ->
	if !exprStr then return null

	if specialType is "repeat"
		i = exprStr.indexOf(" in ")
		if i > 0
			aliasName = exprStr.substring(0, i)
			if aliasName.match(cola.constants.VARIABLE_NAME_REGEXP)
				exprStr = exprStr.substring(i + 4)
				if !exprStr then return null
				exp = new cola.Expression(exprStr, true)
				exp.raw = aliasName + " in " + exp.raw
				exp.repeat = true
				exp.alias = aliasName
			if not exp
				throw new cola.Exception("\"#{exprStr}\" is not a valid expression.")
		else
			exp = new cola.Expression(exprStr, true)
			exp.repeat = true
			exp.alias = "item"
	else if specialType is "alias"
		i = exprStr.indexOf(" as ")
		if i > 0
			aliasName = exprStr.substring(i + 4)
			if aliasName && aliasName.match(cola.constants.VARIABLE_NAME_REGEXP)
				exprStr = exprStr.substring(0, i)
				if !exprStr then return null
				exp = new cola.Expression(exprStr, true)
				exp.raw = exp.raw + " as " + aliasName
				exp.setAlias = true
				exp.alias = aliasName
		if not exp
			throw new cola.Exception("\"#{exprStr}\" should be a alias expression.")
	else
		exp = new cola.Expression(exprStr, true)

	return exp

splitExpression = (text, separator) ->
	separatorCharCode = separator.charCodeAt(0)
	parts = null
	p = 0
	i = 0
	len = text.length
	while i < len
		c = text.charCodeAt(i)
		if c is separatorCharCode && !quota
			part = text.substring(p, i)
			parts ?= []
			parts.push(cola.util.trim(part))
			p = i + 1
		else
			if c is 39 or c is 34    # `'` or `"`
				if quota
					if quota is c then quota = false
				else
					quota = c
		i++

	if p < len
		part = text.substring(p)
		parts ?= []
		parts.push(cola.util.trim(part))
	return parts

class cola.Expression
	#paths
	#hasCallStatement

	constructor: (exprStr) ->
		@raw = exprStr

		i = exprStr.indexOf(" on ")
		if 0 < i < (exprStr.length - 1)
			watchPathStr = exprStr.substring(i + 4)
			exprStr = exprStr.substring(0, i)

			watchPaths = []
			for path in watchPathStr.split(/[,;]/)
				path = cola.util.trim(path)
				continue unless path
				if path.indexOf(".") > 0
					parts = []
					oldParts = path.split(".")
					last = oldParts.length - 1
					for part, j in oldParts
						if j < last and part.charCodeAt(0) != 33 # `!`
							part = "!" + part
						parts.push(part)
					path = parts.join(".")
				watchPaths.push(path)

		fc = exprStr.charCodeAt(0)
		if fc is 61 # `=`
			exprStr = exprStr.substring(1)
			@isStatic = true
		else if fc is 63 # `?`
			exprStr = exprStr.substring(1)
			@isDyna = true

		@compile(exprStr)
		@paths = watchPaths if watchPaths

	compile: (exprStr) ->

		stringify = (node, parts, pathParts, close, context) ->
			type = node.type
			switch type
				when "MemberExpression", "Identifier", "ThisExpression"
					if type is "MemberExpression"
						stringify(node.object, parts, pathParts, false, context)

						if pathParts.length
							pathParts.push(node.property.name)
						else
							parts.push(".")
							parts.push(node.property.name)
					else
						pathParts.push(node.name)

				when "CallExpression"
					context.hasCallStatement = true

					callee = node.callee
					if callee.type is "Identifier"
						parts.push("scope.action(\"")
						parts.push(node.callee.name)
						parts.push("\")(")
					else if callee.type is "MemberExpression"
						stringify(callee.object, parts, pathParts, true, context)
						parts.push(".")
						parts.push(callee.property.name)
						parts.push("(")
					else
						throw new cola.Exception("\"#{exprStr}\" invalid callee.")

					if node.arguments?.length
						for argument, i in node.arguments
							if i > 0 then parts.push(",")
							stringify(argument, parts, pathParts, true, context)
					parts.push(")")

				when "Literal"
					parts.push(node.raw)

				when "BinaryExpression", "LogicalExpression"
					parts.push("(")
					stringify(node.left, parts, pathParts, true, context)
					parts.push(node.operator)
					stringify(node.right, parts, pathParts, true, context)
					parts.push(")")

				when "UnaryExpression"
					parts.push(node.operator)
					stringify(node.argument, parts, pathParts, true, context)

				when "ConditionalExpression"
					parts.push("(")
					stringify(node.test, parts, pathParts, true, context)
					parts.push("?")
					stringify(node.consequent, parts, pathParts, true, context)
					parts.push(":")
					stringify(node.alternate, parts, pathParts, true, context)
					parts.push(")")

				when "ArrayExpression"
					parts.push("[")
					for element, i in node.elements
						if i > 0 then parts.push(",")
						stringify(element, parts, pathParts, true, context)
					parts.push("]")

			if close and pathParts.length
				path = pathParts.join(".")
				if not context.paths
					context.paths = [path]
				else
					context.paths.push(path)

				parts.push("_getData(scope,'")
				parts.push(path)
				parts.push("',loadMode,dataCtx)")
				pathParts.splice(0, pathParts.length)

			return

		tree = jsep(exprStr)
		@type = tree.type

		parts = []
		pathParts = []
		stringify(tree, parts, pathParts, true, @)
		@expression = parts.join("")
		return

	evaluate: (scope, loadMode, dataCtx)  ->
		retValue = eval(@expression)

		if retValue instanceof cola.Chain
			retValue = retValue._data

		if retValue instanceof cola.Entity or retValue instanceof cola.EntityList
			dataCtx?.path = retValue.getPath()
		return retValue

	toString: () ->
		return @expression

_getData = (scope, path, loadMode, dataCtx)  ->
	retValue = scope.get(path, loadMode, dataCtx)
	if retValue is undefined and dataCtx?.vars
		retValue = dataCtx.vars[path]
	return retValue