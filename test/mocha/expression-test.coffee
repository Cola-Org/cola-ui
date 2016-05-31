assert = require("chai").assert
should = require("chai").should()
cola = require("../../src/core/expression.js")

describe "expression", () ->
	describe "compileText", () ->
		it "compileText 1", () ->
			parts = cola._compileText("aaa")
			assert.isNull(parts)

			parts = cola._compileText("aaa{{")
			assert.isNull(parts)

			parts = cola._compileText("aaa{{bbb}")
			assert.isNull(parts)

			parts = cola._compileText("{{}}")
			assert.isNull(parts)

			parts = cola._compileText("{{aaaa} }")
			assert.isNull(parts)

			parts = cola._compileText("{{aaaa{{}")
			assert.isNull(parts)

			parts = cola._compileText("{{\"}}\"")
			assert.isNull(parts)

		it "compileText 2", () ->
			parts = cola._compileText("{{aaaa}}")
			assert.equal(parts.length, 1)

			parts = cola._compileText("{{\"aaaa\" + 'ccc'}}")
			assert.equal(parts.length, 1)

			parts = cola._compileText("{{\"{{\" + '}}'}}")
			assert.equal(parts.length, 1)

		it "compileText 3", () ->
			should.throw () ->
				cola._compileText("{{?}}")

			should.throw () ->
				cola._compileText("{{pro:duct()}}")

		it "compileText 4", () ->
			parts = cola._compileText("aaa{{product.price * product.taxRate / 100}}bbb{{aaa.bb}}ccc")
			assert.equal(parts.length, 5)
			assert.equal(parts[0], "aaa")
			assert.equal(typeof parts[1], "object")
			assert.equal(parts[2], "bbb")
			assert.equal(typeof parts[3], "object")
			assert.equal(parts[4], "ccc")

	describe "cola.Expression", () ->
		it "stringify 1", () ->
			expr = new cola.Expression("abc")
			assert.equal(expr.expression, "_getData(scope,'abc',loadMode,dataCtx)")

			expr = new cola.Expression("(1 + 2) / 3")
			assert.equal(expr.expression, "((1+2)/3)")

			expr = new cola.Expression("(1 + 2) / (a ? b : c)")
			assert.equal(expr.expression, "((1+2)/(_getData(scope,'a',loadMode,dataCtx)?_getData(scope,'b',loadMode,dataCtx):_getData(scope,'c',loadMode,dataCtx)))")

		it "stringify dataPath", () ->
			expr = new cola.Expression("a.b.c")
			assert.equal(expr.expression, "_getData(scope,'a.b.c',loadMode,dataCtx)")
			assert.equal(expr.path, "a.b.c")

			expr = new cola.Expression("a.b ? a.c : a.d")
			assert.equal(expr.expression, "(_getData(scope,'a.b',loadMode,dataCtx)?_getData(scope,'a.c',loadMode,dataCtx):_getData(scope,'a.d',loadMode,dataCtx))")
			assert.equal(expr.path.length, 3)
			assert.equal(expr.path[0], "a.b")
			assert.equal(expr.path[1], "a.c")
			assert.equal(expr.path[2], "a.d")

		it "stringify action call", () ->
			expr = new cola.Expression("reset()")
			assert.equal(expr.expression, "scope.action.reset()")
			assert.isFalse(!!expr.path)

			expr = new cola.Expression("add('abc')")
			assert.equal(expr.expression, "scope.action.add('abc')")
			assert.isFalse(!!expr.path)

			expr = new cola.Expression("calculate(x.y.z, 'wow')")
			assert.equal(expr.expression, "scope.action.calculate(_getData(scope,'x.y.z',loadMode,dataCtx),'wow')")
			assert.equal(expr.path, "x.y.z")

		it "convertor", () ->
			expr = new cola.Expression("persons | filter:name", true)
			assert.equal(expr.expression, "_getData(scope,'persons',loadMode,dataCtx)")
			assert.equal(expr.path.join(","), "persons,name")
			assert.equal(expr.convertors.length, 1)

			convertor = expr.convertors[0]
			assert.equal(convertor.name, "filter")
			assert.equal(convertor.params.length, 1)

			param = convertor.params[0]
			assert.equal(param.expression, "_getData(scope,'name',loadMode,dataCtx)")

		it "multi convertors", () ->
			expr = new cola.Expression("dept.persons | filter:name | format:'-|-':123 ", true)
			assert.equal(expr.expression, "_getData(scope,'dept.persons',loadMode,dataCtx)")
			assert.equal(expr.path.join(","), "dept.persons,name")
			assert.equal(expr.convertors.length, 2)

			convertor = expr.convertors[1]
			assert.equal(convertor.name, "format")
			assert.equal(convertor.params.length, 2)

			param = convertor.params[0]
			assert.equal(param.expression, "'-|-'")

			param = convertor.params[1]
			assert.equal(param.expression, "123")

	describe "compileExpression", () ->
		it "as", () ->
			expr = cola._compileExpression("employee.supervisor as person", "alias")
			assert.isTrue(expr.setAlias)
			assert.equal(expr.alias, "person")
			assert.equal(expr.path, "employee.supervisor")

		it "in", () ->
			expr = cola._compileExpression("employee in company.employees", "repeat")
			assert.isTrue(expr.repeat)
			assert.equal(expr.alias, "employee")
			assert.equal(expr.path, "company.employees")