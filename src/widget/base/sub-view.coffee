class cola.SubView extends cola.Widget
	@CLASS_NAME: "sub-view"

	@ATTRIBUTES:
		loading: null
		url:
			readOnlyAfterCreate: true
		jsUrl:
			readOnlyAfterCreate: true
		cssUrl:
			readOnlyAfterCreate: true
		model:
			readOnly: true
			getter: () ->
				return if @_dom then cola.util.userData(@_dom, "_model") else null
		param:
			readOnlyAfterCreate: true

	@EVENTS:
		load: null
		loadError: null
		unload: null

	_initDom: (dom)->
		if @_url
			@load(
				url: @_url
				jsUrl: @_jsUrl
				cssUrl: @_cssUrl
				param: @_param
			)
		return

	load: (options, callback) ->
		dom = @_dom
		@unload()

		model = new cola.Model(@_scope)
		cola.util.userData(dom, "_model", model)

		@_url = options.url
		@_jsUrl = options.jsUrl
		@_cssUrl = options.cssUrl
		@_param = options.param

		@_loading = true
		cola.loadSubView(@_dom,
			{
				model: model
				htmlUrl: @_url
				jsUrl: @_jsUrl
				cssUrl: @_cssUrl
				param: @_param
				callback: {
					callback:(success, result) =>
						@_loading = false
						if success
							@fire("load", @)
						else
							@fire("loadError", @, {
								error: result
							})
						cola.callback(callback, success, result)
						return
				}
			})
		return

	loadIfNecessary: (options, callback) ->
		if @_url == options.url
			cola.callback(callback, true)
		else
			@load(options, callback)
		return

	unload: () ->
		dom = @_dom

		delete @_url
		delete @_jsUrl
		delete @_cssUrl
		delete @_param

		model = cola.util.userData(dom, "_model")
		model?.destroy()
		cola.util.removeUserData(dom, "_model")
		$fly(dom).empty()
		@fire("unload", @)
		return

