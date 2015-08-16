function includeAll(root) {
	var cacheBuster="";
	 //cacheBuster="?time="+new Date().getTime();

	function writeScriptlet(file) {
		document.write("<script language=\"JavaScript\" type=\"text/javascript\" charset=\"utf-8\" src=\"" + root + file + cacheBuster + "\"></script>");
	}

	function writeStyleSheet(file) {
		document.write("<link rel=\"stylesheet\" type=\"text/css\" charset=\"utf-8\" href=\"" + root + file +cacheBuster+ "\" />");
	}

	writeStyleSheet("lib/semantic-ui/semantic.css");
	writeStyleSheet("skins/default/cola.css");

	writeScriptlet("lib/number-formatter.js");
	writeScriptlet("lib/xdate.js");
	writeScriptlet("lib/swipe.lite.js");
	writeScriptlet("lib/jquery-2.1.3.js");
	writeScriptlet("lib/jquery.transit.js");

	writeScriptlet("lib/jsep.js");
	writeScriptlet("lib/animate.js");
	writeScriptlet("lib/scroller.js");
	writeScriptlet("lib/easy-scroller.js");

	writeScriptlet("lib/fastclick.js");
	writeScriptlet("lib/semantic-ui/semantic.js");
	writeScriptlet("lib/hammer.js");
	writeScriptlet("lib/jquery.hammer.js");

	writeScriptlet("cola.js");
	writeScriptlet("widget/widget.js");
	writeScriptlet("widget/base.js");
	writeScriptlet("widget/layout.js");
	writeScriptlet("widget/edit.js");
	writeScriptlet("widget/collection.js");
	writeScriptlet("widget/list.js");

	writeScriptlet("i18n/zh-Hans/cola.js");
}

includeAll(location.protocol + "//" + location.host + "/cola-ui/dest/dev/");