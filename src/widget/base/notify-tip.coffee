TipManager = []

class cola.NotifyTip extends cola.Layer
	@tagName: "c-notify-tip"
	@CLASS_NAME: "transition hidden notify-tip message"
	@attributes:
		type:
			defaultValue: ""
			enum: [
				"info", "warning", "error", "success", ""
			]
		message:
			refreshDom: true
		description:
			refreshDom: true
		showDuration: null

	_initDom: (dom)->
		super(dom)
		notifyTip = @
		@_doms ?= {}
		$(dom).xAppend([
			{
				tagName: "i"
				class: "close icon"
				contextKey: "closeBtn"
			}
			{
				tagName: "div"
				class: "header"
				contextKey: "header"
			}
			{
				tagName: "p"
				contextKey: "description"
			}
		], @_doms)
		$(@_doms.closeBtn).on("click", ()-> notifyTip.hide())

	_doRefreshDom: ()->
		return unless @_dom
		super()
		$(@_doms.header).text(@_message || "")
		$(@_doms.description).text(@_description || "")

	_doTransition: (options, callback)->
		notifyTip = @
		isShow = options.target is "show"
		if isShow
			if cola.device.mobile
				options.animation = "scale"

			@get$Dom().addClass(@_type)
			if @_showDuration
				setTimeout(()->
					notifyTip.hide()
				, parseInt(@_showDuration))
		else
			options.animation = "scale"
		super(options, callback)
	_onHide: ()->
		super()
		@destroy()
		container=$("#c-notify-tip-container")
		if container.children().length ==0
			container.remove()

	close: @hide

cola.NotifyTipManager =
	show: (options)->
		if typeof options == "string"
			options = {
				message: options
			}
		tip = new cola.NotifyTip(options)
		dom = tip.getDom()
		container = $("#c-notify-tip-container")
		if container.length == 0
			container = $.xCreate({
				tagName: "div",
				id: "c-notify-tip-container"
			})
			document.body.appendChild(container)
		$(container).append(dom)
		tip.show()
		return tip

	info: (options)->
		if typeof options == "string"
			options = {
				message: options
			}
		options.type = "info"
		cola.NotifyTipManager.show(options)
	warning: (options)->
		if typeof options == "string"
			options = {
				message: options
			}
		options.type = "warning"
		cola.NotifyTipManager.show(options)
	error: (options)->
		if typeof options == "string"
			options = {
				message: options
			}
		options.type = "error"
		cola.NotifyTipManager.show(options)
	success: (options)->
		if typeof options == "string"
			options = {
				message: options
			}
		options.type = "success"
		cola.NotifyTipManager.show(options)

	clear: ()->
		$("#c-notify-tip-container").find(">.notify-tip").each(()->
			cola.widget(@).hide()
		)