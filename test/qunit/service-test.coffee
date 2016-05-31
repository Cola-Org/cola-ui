QUnit.test "cola.AjaxService: success", (assert) ->
	service = new cola.AjaxService({
		url: "test/resources/city.json"
	})
	invoker = service.getInvoker()

	stop()
	invoker.invokeAsync(
		callback: (success, result) ->
			assert.ok(success)
			assert.ok(result instanceof Array)
			assert.equal(result.length, 3)
			start()
	)

QUnit.test "cola.AjaxService: failure", (assert) ->
	service = new cola.AjaxService({
		url: "test/resources/city-error.json"
	})
	invoker = service.getInvoker()

	stop()
	invoker.invokeAsync(
		callback: (success, result) ->
			assert.notOk(success)
			start()
	)

QUnit.test "cola.Provider", (assert) ->
	provider = new cola.Provider({
		url: "test/resources/city.json"
		pageSize: 20
		pageNo: 3
	})
	invoker = provider.getInvoker()

	stop()
	invoker.invokeAsync(
		callback: (success, result) ->
			assert.ok(success)
			assert.ok(result instanceof Array)
			assert.equal(result.length, 3)
			start()
	)