class cola.Pager extends cola.Widget
	@tagName: "c-pager"
	@CLASS_NAME: "ui pager empty"
	@attributes:
		bind:
			setter: (bindStr)-> @_bindSetter(bindStr)
	_getBindItems: ()-> @_getItems()?.items
	_initDom: (dom)->
		@_doms ?= {}
		@_doms.pageNoWrapper = $.xCreate({
			tagName: "div",
			class: "page-no-wrapper"
		})

		pager = @
		$(@_doms.pageNoWrapper).delegate("span:not(.nav-btn)", "click", ()->
			if $(@).hasClass("separator") then return
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
					content: cola.resource("cola.pager.goto.prefix")
				}
				{
					tagName: "input",
					type: "number",
					contextKey: "gotoInput",
					min: 1,
					step: 1,
					change: ()->
						pageNo = parseInt($(this).val())
						
						if pageNo > pager._pageCount
							pageNo = pager._pageCount
							$(this).val(pageNo)

						pager.goTo(pageNo)

				}
				{
					tagName: "span"
					contextKey: "gotoLabel"
					content: cola.resource("cola.pager.goto.suffix")
				}
			]
		}, @_doms)


		@_doms.count = $.xCreate({
			tagName: "div",
			class: "count"
		})
		dom.appendChild(@_doms.count)
		dom.appendChild(@_doms.pageNoWrapper)
		@_doms._pageSizeInput = cola.xRender({
			tagName: "c-dropdown",
			class: "page-size",
			showClearButton: false,
			editable: false,
			valueProperty: "key",
			textProperty: "value",
			"c-items": "dictionary('cola.pageSize')"
		}, @scope)

		pageSizeDrop = cola.widget(@_doms._pageSizeInput)
		pageSizeDrop.on("post", (self, arg)->
			pager.pageSize(self.get("value"))
		)
		dom.appendChild(@_doms._pageSizeInput)
		dom.appendChild(@_doms.goTo)

	goTo: (pageNo)->
		data = @_getBindItems()
		data?.gotoPage(parseInt(pageNo))


	pageSize: (pageSize)->
		@_pageTimmer && clearTimeout(@_pageTimmer)
		data = @_getBindItems()

		if data?._providerInvoker?.pageSize is pageSize
			return
		@_pageTimmer = setTimeout(()->
			data?._providerInvoker?.ajaxService?.set("pageSize", pageSize)
			data?._providerInvoker?.pageNo = 1
			data && cola.util.flush(data)
		, 100)

	pagerItemsRefresh: ()->
		pager = @
		data = pager._getBindItems()
		pageNo = 0
		pageCount = 0
		totalEntityCount = 0
		pageSize = 0
		hasPrev = false
		hasNext = false
		if data
			pageCount = Math.floor((data.totalEntityCount + data.pageSize - 1) / data.pageSize)
			totalEntityCount = data.totalEntityCount || 0
			pageNo = data.pageNo || 0
			pageCount = data.pageCount || 0
			pageSize = data.pageSize || 0
			hasPrev = data.pageNo > 1
			hasNext = pageCount > data.pageNo
		@_pageNo = pageNo

		@_pageCount = pageCount;

		wrapper = @_doms.pageNoWrapper
		$(wrapper).empty()
		$(@_dom).toggleClass("empty", totalEntityCount <= 0);

		$(@_doms.gotoInput).attr("max", pageCount || 1);

		wrapper.appendChild($.xCreate({
			tagName: "span",
			class: "nav-btn prev",
			click: ()->
				if $(this).hasClass("disabled")
					return
				pager.prevPage()
				return
		}))

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
		wrapper.appendChild($.xCreate({
			tagName: "span",
			class: "nav-btn next",
			click: ()->
				if $(this).hasClass("disabled")
					return
				pager.nextPage()
				return
		}))

		$(@_doms.count).text(cola.resource("cola.pager.entityCount", totalEntityCount))
		$(@_doms.gotoInput).val(pageNo);
		$(@_doms.gotoInput).attr("max", pageCount);
		cola.widget(@_doms._pageSizeInput).set("value", pageSize);

		$(@_dom).find("span[no='#{pageNo}']").addClass("current");
		$(@_dom).find(".nav-btn.prev").toggleClass("disabled", !hasPrev);
		$(@_dom).find(".nav-btn.next").toggleClass("disabled", !hasNext);
	prevPage: ()->
		data = @_getBindItems()
		data?.previousPage()
	nextPage: ()->
		data = @_getBindItems()
		data?.nextPage()
	_onItemsRefresh: ()-> @pagerItemsRefresh()
	_onItemRefresh: (arg)->
	_onItemInsert: (arg)->
	_onItemRemove: (arg)->
	_onItemsLoadingStart: (arg)->
	_onItemsLoadingEnd: (arg)->
	_onCurrentItemChange: (arg)->
		if @_pageNo isnt arg.entityList.pageNo
			@pagerItemsRefresh()


cola.Element.mixin(cola.Pager, cola.DataItemsWidgetMixin)
cola.registerWidget(cola.Pager)