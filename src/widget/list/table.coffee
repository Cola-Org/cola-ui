_columnsSetter = (table, columnConfigs)->
	if @_columns
		for column in @_columns
			delete column._parent
			column._setTable(null)

	columns = []
	if columnConfigs
		for columnConfig in columnConfigs
			continue unless columnConfig
			if columnConfig instanceof cola.TableColumn
				column = columnConfig
				if column._parent and column._parent isnt @
					parentColumns = column._parent._columns
					if parentColumns
						i = parentColumns.indexOf(column)
						if i >= 0
							parentColumns.splice(i, 1)
						column._parent.set("columns", parentColumns)
			else
				column = cola.create("table.column", columnConfig, cola.TableColumn)

			column._parent = @
			column._setTable(table)
			columns.push(column)
	@_columns = columns
	return

class cola.Table extends cola.AbstractTable
	@tagName: "c-table"
	@className: "items-view widget-table"

	@scrollBarWidth = 10

	@attributes:
		items:
			refreshItems: true
			setter: (items)->
				return if @_items is items
				@_set("bind", undefined)
				@_items = items
				return
		bind:
			setter: (bindStr)->
				return if @_bindStr is bindStr
				@_set("items", undefined)
				@_bindSetter(bindStr)
				return

		dataType:
			setter: cola.DataType.dataTypeSetter

		scrollMode:
			defaultValue: "auto" # auto/scroll
			readOnlyAfterCreate: true
		selectedProperty:
			defaultValue: "selected"

		sortMode:
			defaultValue: "remote" # local/remote
		sortCriteria:
			refreshItems: true
			setter: (sortCriteria)->
				@_sortCriteria = sortCriteria
				@_centerTable._sortCriteria = sortCriteria
				return

		readOnly:
			type: "boolean"
			defaultValue: true

		leftFixedCols:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_leftFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

		rightFixedCols:
			type: "number"
			defaultValue: 0
			setter: (value)->
				@_rightFixedCols = value
				if @_rendered then @_collectionColumnsInfo()
				return

		allowNoCurrent:
			type: "boolean"
		currentPageOnly:
			type: "boolean"
			defaultValue: true
		changeCurrentItem:
			type: "boolean"
			defaultValue: true

	@events:
		filterItem: null
		sortDirectionChange: null

	@templates:
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

	_getItems: ()->
		if @_items
			return items: @_items
		else
			return super()

	_convertItems: (items)->
		if @getListeners("filterItem")
			arg = {
				filterCriteria: @_filterCriteria
			}
			items = cola.util.filter(items, (item)=>
				arg.item = item
				return @fire("filterItem", @, arg)
			)
		else
			if @_filterCriteria
				items = cola.util.filter(items, @_filterCriteria)
			if @_sortCriteria
				items = cola.util.sort(items, @_sortCriteria)
		return items

	_getItemScope: (parentScope, alias, item)->
		itemScope = parentScope.getItemScope(item)
		if itemScope
			cola.currentScope = itemScope
		else
			itemScope = new cola.ItemScope(parentScope, alias)
			cola.currentScope = itemScope
			itemScope.data.setItemData(item, true)
		return itemScope

	_getItemType: (type)->
		return @_centerTable._getItemType(type)

	_createDom: ()->
		dom = cola.xCreate(
			tagName: @constructor.tagName
		)
		@_doms ?= {}
		@_createInnerDom(dom)
		return dom

	_createInnerTable: (config)->
		return new cola.Table.InnerTable(config)

	_createInnerDom: (dom)->
		@_centerTable = @_createInnerTable(
			scope: @_scope
			type: "center"
			table: @
		)
		@_centerTable.appendTo(dom)

		if @_scrollMode is "scroll"
			@_createVertScrollBar(dom)

		setTimeout(()=>
			$fly(dom).on("mouseenter", ()=>
				@_mouseIn = true
				@_refreshScrollbars()
			).on("mouseleave", ()=>
				@_mouseIn = false
			).on("sizingChange", ()=>
				if dom.offsetWidth is self._oldOffsetWidth and dom.offsetHeight is self._oldOffsetHeight
					return

				if @_refreshItemsScheduled
					@refresh()
				else
					@_buildStyleSheet()
					@_refreshScrollbars()
				self._oldOffsetWidth = dom.offsetWidth
				self._oldOffsetHeight = dom.offsetHeight
				return
			)
			return
		, 50)
		return

	_refreshScrollbars: ()->
		table = @
		dom = @_dom
		innerTable = @_centerTable._dom
		return unless innerTable

		tableBody = innerTable.querySelector(".table-body")
		if innerTable.scrollWidth > (innerTable.clientWidth + 2)
			# 修复右边内容缺失，tbody无法被撑开的BUG
			tableBody.style.width = "auto"
			tableBody.style.width = innerTable.scrollWidth + "px"

			if not @_horiScrollBar and table._mouseIn
				@_horiScrollBar = cola.xCreate({
					class: "scroll-bar hori"
					content:
						class: "fake-content"
					scroll: ()->
						return if table._ignoreScrollbarMove
						innerTable.scrollLeft = @scrollLeft / @scrollWidth * innerTable.scrollWidth
						return
				})
				dom.appendChild(@_horiScrollBar)

			horiScrollBar = @_horiScrollBar
			if horiScrollBar
				fakeContent = horiScrollBar.querySelector(".fake-content")
				fakeContent.style.width =
				  (innerTable.scrollWidth / innerTable.clientWidth * horiScrollBar.clientWidth) + "px"
				horiScrollBar.scrollLeft = innerTable.scrollLeft / innerTable.scrollWidth * horiScrollBar.scrollWidth
				horiScrollBar.style.display = ""

			@_$dom.addClass("h-scroll")
		else
			# 修复右边内容缺失，tbody无法被撑开的BUG
			tableBody.style.width = "100%"

			if @_horiScrollBar
				@_horiScrollBar.style.display = "none"
			@_$dom.removeClass("h-scroll")

		tableBody = @_centerTable._doms.tableBody
		if tableBody.scrollHeight > (tableBody.clientHeight + 2)
			if not @_vertScrollBar and table._mouseIn
				@_vertScrollBar = @_createVertScrollBar(@_dom)

			vertScrollBar = @_vertScrollBar
			if vertScrollBar
				fakeContent = vertScrollBar.querySelector(".fake-content")
				fakeContent.style.height =
				  (tableBody.scrollHeight / tableBody.clientHeight * vertScrollBar.clientHeight) + "px"
				vertScrollBar.scrollTop = tableBody.scrollTop / tableBody.scrollHeight * vertScrollBar.scrollHeight
				vertScrollBar.style.display = ""
		else if @_vertScrollBar
			@_vertScrollBar.style.display = "none"
		return

	_createVertScrollBar: (dom)->
		table = @
		@_vertScrollBar = cola.xCreate({
			class: "scroll-bar vert"
			content:
				class: "fake-content"
			scroll: ()->
				return if table._ignoreScrollbarMove
				tableBody = table._centerTable._doms.tableBody
				scrollTop = @scrollTop / @scrollHeight * tableBody.scrollHeight
				tableBody.scrollTop = scrollTop
				table._leftTable?._doms.tableBody.scrollTop = scrollTop
				table._rightTable?._doms.tableBody.scrollTop = scrollTop
				return
		})
		dom.appendChild(@_vertScrollBar)
		return @_vertScrollBar

	_initDom: (dom)->
		@_mainItemsContainer = ">.center.ui.inner-table >.table-body"
		super(dom)

		if $.fn.draggable
			@_initDragDrop(">.inner-table >.table-header", dom)

		dataType = @get("dataType") or @_getBindDataType()
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

	_getNodeNameColumnMap: ()->
		return {
			"COLUMN": null
			"SELECT-COLUMN": "select"
			"STATE-COLUMN": "state"
			"NUM-COLUMN": "num"
		}

	_doRefreshDom: ()->
		return unless @_dom
		super()

		if @_refreshItemsScheduled
			delete @_refreshItemsScheduled
			@_leftTable?._refreshItemsScheduled = true
			@_rightTable?._refreshItemsScheduled = true
			@_centerTable._refreshItemsScheduled = true

			@_classNamePool.toggle("highlight-current", @_highlightCurrentItem)
			@_classNamePool.toggle("v-scroll", @_scrollMode is "scroll")
			@_classNamePool.toggle("has-left-pane", @_realLeftFixedCols > 0)
			@_classNamePool.toggle("has-right-pane", @_realRightFixedCols > 0)

			if not @_columnsInfo
				@_collectionColumnsInfo()
			@_refreshItems()
		return

	refreshItem: (item)->
		@_leftTable?.refreshItem(item)
		@_rightTable?.refreshItem(item)
		@_centerTable.refreshItem(item)
		return

	_onItemRefresh: (arg)->
		item = arg.entity
		if typeof item is "object"
			@refreshItem(item)
		return

	_onItemsRefresh: ()->
		return @_refreshItems()

	_refreshItems: ()->
		if not @_dom or not cola.util.isVisible(@_dom)
			@_refreshItemsScheduled = true
			return

		if @_columnsTimestamp isnt @_columnsInfo.timestamp or @_oldClientWidth = @_dom.clientWidth
			@_columnsTimestamp = @_columnsInfo.timestamp
			@_oldClientWidth = @_dom.clientWidth

			$centerTableDom = @_centerTable.get$Dom()
			if @_columnsInfo.left and not @_leftTable
				@_leftTable = @_createInnerTable(
					type: "left"
					table: @
				)
				$centerTableDom.before(@_leftTable.getDom())
			if @_columnsInfo.right and not @_rightTable
				@_rightTable = @_createInnerTable(
					type: "right"
					table: @
				)
				$centerTableDom.after(@_rightTable.getDom())

			@_buildStyleSheet()

			@_leftTable?.set("columnsInfo", @_columnsInfo.left)
			@_rightTable?.set("columnsInfo", @_columnsInfo.right)
			@_centerTable.set("columnsInfo", @_columnsInfo.center)

		realItems = @_realItems
		ret = @_getItems()
		@_realItems = ret.items
		@_realOriginItems = ret._originItems
		@_fullRefresh = realItems isnt @_realItems

		@_leftTable?._refreshItems()
		@_rightTable?._refreshItems()
		@_centerTable._refreshItems()

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 50, ()=>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)

		@_fullRefresh = false
		cola.util.delay(@, "refreshScrollbars", 300, @_refreshScrollbars)
		return

	_onCurrentItemChange: (arg)->
		@_setCurrentItem(arg.current)
		return

	_onItemInsert: (arg)->
		@_refreshItems()
		return

	_onItemRemove: (arg)->
		@_refreshItems()

		if @_columnsInfo.selectColumns
			cola.util.delay(@, "refreshHeaderCheckbox", 50, ()=>
				for colInfo in @_columnsInfo.selectColumns
					colInfo.column.refreshHeaderCheckbox()
				return
			)
		return

	_setCurrentItem: (item)->
		@_syncCurrentItem = true
		@_leftTable?._setCurrentItem(item)
		@_rightTable?._setCurrentItem(item)
		@_centerTable?._setCurrentItem(item)
		@_syncCurrentItem = false
		return

	_getCurrentItem: ()->
		return @_centerTable?._getCurrentItem()

	_onBlur: ()->
		@_currentInnerTable?.hideCellEditor()
		return

	_onKeyDown: (evt)->
		centerTable = @_centerTable

		if evt.keyCode is 9 # Tab
			currentItem = @_getCurrentItem()
			return unless currentItem

			dataColumns = @_columnsInfo.dataColumns
			index = -1
			for columnInfo, i in dataColumns
				if columnInfo.column is @_currentColumn
					index = i
					break

			while not nextColumnInfo
				if evt.shiftKey
					if index <= 0 or index > dataColumns.length - 1
						index = dataColumns.length - 1
						itemDom = centerTable._getPreviousItemDom(centerTable._currentItemDom)
						if itemDom
							centerTable._setCurrentItemDom(itemDom)
							currentItem = centerTable._getCurrentItem()
					else
						index--
				else
					if index < 0 or index >= dataColumns.length - 1
						index = 0
						itemDom = centerTable._getNextItemDom(centerTable._currentItemDom)
						if itemDom
							centerTable._setCurrentItemDom(itemDom)
							currentItem = centerTable._getCurrentItem()
					else
						index++

				columnInfo = dataColumns[index]
				# if not columnInfo.column._readOnly and columnInfo.column._property
				nextColumnInfo = columnInfo

			if nextColumnInfo and currentItem
				if @_columnsInfo.center.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = centerTable
				else if @_columnsInfo.left?.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = @_leftTable
				else if @_columnsInfo.right?.dataColumns.indexOf(nextColumnInfo) >= 0
					innerTable = @_rightTable

				innerTable.setCurrentCell(currentItem, nextColumnInfo.column)
				return false

		else if evt.keyCode is 38 # up
			currentItem = @_getCurrentItem()
			if currentItem
				itemDom = centerTable._getPreviousItemDom(centerTable._currentItemDom)
			else
				itemDom = @_getNextItemDom()

			if itemDom
				centerTable._setCurrentItemDom(itemDom)
				currentItem = centerTable._getCurrentItem()
				if currentItem and @_currentInnerTable
					@_currentInnerTable.setCurrentCell(currentItem, @_currentColumn)

		else if evt.keyCode is 40 # down
			currentItem = @_getCurrentItem()
			if currentItem
				itemDom = centerTable._getNextItemDom(centerTable._currentItemDom)
			else
				itemDom = @_getFirstItemDom()

			if itemDom
				centerTable._setCurrentItemDom(itemDom)
				currentItem = centerTable._getCurrentItem()
				if currentItem and @_currentInnerTable
					@_currentInnerTable.setCurrentCell(currentItem, @_currentColumn)
		return

	_sysHeaderClick: (column)->
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
						invoker.ajaxService.set("parameter", parameter = {})
					else if typeof parameter isnt "object" or parameter instanceof cola.EntityList or parameter instanceof Date
						throw new cola.Exception("Can not set sort parameter automatically.")

					if parameter instanceof cola.Entity
						parameter.set(cola.setting("defaultSortParameter",) or "sort", criteria)
					else
						parameter[cola.setting("defaultSortParameter") or "sort"] = criteria

					cola.util.flush(collection)
			else
				if @fire("sortDirectionChange", @, {
					column: column
					sortDirection: sortDirection
				}) is false
					return

				@set("sortCriteria", criteria)
		return

