BLANK_PATH = "about:blank"
class cola.IFrame extends cola.Widget
	@tagName: "c-iframe"
	@className: "iframe"

	@attributes:
		path:
			defaultValue: BLANK_PATH
			setter: (value)->
				#oldValue = @_path
				@_path = value
				#return if oldValue is value or !@_dom
				@_loaded = false
				@_replaceUrl(@_path)
				return

		loadingText: null

	@events:
		load: null

	_initDom: (dom)->
		frame = @
		frameDoms = @_doms
		$dom = $(dom)
		$dom.addClass("loading").empty().append($.xCreate([
			{
				tagName: "div"
				class: "ui active inverted dimmer"
				content: {
					tagName: "div"
					class: "ui medium text loader"
					content: @_loadingText or ""
					contextKey: "loader"
				}
				contextKey: "dimmer"
			}
			{
				tagName: "iframe"
				contextKey: "iframe"
#				scrolling: if cola.os.ios then "no" else "auto"
				frameBorder: 0
			}
		], frameDoms))

		$(frameDoms.iframe).on("load", ()=>
			$(frameDoms.dimmer).removeClass("active")
			frame.fire("load", @)
			frame._loaded = true
		).attr("src", @_path)
		return

	getLoaderContainer: ()->
		if not @_dom then @getDom()
		return @_doms.dimmer

	getContentWindow: ()->
		@_doms ?= {}
		try
			contentWindow = @_doms.iframe.contentWindow if @_doms.iframe
		catch e

		return contentWindow

	open: (path, callback)->
		if callback then @one("load", ()-> cola.callback(callback, true))
		@set("path", path)
		return

	reload: (callback)->
		if callback then @one("load", ()-> cola.callback(callback, true))
		@_replaceUrl(@_path)
		return @

	_replaceUrl: (url)->
		if @_doms and @_doms.dimmer
			$fly(@_doms.dimmer).addClass("active")
		contentWindow = @getContentWindow()
		if contentWindow
			contentWindow.location.replace(url)
		else
			@_doms.iframe && $fly(@_doms.iframe).prop("src", url)
		return @

cola.registerWidget(cola.IFrame)