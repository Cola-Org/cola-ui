cola.slotPicker ?= {}
class cola.slotPicker.ZyngaScroller extends cola.Element
	@EVENTS:
		scrolled: null
	constructor: (container, options)->
		self = @
		options ?= {}
		@options = options
		@container = container
		$fly(container).css("position", "relative") if $fly(container).css("position") == "static"
		self.container.style.overflowX = "hidden"
		self.container.style.overflowY = "hidden"

		self.content = $fly(container).children(":first")[0]
		self.render = options.render

		options.scrollingX = false
		options.scrollingY = true

		options.scrollingComplete = ()->
			cola.util.delay(self, "scrolled", 50, self._scrolled)

		self.scroller = new Scroller((left, top, zoom)->
			self.render(left, top, zoom)
			cola.util.delay(self, "scrolled", 50, self._scrolled)
			self._scrolling(left, top, zoom)
			return
		, options)

		@_bindEvents()

	scrollSize: (dir, container, content)->
		translate = cola.Fx.getElementTranslate(content)
		cola.Fx.cancelTranslateElement(content)

		if dir == "h"
			result = Math.max(container.scrollWidth, content.clientWidth)
		else
			result = Math.max(container.scrollHeight, content.clientHeight)

		cola.Fx.translateElement(content, translate.left, translate.top)
		return result

	update: ()->
		unless @_contentInited
			content = @content = @container.children[0]
			@_contentInited = !!@content

		return unless @content
		viewWidth = @container.clientWidth
		viewHeight = @container.clientHeight
		scrollWidth = @scrollSize("h", @container, @content)
		scrollHeight = @scrollSize("v", @container, @content)
		@scroller.options.scrollingX = false
		@scroller.options.scrollingY = true
		@scrollHeight = scrollHeight
		@scroller.setDimensions(viewWidth, viewHeight, scrollWidth, scrollHeight)

		if @snapHeight || @snapWidth
			@scroller.setSnapSize(@snapWidth || 100, @snapHeight || 100)

		scrollTop = @defaultScrollTop
		scrollLeft = @defaultScrollLeft

		if scrollTop != undefined || scrollLeft != undefined
			@scroller.scrollTo(scrollLeft, scrollTop, false)
			@defaultScrollTop = undefined
			@defaultScrollLeft = undefined
		return @

	_scrolled: ()->
		value = @getValues()
		oldValue = @_scrollTop
		return if oldValue is value.top
		top = Math.round(value.top / 60) * 60
		@_scrollTop = top
		@scrollTo(value.left, top, true)
		@fire("scrolled", @, {left: value, top: top})
		return

	_scrolling: ()->

	_bindEvents: ()->
		self = @
		handleStart = @_handleStart = ()->
			event = window.event
			if event.target.tagName.match(/input|select/i)
				event.stopPropagation()
				return
			if cola.os.mobile
				self.scroller.doTouchStart(event.touches, event.timeStamp)
			else
				self.scroller.doTouchStart([{
					pageX: event.pageX,
					pageY: event.pageY
				}], event.timeStamp)
			self._touchStart = true
			event.preventDefault()
			return

		handleMove = @_handleMove = ()->
			event = window.event
			return unless self._touchStart
			if cola.os.mobile
				self.scroller.doTouchMove(event.touches, event.timeStamp)
			else
				self.scroller.doTouchMove([{
					pageX: event.pageX
					pageY: event.pageY
				}], event.timeStamp)
			return

		handleEnd = @_handleEnd = ()->
			return unless self._touchStart
			event = window.event
			self.scroller.doTouchEnd(event.timeStamp)
			self._touchStart = false
			return

		handleMouseWheel = @_handleMouseWheel = (event)->
			self.scroller.scrollBy(0, event.wheelDelta, true)
			return
		self.container.addEventListener("mousewheel", handleMouseWheel)
		if cola.os.mobile
			$(self.container).on("touchstart", handleStart).on("touchmove", handleMove).on("touchend", handleEnd)
		else
			$(self.container).on("mousedown", handleStart).on("mousemove", handleMove).on("mouseup", handleEnd)
		return @

	scrollTo: (left, top, animate)->
		@scroller.scrollTo(left, top, animate)
		return

	scrollBy: (left, top)->
		@scroller.scrollBy(left, top, animate)
		return

	getValues: ()->
		return @scroller.getValues()

	destroy: ()->
		cola.util.cancelDelay(@, "scrolled")
		if cola.os.mobile
			$(@container).off("touchstart", @_handleStart).off("touchmove", @_handleMove).off("touchend",
				@_handleEnd)
		else
			$(@container).off("mousedown", @_handleStart).off("mousemove", @_handleMove).off("mouseup", @_handleEnd)
		delete @container
		delete @content
		return

