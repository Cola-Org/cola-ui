class cola.Pager extends cola.Widget
	@tagName: "c-pager"
	@className: "ui pager empty"
	@attributes:
		bind:
			setter: (bindStr)-> @_bindSetter(bindStr)
	@events:
		retrieveTotalEntityCount: null

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
			class: "count"
			content: [
				{
					tagName: "span"
					class: "text"
				}
				{
					tagName: "i"
					class: "icon eye"
				}
			]
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

		$count = $(@_doms.count).toggleClass("loose", data?.entityCount and not (data.pageCountDetermined)).click(()=>
			return if not $count.hasClass("loose") or $count.hasClass("loading")

			$icon = $count.find(">.icon")

			$count.addClass("loading")
			$icon.removeClass("eye").addClass("loading spinner")

			eventArg =
				items: @_getBindItems()
			@fire("retrieveTotalEntityCount", @, eventArg)

			if eventArg.deferred
				eventArg.deferred.done((count) =>
					eventArg.items.setTotalEntityCount(count)
				).always(()=>
					$count.removeClass("loading")
					$icon.removeClass("loading spinner")
				)
			else
				if eventArg.totalEntityCount?
					eventArg.items.setTotalEntityCount(count)
				$count.removeClass("loading")
				$icon.removeClass("loading spinner").addClass("eye")
		)
		return

	goTo: (pageNo)->
		data = @_getBindItems()
		data?.gotoPage(parseInt(pageNo))

	pageSize: (pageSize)->
		return unless pageSize > 0

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
			if data.pageCountDetermined
				totalEntityCount = data.totalEntityCount
			else
				page = data.findPage(data.pageCount)
				totalEntityCount = data.pageSize * (data.pageCount - 1) + (if page then page.entityCount else data.pageSize)

			@_pageNo = pageNo
			@_pageCount = pageCount

			pageNo = data.pageNo || 0
			pageCount = data.pageCount || 0
			pageSize = data.pageSize || 0
			hasPrev = data.pageNo > 1
			hasNext = data.hasNextPage()

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
		$(@_doms.gotoInput).attr("max", pageCount || 1);

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

		$count = $(@_doms.count).toggleClass("loose", !(data?.pageCountDetermined) and totalEntityCount > 0)
		$count.find(">.text").text(cola.resource("cola.pager.entityCount", totalEntityCount + (if data?.pageCountDetermined then "" else "+")))

		$(@_doms.gotoInput).val(pageNo).attr("max", pageCount);
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
	_doItemsLoadingStart: (arg)->
	_doItemsLoadingEnd: (arg)->
	_onCurrentItemChange: (arg)->
		if @_pageNo isnt arg.entityList.pageNo
			@pagerItemsRefresh()


cola.Element.mixin(cola.Pager, cola.DataItemsWidgetMixin)
cola.registerWidget(cola.Pager)