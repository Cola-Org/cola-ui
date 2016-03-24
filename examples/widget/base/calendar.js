/**
 *
 * User: Alex Tong(mailto:alex.tong@bstek.com)
 * Date: 15/7/7
 * Time: 下午1:26
 * To change this template use File | Settings | File Templates.
 */


cola(function(model){
	model.widgetConfig({
		calendar:{
			$type:"calendar",
			monthChange:function(self,arg){
				console.log(arg)
			}
		}
	})

});