class cola.AbstractSlotList extends cola.RenderableElement
	_resetDimension: ()->
		return
	_setDom: (dom)->

	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_resetDimension()
		return

	getDom: ()->
		return null if @_destroyed
		unless @_dom
			dom = @_dom = @_createDom()
			@_setDom(dom)
			arg =
				dom: dom, returnValue: null
			@fire("createDom", @, arg)

		return @_dom

	get$Dom: ()->
		return null if @_destroyed
		@_$dom ?= $(@getDom())

		return @_$dom

	refresh: ()->
		return @ unless @_dom
		@_refreshDom()

		arg =
			dom: @_dom, returnValue: null
		@fire("refreshDom", @, arg)

		return @

	appendTo: (dom)->
		$(dom).append(@_dom) if dom and @getDom()
		return @

	remove: ()->
		@get$Dom().remove() if @_dom
		return @

class cola.SlotList extends cola.AbstractSlotList
	@CLASS_NAME: "list"
	@ATTRIBUTES:
		viewItemCount:
			type: "number"
			refreshDom: true
			defalutValue: 3

		items:
			refreshDom: true
			setter: (value)->
				oldValue = @_items;
				@_oldItems = oldValue || []
				@_items = value
				this._itemChanged = true if this._dom

		value:
#			refreshDom: true
			getter: ()->
				items = @doGetItems()
				currentIndex = @_currentIndex || 0;
				if items && currentIndex != undefined
					return items[currentIndex]

				return undefined

			setter: (value)->
				items = @doGetItems()
				oldIndex = @_currentIndex
				newIndex = items.indexOf(value)
				return if newIndex == oldIndex
				@_currentIndex = items.indexOf(value)
				@syncScroll() if @_dom

		defaultValue: null
		currentIndex:
			type: "number"
			refreshDom: true
			defaultValue: 0
		formatter: null
	@EVENTS:
		onValueChange: null

	doTouchStart: (touches, timeStamp)->
		cola.slotPicker._activePicker = @
		@_scroller?.doTouchMove(touches, timeStamp)
		return

	doTouchMove: (touches, timeStamp)->
		@_scroller?.doTouchMove(touches, timeStamp)
		return

	doTouchEnd: (timeStamp)->
		@_scroller?.doTouchEnd(timeStamp)
		cola.slotPicker._activePicker = null
		return

	syncScroll: ()->
		return unless this._zyngaScroller
		doms = @_doms
		value = @get("value")

		if value != undefined
			item = $fly(doms.body).find(" > .slot-item")[@_currentIndex]
			if item
				this._disableScrollEvent = true;
				this._zyngaScroller.scrollTo(0, item.offsetTop - 60, false)
				this._disableScrollEvent = false;


	_createDom: ()->
		list = @
		@_doms ?= {}
		doms = @_doms
		dom = $.xCreate({
			class: @constructor.CLASS_NAME
			content: [{
				class: "items-wrap",
				contextKey: "body"
			}]
		}, @_doms)

		viewItemCount = this._viewItemCount || 3

		dummyItemCount = Math.floor(viewItemCount / 2)
		i = 0
		while i < dummyItemCount
			itemDom = document.createElement("div")
			itemDom.className = "dummy-item"
			doms.body.appendChild(itemDom)
			i++

		items = list.doGetItems()
		formatter = this._formatter or (index, value)->  return value

		i = 0
		while i < items.length
			itemDom = document.createElement("div")
			itemDom.className = "slot-item"
			itemDom.innerHTML = formatter(i, items[i])
			doms.body.appendChild(itemDom)
			i++

		i = 0
		while i < dummyItemCount
			itemDom = document.createElement("div")
			itemDom.className = "dummy-item"
			doms.body.appendChild(itemDom)
			i++
		return dom

	_setDom: (dom)->
		list = @
		items = @doGetItems()
		defaultValue = @_defaultValue
		scrollTop = 0

		if defaultValue != undefined
			index = @_currentIndex = items.indexOf(defaultValue)

			item = $fly(@_doms.body).find(" > *")[index]
			position = $fly(item).position()
			scrollTop = position.top

		list._zyngaScroller = new cola.slotPicker.ZyngaScroller(dom, {
			render: cola.util.getScrollerRender(@_doms.body)
		})

		list._zyngaScroller.on("scrolled", (self, arg)->
			itemIndex = Math.round(arg.top / 60)
			position = itemIndex * 60

			if position == arg.top
				list._currentIndex = Math.abs(itemIndex)
				value = list.get("value")
				list.fire("onValueChange", list, {
					currentIndex: Math.abs(itemIndex),
					value: value
				})
		)
		return

	_updateScroller: ()->
		if @_scroller
			rect = @_dom.getBoundingClientRect()
			dom = @_dom
			doms = @_doms

			@_scroller.setPosition(rect.left + dom.clientLeft, rect.top + dom.clientTop)
			@_scroller.setDimensions(dom.clientWidth, dom.clientHeight, doms.body.offsetWidth, doms.body.offsetHeight)

	_refreshItemDoms: ()->
		items = @doGetItems()
		doms = @_doms
		viewItemCount = this._viewItemCount || 3

		dummyItemCount = Math.floor(viewItemCount / 2)
		formatter = @_formatter || (index, value)-> return value

		nodeLength = doms.body.children.length

		finalLength = items.length + dummyItemCount * 2
		if finalLength > nodeLength
			refDom = doms.body.children[nodeLength - dummyItemCount]
			insertSize = finalLength - nodeLength
			i = 0
			while i < insertSize
				itemDom = document.createElement("div")
				itemDom.className = "slot-item"
				doms.body.insertBefore(itemDom, refDom)
				i++
		else if finalLength < nodeLength
			removeSize = nodeLength - finalLength
			i = 0
			while i < removeSize
				$fly(doms.body.children[finalLength - dummyItemCount]).remove();
				i++
		i = 0
		while i < items.length
			itemDom = doms.body.children[i + 1]
			itemDom.className = "slot-item"
			itemDom.innerHTML = formatter(i, items[i])
			i++
		this._itemChanged = false

	_doRefreshDom: ()->
		return unless @_dom
		list = @

		@_refreshItemDoms()

		if list._zyngaScroller
			list._zyngaScroller.update()
			list.syncScroll()
