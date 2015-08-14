assert = require("chai").assert
cola = require("../../src/core/base")

describe "base", () ->
	describe "cola.setting", ()->
		it "load & read", ()->
			cola.setting("a": "A", "a.b": "A.B")
			assert.equal("A", cola.setting("a"))
			assert.equal("A.B", cola.setting("a.b"))

	describe "cola.Exception", ()->
		it "new", ()->
			msg = "test message"
			err = new Error()
			ex = new cola.Exception(msg, err)
			assert.equal(msg, ex.message)
			assert.equal(err, ex.error)

		it "processException", (done)->
			msg = "processException"
			ex = new cola.Exception(msg)

			showExceptionCalledCounter = 0
			ex.safeShowException = () =>
				showExceptionCalledCounter++
				if ex != @
					throw "wrong exception instance"

			run = () ->
				if showExceptionCalledCounter == 0
					throw "showException() never called"
				done()
			setTimeout(run, 200)

		it "removeException", (done)->
			msg = "removeException"
			ex = new cola.Exception(msg)

			showExceptionCalledCounter = 0
			ex.safeShowException = () =>
				showExceptionCalledCounter++
				if ex != @
					throw "wrong exception instance"

			cola.Exception.removeException(ex)

			run = () ->
				if showExceptionCalledCounter > 0
					throw "showException() called"
				done()
			setTimeout(run, 200)

	describe "cola.RunnableException", ()->
		it "script evaluate", (done)->
			new cola.RunnableException("""
				console.log("cola.RunnableException.script invoked");
				cola["cola.RunnableException.testFlag"] = true;
				""")

			run = () ->
				if !cola["cola.RunnableException.testFlag"]
					throw "script never evaluated"
				done()
			setTimeout(run, 200)

	describe "i18n", ()->
		it "load and read", ()->
			locale = "moon"

			cola.i18n({
				key1: "string1",
				key2: "{0} said hello to {1}"
			}, locale)

			cola.setting("locale", locale)
			assert.equal("string1", cola.i18n("key1"))
			assert.equal("Tom said hello to Mike", cola.i18n("key2", "Tom", "Mike"))

			cola.setting("locale", "en_US")
			assert.equal("key1", cola.i18n("key1"))

	describe "event", ()->
		it "on", ()->
			event = ()->
			cola.on("exception", event)
			assert.equal(1, cola.getListeners("exception").length)
			cola.on("exception", event)
			assert.equal(2, cola.getListeners("exception").length)
			cola.off("exception", event)
			assert.equal(1, cola.getListeners("exception").length)
			cola.off("exception", event)
			assert.isNull(cola.getListeners("exception"))

		it "on with alias", ()->
			event = ()->
			cola.on("exception:alias1", event)
			assert.equal(1, cola.getListeners("exception").length)
			cola.on("exception:alias1", event)
			assert.equal(1, cola.getListeners("exception").length)
			cola.off("exception:alias1")
			assert.isNull(cola.getListeners("exception"))

		it "off all", ()->
			event = ()->
			cola.on("exception:alias1", event)
			assert.equal(1, cola.getListeners("exception").length)
			cola.on("exception:alias2", event)
			assert.equal(2, cola.getListeners("exception").length)
			cola.off("exception")
			assert.isNull(cola.getListeners("exception"))

		it "fire exception", (done)->
			eventFiredCounter = 0
			ex = new cola.Exception()

			event = (self, arg)->
				if ex != arg.exception
					throw "wrong exception instance"
				eventFiredCounter++
				console.log("exception event fired")

			cola.on("exception", event)
			cola.on("exception", event)

			run = () ->
				cola.off("exception")
				if eventFiredCounter != 2
					throw "exception event counter should be 2, but was #{eventFiredCounter}"
				done()
			setTimeout(run, 500)