class cola.DatePicker extends cola.CustomDropdown
	@ATTRIBUTES:
		icon:
			defaultValue: "calendar"
		content:
			$type: "calender"

	_getDropdownContent: () ->
		if !@_dropdownContent
			calendar = new cola.Calendar({
				date: new Date()
				cellClick: (self, arg)->
					console.log(arg)
			})
			@_dropdownContent = calendar.getDom()

		return @_dropdownContent