#		@_updateScroller()




	doGetItems: ()->
		return @_items || []

class cola.RangeSlotList extends cola.SlotList
	@ATTRIBUTES:
		range:
			refreshDom: true
			setter: (value)->
				@_oldItems = @doGetItems()
				@_range = value
				@_itemChanged = true if this._dom
				return @
		step:
			defaultValue: 1

	doGetItems: ()->
		range = this._range
		items = []
		if range && range.length == 2
			start = range[0]
			step = this._step
			itemCount = (range[1] - start) / step + 1
			i = 0
			while i < itemCount
				items.push(start + i * step);
				i++
		return items

class cola.MultiSlotPicker extends cola.AbstractSlotList
	@CLASS_NAME: "multi-slot-picker"
	@slotConfigs: []
	@ATTRIBUTES:
		height: null
	_createDom: ()->
		picker = @
		doms = {}
		dom = $.xCreate({
			class: @constructor.CLASS_NAME
			content: [{
				class: "body"
				contextKey: "body"
			}]
		}, doms)

		picker._doms = doms
		picker._slotListMap = {}
		slotConfigs = picker.slotConfigs
		items = []
		slotLists = []
		i = 0
		j = slotConfigs.length

		while i < j
			slotConfig = slotConfigs[i]
			slotName = slotConfig.name

			domContext = {}
			itemDom = $.xCreate({
				class: "slot-picker"
				style:
					webkitBoxFlex: 1
				content: [
					{
						content: slotConfig.unit || ""
						class: "unit"
					}
					{
						class: "slot"
						contextKey: "slot"
						content: [
							{
								class: "mask"
								content: {
									class: "bar"
								}
							}
						]
					}
				]
			}, domContext)

			slotDom = domContext.slot

			if slotConfig.$type == "Range"

				list = new cola.RangeSlotList({
					range: slotConfig.range
					formatter: slotConfig.formatter
					defaultValue: slotConfig.defaultValue
					onValueChange: (self, arg)->
						value = arg.value

						picker.setSlotValue(self._slotIndex, value)
				})
			else
				list = new cola.SlotList({
					items: slotConfig.items
					formatter: slotConfig.formatter
					defaultValue: slotConfig.defaultValue
					onValueChange: (self, arg)->
						value = arg.value

						picker.setSlotValue(self._slotIndex, value)
				})
			list._slotIndex = i
			picker._slotListMap[slotName] = list
			list.appendTo(slotDom)

			doms.body.appendChild(itemDom)
			slotLists.push(list)
			items.push(slotDom)

			i++
		picker._slotLists = slotLists
		picker._items = items
		return dom

	constructor: (config)->
		@initSlotConfigs() if @slotConfigs
		super(config)

	initSlotConfigs: ()->
		slotConfigs = this.slotConfigs
		slotMap = this._slotMap = {}
		values = this._values = []
		i = 0
		j = slotConfigs.length

		while i < j
			config = slotConfigs[i]
			name = config.name
			config.class = config.className || "slot"
			config.range = config.range || [null, null]
			slotMap[name] = config
			values[i] = config.defaultValue
			i++

		return

	getSlotValue: (slotIndex)->
		slotIndex = @getSlotIndexByName(slotIndex) if typeof slotIndex == "string"
		return @_values[slotIndex]

	setSlotValue: (slotIndex, value)->
		picker = @
		slotIndex = picker.getSlotIndexByName(slotIndex) if typeof slotIndex == "string"
		return if slotIndex < 0

		if value != null
			config = picker.slotConfigs[slotIndex]
			range = config.range || []
			minValue = range[0]
			maxValue = range[1]

			value = parseInt(value, 10)

			value = config.defaultValue || 0 if isNaN(value)
			if maxValue != null && value > maxValue
				value = maxValue
			else if minValue != null && value < minValue
				value = minValue

		@_values[slotIndex] = value
		@_slotLists[slotIndex].set("value", value) if @_dom && @_slotLists

