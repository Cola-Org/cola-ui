#cola.os.mobile = true
do()->
	cola.commonDimmer =
		show: ()->
			_dimmerDom = cola.commonDimmer._dom
			unless _dimmerDom
				_dimmerDom = $.xCreate({
					tagName: "Div"
					class: "ui dimmer sys-dimmer"
					contextKey: "dimmer"
				})
				window.document.body.appendChild(_dimmerDom)
				cola.commonDimmer._dom = _dimmerDom
			$(_dimmerDom).addClass("active")
			return

		hide: ()->
			$(cola.commonDimmer._dom).removeClass("active")

	messageBox =
		animation: if cola.device.phone then "slide up" else "scale"
		settings:
			info:
				title: "消息"
				icon: "blue info icon"
			warning:
				title: "警告"
				icon: "yellow warning sign icon"
			error:
				title: "错误"
				icon: "red warning sign icon"
			question:
				title: "确认框"
				icon: "black help circle icon"
		ui: "standard"
		level:
			WARNING: "warning"
			ERROR: "error"
			INFO: "info"
			QUESTION: "question"

		_executeCallback: (name)->
			_eventName = "_on#{name}"
			return unless messageBox[_eventName]
			setTimeout(()->
				config = messageBox[_eventName]
				if typeof config == "function"
					config.apply(null, [])
				messageBox[_eventName] = null
			, 0)
			return

		_doShow: ()->
			animation = messageBox.animation
			css = {
				zIndex: cola.floatWidget.zIndex()
			}
			$dom = $(messageBox._dom)

			unless cola.device.phone
				width = $dom.width()
				height = $dom.height()

				pWidth = $(window).width()
				pHeight = $(window).height()
				css.left = (pWidth - width) / 2
				css.top = (pHeight - height) / 2

			$dom.css(css)

			$dom.transition(animation)

			cola.commonDimmer.show()

		_doApprove: ()->
			messageBox._executeCallback("approve")
			messageBox._doHide()
			return

		_doDeny: ()->
			messageBox._executeCallback("deny")
			messageBox._doHide()
			return

		_doHide: ()->
			$(messageBox._dom).transition(messageBox.animation)
			cola.commonDimmer.hide()
			messageBox._executeCallback("hide")
			return

		getDom: ()->
			createMessageBoxDom() unless messageBox._dom
			return messageBox._dom

		show: (options)->
			dom = messageBox.getDom()
			settings = messageBox.settings
			level = options.level || messageBox.level.INFO

			$dom = $(dom)
			options.title ?= settings[level].title
			options.icon ?= settings[level].icon

			messageBox._onDeny = options.onDeny
			messageBox._onApprove = options.onApprove
			messageBox._onHide = options.onHide
			$dom.removeClass("warning error info question").addClass(level);

			oldUI = $dom.attr("_ui")
			ui = options.ui or messageBox.ui
			if oldUI isnt ui
				$dom.removeClass(oldUI) if oldUI
				$dom.addClass(ui).attr("_ui", ui)
			
			doms = messageBox._doms

			isAlert = options.mode is "alert"
			$(doms.actions).toggleClass("hidden", isAlert)
			$(doms.close).toggleClass("hidden", !isAlert)
			$(doms.description).html(options.content)
			$(doms.title).text(options.title)

			doms.icon.className = options.icon
			messageBox._doShow()
			return @

	createMessageBoxDom = ()->
		doms = {}
		dom = $.xCreate(
			{
				tagName: "Div"
				class: "ui #{if cola.device.phone then "mobile layer" else "desktop"} message-box transition hidden"
				contextKey: "messageBox"
				content: {
					class: "content-container "
					contextKey:"contentContainer"
					content: [
						{
							tagName: "div"
							class: "header"
							content: [
								{
									tagName: "div"
									class: "caption"
									contextKey: "title"
								}
								{
									tagName: "div"
									contextKey: "close"
									class: " close-btn"
									click: messageBox._doHide
									content: {
										tagName: "i"
										class: "close icon"
									}
								}
							]
						},
						{
							tagName: "div"
							class: "image content"
							contextKey: "content"
							content: [
								{
									tagName: "div"
									class: "image"
									content: {
										tagName: "i"
										class: "announcement icon"
										contextKey: "icon"
										style: {
											"font-size": "4rem"
										}
									}
								}
								{
									tagName: "div"
									class: "description"
									contextKey: "description"
								}
							]
						}
					]
				}
			}, doms)
		actionsDom = $.xCreate({
			tagName: "div"
			class: "actions #{if cola.device.phone then "ui buttons two fluid top attached" else ""}"
			contextKey: "actions"
			content: [
				{
					tagName: "div"
					contextKey: "no"
					content: "取消"
					click: messageBox._doDeny
					class: "ui button"
				}
				{
					tagName: "div"
					contextKey: "yes"
					click: messageBox._doApprove
					class: "ui positive right labeled icon button "
					content: [
						{
							tagName: "i"
							class: "checkmark icon"
						}
						{
							tagName: "span"
							content: "确认"
							contextKey: "yesCaption"
						}
					]
				}
			]
		}, doms)

		if cola.device.phone then $(doms.content).before(actionsDom) else doms.contentContainer.appendChild(actionsDom)
		bodyNode = window.document.body
		if bodyNode then bodyNode.appendChild(dom) else
			$(window).on("load", ()->
				$(window.document.body).append(dom)
			)
		messageBox._dom = dom
		messageBox._doms = doms

		return dom


	cola.alert = (msg, options)->
		settings = {}
		if options
			if typeof options == "function"
				settings.onHide = options
			else
				settings[key] = value for key,value of options
		settings.content = msg
		settings.mode = "alert"
		messageBox.show(settings)
		return @


	cola.confirm = (msg, options)->
		settings = {}
		settings.actions = "block"
		if options
			if typeof options == "function"
				settings.onApprove = options
			else
				settings[key] = value for key,value of options
		settings.content = msg
		settings.level = messageBox.level.QUESTION
		settings.title ?= messageBox.settings.question.title
		settings.icon ?= messageBox.settings.question.icon
		settings.mode = "confirm"
		messageBox.show(settings)
		return @

	messageBox.getDom() if cola.os.mobile
	cola.MessageBox=messageBox