cola.registerWidget(cola.Table)
cola.Element.mixin(cola.Table, cola.TemplateSupport)
cola.Element.mixin(cola.Table, cola.DataItemsWidgetMixin)

class cola.Table.InnerTable extends cola.AbstractList
	@className: "inner-table"

	manageItemScope: false

	@attributes:
		type: null
		table: null
		columnsInfo: null

	constructor: (config)->
		@_itemsScope = config.table._itemsScope
		@_alias = config.table._alias

		config.allowNoCurrent = config.table._allowNoCurrent
		config.currentPageOnly = config.table._currentPageOnly
		config.highlightCurrentItem = config.table._highlightCurrentItem
		config.changeCurrentItem = config.table._changeCurrentItem

		super(config)
		@_focusParent = @_table
		@on("itemClick", (self, arg)=> @_table.fire("itemClick", @_table, arg))
		@on("itemDoubleClick", (self, arg)=> @_table.fire("itemDoubleClick", @_table, arg))
		@on("itemPress", (self, arg)=> @_table.fire("itemPress", @_table, arg))

	_createItemsScope: ()-> @_itemsScope

	_getItemScope: (parentScope, alias, item)->
		return @_table._getItemScope(parentScope, alias, item)

	_getItems: ()-> @_table._getItems()

	_convertItems: null

	_createDom: ()->
		@_doms ?= {}
		dom = $.xCreate({
			tagName: "div"
			class: @_type
			content:
				class: "table-body"
				contextKey: "tableBody"
				content:
					tagName: "ul"
					contextKey: "itemsWrapper"
				mousewheel: (evt)=>
					evt = evt.originalEvent

					table = @_table
					centerTableDom = table._centerTable._dom
					scrollLeft = centerTableDom.scrollLeft + evt.deltaX

					centerTableBody = table._centerTable._doms.tableBody
					scrollTop = centerTableBody.scrollTop + evt.deltaY

					oldScrollLeft = centerTableDom.scrollLeft
					oldScrollTop = centerTableBody.scrollTop
					centerTableDom.scrollLeft = scrollLeft
					centerTableBody.scrollTop = scrollTop

					if centerTableDom.scrollLeft is oldScrollLeft and centerTableBody.scrollTop is oldScrollTop
						return true

					table._leftTable?._doms.tableBody.scrollTop = scrollTop
					table._rightTable?._doms.tableBody.scrollTop = scrollTop

					table._ignoreScrollbarMove = true
					if table._horiScrollBar
						table._horiScrollBar.scrollLeft = scrollLeft / centerTableDom.scrollWidth * table._horiScrollBar.scrollWidth
					if table._vertScrollBar
						table._vertScrollBar.scrollTop = scrollTop / centerTableBody.scrollHeight * table._vertScrollBar.scrollHeight
					table._ignoreScrollbarMove = false
					return false
		}, @_doms)

		$fly(@_doms.itemsWrapper).delegate(".cell", "click", (evt)=>
			return if @_readOnly

			cell = evt.currentTarget
			columnName = cell._name
			column = @_table.getColumn(columnName)
			item = @getItemByItemDom(cell.parentNode)
			@setCurrentCell(item, column)
			return
		)
		return dom

	_createNewItem: (itemType, item)->
		template = @_table.getTemplate(itemType + "-row")
		itemDom = @_table._cloneTemplate(template)
		klass = "table item " + itemType
		if @_transition
			klass += " " + cola.constants.REPEAT_ITEM_TRANSITION_CLASS
		$fly(itemDom).addClass(klass)
		itemDom._itemType = itemType
		return itemDom

	_doRefreshItems: (itemsWrapper)->
		return unless @_dom and @_columnsInfo

		@hideCellEditor()

		if @_table._showHeader
			header = @_doms.header
			if not header
				$fly(@_doms.tableBody).xInsertBefore({
					class: "table-header"
					contextKey: "tableHeader"
					content:
						contextKey: "header"
					scroll: (evt)=>
						return unless @_table._innerDragging
						@_doms.tableBody?.scrollLeft = evt.target.scrollLeft
						return
				}, @_doms)
				header = @_doms.header

				$fly(header).delegate(".header-cell", "click", (evt)=>
					columnName = evt.currentTarget._name
					column = @_table.getColumn(columnName)
					eventArg =
						column: column
					if column.fire("headerClick", @, eventArg) isnt false
						if @_table.fire("headerClick", @, eventArg) isnt false
							@_table._sysHeaderClick(column)
					return
				)

			@_refreshHeader(header)
			@_doms.tableBody.className = "table-body header-" + @_columnsInfo.rows

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
				$fly(footer).delegate(".footer-cell", "click", (evt)=>
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

		return super(itemsWrapper)

	_refreshHeaderRow: (rowDom, colInfos, rowHeight)->
		for colInfo in colInfos
			column = colInfo.column
			cell = cola.xCreate(
				class: "header-cell " + column._id + " h-center"
				content:
					class: "content default-content"
			)
			cell._name = column._name

			if column instanceof cola.TableGroupColumn
				cell.className += " rows-1"
				subRowDom = cola.xCreate(
					class: "header-row"
				)
				groupColumnCell = cola.xCreate(
					class: "header-group"
					content: [ cell, subRowDom ]
				)
				@_refreshHeaderRow(subRowDom, colInfo.colInfos, rowHeight - 1)
				rowDom.appendChild(groupColumnCell)
			else
				cell.className += " rows-" + rowHeight
				rowDom.appendChild(cell)

			@_refreshHeaderCell(cell.firstElementChild, colInfo)
		return

	_refreshHeader: (header)->
		return if @_headerTimestamp is @_columnsInfo.timestamp
		@_headerTimestamp = @_columnsInfo.timestamp

		$fly(header).empty()

		rowDom = $.xCreate(
			class: "header-row first-row"
		)
		@_refreshHeaderRow(rowDom, @_columnsInfo.colInfos, @_columnsInfo.rows)
		cola.xRender(rowDom, @_scope)
		header.appendChild(rowDom)
		return

	_refreshHeaderCell: (dom, columnInfo)->
		column = columnInfo.column

		$cell = $fly(dom.parentNode)
		$cell.toggleClass("sortable", !!column._sortable).removeClass("asc desc")
		if column._sortDirection then $cell.addClass(column._sortDirection)

		template = column.getTemplate("headerTemplate")
		if template
			template = @_cloneTemplate(template)
			dom.appendChild(template)
			skipDefault = column._real_headerTemplate
		else
			if column.renderHeader
				skipDefault = column.renderHeader(dom) != true

		if column.getListeners("renderHeader")
			if column.fire("renderHeader", column, { dom: dom }) == false
				return

		if @getListeners("renderHeaderCell")
			if @fire("renderHeaderCell", @, { column: column, dom: dom }) == false
				return

		return if skipDefault

		caption = column._caption or column._name
		if caption?.charCodeAt(0) is 95 # `_`
			caption = column._property or column._bind
		dom.innerText = caption or ""
		return

	_refreshFooterRow: (rowDom)->
		for colInfo in @_columnsInfo.dataColumns
			column = colInfo.column

			exClass = ""
			if column._align
				exClass = " h-" + column._align
			else
				exClass = " h-center"

			cell = cola.xCreate(
				class: "footer-cell " + column._id + exClass
				content:
					class: "content default-content"
			)
			cell._name = column._name
			rowDom.appendChild(cell)

			@_refreshFooterCell(cell.firstElementChild, colInfo)
		return

	_refreshFooterCell: (dom, columnInfo)->
		column = columnInfo.column

		template = column.getTemplate("footerTemplate")
		if template
			template = @_cloneTemplate(template)
			dom.appendChild(template)
			skipDefault = column._real_footerTemplate
		else
			if column.renderFooter
				skipDefault = column.renderFooter(dom) != true

		if column.getListeners("renderFooter")
			if column.fire("renderFooter", column, { dom: dom }) == false
				return

		if @getListeners("renderFooterCell")
			if @fire("renderFooterCell", @, { column: column, dom: dom }) == false
				return

		return if skipDefault

		data = column._footerValue
		if column._format
			data = cola.util.format(data, column._format)
		dom.innerText = data or ""
		return

	_refreshFooter: (footer)->
		return if @_footerTimestamp is @_columnsInfo.timestamp
		@_footerTimestamp = @_columnsInfo.timestamp

		$fly(footer).empty()

		rowDom = $.xCreate(
			class: "footer-row"
		)
		@_refreshFooterRow(rowDom)
		cola.xRender(rowDom, @_scope)
		footer.appendChild(rowDom)
		return

	_doRefreshItemDom: (itemDom, item, itemScope)->
		itemType = itemDom._itemType

		if @_table.getListeners("renderItem")
			if @_table.fire("renderItem", @_table, { item: item, dom: itemDom, scope: itemScope }) == false
				return

		if itemType == "default"
			colInfos = @_columnsInfo.dataColumns
			for colInfo, i in colInfos
				column = colInfo.column
				cell = itemDom.childNodes[i]
				while cell and cell._name isnt column._name
					if cell.nodeName is "CELL"
						itemDom.removeChild(cell)
						cell = itemDom.childNodes[i]
					else
						tailChild = cell
						cell = null
						break

				if not cell
					isNew = true
					cell = $.xCreate({
						tagName: "cell"
						content:
							class: "content"
					})
					cell._name = column._name

					if tailChild
						itemDom.insertBefore(cell, tailChild)
					else
						itemDom.appendChild(cell)

				exClass = ""
				if column._align
					exClass = " h-" + column._align
				if column._valign
					exClass += " v-" + column._valign

				cell.className = "cell " + column._id + (exClass or "")
				contentWrapper = cell.firstElementChild

				@_refreshCell(contentWrapper, item, colInfo, itemScope, isNew)

			child = cell.nextSibling
			while child
				if child.nodeName is "CELL"
					temp = child.nextSibling
					itemDom.removeChild(child)
					child = temp
				else
					break
		return

	_refreshCell: (dom, item, columnInfo, itemScope, isNew)->
		column = columnInfo.column

		if column.renderCell
			skipDefault = column.renderCell(dom, item, itemScope) != true

		if column.getListeners("renderCell")
			if column.fire("renderCell", column, { item: item, dom: dom, scope: itemScope }) == false
				return

		if @_table.getListeners("renderCell")
			if @_table.fire("renderCell", @_table,
			  { item: item, column: column, dom: dom, scope: itemScope }) == false
				return

		return if skipDefault

		if isNew
			template = column.getTemplate("template")
			if template
				template = @_cloneTemplate(template)
				dom.appendChild(template)
				if column._property
					if column._format
						context = {
							defaultPath: "format(#{@_alias}.#{column._property},\"#{column._format}\")"
						}
					else
						context = {
							defaultPath: "#{@_alias}.#{column._property}"
						}
				cola.xRender(dom, itemScope, context)

		if item instanceof cola.Entity and column._property
			$cell = $fly(dom.parentNode)
			i = column._property.lastIndexOf(".")
			if i > 0
				subItem = item.get(column._property.substring(0, i))
				if subItem and subItem instanceof cola.Entity
					message = subItem.getKeyMessage(column._property.substring(i + 1))
			else
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
				$cell.removeClass("info warn error")
				if dom._popupSetted
					$cell.attr("data-content", "").popup("destroy")
				dom._hasState = false
				dom._popupSetted = false

		return if column._real_template

		$dom = $fly(dom).addClass("default-content")
		if columnInfo.expression
			$dom.attr("c-bind", columnInfo.expression.raw)
		else if column._property
			if item instanceof cola.Entity
				value = item.get(column._property)
			else
				value = item[column._property]

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

	refreshItem: (item)->
		return unless @_itemDomMap

		itemId = cola.Entity._getEntityId(item)
		itemDom = @_itemDomMap[itemId]
		if itemDom
			@_refreshItemDom(itemDom, item, @_itemsScope)
		return

	_setCurrentItem: (item)->
		return unless @_itemDomMap
		if item
			itemId = cola.Entity._getEntityId(item)
			if itemId
				currentItemDom = @_itemDomMap[itemId]
				if not currentItemDom
					@_refreshItems()
					return
		@_setCurrentItemDom(currentItemDom)
		return

	_setCurrentItemDom: (itemDom)->
		return if @_duringSetCurrentItemDom
		@_duringSetCurrentItemDom = true
		super(itemDom)
		if not @_table._syncCurrentItem
			item = cola.util.userData(itemDom, "item")
			@_table._setCurrentItem(item)
		@_duringSetCurrentItemDom = false
		return

	_getCurrentItem: ()->
		if @_currentItemDom
			return cola.util.userData(@_currentItemDom, "item")
		else
			return null

	setCurrentCell: (item, column)->
		return unless @_rendered

		@_table._currentInnerTable = @
		@_table._currentColumn = column
		if @_table._currentCell
			$fly(@_table._currentCell).removeClass("current")

		if item
			itemId = cola.Entity._getEntityId(item)
			itemDom = @_itemDomMap[itemId]
			if itemDom
				child = itemDom.firstElementChild
				while child
					if child._name is column._name
						cell = child
						break
					child = child.nextElementSibling

			@_table._currentCell = cell
			if cell
				$fly(cell).addClass("current")
				if column._property
					@showCellEditor(cell, item, column)
		return

	_getCellEditorPane: (create)->
		if not @_cellEditorPane and create
			@_cellEditorPane = cola.xCreate(
				class: "cell-editor-pane protected"
			)
			@_doms.itemsWrapper.appendChild(@_cellEditorPane)
		return @_cellEditorPane

	_resize: (editorPane, cell)->
		itemDom = cell.parentNode
		$fly(editorPane)
			.css("left", cell.offsetLeft)
			.css("top", itemDom.offsetTop)
			.width(cell.clientWidth)
			.height(cell.clientHeight)
		return

	showCellEditor: (cell, item, column)->
		if @_table._readOnly or column._readOnly
			return

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

			setTimeout(()=>
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

						if templateDom
							editor = cola.widget(templateDom)
							if editor instanceof cola.AbstractEditor and not editor._bindInfo
								editor.set("bind", "#{@_table._alias}.#{column._property}")
					finally
						cola.currentScope = oldScope
				else
					scope = cola.util.userData(templateDom, "scope")
					scope?.data.setItemData(item)

				$fly(editorPane).removeClass("hidden")

				cellWidget = cola.widget(cell.firstElementChild?.firstElementChild)
				if cellWidget instanceof cola.AbstractEditor
					cellWidget.focus()
				else
					if templateDom.parentNode isnt editorPane
						if editorPane.firstElementChild
							cola.util.cacheDom(editorPane.firstElementChild)
						editorPane.appendChild(templateDom)

					@_resize(editorPane, cell)

					if templateDom?.className is "editor-container"
						editContent = templateDom.firstElementChild
					else
						editContent = templateDom
					cellEditorWidget = cola.widget(editContent)
					cellEditorWidget?.focus()
				return
			, 0)
		return

	hideCellEditor: ()->
		editorPane = @_getCellEditorPane()
		if editorPane
			$fly(editorPane).addClass("hidden")
		return

	_onKeyDown: (evt)->
		return