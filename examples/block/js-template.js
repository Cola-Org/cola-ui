var template = {
	blocks: [
		{
			$dataType: "BlockTemplate",
			type: "Form",
			cols: "2",
			dataPath: "actual",
			caption: "个人意外伤害险",
			elements: [
				{
					property: "underwritingAcceptDate",
					caption: "核保日期",

					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "recordDate",
					caption: "录单日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "quotationNo",
					caption: "报价单号"
				},
				{
					property: "businessCategory",
					caption: "业务种类"
				},
				{
					property: "policyPremium",
					caption: "保单保费"
				},
				{
					property: "applicationDate",
					caption: "投保日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "applicationNo",
					caption: "投保单号"
				},
				{
					property: "startDate",
					caption: "生效日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "endDate",
					caption: "终止日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "policyNo",
					caption: "保单号"
				},
				{
					property: "policyStatus",
					caption: "保单状态"
				},
				{
					property: "basicSumInsured",
					caption: "基本保额"
				},
				{
					content: [
						{
							tagName: "c-button",
							class: "primary",
							caption: "打开对话框",
							click: function () {
								cola.widget("dialog1").show();
							}
						},
						{
							tagName: "c-button",
							class: "primary",
							caption: "打开边栏",
							click: function () {
								cola.widget("sidebar1").show();
							}
						}
					]
				}
			]
		},
		{
			$dataType: "BlockTemplate",
			type: "Table",
			cols: "3",
			collapsed: true,
			dataPath: "actual.underwritingResultRecord",
			caption: "核保结果信息",
			elements: [
				{
					property: "underwritingSn",
					caption: "核保序号",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "underwritingDate",
					caption: "核保日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "appliedPartyId",
					caption: "承保对象",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "underwritingComment",
					caption: "核保意见",
					editContent: {
						tagName: "c-input"
					}
				}
			]
		},
		{
			$dataType: "BlockTemplate",
			type: "Form",
			cols: "3",
			collapsed: true,
			caption: "投保人",
			elements: [
				{
					property: "sccolor",
					caption: "肤色",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "blankListFlag",
					caption: "黑名单标记",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "customerVipFlag",
					caption: "客户VIP标识",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "driveYears",
					caption: "驾龄",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "driveLicenseRegiseterDate",
					caption: "驾照领证日期",
					editContent: {
						tagName: "c-input",
						displayFormat: "yyyy-MM-dd HH:mm:ss.fff",
						inputFormat: "yyyy-MM-dd"
					}
				},
				{
					property: "personHeight",
					caption: "身高",
					editContent: {
						tagName: "c-input"
					}
				},

				{
					property: "cellPhone",
					caption: "手机号码",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "contactAddress",
					caption: "联系地址",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "certificateType",
					caption: "证件类型",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "email",
					caption: "邮箱",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "postalCode",
					caption: "邮政编码",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "telephoneNumber",
					caption: "固定电话",
					editContent: {
						tagName: "c-input"
					}
				},

				{
					property: "countryName",
					caption: "国家",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "streetNumberDetail",
					caption: "街道门牌号",
					editContent: {
						tagName: "c-input"
					}
				},

				{
					property: "certificateCode",
					caption: "证件代码",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "provinceName",
					caption: "省直辖市",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "cityName",
					caption: "地市",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "countyName",
					caption: "区县",
					editContent: {
						tagName: "c-input"
					}
				},

				{
					property: "nativePlace",
					caption: "籍贯",
					editContent: {
						tagName: "c-input"
					}
				},

				{
					property: "gender",
					caption: "性别",
					editContent: {
						tagName: "c-input"
					}
				},
				{
					property: "personAge",
					caption: "年龄",
					editContent: {
						tagName: "c-input"
					}
				}
			]
		}

	]
};