#		cola.util.delay(picker, "$refreshDelayTimerId", 50, picker.refresh)

	getSlotText: (slotIndex)->
		picker = this;

		slotIndex = picker.getSlotIndexByName(slotIndex) if typeof slotIndex == "string"


		return "" if slotIndex < 0

		config = picker.slotConfigs[slotIndex]
		text = picker.getSlotValue(slotIndex)

		if text == null
			if config.digit > 0
				text = '';
				i = 0
				while i < config.digit
					text += "&nbsp;"
					i++
			else
				text = "&nbsp;";

		else
			num = text
			negative = (num < 0)
			text = Math.abs(num) + ""

			if config.digit > 0 && text.length < config.digit
				i = text.length
				while i <= config.digit - 1
					text = '0' + text
					i++
			text = (negative ? '-': '') + text;

		return text

	getText: ()->
		picker = this
		slotConfigs = picker.slotConfigs
		text = ""
		i = 0
		while i < slotConfigs.length
			config = slotConfigs[i]
			text += config.prefix || ""
			text += picker.getSlotText(i)
			text += config.suffix || ""
			i++
		return text

	getSlotIndexByName: (name)->
		unless @_slotMap
			@initSlotConfigs()
		config = @_slotMap[name]
		return if config then @slotConfigs.indexOf(config) else -1

	doOnResize: ()->
		picker = @
		items = picker._items || []
		dom = picker._dom
		flexes = []
		for item,index in items
			width = picker.slotConfigs[index].width || 90
			flexes.push(width)
		viewWidth = dom.clientWidth
		columnCount = flexes.length
		totalFlex = 0

		i = 0
		while i < columnCount
			flex = flexes[i]
			totalFlex += parseInt(flex, 10) || 90
			i++

		unitWidth = viewWidth / totalFlex
		lastWidth = 0
		i = 0
		while i < columnCount
			if i != columnCount - 1
				$fly(items[i]).css({width: Math.floor(unitWidth * flexes[i])})
				lastWidth += Math.floor(unitWidth * flexes[i])
			else
				$fly(items[i]).css({width: viewWidth - lastWidth})
			i++
	updateItems: ()->
		for list in @_slotLists
			list.refresh()
		return @

