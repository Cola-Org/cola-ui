class cola.Grid extends cola.Widget
	@tagName: "c-grid"
	@CLASS_NAME: "items-view widget-grid"

	@attributes:
		items:
			refreshItems: true
			setter: (items) ->
				return if @_items is items
				@_set("bind", undefined)
				@_items = items
				return
		bind:
			setter: (bindStr) ->
				return if @_bindStr is bindStr
				@_set("items", undefined)
				@_bindSetter(bindStr)
				return

		columns:
			setter: (columnConfigs) ->
				if @_columns
					for column in @_columns
						column._setTable(null)

				columns = []
				if columnConfigs
					for columnConfig in columnConfigs
						continue unless columnConfig
						if columnConfig instanceof cola.TableColumn
							column = columnConfig
						else
							column = cola.create("table.column", columnConfig, cola.TableColumn)
						column._setTable(@)
						columns.push(column)
				@_columns = columns
				@_collectionColumnsInfo()
				return
		dataType:
			setter: cola.DataType.dataTypeSetter

		showHeader:
			type: "boolean"
			defaultValue: true
		showFooter:
			type: "boolean"

		columnStretchable:
			type: "boolean"
			defaultValue: true
		selectedProperty:
			defaultValue: "selected"

		sortMode:
			defaultValue: "remote" # local/remote
		readOnly:
			type: "boolean"
			defaultValue: true

		leftFixedCols:
			defaultValue: 0
			setter: (value) ->
				@_leftFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

		rightFixedCols:
			defaultValue: 0
			setter: (value) ->
				@_rightFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

	@events:
		renderRow: null
		renderCell: null
		renderHeaderCell: null
		renderFooterCell: null
		cellClick: null
		headerClick: null
		footerClick: null
		sortDirectionChange: null

	@TEMPLATES:
		"default-row":
			tagName: "div"

		"boolean-column":
			"c-display": "$default"
			content:
				tagName: "i"
				class: "green checkmark icon"
		"checkbox-column":
			tagName: "c-checkbox"
			bind: "$default"
		"toggle-column":
			tagName: "c-toggle"
			bind: "$default"
		"input-column":
			tagName: "c-input"
			bind: "$default"
		"date-picker-column":
			tagName: "c-datepicker"
			bind: "$default"

		"input":
			tagName: "c-input"
			bind: "$default"
		"checkbox":
			class: "editor-container"
			content:
				tagName: "c-checkbox"
				bind: "$default"
		"toggle":
			class: "editor-container"
			content:
				tagName: "c-toggle"
				bind: "$default"
		"date-picker":
			tagName: "c-date-picker"
			bind: "$default"

	constructor: (config) ->
		@_columnMap = {}
		super(config)

	_getItems: () ->
		if @_items
			return { items: @_items }
		else
			return super()

	_regColumn: (column) ->
		if column._name
			@_columnMap[column._name] = column
		return

	_unregColumn: (column) ->
		if column._name
			delete @_columnMap[column._name]
		return

	getColumn: (name) ->
		return @_columnMap[name]

	_collectionColumnsInfo: () ->
		collectColumnInfo = (column, context, deepth, rootIndex) ->
			info =
				level: deepth
				column: column
			if column instanceof cola.TableGroupColumn
				if column._columns
					info.columns = cols = []
					for col in column._columns
						continue unless col._visible
						if context.rows.length == deepth
							context.rows[deepth] = []
						cols.push(collectColumnInfo(col, context, deepth + 1, rootIndex))
					if cols.length
						if context.rows.length == deepth then context.rows[deepth] = []
						context.rows[deepth].push(info)
			else
				if column._bind
					bind = column._bind
					if bind.charCodeAt(0) == 46 # `.`
						if not column._property
							column._property = bind.substring(1)
					else
						info.expression = cola._compileExpression(@_scope, bind)

				if column._width
					width = column._width
					if typeof width == "string"
						if width.indexOf("px") > 0
							widthType = "px"
						else if width.indexOf("%") > 0
							widthType = "percent"
					info.widthType = widthType
					info.width = parseFloat(width)

					context.totalWidth += info.width

				info.index = context.dataColumns.length
				info.rootIndex = rootIndex
				context.dataColumns.push(info)

				if column instanceof cola.TableSelectColumn
					context.selectColumns ?= []
					context.selectColumns.push(info)

				if context.rows.length == deepth then context.rows[deepth] = []
				context.rows[deepth].push(info)
			return info

		@_columnsInfo = columnsInfo = {
			timestamp: cola.sequenceNo()
			totalWidth: 0
			rows: [ [] ]
			dataColumns: []
			alias: "item"
		}
		if @_columns
			expression = @_itemsScope.expression
			if expression
				columnsInfo.alias = expression.alias

			for col, i in @_columns
				continue unless col._visible
				collectColumnInfo(col, columnsInfo, 0, i)

			if @_leftFixedCols > 0 or @_rightFixedCols > 0
				overflow = @_leftFixedCols + @_rightFixedCols - @_columns.length
				if overflow >= 0
					if @_rightFixedCols > overflow
						@_rightFixedCols -= (overflow + 1)
						overflow = -1
					else
						@_rightFixedCols = 0
						overflow -= @_rightFixedCols

					if overflow >= 0
						@_leftFixedCols -= (overflow + 1)

			if @_leftFixedCols < 0 then @_leftFixedCols = 0
			if @_rightFixedCols < 0 then @_rightFixedCols = 0

			if @_leftFixedCols > 0 or @_rightFixedCols > 0
				if @_leftFixedCols > 0
					columnsInfo.left =
						timestamp: columnsInfo.timestamp
						start: 0
						rows: columnsInfo.rows
						columns: @_columns.slice(0, @_leftFixedCols)
						dataColumns: []
				else
					delete columnsInfo.left

				if @_rightFixedCols > 0
					columnsInfo.right =
						timestamp: columnsInfo.timestamp
						start: @_columns.length - @_rightFixedCols
						rows: columnsInfo.rows
						columns: @_columns.slice(@_columns.length - @_rightFixedCols, @_rightFixedCols)
						dataColumns: []
				else
					delete columnsInfo.right

				columnsInfo.center =
					timestamp: columnsInfo.timestamp
					start: @_leftFixedCols
					rows: columnsInfo.rows
					columns: @_columns.slice(@_leftFixedCols, @_columns.length - @_leftFixedCols - @_rightFixedCols)
					dataColumns: []

				for col in columnsInfo.dataColumns
					if col < @_leftFixedCols
						columnsInfo.left.dataColumns.push(col)
					else if col >= @_columns.length - @_rightFixedCols
						columnsInfo.right.dataColumns.push(col)
					else
						columnsInfo.center.dataColumns.push(col)
			else
				delete columnsInfo.left
				delete columnsInfo.right
				columnsInfo.center =
					timestamp: columnsInfo.timestamp
					start: 0
					rows: columnsInfo.rows
					columns: @_columns
					dataColumns: columnsInfo.dataColumns
		return

	_createDom: ()->
		dom = cola.xCreate({})
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom) ->
		@_centerTable = new cola.Table.InnerTable(
			scope: @_scope
			table: @
		)
		@_centerTable.appendTo(dom)
		return

	_initDom: (dom) ->
		@_regDefaultTemplates()
		@_templateContext ?= {}

		dataType = @_getBindDataType()
		if dataType and dataType instanceof cola.EntityDataType
			if not @_columns
				columnConfigs = []
				for propertyDef in dataType.getProperties().elements
					columnConfigs.push(
						caption: propertyDef._caption
						bind: propertyDef._property
					)
				@set("columns", columnConfigs)

			if @_columns
				for column in @_columns
					if not column._property then continue

					propertyDef = dataType.getProperty(column._property)
					column._propertyDef = propertyDef
					if propertyDef and not column._caption
						column._caption = propertyDef._caption or propertyDef._property
		return

	_parseDom: (dom) ->
		return unless dom
		@_doms ?= {}

		child = dom.firstElementChild
		while child
			cola.xRender(child)
			child.setAttribute(cola.constants.IGNORE_DIRECTIVE, "")
			child = child.nextElementSibling

		columns = []
		child = dom.firstElementChild
		while child
			next = child.nextElementSibling
			nodeName = child.nodeName
			if nodeName is "TEMPLATE"
				@regTemplate(child)
			else
				if nodeName is "COLUMN"
					column = @_parseColumnDom(child)
				else if nodeName is "SELECT-COLUMN"
					column = @_parseColumnDom(child)
					column.$type = "select"
				else if nodeName is "STATE-COLUMN"
					column = @_parseColumnDom(child)
					column.$type = "state"
				if column then columns.push(column)
				dom.removeChild(child)
			child = next

		@set("columns", columns) if columns.length

		@_createInnerDom(dom)
		return

	_parseColumnDom: (dom) ->
		column = {}
		for attr in dom.attributes
			attrName = attr.name
			if attrName.substring(0, 2) is "c-"
				expression = cola._compileExpression(@_scope, attr.value)
				column[attrName.substring(2)] = expression
			else
				column[attrName] = attr.value

		child = dom.firstElementChild
		while child
			next = child.nextElementSibling
			nodeName = child.nodeName
			if nodeName is "TEMPLATE"
				templateName = child.getAttribute("name")
				if templateName and templateName.indexOf("header") is 0
					templateName = "headerTemplate"
				else if templateName and templateName.indexOf("footer") is 0
					templateName = "footerTemplate"
				else
					templateName = "template"
				column[templateName] = @trimTemplate(child)
			else if child.nodeType is 1
				subColumn = @_parseColumnDom(child)
				column.columns ?= []
				column.columns.push(subColumn)
			child = next
		return column

	_doSet: (attr, attrConfig, value) ->
		if attrConfig?.refreshItems
			attrConfig.refreshDom = true
			@_refreshItemsScheduled = true
		return super(attr, attrConfig, value)

	_buildStyleSheet: ()->
		getGroupWidth = (colInfo) ->
			width = 0
			for subColInfo in colInfo.columns
				if subColInfo.columns
					width += getGroupWidth(subColInfo)
				else
					width += subColInfo.width
			return width

		columnCssDefs = []
		for rowInfo in @_columnsInfo.rows
			for colInfo in rowInfo
				if colInfo.columns
					colInfo.realWidth = getGroupWidth(colInfo)

				def = "." + colInfo.column._id + "{"
				def += "width:" + (colInfo.realWidth or colInfo.width or 100) + "px;"

				def += "}"
				columnCssDefs.push(def)

		head = document.querySelector("head") or document.documentElement
		@_styleSheetDom ?= $.xCreate(
			tagName: "style"
			type: "text/css"
		)
		@_styleSheetDom.innerHTML = "\n" + columnCssDefs.join("\n") + "\n"
		head.appendChild(@_styleSheetDom)
		return

	_doRefreshDom: (dom)->
		if @_columnsTimestamp isnt @_columnsInfo.timestamp
			@_columnsTimestamp = @_columnsInfo.timestamp

			if @_columnsInfo.left and not @_leftTable
				@_leftTable = new cola.Table.InnerTable(
					table: @
				)
				@_centerTable.get$Dom().before(@_leftTable.getDom())
			if @_columnsInfo.right and not @_leftTable
				@_rightTable = new cola.Table.InnerTablee(
					table: @
				)
				@_centerTable.get$Dom().after(@_rightTable.getDom())

			@_buildStyleSheet()

			@_leftTable?.set("columnsInfo", @_columnsInfo.left)
			@_rightTable?.set("columnsInfo", @_columnsInfo.right)
			@_centerTable.set("columnsInfo", @_columnsInfo.center)

		super(dom)

		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_refreshItems()
		return

	refreshItem: (item) ->
		@_leftTable?.refreshItem(item)
		@_rightTable?.refreshItem(item)
		@_centerTable.refreshItem(item)
		return

	_onItemRefresh: (arg) ->
		item = arg.entity
		if typeof item is "object"
			@refreshItem(item)
		return

	_onItemsRefresh: () ->
		return @_refreshItems()

	_refreshItems: () ->
		@_leftTable?._refreshItems()
		@_rightTable?._refreshItems()
		@_centerTable._refreshItems()
		return

	_onCurrentItemChange: (arg) ->
		@_leftTable?._onCurrentItemChange(arg)
		@_rightTable?._onCurrentItemChange(arg)
		@_centerTable._onCurrentItemChange(arg)
		return

	_onItemInsert: (arg) ->
		@_leftTable?._onItemInsert(arg)
		@_rightTable?._onItemInsert(arg)
		@_centerTable._onItemInsert(arg)

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 100, () =>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_onItemRemove: (arg) ->
		@_leftTable?._onItemRemove(arg)
		@_rightTable?._onItemRemove(arg)
		@_centerTable._onItemRemove(arg)

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 100, () =>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_onBlur: (evt) ->
		@_currentInnerTable?.hideCellEditor()
		return

	_onKeyDown: (evt) ->

		findNextColumn = (column) =>
			dataColumns = @_columnsInfo.dataColumns
			i = dataColumns.indexOf(column)
			if i < 0 or i >= dataColumns.length - 1
				i = 0
			else
				i++
			return dataColumns[i]

		if evt.keyCode is 9 # Tab
			return unless @_currentItem

			nextColumn = findNextColumn(@_currentColumn)
			if @_columnsInfo.center.dataColumns.indexOf(nextColumn) >= 0
				innerTable = @_centerTable
			else if @_columnsInfo.left?.dataColumns.indexOf(nextColumn) >= 0
				innerTable = @_leftTable
			else if @_columnsInfo.right?.dataColumns.indexOf(nextColumn) >= 0
				innerTable = @_rightTable

			innerTable.setCurrentCell(@_currentItem, nextColumn)
		return

