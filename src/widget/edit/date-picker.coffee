class cola.DateGrid extends cola.RenderableElement
	@className: "calendar"
	@attributes:
		columnCount:
			type: "number"
			defaultValue: 7
		rowCount:
			type: "number"
			defaultValue: 6
		cellClassName: null
		selectedCellClassName: ""
		rowClassName: null
		autoSelect:
			defaultValue: true
		tableClassName:
			defaultValue: "ui date-table"

	@events:
		cellClick: null
		cellDoubleClick: null
		refreshCellDom: null

	_initDom: (dom)->
		picker = @
		columnCount = @_columnCount
		rowCount = @_rowCount
		@_doms ?= {}
		allWeeks = cola.resource("cola.date.dayNamesShort")
		weeks = allWeeks.split(",")
		headerDom = $.xCreate({
			tagName: "div"
			class: "caption-panel",
			content: [
				{
					tagName: "div"
					class: "header"
					contextKey: "header"
					content: [
						{
							tagName: "div"
							class: "nav-wrapper"
							content: [
								{
									tagName: "span"
									class: "button year prev"
									contextKey: "prevYearButton"
									click: ()->
										picker.prevYear()
								}
								{
									tagName: "span"
									class: "button month prev"
									contextKey: "prevMonthButton"
									click: ()->
										picker.prevMonth()
								}
							]
						}
						{
							tagName: "div"
							class: "content"
							content: [
								{
									tagName: "span"
									class: "label"
									contextKey: "monthLabel"
									click: ()->
										picker.toggleMonthPicker()

								}
								{
									tagName: "span"
									class: "label"
									contextKey: "yearLabel",
									click: ()->
										picker.toggleYearPicker()
								}

							]
						}
						{
							tagName: "div"
							class: "nav-wrapper"
							content: [
								{
									tagName: "span"
									class: "button month next"
									contextKey: "nextMonthButton"
									click: ()->
										picker.nextMonth()
								}
								{
									tagName: "span"
									class: "button year next"
									contextKey: "nextYearButton"
									click: ()->
										picker.nextYear()
								}
							]
						}
					]
				}

			]
		}, @_doms)

		table = $.xCreate({
			tagName: "div",
			class: "date-grid",
			content: [
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
				}, {
					tagName: "table"
					cellSpacing: 0
					class: "#{picker._className || ""} #{picker._tableClassName || ""}"
					content: {
						tagName: "tbody",
						contextKey: "body"
					}
				} ]
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

		$fly(table).on("click", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					picker.setSelectionCell(position.row, position.column)
					value = $fly(position.element).attr("cell-date")
					picker._currentDate = new Date(Date.parse(value))
				picker.fire("cellClick", picker, position)
		).on("dblclick", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					picker.setSelectionCell(position.row, position.column)
					value = $fly(position.element).attr("cell-date")
					picker._currentDate = new Date(Date.parse(value))
				picker.fire("cellDoubleClick", picker, position)
		)
		dom.appendChild(headerDom)
		@_doms.tableWrapper = $.xCreate({
			tagName: "div"
			class: "date-table-wrapper"
		})
		$(table).addClass("active")

		@_doms.tableWrapper.appendChild(table)

		yearMonthGrid = new cola.YearMonthGrid({
			cellClick: (self, arg)->
				month = self._value.split("-")[1];

				picker.setState(picker._year, parseInt(month) - 1);
				picker.toggleMonthPicker()
				return

		})
		@_yearMonthGrid = yearMonthGrid;
		@_doms.tableWrapper.appendChild(yearMonthGrid.getDom())
		yearGrid = new cola.YearGrid({
			cellClick: (self, arg)->
				year = self._year;
				picker.setYear(year);
				picker.toggleYearPicker()
				return
		})
		@_yearGrid = yearGrid;
		@_doms.tableWrapper.appendChild(yearGrid.getDom())

		dom.appendChild(@_doms.tableWrapper)

		return dom

	doFireRefreshEvent: (eventArg)->
		return @fire("refreshCellDom", @, eventArg)
	toggleMonthPicker: ()->
		$wrapper = $(@_doms.tableWrapper)
		$monthPicker = $wrapper.find(">.year-month-grid");
		if $monthPicker.hasClass("active")
			$wrapper.find(".active").removeClass("active");
			$wrapper.find(">.date-grid").addClass("active")
		else
			@_yearMonthGrid.setState(parseInt(@_year), (@_month))
			$wrapper.find(".active").removeClass("active");
			$wrapper.find(">.year-month-grid").addClass("active")
	toggleYearPicker: ()->
		$wrapper = $(@_doms.tableWrapper)
		$yearPicker = $wrapper.find(">.year-grid");
		if $yearPicker.hasClass("active")
			$wrapper.find(".active").removeClass("active");
			$wrapper.find(">.date-grid").addClass("active")
		else
			@_yearGrid.setState(parseInt(@_year))
			$wrapper.find(".active").removeClass("active");
			$wrapper.find(">.year-grid").addClass("active")
	refreshHeader: ()->
		if @_doms
			monthLabel = @_doms.monthLabel
			yearLabel = @_doms.yearLabel
			$fly(yearLabel).text(@_year || "")
			$fly(monthLabel).text(@_month + 1 || "")

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

				processDefault = @doFireRefreshEvent(eventArg)
				@doRefreshCell(cell, i, j) if processDefault isnt false
				j++
			i++
		return @

	_doRefreshDom: ()->
		super()
		return unless @_dom
		@refreshGrid()
		@refreshHeader()

	setSelectionCell: (row, column)->
		picker = this
		lastSelectedCell = @_lastSelectedCell

		unless @_dom
			@_selectionPosition = { row: row, column: column }
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
		value = new XDate(date).toString(cola.setting("defaultDateFormat"))
		return $(@_dom).find("td[cell-date='#{value}']")[0]

	setCurrentDate: (date)->
		@_currentDate = date;
		month = date.getMonth()
		year = date.getFullYear()
		@setState(year, month)
		@selectCell(@getDateCellDom(date))

	selectCell: (cell)->
		lastSelectedCell = @_lastSelectedCell
		unless @_dom
			return @
		if lastSelectedCell
			$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
			@_lastSelectedCell = null
		return @ unless cell
		$fly(cell).addClass(@_selectedCellClassName || "selected")
		@_lastSelectedCell = cell

	doRefreshCell: (cell, row, column)->
		state = @_state
		return unless state

		cellState = state[row * 7 + column]
		$fly(cell).removeClass("prev-month next-month").addClass(cellState.type).find(".label").html(cellState.text)
		ym = @getYMForState(cellState)
		month = ym.month + 1
		d = cellState.text
		if month < 10 then month = "0#{month}"
		if +d < 10 then d = "0#{d}"
		$fly(cell).attr("cell-date", "#{ym.year}-#{month}-#{d}")

	setState: (year, month)->
		oldYear = @_year
		oldMonth = @_month

		if oldYear != year || oldMonth != month
			@_year = year
			@_month = month

			@_state = cola.getDateTableState(new Date(year, month, 1))
			if @_dom
				@refreshGrid()
				@refreshHeader()

		@onCalDateChange()

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
	onCalDateChange: ()->
		return @ unless @_dom
		return @

class cola.DatePicker extends cola.CustomDropdown
	@tagName: "c-datepicker,c-date-picker"
	@className: "date input drop"
	@attributes:
		displayFormat: null
		inputFormat: null
		icon:
			defaultValue: "calendar"
		content:
			$type: "calender"
		inputType:
			defaultValue: "date"
		defaultDate:
			defaultValue: "currentDate"
			setter: (value)->
				if value
					if not (value instanceof Date) and value isnt "currentDate"
							value = new XDate(value)
				@_defaultDate = value
				return

	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null
		inputInvalidDate: null

	_postInput: ()->
		if not @_finalReadOnly
			value = $(@_doms.input).val()
			inputValue = value

			inputFormat = @_inputFormat
			unless inputFormat
				if @_inputType is "date"
					inputFormat = cola.setting("defaultDateInputFormat")
				else
					inputFormat = cola.setting("defaultDateTimeInputFormat")

			displayFormat = @_displayFormat
			unless displayFormat
				if @_inputType is "date"
					displayFormat = cola.setting("defaultDateFormat")
				else
					displayFormat = cola.setting("defaultDateTimeFormat")

			xDate = new XDate(inputFormat + "||" + value)
			value = xDate.toDate()

			if value.toDateString() is "Invalid Date"
				xDate = new XDate(displayFormat + "||" + value)
				value = xDate.toDate()

			if value.toDateString() is "Invalid Date"
				@fire("inputInvalidDate", @, {
					inputValue: inputValue
				})
				value = null
			@set("value", value)
		return

	_refreshInputValue: (value)->
		if value instanceof Date
			if value.toDateString() is "Invalid Date"
				value = ""
			else
				format = if @_focused then (@_inputFormat or @_displayFormat) else (@_displayFormat or @_inputFormat)
				unless format
					if @_inputType is "date"
						format = cola.setting("defaultDateFormat")
					else
						format = cola.setting("defaultDateTimeFormat")
				value = (new XDate(value)).toString(format)
		return super(value)

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.attr("readOnly", @_finalReadOnly)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")
		@_refreshInputValue(@_value)
		return

	_onBlur: ()->
		@_postInput()
		return super()

	open: ()->
		if super()
			value = @get("value")
			unless value instanceof Date
				value = new Date(Date.parse(value))

			if value.toDateString() is "Invalid Date"
				value = null

			if value
				@_dataGrid.setCurrentDate(value)
				@_timeEditor?.set({
					hour: value.getHours()
					minute: value.getMinutes()
					second: value.getSeconds()
				})
			return true
		return

	_getDropdownContent: ()->
		if @_inputType is "date" then @_getDateDropdownContent() else @_getDateTimeDropdownContent()

	_getDateTimeDropdownContent: ()->
		datePicker = @
		datePicker._selectedDate = null;
		if not @_dropdownContent
			@_dataGrid = dateGrid = new cola.DateGrid({
				cellClick: (self, arg)->
					value = $fly(arg.element).attr("cell-date")
					datePicker._selectedDate = value
				cellDoubleClick: ()->
					context.approveBtn.click()
			})

			if @_defaultDate is "currentDate"
				currentDate = (new XDate()).setHours(0).setMinutes(0).setSeconds(0).setMilliseconds(0).toDate()
			else
				currentDate = @_defaultDate

			currentDate or= (new XDate()).setMilliseconds(0).toDate()

			dateGrid.setCurrentDate(currentDate)
			context = {}
			container = $.xCreate({
				class: "v-box date-time-picker"
				content: [
					{
						class: "flex-box", contextKey: "dateGridBox"
					},
					{
						class: "box", contextKey: "timeBox",
						content: {
							class: "h-box"
							content: [
								{
									class: "label box", content: "#{cola.resource("cola.date.time")}:"
								},
								{
									class: "flex-box"
									content: {
										class: "time-editor-box",
										contextKey: "timeEditorBox"
									}
								},
								{
									class: "box actions"
									content: {
										class: "button primary", content: cola.resource("cola.message.approve")
										contextKey: "approveBtn"
									}
								}
							]
						}
					}
				]
			}, context)

			@_timeEditor = new cola.TimeEditor({
				hour: currentDate.getHours()
				minute: currentDate.getMinutes()
				second: currentDate.getSeconds()
			})

			context.dateGridBox.appendChild(dateGrid.getDom())
			context.timeEditorBox.appendChild(@_timeEditor.getDom())
			$(context.approveBtn).on("click", ()->
				date = datePicker._dataGrid._currentDate
				xdate = new Date(date.getTime())
				xdate.setHours(datePicker._timeEditor.get("hour"))
				xdate.setMinutes(datePicker._timeEditor.get("minute"))
				xdate.setSeconds(datePicker._timeEditor.get("second"))
				datePicker.close(xdate)
			)

			@_dropdownContent = container
		return @_dropdownContent

	_getDateDropdownContent: ()->
		datePicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.DateGrid({
				cellClick: (self, arg)->
					value = $fly(arg.element).attr("cell-date")
					d = new XDate(cola.setting("defaultDateFormat") + "||" + value);
					datePicker.close(d.toDate())
			})
			dateGrid.setCurrentDate(new Date())
			content = $.xCreate({
				tagName: "div"
				class: "date-picker"
			})
			content.appendChild(dateGrid.getDom())
			@_dropdownContent = content

		return @_dropdownContent

class cola.YearGrid extends cola.RenderableElement
	@className: "year-grid"
	@tagName: "c-year-grid"
	@attributes:
		value:
			refreshDom: true
		autoSelect:
			defaultValue: true
	@events:
		cellClick: null
		refreshCellDom: null

	_initDom: (dom)->
		super(dom)

		picker = @
		@_doms ?= {}
		table = $.xCreate({
			tagName: "table"
			cellSpacing: 0
			content: {
				tagName: "tbody",
				contextKey: "body"
			}
		}, @_doms)

		$fly(table).on("click", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					cell = picker._doms.body.rows[position.row].cells[position.column]
					picker.selectCell(cell)
				picker.fire("cellClick", picker, position)
		)

		@_doms.tableWrapper = $.xCreate({
			tagName: "div"
			class: "table-wrapper"
		})
		@_doms.tableWrapper.appendChild(table)
		@_doms.table = table

		@_doms.tableWrapper.appendChild($.xCreate({
			tagName: "div"
			class: "prev nav-btn"
			click: ()->
				picker.prevYears()
		}));
		@_doms.tableWrapper.appendChild($.xCreate({
			tagName: "div"
			class: "next nav-btn"
			click: ()->
				picker.nextYears()
		}));
		dom.appendChild(@_doms.tableWrapper)
		return dom

	doFireRefreshEvent: (eventArg)->
		@fire("refreshCellDom", @, eventArg)
		return @
	_doRefreshDom: ()->
		date = new Date()
		if @_value
			@_year = +@_value
		else
			@_year ?= date.getFullYear()
			@_value = @_year
		super()
		return unless @_dom

		@refreshGrid()

	doRenderCell: (cell, row, column)->
		content = column + 1 + row * 3
		year = @_year;
		content = year + (content - 5)
		$(cell).attr("year", content)
		cell.appendChild($.xCreate({
			tagName: "div"
			content: content
		}))
		return

	selectCell: (cell)->
		year = $(cell).attr("year")
		@_year = Number(year)

		@set("value", year)


	setState: (year)->
		oldYear = @_year
		if oldYear != year
			@_year = year
			if @_dom
				@refreshGrid()
	refreshGrid: ()->
		$dom = $(@_dom)
		$(@_doms.body).empty();
		i = 0
		year = @_year
		while i < 4
			tr = document.createElement("tr")
			j = 0
			while j < 3
				td = document.createElement("td")
				@doRenderCell(td, i, j)
				tr.appendChild(td)
				j++
			@_doms.body.appendChild(tr)
			i++
		$dom.find(".selected").removeClass("selected")
		$($dom.find("td[year='#{year}']")[0]).addClass("selected");

	prevYears: ()->
		year = @_year
		@setState(year - 12) if year != undefined
		return @

	setYear: (newYear)->
		year = @_year
		@setState(newYear) if year != undefined

	nextYears: ()->
		year = @_year
		@setState(year + 12) if year != undefined
		return @
	onCalDateChange: ()->
		return @ unless @_dom
		return @

class cola.YearMonthGrid extends cola.RenderableElement
	@className: "year-month-grid"
	@tagName: "c-yearMonthGrid"
	@attributes:
		value:
			refreshDom: true
		autoSelect:
			defaultValue: true
	@events:
		cellClick: null
		refreshCellDom: null

	_initDom: (dom)->
		picker = @
		@_doms ?= {}
		headerDom = $.xCreate(
		  {
			  tagName: "div"
			  class: "header"
			  contextKey: "header"
			  content: [
				  {
					  tagName: "div"
					  class: "year"
					  content: [
						  {
							  tagName: "div"
							  class: "button prev"
							  contextKey: "prevYearButton"
							  click: ()->
								  picker.prevYear()
						  }
						  {
							  tagName: "div"
							  class: "label"
							  contextKey: "yearLabel"
						  }
						  {
							  tagName: "div"
							  class: "button next"
							  contextKey: "nextYearButton"
							  click: ()->
								  picker.nextYear()
						  }

					  ]
				  }
			  ]

		  }, @_doms)

		table = $.xCreate({
			tagName: "table"
			cellSpacing: 0
			content: {
				tagName: "tbody",
				contextKey: "body"
			}
		}, @_doms)

		i = 0
		while i < 4
			tr = document.createElement("tr")
			j = 0
			while j < 3
				td = document.createElement("td")
				@doRenderCell(td, i, j)
				tr.appendChild(td)
				j++

			@_doms.body.appendChild(tr)
			i++

		$fly(table).on("click", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					cell = picker._doms.body.rows[position.row].cells[position.column]
					picker.selectCell(cell)

				picker.fire("cellClick", picker, position)
		)
		dom.appendChild(headerDom)
		@_doms.tableWrapper = $.xCreate({
			tagName: "div"
			class: "table-wrapper"
		})
		@_doms.tableWrapper.appendChild(table)
		dom.appendChild(@_doms.tableWrapper)
		return dom

	doFireRefreshEvent: (eventArg)->
		@fire("refreshCellDom", @, eventArg)
		return @

	refreshHeader: ()->
		if @_doms
			yearLabel = @_doms.yearLabel
			$fly(yearLabel).text(@_year || "")

	_doRefreshDom: ()->
		date = new Date()
		if @_value
			values = @_value.split("-")
			@_year = +values[0]
			@_month = +values[1]
		else
			@_year ?= date.getFullYear()
			@_month ?= date.getMonth() + 1
			month = if @_month < 10 then "0#{@_month}" else @_month
			@_value = "#{@_year}-#{month}"
		super()
		return unless @_dom
		@refreshHeader()
		@refreshGrid()

	doRenderCell: (cell, row, column)->
		content = column + 1 + row * 3
		monthNames = cola.resource("cola.date.monthNames")
		$(cell).attr("month", content)
		cell.appendChild($.xCreate({
			tagName: "div"
			content: monthNames.split(",")[content - 1]
		}))
		return

	selectCell: (cell)->
		month = $(cell).attr("month")
		year = @_year
		if +month < 10
			month = "0#{month}"

		@set("value", "#{year}-#{month}")
	setState: (year, month)->
		oldYear = @_year
		oldMonth = @_month

		if oldYear != year || oldMonth != month
			@_year = year
			@_month = month
			if @_dom
				@refreshHeader()
				@refreshGrid()

	refreshGrid: ()->
		values = @_value.split("-")
		year = +values[0]
		month = +values[1]
		$dom = $(@_dom)
		$dom.find(".selected").removeClass("selected")
		if @_year == year
			$($dom.find("td[month='#{month}']")[0]).addClass("selected");

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
	onCalDateChange: ()->
		return @ unless @_dom
		return @

class cola.YearMonthDropDown extends cola.CustomDropdown
	@tagName: "c-yearmonthdropdown"
	@className: "year-month input date drop"
	@attributes:
		icon:
			defaultValue: "calendar"
	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null

	_postInput: ()->
		if not @_finalReadOnly
			value = $(@_doms.input).val()
			@set("value", value)
		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		@_doms.input.readOnly = @_finalReadOnly
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")

		@_refreshInputValue(@_value)
		return

	open: ()->
		if super()
			value = @get("value")
			unless value
				date = new Date()
				value = "#{date.getFullYear()}-#{date.getMonth() + 1}"
			@_dataGrid.set("value", value)
			return true
		return

	_getDropdownContent: ()->
		datePicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.YearMonthGrid({
				cellClick: (self, arg)=>
					datePicker.close(self.get("value"))
			})

			content = $.xCreate({
				tagName: "div"
				class: "month-picker"
			})
			content.appendChild(dateGrid.getDom())
			@_dropdownContent = content

		return @_dropdownContent

class cola.YearMonthPicker extends cola.YearMonthDropDown
	@tagName: "c-monthpicker,c-month-picker"
	@className: "year-month input date drop"

class cola.TimeEditor extends cola.Widget
	@className: "ui time-editor"
	@attributes:
		hour:
			defaultValue: "00"
			refreshDom: true
		minute:
			defaultValue: "00"
			refreshDom: true
		second:
			defaultValue: "00"
			refreshDom: true
	@events:
		change: null

	_initDom: (dom)->
		@_doms ?= {}
		childDom = $.xCreate({
			class: "time-wrapper"
			content: [
				{
					class: "edit ui input"
					content: {
						tagName: "input",
						class: "hour",
						type: "number",
						contextKey: "hour",
						max: 23,
						min: "0"
					}
				}
				{
					class: "separator", content: ":"
				}
				{
					class: "edit ui input"
					content: {
						tagName: "input",
						class: "minute",
						type: "number",
						contextKey: "minute",
						max: 59,
						min: "0"
					}
				}
				{
					class: "separator", content: ":"
				}
				{
					class: "edit ui input"
					content: {
						tagName: "input",
						class: "second",
						type: "number",
						contextKey: "second",
						max: 59,
						min: "0"
					}
				}
			]
		}, @_doms)

		doPost = (input)=>
			@["_#{input.className}"] = +$(input).val() or 0
			@fire("change", @, {
				hour: @_hour, minute: @_minute, second: @_second
			})

		$(childDom).find("input").change((event)->
			doPost(this)
		)

		dom.appendChild(childDom)

	_doRefreshDom: ()->
		super()
		for v in [ "hour", "minute", "second" ]
			$fly(@_doms[v]).val(@["_#{v}"])
		return

cola.registerWidget(cola.DatePicker)
cola.registerWidget(cola.YearMonthDropDown)
cola.registerWidget(cola.YearMonthPicker)


class cola.YearPicker extends cola.CustomDropdown
	@tagName: "c-yearpicker,c-year-picker"
	@className: "year input date drop"
	@attributes:
		icon:
			defaultValue: "calendar"
	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null

	_postInput: ()->
		if not @_finalReadOnly
			value = $(@_doms.input).val()
			@set("value", value)
		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		@_doms.input.readOnly = @_finalReadOnly
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")

		@_refreshInputValue(@_value)
		return

	open: ()->
		if super()
			value = @get("value")
			unless value
				date = new Date()
				value = date.getFullYear() - 1
			@_dataGrid.set("value", value)
			return true
		return

	_getDropdownContent: ()->
		yearPicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.YearGrid({
				cellClick: (self, arg)=>
					yearPicker.close(self.get("value"))
			})
			content = $.xCreate({
				tagName: "div"
				class: "year-picker"
			})
			content.appendChild(dateGrid.getDom())
			@_dropdownContent = content
		return @_dropdownContent

cola.registerWidget(cola.YearPicker)
