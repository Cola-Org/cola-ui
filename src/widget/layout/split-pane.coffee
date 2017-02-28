class cola.SplitPane extends cola.Widget
	@tagName: "c-split-pane"
	@CLASS_NAME: "ui split-pane"

	@attributes:
		direction:
			refreshDom: true
			enum: ["left", "right", "top", "bottom"]
			defaultValue: "top"
		position:
			defaultValue: 100

	_doRefreshDom: ()->
		return unless @_dom
		super()

		@_setPosition(@_position)
		return

	_setPosition: (position)->
		direction = this._direction
		$sideDom = $(@_doms.sideDom)
		$mainDom = $(@_doms.mainDom)
		$splitterDom = $(@_doms.splitter)

		if isFinite(position)
			mainPos = position + 4;
		else
			mainPos = "calc(" + position + " + 4px)";

		switch direction
			when "left"
				$sideDom.css({width: position})
				$splitterDom.css({left: position})
				$mainDom.css({left: mainPos})
			when "right"
				$sideDom.css({width: position})
				$splitterDom.css({right: position})
				$mainDom.css({right: mainPos})
			when "top"
				$sideDom.css({height: position})
				$splitterDom.css({top: position})
				$mainDom.css({top: mainPos})
			when "bottom"
				$sideDom.css({height: position})
				$splitterDom.css({bottom: position})
				$mainDom.css({bottom: mainPos})


	_initDom: (dom)->
		super(dom)
		$dom = $(dom)
		doms = @_doms
		unless doms.splitter
			doms.splitter = $.xCreate({
				tagName: "div", class: "splitter"
			})
			$($dom.find(">.pane")[1]).before(doms.splitter)
		$dom.addClass("fixed-" + this._direction)

		$(doms.sideDom).addClass("side-pane")
		$(doms.mainDom).addClass("main-pane")

		pagePos = (event, pos)->
			attrName = "page" + pos
			if event[attrName] != undefined
				return event[attrName];
			else if event.originalEvent[attrName] != undefined
				return event.originalEvent[attrName];
			else if event.originalEvent.touches
				return event.originalEvent.touches[0][attrName]


		pageXof = (event)-> pagePos(event, "X")
		pageYof = (event)-> pagePos(event, "Y")

		splitPane = this

		minSize = (element, name)-> parseInt($(element).css('min-' + name), 10) || 0
		minWidth = (element)-> minSize(element, "width")
		minHeight = (element)-> minSize(element, "height")

		fixedVerticalHandler = (pageX)->
			sideMinWidth = minWidth(doms.sideDom)
			sideMaxWidth = dom.offsetWidth - minWidth(doms.mainDom) - doms.splitter.offsetWidth
			leftOffset = doms.splitter.offsetLeft - pageX;
			return (event)->
				event.preventDefault?()
				left = Math.min(Math.max(sideMinWidth, leftOffset + pageXof(event)), sideMaxWidth)
				splitPane._setPosition(left)

		fixedHorizontalHandler = (pageY)->
			sideMinHeight = minHeight(doms.sideDom)
			sideMaxHeight = dom.offsetHeight - minHeight(doms.mainDom) - doms.splitter.offsetHeight
			topOffset = doms.splitter.offsetTop - pageY;
			return (event)->
				event.preventDefault?()
				top = Math.min(Math.max(sideMinHeight, topOffset + pageYof(event)), sideMaxHeight)
				splitPane._setPosition(top)

		createMouseMove = ($splitPane, pageX, pageY)->
			direction = splitPane._direction

			if direction is "left" or direction is "right"
				return fixedVerticalHandler(pageX)
			else
				return fixedHorizontalHandler(pageY)

		$(doms.splitter).on('mousedown', ()->
			event.preventDefault();
			$splitter = $(this);
			$splitPane = $splitter.parent();
			$splitter.addClass('dragged');
			moveEventHandler = createMouseMove($splitPane, pageXof(event), pageYof(event));
			$(document).on('mousemove', moveEventHandler);
			$(document).one('mouseup', (event)->
				$(document).off('mousemove', moveEventHandler);
				$splitter.removeClass('dragged touch');
			);
		)

		return @

	destroy: ()->
		return if @_destroyed
		super()

	_parseDom: (dom)->
		@_doms ?= {}
		$dom = $(dom)
		panes = $dom.find(">.pane")
		sideIndex = 0
		mainIndex = 1
		unless @_direction is "left" or @_direction is "top"
			sideIndex = 1
			mainIndex = 0

		@_doms.sideDom = panes[sideIndex]
		@_doms.mainDom = panes[mainIndex]
		splitter = $dom.find(">.splitter")

		if splitter.length then @_doms.splitter = splitter[0]
		return

cola.registerWidget(cola.SplitPane)