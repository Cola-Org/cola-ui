## RELEASE NOTES

### Version 0.8.2 - March 11, 2016
**Bug 修复**
- **Pager** - 在$entityCount=0情况下 下一页按钮可单击的Bug
- **RadioGroup** - 控件dom上value值为none的bug
- **字体请求** - 修复默认上google请求字体导致的页面停止渲染

**小改进**
- **布局** - h-box默认宽度设定为100%、 v-box默认高度设定为100%
- **core** - 新增chain()内置Action，以及对链式表达式的支持,为c-repeat提供$index默认迭代变量，用于显示当前迭代的序号（从1开始）、	
微调cola.router()的API、改进cola.resource的默认值规则