cola.Element.mixin(cola.Grid, cola.TemplateSupport)
cola.Element.mixin(cola.Grid, cola.DataItemsWidgetMixin)

class cola.Table.InnerTable extends cola.AbstractList
	@CLASS_NAME: "inner-table"

	@attributes:
		table: null
		columnsInfo: null

	constructor: (config) ->
		@_itemsScope = config.table._itemsScope
		super(config)
		@_focusParent = @_table

	_createItemsScope: () -> @_itemsScope

	_getItems: () -> @_table._getItems()

	_createDom: () ->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			content:
				class: "table-body"
				contextKey: "tableBody"
				content:
					tagName: "ul"
					contextKey: "itemsWrapper"
				scroll: (evt) =>
					scrollLeft = evt.target.scrollLeft
					@_doms.tableHeader?.scrollLeft = scrollLeft
					@_doms.tableFooter?.scrollLeft = scrollLeft
					return
		}, @_doms)

		$fly(@_doms.itemsWrapper).delegate(".cell", "mousedown", (evt) =>
			return if @_readOnly

			cell = evt.currentTarget
			columnName = cell._name
			column = @_table.getColumn(columnName)
			item = @getItemByItemDom(cell.parentNode)
			@setCurrentCell(item, column)

			#			eventArg =
			#				column: column
			#			if column.fire("headerClick", @, eventArg) isnt false
			#				if @fire("headerClick", @, eventArg) isnt false
			#					@_sysHeaderClick(column)
			return
		)
		return dom

	_createNewItem: (itemType, item) ->
		template = @_table.getTemplate(itemType + "-row")
		itemDom = @_table._cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom

	_doRefreshItems: (itemsWrapper) ->
		return unless @_columnsInfo

		if @_table._showHeader
			header = @_doms.header
			if not header
				$fly(@_doms.tableBody).xInsertBefore({
					class: "table-header"
					contextKey: "tableHeader"
					content:
						tagName: "table"
						cellSpacing: 0
						cellPadding: 0
						content:
							tagName: "tbody"
							contextKey: "header"
				}, @_doms)
				header = @_doms.header

				$fly(header).delegate(".header-cell", "click", (evt) =>
					columnName = evt.currentTarget._name
					column = @_table.getColumn(columnName)
					eventArg =
						column: column
					if column.fire("headerClick", @, eventArg) isnt false
						if @_table.fire("headerClick", @, eventArg) isnt false
							@_sysHeaderClick(column)
					return
				)

			@_refreshHeader(header)
			@_doms.tableBody.style.paddingTop = @_doms.tableHeader.offsetHeight + "px"

		if @_table._showFooter
			footer = @_doms.footer
			if not footer
				$fly(@_doms.tableBody).xInsertAfter({
					class: "table-footer"
					contextKey: "tableFooter"
					content:
						contextKey: "footer"
				}, @_doms)

				footer = @_doms.footer
				$fly(footer).delegate(".footer-cell", "click", (evt) =>
					columnName = evt.currentTarget._name
					column = @_table.getColumn(columnName)
					eventArg =
						column: column
					if column.fire("footerClick", @, eventArg) isnt false
						@fire("footerClick", @, eventArg)
					return
				)
			@_refreshFooter(footer)
			@_doms.tableBody.style.paddingBottom = @_doms.tableFooter.offsetHeight + "px"

		super(itemsWrapper)

		rightMargin = (@_doms.tableBody.offsetWidth - @_doms.tableBody.clientWidth) + "px";
		@_doms.tableHeader?.style.right = rightMargin
		@_doms.tableFooter?.style.right = rightMargin

		return

	_refreshHeader: (header) ->
		return if @_headerTimestamp is @_columnsInfo.timestamp
		@_headerTimestamp = @_columnsInfo.timestamp

		$fly(header).empty()

		fragment = null
		rowInfos = @_columnsInfo.rows
		i = 0
		len = rowInfos.length
		while i < len
			row = header.childNodes[i]
			if not row
				row = $.xCreate(
					tagName: "tr"
					class: "header-row"
				)
				fragment ?= document.createDocumentFragment()
				fragment.appendChild(row)

			rowInfo = rowInfos[i]
			for colInfo, j in rowInfo
				column = colInfo.column

				cell = $.xCreate({
					tagName: "td"
					class: "header-cell " + column._id + " h-center"
					content:
						tagName: "div"
				})
				cell._name = column._name
				row.appendChild(cell)

				if colInfo.columns
					cell.rowSpan = 1
					cell.colSpan = colInfo.columns.length
				else
					cell.rowSpan = len - i
					cell.colSpan = 1
				contentWrapper = cell.firstElementChild

				@_refreshHeaderCell(contentWrapper, colInfo)

			cola.xRender(row, @_scope)
			i++

		if fragment then header.appendChild(fragment)
		return

	_refreshHeaderCell: (dom, columnInfo) ->
		column = columnInfo.column

		$cell = $fly(dom.parentNode)
		$cell.toggleClass("sortable", !!column._sortable).removeClass("asc desc")
		if column._sortDirection then $cell.addClass(column._sortDirection)

		if column.renderHeader
			if column.renderHeader(dom) != true
				return

		if column.getListeners("renderHeader")
			if column.fire("renderHeader", column, { dom: dom }) == false
				return

		if @getListeners("renderHeaderCell")
			if @fire("renderHeaderCell", @, { column: column, dom: dom }) == false
				return

		template = column.getTemplate("headerTemplate")
		if template
			template = @_cloneTemplate(template)
			dom.appendChild(template)
		return if column._real_headerTemplate

		caption = column._caption or column._name
		if caption?.charCodeAt(0) == 95 # `_`
			caption = column._bind
		dom.innerText = caption or ""
		return

	_refreshFooter: (footer) ->

	_doRefreshItemDom: (itemDom, item, itemScope) ->
		itemType = itemDom._itemType

		if @getListeners("renderRow")
			if @fire("renderRow", @, { item: item, dom: itemDom, scope: itemScope }) == false
				return

		if itemType == "default"
			colInfos = @_columnsInfo.dataColumns
			for colInfo, i in colInfos
				column = colInfo.column
				cell = itemDom.childNodes[i]
				while cell and cell._name != column._name
					itemDom.removeChild(cell)
					cell = itemDom.childNodes[i]

				if not cell
					isNew = true
					cell = $.xCreate({
						tagName: "div"
						content:
							tagName: "div"
					})
					cell._name = column._name
					itemDom.appendChild(cell)

				exClass = ""
				if column._align
					exClass = " h-" + column._align
				if column._valign
					exClass += " v-" + column._valign

				cell.className = "cell " + column._id + (exClass or "")
				contentWrapper = cell.firstElementChild

				@_refreshCell(contentWrapper, item, colInfo, itemScope, isNew)

			while itemDom.lastChild and itemDom.lastChild != cell
				itemDom.removeChild(itemDom.lastChild)
		return

	_refreshCell: (dom, item, columnInfo, itemScope, isNew) ->
		column = columnInfo.column

		if column.renderCell
			if column.renderCell(dom, item, itemScope) != true
				return

		if column.getListeners("renderCell")
			if column.fire("renderCell", column, { item: item, dom: dom, scope: itemScope }) == false
				return

		if @getListeners("renderCell")
			if @fire("renderCell", @,
			  { item: item, column: column, dom: dom, scope: itemScope }) == false
				return

		if isNew
			template = column.getTemplate("template")
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
				if column._property
					if column._format
						context = {
							defaultPath: "format(#{@_alias}.#{column._property},#{column._format})"
						}
					else
						context = {
							defaultPath: "#{@_alias}.#{column._property}"
						}
				cola.xRender(dom, itemScope, context)

		return if column._real_template

		$dom = $fly(dom).addClass("default-content")
		if columnInfo.expression
			$dom.attr("c-bind", columnInfo.expression.raw)
		else if column._property
			value = item.get(column._property)
			if column._format
				value = cola.defaultAction.format(value, column._format)
			else
				if value instanceof Date
					defaultDateFormat = cola.setting("defaultDateFormat")
					if defaultDateFormat
						value = cola.defaultAction.formatDate(value, defaultDateFormat)
			value = "" if value is undefined or value is null
			$dom.text(value)
		return

	refreshItem: (item) ->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_refreshItemDom(itemDom, item, @_itemsScope)
		return

	setCurrentCell: (item, column) ->
		@_table._currentInnerTable = @
		@_table._currentColumn = column
		@showCellEditor(item, column)
		return

	_getCellEditorPane: (create) ->
		if not @_cellEditorPane and create
			@_cellEditorPane = cola.xCreate(
				class: "cell-editor-pane"
			)
			@_doms.itemsWrapper.appendChild(@_cellEditorPane)
		return @_cellEditorPane

	_resize: (editorPane, item, column) ->
		itemId = _getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			child = itemDom.firstElementChild
			while child
				if child._name is column._name
					cell = child
					break
				child = child.nextElementSibling

			if cell
				$fly(@_cellEditorPane)
					.css("left", cell.offsetLeft)
					.css("top", itemDom.offsetTop)
					.width(cell.clientWidth)
					.height(cell.clientHeight)
		return

	showCellEditor: (item, column) ->
		return unless item
		return if column._readOnly or not column._property

		if not column._editTemplate
			propertyType = column._propertyDef?._dataType
			if propertyType instanceof cola.BooleanDataType
				template = "checkbox"
			else if propertyType instanceof cola.DateDataType
				template = "date-picker"
			else
				template = "input"
		template = column.getTemplate("editTemplate", template)

		if template
			editorPane = @_getCellEditorPane(true)
			$fly(editorPane).addClass("hidden")

			setTimeout(() =>
				templateDom = column._editTemplateDom
				if not templateDom
					scope = new cola.ItemScope(@_scope, @_table._alias)
					scope.data.setItemData(item, true)

					oldScope = cola.currentScope
					try
						cola.currentScope = scope
						column._editTemplateDom = templateDom = @_cloneTemplate(template)
						cola.util.userData(templateDom, "scope", scope)
						context = {
							defaultPath: "#{@_table._alias}.#{column._property}"
						}
						cola.xRender(templateDom, scope, context)
					finally
						cola.currentScope = oldScope
				else
					scope = cola.util.userData(templateDom, "scope")
					scope.data.setItemData(item)

				$fly(editorPane).removeClass("hidden")

				if templateDom.parentNode isnt editorPane
					if editorPane.firstElementChild
						cola.util.cacheDom(editorPane.firstElementChild)
					editorPane.appendChild(templateDom)

				@_resize(editorPane, item, column)

				cellEditorWidget = cola.widget(templateDom)
				cellEditorWidget?.focus?()
				return
			, 0)
		return

	hideCellEditor: () ->
		editorPane = @_getCellEditorPane()
		if editorPane
			$fly(editorPane).addClass("hidden")
		return