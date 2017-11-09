_columnsSetter = (table, columnConfigs) ->
	if table?._columns
		for column in table._columns
			column._setTable(null)

	columns = []
	if columnConfigs
		for columnConfig in columnConfigs
			continue unless columnConfig
			if columnConfig instanceof cola.TableColumn
				column = columnConfig
			else
				column = cola.create("table.column", columnConfig, cola.TableColumn)
			column._setTable(table)
			columns.push(column)
	@_columns = columns
	return

class cola.AbstractTable extends cola.AbstractList
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
				_columnsSetter.call(@, @, columnConfigs)
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
		"default":
			tagName: "tr"
		"boolean-column":
			"c-display": "$default"
			content:
				tagName: "i"
				class: "green checkmark icon"
		"checkbox-column":
			tagName: "c-checkbox"
			class: "in-cell"
			bind: "$default"
		"toggle-column":
			tagName: "c-toggle"
			class: "in-cell"
			bind: "$default"
		"input-column":
			tagName: "c-input"
			class: "in-cell"
			bind: "$default"
		"date-column":
			tagName: "c-datepicker"
			class: "in-cell"
			bind: "$default"
		"group-header":
			tagName: "tr"
			content:
				tagName: "td"
				colSpan: 100

	constructor: (config) ->
		@_columnMap = {}
		super(config)

	_getItems: () ->
		if @_items
			return {items: @_items}
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
		collectColumnInfo = (column, context, deepth) ->
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
						cols.push(collectColumnInfo(col, context, deepth + 1))
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

					if not widthType and info.width
						context.totalWidth += info.width

				info.index = context.dataColumns.length
				context.dataColumns.push(info)

				if column instanceof cola.TableSelectColumn
					context.selectColumns ?= []
					context.selectColumns.push(info)

				if context.rows.length == deepth then context.rows[deepth] = []
				context.rows[deepth].push(info)
			return info

		@_columnsInfo = columnsInfo = {
			totalWidth: 0
			rows: [[]]
			dataColumns: []
			alias: "item"
		}
		if @_columns
			expression = @_itemsScope.expression
			if expression
				columnsInfo.alias = expression.alias

			for col in @_columns
				continue unless col._visible
				collectColumnInfo(col, columnsInfo, 0)
		return

	_getBindDataType: () ->
		return @_dataType if @_dataType
		return @_dataType = super()

	_createDom: ()->
		dom = document.createElement("div")
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerDom: (dom) ->
		$fly(dom).xAppend({
			tagName: "div"
			class: "table-wrapper"
			contextKey: "itemsWrapper"
			content:
				tagName: "table"
				contextKey: "table"
				content: [
					{
						tagName: "colgroup"
						contextKey: "colgroup"
						span: 100
					},
					{
						tagName: "tbody"
						class: "items"
						contextKey: "tbody"
					}
				]
		}, @_doms)

		$fly(@_doms.tbody).delegate(">tr >td", "click", (evt) =>
			columnName = evt.currentTarget._name
			column = @getColumn(columnName)
			eventArg =
				column: column
			if column.fire("cellClick", @, eventArg) isnt false
				@fire("cellClick", @, eventArg)
			return
		)
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

	_createNewItem: (itemType, item) ->
		template = @getTemplate(itemType)
		itemDom = @_cloneTemplate(template)
		$fly(itemDom).addClass("table item " + itemType)
		itemDom._itemType = itemType
		return itemDom

