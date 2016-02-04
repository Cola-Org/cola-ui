function includeAll(root) {
	var cacheBuster="";
	 //cacheBuster="?time="+new Date().getTime();

	function writeScriptlet(file) {
		document.write("<script language=\"JavaScript\" type=\"text/javascript\" charset=\"utf-8\" src=\"" + root + file + cacheBuster + "\"></script>");
	}

	function writeStyleSheet(file) {
		document.write("<link rel=\"stylesheet\" type=\"text/css\" charset=\"utf-8\" href=\"" + root + file +cacheBuster+ "\" />");
	}

	//writeStyleSheet("lib/semantic-ui/semantic.css");
	//writeStyleSheet("skins/default/cola.css");

	writeScriptlet("lib/number-formatter.js");
	writeScriptlet("lib/xdate.js");
	writeScriptlet("lib/jquery-1.11.0.js");

	writeScriptlet("lib/jsep.js");
	writeScriptlet("cola.js");

	//writeScriptlet("i18n/zh-Hans/cola.js");
}

includeAll(location.protocol + "//" + location.host + "/cola-dorado7/dest/dev/");