## RELEASE NOTES

### Version 0.9.0 - April 25, 2016

**新增控件**
- **DataPicker** - 日期选择框

**Bug 修复**
- **Input** - 修复改进Input显示空值的逻辑，防止将Null显示为0或invalid date等内容的Bug
- **Stack** - 修复 stack控件无法显示bug
- **Tab** - 修复 tab在close所有标签时报错的bug
- **Carousel** - 修复 Carousel控件，控制按钮无法切换的bug

**小改进**
- **列表型控件API** - hbox和v-box的.box overflow默认设定改为：visible
- **Panel** - Panel控件改进为在无icon下，图标Dom自动隐藏
- **Time-Line** - time-line控件新增皮肤以及多色主题
- **Box布局** - hbox和v-box的.box overflow默认设定改为：visible
### Version 0.8.4 - April 05, 2016
#### 建议原使用v0.8.3版本的用户更新之此版本。
**Bug 修复**
- **ListView** - 修复v0.8.3中列表型控件报Connot read property ‘call’ of undefined 的严重Bug
- **Dialog** - 修复Dialog高度默认为100%的Bug

**小改进以及文档补充**
- **列表型控件API** - 重新调整列表型控件API
- **Panel** - Panel控件改进为在无icon下，图标Dom自动隐藏
- **Time-Line** - 编写time-line API

### Version 0.8.3 - April 03, 2016

**新控件**
- **TimeLine** - [Api](http://cola-ui.com/api/cola.TimeLine.html) 
- **Panel** - [Api](http://cola-ui.com/api/cola.Panel.html)
- **FieldSet** - [Api](http://cola-ui.com/api/cola.FieldSet.html)
- **GroupBox** - [Api](http://cola-ui.com/api/cola.GroupBox.html)

**Bug 修复**
- **Carousel** - 修正Carousel利用数据绑定时，常常不能自动刷新出indicators的BUG。
- **Provider** - 修正Provider发送limit from和pageSize pageNo参数时的BUG
- **Tree** - 修复Tree autoExpand=true时 出现全部收缩的问题 
- **Pager** - 修复pager控件items属性默认为空的bug  …
- **Stack** - 修复Stack控件在部分Android下滑动不了得问题…
- **Calendar** - 修复Calendar控件获得日期对应dom在切换前无法获得的bug…

**小改进**
- **Input** - 先执行Input的post工作，再触发change事件。
- **Semantic** - Semantic-UI 汉字优化
- **Provider** - 为provider提供loadMode属性
- **Font** - 英文字体 Open Sans字体优先级调高
- **Table** - 改进table外观

### Version 0.8.2 - March 11, 2016
**Bug 修复**
- **Pager** - 在$entityCount=0情况下 下一页按钮可单击的Bug
- **RadioGroup** - 控件dom上value值为none的bug
- **字体请求** - 修复默认上google请求字体导致的页面停止渲染

**小改进**
- **布局** - h-box默认宽度设定为100%、 v-box默认高度设定为100%
- **core** - 新增chain()内置Action，以及对链式表达式的支持,为c-repeat提供$index默认迭代变量，用于显示当前迭代的序号（从1开始）、	
微调cola.router()的API、改进cola.resource的默认值规则

