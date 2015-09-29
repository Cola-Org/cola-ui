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

		settings:
			info:
				title: cola.resource("cola.messageBox.info.title")
				icon: "blue info icon"
			warning:
				title: cola.resource("cola.messageBox.warning.title")
				icon: "yellow warning sign icon"
			error:
				title: cola.resource("cola.messageBox.error.title")
				icon: "red warning sign icon"
			question:
				title: cola.resource("cola.messageBox.question.title")
				icon: "black help circle icon"
		class: "standard"
		dialogMode: true
		level:
			WARNING: "warning"
			ERROR: "error"
			INFO: "info"
			QUESTION: "question"

		_getAnimation: ()->
			return  if messageBox.dialogMode then "scale" else "slide up"

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
			animation = messageBox._getAnimation()
			css = {
				zIndex: cola.floatWidget.zIndex()
			}
			$dom = $(messageBox._dom)

			if messageBox.dialogMode
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
			messageBox._executeCallback("Approve")
			messageBox._doHide()
			return

		_doDeny: ()->
			messageBox._executeCallback("Deny")
			messageBox._doHide()
			return

		_doHide: ()->
			$(messageBox._dom).transition(messageBox._settings.animation)
			cola.commonDimmer.hide()
			messageBox._executeCallback("Hide")
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

			oldClassName = $dom.attr("_class")
			className = options.class or messageBox.class
			if oldClassName isnt className
				$dom.removeClass(oldClassName) if oldClassName
				$dom.addClass(className).attr("_class", className)

			doms = messageBox._doms
			isAlert = options.mode is "alert"
			$(doms.actions).toggleClass("hidden", isAlert)
			$(doms.close).toggleClass("hidden", !isAlert)
			$(doms.description).html(options.content)
			$(doms.title).text(options.title)

			doms.icon.className = options.icon
			messageBox._doShow()
			return @
	_getClassName: ()->
		return if messageBox.dialogMode then "desktop" else "mobile layer"
	createMessageBoxDom = ()->
		messageBox._settings = {
			dialogMode: messageBox.dialogMode
			className: if messageBox.dialogMode then "desktop" else "mobile layer"
			animation: if messageBox.dialogMode then "scale" else "slide up"
		}
		doms = {}
		dom = $.xCreate(
			{
				tagName: "Div"
				class: "ui #{messageBox._settings.className} message-box transition hidden"
				contextKey: "messageBox"
				content: {
					class: "content-container "
					contextKey: "contentContainer"
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
			class: "actions #{if messageBox._settings.dialogMode then "" else  "ui buttons two fluid top attached"}"
			contextKey: "actions"
			content: [
				{
					tagName: "div"
					contextKey: "no"
					content: cola.resource("cola.message.deny")
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
							content: cola.resource("cola.message.approve")
							contextKey: "yesCaption"
						}
					]
				}
			]
		}, doms)

		if messageBox._settings.dialogMode then doms.contentContainer.appendChild(actionsDom) else $(doms.content).before(actionsDom)
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
	cola.MessageBox = messageBox