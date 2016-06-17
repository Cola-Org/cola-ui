class cola.SubView extends cola.Widget
	@tagName: "c-subView"
	@CLASS_NAME: "sub-view"

	@attributes:
		loading: null
		url:
			readOnlyAfterCreate: true
		jsUrl:
			readOnlyAfterCreate: true
		cssUrl:
			readOnlyAfterCreate: true
		parentModel: null
		modelName: null
		model:
			readOnly: true
			getter: () ->
				return if @_dom then cola.util.userData(@_dom, "_model") else null
		param:
			readOnlyAfterCreate: true

		showLoadingContent: null

	@events:
		load: null
		loadError: null
		unload: null

	_initDom: (dom)->
		$dom = $fly(dom)
		if $dom.find(">.content").length is 0
			$dom.xAppend(class: "content")

		if @_url
			@load(
				url: @_url
				jsUrl: @_jsUrl
				cssUrl: @_cssUrl
				param: @_param
			)
		return

	load: (options, callback) ->
		if typeof options is "function"
			callback = options
			options = null

		dom = @_dom
		@unload()

		if options
			@_parentModel = options.parentModel
			@_modelName = options.modelName
			@_url = options.url
			@_jsUrl = options.jsUrl
			@_cssUrl = options.cssUrl
			@_param = options.param

		if @_parentModel instanceof cola.Scope
			parentModel = @_parentModel
		else
			parentModelName = @_parentModel or cola.constants.DEFAULT_PATH
			parentModel = cola.model(parentModelName)

		if @_modelName
			model = new cola.Model(@_modelName, parentModel or @_scope)
		else
			model = new cola.Model(parentModel or @_scope)
		cola.util.userData(dom, "_model", model)

		@_loading = true
		$dom = $(@_dom)
		$content = $dom.find(">.content")

		if not @_showLoadingContent
			$content.css("visibility", "hidden")

		$dimmer = $dom.find(">.ui.dimmer")
		if $dimmer.length is 0
			$dom.xAppend(
				class: "ui inverted dimmer"
				content:
					class: "ui loader"
			)
			$dimmer = $dom.find(">.ui.dimmer")
		$dimmer.addClass("active")

		cola.loadSubView($content[0],
			{
				model: model
				htmlUrl: @_url
				jsUrl: @_jsUrl
				cssUrl: @_cssUrl
				param: @_param
				callback: {
					complete:(success, result) =>
						@_currentUrl = @_url
						@_currentJsUrl = @_jsUrl
						@_currentCssUrl = @_cssUrl

						if not @_showLoadingContent
							$dom.find(">.content").css("visibility", "")

						$dom.find(">.ui.dimmer").removeClass("active")

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
		if typeof options is "function"
			callback = options
			options = null

		if @_currentUrl and @_currentUrl is options?.url and @_currentJsUrl is options.jsUrl and @_currentCssUrl is options.cssUrl
			cola.callback(callback, true)
		else
			@load(options, callback)
		return

	unload: () ->
		return unless @_dom

		cola.unloadSubView($fly(@_dom).find(">.content")[0], {
			htmlUrl: @_url
			cssUrl: @_cssUrl
		})

		delete @_currentUrl
		delete @_currentCssUrl

		dom = @_dom
		model = cola.util.userData(dom, "_model")
		model?.destroy()
		cola.util.removeUserData(dom, "_model")

		@fire("unload", @)
		return

	reload: (callback) -> @load(callback)

cola.registerWidget(cola.SubView)

