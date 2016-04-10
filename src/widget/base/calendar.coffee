do->
	getCellPosition = (event) ->
		element = event.srcElement || event.target
		row = -1
		column = -1

		while element && element != element.ownerDocument.body
			tagName = element.tagName.toLowerCase()
			if tagName == "td"
				row = element.parentNode.rowIndex
				column = element.cellIndex
				break
			element = element.parentNode

		if element != element.ownerDocument.body
			return {
			row: row
			column: column
			element: element
			}
		return null

	cola.calendar ?= {}

	class cola.calendar.DateGrid extends cola.RenderableElement
		@ATTRIBUTES:
			calendar: null
			columnCount:
				type: "number"
				defaultValue: 1
			rowCount:
				type: "number"
				defaultValue: 1
			cellClassName: null
			selectedCellClassName: ""
			rowClassName: null
			tableClassName: null

		@EVENTS:
			cellClick: null
			refreshCellDom: null

		_createDom: ()->
			picker = @
			columnCount = @_columnCount
			rowCount = @_rowCount
			@_doms ?= {}
			dom = $.xCreate({
				tagName: "table"
				cellSpacing: 0
				class: "#{picker._className || ""} #{picker._tableClassName || ""}"
				content: {
					tagName: "tbody",
					contextKey: "body"
				}
			}, @_doms)

			i = 0
			while i < rowCount
				tr = document.createElement("tr")
				j = 0
				while j < columnCount
					td = document.createElement("td")
					td.className = @_cellClassName if @_cellClassName
					@doRenderCell(td, i, j)
					tr.appendChild(td)
					j++
				tr.className = @_rowClassName if @_rowClassName
				@_doms.body.appendChild(tr)
				i++

			$fly(dom).on("click", (event)->
				position = getCellPosition(event)
				if position and position.element
					return if position.row >= picker._rowCount
					picker.fire("cellClick", picker, position)
			)

			return dom

		doFireRefreshEvent: (eventArg) ->
			@fire("refreshCellDom", @, eventArg)
			return @

		refreshGrid: ()->
			picker = @
			dom = @_doms.body
			columnCount = @_columnCount
			rowCount = @_rowCount
			lastSelectedCell = @_lastSelectedCell

			if lastSelectedCell
				$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
				@_lastSelectedCell = null

			i = 0
			while i < rowCount
				rows = dom.rows[i]
				j = 0
				while j < columnCount
					cell = rows.cells[j]
					cell.className = picker._cellClassName if picker._cellClassName
					eventArg =
						cell: cell
						row: i
						column: j

					@doFireRefreshEvent(eventArg)

					@doRefreshCell(cell, i, j) if eventArg.processDefault != false
					j++
				i++
			return @

		setSelectionCell: (row, column)->
			picker = this
			lastSelectedCell = @_lastSelectedCell
			row = null
			column = null
			unless @_dom
				@_selectionPosition = {row: row, column: column}
				return @
			if lastSelectedCell
				$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
				@_lastSelectedCell = null
			tbody = picker._doms.body
			if tbody.rows[row]
				cell = tbody.rows[row].cells[column]
			return @ unless cell
			$fly(cell).addClass(@_selectedCellClassName || "selected")
			@_lastSelectedCell = cell
			return @
		getYMForState: (cellState)->
			month = @_month
			year = @_year
			if cellState.type == "prev-month"
				year = if month == 0 then year - 1 else year
				month = if month == 0 then 11 else month - 1
			else if cellState.type == "next-month"
				year = if month == 11 then year + 1 else year
				month = if month == 11 then 0 else month + 1

			return {
			year: year
			month: month
			}

		doFireRefreshEvent: (eventArg)->
			row = eventArg.row
			column = eventArg.column
			if @_state && @_year && @_month
				cellState = @_state[row * 7 + column]
				ym = @getYMForState(cellState)
				eventArg.date = new Date(ym.year, ym.month, cellState.text)
			@fire("refreshCellDom", @, eventArg)
			return @

		doRenderCell: (cell, row, column)->
			label = document.createElement("div")
			label.className = "label"
			cell.appendChild(label)

			return
		getDateCellDom: (date)->
			value = new XDate(date).toString("yyyy-M-d")
			return $(@_dom).find("td[c-date='#{value}']")

		doRefreshCell: (cell, row, column) ->
			state = @_state
			return unless state

			cellState = state[row * 7 + column]
			$fly(cell).removeClass("prev-month next-month").addClass(cellState.type).find(".label").html(cellState.text)
			ym = @getYMForState(cellState)
			$fly(cell).attr("c-date", "#{ym.year}-#{ym.month + 1}-#{cellState.text}")
			if cellState.type == "normal"
				if @_year == @_calendar._year && @_month == @_calendar._month && cellState.text == @_calendar._monthDate
					$fly(cell).addClass("selected")
					@_lastSelectedCell = cell

		setState: (year, month)->
			oldYear = @_year
			oldMonth = @_month

			if oldYear != year || oldMonth != month
				@_year = year
				@_month = month

				@_state = getDateTableState(new Date(year, month, 1))

				@refreshGrid()
			@onCalDateChange()

		onCalDateChange: () ->
			return @ unless @_dom

			date = @_calendar._date
			year = @_year
			month = @_month
			if date && year == date.getFullYear() && month == date.getMonth() && date.getDate()
				monthDate = date.getDate()
				state = @_state
				firstDayPosition = state.firstDayPosition
				delta = monthDate + firstDayPosition - 1
				column = delta % 7
				row = Math.floor(delta / 7)

				tbody = @_doms.body
				cell = tbody.rows[row].cells[column]
				$fly(@_lastSelectedCell).removeClass("selected") if @_lastSelectedCell

				$fly(cell).addClass("selected") if cell

				@_lastSelectedCell = cell
			else
				$fly(@_lastSelectedCell).removeClass("selected") if @_lastSelectedCell
				@_lastSelectedCell = null
			return @


	class cola.calendar.SwipePicker extends cola.RenderableElement
		@CLASS_NAME: "ui swipe-picker"
		@ATTRIBUTES:
			calendar: null
		@EVENTS:
			change: null
		createDateTable: (dom)->
			calendar = @_calendar
			dateTable = new cola.calendar.DateGrid({
				rowCount: 6
				columnCount: 7
				calendar: calendar
				tableClassName: "date-table"
				refreshCellDom: (self, arg)->
					calendar.doFireCellRefresh(arg)
				cellClick: (self, arg)->
					element = arg.element
					state = self._state
					return unless element
					cellState = state[arg.row * 7 + arg.column]
					if cellState.type == "prev-month"
						calendar.prevMonth()
					else if cellState.type == "next-month"
						calendar.nextMonth()

					calendar.setDate(cellState.text)
					calendar.fire("change", calendar, {date: calendar._date})
					calendar.fire("cellClick", calendar, {date: calendar._date, element: element})
			})
			dateTable.appendTo(dom)

			return dateTable

		doOnSwipeNext: ()->
			@_calendar.nextMonth()
			return @

		doOnSwipePrev: ()->
			@_calendar.prevMonth()
			return @

		setState: (year, month)->
			@_current.setState(year, month)
			prevY = if month == 0 then year - 1 else year
			prevM = if month == 0 then 11 else month - 1
			@_prev.setState(prevY, prevM)
			nextY = if month == 11 then year + 1 else year
			nextM = if month == 11 then 0 else month + 1
			@_next.setState(nextY, nextM)
			return @

		setDate: ()->
			return @ unless @_dom
			@_current.onCalDateChange()
			@_prev.onCalDateChange()
			@_next.onCalDateChange()
			return @

		_createDom: ()->
			dom = document.createElement("div")
			picker = @
			dom.className = "date-table-wrapper"
			setType = (type)->
				picker["_#{type}"] = @
				return
			@_stack = new cola.Stack({
				change: (self, arg)=>
					cDom = @_current.getDom()
					if arg.prev is cDom.parentNode
						@doNext()
					else
						@doPrev()
			})

			stackDom = @_stack.getDom()
			dom.appendChild(stackDom)

			@_current = @createDateTable(@_stack._currentItem)
			@_current.setType = setType
			@_current.setType("current")

			@_next = @createDateTable(@_stack._nextItem)
			@_next.setType = setType
			@_next.setType("next")

			@_prev = @createDateTable(@_stack._prevItem)
			@_prev.setType = setType
			@_prev.setType("prev")

			return dom

		doNext: ()->
			picker = @
			current = picker._current
			prev = picker._prev
			next = picker._next
			current.setType("prev")
			next.setType("current")
			prev.setType("next")
			@fire("change", @, {target: "next"})

		doPrev: ()->
			picker = @
			current = picker._current
			prev = picker._prev
			next = picker._next
			current.setType("next")
			next.setType("prev")
			prev.setType("current")
			@fire("change", @, {target: "prev"})

		next: (callback)->
			@_stack.next()
			callback?()
			return @

		prev: (callback)->
			@_stack.prev()
			callback?()
			return @
		getDateCellDom: (date)-> @_current.getDateCellDom(date)
	DateHelper =
		getDayCountOfMonth: (year, month)->
			return 30 if month == 3 or month == 5 or month == 8 or month == 10
			if month == 1
				if year % 4 == 0 and year % 100 != 0 or year % 400 == 0
					return 29
				else
					return 28
			return 31

		getFirstDayOfMonth: (date)->
			temp = new Date(date.getTime())
			temp.setDate(1)
			return temp.getDay()

		getWeekNumber: (date)->
			d = new Date(+date)
			d.setHours(0, 0, 0)
			d.setDate(d.getDate() + 4 - (d.getDay() || 7))
			return Math.ceil((((d - new Date(d.getFullYear(), 0, 1)) / 8.64e7) + 1) / 7)

	getDateTableState = (date)->
		day = date.getDay()

		maxDay = DateHelper.getDayCountOfMonth(date.getFullYear(), date.getMonth())
		lastM = if date.getMonth() == 0 then 11 else date.getMonth() - 1
		lastMonthDay = DateHelper.getDayCountOfMonth(date.getFullYear(), lastM)
		day = if day == 0 then 7 else day
		cells = []
		count = 1
		firstDayPosition = null
		i = 0
		while i < 6
			j = 0
			while j < 7
				cell =
					row: i
					column: j
					type: "normal"
				if i == 0
					if j >= day
						cell.text = count++
						firstDayPosition = i * 7 + j if count == 2
					else
						cell.text = lastMonthDay - (day - j % 7) + 1
						cell.type = "prev-month"
				else
					if count <= maxDay
						cell.text = count++
						firstDayPosition = i * 7 + j if count == 2
					else
						cell.text = count++ - maxDay
						cell.type = "next-month"
				cells.push(cell)
				j++
			i++
		cells.firstDayPosition = firstDayPosition
		return cells


	class cola.Calendar extends cola.Widget
		@CLASS_NAME: "calendar"
		@ATTRIBUTES:
			date:
				getter: ()->
					return @_date or new Date()
		@EVENTS:
			refreshCellDom: null
			change: null
			cellClick: null
		doFireCellRefresh: (arg)->
			@fire("refreshCellDom", @, arg)
		bindButtonsEvent: ()->
			cal = @
			doms = @_doms
			picker = @_datePicker
			$fly(doms.prevMonthButton).on("click", ()->
				picker.prev()
			)
			$fly(doms.nextMonthButton).on("click", ()->
				picker.next()
			)
			$fly(doms.prevYearButton).on("click", ()->
				cal.prevYear()
			)
			$fly(doms.nextYearButton).on("click", ()->
				cal.nextYear()
			)
		_createDom: ()->
			allWeeks = cola.resource("cola.date.dayNamesShort")
			weeks = allWeeks.split(",")
			cal = this
			@_doms ?= {}
			dom = $.xCreate({
				tagName: "div"
				content: [
					{
						tagName: "div"
						class: "header"
						contextKey: "header"
						content: [
							{
								tagName: "div"
								class: "month"
								content: [
									{
										tagName: "span"
										class: "button prev"
										contextKey: "prevMonthButton"
									}
									{
										tagName: "span"
										class: "button next"
										contextKey: "nextMonthButton"
									}
									{
										tagName: "div"
										class: "label"
										contextKey: "monthLabel"
									}
								]
							}
							{
								tagName: "div"
								class: "year"
								content: [
									{
										tagName: "span"
										class: "button prev"
										contextKey: "prevYearButton"
									}
									{
										tagName: "span"
										class: "button next"
										contextKey: "nextYearButton"
									}
									{
										tagName: "div"
										class: "label"
										contextKey: "yearLabel"
									}
								]
							}
						]
					}
					{
						tagName: "table"
						cellPadding: 0
						cellSpacing: 0
						border: 0
						class: "date-header"
						contextKey: "dateHeader"
						content: [
							{
								tagName: "tr"
								class: "header"
								content: [
									{
										tagName: "td"
										content: weeks[0]
									}
									{
										tagName: "td"
										content: weeks[1]
									}
									{
										tagName: "td"
										content: weeks[2]
									}
									{
										tagName: "td"
										content: weeks[3]
									}
									{
										tagName: "td"
										content: weeks[4]
									}
									{
										tagName: "td"
										content: weeks[5]
									}
									{
										tagName: "td"
										content: weeks[6]
									}
								]
							}
						]
					}

				]
			}, @_doms)

			picker = cal._datePicker = new cola.calendar.SwipePicker({
				className: "date-table-wrapper"
				calendar: cal
				change: (self, arg)->
					if arg.target == "next"
						cal.nextMonth()
					else
						cal.prevMonth()

			})
			picker.appendTo(dom)
			@_doms.dateTableWrapper = picker._dom

			cal.bindButtonsEvent()
			return dom



		setState: (year, month)->
			doms = @_doms

			@_year = year
			@_month = month

			$fly(doms.monthLabel).html(month + 1 || "")
			$fly(doms.yearLabel).html(year || "")


			@_datePicker.setState(year, month)

		setDate: (date)->
			@_date = new Date(@_year, @_month, date)
			@_monthDate = date
			@_datePicker.setDate(date)
			return @

		prevMonth: ()->
			year = @_year
			month = @_month

			if year != undefined && month != undefined
				newYear = if month == 0 then year - 1 else year
				newMonth = if month == 0 then 11 else month - 1

				@setState(newYear, newMonth)
			return @

		nextMonth: ()->
			year = @_year
			month = @_month

			if year != undefined && month != undefined
				newYear = if month == 11 then  year + 1 else year
				newMonth = if  month == 11 then 0 else month + 1

				@setState(newYear, newMonth)
			return @

		prevYear: ()->
			year = @_year
			month = @_month

			@setState(year - 1, month) if year != undefined && month != undefined
			return @

		setYear: (newYear)->
			year = @_year
			month = @_month
			@setState(newYear, month) if year != undefined && month != undefined

		nextYear: ()->
			year = @_year
			month = @_month

			@setState(year + 1, month) if year != undefined && month != undefined
			return @

		_doRefreshDom: ()->
			return unless @_dom
			super()
			date = @get("date")
			if date
				@setState(date.getFullYear(), date.getMonth())
				@setDate(date.getDate())
		getDateCellDom: (date)-> @_datePicker.getDateCellDom(date)