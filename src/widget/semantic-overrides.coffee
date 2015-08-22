cola.semantic =
	###
	fixVisibilityOnUpdate和fixVisibilityOnRefresh方法用于修正SemanticUI中visibility的一处计算错误。
    当我们尝试利用visibility处理非body的滚动时，SemanticUI中的一处对jQuery.offset()的误用导致获得对象偏移量总是相对于document的，而非实际滚动的容器。
    使用时，将fixVisibilityOnUpdate和fixVisibilityOnRefresh方法分别定义为visibility的onUpdate和onRefresh监听器。
	###
	fixVisibilityOnUpdate: (calculations) ->
		@_offset ?=
			left: @offsetLeft,
			top: @offsetTop
		calculations.offset = @_offset
		return

	fixVisibilityOnRefresh: () ->
		@_offset =
			left: @offsetLeft,
			top: @offsetTop
		return