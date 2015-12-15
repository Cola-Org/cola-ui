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

		showLoadingContent: null
		showDimmer:
			defaultValue: false

	@EVENTS:
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
		dom = @_dom
		@unload()

		model = new cola.Model(@_scope)
		cola.util.userData(dom, "_model", model)

		@_url = options.url
		@_jsUrl = options.jsUrl
		@_cssUrl = options.cssUrl
		@_param = options.param

		@_loading = true
		$dom = $(@_dom)
		$content = $dom.find(">.content")

		if not @_showLoadingContent
			$content.css("visibility", "hidden")

		if @_showDimmer
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
						if not @_showLoadingContent
							$dom.find(">.content").css("visibility", "")

						if @_showDimmer
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
		if @_url == options.url
			cola.callback(callback, true)
		else
			@load(options, callback)
		return

	unload: () ->
		return unless @_dom

		cola.unloadSubView($fly(@_dom).find(">.content")[0], {
			cssUrl: @_cssUrl
		})

		delete @_url
		delete @_jsUrl
		delete @_cssUrl
		delete @_param

		dom = @_dom
		model = cola.util.userData(dom, "_model")
		model?.destroy()
		cola.util.removeUserData(dom, "_model")

		@fire("unload", @)
		return

