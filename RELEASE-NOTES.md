## RELEASE NOTES

### Version 1.0.6 - Mar 10, 2017

**新增**
- **SplitPanel控件** - 新增cola.SplitPanel 控件滑动分割面板
- **SelectButton控件** - 新增cola.SelectButton 按钮模式选择器
- **Core** - 新增cola.util.dictionary，主要支持，管理系统开发中的数据字典翻译功能

**Bug 修复**
- **Widget** - 修复ie11 下alt+tab 输入类控件失去值的问题
- **DropDown** - 修复Dropdown在box布局下的兼容性问题
- **DropDown** - 修正DropDown选择后做了不必要的post的BUG
- **Carousel** - 修复carousel的小bug
- **Core** - 改进Entity.get在处理深度path, 且包含多层懒装载的情况
- **Core** - 修正xRender处理template时的一处逻辑BUG
- **Core** - 修正自定义控件中item in ?@bindItems这样的绑定不生效的BUG
- **Core** - 修正userData的改变引起c-repeat不正常的BUG


**小改进**
- **Core** - 改进DOM解析顺序
- **Core** - 对绑定机制做了一次重构, 改善性能, 增强健壮性
- **Core** - 为DataProvider提供response事件
- **Widget** - 修正Table等列表总是显示所有页数据的BUG，添加currentPageOnly属性，默认值为false。实现翻页功能时需设置此属性为true
- **Widget** - Dropdown和Table支持键盘操作
- **Core** - 修正watch关键字冲突导致在firefox下报错的BUG
- **Widget** - 重构Form表单控件，并field标签绑定数据
- **Widget** - 重写并增强Form 表单布局管理器，放弃Semantic表单布局
- **Core** - 添加名为show-on-ready的css class, 所有拥有此class的dom在cola初始化完成之前将不可见
- **Widget** - 小重构cardbook
- **Widget** - 为MessageBox添加max-width的css 
- **Widget** - 改进SubView选择parentModel
- **Widget** - 改进RadioGroup控件
- **Widget** - stack 控件提供 touchable 属性
- **Core** - 为EntityList添加empty()方法

### Version 0.9.8 - August 3, 2016

**新增控件**
- **notifyTip** - 新增cola.notifyTip 控件
- **YearMonthDropDown** - 新增控件YearMonthDropDown
- **TextArea** - 新增控件 TextArea

**Bug 修复**
- **Widget** - 修复 display 属性在部分控件中不起效的问题
- **Layer** - 修复 layer 控件z-index问题
- **DropDown** - 修复 DropDown 显示位置错误的bug
- **Carousel** - 修复 carousel 无法自动切换的bug
- **AjaxValidator** - 修正AjaxValidator不可用的BUG
- **Editor** - 修正Editor有时不能正确的显示校验状态的BUG
- **DropDown** - 修复DropDown 在界面滚动后显示位置错误问题
- **DataPicker** - 修复手机下的日期下拉框的bug
- **TimeLine** - 修复TimeLine 控件无法下拉刷新的bug
- **SubView**  - 修正SubView.loadIfNecessary()可能导致不装载的BUG
- **DropDown** - 修复 下拉框ie10 和11 下的无法选中问题
- **Tree** - 修复Tree 控件itemClick事件穿透的Bug和子节点无法刷新的bug
- **Panel** - 修复Panel 在不指定高度时,收缩和展开无动画效果的Bug
- **CheckBox** - 修复 semantic CheckBox onDisabled on undefined 错误

**小改进**
- **Core** - 改进UserData对低版本IE的兼容性
- **Core** - 修正Router在firefox下无法正确的触发onStateChange事件的BUG
- **Core** - 为AjaxService、Provider提供timeout属性
- **Core** - 为AjaxService、Provider提供timeout属性
- **Core** - 修正watch关键字冲突导致在firefox下报错的BUG
- **Core** - 改进对微信浏览器的判断方式
- **Widget** - 调整 button icon 样式
- **Widget** - 调整Form 必填项样式
- **Core** - 增强cola.util.findWidget(), 使其支持跨框架的查找
- **Widget** - 改进 panel和sidebar样式
- **Widget** - 改进 sidebar 控件显示时body滚动条显示问题
- **Widget** - input 支持低版本手机浏览器



### Version 0.9.0 - April 25, 2016

**新增特性**
- **自定义控件** - 新增自定义控件特性，用户可通过cola.defineWidget(type,config)自定义控件

**新增控件**
- **DataPicker** - 日期选择框

**新增UI Class**
- **ui fragment** - 提供侧边有点缀色的片段class 可通过class="ui fragment red" 
可添加black、yellow、green、blue、orange、purple、red、pink、teal和basic获得不同的主题效果

**Bug 修复**
- **Core** - 修正action expression导致的死锁
- **Input** - 修复改进Input显示空值的逻辑，防止将Null显示为0或invalid date等内容的Bug
- **Stack** - 修复 stack控件无法显示bug
- **Tab** - 修复 tab在close所有标签时报错的bug
- **Carousel** - 修复 Carousel控件，控制按钮无法切换的bug

**小改进**
- **Provider** - 改进Provider的parameter中的参数定义方式。今后统一用{{xxx}}来定义，其中@开头的表达式表示从本Entity中提取数值。$pageNo、$pageSize等是特殊的内置变量
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

