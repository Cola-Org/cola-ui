class cola.Pager extends cola.Widget
	@tagName: "c-pager"
	@CLASS_NAME: "ui pager"
	@attributes:
		bind:
			setter: (bindStr) -> @_bindSetter(bindStr)
	_getBindItems: ()-> @_getItems()?.items
	_initDom: (dom)->
		@_doms ?= {}
		@_doms.pageNoWrapper = $.xCreate({
			tagName: "div",
			class: "page-no-wrapper"
		})
		pager = @
		$(@_doms.pageNoWrapper).delegate("span", "click", ()->
			pageNo = $(@).attr("no");
			pager.goTo(pageNo)
		)
		@_doms.goTo = $.xCreate({
			tagName: "div",
			class: "goto",
			content: [
				{
					tagName: "span"
					contextKey: "gotoLabel"
					content: cola.resource("cola.pager.goto")
				}
				{
					tagName: "input",
					type: "number",
					contextKey: "gotoInput",
					change: ()->
						pageNo = parseInt($(this).val())
						pager.goTo(pageNo)

				}
			]
		}, @_doms)

		@_doms.pageSize = $.xCreate({
			tagName: "div",
			class: "page-size",
			content: [
				{
					tagName: "span"
					contextKey: "pageSizeLabel"
					content: cola.resource("cola.pager.pageSize")
				}
				{
					tagName: "input",
					type: "number",
					step: "10",
					contextKey: "pageSizeInput",
					change: ()->
						pageSize = parseInt($(this).val())
						pager.pageSize(pageSize)

				}
			]
		}, @_doms)


		@_doms.count = $.xCreate({
			tagName: "div",
			class: "count"
		})
		dom.appendChild(@_doms.pageNoWrapper)
		dom.appendChild(@_doms.goTo)
		#dom.appendChild(@_doms.pageSize)
		dom.appendChild(@_doms.count)

	goTo: (pageNo)->
		@_pageTimmer && clearTimeout(@_pageTimmer)
		data = @_getBindItems()
		@_pageTimmer = setTimeout(()->
			data?.gotoPage(parseInt(pageNo))
		, 100)
	pageSize: (pageSize)->
		@_pageTimmer && clearTimeout(@_pageTimmer)
		data = @_getBindItems()
		@_pageTimmer = setTimeout(()->
			data?._providerInvoker?.pageSize = pageSize
			data?._providerInvoker?.pageNo = 1
			data.pageSize = pageSize
			data.pageNo = 1
			cola.util.flush(data)
		, 100)
	pagerItemsRefresh: () ->
		pager = @
		data = pager._getBindItems()
		hasPrev = false
		hasNext = false
		pageNo = 0
		pageCount = 0
		totalEntityCount = 0
		pageSize = 0
		if data
			pageCount = Math.trunc((data.totalEntityCount + data.pageSize - 1) / data.pageSize)
			totalEntityCount = data.totalEntityCount || 0
			hasPrev = data.pageNo > 1
			hasNext = pageCount > data.pageNo
			pageNo = data.pageNo || 0
			pageCount = data.pageCount || 0
			pageSize = data.pageSize || 0

		@_pageNo = pageNo

		wrapper = @_doms.pageNoWrapper
		$(@_doms.pageNoWrapper).empty()


		if pageCount <= 5
			i = 0
			while i < pageCount
				i++
				wrapper.appendChild($.xCreate({
					tagName: "span",
					content: i
					no: i
				}))
		else if pageNo < 4
			i = 0
			while i < 4
				i++
				wrapper.appendChild($.xCreate({
					tagName: "span",
					content: i
					no: i
				}))
			wrapper.appendChild($.xCreate({
				tagName: "span",
				class: "separator"
			}))
			wrapper.appendChild($.xCreate({
				tagName: "span",
				content: pageCount
				no: pageCount
			}))
		else if pageNo <= pageCount && pageNo > pageCount - 3
			wrapper.appendChild($.xCreate({
				tagName: "span",
				content: 1
				no: 1
			}))
			wrapper.appendChild($.xCreate({
				tagName: "span",
				class: "separator"
			}))
			i = pageCount - 3
			while i <= pageCount
				wrapper.appendChild($.xCreate({
					tagName: "span",
					content: i
					no: i
				}))
				i++
		else
			wrapper.appendChild($.xCreate({
				tagName: "span",
				content: 1
				no: 1
			}))
			wrapper.appendChild($.xCreate({
				tagName: "span",
				class: "separator"
			}))
			i = pageNo - 2
			while i < pageNo + 1
				i++
				wrapper.appendChild($.xCreate({
					tagName: "span",
					content: i
					no: i
				}))
			wrapper.appendChild($.xCreate({
				tagName: "span",
				class: "separator"
			}))

			wrapper.appendChild($.xCreate({
				tagName: "span",
				content: pageCount
				no: pageCount
			}))
		$(@_doms.count).text(cola.resource("cola.pager.entityCount", totalEntityCount))
		$(@_doms.gotoInput).val(pageNo);
		#$(@_doms.pageSizeInput).val(pageSize);
		$(@_dom).find("span[no='#{pageNo}']").addClass("current");

	_onItemsRefresh: ()-> @pagerItemsRefresh()
	_onItemRefresh: (arg)->
	_onItemInsert: (arg) ->
	_onItemRemove: (arg) ->
	_onItemsLoadingStart: (arg)->
	_onItemsLoadingEnd: (arg)->
	_onCurrentItemChange: (arg)->
		if @_pageNo isnt arg.entityList.pageNo
			@pagerItemsRefresh()


cola.Element.mixin(cola.Pager, cola.DataItemsWidgetMixin)
cola.registerWidget(cola.Pager)