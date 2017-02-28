###
    按钮的抽象类
###
class cola.ToolbarButton extends cola.Widget
	@tagName: "c-toolbar-button"
	@CLASS_NAME: "toolbar-button"
	@attributes:
		caption:
			refreshDom: true
		icon:
			refreshDom: true
			setter: (value)->
				oldValue = @_icon
				@_icon = value
				if oldValue and oldValue isnt value and @_dom and @_doms?.iconDom
					$fly(@_doms.iconDom).removeClass(oldValue)
				return

		iconPosition:
			refreshDom: true
			defaultValue: "left"
			enum: ["left", "right"]

		focusable:
			type: "boolean"
			refreshDom: true
			defaultValue: false

		disabled:
			type: "boolean"
			refreshDom: true
			defaultValue: false
	_initDom: (dom)->
		@_doms = {}
		$(dom).append($.xCreate({
			tagName: "div", contextKey: "innerDom", class: "ui button"
		}, @_doms))

	_refreshIcon: ()->
		return unless @_dom
		icon = @get("icon")
		iconPosition = @get("iconPosition")
		caption = @get("caption")
		$innerDom = $(@_doms.innerDom);
		iconDom = $innerDom.find(">i")
		if @_icon
			unless iconDom.length
				iconDom = $.xCreate({
					tagName: "i", class: "icon"
				})
			pos = if iconPosition is "right" then "append" else "prepend"
			$innerDom[pos](iconDom)
			$(iconDom).addClass(icon)
		else
			$(iconDom).remove()
		return


	_doRefreshDom: ()->
		return unless @_dom
		super()
		$innerDom = $(@_doms.innerDom);
		classNamePool = @_classNamePool
		caption = @_caption
		captionDom = $innerDom.find(".caption")
		if caption
			unless captionDom.length
				captionDom = $.xCreate({
					tagName: "span", class: "caption"
				})
				$innerDom.append(captionDom)
			$(captionDom).text(caption)
		else
			$(captionDom).empty()

		if @get("focusable") then $innerDom.attr("tabindex", "0") else  $innerDom.removeAttr("tabindex")

		@_refreshIcon()
		$innerDom.toggleClass("disabled", @_disabled)
		return
class cola.Toolbar extends cola.Widget
	@tagName: "c-toolbar"
	@CLASS_NAME: "ui toolbar"
cola.registerWidget(cola.ToolbarButton)
cola.registerWidget(cola.Toolbar)