now = new Date()
currentYear = now.getFullYear()
currentMonth = now.getMonth() + 1
currentDate = now.getDate()
currentHours = now.getHours()
currentMinutes = now.getMinutes()
currentSeconds = now.getSeconds()

dateTimeSlotConfigs =
	year:
		$type: "Range"
		name: "year"
		range: [currentYear - 50, currentYear + 50]
		defaultValue: currentYear
		unit: "年"
		width: 120
	month:
		$type: "Range"
		name: "month"
		range: [1, 12]
		defaultValue: currentMonth
		unit: "月"
		width: 90

	date:
		$type: "Range"
		name: "date"
		range: [1, 31]
		defaultValue: currentDate
		unit: "日"
		width: 90

	hours:
		$type: "Range"
		name: "hours"
		range: [0, 23]
		defaultValue: currentHours
		unit: "时"
		width: 90

	minutes:
		$type: "Range"
		name: "minutes"
		range: [0, 59]
		defaultValue: 0
		unit: "分"
		width: 90

	seconds:
		$type: "Range"
		name: "seconds"
		range: [0, 59]
		defaultValue: 0
		unit: "秒"
		width: 90
slotAttributeGetter = (attr)->
	return this.getSlotValue(attr)
slotAttributeSetter = (value, attr)->
	this.setSlotValue(attr, value)
dateTypeConfig =
	year: [dateTimeSlotConfigs.year]
	month: [dateTimeSlotConfigs.year, dateTimeSlotConfigs.month]
	date: [dateTimeSlotConfigs.year, dateTimeSlotConfigs.month, dateTimeSlotConfigs.date]
	time: [dateTimeSlotConfigs.hours, dateTimeSlotConfigs.minutes, dateTimeSlotConfigs.seconds]
	dateTime: [dateTimeSlotConfigs.year, dateTimeSlotConfigs.month, dateTimeSlotConfigs.date, dateTimeSlotConfigs.hours,
	           dateTimeSlotConfigs.minutes, dateTimeSlotConfigs.seconds]
	hours: [dateTimeSlotConfigs.hours]
	minutes: [dateTimeSlotConfigs.hours, dateTimeSlotConfigs.minutes]
	dateHours: [dateTimeSlotConfigs.year, dateTimeSlotConfigs.month, dateTimeSlotConfigs.date,
	            dateTimeSlotConfigs.hours]
	dateMinutes: [dateTimeSlotConfigs.year, dateTimeSlotConfigs.month, dateTimeSlotConfigs.date,
	              dateTimeSlotConfigs.hours, dateTimeSlotConfigs.minutes]
cola.mobile ?= {}

