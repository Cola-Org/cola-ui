class cola.SubView extends cola.Widget
	@tagName: "c-subView"
	@CLASS_NAME: "sub-view"

	@attributes:
		loading: null

		loadMode:   # lazy、auto、manual
			readOnlyAfterCreate: true
			defaultValue: "lazy"

		url:
			readOnlyAfterCreate: true
		jsUrl:
			readOnlyAfterCreate: true
		cssUrl:
			readOnlyAfterCreate: true
		timeout:
			readOnlyAfterCreate: true

		parentModel: null
		modelName: null
		contentModel:
			readOnly: true
			getter: ()->
				return if @_dom then cola.util.userData(@_dom, "_model") else null

		param: null
		showLoadingContent: null

	@events:
		load: null
		loadError: null
		unload: null

	_initDom: (dom)->
		$dom = $fly(dom)
		if $dom.find(">.content").length is 0
			content = { class: "content" }
			content[cola.constants.IGNORE_DIRECTIVE] = true
			$dom.xAppend(content)

		if @_url
			option =
				url: @_url
				jsUrl: @_jsUrl
				cssUrl: @_cssUrl
				param: @_param

			if @_loadMode is "lazy"
				if cola.util.isVisible(dom)
					@load(option)
				else
					$dom.one("visibilityChange", (evt, data)=>
						if data.visible
							@loadIfNecessary(option)
						return
					)
			else if @_loadMode is "auto"
				@load(option)
		return

	load: (options, callback)->
		if typeof options is "function"
			callback = options
			options = null

		dom = @_dom
		@unload()

		if options
			@_parentModel = options.parentModel if options.parentModel
			@_modelName = options.modelName if options.modelName
			@_url = options.url if options.url
			@_jsUrl = options.jsUrl if options.jsUrl
			@_cssUrl = options.cssUrl if options.cssUrl
			@_timeout = options.timeout if options.timeout
			@_param = options.param if options.param

		if @_modelName
			model = cola.model(@_modelName)

		if not model
			if @_parentModel instanceof cola.Scope
				parentModel = @_parentModel
			else if @_parentModel
				parentModel = cola.model(@_parentModel)
			else
				parentModel = @_scope or cola.model(cola.constants.DEFAULT_PATH)

			if @_modelName
				model = new cola.Model(@_modelName, parentModel)
			else
				model = new cola.Model(parentModel)
			@_hasOwnModel = true
		cola.util.userData(dom, "_model", model)

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

		@_currentUrl = @_url
		@_currentJsUrl = @_jsUrl
		@_currentCssUrl = @_cssUrl
		@_loaded = false

		@_loadingDeferred = cola.loadSubView($content[0], {
			model: model
			htmlUrl: @_url
			jsUrl: @_jsUrl
			cssUrl: @_cssUrl
			timeout: @_timeout
			param: @_param
		}).done(()=>
			@_loadingDeferred = null
			@_loaded = true

			if not @_showLoadingContent
				$dom.find(">.content").css("visibility", "")

			$dom.find(">.ui.dimmer").removeClass("active")

			@fire("load", @)
			cola.callback(callback, true)
			return
		).fail((result)=>
			@_loadingDeferred = null

			@fire("loadError", @, {
				error: result
			})
			cola.callback(callback, false, result)
			return
		)
		return cola.util.wrapDeferredWith(@, @_loadingDeferred)

	loadIfNecessary: (options, callback)->
		if typeof options is "function"
			callback = options
			options = null

		url = @_url
		jsUrl  = @_jsUrl
		cssUrl = @_cssUrl
		url = options.url if options.url
		jsUrl = options.jsUrl if options.jsUrl
		cssUrl = options.cssUrl if options.cssUrl

		if @_loadingDeferred
			if @_currentUrl is url and @_currentJsUrl is jsUrl and @_currentCssUrl is cssUrl
				return @_loadingDeferred.done(()->
					cola.callback(callback, true)
					return
				)
			else
				throw new cola.Exception("Can not load SubView during loading.")

		if @_loaded and @_currentUrl is url and @_currentJsUrl is jsUrl and @_currentCssUrl is cssUrl
			dfd = $.Deferred().resolve()
			return dfd.done(()->
				cola.callback(callback, true)
				return
			)

		return @load(options, callback)

	unload: ()->
		return unless @_dom or @_currentUrl

		cola.unloadSubView($fly(@_dom).find(">.content")[0], {
			htmlUrl: @_currentUrl
			cssUrl: @_currentCssUrl
		})

		delete @_currentUrl
		delete @_currentCssUrl

		dom = @_dom
		if @_hasOwnModel = true
			model = cola.util.userData(dom, "_model")
			model?.destroy()
		cola.util.removeUserData(dom, "_model")

		@fire("unload", @)
		return

	reload: (callback)-> @load(callback)

cola.registerWidget(cola.SubView)

