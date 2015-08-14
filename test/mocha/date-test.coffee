assert = require("chai").assert
XDate = require("../../src/lib/xdate")
cola = require("../../src/core/date")

describe "XDate", () ->
	describe "parser", ()->
		test = (format, str) ->
			date = new XDate("#{format}___#{str}")
			assert.equal(str, date.toString(format))

		it "yyyy-MM-dd", ()->
			test("yyyy-MM-dd", "1977-04-03")

		it "yyyyMMdd", ()->
			test("yyyyMMdd", "19791115")

		it "yyMMdd", ()->
			test("yyMMdd", "081223")

		it "yyyy年MM月dd日", ()->
			test("yyyy年MM月dd日", "2009年10月15日")

		it "yyyy\'y\'MM\'M\'dd\'d\'", ()->
			test("yyyy\'y\'MM\'M\'dd\'d\'", "1994y08M06d")

		it "hh:mm:ss", ()->
			test("hh:mm:ss", "10:08:32")

		it "hh:mm", ()->
			test("hh:mm:ss", "10:08:32")
			date = new XDate("hh:mm___12:18")
			assert.equal("12:18:00", date.toString("hh:mm:ss"))