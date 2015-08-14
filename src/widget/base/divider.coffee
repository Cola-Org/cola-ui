class cola.Divider extends cola.Widget
	@CLASS_NAME: "divider"
	@ATTRIBUTES:
		content:
			refreshDom: true
			setter: (value)->
				oldValue = @["_content"]
				@["_content"] = value
				delete @["_contentDom"] if oldValue and @["_contentDom"]

				if @_dom
					contentDom = @_getContentDom()
					@get$Dom().html(contentDom) if contentDom
				return

			getter: ()->
				return @_content if @_content
				if @_dom
					childNodes = @_dom.childNodes
					if childNodes.length is 1 and childNodes[0].nodeType is 3
						return cola.util.getTextChildData(@_dom)
					else if childNodes.length
						return @_dom.childNodes
		direction:
			enum: ["vertical", "horizontal",""]
			defaultValue: ""
			setter: (value)->
				oldValue = @["_direction"]
				@["_direction"] = value
				if @_dom and oldValue and oldValue isnt value
					@get$Dom().removeClass(oldValue)
				return

	_getContentDom: ()->
		return @_contentDom if @_contentDom

		content = @get("content")
		return null unless content

		contentDom = null

		if content.getDom
			contentDom = content.getDom()

		else if typeof content is "string"
			contentDom = $.xCreate(
				tagName: "SPAN"
				content: content
			)
			@_content = contentDom

		else if content.nodeType is 1
			contentDom = content

		else if content.constructor == Object.prototype.constructor
			if content.$type
				@_content = cola.widget(content)
				contentDom = @_content.getDom()
			else
				contentDom = $.xCreate(content)


		@_contentDom = contentDom

		return @_contentDom

	_setDom: (dom, parseChild)->
		super(dom, parseChild)
		if @_content
			contentDom = @_getContentDom()
			@get$Dom().append(contentDom) if contentDom.parentNode isnt @_dom


	_doRefreshDom: ()->
		return unless @_dom
		super()
		classNamePool = @_classNamePool


		classNamePool.add(@_direction) if @_direction

		return

	destroy: ()->
		unless @_destroyed
			delete @_content
			super()
		return










