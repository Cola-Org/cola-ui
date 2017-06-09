class cola.DateGrid extends cola.RenderableElement
	@CLASS_NAME: "calendar mild"
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
							class: "month"
							content: [
								{
									tagName: "span"
									class: "button prev"
									contextKey: "prevMonthButton"
									click: ()->
										picker.prevMonth()
								}
								{
									tagName: "span"
									class: "button next"
									contextKey: "nextMonthButton"
									click: ()->
										picker.nextMonth()
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
									click: ()->
										picker.prevYear()
								}
								{
									tagName: "span"
									class: "button next"
									contextKey: "nextYearButton"
									click: ()->
										picker.nextYear()
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
		table = $.xCreate({
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

		$fly(table).on("click", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					picker.setSelectionCell(position.row, position.column)
					value = $fly(position.element).attr("cell-date")
					picker._currentDate = new Date(Date.parse(value))
				picker.fire("cellClick", picker, position)
		)
		dom.appendChild(headerDom)
		@_doms.tableWrapper = $.xCreate({
			tagName: "div"
			class: "date-table-wrapper"
		})
		@_doms.tableWrapper.appendChild(table)
		dom.appendChild(@_doms.tableWrapper)
		return dom

	doFireRefreshEvent: (eventArg) ->
		@fire("refreshCellDom", @, eventArg)
		return @
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

				@doFireRefreshEvent(eventArg)

				@doRefreshCell(cell, i, j) if eventArg.processDefault != false
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
		value = new XDate(date).toString("yyyy-MM-dd")
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

	doRefreshCell: (cell, row, column) ->
		state = @_state
		return unless state

		cellState = state[row * 7 + column]
		$fly(cell).removeClass("prev-month next-month").addClass(cellState.type).find(".label").html(cellState.text)
		ym = @getYMForState(cellState)
		month = ym.month + 1
		d = cellState.text
		if month < 10 then month = "0#{month}"
		if parseInt(d) < 10 then d = "0#{d}"
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
	onCalDateChange: () ->
		return @ unless @_dom
		return @

DEFAULT_DATE_DISPLAY_FORMAT = "yyyy-MM-dd"
DEFAULT_DATE_TIME_DISPLAY_FORMAT = "yyyy-MM-dd HH:mm:ss"

class cola.DatePicker extends cola.CustomDropdown
	@tagName: "c-datepicker"
	@CLASS_NAME: "date input drop"
	@attributes:
		displayFormat: null
		inputFormat: null
		icon:
			defaultValue: "calendar"
		content:
			$type: "calender"
		inputType:
			defaultValue: "date"
	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null
	_initDom: (dom)->
		super(dom)
		doPost = ()=>
			readOnly = @_readOnly
			if !readOnly
				value = $(@_doms.input).val()
				inputFormat = @_inputFormat or @_displayFormat
				unless inputFormat
					if @_inputType == "date"
						inputFormat = DEFAULT_DATE_DISPLAY_FORMAT
					else
						inputFormat = DEFAULT_DATE_TIME_DISPLAY_FORMAT
				if inputFormat and value
					value = inputFormat + "||" + value
					xDate = new XDate(value)
					value = xDate.toDate()
				@set("value", value)
			return

		$(@_doms.input).on("change", ()=>
			doPost()
			return
		).on("focus", ()=>
			
			@_inputFocused = true
			@_refreshInputValue(@_value)
			@addClass("focused") if not @_finalReadOnly
			@fire("focus", @)
			return
		).on("blur", ()=>
			
			@_inputFocused = false
			@removeClass("focused")
			@_refreshInputValue(@_value)
			@fire("blur", @)

			if !@_value? or @_value is "" and @_bindInfo?.writeable
				propertyDef = @getBindingProperty()
				if propertyDef?._required and propertyDef._validators
					entity = @_scope.get(@_bindInfo.entityPath)
					entity.validate(@_bindInfo.property) if entity
			return
		).on("keydown", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			@fire("keyDown", @, arg)
			if arg.keyCode == 9 then @_closeDropdown()
		).on("keypress", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			if @fire("keyPress", @, arg) == false then return

			if event.keyCode == 13 && isIE11 then doPost()
		)
		return
	_refreshInputValue: (value) ->
		inputType = @_inputType
		if value instanceof Date
			if value.toDateString() is "Invalid Date"
				value = ""
			else
				format = @_inputFormat or @_displayFormat
				unless format
					if inputType is "date"
						format = DEFAULT_DATE_DISPLAY_FORMAT
					else
						format = DEFAULT_DATE_TIME_DISPLAY_FORMAT
				value = (new XDate(value)).toString(format)
		return super(value)

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.prop("readOnly", @_finalReadOnly)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")
		@_refreshInputValue(@_value)
		return

	open: () ->
		if super()
			value = @get("value")
			unless value
				value = new Date()
			else
				unless value instanceof Date
					value = new Date(Date.parse(value))
			if value.toDateString() is "Invalid Date"
				value = new Date()

			@_dataGrid.setCurrentDate(value)
			@_timeEditor?.set({
				hour: value.getHours()
				minute: value.getMinutes()
				second: value.getSeconds()
			})
			return true
		return

	_getDropdownContent: () ->
		if @_inputType == "date" then @_getDateDropdownContent() else @_getDateTimeDropdownContent()
	_getDateTimeDropdownContent: () ->
		datePicker = @
		datePicker._selectedDate = null;
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.DateGrid({
				cellClick: (self, arg)=>
					value = $fly(arg.element).attr("cell-date")
					datePicker._selectedDate = value
			})
			currentDate = new Date()
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
										contextKey: "timeEditorBox"
									}
								},
								{
									class: "box actions"
									content: {
										class: "ui button primary", content: cola.resource("cola.message.approve")
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
				date.setHours(datePicker._timeEditor.get("hour"))
				date.setMinutes(datePicker._timeEditor.get("minute"))
				date.setSeconds(datePicker._timeEditor.get("second"))
				datePicker.close(date)
			)
			@_dropdownContent = container
		return @_dropdownContent

	_getDateDropdownContent: () ->
		datePicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.DateGrid({
				cellClick: (self, arg)=>
					value = $fly(arg.element).attr("cell-date")
					d = Date.parse(value)
					datePicker.close(new Date(d))
			})
			dateGrid.setCurrentDate(new Date())
			@_dropdownContent = dateGrid.getDom()
		return @_dropdownContent

class cola.YearMonthGrid extends cola.RenderableElement
	@CLASS_NAME: "year-month-grid"
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
		while i < 3
			tr = document.createElement("tr")
			j = 0
			while j < 4
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

	doFireRefreshEvent: (eventArg) ->
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
			@_year = parseInt(values[0])
			@_month = parseInt(values[1])
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
		content = column + 1 + row * 4
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
		if parseInt(month) < 10
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
		year = parseInt(values[0])
		month = parseInt(values[1])
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
	onCalDateChange: () ->
		return @ unless @_dom
		return @

class cola.YearMonthDropDown extends cola.CustomDropdown
	@tagName: "c-yearmonthdropdown"
	@CLASS_NAME: "year-month input date drop"
	@attributes:
		icon:
			defaultValue: "calendar"
	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null
	_initDom: (dom)->
		super(dom)
		doPost = ()=>
			readOnly = @_readOnly
			if !readOnly
				value = $(@_doms.input).val()
				@set("value", value)
			return

		$(@_doms.input).on("change", ()=>
			doPost()
			return
		).on("focus", ()=>
			@_inputFocused = true
			@_refreshInputValue(@_value)
			@addClass("focused") if not @_finalReadOnly
			@fire("focus", @)
			return
		).on("blur", ()=>
			@_inputFocused = false
			@removeClass("focused")
			@_refreshInputValue(@_value)
			@fire("blur", @)

			if !@_value? or @_value is "" and @_bindInfo?.writeable
				propertyDef = @getBindingProperty()
				if propertyDef?._required and propertyDef._validators
					entity = @_scope.get(@_bindInfo.entityPath)
					entity.validate(@_bindInfo.property) if entity
			return
		).on("keydown", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			@fire("keyDown", @, arg)
		).on("keypress", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			if @fire("keyPress", @, arg) == false then return

			if event.keyCode == 13 && isIE11 then doPost()
		)
		return

	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.prop("readOnly", @_finalReadOnly)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")

		@_refreshInputValue(@_value)
		return
	open: () ->
		if super()
			value = @get("value")
			unless value
				date = new Date()
				value = "#{date.getFullYear()}-#{date.getMonth() + 1}"
			@_dataGrid.set("value", value)
			return true
		return

	_getDropdownContent: () ->
		datePicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.YearMonthGrid({
				cellClick: (self, arg)=>
					datePicker.close(self.get("value"))
			})
			@_dropdownContent = dateGrid.getDom()

		return @_dropdownContent
class cola.YearMonthPicker extends cola.YearMonthDropDown
	@tagName: "c-monthpicker"
	@CLASS_NAME: "year-month input date drop"

class cola.TimeEditor extends cola.Widget
	@CLASS_NAME: "ui time-editor"
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
						contextKey: "hour"
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
						contextKey: "minute"
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
						contextKey: "second"
					}
				}
			]
		}, @_doms)

		doPost = (input)=>
			@["_#{input.className}"] = parseInt($(input).val() || "00")
			@fire("change", @, {
				hour: @_hour, minute: @_minute, second: @_second
			})

		$(childDom).find("input").keyup(()->
			val = this.value.replace(/[^\d]/g, '')
			if event.keyCode == 37 or event.keyCode == 39
				return

			if event.keyCode != 8 and val
				intVal = parseInt(this.value)
				if event.keyCode == 38
					intVal++
				else if event.keyCode == 40
					intVal--
				max = if this.className == "hour" then 24 else 60
				if intVal >= max
					this.value = max - 1
				else if intVal <= 0
					this.value = if val.length >= 2 then "00" else "0"
				else if intVal > 0 and intVal < 10
					this.value = if val.length >= 2 then  "0#{intVal}" else intVal
				else
					this.value = intVal

			doPost(this)
		)

		dom.appendChild(childDom)

	_doRefreshDom: ()->
		super()
		for v in ["hour", "minute", "second"]
			$fly(@_doms[v]).val(@["_#{v}"])
		return


cola.registerWidget(cola.DatePicker)
cola.registerWidget(cola.YearMonthDropDown)
cola.registerWidget(cola.YearMonthPicker)