class cola.mobile.DateTimePicker extends cola.MultiSlotPicker
	@CLASS_NAME: "multi-slot-picker"
	@slotConfigs: []
	@ATTRIBUTES:
		type:
			enum: ["year", "month", "date", "time", "datetime", "hours", "minutes", "dateHours", "dateMinutes"]
			defaultValue: "date"
		year:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		month:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		date:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		hours:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		minutes:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		seconds:
			getter: slotAttributeGetter
			setter: slotAttributeSetter
		value:
			getter: ()->
				year = @getSlotValue("year") || 1980
				month = (@getSlotValue("month") - 1) || 0
				date = @getSlotValue("date") || 1
				hours = @getSlotValue("hours") || 0
				minutes = @getSlotValue("minutes") || 0
				seconds = @getSlotValue("seconds") || 0
				return new Date(year, month, date, hours, minutes, seconds)

			setter: (d)->
				year = 0
				month = 1
				date = 1
				hours = 0
				minutes = 1
				seconds = 1
				if d
					year = d.getFullYear()
					month = d.getMonth() + 1
					date = d.getDate()
					hours = d.getHours()
					minutes = d.getMinutes()
					seconds = d.getSeconds()

				@setSlotValue("year", year)
				@setSlotValue("month", month)
				@setSlotValue("date", date)
				@setSlotValue("hours", hours)
				@setSlotValue("minutes", minutes)
				@setSlotValue("seconds", seconds)

	_createDom: ()->
		picker = this
		type = picker._type
		configs = dateTypeConfig[type]
		picker.slotConfigs = configs
		picker.initSlotConfigs()

		dom = super()

		if picker._slotMap["date"]
			year = picker.getSlotValue("year")
			month = picker.getSlotValue("month")
			dayCount = XDate.getDaysInMonth(year, month - 1)
			picker.refreshSlotList("date", {range: [1, dayCount]})
		return dom
	_doRefreshDom: ()->
		return unless @_dom
		super()
		@_classNamePool.add("multi-slot-picker")
		return
	refreshSlotList: (slotName, value)->
		picker = this
		slotList = picker._slotListMap[slotName]
		slotList.set(value) if slotList and value != undefined
		return @


	setSlotValue: (slotIndex, value)->
		picker = this
		if value == null
			super(slotIndex, value)
			return

		if typeof slotIndex == "number"
			config = picker.slotConfigs[slotIndex]
			slotName = config.name if config
		else
			slotName = slotIndex
			slotIndex = picker.getSlotIndexByName(slotName)

		return if !slotName || !picker._slotMap[slotName]

		if !picker._slotMap["date"]
			super(slotIndex, value)
			return
		dateSlotIndex = picker.getSlotIndexByName("date")
		date = picker._values[dateSlotIndex]
		newDate = 0
		year = if (slotIndex == 0) then  value else  picker._values[0]
		month = if (slotIndex == 1) then  value else picker._values[1]
		dayCount = XDate.getDaysInMonth(year, month - 1)

		if slotName == "year" || slotName == "month"
			picker.refreshSlotList("date", {range: [1, dayCount]})

		newDate = dayCount if date >= 28 and date > dayCount

		if newDate
			if slotName == "year" || slotName == "month"
				picker.setSlotValue("date", newDate)
				picker._slotListMap[slotName]._value = newDate
				picker.refreshSlotList("date")
				super(slotIndex, value)
			else
				super(slotIndex, newDate)
		else
			super(slotIndex, value)

cola.mobile.showDateTimePicker = (options)->
	timerLayer = cola.mobile._cacheDateTimer
	if timerLayer
		if options.type isnt timerLayer._picker.get("type")
			timerLayer.destroy()
			cola.mobile._cacheDateTimer = null
			timerLayer = null

	unless timerLayer
		picker = new cola.mobile.DateTimePicker({type: options.type || "date"})
		timerLayer = new cola.Layer({
			animation: "slide down"
			vertical: true
			horizontal: true
			class: "date-timer"
		})
#		timerLayer.set("content",picker)
		timerLayer._picker = picker

		layerDom = timerLayer.getDom()
		layerDom.appendChild(picker.getDom())
		actionDom = $.xCreate({
			class: "actions ui two fluid bottom attached buttons"
			content: [
				{
					class: "ui button"
					content: "取消"
					click: ()->
						cola.commonDimmer.hide()
						timerLayer.hide()
				}
				{
					class: "ui positive button"
					content: "确定"
					click: ()->
						cola.commonDimmer.hide()
						timerLayer.hide()
						timerLayer._hideCallback?(picker)
						delete timerLayer._hideCallback
				}
			]
		})
		layerDom.appendChild(actionDom)
		$fly(layerDom).css("top", "auto")
		window.document.body.appendChild(layerDom)
		cola.mobile._cacheDateTimer = timerLayer
	timerLayer = cola.mobile._cacheDateTimer
	options ?= {}
	if options.onHide
		timerLayer._hideCallback = options.onHide
		delete options.onHide


	cola.commonDimmer.show()
	timerLayer.show(()->
		timerLayer._picker.set(options)
		timerLayer._picker.updateItems()
	)
	return timerLayer._picker








