class cola.Table extends cola.AbstractTable
	@tagName: "c-table"
	@CLASS_NAME: "items-view widget-table"

	_initDom: (dom) ->
		super(dom)
		$fly(window).resize () =>
			if @_fixedHeaderVisible
				fixedHeader = @_getFixedHeader()
				$fly(fixedHeader).width(@_doms.itemsWrapper.clientWidth)
			if @_fixedFooterVisible
				fixedFooter = @_getFixedFooter()
				$fly(fixedFooter).width(@_doms.itemsWrapper.clientWidth)
			return
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

			if @fire("sortDirectionChange", @, {
				column: column
				sortDirection: sortDirection
			}) is false
				return

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

			if @_sortMode is "remote"
				if collection instanceof cola.EntityList
					invoker = collection._providerInvoker
					if invoker
						parameter = invoker.invokerOptions.data
						if not parameter
							invoker.invokerOptions.data = parameter = {}
						else if typeof parameter isnt "object" or parameter instanceof Date
							throw new cola.Exception("Can not set sort parameter automatically.")
						parameter.sort = criteria

						provider = invoker.ajaxService
						parameter = provider.get("parameter")
						if not parameter
							provider.set("parameter", parameter = {})
						else if typeof parameter isnt "object" or parameter instanceof Date
							throw new cola.Exception("Can not set sort parameter automatically.")
						parameter.sort = criteria

						cola.util.flush(collection)
						processed = true

				if not processed
					throw new cola.Exception("Remote sort not supported.")
			else
				@_sortCriteria = criteria
				@_refreshItems()
		return

	_doRefreshItems: () ->
		return unless @_columnsInfo

		dataType = @_getBindDataType()
		if not @_columnsInfo.dataColumns.length and dataType and dataType instanceof cola.EntityDataType
			columnConfigs = []
			for propertyDef in dataType.getProperties().elements
				columnConfigs.push(
					bind: propertyDef._property
				)
			@set("columns", columnConfigs)

		colgroup = @_doms.colgroup
		nextCol = colgroup.firstChild
		for colInfo, i in @_columnsInfo.dataColumns
			col = nextCol
			if !col
				col = document.createElement("col")
				colgroup.appendChild(col)
			else
				nextCol = col.nextSibling

			if colInfo.widthType == "precent"
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
			nextCol = col.nextSibling
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
				$fly(tfoot).delegate("td", "click", (evt) ->
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

				if !cell
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
				contentWrapper = cell.firstChild

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
			template = column._realHeaderTemplate
			if template == undefined
				templateName = column._headerTemplate
				if templateName
					template = @getTemplate(templateName)
				column._realHeaderTemplate = template or null
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
		return if column._realHeaderTemplate

		dataType = @_getBindDataType()
		if dataType and column._property
			propertyDef = dataType.getProperty(column._property)

		caption = column._caption or propertyDef?._caption
		if !caption
			caption = column._name
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

			if !cell
				isNew = true
				cell = $.xCreate({
					tagName: "td"
					content:
						tagName: "div"
				})
				cell._name = column._name
				row.appendChild(cell)
			contentWrapper = cell.firstChild

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
			template = column._realFooterTemplate
			if template == undefined
				templateName = column._footerTemplate
				if templateName
					template = @getTemplate(templateName)
				column._realFooterTemplate = template or null
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
		return if column._realFooterTemplate

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

				if !cell
					isNew = true
					cell = $.xCreate({
						tagName: "td"
						content:
							tagName: "div"
					})
					cell._name = column._name
					itemDom.appendChild(cell)
				contentWrapper = cell.firstChild

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
			template = column._realTemplate
			if template == undefined
				templateName = column._template
				if templateName
					template = @getTemplate(templateName)
				column._realTemplate = template or null
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

		return if column._realTemplate

		$dom = $fly(dom)
		if columnInfo.expression
			$dom.attr("c-bind", columnInfo.expression.raw)
		else
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
		nextCell = row.firstChild
		for colInfo, i in @_columnsInfo.dataColumns
			cell = nextCell
			if !cell
				cell = $.xCreate({
					tagName: "td"
				})
				row.appendChild(cell)
			else
				nextCell = nextCell.nextSibling

		while nextCell
			cell = nextCell
			nextCell = nextCell.nextSibling
			row.removeChild(cell)
		return

	_getFixedHeader: (create) ->
		fixedHeaderWrapper = @_doms.fixedHeaderWrapper
		if !fixedHeaderWrapper and create
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
			@_refreshFakeRow(fakeThead.firstChild)
			$fly(@_doms.tbody).before(fakeThead)
		return fixedHeaderWrapper

	_getFixedFooter: (create) ->
		fixedFooterWrapper = @_doms.fixedFooterWrapper
		if !fixedFooterWrapper and create
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
			@_refreshFakeRow(fakeTfoot.firstChild)
			$fly(@_doms.tbody).after(fakeTfoot)
		return fixedFooterWrapper

	_refreshFixedColgroup: (colgroup, fixedColgroup) ->
		nextCol = colgroup.firstChild
		nextFixedCol = fixedColgroup.firstChild
		while nextCol
			col = nextCol
			nextCol = nextCol.nextSibling

			fixedCol = nextFixedCol
			if !fixedCol
				fixedCol = document.createElement("col")
			else
				nextFixedCol = nextFixedCol.nextSibling

			fixedCol.width = col.width
			fixedCol.valign = col.valign

		while nextFixedCol
			fixedCol = nextFixedCol
			nextFixedCol = nextFixedCol.nextSibling
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
		$fly(@_doms.fakeThead.firstChild).height(@_doms.thead.offsetHeight)
		return

	_setFixedFooterSize: () ->
		colgroup = @_doms.colgroup
		fixedFooterColgroup = @_doms.fixedFooterColgroup
		if !fixedFooterColgroup
			@_doms.fixedFooterColgroup = fixedFooterColgroup = colgroup.cloneNode(true)
			@_doms.fixedFooterTable.appendChild(fixedFooterColgroup)
		else
			@_refreshFixedColgroup(colgroup, fixedFooterColgroup)
		$fly(@_doms.fakeTfoot.firstChild).height(@_doms.tfoot.offsetHeight)
		return

	_refreshFixedHeader: () ->
		itemsWrapper = @_doms.itemsWrapper
		scrollTop = itemsWrapper.scrollTop
		showFixedHeader = scrollTop > 0
		return if showFixedHeader == @_fixedHeaderVisible

		@_fixedHeaderVisible = showFixedHeader
		if showFixedHeader
			fixedHeader = @_getFixedHeader(true)
			@_setFixedHeaderSize()
			$fly(@_doms.tbody).before(@_doms.fakeThead)
			@_doms.fixedHeaderTable.appendChild(@_doms.thead)
			$fly(fixedHeader).width(itemsWrapper.clientWidth).show()
		else
			fixedHeader = @_getFixedHeader()
			if fixedHeader
				$fly(fixedHeader).hide()
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
		showFixedFooter = scrollTop < maxScrollTop
		return if showFixedFooter == @_fixedFooterVisible

		@_fixedFooterVisible = showFixedFooter
		if showFixedFooter
			fixedFooter = @_getFixedFooter(true)
			@_setFixedFooterSize()
			$fly(@_doms.tbody).after(@_doms.fakeTfoot)
			@_doms.fixedFooterTable.appendChild(@_doms.tfoot)
			$fixedFooter = $fly(fixedFooter).width(itemsWrapper.clientWidth)
			if duration
				$fixedFooter.fadeIn(duration)
			else
				$fixedFooter.show()
		else
			fixedFooter = @_getFixedFooter()
			if fixedFooter
				$fly(fixedFooter).hide()
				@_doms.fixedFooterTable.appendChild(@_doms.fakeTfoot)
				$fly(@_doms.tbody).after(@_doms.tfoot)
		return

	_onItemsWrapperScroll: () ->
		@_refreshFixedHeader() if @_showHeader
		@_refreshFixedFooter() if @_showFooter
		return super()

cola.registerWidget(cola.Table)