class cola.Table extends cola.AbstractTable
	@tagName: "c-table"
	@CLASS_NAME: "items-view widget-table"

	_initDom: (dom) ->
		super(dom)

		dataType = @_getBindDataType()
		if dataType and dataType instanceof cola.EntityDataType
			if not @_columnsInfo.dataColumns.length
				columnConfigs = []
				for propertyDef in dataType.getProperties().elements
					columnConfigs.push(
						caption: propertyDef._caption
						bind: propertyDef._property
					)
				@set("columns", columnConfigs)
			else
				for columnInfo in @_columnsInfo.dataColumns
					column = columnInfo.column
					if not column._property then continue

					propertyDef = dataType.getProperty(column._property)
					if propertyDef
						if not column._caption
							caption = propertyDef._caption or propertyDef._property
							if caption?.charCodeAt(0) is 95 # `_`
								caption = column._bind
							column.set("caption", caption)

						if column._template is "$autoEditable"
							propertyType = propertyDef.get("dataType")

							if propertyType instanceof cola.BooleanDataType
								template = "checkbox-column"
							else if propertyType instanceof cola.DateDataType
								template = "date-column"
							else
								template = "input-column"
							column.set("template", template)

		$fly(window).resize () =>
			if @_fixedHeaderVisible
				fixedHeader = @_getFixedHeader()
				$fly(fixedHeader).width(@_doms.itemsWrapper.clientWidth)
			if @_fixedFooterVisible
				fixedFooter = @_getFixedFooter()
				$fly(fixedFooter).width(@_doms.itemsWrapper.clientWidth)
			return
		@_bindKeyDown()
		return

	_convertItems: (items) ->
		items = super(items)
		if @_sortCriteria
			items = cola.util.sort(items, @_sortCriteria)
		return items

	_sysHeaderClick: (column) ->
		if column instanceof cola.TableDataColumn and column.get("sortable")
			sortDirection = column.get("sortDirection")
			if sortDirection is "asc" then sortDirection = "desc"
			else if sortDirection is "desc" then sortDirection = null
			else sortDirection = "asc"
			column.set("sortDirection", sortDirection)

			collection = @_realOriginItems or @_realItems
			if not collection then return

			if not sortDirection
				criteria = null
			else
				criteria = if sortDirection is "asc" then "+" else "-"
				property = column._bind
				if not property or property.match(/\(/)
					property = column._property
				if not property then return

				if property.charCodeAt(0) is 46 # `.`
					property = property.slice(1)
				else if @_alias and property.indexOf("." + @_alias) is 0
					property = property.slice(@_alias.length + 1)
				criteria += property

			colInfos = @_columnsInfo.dataColumns
			for colInfo in colInfos
				col = colInfo.column
				if col isnt column then col.set("sortDirection", null)

			if @_sortMode is "remote"
				if collection instanceof cola.EntityList
					invoker = collection._providerInvoker

				if @fire("sortDirectionChange", @, {
					column: column
					invoker: invoker
					sortDirection: sortDirection
				}) is false
					return

				if collection instanceof cola.EntityList and invoker
					parameter = invoker.ajaxService.get("parameter")
					if not parameter
						invoker.invokerOptions.data = parameter = {}
					else if typeof parameter isnt "object" or parameter instanceof cola.EntityList or parameter instanceof Date
						throw new cola.Exception("Can not set sort parameter automatically.")
					else if parameter instanceof cola.Entity
						parameter = parameter.toJSON()
					parameter[cola.setting("defaultSortParameter") or sort] = criteria

					cola.util.flush(collection)
			else
				if @fire("sortDirectionChange", @, {
					column: column
					sortDirection: sortDirection
				}) is false
					return

				@_sortCriteria = criteria
				@_refreshItems()
		return

	_doRefreshItems: () ->
		return unless @_columnsInfo

		colgroup = @_doms.colgroup
		nextCol = colgroup.firstElementChild
		for colInfo, i in @_columnsInfo.dataColumns
			col = nextCol
			if not col
				col = document.createElement("col")
				colgroup.appendChild(col)
			else
				nextCol = col.nextElementSibling

			if colInfo.widthType == "percent"
				col.width = colInfo.width + "%"
			else if colInfo.widthType
				col.width = colInfo.width + colInfo.widthType
			else if colInfo.width
				col.width = (colInfo.width * 100 / @_columnsInfo.totalWidth) + "%"
			else
				col.width = ""

			column = colInfo.column
			col.valign = column._valign or ""

		col = nextCol
		while col
			nextCol = col.nextElementSibling
			colgroup.removeChild(col)
			col = nextCol

		tbody = @_doms.tbody

		if @_showHeader
			thead = @_doms.thead
			if not thead
				$fly(tbody).xInsertBefore({
					tagName: "thead"
					contextKey: "thead"
				}, @_doms)

				thead = @_doms.thead

				$fly(thead).delegate("th", "click", (evt) =>
					columnName = evt.currentTarget._name
					column = @getColumn(columnName)
					eventArg =
						column: column
					if column.fire("headerClick", @, eventArg) isnt false
						if @fire("headerClick", @, eventArg) isnt false
							@_sysHeaderClick(column)
					return
				)

			@_refreshHeader(thead)

		super(tbody)

		if @_showFooter
			tfoot = @_doms.tfoot
			if !tfoot
				$fly(tbody).xInsertAfter({
					tagName: "tfoot"
					contextKey: "tfoot"
				}, @_doms)

				tfoot = @_doms.tfoot
				$fly(tfoot).delegate("td", "click", (evt) =>
					columnName = evt.currentTarget._name
					column = @getColumn(columnName)
					eventArg =
						column: column
					if column.fire("footerClick", @, eventArg) isnt false
						@fire("footerClick", @, eventArg)
					return
				)
			@_refreshFooter(tfoot)

			if !@_fixedFooterVisible
				@_showFooterTimer = setInterval(() =>
					itemsWrapper = @_doms.itemsWrapper
					if itemsWrapper.scrollHeight
						@_refreshFixedFooter(300)
					return
				, 300)
		return

	_onItemInsert: (arg) ->
		super(arg)

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 100, () =>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_onItemRemove: (arg) ->
		super(arg)
		@_refreshFixedFooter() if @_showFooter

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 100, () =>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_refreshHeader: (thead) ->
		fragment = null
		rowInfos = @_columnsInfo.rows
		i = 0
		len = rowInfos.length
		while i < len
			row = thead.rows[i]
			if !row
				row = $.xCreate(
					tagName: "tr"
				)
				fragment ?= document.createDocumentFragment()
				fragment.appendChild(row)

			rowInfo = rowInfos[i]
			for colInfo, j in rowInfo
				column = colInfo.column
				cell = row.cells[j]
				while cell and cell._name != column._name
					row.removeChild(cell)
					cell = row.cells[j]

				if not cell
					isNew = true
					cell = $.xCreate({
						tagName: "th"
						content:
							tagName: "div"
					})
					cell._name = column._name
					row.appendChild(cell)
				cell._index = colInfo.index
				if colInfo.columns
					cell.rowSpan = 1
					cell.colSpan = colInfo.columns.length
				else
					cell.rowSpan = len - i
					cell.colSpan = 1
				contentWrapper = cell.firstElementChild

				@_refreshHeaderCell(contentWrapper, colInfo, isNew)

			while row.lastChild and row.lastChild != cell
				row.removeChild(row.lastChild)
			cola.xRender(row, @_scope)
			i++

		if fragment then thead.appendChild(fragment)
		while thead.lastChild and thead.lastChild != row
			thead.removeChild(thead.lastChild)
		return

	_refreshHeaderCell: (dom, columnInfo, isNew) ->
		column = columnInfo.column
		dom.style.textAlign = column._align or "left"

		$cell = $fly(dom.parentNode)
		$cell.toggleClass("sortable", !!column._sortable).removeClass("asc desc")
		if column._sortDirection then $cell.addClass(column._sortDirection)

		if column.renderHeader
			if column.renderHeader(dom) != true
				return

		if column.getListeners("renderHeader")
			if column.fire("renderHeader", column, {dom: dom}) == false
				return

		if @getListeners("renderHeaderCell")
			if @fire("renderHeaderCell", @, {column: column, dom: dom}) == false
				return

		if isNew
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

	_refreshFooter: (tfoot) ->
		colInfos = @_columnsInfo.dataColumns
		row = tfoot.rows[0]
		if !row
			row = document.createElement("tr")
		for colInfo, i in colInfos
			column = colInfo.column
			cell = row.cells[i]
			while cell and cell._name != column._name
				row.removeChild(cell)
				cell = row.cells[i]

			if not cell
				isNew = true
				cell = $.xCreate({
					tagName: "td"
					content:
						tagName: "div"
				})
				cell._name = column._name
				row.appendChild(cell)
			contentWrapper = cell.firstElementChild

			@_refreshFooterCell(contentWrapper, colInfo, isNew)

		while row.lastChild != cell
			row.removeChild(row.lastChild)

		cola.xRender(row, @_scope)
		if tfoot.rows.length < 1
			tfoot.appendChild(row)
		return

	_refreshFooterCell: (dom, columnInfo, isNew) ->
		column = columnInfo.column
		dom.style.textAlign = column._align or "left"

		if column.renderFooter
			if column.renderFooter(dom) != true
				return

		if column.getListeners("renderFooter")
			if column.fire("renderFooter", column, {dom: dom}) == false
				return

		if @getListeners("renderFooterCell")
			if @fire("renderFooterCell", @, {column: column, dom: dom}) == false
				return

		if isNew
			template = column.getTemplate("footerTemplate")
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
		return if column._real_footerTemplate

		dom.innerHTML = "&nbsp;"
		return

	_doRefreshItemDom: (itemDom, item, itemScope) ->
		itemType = itemDom._itemType

		if @getListeners("renderRow")
			if @fire("renderRow", @, {item: item, dom: itemDom, scope: itemScope}) == false
				return

		if itemType == "default"
			colInfos = @_columnsInfo.dataColumns
			for colInfo, i in colInfos
				column = colInfo.column
				cell = itemDom.cells[i]
				while cell and cell._name != column._name
					itemDom.removeChild(cell)
					cell = itemDom.cells[i]

				if not cell
					isNew = true
					cell = $.xCreate({
						tagName: "td"
						content:
							tagName: "div"
					})
					cell._name = column._name
					itemDom.appendChild(cell)
				contentWrapper = cell.firstElementChild

				@_refreshCell(contentWrapper, item, colInfo, itemScope, isNew)

			while itemDom.lastChild and itemDom.lastChild != cell
				itemDom.removeChild(itemDom.lastChild)
		return

	_refreshCell: (dom, item, columnInfo, itemScope, isNew) ->
		column = columnInfo.column
		dom.style.textAlign = column._align or ""

		if column.renderCell
			if column.renderCell(dom, item, itemScope) != true
				return

		if column.getListeners("renderCell")
			if column.fire("renderCell", column, {item: item, dom: dom, scope: itemScope}) == false
				return

		if @getListeners("renderCell")
			if @fire("renderCell", @,
			  {item: item, column: column, dom: dom, scope: itemScope}) == false
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

		if item instanceof cola.Entity and column._property
			$cell = $fly(dom.parentNode)
			message = item.getKeyMessage(column._property)
			if message
				if typeof message is "string"
					message =
						type: "error"
						text: message

				$cell.removeClass("info warn error").addClass(message.type)

				$cell.attr("data-content", message.text)
				if not dom._popupSetted
					$cell.popup({
						position: "bottom center"
					})
					dom._popupSetted = true
				dom._hasState = true
			else if dom._hasState
				$cell.removeClass("info warn error").attr("data-content", "").popup("destroy")
				dom._hasState = false
				dom._popupSetted = false

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

	_refreshFakeRow: (row) ->
		nextCell = row.firstElementChild
		for colInfo, i in @_columnsInfo.dataColumns
			cell = nextCell
			if !cell
				cell = $.xCreate({
					tagName: "td"
				})
				row.appendChild(cell)
			else
				nextCell = nextCell.nextElementSibling

		while nextCell
			cell = nextCell
			nextCell = nextCell.nextElementSibling
			row.removeChild(cell)
		return

	_getFixedHeader: (create) ->
		fixedHeaderWrapper = @_doms.fixedHeaderWrapper
		if not fixedHeaderWrapper and create
			fixedHeaderWrapper = $.xCreate({
				tagName: "div"
				contextKey: "fixedHeaderWrapper"
				class: "fixed-header table-wrapper"
				content:
					tagName: "table"
					contextKey: "fixedHeaderTable"
			}, @_doms)
			@_dom.appendChild(fixedHeaderWrapper)

			@_doms.fakeThead = fakeThead = $.xCreate(
				tagName: "thead"
				content:
					tagName: "tr"
			)
			@_refreshFakeRow(fakeThead.firstElementChild)
		return fixedHeaderWrapper

	_getFixedFooter: (create) ->
		fixedFooterWrapper = @_doms.fixedFooterWrapper
		if not fixedFooterWrapper and create
			fixedFooterWrapper = $.xCreate({
				tagName: "div"
				contextKey: "fixedFooterWrapper"
				class: "fixed-footer table-wrapper"
				content:
					tagName: "table"
					contextKey: "fixedFooterTable"
			}, @_doms)
			@_dom.appendChild(fixedFooterWrapper, @_doms)

			@_doms.fakeTfoot = fakeTfoot = $.xCreate(
				tagName: "tfoot"
				content:
					tagName: "tr"
			)
			@_refreshFakeRow(fakeTfoot.firstElementChild)
		return fixedFooterWrapper

	_refreshFixedColgroup: (colgroup, fixedColgroup) ->
		nextCol = colgroup.firstElementChild
		nextFixedCol = fixedColgroup.firstElementChild
		while nextCol
			col = nextCol
			nextCol = nextCol.nextElementSibling

			fixedCol = nextFixedCol
			if !fixedCol
				fixedCol = document.createElement("col")
			else
				nextFixedCol = nextFixedCol.nextElementSibling

			fixedCol.width = col.width
			fixedCol.valign = col.valign

		while nextFixedCol
			fixedCol = nextFixedCol
			nextFixedCol = nextFixedCol.nextElementSibling
			fixedColgroup.removeChild(fixedCol)
		return

	_setFixedHeaderSize: () ->
		colgroup = @_doms.colgroup
		fixedHeaderColgroup = @_doms.fixedHeaderColgroup
		if !fixedHeaderColgroup
			@_doms.fixedHeaderColgroup = fixedHeaderColgroup = colgroup.cloneNode(true)
			@_doms.fixedHeaderTable.appendChild(fixedHeaderColgroup)
		else
			@_refreshFixedColgroup(colgroup, fixedHeaderColgroup)
		$fly(@_doms.fakeThead.firstElementChild).height(@_doms.thead.offsetHeight)
		return

	_setFixedFooterSize: () ->
		colgroup = @_doms.colgroup
		fixedFooterColgroup = @_doms.fixedFooterColgroup
		if !fixedFooterColgroup
			@_doms.fixedFooterColgroup = fixedFooterColgroup = colgroup.cloneNode(true)
			@_doms.fixedFooterTable.appendChild(fixedFooterColgroup)
		else
			@_refreshFixedColgroup(colgroup, fixedFooterColgroup)
		$fly(@_doms.fakeTfoot.firstElementChild).height(@_doms.tfoot.offsetHeight)
		return

	_refreshFixedHeader: () ->
		itemsWrapper = @_doms.itemsWrapper
		scrollTop = itemsWrapper.scrollTop
		showFixedHeader = scrollTop > 0 and not (cola.browser.ie is 11)
		return if showFixedHeader == @_fixedHeaderVisible

		@_fixedHeaderVisible = showFixedHeader
		if showFixedHeader
			fixedHeader = @_getFixedHeader(true)
			@_setFixedHeaderSize()
			if @_doms.fakeThead.parentNode
				@_doms.fixedHeaderTable.removeChild(@_doms.fakeThead)
			@_doms.fixedHeaderTable.appendChild(@_doms.thead)
			$fly(@_doms.tbody).before(@_doms.fakeThead)
			$fly(fixedHeader).width(itemsWrapper.clientWidth).show()
		else
			fixedHeader = @_getFixedHeader()
			if fixedHeader
				$fly(fixedHeader).hide()
				@_doms.fixedHeaderTable.removeChild(@_doms.thead)
				@_doms.fixedHeaderTable.appendChild(@_doms.fakeThead)
				$fly(@_doms.tbody).before(@_doms.thead)
		return

	_refreshFixedFooter: (duration) ->
		if @_showFooterTimer
			clearInterval(@_showFooterTimer)
			delete @_showFooterTimer

		itemsWrapper = @_doms.itemsWrapper
		scrollTop = itemsWrapper.scrollTop
		maxScrollTop = itemsWrapper.scrollHeight - itemsWrapper.clientHeight
		showFixedFooter = scrollTop < maxScrollTop and not (cola.browser.ie is 11)
		return if showFixedFooter == @_fixedFooterVisible

		@_fixedFooterVisible = showFixedFooter
		if showFixedFooter
			fixedFooter = @_getFixedFooter(true)
			@_setFixedFooterSize()
			if @_doms.fakeTfoot.parentNode
				@_doms.fixedFooterTable.removeChild(@_doms.fakeTfoot)
			@_doms.fixedFooterTable.appendChild(@_doms.tfoot)
			$fly(@_doms.tbody).after(@_doms.fakeTfoot)
			$fixedFooter = $fly(fixedFooter).width(itemsWrapper.clientWidth)
			if duration
				$fixedFooter.fadeIn(duration)
			else
				$fixedFooter.show()
		else
			fixedFooter = @_getFixedFooter()
			if fixedFooter
				$fly(fixedFooter).hide()
				@_doms.fixedFooterTable.removeChild(@_doms.tfoot)
				@_doms.fixedFooterTable.appendChild(@_doms.fakeTfoot)
				$fly(@_doms.tbody).after(@_doms.tfoot)
		return

	_onItemsWrapperScroll: () ->
		@_refreshFixedHeader() if @_showHeader
		@_refreshFixedFooter() if @_showFooter
		return super()

	_bindKeyDown: ()->
		table = @

		#修复tab切换焦点时不切换当前的Bug
		$(@_dom).delegate("input", "keydown", (event)->
			td = $(this).closest("td")[0]
			targetRow = $(td).parent()[0]
			item = cola.util.userData(targetRow, "item")
			if targetRow._itemType == "default"
				if item
					if table._changeCurrentItem and item.parent instanceof cola.EntityList
						item.parent.setCurrent(item)
					else
						table._setCurrentItemDom(targetRow)
		)

		#待完善
		$(@_dom).delegate("input", "keydown", (event)->
			keyCode = event.keyCode
			ctrlKey = event.ctrlKey
			td = $(this).closest("td")[0]
			tr = $(td).parent()[0]
			colIndex = $(td).index()
			if keyCode is 38
				targetRow = tr.previousElementSibling;
			else if keyCode is 40
				targetRow = tr.nextElementSibling
			else if ctrlKey && keyCode is 37
				targetCell = td.previousElementSibling;
			else if ctrlKey && keyCode is 39
				targetCell = td.nextElementSibling

			if targetRow
				tds = $(targetRow).find(">td")
				if tds.length >= colIndex then targetCell = tds[colIndex]

				item = cola.util.userData(targetRow, "item")
				if targetRow._itemType == "default"
					if item
						if table._changeCurrentItem and item.parent instanceof cola.EntityList
							item.parent.setCurrent(item)
						else
							table._setCurrentItemDom(targetRow)

			if targetCell
				$input = $(targetCell).find(".ui.input")
				if $input.length > 0
					input = cola.widget($input[0])
					input && input.focus()

			if keyCode == 38 || keyCode == 40 || (ctrlKey && keyCode == 37) || (ctrlKey && keyCode == 39)
				event.preventDefault()
		)

		return

	focus: ()->
		unless @_$dom then return

		table = @_$dom.find("table")[0]
		inputs = $(table.tBodies).find(".ui.input")
		if inputs.length
			input = cola.widget(inputs[0])
			if input then input.focus()


cola.registerWidget(cola.Table)
