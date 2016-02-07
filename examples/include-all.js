function includeAll(root) {
	var cacheBuster="";

	function writeScriptlet(file) {
		document.write("<script language=\"JavaScript\" type=\"text/javascript\" charset=\"utf-8\" src=\"" + root + file + cacheBuster + "\"></script>");
	}

	writeScriptlet("lib/number-formatter.js");
	writeScriptlet("lib/xdate.js");
	writeScriptlet("lib/jquery-1.11.0.js");
	writeScriptlet("lib/jsep.js");

	writeScriptlet("lib/dorado/core.js");
	writeScriptlet("lib/dorado/data.js");

	writeScriptlet("cola-dorado7.js");

	//writeScriptlet("i18n/zh-Hans/cola.js");
}

includeAll(location.protocol + "//" + location.host + "/cola-dorado7/dist/");