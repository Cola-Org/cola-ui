/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 数据管道。
 * <p>
 * 数据管道是一种用于向外界提供数据的对象。 该对象一般仅在dorado的内部被使用，有时我们可以直接将数据管道视为一种特殊的数据，
 * 因为数据管道本身就是用来代表一组数据的，只不过这组数据需要经由一些逻辑才能获得。 例如：dorado的一些处理中将{@link dorado.DataProvider}封装成数据管道。
 * 这样，当外界尝试利用该数据管道来获取数据时，数据管道内部会通过封装的{@link dorado.DataProvider}来获得最终的数据。
 * </p>
 * @abstract
 */
dorado.DataPipe = $class(/** @scope dorado.DataPipe.prototype */{
	$className: "dorado.DataPipe",
	
	/**
	 * @property
	 * @name dorado.DataPipe#dataTypeRepository
	 * @type dorado.DataTypeRepository
	 * @description 解析返回数据时可能需要用到的数据类型管理器。
	 */
	/**
	 * @property
	 * @name dorado.DataPipe#dataType
	 * @type dorado.LazyLoadDataType|dorado.DataType
	 * @description 返回数据的数据类型。
	 */
	// =====
	
	/**
	 * @name dorado.DataPipe#doGet
	 * @function
	 * @protected
	 * @description 用于提取数据的同步方法。
	 * <p>
	 * 当我们需要在子类中改写提取数据的同步方法时，我们应该覆盖DataPipe的doGet()方法，而不是get()方法。
	 * </p>
	 * @return {dorado.Entity|dorado.EntityList} 提取到的数据。
	 */
	/**
	 * @name dorado.DataPipe#doGetAsync
	 * @function
	 * @protected
	 * 用于提取数据的异步方法。
	 * <p>
	 * 当我们需要在子类中改写提取数据的异步方法时，我们应该覆盖DataPipe的doGetAsync()方法，而不是getAsync()方法。
	 * </p>
	 * @param {Function|dorado.Callback} callback 回调对象，传入回调对象的参数即为提取到的数据。
	 */
	// =====
	
	/**
	 * 正在执行的数据装载的过程的个数。
	 * @type int
	 */
	runningProcNum: 0,
	
	shouldFireEvent: true,
	
	convertIfNecessary: function(data, dataTypeRepository, dataType) {
		var oldFireEvent = dorado.DataUtil.FIRE_ON_ENTITY_LOAD;
		dorado.DataUtil.FIRE_ON_ENTITY_LOAD = this.shouldFireEvent;
		try {
			return dorado.DataUtil.convertIfNecessary(data, dataTypeRepository, dataType);
		}
		finally {
			dorado.DataUtil.FIRE_ON_ENTITY_LOAD = oldFireEvent;
		}
	},
	
	/**
	 * 用于提取数据的同步方法。
	 * <p>
	 * 请不要在子类中改写此方法，如需改写应将改写的逻辑放在doGet()中。
	 * </p>
	 * @return {dorado.Entity|dorado.EntityList} 提取到的数据
	 * @see dorado.DataPipe#doGet
	 */
	get: function() {
		dorado.DataPipe.MONITOR.executionTimes++;
		dorado.DataPipe.MONITOR.syncExecutionTimes++;
		return this.convertIfNecessary(this.doGet(), this.dataTypeRepository, this.dataType);
	},
	
	/**
	 * 用于提取数据的异步方法。
	 * <p>
	 * 请不要在子类中改写此方法，如需改写应将改写的逻辑放在doGetAsync()中。
	 * </p>
	 * @param {dorado.Callback} callback 回调对象，传入回调对象的参数即为提取到的数据。
	 * @see dorado.DataPipe#doGetAsync
	 */
	getAsync: function(callback) {
		dorado.DataPipe.MONITOR.executionTimes++;
		dorado.DataPipe.MONITOR.asyncExecutionTimes++;
		
		callback = callback || dorado._NULL_FUNCTION;
		var callbacks = this._waitingCallbacks;
		if (callbacks) {
			callbacks.push(callback);
		} else {
			this._waitingCallbacks = callbacks = [callback];
			this.runningProcNum++;
			
			this.doGetAsync({
				scope: this,
				callback: function(success, result) {
					if (success) {
						result = this.convertIfNecessary(result, this.dataTypeRepository, this.dataType);
					}
					
					var errors, callbacks = this._waitingCallbacks;
					delete this._waitingCallbacks;
					this.runningProcNum = 0;
					
					if (callbacks) {
						for (var i = 0; i < callbacks.length; i++) {
							try {
								$callback(callbacks[i], success, result);
							} 
							catch (e) {
								if (errors === undefined) errors = [];
								errors.push(e);
							}
						}
					}
					if (errors) throw ((errors.length > 1) ? errors : errors[0]);
				}
			});
		}
	},
	
	abort: function(success, result) {
		var callbacks = this._waitingCallbacks;
		delete this._waitingCallbacks;
		this.runningProcNum = 0;
		
		if (!callbacks) return;
		
		var errors;
		for (var i = 0; i < callbacks.length; i++) {
			try {
				$callback(callbacks[i], success, result);
			} 
			catch (e) {
				if (errors === undefined) errors = [];
				errors.push(e);
			}
		}
		if (errors) throw ((errors.length > 1) ? errors : errors[0]);
	}
});

dorado.DataPipe.MONITOR = {
	executionTimes: 0,
	asyncExecutionTimes: 0,
	syncExecutionTimes: 0
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 数据提供者。
	 * <p>
	 * 此对象一般只用于配合dorado服务端的开发模式中。在纯使用dorado客户端功能的开发模式下一般应使用@{link dorado.AjaxDataProvider}。
	 * </p>
	 * <p>
	 * 通常我们不建议您通过<pre>new dorado.DataProvider("xxx");</pre>的方式来创建数据提供者，而应该用{@link dorado.DataProvider.create}来代替。
	 * 这是因为用{@link dorado.DataProvider.create}支持缓存功能，利用此方法来获得数据提供者的效率往往更高。
	 * </p>
	 * @param {String} id 数据提供者的服务id。通常此id也会被直接认为是数据提供者的name。
	 */
	dorado.DataProvider = $class(/** @scope dorado.DataProvider.prototype */{
		$className: "dorado.DataProvider",
		
		/**
		 * @property
		 * @name dorado.DataProvider#dataTypeRepository
		 * @type dorado.DataTypeRepository
		 * @description 解析返回数据时可能需要用到的数据类型管理器。
		 */
		/**
		 * @property
		 * @name dorado.DataProvider#dataType
		 * @type dorado.LazyLoadDataType|dorado.DataType
		 * @description 返回数据的数据类型。
		 */
		/**
		 * @property
		 * @name dorado.DataProvider#message
		 * @type String
		 * @description 当此DataProvider正在执行时希望系统显示给用户的提示信息。
		 * <p>
		 * 此属性目前仅在以异步模式执行时有效。
		 * </p>
		 */
		// =====
		
		/**
		 * 是否支持Dorado的数据实体。
		 * <p>
		 * 如果选择是，那么当有数据从服务端返回时，系统自动判断该数据在服务端的形态。
		 * 如果该数据在服务端是Entity/EntityList的形式，那么系统也会在客户端将他们转换成Entity/EntityList的形式。<br>
		 * 如果选择否，那么不管这些数据在服务端是怎样的，到了客户端将变成JSON形式。
		 * </p>
		 * @type boolean
		 * @default true
		 */
		supportsEntity: true,
		
		shouldFireEvent: true,
		
		constructor: function(id) {
			this.id = id;
			this.name = dorado.DataUtil.extractNameFromId(id);
		},
		
		/**
		 * @name dorado.DataProvider#id
		 * @decription 数据提供者的服务id。
		 * @type String
		 */
		/**
		 * @name dorado.DataProvider#name
		 * @decription 数据提供者的名称。
		 * @type String
		 */
		// =====
		
		/**
		 * 进行数据装载操作时传入{@link dorado.util.AjaxEngine}的执行选项。
		 * @protected
		 * @return {Object} 执行选项。
		 * @see dorado.util.AjaxEngine#request
		 * @see dorado.util.AjaxEngine#requestSync
		 */
		getAjaxOptions: function(arg) {
			var jsonData = {
				action: "load-data",
				dataProvider: this.id,
				supportsEntity: this.supportsEntity
			};
			if (arg) {
				jsonData.parameter = arg.parameter;
				jsonData.sysParameter = arg.sysParameter;
				if (arg.dataType) {
					var dataType = arg.dataType;
					if (dataType instanceof dorado.DataType) dataType = dataType.get("id");
					else if (typeof dataType == "string") dataType = dataType;
					else dataType = dataType.id;
					jsonData.resultDataType = dataType;
				}
				jsonData.pageSize = arg.pageSize;
				jsonData.pageNo = arg.pageNo;
				jsonData.context = arg.view ? arg.view.get("context") : null;
			}
			if (this.supportsEntity && this.dataTypeRepository) {
				jsonData.loadedDataTypes = this.dataTypeRepository.getLoadedDataTypes();
			}
			return dorado.Object.apply({
				jsonData: jsonData
			}, $setting["ajax.dataProviderOptions"]);
		},
		
		convertEntity: function(data, dataTypeRepository, dataType, ajaxOptions) {
			if (data == null) return data;
			
			var oldFireEvent = dorado.DataUtil.FIRE_ON_ENTITY_LOAD;
			dorado.DataUtil.FIRE_ON_ENTITY_LOAD = this.shouldFireEvent;
			try {
				data = dorado.DataUtil.convertIfNecessary(data, dataTypeRepository, dataType);
			}
			finally {
				dorado.DataUtil.FIRE_ON_ENTITY_LOAD = oldFireEvent;
			}
			
			if (data instanceof dorado.EntityList) {
				data.dataProvider = this;
				data.parameter = ajaxOptions.jsonData.parameter;
				data.sysParameter = ajaxOptions.jsonData.sysParameter;
				data.pageSize = ajaxOptions.jsonData.pageSize;
			} else if (data instanceof dorado.Entity) {
				data.dataProvider = this;
				data.parameter = ajaxOptions.jsonData.parameter;
				data.sysParameter = ajaxOptions.jsonData.sysParameter;
			}
			return data;
		},
		
		/**
		 * 用于以同步方式提取数据的方法。
		 * @param {Object} [arg] 提取数据时的选项。
		 * @param {Object} [arg.parameter] 提取数据时使用的参数。
		 * @param {int} [arg.pageNo] 提取分页数据时请求的页号。
		 * @param {int} [arg.pageSize] 提取分页数据时每页的记录数。
		 * @return {dorado.Entity|dorado.EntityList} 提取到的数据。
		 * @throws {Error}
		 */
		getResult: function(arg) {
			var ajaxOptions = this.getAjaxOptions(arg), ajax = dorado.util.AjaxEngine.getInstance(ajaxOptions);
			var result = ajax.requestSync(ajaxOptions);
			if (result.success) {
				var json = result.getJsonData(), data;
				if (json && (json.$dataTypeDefinitions || json.$context)) {
					data = json.data;
					if (json.$dataTypeDefinitions) this.dataTypeRepository.parseJsonData(json.$dataTypeDefinitions);
					if (json.$context && arg && arg.view) {
						var context = arg.view.get("context");
						context.put(json.$context);
					}
				} else {
					data = json;
				}
				if (data && this.supportsEntity) {
					data = this.convertEntity(data, this.dataTypeRepository, this.dataType, ajaxOptions);
				}
				return data;
			} else {
				throw result.exception;
			}
		},
		
		/**
		 * 用于以异步方式提取数据的方法。
		 * @param {Object} arg 提取数据时的选项。
		 * @param {Object} [arg.parameter] 提取数据时使用的参数。
		 * @param {int} [arg.pageNo] 提取分页数据时请求的页号。
		 * @param {int} [arg.pageSize] 提取分页数据时每页的记录数。
		 * @param {Function|dorado.Callback} callback 回调对象，传入回调对象的参数即为提取到的数据。
		 */
		getResultAsync: function(arg, callback) {
			var ajaxOptions = this.getAjaxOptions(arg), ajax = dorado.util.AjaxEngine.getInstance(ajaxOptions);
			var dataType = this.dataType, supportsEntity = this.supportsEntity, dataTypeRepository = this.dataTypeRepository;
			
			var message = this.message;
			if (message == null) message = ajaxOptions.message;
			if (message === undefined) message = $resource("dorado.data.DataProviderTaskIndicator");
			if (message) ajaxOptions.message = message;

			ajax.request(ajaxOptions, {
				scope: this,
				callback: function(success, result) {
					if (success) {
						var json = result.getJsonData(), data;
						if (json && (json.$dataTypeDefinitions || json.$context)) {
							data = json.data;
							if (json.$dataTypeDefinitions) this.dataTypeRepository.parseJsonData(json.$dataTypeDefinitions);
							if (json.$context && arg && arg.view) {
								var context = arg.view.get("context");
								context.put(json.$context);
							}
						} else {
							data = json;
						}
						if (data && supportsEntity) {
							data = this.convertEntity(data, dataTypeRepository, dataType, ajaxOptions);
						}
						$callback(callback, true, data, {
							scope: this
						});
					} else {
						$callback(callback, false, result.exception, {
							scope: this
						});
					}
				}
			});
		}
	});
	
	/**
	 * @class 通过Ajax引擎获取数据的数据提供者。
	 * <p>
	 * 此对象一般只用于纯使用dorado客户端功能开发模式中。在配合dorado服务端的开发模式下一般应使用@{link dorado.DataProvider}。
	 * </p>
	 * @extends dorado.DataProvider
	 * @param {Object|String} options 默认的进行数据装载操作时传入{@link dorado.util.AjaxEngine}的执行选项。
	 * @see dorado.util.AjaxEngine
	 */
	dorado.AjaxDataProvider = $extend(dorado.DataProvider, {
		$className: "dorado.AjaxDataProvider",
		
		constructor: function(options) {
			if (typeof options == "string") {
				options = {
					url: options
				};
			}
			this._baseOptions = options || {};
		},
		
		getAjaxOptions: function(arg) {
			var options = dorado.Object.apply({}, this._baseOptions), jsonData = options.jsonData = {};
			if (this._baseOptions.jsonData) dorado.Object.apply(jsonData, this._baseOptions.jsonData);
			if (arg) {
				jsonData.parameter = arg.parameter;
				jsonData.sysParameter = arg.sysParameter;
				jsonData.pageSize = arg.pageSize;
				jsonData.pageNo = arg.pageNo;
			}
			return options;
		}
	});
	
	var dataProviders = {};
	
	/**
	 * 创建一个数据提供者。
	 * @param {String} id 数据提供者的服务id。
	 * @return {dorado.DataProvider} 新创建的数据提供者。
	 */
	dorado.DataProvider.create = function(id) {
		var provider = dataProviders[id];
		if (provider === undefined) {
			dataProviders[id] = provider = new dorado.DataProvider(id);
		}
		return provider;
	};
	
	dorado.DataProviderPipe = $extend(dorado.DataPipe, {
		$className: "dorado.DataProviderPipe",
		
		getDataProvider: function() {
			return this.dataProvider;
		},
		
		doGet: function() {
			return this.doGetAsync();
		},
		
		doGetAsync: function(callback) {
			var dataProvider = this.getDataProvider();
			if (dataProvider) {
				var dataProviderArg = this.getDataProviderArg()
				dataProvider.dataTypeRepository = this.dataTypeRepository;
				dataProvider.dataType = this.dataType;
				dataProvider.shouldFireEvent = this.shouldFireEvent;
				if (callback) {
					dataProvider.getResultAsync(dataProviderArg, callback);
				} else {
					return dataProvider.getResult(dataProviderArg);
				}
			}
			else {
				if (callback) {
					$callback(callback, true, null);
				}
				else {
					return null;
				}
			}
		}
	});
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 数据处理器。
	 *  <p>
	 * 此对象一般只用于配合dorado服务端的开发模式中。在纯使用dorado客户端功能的开发模式下一般应使用@{link dorado.AjaxDataResolver}。
	 * </p>
	 * <p>
	 * 通常我们不建议您通过<pre>new dorado.DataResolver("xxx");</pre>的方式来创建数据处理器，而应该用{@link dorado.DataResolver.create}来代替。
	 * 这是因为用{@link dorado.DataResolver.create}支持缓存功能，利用此方法来获得数据处理器的效率往往更高。
	 * </p>
	 * @param {String} id 数据处理器的服务id。通常此id也会被直接认为是数据处理器的name。
	 */
	dorado.DataResolver = $class(/** @scope dorado.DataResolver.prototype */{
		$className: "dorado.DataResolver",
		
		supportsEntity: true,

		constructor: function(id) {
			this.id = id;
			this.name = dorado.DataUtil.extractNameFromId(id);
		},

		/**
		 * @name dorado.DataProvider#id
		 * @decription 数据处理器的服务id。
		 * @type String
		 */
		/**
		 * @name dorado.DataResolver#name
		 * @type String
		 * @decription 数据处理器的名称。
		 */
		/**
		 * @property
		 * @name dorado.DataResolver#dataTypeRepository
		 * @type dorado.DataTypeRepository
		 * @description 解析返回数据时可能需要用到的数据类型管理器。
		 */
		/**
		 * @property
		 * @name dorado.DataResolver#message
		 * @type String
		 * @description 当此DataResolver正在执行时希望系统显示给用户的提示信息。
		 * <p>
		 * 此属性目前仅在以异步模式执行时有效。
		 * </p>
		 */
		// =====

		/**
		 * 进行数据提交操作时传入{@link dorado.util.AjaxEngine}的执行选项。
		 * @return {Object} 执行选项。
		 * @see dorado.util.AjaxEngine#request
		 * @see dorado.util.AjaxEngine#requestSync
		 */
		getAjaxOptions: function(arg) {
			var jsonData = {
				action: "resolve-data",
				dataResolver: this.id,
				supportsEntity: this.supportsEntity
			};
			if (arg) {
				jsonData.dataItems = arg.dataItems;
				jsonData.parameter = arg.parameter;
				jsonData.sysParameter = arg.sysParameter;
				jsonData.context = arg.view ? arg.view.get("context") : null;
			}
			if (this.supportsEntity && this.dataTypeRepository) {
				jsonData.loadedDataTypes = this.dataTypeRepository.getLoadedDataTypes();
			}
			return dorado.Object.apply({
				jsonData: jsonData
			}, $setting["ajax.dataResolverOptions"]);
		},

		/**
		 * 用于以同步方式调用后台数据处理的方法。
		 * @param {Object} [arg] 处理数据时的选项。
		 * @param {Object[]} [arg.dataItems] 要提交的数据项的数组。
		 * 其中每一个数据项又是一个子对象，该子对象应包含以下两个子属性:
		 * <ul>
		 * <li>name - {String} 数据项的名称（键值）。</li>
		 * <li>data - {Object} 具体的数据。</li>
		 * </ul>
		 * @param {Object} [arg.parameter] 提交数据时附带的参数。
		 * @return {Object} 数据处理完成后得到的返回结果。
		 * @throws {Error}
		 */
		resolve: function(arg) {
			var ajaxOptions = this.getAjaxOptions(arg), ajax = dorado.util.AjaxEngine.getInstance(ajaxOptions);
			var result = ajax.requestSync(ajaxOptions);
			if (result.success) {
				var result = result.getJsonData(), returnValue = (result ? result.returnValue : null);
				if (returnValue && (returnValue.$dataTypeDefinitions || returnValue.$context)) {
					if (returnValue.$dataTypeDefinitions) this.dataTypeRepository.parseJsonData(returnValue.$dataTypeDefinitions);
					if (returnValue.$context && arg && arg.view) {
						var context = arg.view.get("context");
						context.put(returnValue.$context);
					}
					returnValue = returnValue.data;
				}
				if (returnValue && this.supportsEntity) {
					returnValue = dorado.DataUtil.convertIfNecessary(returnValue, this.dataTypeRepository);
				}
				return {
					returnValue: returnValue,
					entityStates: result.entityStates
				};
			} else {
				throw result.exception;
			}
		},

		/**
		 * 用于以异步方式调用后台数据处理的方法。
		 * @param {Object} arg 处理数据时的选项。见{@link dorado.DataResolver#resolve}中arg参数的说明。
		 * @param {Function|dorado.Callback} callback 回调对象，传入回调对象的参数即为数据处理完成后的结果。
		 * @see dorado.DataResolver#resolve
		 */
		resolveAsync: function(arg, callback) {
			var ajaxOptions = this.getAjaxOptions(arg), supportsEntity = this.supportsEntity, ajax = dorado.util.AjaxEngine.getInstance(ajaxOptions);
			
			var message = this.message;
			if (message == null) message = ajaxOptions.message;
			if (message === undefined) message = $resource("dorado.data.DataResolverTaskIndicator");
			if (message) ajaxOptions.message = message;
			if (ajaxOptions.modal == null) ajaxOptions.modal = this.modal;
			
			ajax.request(ajaxOptions, {
				scope: this,
				callback: function(success, result) {
					if (success) {
						var result = result.getJsonData(), returnValue = (result ? result.returnValue : null);
						if (returnValue && (returnValue.$dataTypeDefinitions || returnValue.$context)) {
							if (returnValue.$dataTypeDefinitions) this.dataTypeRepository.parseJsonData(returnValue.$dataTypeDefinitions);
							if (returnValue.$context && arg && arg.view) {
								var context = arg.view.get("context");
								context.put(returnValue.$context);
							}
							returnValue = returnValue.data;
						}
						if (returnValue && supportsEntity) {
							returnValue = dorado.DataUtil.convertIfNecessary(returnValue, this.dataTypeRepository);
						}
						$callback(callback, true, {
							returnValue: returnValue,
							entityStates: result.entityStates
						}, {
							scope: this
						});
					} else {
						$callback(callback, false, result.exception, {
							scope: this
						});
					}
				}
			});
		}
	});

	dorado.AjaxDataResolver = $extend(dorado.DataResolver, {
		$className: "dorado.AjaxDataResolver",

		constructor: function(options) {
			if (typeof options == "string") {
				options = {
					url: options
				};
			}
			this._baseOptions = options || {};
		},

		getAjaxOptions: function(arg) {			
			var options = dorado.Object.apply({}, this._baseOptions), jsonData = options.jsonData = {};
			if (this._baseOptions.jsonData) dorado.Object.apply(jsonData, this._baseOptions.jsonData);
			jsonData.action = "resolve-data";
			jsonData.dataResolver = this.name;
			if (arg) {
				jsonData.dataItems = arg.dataItems;
				jsonData.parameter = arg.parameter;
				jsonData.sysParameter = arg.sysParameter;
				jsonData.context = arg.view ? arg.view.get("context") : null;
			}
			return options;
		}
	});

	var dataResolvers = {};

	/**
	 * 创建一个数据处理器。
	 * @param {String} id 数据处理器的服务id。
	 * @return {dorado.DataProvider} 新创建的数据处理器。
	 */
	dorado.DataResolver.create = function(id) {
		var resolver = dataResolvers[id];
		if (resolver === undefined) {
			dataResolvers[id] = resolver = new dorado.DataResolver(id);
		}
		return resolver;
	};

})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function () {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 数据类型。数据类型是对所有系统中可能使用到的数据类型的抽象。
	 * <p>
	 * 此参数具有多态性，当我们传入一个String类型的参数时，该String值表示数据类型的name。
	 * 当我们传入的参数是一个JSON对象时，系统会自动将该JSON对象中的属性复制到数据类型中。 <br>
	 * 如果没有在此步骤中没有为组件指定name，那么系统会自动为其分配一个name。
	 * </p>
	 * @abstract
	 * @extends dorado.AttributeSupport
	 * @param {String|Object} [config] 配置信息。
	 */
	dorado.DataType = $extend(dorado.AttributeSupport, /** @scope dorado.DataType.prototype */
		{
			/**
			 * @function
			 * @name dorado.DataType#parse
			 * @description 尝试将一个任意类型的值转换成本数据类型所描述的类型。
			 * @param {Object} data 要转换的数据。
			 * @param {Object} [argument] 转换时可能需要用到的参数。
			 * @return {Object} 转换后得到的数据。
			 */
			// =====

			$className: "dorado.DataType",

			ATTRIBUTES: /** @scope dorado.DataType.prototype */
			{

				/**
				 * 数据类型的名称。
				 * @type String
				 * @attribute readOnly
				 */
				name: {
					readOnly: true
				},

				/**
				 * 用于在后端定位服务的id。如无特殊需要请不要修改。
				 * @type String
				 * @attribute writeOnce
				 */
				id: {
					writeOnce: true
				},

				/**
				 * 隶属的数据类型管理器。
				 * @type dorado.DataTypeRepository
				 * @attribute readOnly
				 */
				dataTypeRepository: {
					readOnly: true
				},

				/**
				 * 返回所属的视图。
				 * @type dorado.widget.View
				 * @attribute readOnly
				 */
				view: {
					path: "_dataTypeRepository._view"
				},

				/**
				 * 用户自定义数据。
				 * @type Object
				 * @attribute skipRefresh
				 */
				userData: {
					skipRefresh: true
				}
			},

			constructor: function (config) {
				dorado.AttributeSupport.prototype.constructor.call(this, config);

				var name;
				if (config && config.constructor == String) {
					name = config;
					config = null;
				} else if (config) {
					name = config.name;
					delete config.name;
					this.set(config, { tryNextOnError: true, skipUnknownAttribute: true });
				}
				this._name = name ? name : dorado.Core.newId();
				if (!this._id) this._id = this._name;

				if (this.id) {
					if (window[this.id] === undefined) {
						window[this.id] = this;
					} else {
						var v = window[this.id];
						if (v instanceof Array) {
							v.push(this);
						} else {
							window[this.id] = [v, this];
						}
					}
				}
			},
			
			setDataTypeRepository: function(dataTypeRepository) {
				this._dataTypeRepository = dataTypeRepository;
				if (this._processLiveBinding && dataTypeRepository) {
					var view = dataTypeRepository._view;
					if (view && view !== $topView && !this._liveBindingProcessed) {
						this._processLiveBinding(view);
					}
				}
			},

			getListenerScope: function () {
				return this.get("view");
			},

			/**
			 * 尝试将一个任意类型的值转换成本文本值。<br>
			 * 如需在子类中改变其逻辑其复写{@link dorado.DataType#doToText}方法。
			 * @param {Object} data 要转换的数据。
			 * @param {Object} [argument] 转换时可能需要用到的参数。
			 * @return {String} 转换后得到的文本。
			 * @final
			 * @see dorado.DataType#doToText
			 */
			toText: function (data, argument) {
				if (typeof argument == "string" && argument.indexOf("call:") == 0) {
					var func = argument.substring(5);
					func = window[func];
					if (typeof func == "function") {
						return func(data);
					}
				}
				return this.doToText.apply(this, arguments);
			},

			/**
			 * 将一个任意类型的值转换成本文本值。此方法供子类复写。
			 * @param {Object} data 要转换的数据。
			 * @param {Object} [argument] 转换时可能需要用到的参数。
			 * @return {String} 转换后得到的文本。
			 * @protected
			 * @see dorado.DataType#toText
			 */
			doToText: function (data, argument) {
				if (data === null || data === undefined || (typeof data !== "string" && typeof data !== "object" && isNaN(data))) {
					return '';
				} else {
					return data + '';
				}
			}
		});

	dorado.DataType.getSubName = function (name) {
		var complexDataTypeNameRegex = /^[\w\/.$:@#\-|]*\[[\w\/\[\]\..$:@#\-|]*\]$/;
		return (name.match(complexDataTypeNameRegex)) ? name.substring(name.indexOf('[') + 1, name.length - 1) : null;
	};

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 聚合类型。
	 * @extends dorado.DataType
	 * @see dorado.EntityDataType
	 */
	dorado.AggregationDataType = $extend(dorado.DataType, /** @scope dorado.AggregationDataType.prototype */
		{
			$className: "dorado.AggregationDataType",

			ATTRIBUTES: /** @scope dorado.AggregationDataType.prototype */
			{
				/**
				 * 聚合元素的数据类型。
				 * @return {dorado.DataType}
				 * @attribute writeOnce
				 */
				elementDataType: {
					getter: function () {
						return this.getElementDataType("always");
					},
					writeOnce: true
				},

				/**
				 * 对数据进行分页浏览时每页的记录数。
				 * @type int
				 * @attribute
				 */
				pageSize: {
					defaultValue: 0
				}
			},

			constructor: function (config, elementDataType) {
				dorado.DataType.prototype.constructor.call(this, config, elementDataType);
				if (elementDataType)
					this._elementDataType = elementDataType;
			},

			getElementDataType: function (loadMode) {
				var dataType = this._elementDataType;
				if (dataType != null) {
					dataType = dorado.LazyLoadDataType.dataTypeTranslator.call(this, dataType, loadMode);
					if (dataType instanceof dorado.DataType) this._elementDataType = dataType;
				}
				return dataType;
			},
			/**
			 * 将传入的数据转换为集合。
			 * @param {Object|Object[]} data 要转换的数据。
			 * @return {dorado.EntityList} 转换后得到的集合。
			 */
			parse: function (data, alwaysTransferEntity) {
				if (data != null) {
					return (data instanceof dorado.EntityList) ? data : new dorado.EntityList(data, this._dataTypeRepository, this, alwaysTransferEntity);
				} else {
					return null;
				}
			}
		});

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @name dorado.EntityDataType
	 * @class 实体类型。
	 * <p>
	 * EntityDataType的get方法在{@link dorado.AttributeSupport#get}的基础上做了增强。
	 * 除了原有的读取属性值的功能之外，此方法还另外提供了下面的用法。
	 * <ul>
	 *    <li>当传入一个以#开头的字符串时，#后面的内容将被识别成属性声明的名称，表示根据名称获取属性声明。参考{@link dorado.EntityDataType#getPropertyDef}。</li>
	 * </ul>
	 * </p>
	 * @extends dorado.DataType
	 * @extends dorado.EventSupport
	 * @see dorado.PropertyDef
	 * @see dorado.Reference
	 * @see dorado.Lookup
	 */
	dorado.EntityDataType = $extend([dorado.DataType, dorado.EventSupport], /** @scope dorado.EntityDataType.prototype */
		{
			$className: "dorado.EntityDataType",

			ATTRIBUTES: /** @scope dorado.EntityDataType.prototype */
			{

				/**
				 * 是否允许外界访问实体中尚未声名的属性。
				 * @type boolean
				 * @attribute
				 */
				acceptUnknownProperty: {},

				/**
				 * 默认的显示属性。
				 * <p>
				 * 当系统需要将一个属于此类型的数据实体转换成用于显示的文本时（即相当于调用{@link dorado.Entity#toText}方法时），
				 * 如果此时数据类型中定义了此值，那么系统将直接使用此值所代表的属性的属性值作为整个数据实体的显示文本。
				 * </p>
				 * <p>
				 * 例如一个Employee类型中有id、name、sex、phone等很多属性，如果我们定义了Employee类型的defaultDisplayProperty=name，
				 * 那么系统会将直接用name属性的值作为其隶属的数据实体的显示文本。
				 * </p>
				 * @type String
				 * @attribute
				 */
				defaultDisplayProperty: {},

				/**
				 * 当数据实体需要确认其中的内容修改时，最高可以接受哪个级别的验证信息。
				 * 出此处给定的默认值ok之外，通常可选的值还有warn。info和error则一般不会作为此属性的值。
				 * @type String
				 * @default "ok"
				 * @attribute
				 * @see dorado.validator.Validator#validate
				 * @see dorado.Entity#getValidationResults
				 */
				acceptValidationState: {
					defaultValue: "ok"
				},

				/**
				 * 是否禁用其中所有的数据验证器。包括所有属性上的数据验证器。
				 * @type boolean
				 * @attribute
				 */
				validatorsDisabled: {},

				/**
				 * 属性声明的集合。
				 * <p>
				 * 此属性在读写时的意义不完全相同。
				 * <ul>
				 * <li>当读取时返回实体类型中属性声明的集合，类型为{@link dorado.util.KeyedArray}。</li>
				 * <li>当写入时用于添加属性声明。<br>
				 * 此处数组中既可以放入属性声明的实例，又可以放入JSON对象。
				 * 具体请参考{@link dorado.EntityDataType#addPropertyDef}。</li>
				 * </ul>
				 * </p>
				 * @type Object[]|dorado.PropertyDef[]
				 * @attribute
				 */
				propertyDefs: {
					setter: function (value) {
						this.removeAllPropertyDef();
						if (value) {
							for (var i = 0; i < value.length; i++) {
								this.addPropertyDef(value[i]);
							}
						}
					}
				}
			},

			EVENTS: /** @scope dorado.EntityDataType.prototype */
			{
				/**
				 * 当某个此类型的{@link dorado.EntityList}中的当前数据实体将要被改变前触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.oldCurrent 原先的当前数据实体。
				 * @param {dorado.Entity} arg.newCurrent 新的当前数据实体。
				 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#current
				 * @see dorado.EntityList#setCurrent
				 */
				beforeCurrentChange: {},

				/**
				 * 当某个此类型的{@link dorado.EntityList}中的当前数据实体被改变后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.oldCurrent 原先的当前数据实体。
				 * @param {dorado.Entity} arg.newCurrent 新的当前数据实体。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#current
				 * @see dorado.EntityList#setCurrent
				 */
				onCurrentChange: {},

				/**
				 * 当某个此类型的{@link dorado.EntityList}中的将要插入一个新的数据实体前触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.entity 将要插入的数据实体。
				 * @param {String} arg.insertMode 插入方式。
				 * @param {dorado.Entity} arg.refEntity 插入位置的参照数据实体。
				 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#insert
				 */
				beforeInsert: {},

				/**
				 * 当某个此类型的{@link dorado.EntityList}中的插入一个新的数据实体后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.entity 新插入的数据实体。
				 * @param {String} arg.insertMode 插入方式。
				 * @param {dorado.Entity} arg.refEntity 插入位置的参照数据实体。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#insert
				 */
				onInsert: {},

				/**
				 * 当某个此类型的{@link dorado.EntityList}中的将要删除的一个数据实体前触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.entity 将被删除的数据实体。
				 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#remove
				 */
				beforeRemove: {},

				/**
				 * 当某个此类型的{@link dorado.EntityList}中的删除了一个数据实体后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.EntityList} arg.entityList 触发事件的实体对象集合。
				 * @param {dorado.Entity} arg.entity 被删除的数据实体。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.EntityList#remove
				 */
				onRemove: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}中的属性值将要被改变前触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @param {String} arg.property 将要被改变的属性名。
				 * @param {Object} arg.oldValue 原先的属性值。
				 * @param {Object} #arg.newValue 将要写入的值。
				 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#set
				 */
				beforeDataChange: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}中的属性值被改变后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @param {String} arg.property 被改变的属性名。
				 * @param {Object} arg.oldValue 原先的属性值。
				 * @param {Object} arg.newValue 将要写入的值。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#set
				 */
				onDataChange: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}的状态将要被改变前触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @param {int} arg.oldState 原先的状态代码。
				 * @param {int} arg.newState 新的状态代码。
				 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#state
				 * @see dorado.Entity#setState
				 */
				beforeStateChange: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}的状态被改变后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @param {int} arg.oldState 原先的状态代码。
				 * @param {int} arg.newState 新的状态代码。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#state
				 * @see dorado.Entity#setState
				 */
				onStateChange: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}的被装载是触发的事件。<br>
				 * 此处所说的装载一般指数据实体从服务端被装载到客户端，在客户端添加一个数据实体不会触发此事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 */
				onEntityLoad: {},

				/**
				 * 当某个此类型的{@link dorado.Entity}的额外信息被改变后触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#getMessages
				 * @see dorado.Entity#getMessageState
				 * @see dorado.Entity#setMessages
				 */
				onMessageChange: {},

				/**
				 * 系统尝试将一个数据实体对象转换成一段用于显示的文本时触发的事件。
				 * @param {Object} self 事件的发起者，即EntityDataType本身。
				 * @param {Object} arg 事件参数。
				 * @param {dorado.Entity} arg.entity 触发事件的实体对象。
				 * @param {String} #arg.text 转换得到的用于显示的文本。
				 * @param {boolean} #arg.processDefault=false 用于通知系统是否要继续完成后续动作。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 * @see dorado.Entity#state
				 * @see dorado.Entity#setState
				 */
				onEntityToText: {}
			},

			constructor: function (config) {
				this._observers = {};
				this._propertyDefs = new dorado.util.KeyedArray(function (propertyDef) {
					return propertyDef._name;
				});
				dorado.DataType.prototype.constructor.call(this, config);
			},
			
			_addObserver: function(observer) {
				var key = observer._uniqueId;
				if (!key) observer._uniqueId = key = dorado.Core.newId();
				if (!this._observers[key]) {
					this._observers[key] = observer;
				}
			},
			
			_removeObserver: function(observer) {
				var key = observer._uniqueId;
				if (!key) return;
				delete this._observers[key];
			},

			doGet: function (attr) {
				var c = attr.charAt(0);
				if (c == '#' || c == '&') {
					return this.getPropertyDef(attr.substring(1));
				} else {
					return dorado.DataType.prototype.doGet.call(this, attr);
				}
			},

			fireEvent: function () {
				// 对于那些Ajax懒装载的DataType，其中view可能是空的
				var view = this.get("view"), oldView = window.view;
				window.view = view;
				try {
					return $invokeSuper.call(this, arguments);
				}
				finally {
					window.view = oldView;
				}
			},

			/**
			 * 向实体类型中添加一个属性声明。
			 * <p>
			 * 此处数组中可放置两种类型的属性声明定义：
			 *    <ul>
			 *    <li>直接放入一个属性声明的实例对象。</li>
			 *    <li>放入含属性声明信息的JSON对象。<br>
			 * 此时可以使用子控件类型名称中"dorado."和"PropertyDef"之间的部分作为$type的简写。
			 * 如果$type为空或不指定$type，系统将会按照{@link dorado.PropertyDef}来实例化。
			 *    </li>
			 *    </ul>
			 * </p>
			 * @param {dorado.PropertyDef|Object} propertyDef 要添加的属性声明或含属性声明信息的JSON对象。
			 * @return dorado.PropertyDef 添加的属性声明。
			 * @see dorado.PropertyDef
			 * @see dorado.Reference
			 * @see dorado.Toolkits.createInstance
			 */
			addPropertyDef: function (propertyDef) {
				if (propertyDef instanceof dorado.PropertyDef) {
					if (propertyDef._parent) {
						var parent = propertyDef._parent;
						if (parent.getPropertyDef(propertyDef._name) == propertyDef) {
							parent._propertyDefs.remove(propertyDef);
						}
					}
				} else {
					propertyDef = dorado.Toolkits.createInstance("propertydef", propertyDef);
				}

				propertyDef._parent = this;
				this._propertyDefs.append(propertyDef);

				if (this._wrapperType) this.updateWrapperType();
				return propertyDef;
			},

			/**
			 * 从实体类型中删除一个属性声明。
			 * @param {dorado.PropertyDef} propertyDef 要删除的属性声明。
			 */
			removePropertyDef: function (propertyDef) {
				propertyDef._parent = null;
				this._propertyDefs.remove(propertyDef);
			},

			/**
			 * 从实体类型中删除所有属性声明。
			 */
			removeAllPropertyDef: function() {
				if (this._propertyDefs.size == 0) return;
				this._propertyDefs.each(function (propertyDef) {
					propertyDef._parent = null;
				});
				this._propertyDefs.clear();
			},

			/**
			 * 根据属性名从实体类型返回相应的属性声明。
			 * @param {String} name 属性名。
			 * @return {dorado.PropertyDef} 属性声明。
			 */
			getPropertyDef: function (name) {
				return this._propertyDefs.get(name);
			},

			/**
			 * 将传入的数据转换为一个实体对象。
			 * @param {Object} data 要转换的数据
			 * @return {dorado.Entity} 转换后得到的实体。
			 */
			parse: function (data, alwaysTransferEntity) {
				if (data != null) {
					if (data instanceof dorado.Entity) {
						return data
					} else {
						var oldProcessDefaultValue = SHOULD_PROCESS_DEFAULT_VALUE;
						SHOULD_PROCESS_DEFAULT_VALUE = false;
						var entity = new dorado.Entity(data, this._dataTypeRepository, this);
						entity.alwaysTransferEntity = true;
						SHOULD_PROCESS_DEFAULT_VALUE = oldProcessDefaultValue;
                        return entity;
					}
				} else {
					return null;
				}
			},

			/**
			 * 扩展本实体数据类型。即以当前的实体数据类型为模板，创建一个相似的、全新的实体数据类型。
			 * @param {String|Object} config 新的实体数据类型的名称或构造参数。
			 * <p>
			 * 此参数具有多态性，当我们传入一个String类型的参数时，该String值表示数据类型的name。
			 * 当我们传入的参数是一个JSON对象时，系统会自动将该JSON对象中的属性复制到数据类型中。 <br>
			 * 如果没有在此步骤中没有为组件指定name，那么系统会自动为其分配一个name。
			 * </p>
			 * @return {dorado.EntityDataType} 新的实体数据类型。
			 */
			extend: function (config) {
				if (typeof config == "string") {
					config = {
						name: config
					};
				} else
					config = config || {};
				var self = this;
				jQuery(["acceptUnknownProperty", "tag"]).each(function (i, p) {
					if (config[p] === undefined)
						config[p] = self.get(p);
				});
				var newDataType = new this.constructor(config);
				newDataType._events = dorado.Core.clone(this._events);
				this._propertyDefs.each(function (pd) {
					newDataType.addPropertyDef(dorado.Core.clone(pd));
				});
				return newDataType;
			},
			
			_processLiveBinding: function(view) {
				if (view) {
					if (this._tags) {
						var tag;
						for (var i = 0, len = this._tags.length; i < len; i++) {
							tag = this._tags[i];
							if (view._liveTagBindingMap) {
								var liveBindings = view._liveTagBindingMap[tag];
								if (liveBindings) {
									var liveBinding;
									for (var j = 0, l = liveBindings.length; j < l; j++) {
										liveBinding = liveBindings[j];
										if (liveBinding.subObject) {
											var subObject = this.get(liveBinding.subObject);
											if (subObject) subObject.bind(liveBinding.event, liveBinding.listener);
										}
										else {
											this.bind(liveBinding.event, liveBinding.listener);
										}
									}
								}
							}
							if (view._liveTagSettingMap) {
								var liveSettings = view._liveTagSettingMap[tag];
								if (liveSettings) {
									var liveSetting;
									for (var j = 0, l = liveSettings.length; j < l; j++) {
										liveSetting = liveSettings[j];
										this.set(liveSetting.attr, liveSetting.value, liveSetting.options);
									}
								}
							}
						}
					}
				}
				this._liveBindingProcessed = true;
			},

			updateWrapperType: function () {
				var wrapperType = this._wrapperType, wrapperPrototype = wrapperType.prototype;
				this._propertyDefs.each(function (pd) {
					var name = pd._name;
					if (wrapperType._definedProperties[name]) return;
					wrapperType._definedProperties[name] = true;

					var getter = function () {
						var value;
						if (this._textMode) {
							value = this._entity._data[name];
							if (value && typeof value == "object" && !(value instanceof Date)) {
								value = this._entity.get(name);
							}
							else {
								value = this._entity.getText(name);
							}
						}
						else {
							value = this._entity.get(name);
						}
						if (value instanceof dorado.Entity || value instanceof dorado.EntityList) {
							value = value.getWrapper(this._options);
						}
						return value;
					};
					var setter = function (value) {
						if (this._readOnly) {
							throw new dorado.Exception("Wrapper is readOnly.");
						}
						this._entity.set(name, value);
					};

					try {
						wrapperPrototype.__defineGetter__(name, getter);
						wrapperPrototype.__defineSetter__(name, setter);
					} catch (e) {
						Object.defineProperty(wrapperPrototype, name, {
							get: getter,
							set: setter
						});
					}
				});
			},

			getWrapperType: function () {
				if (!this._wrapperType) {
					this._wrapperType = function (entity, options) {
						this._entity = entity;
						this._options = options;
						this._textMode = options && options.textMode;
						this._readOnly = options && options.readOnly;
					};
					this._wrapperType._definedProperties = {};
					this.updateWrapperType();
				}
				return this._wrapperType;
			}
		});

	/**
	 * @name dorado.datatype
	 * @namespace 包含各种常用数据类型声明的命名空间。
	 */
	dorado.datatype = {};

	var DataType = dorado.DataType;
	DataType.STRING = 1;
	DataType.PRIMITIVE_INT = 2;
	DataType.INTEGER = 3;
	DataType.PRIMITIVE_FLOAT = 4;
	DataType.FLOAT = 5;
	DataType.PRIMITIVE_BOOLEAN = 6;
	DataType.BOOLEAN = 7;
	DataType.DATE = 8;
	DataType.TIME = 9;
	DataType.DATETIME = 10;
	DataType.PRIMITIVE_CHAR = 11;
	DataType.CHARACTER = 12;

	/**
	 * @class 字符串类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.StringDataType = $extend(DataType, /** @scope dorado.datatype.StringDataType.prototype */
		{
			$className: "dorado.datatype.StringDataType",

			_code: DataType.STRING,

			parse: function (data, argument) {
				return (data == null) ? null : (data + '');
			},
			doToText: function (data, argument) {
				return (data == null) ? '' : data + '';
			}
		});

	/**
	 * 默认的字符串类型的实例。
	 * @type dorado.datatype.StringDataType
	 * @constant
	 */
	dorado.$String = new dorado.datatype.StringDataType("String");

	$parseFloat = dorado.util.Common.parseFloat;
	$parseInt = function (s) {
		var n = Math.round($parseFloat(s));
		if (n > 9007199254740991) {
			throw new dorado.ResourceException("dorado.data.ErrorNumberOutOfRangeG");
		}
		else if (n < -9007199254740991) {
			throw new dorado.ResourceException("dorado.data.ErrorNumberOutOfRangeL");
		}
		return n;
	};
	$formatFloat = dorado.util.Common.formatFloat;

	/**
	 * @class 原生整数类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.PrimitiveIntDataType = $extend(DataType, /** @scope dorado.datatype.PrimitiveIntDataType.prototype */
		{
			$className: "dorado.datatype.PrimitiveIntDataType",

			_code: DataType.PRIMITIVE_INT,

			parse: function (data, argument) {
				var n = $parseInt(data);
				return (isNaN(n)) ? 0 : n;
			},
			/**
			 * 尝试将一个整数转换成本文本值。
			 * @param {int} data 要转换的数据。
			 * @param {String} [argument] 转换时可能需要用到的参数。此处为数字的格式化字符串。
			 * @return {String} 转换后得到的文本。
			 * @see $formatFloat
			 */
			doToText: $formatFloat
		});

	/**
	 * 默认的原生整数类型的实例。
	 * @type dorado.datatype.PrimitiveIntDataType
	 * @constant
	 */
	dorado.$int = new dorado.datatype.PrimitiveIntDataType("int");

	/**
	 * @class 整数对象类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.IntegerDataType = $extend(DataType, /** @scope dorado.datatype.IntegerDataType.prototype */
		{
			$className: "dorado.datatype.IntegerDataType",

			_code: DataType.INTEGER,

			parse: function (data, argument) {
				var n = $parseInt(data);
				return (isNaN(n)) ? null : n;
			},
			/**
			 * 尝试将一个整数对象转换成本文本值。
			 * @param {int} data 要转换的数据。
			 * @param {String} [argument] 转换时可能需要用到的参数。此处为数字的格式化字符串。
			 * @return {String} 转换后得到的文本。
			 * @see $formatFloat
			 */
			doToText: $formatFloat
		});

	/**
	 * 默认的整数对象类型的实例。
	 * @type dorado.datatype.IntegerDataType
	 * @constant
	 */
	dorado.$Integer = new dorado.datatype.IntegerDataType("Integer");

	/**
	 * @class 原生浮点类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.PrimitiveFloatDataType = $extend(DataType, /** @scope dorado.datatype.PrimitiveFloatDataType.prototype */
		{
			$className: "dorado.datatype.PrimitiveFloatDataType",

			_code: DataType.PRIMITIVE_FLOAT,

			parse: function (data, argument) {
				var n = $parseFloat(data);
				return (isNaN(n)) ? 0 : n;
			},
			/**
			 * 尝试将一个浮点数转换成本文本值。
			 * @param {float} data 要转换的数据。
			 * @param {String} [argument] 转换时可能需要用到的参数。此处为数字的格式化字符串。
			 * @return {String} 转换后得到的文本。
			 * @see $formatFloat
			 */
			doToText: $formatFloat
		});

	/**
	 * 默认的原生浮点类型的实例。
	 * @type dorado.datatype.PrimitiveFloatDataType
	 * @constant
	 */
	dorado.$float = new dorado.datatype.PrimitiveFloatDataType("float");

	/**
	 * @class 浮点对象类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.FloatDataType = $extend(DataType, /** @scope dorado.datatype.FloatDataType.prototype */
		{
			$className: "dorado.datatype.FloatDataType",

			_code: DataType.FLOAT,

			parse: function (data, argument) {
				var n = $parseFloat(data);
				return (isNaN(n)) ? null : n;
			},
			/**
			 * 尝试将一个浮点数对象转换成本文本值。
			 * @param {float} data 要转换的数据。
			 * @param {String} [argument] 转换时可能需要用到的参数。此处为数字的格式化字符串。
			 * @return {String} 转换后得到的文本。
			 * @see $formatFloat
			 */
			doToText: $formatFloat
		});

	/**
	 * 默认的浮点对象类型的实例。
	 * @type dorado.datatype.FloatDataType
	 * @constant
	 */
	dorado.$Float = new dorado.datatype.FloatDataType("Float");

	function parseBoolean(data, argument) {
		if (argument == null) {
			if (data == null) return false;
			if (data.constructor == String) {
				return (data.toLowerCase() == "true");
			} else {
				return !!data;
			}
		} else {
			return (data === argument);
		}
	}

	/**
	 * @class 原生逻辑类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.PrimitiveBooleanDataType = $extend(DataType, /** @scope dorado.datatype.PrimitiveBooleanDataType.prototype */
		{
			$className: "dorado.datatype.PrimitiveBooleanDataType",

			_code: DataType.PRIMITIVE_BOOLEAN,

			/**
			 * 尝试将一个任意类型的值转换逻辑值。
			 * @param {String|int} data 要转换的数据。
			 * @param {String} [argument] 代表逻辑true的值，即如果指定了该参数，那么当传入的数据与该值相等时将被转换为逻辑true。
			 * @return {boolean} 转换后得到的逻辑值。
			 */
			parse: parseBoolean
		});

	/**
	 * 默认的原生逻辑类型的实例。
	 * @type dorado.datatype.PrimitiveBooleanDataType
	 * @constant
	 */
	dorado.$boolean = new dorado.datatype.PrimitiveBooleanDataType("boolean");

	/**
	 * @class 逻辑对象类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.BooleanDataType = $extend(DataType, /** @scope dorado.datatype.BooleanDataType.prototype */
		{
			$className: "dorado.datatype.BooleanDataType",

			_code: DataType.BOOLEAN,

			/**
			 * 尝试将一个任意类型的值转换逻辑对象。
			 * @param {String|int} data 要转换的数据。
			 * @param {String} [argument] 代表逻辑true的值，即如果指定了该参数，那么当传入的数据与该值相等时将被转换为逻辑true。
			 * @return {boolean} 转换后得到的逻辑对象。
			 */
			parse: function (data, argument) {
				if (data === undefined || data === null) return null;
				return parseBoolean(data, argument);
			}
		});

	/**
	 * 默认的逻辑对象类型的实例。
	 * @type dorado.datatype.BooleanDataType
	 * @constant
	 */
	dorado.$Boolean = new dorado.datatype.BooleanDataType("Boolean");

	/**
	 * @class 日期类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.DateDataType = $extend(DataType, /** @scope dorado.datatype.DateDataType.prototype */
		{
			$className: "dorado.datatype.DateDataType",

			_code: DataType.DATE,

			/**
			 * 尝试将一个任意类型的值转换日期值。
			 * @param {String|int} data 要转换的数据。
			 * @param {String} [argument] 如果传入的数据为日期字符创，那么此参数可用于指定日期格式。
			 * @return {Date} 转换后得到的日期值。
			 */
			parse: function (data, argument) {
				if (data == null) return null;
				if (typeof data == "string") data = jQuery.trim(data);
				if (data == '') return null;

				if (data instanceof Date) return data;
				if (typeof data == "number") {
					var date = new Date(data);
					if (!isNaN(date.getTime())) {
						return date;
					}
					else {
						date = null;
					}
				}

				if (typeof data == "string") {
					var format = argument || $setting["common.defaultDateFormat"];
					var date = Date.parseDate(data, format);
					if (date == null) {
						date = Date.parseDate(data, "Y-m-d\\TH:i:s\\Z");
						if (date == null) {
							format = $setting["common.defaultTimeFormat"];
							if (format) {
								date = Date.parseDate(data, format);
								if (date == null) {
									var format = $setting["common.defaultDateTimeFormat"];
									if (format) {
										date = Date.parseDate(data, format);
//										if (date == null) date = new Date(data);
									}
								}
							}
						}
					}
				}

				if (date == null) {
					throw new dorado.ResourceException("dorado.data.BadDateFormat", data);
				}
				return date;
			},

			/**
			 * 尝试将一个日期值转换成本文本值。
			 * @param {Date} data 要转换的数据。
			 * @param {String} [argument] 转换时可能需要用到的参数。
			 * @return {String} 转换后得到的文本。
			 * @see Date
			 */
			doToText: function (data, argument) {
				return (data != null && data instanceof Date) ? data.formatDate(argument || $setting["common.defaultDisplayDateFormat"]) : '';
			}
		});

	/**
	 * 默认的日期类型的实例。
	 * @type dorado.datatype.DateDataType
	 * @constant
	 */
	dorado.$Date = new dorado.datatype.DateDataType("Date");

	/**
	 * 默认的时间类型的实例。
	 * @type dorado.datatype.DateDataType
	 * @constant
	 */
	var time = dorado.$Time = new dorado.datatype.DateDataType("Time");
	time._code = DataType.TIME;
	time.doToText = function (data, argument) {
		return (data != null && data instanceof Date) ? data.formatDate(argument || $setting["common.defaultDisplayTimeFormat"]) : '';
	};

	/**
	 * 默认的日期时间类型的实例。
	 * @type dorado.datatype.DateDataType
	 * @constant
	 */
	var datetime = dorado.$DateTime = new dorado.datatype.DateDataType("DateTime");
	datetime._code = DataType.DATETIME;
	datetime.doToText = function (data, argument) {
		return (data != null && data instanceof Date) ? data.formatDate(argument || $setting["common.defaultDisplayDateTimeFormat"]) : '';
	};

	/**
	 * @class 原生字符对象类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.PrimitiveCharDataType = $extend(DataType, /** @scope dorado.datatype.PrimitiveCharDataType.prototype */
		{
			$className: "dorado.datatype.PrimitiveCharDataType",

			_code: DataType.PRIMITIVE_CHAR,

			parse: function (data, argument) {
				var s = (data == null) ? '\0' : (data + '\0');
				return s.charAt(0);
			}
		});
	/**
	 * 默认的原生字符对象类型的实例。
	 * @type dorado.datatype.PrimitiveCharDataType
	 * @constant
	 */
	dorado.$char = new dorado.datatype.PrimitiveCharDataType("char");

	/**
	 * @class 字符对象类型。
	 * @extends dorado.DataType
	 */
	dorado.datatype.CharacterDataType = $extend(DataType, /** @scope dorado.datatype.CharacterDataType.prototype */
		{
			$className: "dorado.datatype.CharacterDataType",

			_code: DataType.CHARACTER,

			parse: function (data, argument) {
				var s = (data == null) ? '' : (data + '');
				return (s.length > 0) ? s.charAt(0) : null;
			}
		});
	/**
	 * 默认的字符对象类型的实例。
	 * @type dorado.datatype.CharacterDataType
	 * @constant
	 */
	dorado.$Character = new dorado.datatype.CharacterDataType("Character");

})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {
	var hasRespositoryListener = false;
	
	function newAggDataType(name, subId) {
		var dataType = new AggregationDataType(name, dorado.LazyLoadDataType.create(this, subId));
		this.register(dataType);
		return dataType;
	}
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 用于实现{@link dorado.DataType}信息延时装载的类。
	 * @param {dorado.DataTypeRepository} dataTypeRepository 对应的DataType所隶属的数据类型的管理器。
	 * @param {String} id DataType对应的服务端id。
	 */
	dorado.LazyLoadDataType = $class(/** @scope dorado.LazyLoadDataType.prototype */{
		$className: "dorado.LazyLoadDataType",
		
		constructor: function(dataTypeRepository, id) {
			/**
			 * @name dorado.LazyLoadDataType#dataTypeRepository
			 * @type dorado.DataTypeRepository
			 * @description 隶属的数据类型的管理器。
			 */
			this.dataTypeRepository = dataTypeRepository;
			
			/**
			 * @name dorado.LazyLoadDataType#id
			 * @type String
			 * @description DataType对应的服务端id。
			 */
			this.id = id;
		},
		
		/**
		 * 以同步操作的方式装载DataType的详细信息。
		 * @param {String} [loadMode="always"] 装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的DataType。</li>
		 * <li>auto	-	如果有需要则自动启动异步的DataType装载过程，但对于本次方法调用将返回undefined。</li>
		 * <li>never	-	不会激活DataType的装载过程。</li>
		 * </ul>
		 * @return {dorado.DataType} 装载到的DataType。
		 */
		get: function(loadMode) {
			return this.dataTypeRepository.get(this.id, loadMode);
		},
		
		/**
		 * 以异步操作的方式装载DataType的详细信息。
		 * @param {String} [loadMode="always"] 装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的DataType。</li>
		 * <li>auto	-	对于异步操作而言此选项没有实际意义，系统内部的处理方法将与always完全一致。</li>
		 * <li>never	-	不会激活DataType的装载过程。</li>
		 * </ul>
		 * @param {dorado.Callback} callback 回调对象，传入回调对象的参数即为装载到的DataType。
		 */
		getAsync: function(loadMode, callback) {
			this.dataTypeRepository.getAsync(this.id, callback, loadMode);
		},
		
		toString: function() {
			return dorado.defaultToString(this);
		}
	});
	
	dorado.LazyLoadDataType.create = function(dataTypeRepository, id) {
		var name = dorado.DataUtil.extractNameFromId(id);
		var origin = dataTypeRepository._get(name);
		if (origin instanceof dorado.DataType) {
			return origin;
		} else {
			if (origin && origin != DataTypeRepository.UNLOAD_DATATYPE) {
				return dataTypeRepository.get(name);
			} else {
				var subId = dorado.DataType.getSubName(id);
				if (subId) {
					var aggDataType = newAggDataType.call(dataTypeRepository, name, subId);
					aggDataType.set("id", id);
					return aggDataType;
				} else {
					dataTypeRepository.register(name);
					return new dorado.LazyLoadDataType(dataTypeRepository, id);
				}
			}
		}
	};
	
	dorado.LazyLoadDataType.dataTypeTranslator = function(dataType, loadMode) {
		if (dataType.constructor == String) {
			var repository;
			if (this.getDataTypeRepository) {
				repository = this.getDataTypeRepository();
			} else if (this.ATTRIBUTES && this.ATTRIBUTES.dataTypeRepository) {
				repository = this.get("dataTypeRepository");
			}
			if (!repository) repository = dorado.DataTypeRepository.ROOT;
			
			if (repository) {
				dataType = dorado.LazyLoadDataType.create(repository, dataType);
			} else {
				throw new dorado.ResourceException("dorado.data.RepositoryUndefined");
			}
		}
		
		loadMode = loadMode || "always";
		if (loadMode == "always") {
			if (dataType instanceof dorado.AggregationDataType) {
				dataType.getElementDataType();
			} else if (dataType instanceof dorado.LazyLoadDataType) dataType = dataType.get();
		} else if (loadMode == "auto") {
			if (dataType instanceof dorado.AggregationDataType) {
				dataType.getElementDataType();
			} else if (dataType instanceof dorado.LazyLoadDataType) dataType.getAsync();
		}
		if (!(dataType instanceof dorado.DataType)) dataType = null;
		return dataType;
	};
	
	dorado.LazyLoadDataType.dataTypeGetter = function() {
		var dataType = this._dataType;
		if (dataType != null) {
			dataType = dorado.LazyLoadDataType.dataTypeTranslator.call(this, dataType);
			if (this._dataType != dataType && dataType instanceof dorado.DataType) {
				this._dataType = dataType;
			}
		}
		return dataType;
	};
	
	dorado.DataTypePipe = $extend(dorado.DataPipe, {
		constructor: function(dataTypeRepository, id) {
			this.dataTypeRepository = dataTypeRepository || $dataTypeRepository;
			this.loadOptions = dataTypeRepository.loadOptions;
			this.id = id;
			this.name = dorado.DataUtil.extractNameFromId(id);
		},
		
		getAjaxOptions: function() {
			var dataTypeRepository = this.dataTypeRepository;
			return dorado.Object.apply({
				jsonData: {
					action: "load-datatype",
					dataType: [this.id],
					context: (dataTypeRepository._view ? dataTypeRepository._view.get("context") : null)
				}
			}, this.loadOptions);
		},
		
		doGet: function() {
			return this.doGetAsync();
		},
		
		doGetAsync: function(callback) {
			var ajax = dorado.util.AjaxEngine.getInstance(this.loadOptions), dataTypeRepository = this.dataTypeRepository;
			if (callback) {
				dataTypeRepository.register(this.name, this);
				ajax.request(this.getAjaxOptions(), {
					scope: this,
					callback: function(success, result) {
						if (success) {
							var json = result.getJsonData(), dataTypeJson, context;
							if (json.$context) {
								dataTypeJson = json.data;
								context = json.$context;
							} else {
								dataTypeJson = json;
							}
							
							if (dataTypeRepository.parseJsonData(dataTypeJson) > 0) {
								var dataType = dataTypeRepository._dataTypeMap[this.name];
//								if (dataType && dataType._config) {
//									var config =  dataType._config;
//									delete dataType._config;
//									dataType.set(config, { tryNextOnError: true, skipUnknownAttribute: true });
//								}
								$callback(callback, true, dataType, {
									scope: this
								});
							}
							
							if (context && dataTypeRepository._view) {
								var context = dataTypeRepository._view.get("context");
								context.put(context);
							}
						} else {
							$callback(callback, false, result.error, {
								scope: this
							});
						}
					}
				});
			} else {
				dataTypeRepository.unregister(this.name);
				var result = ajax.requestSync(this.getAjaxOptions());
				var jsonData = result.getJsonData(), dataType;
				if (jsonData && dataTypeRepository.parseJsonData(jsonData) > 0) {
					dataType = dataTypeRepository._dataTypeMap[this.name];
//					if (dataType && dataType._config) {
//						var config =  dataType._config;
//						delete dataType._config;
//						dataType.set(config, { tryNextOnError: true, skipUnknownAttribute: true });
//					}
				}
				if (!dataType) {
					throw new dorado.ResourceException("dorado.data.DataTypeLoadFailed", this.name);
				}
				return dataType;
			}
		}
	});
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 数据类型的管理器。
	 * <p>
	 * 子数据类型的管理器总是会继承父管理器中所有的数据类型。当外界尝试从子管理器获取某个数据类型时，
	 * 如果该类型不存在与子管理器中，那么子管理器将会继续尝试到父管理器查找。
	 * </p>
	 * @param {dorado.DataTypeRepository} parent 父数据类型的管理器。
	 */
	dorado.DataTypeRepository = DataTypeRepository = $extend(dorado.EventSupport, /** @scope dorado.DataTypeRepository.prototype */ {
		$className: "dorado.DataTypeRepository",
		
		EVENTS: /** @scope dorado.DataTypeRepository.prototype */ {
		
			/**
			 * 每当有新的数据类型被注册到该管理器或其父管理器中是触发的事件。
			 * @param {Object} self 事件的发起者，即控件本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DataType} arg.dataType 新注册的数据类型。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDataTypeRegister: {
				interceptor: function(superFire, self, arg) {
					var retval = superFire(self, arg);
					if (retval !== false) {
						for (var i = 0; i < this.children.length; i++) {
							this.children[i].fireEvent(self, arg);
						}
					}
					return retval;
				}
			}
		},
		
		constructor: function(parent) {
			this._dataTypeMap = {};
			
			/**
			 * @name dorado.DataTypeRepository#parent
			 * @type dorado.DataTypeRepository
			 * @description 父数据类型的管理器。
			 */
			this.parent = parent;
			if (parent) parent.children.push(this);
			
			/**
			 * @name dorado.DataTypeRepository#children
			 * @type dorado.DataTypeRepository[]
			 * @description 子数据类型的管理器的数组。
			 */
			this.children = [];
			
			/**
			 * @name dorado.DataTypeRepository#loadOptions
			 * @type Object
			 * @see dorado.util.AjaxEngine#request
			 * @see dorado.util.AjaxEngine#requestSync
			 * @description 进行数据类型装载操作时传入{@link dorado.util.AjaxEngine}的执行选项。
			 * <p>
			 * 如果要修改此属性的内容，您应该为loadOptions属性赋一个新的对象，
			 * 而不是直接修改原loadOptions对象中的子属性，因为这样很可能导致其他的其它DataTypeRepository实例的loadOptions被意外改变。
			 * </p>
			 */
			this.loadOptions = dorado.Object.apply({}, $setting["ajax.dataTypeRepositoryOptions"]);
		},
		
		destroy: function() {
			if (this.parent) this.parent.children.remove(this);
		},
		
		bind: function() {
			hasRespositoryListener = true;
			return $invokeSuper.call(this, arguments);
		},
		
		parseSingleDataType: function(jsonData) {
			var dataType, name = jsonData.name, type = jsonData.$type;
			delete jsonData.name;
			delete jsonData.$type;
			if (type == "Aggregation") {
				dataType = new dorado.AggregationDataType(name);
			} else {
				dataType = new dorado.EntityDataType(name);
			}
			if (dataType) {
				dataType.loadFromServer = true;
				dataType._dataTypeRepository = this;
				//dataType._config = jsonData;
				dataType.set(jsonData, { tryNextOnError: true, skipUnknownAttribute: true });
			}
			return dataType;
		},
		
		parseJsonData: function(jsonData) {
			var n = 0, dataTypeMap = this._dataTypeMap, dataType;
			if (jsonData instanceof Array) {
				n = jsonData.length;
				for (var i = 0; i < n; i++) {
					this.register(this.parseSingleDataType(jsonData[i]));
				}
			} else {
				this.register(this.parseSingleDataType(jsonData));
				n++;
			}
			return n;
		},
		
		/**
		 * 向管理器中注册一个数据类型。 注意此方法的多态参数。
		 * @param {String|dorado.DataType} name 此参数是一个多态参数。
		 * <ul>
		 * <li>当参数类型为String时代表要注册的数据类型的名称，此时还必须通过dataType参数来指定要注册的具体数据类型。</li>
		 * <li>当参数类型为{@link dorado.DataType}时代表要注册的数据类型，此时系统将忽略dataType参数。</li>
		 * </ul>
		 * @param {dorado.DataType} [dataType] 要注册的数据类型。
		 */
		register: function(name, dataType) {
			if (name.constructor == String) {
				dataType = dataType || DataTypeRepository.UNLOAD_DATATYPE;
			} else {
				dataType = name;
				name = name._name;
			}
			
			if (this._dataTypeMap[name] instanceof dorado.DataType) return;
			this._dataTypeMap[name] = dataType;
			if (dataType instanceof dorado.DataType) {
				dataType.setDataTypeRepository(this);
				if (hasRespositoryListener) {
					this.fireEvent("onDataTypeRegister", this, {
						dataType: dataType
					});
				}
			}
		},
		
		/**
		 * 从管理器中注销一个数据类型。
		 * @param {Object} name 此参数是一个多态参数。
		 * <ul>
		 * <li>当参数类型为String时代表要注销的数据类型的名称。</li>
		 * <li>当参数类型为{@link dorado.DataType}时代表要注销的数据类型。</li>
		 * </ul>
		 */
		unregister: function(name) {
			delete this._dataTypeMap[name];
		},
		
		_get: function(name) {
			var dataType = this._dataTypeMap[name];
			if (dataType && dataType._config) {
				var config =  dataType._config;
				delete dataType._config;
				dataType.set(config, { tryNextOnError: true, skipUnknownAttribute: true });
			}
			if (!dataType && this.parent) {
				dataType = this.parent._get(name);
			}
			return dataType;
		},
		
		/**
		 * 根据名称从管理器中获取相应的数据类型。<br>
		 * 如果该数据类型的详细信息尚不存于客户端，那么管理将自动从服务端装载该数据类型的详细信息。
		 * @param {String} name 数据类型的名称。
		 * @param {String} [loadMode="always"] 装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的DataType。</li>
		 * <li>auto	-	如果有需要则自动启动异步的DataType装载过程，但对于本次方法调用将返回undefined。</li>
		 * <li>never	-	不会激活DataType的装载过程。</li>
		 * </ul>
		 * @return {dorado.DataType} 数据类型。
		 */
		get: function(name, loadMode) {
			var id = name, name = dorado.DataUtil.extractNameFromId(id);
			var dataType = this._get(name);
			if (dataType == DataTypeRepository.UNLOAD_DATATYPE) { // 已认识但尚未下载的
				var subId = dorado.DataType.getSubName(id);
				if (subId) {
					dataType = newAggDataType.call(this, name, subId);
					dataType.set("id", id);
				} else {
					loadMode = loadMode || "always";
					if (loadMode == "always") {
						var pipe = new dorado.DataTypePipe(this, id);
						dataType = pipe.get();
					} else {
						if (loadMode == "auto") this.getAsync(id);
						dataType = null;
					}
				}
			} else if (dataType instanceof dorado.DataTypePipe) { // 正在下载的
				var pipe = dataType;
				if (loadMode == "always") dataType = pipe.get(callback);
				else dataType = null;
			} else if (!dataType) { // 不认识的
				var subId = dorado.DataType.getSubName(id);
				if (subId) {
					dataType = newAggDataType.call(this, name, subId);
					dataType.set("id", id);
				}
			}
			return dataType;
		},
		
		/**
		 * 以异步方式、根据名称从管理器中获取相应的数据类型。<br>
		 * 如果该数据类型的详细类型尚不存于客户端，那么管理将自动从服务端装载该数据类型的详细信息。
		 * @param {String} name 数据类型的名称。
		 * @param {Function|dorado.Callback} callback 回调对象，传入回调对象的参数即为获得的DataType。
		 * @param {String} [loadMode="always"] 装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的DataType。</li>
		 * <li>auto	-	对于异步操作而言此选项没有实际意义，系统内部的处理方法将与always完全一致。</li>
		 * <li>never	-	不会激活DataType的装载过程。</li>
		 * </ul>
		 */
		getAsync: function(name, callback, loadMode) {
			var id = name, name = dorado.DataUtil.extractNameFromId(id);
			var dataType = this._get(name);
			if (dataType == DataTypeRepository.UNLOAD_DATATYPE) {
				var subId = dorado.DataType.getSubName(id);
				if (subId) {
					dataType = newAggDataType.call(this, name, subId);
					dataType.set("id", id);
				} else {
					loadMode = loadMode || "always";
					if (loadMode != "never") {
						var pipe = new dorado.DataTypePipe(this, id);
						pipe.getAsync(callback);
						return;
					}
				}
			} else if (dataType instanceof dorado.DataTypePipe) {
				var pipe = dataType;
				if (loadMode != "never") {
					pipe.getAsync(callback);
					return;
				}
			} else if (!dataType) {
				var subId = dorado.DataType.getSubName(id);
				if (subId) {
					dataType = newAggDataType.call(this, name, subId);
					dataType.set("id", id);
				}
			}
			$callback(callback, true, dataType);
		},
		
		getLoadedDataTypes: function() {
		
			function collect(dataTypeRepository, nameMap) {
				var map = dataTypeRepository._dataTypeMap;
				for (var name in map) {
					var dt = map[name];
					if (dt.loadFromServer && !(dt instanceof dorado.AggregationDataType)) nameMap[name] = true;
				}
				if (dataTypeRepository.parent) collect(dataTypeRepository.parent, nameMap);
			}
			
			var nameMap = {}, result = [];
			collect(this, nameMap);
			for (var name in nameMap) 
				result.push(name);
			return result;
		}
	});
	
	var DataType = dorado.DataType;
	var root = new DataTypeRepository();
	
	/**
	 * 客户端的根数据类型管理器。
	 * @name dorado.DataTypeRepository.ROOT
	 * @type {dorado.DataTypeRepository}
	 * @constant
	 */
	DataTypeRepository.ROOT = root;
	DataTypeRepository.UNLOAD_DATATYPE = {};
	
	/**
	 * dorado.DataTypeRepository.ROOT的快捷方式。
	 * @type dorado.DataTypeRepository
	 * @constant
	 * @see dorado.DataTypeRepository.ROOT
	 */
	window.$dataTypeRepository = DataTypeRepository.ROOT;
	
	function cloneDataType(dataType, name) {
		var newDataType = dorado.Object.clone(dataType);
		newDataType._name = name;
		return newDataType;
	}
	
	root.register(dorado.$String);
	root.register("UUID", cloneDataType(dorado.$String, "UUID"));
	
	root.register(dorado.$char);
	root.register(dorado.$Character);
	
	dataType = dorado.$int;
	root.register("int", dataType);
	root.register("byte", cloneDataType(dataType, "byte"));
	root.register("short", cloneDataType(dataType, "short"));
	root.register("long", cloneDataType(dataType, "long"));
	
	dataType = dorado.$Integer;
	root.register("Integer", dataType);
	root.register("Byte", cloneDataType(dataType, "Byte"));
	root.register("Short", cloneDataType(dataType, "Short"));
	root.register("Long", cloneDataType(dataType, "Long"));
	
	dataType = dorado.$float;
	root.register("float", dataType);
	root.register("double", cloneDataType(dataType, "double"));
	
	dataType = dorado.$Float;
	root.register("Float", dataType);
	root.register("Double", cloneDataType(dataType, "Double"));
	root.register("BigDecimal", cloneDataType(dataType, "BigDecimal"));
	
	root.register(dorado.$boolean);
	root.register(dorado.$Boolean);
	
	dataType = dorado.$Date;
	root.register("Date", dataType);
	root.register("Calendar", cloneDataType(dataType, "Calendar"));
	
	root.register("Time", dorado.$Time);
	root.register("DateTime", dorado.$DateTime);
	
	var AggregationDataType = dorado.AggregationDataType;
	root.register(new AggregationDataType("List"));
	root.register(new AggregationDataType("Set"));
	root.register(new AggregationDataType("Array"));
	
	var EntityDataType = dorado.EntityDataType;
	root.register(new EntityDataType({
		name: "Bean",
		acceptUnknownProperty: true
	}));
	root.register(new EntityDataType({
		name: "Map",
		acceptUnknownProperty: true
	}));
	root.register(new EntityDataType({
		name: "Entity",
		acceptUnknownProperty: true
	}));
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 实体类型中的属性声明的抽象类。
	 * <p>
	 * 此对象的get方法在{@link dorado.AttributeSupport#get}的基础上做了增强。
	 * 除了原有的读取属性值的功能之外，此方法还另外提供了下面的用法。
	 * <ul>
	 *    <li>当传入一个以#开头的字符串时，#后面的内容将被识别成数据校验器的名称，表示根据名称获取数据校验器。参考{@link dorado.PropertyDef#getValidator}。</li>
	 * </ul>
	 * </p>
	 * @abstract
	 * @shortTypeName Default
	 * @extends dorado.AttributeSupport
	 * @extends dorado.EventSupport
	 * @see dorado.EntityDataType
	 * @param {String} name 属性名。
	 * @param {dorado.DataType|dorado.LazyLoadDataType} [dataType] 属性的数据类型。
	 */
	dorado.PropertyDef = $extend([dorado.AttributeSupport, dorado.EventSupport], /** @scope dorado.PropertyDef.prototype */ {
		$className: "dorado.PropertyDef",
		
		ATTRIBUTES: /** @scope dorado.PropertyDef.prototype */ {
		
			/**
			 * 属性名。
			 * @type String
			 * @attribute readOnly
			 */
			name: {
				readOnly: true
			},
			
			/**
			 * 此属性所隶属的实体类型。
			 * @type dorado.EntityDataType
			 * @attribute readOnly
			 */
			parent: {
				readOnly: true
			},
			
			/**
			 * 返回所属的视图。
			 * @type dorado.widget.View
			 * @attribute readOnly
			 */
			view: {
				path: "parent.view"
			},
			
			/**
			 * 数据类型。
			 * @return {dorado.DataType}
			 * @attribute writeOnce
			 */
			dataType: {
				getter: dorado.LazyLoadDataType.dataTypeGetter,
				writeOnce: true
			},
			
			/**
			 * 属性的标签，即用于显示的属性名。
			 * @type String
			 * @attribute
			 */
			label: {
				notifyObservers: true,
				getter: function() {
					var label = this._label;
					if (label == null) label = this._name;
					return label;
				}
			},
			
			/**
			 * 属性的描述信息。
			 * @type String
			 * @attribute
			 */
			description: {},
			
			/**
			 * 属性是否只读。
			 * @type boolean
			 * @attribute
			 */
			readOnly: {
				notifyObservers: true
			},
			
			/**
			 * 属性是否默认可见。
			 * @type boolean
			 * @attribute
			 * @default true
			 */
			visible: {
				defaultValue: true
			},
			
			/**
			 * 属性的输入格式。
			 * 具体用法请参考{@link dorado.PropertyDef#attribute:displayFormat}
			 * @type String
			 * @attribute
			 */
			typeFormat: {},
			
			/**
			 * 属性的显示格式。
			 * <p>
			 * 此属性对于不同的DataType其定义方法有不同的解释，具体的实现取决对相应DataType的toText方法。
			 * </p>
			 * <p>
			 * 例如：
			 * <li>对于数值型DataType而言，displayFormat的定义与{@link dorado.util.Common.formatFloat}方法的format参数一致。<li>
			 * <li>对于日期时间型DataType而言，displayFormat的定义与{@link Date.formatDate}方法的format参数一致。<li>
			 * </p>
			 * <p>
			 * 当用户传入的displayFormat字符串以call:开头时，dorado会将call:后面的部分识别为一个全局Function的名字，
			 * 如果系统中确实存在一个这样的Function，那么dorado会直接调用该Function并以其返回值作为转换后的格式。
			 * </p>
			 * @type String
			 * @attribute
			 */
			displayFormat: {},
			
			/**
			 * 一组用于定义改变属性显示方式的"代码"/"名称"键值对。
			 * @type Object[]
			 * @attribute
			 *
			 * @example
			 * // 例如对于一个以逻辑型表示性别的属性，我们可能希望在显示属性值时将true显示为"男"、将false显示为"女"。
			 * propertyDef.set("mapping", [
			 * 	{
			 * 		key : "true",
			 * 		value : "男"
			 * 	},
			 * 	{
			 * 		key : "false",
			 * 		value : "女"
			 * 	}
			 * ]);
			 */
			mapping: {
				setter: function(mapping) {
					this._mapping = mapping;
					if (mapping && mapping.length > 0) {
						var index = this._mappingIndex = {};
						for (var i = 0; i < mapping.length; i++) {
							var key = mapping[i].key;
							if (key == null) key = "${null}";
							else if (key === '') key = "${empty}";
							index[key + ''] = mapping[i].value;
						}
					} else {
						delete this._mappingIndex;
					}
					delete this._mappingRevIndex;
				}
			},
			
			/**
			 * 是否允许向此属性设置mapping的键值中未声明的值。即不允许设置mapping的键值中未声明的值。
			 * <p>
			 * 注意：此属性只在mapping属性确实有值时才有效。
			 * </p>
			 * @type boolean
			 * @attribute
			 */
			acceptUnknownMapKey: {},
			
			/**
			 * 该属性中的内容默认情况是否需要向服务端提交。
			 * @type boolean
			 * @attribute
			 */
			submittable: {
				defaultValue: true
			},
			
			/**
			 * 是否非空。
			 * @type boolean
			 * @attribute
			 */
			required: {
				notifyObservers: true
			},
			
			/**
			 * 默认值。
			 * @type Object
			 * @attribute
			 */
			defaultValue: {},
			
			/**
			 * 数据校验器的数组。
			 * <p>
			 * 此处数组中可放置两种类型的校验器定义：
			 * 	<ul>
			 * 	<li>直接放入一个校验器的实例对象。</li>
			 * 	<li>放入含校验器信息的JSON对象。<br>
			 * 此时可以使用子控件类型名称中"dorado."和"Validator"之间的部分作为$type的简写。
			 * 	</li>
			 * 	<li>直接放入一个字符串代表$type的简写。</li>
			 * 	</ul>
			 * </p>
			 * @type dorado.validator.Validator[]|Object[]|String[]
			 * @attribute
			 * @see dorado.validator.Validator
			 * @see dorado.Toolkits.createInstance
			 */
			validators: {
				setter: function(value) {
					var validators = [];
					for (var i = 0; i < value.length; i++) {
						var v = value[i];
						if (!(v instanceof dorado.validator.Validator)) {
							v = dorado.Toolkits.createInstance("validator", v);
						}
						if (v._propertyDef) {
							throw new dorado.Exception("Validator alreay belongs to another PropertyDef \"" + v._propertyDef._name + "\"."); 
						}
						v._propertyDef = this;
						validators.push(v);
					}
					this._validators = validators;
				}
			},
			
			/**
			 * 隶属的数据类型的管理器。
			 * @type dorado.DataTypeRepository
			 * @attribute readOnly
			 */
			dataTypeRepository: {
				getter: function(attr) {
					var parent = this.get("parent");
					return (parent) ? parent.get(attr) : null;
				},
				readOnly: true
			},
			
			/**
			 * 用户自定义数据。
			 * @type Object
			 * @attribute skipRefresh
			 */
			userData: {
				skipRefresh: true
			}
		},
		
		EVENTS: /** @scope dorado.PropertyDef.prototype */ {
			/**
			 * 当外界尝试从某数据实体中读取此属性的值时触发的事件。
			 * @param {Object} self 事件的发起者，即本属性声明对象。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.Entity} arg.entity 当前读取的数据实体。
			 * @param {Object} #arg.value 默认将要返回给外界的属性值。
			 * 同时如果您希望改变此实体属性提供给外界的值也可以直接修改此子属性。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @see dorado.Entity#get
			 * @event
			 */
			onGet: {},
			
			/**
			 * 当外界尝试从某数据实体中读取此属性的文本值时触发的事件。
			 * @param {Object} self 事件的发起者，即本属性声明对象。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.Entity} arg.entity 当前读取的数据实体。
			 * @param {String} #arg.text 默认将要返回给外界的属性文本值。
			 * 同时如果您希望改变此实体属性提供给外界的文本值也可以直接修改此子属性。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @see dorado.Entity#getText
			 * @event
			 */
			onGetText: {},
			
			/**
			 * 当外界尝试向某数据实体的此属性中写入一个值时触发的事件。
			 * @param {Object} self 事件的发起者，即本属性声明对象。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.Entity} arg.entity 当前设置的数据实体。
			 * @param {Object} #arg.value 默认将要写入该属性的值。
			 * 同时如果您希望改变实际写入值也可以直接修改此子属性。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @see dorado.Entity#set
			 * @event
			 */
			onSet: {}
		},
		
		constructor: function(name, dataType) {
			dorado.AttributeSupport.prototype.constructor.call(this, name, dataType);
			if (name) {
				if (name.constructor == String) {
					this._name = name;
					this._dataType = dataType;
				} else {
					this._name = name.name;
					delete name.name;
					this.set(name);
				}
			}
		},
		
		doSet: function(attr, value, skipUnknownAttribute, lockWritingTimes) {
			dorado.AttributeSupport.prototype.doSet.call(this, attr, value, skipUnknownAttribute, lockWritingTimes);
			if (this._parent) {
				var def = this.ATTRIBUTES[attr];
				if (def && def.notifyObservers) {
					var observers = this._parent._observers, observer;
					for (var key in observers) {
						observer = observers[key];
						if (observer.notifyObservers) {
                            if (dorado.Browser.msie && dorado.Browser.version < 9){
                                observer.notifyObservers();
                            } else {
                                dorado.Toolkits.setDelayedAction(observer, "$refreshDelayTimerId", observer.notifyObservers, 0);
                            }
						}
					}
				}
			}
		},

		doGet: function (attr) {
			var c = attr.charAt(0);
			if (c == '#' || c == '&') {
				var validatorName = attr.substring(1);
				return this.getValidator(validatorName);
			} else {
				return dorado.AttributeSupport.prototype.doGet.call(this, attr);
			}
		},
		
		getListenerScope: function() {
			return this.get("view");
		},

		fireEvent: function() {
			// 对于那些Ajax懒装载的DataType，其中view可能是空的
			var view = this.get("view"), oldView = window.view;
			window.view = view;
			try {
				return $invokeSuper.call(this, arguments);
			}
			finally {
				window.view = oldView;
			}
		},
		
		getDataType: function(loadMode) {
			return dorado.LazyLoadDataType.dataTypeGetter.call(this, loadMode);
		},
		
		/**
		 * 将给定的数值翻译成显示值。
		 * @param {String} key 要翻译的键值。
		 * @return {Object} 显示值。
		 * @see dorado.PropertyDef#attribute:mapping
		 */
		getMappedValue: function(key) {
			if (key == null) key = "${null}";
			else if (key === '') key = "${empty}";
			return this._mappingIndex ? this._mappingIndex[key + ''] : undefined;
		},
		
		/**
		 * 根据给定的显示值返回与其匹配的键值。
		 * @param {Object} value 要翻译的显示值。
		 * @return {String} 键值。
		 * @see dorado.PropertyDef#attribute:mapping
		 */
		getMappedKey: function(value) {
			if (!this._mappingRevIndex) {
				var index = this._mappingRevIndex = {}, mapping = this._mapping;
				for (var i = 0; i < mapping.length; i++) {
					var v = mapping[i].value;
					if (v == null) v = "${null}";
					else if (v === '') v = "${empty}";
					index[v + ''] = mapping[i].key;
				}
			}
			if (value == null) value = "${null}";
			else if (value === '') value = "${empty}";
			return this._mappingRevIndex[value + ''];
		},

		/**
		 * 根据名称返回对应的Validator。
		 * @param name 名称
		 * @returns dorado.Validator
		 */
		getValidator: function(name) {
			if (!this._validators) return null;
			for (var i = 0; i < this._validators.length; i++) {
				var validator = this._validators[i];
				if (validator._name == name) return validator;
			}
		}
	});
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 实体类型中的普通属性声明。
	 * @shortTypeName PropertyDef
	 * @extends dorado.PropertyDef
	 * @see dorado.EntityDataType
	 */
	dorado.BasePropertyDef = $extend(dorado.PropertyDef, /** @scope dorado.BasePropertyDef.prototype */ {
		$className: "dorado.BasePropertyDef",
		
		ATTRIBUTES: /** @scope dorado.BasePropertyDef.prototype */ {
			/**
			 * 是否键值属性。
			 * @type boolean
			 * @attribute
			 */
			key: {}
		}
	});
	
	dorado.ReferenceDataPipe = $extend(dorado.DataProviderPipe, {
		$className: "dorado.ReferenceDataPipe",
		shouldFireEvent: false,
		
		constructor: function(propertyDef, entity) {
			this.propertyDef = propertyDef;
			this.entity = entity;
			this.dataType = propertyDef._dataType;
			var parent = propertyDef.get("parent");
			this.dataTypeRepository = (parent ? parent.get("dataTypeRepository") : null) || $dataTypeRepository;
			this.view = this.dataTypeRepository ? this.dataTypeRepository._view : null;
		},
		
		getDataProviderArg: function() {
			var propertyDef = this.propertyDef;
			dorado.$this = this.entity;
			return {
				pageSize: propertyDef._pageSize,
				parameter: dorado.JSON.evaluate(propertyDef._parameter),
				sysParameter: propertyDef._sysParameter ? propertyDef._sysParameter.toJSON() : undefined,
				dataType: this.dataType,
				view: this.view
			};
		},
		
		getDataProvider: function() {
			return this.propertyDef._dataProvider;
		}
	});
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 实体类型中的数据关联属性。数据关联属性常常用来实现较大量数据的懒装载。
	 * @shortTypeName Refernce
	 * @extends dorado.PropertyDef
	 * @see dorado.EntityDataType
	 */
	dorado.Reference = $extend(dorado.PropertyDef, /** @scope dorado.Reference.prototype */ {
		$className: "dorado.Reference",
		
		ATTRIBUTES: /** @scope dorado.Reference.prototype */ {
		
			/**
			 * 用于为数据关联属性提供数据的数据提供者。
			 * @type dorado.DataProvider
			 * @attribute
			 */
			dataProvider: {},
			
			/**
			 * 提取数据时使用的参数。 即调用{@link dorado.DataProvider}时使用的参数。此处允许使用JSON数据模板。
			 * @type Object
			 * @attribute
			 * @see dorado.JSON
			 */
			parameter: {
				setter: function(parameter) {
					if (this._parameter instanceof dorado.util.Map && parameter instanceof dorado.util.Map) {
						this._parameter.put(parameter);
					} else {
						this._parameter = parameter;
					}
				}
			},
			
			/**
			 * 提取数据时使用的分页大小。即调用{@link dorado.DataProvider}时使用的分页大小。
			 * @type int
			 * @attribute
			 */
			pageSize: {},
			
			/**
			 * 对于新增的数据实体是否有效，及是否为新增的数据实体装载此属性中的子数据。
			 * @type boolean
			 * @attribute
			 */
			activeOnNewEntity: {}
		},
		
		EVENTS: /** @scope dorado.Reference.prototype */ {
			/**
			 * 当系统尝试为某数据实体的此属性装载数据之前触发的事件。
			 * @param {Object} self 事件的发起者，即本属性声明对象。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.Entity} arg.entity 当前处理的数据实体。
			 * @param {int} arg.pageNo 当前装载的页号。
			 * @param {Object} #arg.processDefault = true 用于通知系统是否要继续完成后续动作。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			beforeLoadData: {},
			
			/**
			 * 当系统为某数据实体的此属性装载数据之后触发的事件。
			 * @param {Object} self 事件的发起者，即本属性声明对象。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.Entity} arg.entity 当前处理的数据实体。
			 * @param {int} arg.pageNo 当前装载的页号。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onLoadData: {}
		},
		
		/**
		 * 获取为数据关联属性提供数据的数据管道。
		 * <p>
		 * 该数据管道事实上是对{@link dorado.DataProvider}的包装，目的是为了简化和统一数据获取的方法。
		 * </p>
		 * @param entity {dorado.Entity} 需要使用该数据管道的数据实体。
		 * @return {dorado.DataPipe} 数据管道。
		 */
		getDataPipe: function(entity) {
			if (this._dataProvider) {
				return new dorado.ReferenceDataPipe(this, entity);
			}
			else {
				return null;
			}
		}
	});
	
	dorado.Toolkits.registerPrototype("propertydef", {
		"Default": dorado.BasePropertyDef,
		"Reference": dorado.Reference
	});
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

var SHOULD_PROCESS_DEFAULT_VALUE = true;

(function() {
	var DEFAULT_VALIDATION_RESULT_STATE = "error";

	var STATE_CODE = dorado.Toolkits.STATE_CODE;
	var VALIDATION_RESULT_CODE = {
		ok : 0,
		invalid : 1,
		executing : 2
	};
	
	function addMessage2Context(context, entity, property, message) {
		var state = message.state || "error";
		context[state].push({
			entity : entity,
			property : property,
			state : message.state,
			text : message.text
		});
	}
	
	function addMessages2Context(context, entity, property, messages) {
		for (var i = 0; i < messages.length; i++) {
			addMessage2Context(context, entity, property, messages[i]);
		}
	}
	
	function mergeValidationContext(context, state, subContext) {
		var subContextMessages = subContext[state];
		if (!subContextMessages) return;
		for (var i = 0; i < subContextMessages.length; i++) {
			context[state].push(subContextMessages[i]);
		}
	}
	
	function mergeValidationContexts(context, subContext) {
		mergeValidationContext(context, "info", subContext);
		mergeValidationContext(context, "ok", subContext);
		mergeValidationContext(context, "warn", subContext);
		mergeValidationContext(context, "error", subContext);
		mergeValidationContext(context, "executing", subContext);
	}

	function doDefineProperty(proto, property) {
		var getter = function () {
			var value;
			if (this._textMode) {
				value = this._entity._data[property];
				if (value && typeof value == "object" && !(value instanceof Date)) {
					value = this._entity.get(property);
				}
				else {
					value = this._entity.getText(property);
				}
			}
			else {
				value = this._entity.get(property);
			}
			if (value instanceof dorado.Entity || value instanceof dorado.EntityList) {
				value = value.getWrapper(this._options);
			}
			return value;
		};
		var setter = function (value) {
			if (this._readOnly) {
				throw new dorado.Exception("Wrapper is readOnly.");
			}
			this._entity.set(property, value);
		};

		try {
			proto.__defineGetter__(property, getter);
			proto.__defineSetter__(property, setter);
		} catch (e) {
			Object.defineProperty(proto, property, {
				get: getter,
				set: setter
			});
		}
	}
	
	var STATE_NONE = 0;

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @name dorado.Entity
	 * @class 实体对象。
	 *        <p>
	 *        在创建一个实体对象时，我们既可以为其指定实体数据类型，也可以不指定。<br>
	 *        如果指定了实体数据类型，那么访问该实体对象的属性，这些属性必须存在于{@link dorado.EntityDataType}的{@link dorado.PropertyDef}中。<br>
	 *        如果为指定实体数据类型，就可以随意的访问实体对象中的任意属性。
	 *        </p>
	 *        <p>
	 *        为实体对象指定实体数据类型的方法有两种:<br>
	 *        一是利用构造方法中的dataType参数直接指定，此时dorado.Entity的三个构造参数中只有dataType是必须指定的。<br>
	 *        二是利用被封装的JSON对象中的$dataType属性，此时dorado.Entity的三个构造参数中的data和dataTypeRepository是必须指定的。
	 *        例如以下的JSON对象说明其对应的数据类型应为"Employee"。
	 * 
	 * <pre class="symbol-example code">
	 * <code class="javascript">
	 * {
	 * 	$dataType : &quot;Employee&quot;,
	 * 	id : &quot;0001&quot;,
	 * 	name : &quot;John&quot;,
	 * 	sex : true
	 * }
	 * </code>
	 * </pre>
	 * 
	 * </p>
	 *        <p>
	 *        注意：一旦我们将某个JSON数据对象封装为实体对象，那么这个JSON数据对象将将会被实际对象完全接管。
	 *        实体对象会根据自己的需要修改其中的属性、甚至增加属性。因此该JSON数据对象的有效性和完整性将不再得到保障。
	 *        </p>
	 * @param {Object}
	 *            [data] 要封装JSON数据对象。
	 * @param {dorado.DataTypeRepository}
	 *            [dataTypeRepository] 数据类型的管理器。
	 * @param {dorado.EntityDataType}
	 *            [dataType] 实体对象的数据类型。
	 * 
	 * @example // 创建一个空的实体对象，由于未指定实体数据类型，我们可以随意的访问实体对象中的任意属性。 var entity = new
	 *          dorado.Entity(); entity.set("property1, "value1");
	 * 
	 * @example // 将一个JSON对象封装为实体对象，同时利用$dataType指定实体数据类型。 var employee = {
	 *          $dataType : "Employee", id : "0001", name : "John", sex : true };
	 *          var entity = new dorado.Entity(employee,
	 *          view.dataTypeRepository); entity.get("name"); //
	 *          只能访问Employee类型中存在属性。
	 * 
	 * @example var employee = { id : "0001", name : "John", sex : true };
	 * 
	 * var Employee = new EntityDataType("Employee");
	 * Employee.addPropertyDef(new PropertyDef("id"));
	 * Employee.addPropertyDef(new PropertyDef("name"));
	 * Employee.addPropertyDef(new PropertyDef("sex"));
	 *  // 将一个JSON对象封装为实体对象，同时利用dataType参数指定实体数据类型。 var entity = new
	 * dorado.Entity(employee, null, Employee); entity.get("name"); //
	 * 只能访问Employee类型中存在属性。
	 *  // 创建一个空的、类型为Employee的实体对象。 var entity = new dorado.Entity(null, null,
	 * Employee); entity.set("name", "Mike"); // 只能访问Employee类型中存在属性。
	 */
	dorado.Entity = $class(/** @scope dorado.Entity.prototype */ {
		$className : "dorado.Entity",

		/**
		 * @name dorado.Entity#dataProvider
		 * @property
		 * @type dorado.DataProvider
		 * @description 获取为实体对象提供数据的数据提供者。
		 */
		/**
		 * @name dorado.Entity#parameter
		 * @property
		 * @type Object
		 * @description 装载数据使用的附加参数。
		 */
		// =====

		constructor : function(data, dataTypeRepository, dataType) {

			/**
			 * 实体对象的id。
			 * 
			 * @type long
			 */
			this.entityId = dorado.Core.getTimestamp() + '';

			/**
			 * 实体对象的时间戳。
			 * <p>
			 * 每当实体对象中的数据或状态发生了改变，实体对象都会更新自己的时间戳，
			 * 因此，时间戳可以可以用来判断实体对象中的数据或状态在一段时间内有没有被修改过。
			 * </p>
			 * 
			 * @type int
			 */
			this.timestamp = dorado.Core.getTimestamp();
			
			if (dataTypeRepository instanceof dorado.DataType) {
				dataType = dataTypeRepository;
				dataTypeRepository = null;
			}

			/**
			 * 该实体对象中的数据类型所属的数据类型管理器。
			 * 
			 * @type dorad.DataRepository
			 */
			this.dataTypeRepository = dataTypeRepository;
			
			this._propertyInfoMap = {};
			if (data) {
				this._data = data;
				if (dataType == null) {
					if (dataTypeRepository && data.$dataType) dataType = dataTypeRepository.get(data.$dataType);
				} else {
					data.$dataType = dataType._id;
				}
				if (data.$state) this.state = data.$state;
			} else {
				this._data = data = {};
				if (dataType) this._data.$dataType = dataType._id;
			}

			/**
			 * 该实体对象对应的实体数据类型。
			 * 
			 * @type dorado.EntityDataType
			 */
			this.dataType = dataType;

			if (dataType) {
				this._propertyDefs = dataType._propertyDefs;
				var pdItems = this._propertyDefs.items;
				for (var i = 0, len = pdItems.length; i < len; i++) {
					var pd = pdItems[i];
					if (SHOULD_PROCESS_DEFAULT_VALUE && pd._defaultValue != undefined && data[pd._name] == undefined) {
						data[pd._name] = (typeof pd._defaultValue == "function") ? pd._defaultValue.call(this) : pd._defaultValue;
					}

					if (data[pd._name] == null) {
						var dataType = pd.get("dataType");
						if (dataType) {
							switch (dataType._code) {
								case dorado.DataType.PRIMITIVE_INT:
								case dorado.DataType.PRIMITIVE_FLOAT:
									data[pd._name] = 0;
									break;
								case dorado.DataType.PRIMITIVE_BOOLEAN:
									data[pd._name] = false;
									break;
							}
						}
					}
				}
			} else {
				this._propertyDefs = null;
			}
			if (this.acceptUnknownProperty == null) {
				this.acceptUnknownProperty = (dataType) ? dataType._acceptUnknownProperty : true;
			}
		},

		/**
		 * 实体对象的状态。
		 * 
		 * @type int
		 * @default dorado.Entity.STATE_NONE
		 */
		state : STATE_NONE,

		_observer : null,
		_disableObserversCounter : 0,
		_messages : null,

		_setObserver: function(observer) {
			if (this._observer && this.dataType) this.dataType._removeObserver(this._observer);
			
			this._observer = observer;
			
			if (this.dataType && observer) this.dataType._addObserver(observer);
			
			var data = this._data;
			for(p in data) {
				if (data.hasOwnProperty(p)) {
					var v = data[p];
					if (v == null) continue;
					if ( v instanceof dorado.Entity || v instanceof dorado.EntityList) {
						v._setObserver(observer);
					}
				}
			}
		},
		
		/**
		 * 禁止dorado.Entity将消息发送给其观察者。
		 * <p>
		 * 该方法的主要作用是阻止与该实体对象关联的数据控件自动根据实体对象的变化刷新自身的显示内容，
		 * 这样做的目的一般是为了提高对实体对象连续进行操作时的运行效率。
		 * </p>
		 */
		disableObservers: function() {
			this._disableObserversCounter++;
		},
		
		/**
		 * 允许dorado.Entity将消息发送给其观察者。
		 */
		enableObservers: function() {
			if (this._disableObserversCounter > 0) this._disableObserversCounter--;
		},
		
		/**
		 * 通知dorado.Entity的观察者刷新数据。
		 */
		notifyObservers: function() {
			this.sendMessage(0);
		},
		
		sendMessage: function(messageCode, arg) {
			if (this._disableObserversCounter == 0 && this._observer) {
				this._observer.entityMessageReceived(messageCode, arg);
			}
		},
		
		/**
		 * 设置实体对象的状态。
		 * 
		 * @param {int}
		 *            state 状态。
		 */
		setState: function(state) {
			if (this.state == state) return;

			var eventArg = {
				entity : this,
				oldState : this.state,
				newState : state,
				processDefault : true
			};

			var dataType = this.dataType;
			if (dataType && !this.disableEvents)
				dataType.fireEvent("beforeStateChange", dataType, eventArg);
			if (!eventArg.processDefault) return;

			if (this.state == dorado.Entity.STATE_NONE && (state == dorado.Entity.STATE_MODIFIED || state == dorado.Entity.STATE_MOVED)) {
				this.storeOldData();
			}

			this.state = state;
			this.timestamp = dorado.Core.getTimestamp();
			
			var entityList = this.parent;
			if (entityList && entityList instanceof dorado.EntityList) {
				var page = this.page;
				if (eventArg.oldState == dorado.Entity.STATE_DELETED) {
					entityList.changeEntityCount(page, 1);
				}
				else if (eventArg.newState == dorado.Entity.STATE_DELETED) {
					entityList.changeEntityCount(page, -1);
				}
			}

			if (dataType && !this.disableEvents) dataType.fireEvent("onStateChange", dataType, eventArg);
			this.sendMessage(dorado.Entity._MESSAGE_ENTITY_STATE_CHANGED, eventArg);
		},
		
		_get: function(property, propertyDef, callback, loadMode) {
			
			function transferAndReplaceIf(entity, propertyDef, value, replaceValue) {
				if (value && typeof (value instanceof dorado.Entity || value instanceof dorado.EntityList) && value.parent == entity) return value;
				
				var dataType = (propertyDef) ? propertyDef.get("dataType") : null;
				if (dataType == null && !entity.alwaysTransferEntity) return value;

				var originValue = value; 
				if (dataType) {
					value = dataType.parse(originValue, (propertyDef) ? propertyDef.get("typeFormat") : null);
				}
				else if (value) {
					value = dorado.DataTypeRepository.ROOT.get((value instanceof Array) ? "[Entity]" : "Entity").parse(value, true);
				}

				if ((value instanceof dorado.Entity || value instanceof dorado.EntityList) && value.parent != entity) {
					value.parent = entity;
					value.timestamp = dorado.Core.getTimestamp();
					value.parentProperty = property;
					value._setObserver(entity._observer);
				}
				else {
					replaceValue = false;
				}

				if (replaceValue) {
					var oldValue = entity._data[property];
					if (oldValue !== value)  {
						if (oldValue && oldValue.isDataPipeWrapper) {
							oldValue = oldValue.value;
						}
						if (oldValue instanceof dorado.Entity || oldValue instanceof dorado.EntityList) {
							oldValue.parent = null;
							oldValue.timestamp = dorado.Core.getTimestamp();
							oldValue._setObserver(null);
						}

						entity._data[property] = value;
					}
					
					var eventArg = {};
					if (value instanceof dorado.Entity) {
						eventArg.entity = value;
						if (dataType) dataType.fireEvent("onEntityLoad", dataType, eventArg);
					}
					else if (dataType && value instanceof dorado.EntityList) {
						var elementDataType = dataType.get("elementDataType");
						if (elementDataType) {
							for (var it = value.iterator(); it.hasNext();) {
								eventArg.entity = it.next();
								elementDataType.fireEvent("onEntityLoad", dataType, eventArg);
							}
						}
					}
				}
				return value;
			}
			
			var value = this._data[property], invokeCallback = true;
			if (value === undefined) {
				if (propertyDef) {
					var dataPipeWrapper = null;
					if (loadMode != "never" && propertyDef.getDataPipe) {
						var pipe;
						if (propertyDef instanceof dorado.Reference) {
							if (this.state != dorado.Entity.STATE_NEW || propertyDef._activeOnNewEntity) {
								pipe = propertyDef.getDataPipe(this);
							}
						} else {
							pipe = propertyDef.getDataPipe(this);
						}
						if (pipe) {
							var eventArg = {
								entity : this,
								property: property,
								pageNo: 1
							};
							propertyDef.fireEvent("beforeLoadData", propertyDef, eventArg);
							if (eventArg.processDefault === false) {
								if (callback) $callback(callback, false);
								return;
							}

							if (callback || loadMode == "auto") {
								var isNewPipe = (pipe.runningProcNum == 0);
								pipe.getAsync({
									scope : this,
									callback: function(success, result) {
										var dummyData = this._data[property], dummyValue;
										if (dummyData.isDataPipeWrapper) {
											dummyValue = dummyData.value;
										}
										this._data[property] = dummyValue || null;

										if (isNewPipe) {
											this.sendMessage(dorado.Entity._MESSAGE_LOADING_END, eventArg);
										}
												
										if (success) {
											eventArg.data = result;

											if (isNewPipe) {
												if (result === null &&
													(dummyValue instanceof dorado.EntityList || dummyValue instanceof dorado.Entity) &&
													dummyValue.isNull) {
													if (dummyData.isDataPipeWrapper) {
														result =  this._data[property];
													}
												}
												else {
													result = transferAndReplaceIf(this, propertyDef, result, true);
												}

												propertyDef.fireEvent("onLoadData", propertyDef, eventArg);
											}

											this.sendMessage(dorado.Entity._MESSAGE_DATA_CHANGED, {
												entity: this,
												property: property,
												newValue: result
											});

											if (propertyDef.getListenerCount("onGet")) {
												eventArg = {
													entity : this,
													value : result
												};
												propertyDef.fireEvent("onGet", propertyDef, eventArg);
												result = eventArg.value;
											}
										}
										else if (isNewPipe) {
											this._data[property] = null;
										}
										if (callback) $callback(callback, success, result);
									}
								});
								
								this._data[property] = dataPipeWrapper = {
									isDataPipeWrapper : true,
									pipe : pipe
								};	
								if (isNewPipe) this.sendMessage(dorado.Entity._MESSAGE_LOADING_START, eventArg);
								invokeCallback = false;
							} else {
								value = pipe.get();
								value = transferAndReplaceIf(this, propertyDef, value, true);

								eventArg.data = value;
								propertyDef.fireEvent("onLoadData", propertyDef, eventArg);
							}
						}
					}

					if ((value === undefined || value === null) && dorado.Entity.ALWAYS_RETURN_VALID_ENTITY_LIST) {
						var pdt = propertyDef.get("dataType");
						if (pdt instanceof dorado.AggregationDataType) {
							value = transferAndReplaceIf(this, propertyDef, [], false);
							value.isNull = true;;
							
							if (dataPipeWrapper) {
								dataPipeWrapper.value = value;
							} else if (loadMode != "never") {
								this._data[property] = value;
							}
						}
					}
				}
			} else if (value != null && value.isDataPipeWrapper) {
				var pipe = value.pipe;
				if (loadMode != "never") {
					if (loadMode == "auto" || callback) {
						pipe.getAsync(callback);
						value = undefined;
						invokeCallback = false;
					} else {
						var shouldAbortAsyncProcedures = dorado.Setting["common.abortAsyncLoadingOnSyncLoading"];
						if (pipe.runningProcNum > 0 && !shouldAbortAsyncProcedures) {
							throw new dorado.ResourceException("dorado.data.GetDataDuringLoading", "Entity");
						}
						
						try {
							value = pipe.get();
							pipe.abort(true, value);
						} 
						catch (e) {
							pipe.abort(false, e);
							throw e;
						}
					}
				}
			} else if (value === null && propertyDef) {
				if (dorado.Entity.ALWAYS_RETURN_VALID_ENTITY_LIST) {
					var aggregationDataType = propertyDef.get("dataType");
					if (aggregationDataType instanceof dorado.AggregationDataType) {
						value = transferAndReplaceIf(this, propertyDef, [], false);
						value.isNull = true;
						this._data[property] = value;
					}
				}
			} else if ((value instanceof Object || value instanceof Array) && !(value instanceof Date)) {
				value = transferAndReplaceIf(this, propertyDef, value, true);
			}

			if (propertyDef && propertyDef.getListenerCount("onGet")) {
				eventArg = {
					entity : this,
					value : value
				};
				propertyDef.fireEvent("onGet", propertyDef, eventArg);
				value = eventArg.value;
			}
			if (invokeCallback && callback) $callback(callback, true, value);
			return value;
		},
		
		/**
		 * 根据名称返回某属性对应的PropertyDef。
		 * 
		 * @param {String}
		 *            property
		 * @return {dorado.PropertyDef} 得到的属性值。
		 */
		getPropertyDef: function(property) {
			var propertyDef = null;
			if (this._propertyDefs) {
				propertyDef = this._propertyDefs.get(property);
				if (!propertyDef && !this.acceptUnknownProperty) {
					throw new dorado.ResourceException("dorado.data.UnknownProperty", property);
				}
			}
			return propertyDef;
		},
		
		/**
		 * 获取属性值。
		 * <p>
		 * 此方法还支持迭代式的属性读取，及通过"."来分割一组属性名，交由此方法一层层向下挖掘并返回最终结果。<br>
		 * 当进行迭代式的读取时，系统会自动判断前一个属性返回的对象是dorado.Entity的派生类还是普通JSON对象，并藉此决定如何进一步执行读取操作。
		 * </p>
		 * 
		 * @param {String}
		 *            property 要获取的属性名。
		 * @param {String}
		 *            [loadMode="always"] 数据装载模式。<br>
		 *            包含下列三种取值:
		 *            <ul>
		 *            <li>always - 如果有需要总是装载尚未装载的延时数据。</li>
		 *            <li>auto - 如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 *            <li>never - 不会激活数据装载过程，直接返回数据的当前值。</li>
		 *            </ul>
		 * @return {Object} 得到的属性值。
		 */
		get: function(property, loadMode) {
			loadMode = loadMode || "always";
			var result;
			if (this.ignorePropertyPath) {
				var propertyDef = this.getPropertyDef(property);
				result = this._get(property, propertyDef, null, loadMode);
			} else {
				var properties = property.split('.'), len = properties.length;
				for (var i = 0; i < len; i++) {
					property = properties[i];
					if (i == 0) {
						var propertyDef = this.getPropertyDef(property);
						result = this._get(property, propertyDef, null, loadMode);
					} else {
						if (!result) break;
						result = (result instanceof dorado.Entity) ? result.get(property) : result[property];
					}
					
					if (i < len - 1) {
						if (result instanceof dorado.EntityList) {
							result = result.current;
						}
						else if (result instanceof Array) {
							result = result[0];
						}
					}
				}
			}
			return result;
		},
		
		/**
		 * 以异步操作的方式获取属性值。
		 * <p>
		 * 此方法还支持迭代式的属性读取，及通过"."来分割一组属性名，交由此方法一层层向下挖掘并返回最终结果。<br>
		 * 当进行迭代式的读取时，系统会自动判断前一个属性返回的对象是dorado.Entity的派生类还是普通JSON对象，并藉此决定如何进一步执行读取操作。
		 * </p>
		 * 
		 * @param {String}
		 *            property 要获取的属性名。
		 * @param {Function|dorado.Callback}
		 *            callback 回调对象，传入回调对象的参数即为得到的属性值。
		 * @param {String}
		 *            [loadMode="always"] 数据装载模式。<br>
		 *            包含下列三种取值:
		 *            <ul>
		 *            <li>always - 如果有需要总是装载尚未装载的延时数据。</li>
		 *            <li>auto - 对于异步操作而言此选项没有实际意义，系统内部的处理方法将与always完全一致。</li>
		 *            <li>never - 不会激活数据装载过程，直接返回数据的当前值。</li>
		 *            </ul>
		 */
		getAsync: function(property, callback, loadMode) {

			function _getAsync(entity, property, callback, loadMode) {
				var i = property.indexOf('.');
				if (i > 0 && !entity.ignorePropertyPath) {
					var p1 = property.substring(0, i);
					var p2 = property.substring(i + 1);
					if ( entity instanceof dorado.Entity) {
						entity.getAsync(p1, {
							callback: function(success, result) {
								if (success && result && ( result instanceof Object)) {
									_getAsync(result, p2, callback, loadMode);
								} else {
									$callback(callback, success, result);
								}
							}
						}, loadMode);
					} else {
						var subEntity = entity[p1];
						if (subEntity && ( subEntity instanceof Object)) {
							_getAsync(subEntity, p2, callback, loadMode);
						}
					}
				} else {
					if ( entity instanceof dorado.Entity) {
						entity._get(property, entity.getPropertyDef(property), callback, loadMode);
					} else {
						var result = entity[property];
						$callback(callback, true, result);
					}
				}
			}

			loadMode = loadMode || "always";
			_getAsync(this, property, callback || dorado._NULL_FUNCTION, loadMode);
		},
		
		doGetText: function(property, callback, loadMode) {
			function toText(value, propertyDef) {
				var text;
				if (propertyDef) {
					var dataType = propertyDef.get("dataType");
					text = (dataType || dorado.$String).toText(value, propertyDef._displayFormat);
					if (text && propertyDef._mapping)
						text = propertyDef.getMappedValue(text) || "";
				} else {
					text = dorado.$String.toText(value);
				}
				return text;
			}

			var propertyDef = this.getPropertyDef(property);
			if (callback) {
				var entity = this;
				this._get(property, propertyDef, function(value) {
					var text = toText(value, propertyDef);
					if (propertyDef && propertyDef.getListenerCount("onGetText")) {
						eventArg = {
							entity : entity,
							text : text
						};
						propertyDef.fireEvent("onGetText", propertyDef, eventArg);
						text = eventArg.text;
					}
					$callback(callback, true, text);
				}, loadMode);
			} else {
				var value = this._get(property, propertyDef, null, loadMode);
				var text = toText(value, propertyDef);
				if (propertyDef && propertyDef.getListenerCount("onGetText")) {
					eventArg = {
						entity : this,
						text : text
					};
					propertyDef.fireEvent("onGetText", propertyDef, eventArg);
					text = eventArg.text;
				}
				return text;
			}
		},
		
		/**
		 * 获取属性的文本值。
		 * <p>
		 * 该值可用于界面显示，例如：对于一个日期类型属性，是此方法可以得到经格式化处理之后的日期字符串。 具体的格式化方式由相应{@link dorado.PropertyDef}中的displayFormat属性决定。
		 * </p>
		 * 
		 * @param {String}
		 *            property 要获取的属性名。
		 * @param {String}
		 *            [loadMode="always"] 数据装载模式。<br>
		 *            包含下列三种取值:
		 *            <ul>
		 *            <li>always - 如果有需要总是装载尚未装载的延时数据。</li>
		 *            <li>auto - 如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 *            <li>never - 不会激活数据装载过程，直接返回数据的当前值。</li>
		 *            </ul>
		 * @return {String} 属性的文本值。
		 */
		getText: function(property, loadMode) {
			loadMode = loadMode || "always";
			var result;
			if (this.ignorePropertyPath) {
				result = this.doGetText(property, null, loadMode);
			} else {
				var properties = property.split('.'), result = this;
				for (var i = 0; i < properties.length; i++) {
					property = properties[i];
					if (i == (properties.length - 1)) {
						result = result.doGetText(property, null, loadMode);
					} else {
						result = (result instanceof dorado.Entity) ? result.get(property) : result[property];
					}
					if (result == null) break;
				}
			}
			return result;
		},
		
		/**
		 * 以异步方式获取属性的文本值。
		 * 
		 * @param {String}
		 *            property 要获取的属性名。
		 * @param {Function|dorado.Callback}
		 *            callback 回调对象，传入回调对象的参数即为得到的属性的文本值。
		 * @param {String}
		 *            [loadMode="always"] 数据装载模式。<br>
		 *            包含下列三种取值:
		 *            <ul>
		 *            <li>always - 如果有需要总是装载尚未装载的延时数据。</li>
		 *            <li>auto - 对于异步操作而言此选项没有实际意义，系统内部的处理方法将与always完全一致。</li>
		 *            <li>never - 不会激活数据装载过程，直接返回数据的当前值。</li>
		 *            </ul>
		 * @see dorado.Entity#getText
		 */
		getTextAsync: function(property, callback, loadMode) {

			function _getTextAsync(entity, property, callback, loadMode) {
				var i = property.indexOf('.');
				if (i > 0 && !entity.ignorePropertyPath) {
					var p1 = property.substring(0, i);
					var p2 = property.substring(i + 1);
					if ( entity instanceof dorado.Entity) {
						entity.getAsync(p1, {
							callback: function(success, result) {
								if (success && result && ( result instanceof Object)) {
                                    _getTextAsync(result, p2, callback, loadMode);
								} else {
									$callback(callback, success, result);
								}
							}
						}, loadMode);
					} else {
						var subEntity = entity[p1];
						if (subEntity && ( subEntity instanceof Object)) {
							_getTextAsync(subEntity, p2, callback, loadMode);
						}
					}
				} else {
					if ( entity instanceof dorado.Entity) {
						entity.doGetText(property, callback, loadMode);
					} else {
						var result = entity[property];
						$callback(callback, true, result);
					}
				}
			}

			loadMode = loadMode || "always";
			_getTextAsync(this, property, callback || dorado._NULL_FUNCTION, loadMode);
		},
		
		storeOldData: function() {
			if (this._oldData) return;
			var data = this._data, oldData = this._oldData = {};
			for(var p in data) {
				if (data.hasOwnProperty(p)) {
					var value = data[p];
					if (value != null && value.isDataPipeWrapper) continue;
					oldData[p] = value;
				}
			}
		},
		
		_validateProperty: function(dataType, propertyDef, propertyInfo, value, preformAsyncValidator) {
			var messages = [], property = propertyDef._name, validating, propertyDataType = propertyDef.get("dataType");
			if (propertyDef._required && !dataType._validatorsDisabled) {
				var hasRequiredValidator = false;
				if (propertyDef._validators) {
					for (var i = 0; i < propertyDef._validators.length; i++) {
						if (propertyDef._validators[i] instanceof dorado.validator.RequiredValidator) {
							hasRequiredValidator = true;
							break;
						}
					}
				}
				
				if (!hasRequiredValidator) {
					var v = value;
					if (typeof value == "string") v = jQuery.trim(v);
					var blank = false;				
					if (v === undefined || v === null || v === "") {
						if (propertyDataType && propertyDataType._code == dorado.DataType.STRING) {
							blank = !v;
						}
						else {
							blank = true;
						}
					}
					else if (v instanceof dorado.EntityList && propertyDataType instanceof dorado.AggregationDataType) {
						blank = !v.entityCount;
					}
					
					if (blank) {
						messages.push({
							state: "error",
							text: $resource("dorado.data.ErrorContentRequired")
						});
					}
				}
			}

			if (propertyDef._mapping && value !== undefined && value !== null && value !== "") {
				var mappedValue = propertyDef.getMappedValue(value);
				if (!propertyDef._acceptUnknownMapKey && mappedValue === undefined) {
					messages.push({
						state: "error",
						text: $resource("dorado.data.UnknownMapKey", value)
					});
				}
			}
			
			if (propertyDef._validators && !dataType._validatorsDisabled) {
				var entity = this, currentValue = value, validateArg = {
					property: property,
					entity: entity
				}, oldData = this._oldData;
				
				var valueForValidator = entity.get(property, "never");
				propertyInfo.validating = propertyInfo.validating || 0;
				for (var i = 0; i < propertyDef._validators.length; i++) {
					var validator = propertyDef._validators[i];
					if (!validator._revalidateOldValue && oldData && currentValue == oldData[property]) {
						continue;
					}
					
					if (validator instanceof dorado.validator.RemoteValidator && validator._async && preformAsyncValidator) {
						propertyInfo.validating++;
						validator.validate(valueForValidator, validateArg, {
							callback: function(success, result) {
								if (propertyInfo.validating <= 0) return;
								
								propertyInfo.validating--;
								if (propertyInfo.validating <= 0) {
									propertyInfo.validating = 0;
									propertyInfo.validated = true;
								}
								
								if (success) {
									if (entity._data[property] != currentValue) return;
									
									var originMessages = propertyInfo.messages;
									var messages = dorado.Toolkits.trimMessages(result, DEFAULT_VALIDATION_RESULT_STATE);
									if (originMessages) {
										messages = originMessages.concat(messages);
									}
									entity.doSetMessages(property, messages);
								}
								
								if (entity._data[property] == currentValue) {
									entity.sendMessage(dorado.Entity._MESSAGE_DATA_CHANGED, {
										entity: entity,
										property: property
									});
								}
							}
						});
					} else {
						var msgs = validator.validate(valueForValidator, validateArg);
						if (msgs) {
							messages = messages.concat(msgs);
							var state = dorado.Toolkits.getTopMessageState(msgs);
							var acceptState = dataType.get("acceptValidationState");
							if (STATE_CODE[state || "info"] > STATE_CODE[acceptState || "ok"]) {
								asyncValidateActions = [];
								break;
							}
						}
					}
				}
			}
			
			this.doSetMessages(property, messages);
			
			if (!propertyInfo.validating) {
				propertyInfo.validated = true;
			}
			return messages;
		},
		
		_set: function(property, value, propertyDef) {	
			var oldValue = this._data[property];
			if (oldValue && oldValue instanceof dorado.Entity && value && !(value instanceof dorado.Entity) && typeof value == "object") {
				oldValue.set(value);
				return;
			}
			
			var eventArg = {
				entity : this,
				property : property,
				oldValue : oldValue,
				newValue : value,
				processDefault : true
			};

			var dataType = this.dataType;
			if (dataType && !this.disableEvents && dataType.getListenerCount("beforeDataChange")) {
				dataType.fireEvent("beforeDataChange", dataType, eventArg);
				value = eventArg.newValue;
			}
			if (!eventArg.processDefault) return;

			// 保存原始值
			if (this.state == dorado.Entity.STATE_NONE) this.storeOldData();

			if (oldValue && oldValue.isDataPipeWrapper) oldValue = oldValue.value;
			if (oldValue instanceof dorado.Entity || oldValue instanceof dorado.EntityList) {
				oldValue.parent = null;
				oldValue.timestamp = dorado.Core.getTimestamp();
				oldValue._setObserver(null);
			}

			var propertyInfoMap = this._propertyInfoMap, propertyInfo = propertyInfoMap[property];
			if (!propertyInfo) propertyInfoMap[property] = propertyInfo = {};

			if (value instanceof dorado.Entity || value instanceof dorado.EntityList) {
				if (value.parent != null) {
					throw new dorado.ResourceException("dorado.data.ValueNotFree", (( value instanceof dorado.Entity) ? "Entity" : "EntityList"));
				}
				value.parent = this;
				value.timestamp = dorado.Core.getTimestamp();
				value.parentProperty = property;
				value._setObserver(this._observer);

				propertyInfo.isDirty = true;
			} else {
				var ov = this._oldData ? this._oldData[property] : oldValue;
				propertyInfo.isDirty = (ov != value);
				
				if (value && typeof value == "object" && value.$state === undefined && propertyDef && propertyDef.get("dataType") instanceof dorado.EntityDataType) {
					value = dorado.Object.apply({
						$state: dorado.Entity.STATE_NEW
					}, value);
				}
			}

			eventArg.value = value;
			if (propertyDef && propertyDef.getListenerCount("onSet")) {
				propertyDef.fireEvent("onSet", propertyDef, eventArg);
				value = eventArg.value;
			}

			this._data[property] = value;
			this.timestamp = dorado.Core.getTimestamp();

			if (property.charAt(0) != '$') {
				var messages;
				if (propertyDef) {
					messages = this._validateProperty(dataType, propertyDef, propertyInfo, value, true);
				}
				else {
					messages = null;
				}

				if (!(messages && messages.length) && !propertyInfo.validating) {
					messages = [{
						state : "ok"
					}];
				}
				this.doSetMessages(property, messages);				

				if (this.state == dorado.Entity.STATE_NONE) {
					this.setState(dorado.Entity.STATE_MODIFIED);
				}
			}

			if (dataType && !this.disableEvents && dataType.getListenerCount("onDataChange")) {
				dataType.fireEvent("onDataChange", dataType, eventArg);
			}
			this.sendMessage(dorado.Entity._MESSAGE_DATA_CHANGED, eventArg);
		},
		
		_dispatchOperationToSubEntity: function(property, create, method, args) {
			var i = property.indexOf('.');
			var property1 = property.substring(0, i), property2 = property.substring(i + 1);
			var subEntity = this.get(property1);
			if (subEntity == null && create) subEntity = this.createChild(property1);
			if (subEntity != null) {
				if (subEntity instanceof dorado.EntityList) subEntity = subEntity.current;
				return subEntity[method].apply(subEntity, [property2].concat(args));
			}
		},
		
		/**
		 * 设置属性值。
		 * 
		 * @param {String}
		 *            property 此参数具有下列两种设置方式：
		 *            <ul>
		 *            <li>当property为String时，系统会将property的作为要设置属性名处理。属性值为value参数代表的值。</li>
		 *            <li>
		 *            当property为Object时，系统会将忽略value参数。此时，可以通过attr参数的JSON对象定义一组要设置的属性值。
		 *            <p>
		 *            在此种使用方法中，有一种情况需要注意。见下面的这种代码：
		 * 
		 * <pre class="symbol-example code">
		 * 	<code class="javascript">
		 * employee.set({
		 * 	name : &quot;John&quot;,
		 * 	contact : {
		 * 		mobile : &quot;253466-436&quot;,
		 * 		msn : &quot;asgee@xmail.com&quot;
		 * 	}
		 * });
		 * </code>
		 * 	</pre>
		 * 
		 * <ul>
		 *            <li>
		 *            如果当前employee的contact属性为null，那么Dorado会自动添加一个新的Contact实体，并设置好其中的mobile和msn这两个子属性的值。
		 *            完成后，子Contact对象的状态将是NEW。 </li>
		 *            <li>
		 *            如果当前employee的contact属性不为null，那么Dorado会直接修改这个已存在的Contact实体的mobile和msn这两个子属性的值。
		 *            完成后，子Contact对象的状态将是MODIFIED或NEW。 </li>
		 *            </ul>
		 *            </p>
		 *            </li>
		 *            </ul>
		 * @param {Object}
		 *            value 要设置的属性值。
		 * @return
		 */
		set: function(property, value) {
			
			function doSet(entity, property, value) {
				if (!entity.ignorePropertyPath && property.indexOf('.') > 0) {
					entity._dispatchOperationToSubEntity(property, true, "set", [value]);
				} else {
					var propertyDef = entity.getPropertyDef(property);
					if (propertyDef) {
						var dataType = propertyDef.get("dataType");
						if (dataType) {
							value = dataType.parse(value, propertyDef._typeFormat);
						}
					}
					entity._set(property, value, propertyDef);
				}
			}
			
			if (property.constructor != String) {
				this.disableObservers();
				try {
					for (var p in property) {
						if (property.hasOwnProperty(p)) {
							doSet(this, p, property[p]);
						}
					}
				}
				finally {
					this.enableObservers();
					this.sendMessage(dorado.Entity._MESSAGE_REFRESH_ENTITY, {
						entity: this
					});
				}
			}
			else {
				doSet(this, property, value);
			}
			return this;
		},
		
		/**
		 * 以文本方式设置属性的值。
		 * <p>
		 * 此处的文本值是指用于界面显示的文本，例如：对于一个日期类型属性，通过此方法设置时应传入与displayFormat属性匹配的日期格式文本。
		 * </p>
		 * 
		 * @param {String}
		 *            property 要设置的属性名。
		 * @param {String}
		 *            text 要设置的属性值。
		 */
		setText: function(property, text) {
			if (!this.ignorePropertyPath && property.indexOf('.') > 0) {
				this._dispatchOperationToSubEntity(property, true, "setText", [text]);
			} else {
				var propertyDef = this.getPropertyDef(property), value = text;
				if (propertyDef) {
					if (propertyDef._mapping && text != null) {
						value = propertyDef.getMappedKey(text);
						if (value === undefined) value = text;
					}
					var dataType = propertyDef.get("dataType");
					if (dataType) value = dataType.parse(value, propertyDef._displayFormat);
				}
				this._set(property, value, propertyDef);
			}
		},
		
		/**
		 * 取消对当前数据实体的各种数据操作。
		 * <ul>
		 * <li>如果此数据实体的状态是dorado.Entity.STATE_NEW，那么此操作将会删除此数据实体。</li>
		 * <li>如果此数据实体的状态是dorado.Entity.STATE_MODIFIED，那么此操作将会还原数据实体中的数据，并重置状态。</li>
		 * <li>如果此数据实体的状态是dorado.Entity.STATE_DELETE，那么此操作将会还原数据实体，并重置状态。</li>
		 * <li>如果此数据实体的状态是dorado.Entity.STATE_NONE，那么什么都不会发生。</li>
		 * <li>如果此数据实体的状态是dorado.Entity.STATE_MOVED，那么此操作将会还原数据实体，但不会重置状态。</li>
		 * </ul>
		 * 
		 * @param {boolean}
		 *            deep 是否执行深度撤销。即一并撤销所有子实体（包括子实体中的子实体）的修改。
		 */
		cancel: function(deep) {
			
			function deepCancel(entity) {
				var data = entity._data;
				for(var p in data) {
					if (data.hasOwnProperty(p)) {
						var value = data[p];
						if (value && (value instanceof dorado.Entity || value instanceof dorado.EntityList)) {
							value.cancel(true);
						}
					}
				}
			}
			
			if (this.state == dorado.Entity.STATE_NEW && this.parent && this.parent instanceof dorado.EntityList) {
				this.remove();
			} else if (this.state != dorado.Entity.STATE_NONE) {
				var data = this._data, oldData = this._oldData;
				if (oldData) {
					for (var p in data) {
						if (data.hasOwnProperty(p)) {
							var value = data[p];
							if (value != null && value.isDataPipeWrapper) continue;
							delete data[p];
						}
					}
					for (var p in oldData) {
						if (oldData.hasOwnProperty(p)) {
							data[p] = oldData[p];
						}
					}
				}
				
				var oldState = this.state;
				
				if (deep) deepCancel(this);
				
				if (oldState != dorado.Entity.STATE_MOVED) this.resetState();
				if (oldState == dorado.Entity.STATE_DELETED && this.parent && this.parent instanceof dorado.EntityList) {
					var entityList = this.parent;
					if (entityList.current == null) {
						entityList.disableObservers();
						entityList.setCurrent(this);
						entityList.enableObservers();
					}
				}
				this.sendMessage(0);
			} else if (deep) {
				deepCancel(this);
			}
		},
		
		resetState: function() {
			this._propertyInfoMap = {};
			delete this._messages;
			delete this._messageState;
			this.setState(dorado.Entity.STATE_NONE);
			delete this._oldData;
		},
		
		/**
		 * 重设实体对象。
		 * <p>
		 * 此方法不会改变Entity的状态。但会重置那些通过引用属性(ReferencePropertyDef)装载的关联数据，引起这些关联数据的重新装载。
		 * </p>
		 * 
		 * @param {String}
		 *            [property] 要重置的引用属性的属性名。如果需要定义多个，可以用“,”分隔。
		 */
		reset: function(property) {
			var data = this._data;
			if (property) {
				var props = property.split(',');
				for (var i = 0; i < props.length; i++) {
					var prop = props[i];
					if (data[prop] != undefined) {
						var propertyDef = (this._propertyDefs) ? this._propertyDefs.get(prop) : null;
						if (propertyDef && propertyDef instanceof dorado.Reference) {
							var oldValue = data[prop];
							if (oldValue instanceof dorado.Entity || oldValue instanceof dorado.EntityList) {
								oldValue.parent = null;
								oldValue.timestamp = dorado.Core.getTimestamp();
								oldValue._setObserver(null);
							}
							delete data[prop];
						}
					}

					this.doSetMessages(prop, null);

					var propertyInfo = this._propertyInfoMap[prop];
					delete propertyInfo.validating;
					delete propertyInfo.validated;
				}
				this.timestamp = dorado.Core.getTimestamp();
			} else {
				this._propertyDefs.each(function(propertyDef) {
					if (propertyDef instanceof dorado.Reference) {
						var oldValue = data[propertyDef._name];
						if (oldValue instanceof dorado.Entity || oldValue instanceof dorado.EntityList) {
							oldValue.parent = null;
							oldValue.timestamp = dorado.Core.getTimestamp();
							oldValue._setObserver(null);
						}
						delete data[propertyDef._name];
					}
				});

				this._propertyInfoMap = {};
				delete this._messages;
				delete this._messageState;
			}
			this.sendMessage(0);
		},
		
		/**
		 * 创建并返回一个兄弟实体对象。即创建一个与本实体对象相同类型的新实体对象。
		 * 
		 * @param {Object|dorado.Entity}
		 *            [data] 新创建的实体对象要封装JSON数据对象，可以不指定此参数。
		 * @param {boolean}
		 *            [detached] 是否需要返回一个游离的实体对象。
		 *            如果本实体对象已经隶属于一个实体集合，那么默认情况下此方法会将新创建的实体对象追加到该集合中。
		 *            通过detached参数可以指定本方法不将新的实体对象追加到集合；<br>
		 *            如果本实体对象不隶属于实体集合，那么detached参数将没有实际作用，新的实体对象将总是游离的。
		 * @return {dorado.Entity} 新创建的实体对象。
		 */
		createBrother: function(data, detached) {
			if (data instanceof dorado.Entity) data = data.getData();
			
			var brother = new dorado.Entity(null, this.dataTypeRepository, this.dataType);
			if (data) brother.set(data);
			if (!detached && this.parent instanceof dorado.EntityList) {
				this.parent.insert(brother);
			}
			return brother;
		},
		
		/**
		 * 创建并返回一个子实体对象。
		 * 
		 * @param {String}
		 *            property 子实体对象对应的属性名。
		 * @param {Object|dorado.Entity}
		 *            [data] 新创建的实体对象要封装JSON数据对象，可以不指定此参数。
		 * @param {boolean}
		 *            [detached] 是否需要返回一个游离的实体对象。
		 *            默认情况下，新创建的子实体对象会直接被设置到本实体对象的属性中。
		 *            通过detached参数可以指定本方法不将新的子实体对象附着到本实体对象中。<br>
		 *            需要注意的是，如果子属性的数据类型为集合类型({@link dorado.AggregationDataType})。
		 *            那么，新创建的子实体对象会被追加到该属性对应的实体集合中。如果属性的值为空，则测方法还会自动为该属性创建一个匹配的实体集合。
		 * @return {dorado.Entity} 新创建的实体对象。
		 */
		createChild: function(property, data, detached) {
			if (data instanceof dorado.Entity) data = data.getData();
			
			var child = null;
			if (this.dataType) {
				var propertyDef = this.getPropertyDef(property);
				if (!propertyDef) {
					throw new dorado.ResourceException("dorado.data.UnknownProperty", property);
				}
				var elementDataType = propertyDef.get("dataType"), aggregationDataType;
				if (elementDataType && elementDataType instanceof dorado.AggregationDataType) {
					aggregationDataType = elementDataType;
					elementDataType = elementDataType.getElementDataType();
				}
				if (elementDataType && !( elementDataType instanceof dorado.EntityDataType)) {
					throw new ResourceException("dorado.data.EntityPropertyExpected", property);
				}
				child = new dorado.Entity(null, this.dataTypeRepository, elementDataType);
				if (data) child.set(data);
				if (!detached) {
					if (aggregationDataType) {
						var list = this._get(property, propertyDef);
						list.insert(child);
					} else {
						this._set(property, child, propertyDef);
					}
				}
			} else {
				child = new dorado.Entity();
				if (data) child.set(data);
				if (!detached) {
					var oldChild = this.get(property);
					if (oldChild instanceof dorado.EntityList) {
						oldChild.insert(child);
					} else if (oldChild instanceof Array) {
						oldChild.push(child);
					} else {
						this.set(property, child);
					}
				}
			}
			return child;
		},
		
		/**
		 * 返回与当前数据实体平级的前一个数据实体。
		 * <p>
		 * 注意：此方法不会导致集合的自动装载动作。如果本数据实体不在某个实体集合中,那么此方法将直接返回null。
		 * </p>
		 * 
		 * @return {dorado.Entity} 前一个数据实体。
		 */
		getPrevious: function() {
			var entityList = this.parent;
			if (!entityList || !(entityList instanceof dorado.EntityList)) return null;
			
			var page = this.page;
			var entry = page.findEntry(this);
			entry = entityList._findPreviousEntry(entry);
			return (entry) ? entry.data : null;
		},
		
		/**
		 * 返回与当前数据实体平级的下一个数据实体。
		 * <p>
		 * 注意：此方法不会导致集合的自动装载动作。如果本数据实体不在某个实体集合中,那么此方法将直接返回null。
		 * </p>
		 * 
		 * @return {dorado.Entity} 下一个数据实体。
		 */
		getNext: function() {
			var entityList = this.parent;
			if (!entityList || !(entityList instanceof dorado.EntityList)) return null;
			
			var page = this.page;
			var entry = page.findEntry(this);
			entry = entityList._findNextEntry(entry);
			return (entry) ? entry.data : null;
		},
		
		/**
		 * 将此数据实体设置为其目前所在的实体集合中的当前实体。
		 * <p>
		 * <b>一个数据实体某一时刻最多只能隶属于一个实体集合。</b><br>
		 * 如果此数据实体目前不属于任何实体集合，则此方法什么也不做。
		 * </p>
		 * 
		 * @param {boolean}
		 *            [cascade] 是否同时要将此数据实体之上的每一级父对象都设置为当前数据实体。
		 * @see dorado.EntityList#setCurrent
		 */
		setCurrent: function(cascade) {
			var parentEntity;
			if (this.parent instanceof dorado.EntityList) {
				this.parent.setCurrent(this);
				parentEntity = this.parent.parent;
			} else {
				parentEntity = this.parent;
			}
			
			if (cascade && parentEntity && parentEntity instanceof dorado.Entity) {
				parentEntity.setCurrent(true);
			}
		},
		
		/**
		 * 清空本数据实体中所有的数据。
		 */
		clearData: function() {
			var data = this._data;
			for(var property in data) {
				if (!data.hasOwnProperty(property)) continue;
				delete data[property];
			}
			this.timestamp = dorado.Core.getTimestamp();
			this.sendMessage(0);
		},
		
		/**
		 * 将给定的JSON对象中的数据转换成为数据实体。
		 * 
		 * @param {Object}
		 *            json 要转换的JSON对象。
		 */
		fromJSON: function(json) {
			if (this.dataType) json.$dataType = this.dataType._id;
			this._data = json;
			delete this._oldData;
			this.state = dorado.Entity.STATE_NONE;
			this.timestamp = dorado.Core.getTimestamp();
			this.sendMessage(0);
		},
		
		/**
		 * 将实体对象转换成一个JSON数据对象。
		 * 
		 * @param {Object}
		 *            [options] 转换选项。
		 * @param {String[]}
		 *            [options.properties]
		 *            属性名数组，表示只转换该数组中列举过的属性。如果不指定此属性表示转换实体对象中的所有属性。
		 * @param {boolean}
		 *            [options.includeUnsubmittableProperties=true]
		 *            是否转换实体对象中那么submittable=false的属性（见{@link dorado.PropertyDef#attribute:submittable}）。默认按true进行处理。
		 * @param {boolean}
		 *            [options.includeReferenceProperties=true] 是否转换实体对象中{@link dorado.Reference}类型的属性。默认按true进行处理。
		 * @param {String}
		 *            [options.loadMode="never"]
		 *            数据装载模式，此属性仅在options.includeReferenceProperties=true为true时有效。<br>
		 *            包含下列三种取值:
		 *            <ul>
		 *            <li>always - 如果有需要总是装载尚未装载的延时数据。</li>
		 *            <li>auto - 如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 *            <li>never - 不会激活数据装载过程，直接返回数据的当前值。</li>
		 *            </ul>
		 * @param {boolean}
		 *            [options.includeUnloadPage] 是否转换{@link dorado.EntityList}中尚未装载的页中的数据。
		 *            此属性对于{@link dorado.Entity}的toJSON而言是没有意义的，但是由于options参数会自动被传递到实体对象内部{@link dorado.EntityList}的toJSON方法中，
		 *            因此它会影响内部{@link dorado.EntityList}的处理过程。 默认按true进行处理。
		 * @param {boolean}
		 *            [options.includeDeletedEntity] 是否转换那些被标记为"已删除"的数据实体。 此属性对于{@link dorado.Entity}的toJSON而言是没有意义的，但是由于options参数会自动被传递到实体对象内部{@link dorado.EntityList}的toJSON方法中，
		 *            因此它会影响内部{@link dorado.EntityList}的处理过程。 默认按false进行处理。
		 * @param {boolean}
		 *            [options.simplePropertyOnly] 是否只生成简单类型的属性到JSON中。
		 * @param {boolean}
		 *            [options.generateDataType]
		 *            是否在JSON对象中生成DataType信息，生成的DataType信息将被放置在名为$dataType的特殊子属性中。
		 *            注意：此属性的只对顶层JSON对象有效，即此方法永远不会为子JSON对象生成DataType信息。
		 * @param {boolean}
		 *            [options.generateState]
		 *            是否在JSON对象中生成实体对象的状态信息(即新增、已更改等状态)，生成的状态信息将被放置在名为$state的特殊子属性中。
		 * @param {boolean}
		 *            [options.generateEntityId]
		 *            是否在JSON对象中生成实体对象的ID，生成的状态信息将被放置在名为$entityId的特殊子属性中。
		 * @param {boolean}
		 *            [options.generateOldData]
		 *            是否在JSON对象中生成旧数据，生成的状态信息将被放置在名为$oldData的特殊子属性中。
		 * @param {Function}
		 *            [options.entityFilter]
		 *            用户自定义的数据实体过滤函数，返回true/false表示是否需要将此当前数据实体转换到JSON中。
		 *            此函数的传入参数如下：
		 * @param {dorado.Entity}
		 *            [options.entityFilter.entity] 当前正被过滤的数据实体。
		 * @return {Object} 得到的JSON数据对象。
		 */
		toJSON: function(options, context) {
			var result = {};
			var includeUnsubmittableProperties, includeReferenceProperties, simplePropertyOnly, generateDataType, generateState, generateEntityId, generateOldData, properties, entityFilter;
			includeUnsubmittableProperties = includeReferenceProperties = true, loadMode = "never";
			simplePropertyOnly = generateDataType = generateState = generateEntityId = generateOldData = false;
			properties = entityFilter = null;
			
			if (options != null) {
				if (options.includeUnsubmittableProperties === false) includeUnsubmittableProperties = false;
				if (options.includeReferenceProperties === false) includeReferenceProperties = false;
				if (options.loadMode) loadMode = options.loadMode;
				simplePropertyOnly = options.simplePropertyOnly;
				generateDataType = options.generateDataType;
				generateState = options.generateState;
				generateEntityId = options.generateEntityId;
				generateOldData = !!(options.generateOldData && this._oldData);
				properties = options.properties;
				entityFilter = options.entityFilter;
				if (properties != null && properties.length == 0) properties = null;
			}

			var data = this._data, oldData = this._oldData, oldDataHolder;
			for(var property in data) {
				if (!data.hasOwnProperty(property)) continue;
				if (property.charAt(0) == '$') continue;
				if (properties && properties.indexOf(property) < 0) continue;
				
				var propertyDef = (this._propertyDefs) ? this._propertyDefs.get(property) : null;
				if (propertyDef && simplePropertyOnly) {
					var pdt = propertyDef.getDataType("never");
					if (pdt && (pdt instanceof dorado.EntityDataType || pdt instanceof dorado.AggregationDataType)) continue;
				}
				
				if (!includeUnsubmittableProperties && propertyDef && !propertyDef._submittable) continue;
				if (propertyDef instanceof dorado.Reference) {
					if (!includeReferenceProperties) continue;
				}
				
				var value = this._get(property, propertyDef, null, loadMode);
				if (value != null) {
					if (value instanceof dorado.Entity) {
						if (simplePropertyOnly) continue;
					
						if (!entityFilter || entityFilter(value)) {
							value = value.toJSON(options, context);
						} else {
							value = null;
						}
					} else if (value instanceof dorado.EntityList) {
						value = value.toJSON(options, context);
					}
					else if (value instanceof Object && value.isDataPipeWrapper) {
						value = undefined;
					}
				}
				if (generateOldData && propertyDef && oldData != null) {
					if (!oldDataHolder) oldDataHolder = {};
					oldDataHolder[property] = oldData[property];
				}
				
				result[property] = value;
			}

			if (generateDataType && data.$dataType) result.$dataType = data.$dataType;
			if (generateState && this.state != dorado.Entity.STATE_NONE) result.$state = this.state;
			if (generateEntityId) result.$entityId = this.entityId;
			if (oldDataHolder) result.$oldData = oldDataHolder;

			if (context && context.entities) context.entities.push(this);
			return result;
		},
		
		/**
		 * 将实体对象转换成一个可以以类似JSON方式来读写的代理对象。
		 * 
		 * @param {Object}
		 *            [options] 转换选项。
		 * @param {boolean}
		 *            [options.textMode=false]
		 *            是否代理Entity的getText方法。该选项默认值为false，表示代理Entity的get方法。
		 * @param {boolean}
		 *            [options.readOnly=false] 是否以只读方式代理Entity。该选项默认值为false。
		 * @param {boolean}
		 *            [options.includeUnloadPage] 是否处理{@link dorado.EntityList}中尚未装载的页中的数据。
		 *            此属性对于{@link dorado.Entity}的getWrapper而言是没有意义的，但是由于options参数会自动被传递到实体对象内部{@link dorado.EntityList}的getWrapper方法中，
		 *            因此它会影响内部{@link dorado.EntityList}的处理过程。 默认按false进行处理。
		 * @return {Object} 得到的代理对象。
		 */
		getWrapper: function(options) {
			var wrapperType;
			if (this.acceptUnknownProperty) {
				wrapperType = function(entity, options) {
					this._entity = entity;
					this._options = options;
					this._textMode = options && options.textMode;
					this._readOnly = options && options.readOnly;
				};

				var wrapperPrototype = wrapperType.prototype;
				
				var data = this._data;
				for (var property in data) {
					if (!data.hasOwnProperty(property)) continue;

					doDefineProperty(wrapperPrototype, property);
				}
			}
			else {
				wrapperType = this.dataType.getWrapperType();
			}
			return new wrapperType(this, options);
		},
		
		getData: function() {
			return this._data;
		},
		
		/**
		 * 返回数据实体内部用于保存原有属性值的JSON对象。
		 * 
		 * @return {Object} JSON对象。<br>
		 *         注意：该对象可能并不存在。
		 */
		getOldData: function() {
			return this._oldData;
		},
		
		/**
		 * 返回当前数据实体关联的额外信息的数组。
		 * 
		 * @param {String}
		 *            [property] 属性名。
		 *            <p>
		 *            如果在调用时指定了这个参数，这表示要读取跟某个属性关联的额外信息。否则表示读取跟整个数据实体关联的额外信息。
		 *            </p>
		 * @return [Object] 额外信息的数组。数组中的每一个元素是一个JSON对象，该JSON对象包含以下属性：
		 *         <ul>
		 *         <li>state - {String}
		 *         信息级别。取值范围包括：info、ok、warn、error。默认值为error。</li>
		 *         <li>text - {String} 信息内容。</li>
		 *         </ul>
		 */
		getMessages: function(property) {
			var results;
			if (property) {
				var obj = this._propertyInfoMap[property]
				results = ((obj) ? obj.messages : null);
			} else {
				results = this._messages;
			}
			return results;
		},
		
		doSetMessages: function(property, messages) {

			function getMessageState(entity) {
				var state = null, stateCode = -1;
				if (entity._messages) {
					state = dorado.Toolkits.getTopMessageState(entity._messages);
					if (state)
						stateCode = STATE_CODE[state];
				}
				var map = entity._propertyInfoMap;
				for(var p in map) {
					var obj = map[p];
					var code = STATE_CODE[obj.state];
					if (code > stateCode) {
						stateCode = code;
						state = obj.state;
					}
				}
				return state;
			}

			var retval = false;
			if (messages === undefined) {
				messages = property;
				messages = dorado.Toolkits.trimMessages(messages, DEFAULT_VALIDATION_RESULT_STATE);
				if (this._messages == messages) return false;
				this._messages = messages;
				
				// if (dorado.Toolkits.getTopMessageState(messages) !=
				// this._messageState) {
				this._messageState = getMessageState(this);
				retval = true;
				// }
			} else {
				var map = this._propertyInfoMap;
				messages = dorado.Toolkits.trimMessages(messages, DEFAULT_VALIDATION_RESULT_STATE);
				var propertyInfo = map[property];
				if (propertyInfo && !propertyInfo.validating && propertyInfo.messages == messages) return false;
				
				var state = dorado.Toolkits.getTopMessageState(messages);
				if (!propertyInfo) map[property] = propertyInfo = {};
				propertyInfo.state = state;
				propertyInfo.messages = messages;
				
				// if (state != this._messageState || state != (propertyInfo ?
				// propertyInfo.state : null)) {
				this._messageState = getMessageState(this);
				retval = true;
				// }
			}

			var dataType = this.dataType;
			if (dataType) {
				dataType.fireEvent("onMessageChange", dataType, {
					entity : this,
					property : property,
					messages : messages
				});
			}
			return retval;
		},
		
		/**
		 * 设置当前数据实体关联的额外信息的数组。
		 * <p>
		 * 此方法有两种调用方式：
		 * <ul>
		 * <li>当我们为此方法传递一个传入参数时，表示要将传入的额外信息关联到整个数据实体上。</li>
		 * <li>当我们为此方法传递两个传入参数时，表示要将额外信息关联到数据实体的某个具体属性上。
		 * 此时第一个参数将被认为是属性名，第二个参数被认为是额外信息。</li>
		 * </ul>
		 * </p>
		 * 
		 * @param {String}
		 *            [property] 属性名。
		 * @param {String|Object|[String]|[Object]}
		 *            [messages] 额外信息。
		 *            <p>
		 *            调用此方法时，既可以传入单个的信息，也可以传入信息的数组。
		 *            对于每一个信息既可以是一个描述信息完整信息的JSON对象，也可以是一个简单的字符窜（此时系统会自动将其信息级别处理为error）。
		 *            </p>
		 */
		setMessages: function(property, messages) {
			var retval = this.doSetMessages(property, messages);
			if (retval) {
				this.timestamp = dorado.Core.getTimestamp();
				if (property) {
					this.sendMessage(dorado.Entity._MESSAGE_DATA_CHANGED, {
						entity : this,
						property : property
					});
				} else {
					this.sendMessage(0);
				}
			}
			return retval;
		},
		
		/**
		 * 返回当前数据实体中最高的信息级别。即系统认为error高于warn高于ok高于info。
		 * 
		 * @param {String}
		 *            [property] 属性名。
		 *            <p>
		 *            如果在调用时指定了这个参数，这表示要返回跟某个属性的最高信息级别。否则表示读取跟整个数据实体关联的最高信息级别。
		 *            </p>
		 * @return {String} 最高的验证信息级别。取值包括: error、warn、ok、info。
		 */
		getMessageState: function(property) {
			if (property) {
				var map = this._propertyInfoMap;
				return map[property] ? map[property].state : null;
			} else {
				return this._messageState;
			}
		},
		
		/**
		 * 返回数据实体中某属性校验状态。
		 * 
		 * @param {Object}
		 *            property 属性名。
		 * @return {String} 校验状态。取值包括:
		 *         <ul>
		 *         <li>unvalidate - 尚未校验。</li>
		 *         <li>validating - 正在校验，指正有异步的校验过程仍未结束。</li>
		 *         <li>ok - 校验通过。</li>
		 *         <li>warn - 校验的返回信息中包含警告。</li>
		 *         <li>error - 校验未通过或校验失败。</li>
		 *         </ul>
		 */
		getValidateState: function(property) {
			var state = "unvalidate", map = this._propertyInfoMap;
			if (map) {
				var propertyInfo = map[property];
				if (propertyInfo) {
					if (propertyInfo.validating) {
						state = "validating";
					} else if (propertyInfo.validated) {
						state = this.getMessageState(property);
						if (!state || state == "info")
							state = "ok";
					}
				}
			}
			return state;
		},
		
		/**
		 * 验证此数据实体中的数据当前是否是有效的，即是否可以被提交保存。
		 * <p>
		 * 关于是否有效的判断会与{@link dorado.EntityDataType#attribute:acceptValidationResult}的设置相关。
		 * </p>
		 * 
		 * @param {String|boolean|Object}
		 *            [options=true] 此参数有如下三种使用方式：
		 *            <ul>
		 *            <li>当传入一个String类型的值时，表示要校验的子属性，如果不指定则表示校验所有属性。</li>
		 *            <li>当传入一个boolean类型的值时，表示是否强制重新验证所有子属性及校验器。默认为true。</li>
		 *            <li>当传入一个JSON对象时，其中有可以包含如下的更多选项。</li>
		 *            </ul>
		 * @param {String}
		 *            [options.property] 要校验的子属性，如果不指定则表示校验所有属性。
		 * @param {boolean}
		 *            [options.force=true] 是否强制重新验证所有子属性及校验器。
		 * @param {boolean}
		 *            [options.validateSimplePropertyOnly=true]
		 *            只验证简单数据类型的属性中的数据，如String、boolean、int、Date等数据类型。
		 *            设置此属性产生的实际结果是验证逻辑将忽略对此数据实体中的所有子数据实体的有效性验证。
		 * @param {boolean}
		 *            [options.preformAsyncValidator] 是否重新执行那些异步的校验器。
		 * @param {Object}
		 *            [options.context] 验证上下文。<br>
		 *            传入此参数的目的通常是用于获得更加验证详尽的验证结果。此上下文对象中可以包含如下的返回属性：
		 *            <ul>
		 *            <li>result - {String} 验证结果。等同于此方法的返回值。</li>
		 *            <li>info - {[Object]}
		 *            包含所有info级别验证结果的数组。数组中的每一个元素是一个JSON对象，该JSON对象包含以下属性：
		 *            <ul>
		 *            <li>entity - {dorado.Entity} 相关的数据实体。</li>
		 *            <li>property - {String} 相关的数据实体属性。</li>
		 *            <li>state - {String}
		 *            信息级别。取值范围包括：info、ok、warn、error。默认值为error。</li>
		 *            <li>text - {String} 信息内容。</li>
		 *            </ul>
		 *            </li>
		 *            <li>ok - {[Object]} 包含所有ok级别验证结果的数组。同上。</li>
		 *            <li>warn - {[Object]} 包含所有warn级别验证结果的数组。同上。</li>
		 *            <li>error - {[Object]} 包含所有error级别验证结果的数组。同上。</li>
		 *            <li>executing - {[Object]}
		 *            尚未完成的异步验证过程描述信息的数组。数组中的每一个元素是一个JSON对象，该JSON对象包含以下属性：
		 *            <ul>
		 *            <li>entity - {dorado.Entity} 相关的数据实体。</li>
		 *            <li>property - {String} 相关的数据实体属性。</li>
		 *            <li>num - {int} 正在执行的验证过程的个数。</li>
		 *            </ul>
		 *            </li>
		 *            <li>executingValidationNum - {int} 总的正在执行的验证过程的个数。</li>
		 *            </ul>
		 * @return {String} 验证结果，可能会有如下3种返回值：
		 *         <ul>
		 *         <li>invalid - 表示本数据实体未通过数据验证，不能被提交。</li>
		 *         <li>ok - 表示本数据实体已通过验证，可以提交。</li>
		 *         </ul>
		 */
		validate: function(options) {
			if (typeof options == "string") {
				options = {
					property: options
				};
			}
			else if (typeof options == "boolean") {
				options = {
					force: options
				};
			}
			var property = options && options.property;
			var force = (options && options.force === false) ? false : true;
			var simplePropertyOnly =  (options && options.validateSimplePropertyOnly === false) ? false : true;
			var preformAsyncValidator = (options ? options.preformAsyncValidator : false);
			var context = options ? options.context : null;
			var result, topResult, resultCode, topResultCode = -1, hasValidated = false;
			
			if (force) {
				if (property) {
					delete this._propertyInfoMap[property];
				}
				else {
					this._propertyInfoMap = {};
					delete this._messages;
					delete this._messageState;
				}
			}

			var dataType = this.dataType, propertyInfoMap = this._propertyInfoMap;
			if (context) {
				context.info = [];
				context.ok = [];
				context.warn = [];
				context.error = [];
				context.executing = [];
				context.executingValidationNum = 0;
			}
			
			if (dataType) {
				var entity = this;
				var doValidate = function(pd) {
					var property = pd._name, propertyInfo = propertyInfoMap[property];
					if (property.charAt(0) == '$') return;
					
					if (propertyInfo) {
						if (propertyInfo.validating) {
							if (context) {
								context.executingValidationNum = (context.executingValidationNum || 0) + propertyInfo.validating;
								var executing = context.executing = context.executing || [];
								executing.push({
									entity: entity,
									property: property,
									num: propertyInfo.validating
								});
							}
							return;
						} else if (propertyInfo.validated) {
							if (context && propertyInfo.messages) {
								addMessages2Context(context, entity, property, propertyInfo.messages);
							}
							return;
						}
					} else {
						propertyInfoMap[property] = propertyInfo = {};
					}
					
					var value = entity._data[property];
					hasValidated = true;
					var messages = entity._validateProperty(dataType, pd, propertyInfo, value, preformAsyncValidator);
					if (context && messages) {
						addMessages2Context(context, entity, property, messages);
					}
				};
				
				if (property) {
					var pd = this.getPropertyDef(property);
					if (pd) doValidate(pd);
				} else {
					dataType._propertyDefs.each(doValidate);
				}
			}
			
			if (!simplePropertyOnly) {
				var data = this._data;
				var doValidateEntity = function(p) {
					var value = data[p];
					if (value instanceof dorado.Entity) {
						if (context) options.context = {};
						result = value.validate(options);
						if (context) {
							mergeValidationContexts(context, options.context);
							options.context = context;
						}
						resultCode = VALIDATION_RESULT_CODE[result];
						if (resultCode > topResultCode) {
							topResultCode = resultCode;
							topResult = result;
						}
					} else if (value instanceof dorado.EntityList) {
						var it = value.iterator();
						while (it.hasNext()) {
							if (context) options.context = {};
							result = it.next().validate(options);
							if (context) {
								mergeValidationContexts(context, options.context);
								options.context = context;
							}
							resultCode = VALIDATION_RESULT_CODE[result];
							if (resultCode > topResultCode) {
								topResultCode = resultCode;
								topResult = result;
							}
						}
					}
				};
				
				if (property) {
					doValidateEntity(property);
				} else {
					for (var p in data) {
						if (!data.hasOwnProperty(p) || p.charAt(0) == '$') continue;
						doValidateEntity(p);
					}
				}
			}
			
			state = this.getMessageState(property);
			var acceptState = dataType ? dataType.get("acceptValidationState") : null;
			if (STATE_CODE[state || "info"] <= STATE_CODE[acceptState || "ok"]) {
				result = "ok";
			} else {
				result = "invalid";
			}
			resultCode = VALIDATION_RESULT_CODE[result];
			if (resultCode > topResultCode) {
				topResultCode = resultCode;
				topResult = result;
			}
			
			if (context) context.result = topResult;
			if (hasValidated) this.sendMessage(0);
			return topResult;
		},
		
		/**
		 * 判断数据实体或数据实体中某属性中是否包含未提交的信息。
		 * @param {String} [property] 要判断的属性。如果不定义则表示希望判断整个数据实体是否包含未提交的信息。
		 * @return {boolean} 是否包含未提交的信息。
		 */
		isDirty: function(property) {
			if (this.state == dorado.Entity.STATE_NONE)
				return false;
			if (property) {
				var propertyInfo = this._propertyInfoMap[property];
				return (propertyInfo) ? propertyInfo.isDirty : false;
			} else {
				return this.state != dorado.Entity.STATE_NONE;
			}
		},
		
		/**
		 * 迭代式的判断该数据实体及其所有子数据实体中是否是否包含任何未提交的信息。
		 * @return {boolean} 是否包含未提交的信息。
		 */
		isCascadeDirty: function() {
			function isDirty(entity) {
				var dirty = (entity.state != dorado.Entity.STATE_NONE);
				if(!dirty) {
					var data = entity._data;
					for(var p in data) {
						var v = data[p];
						if (v instanceof dorado.Entity) {
							dirty = isDirty(v);
						} else if (v instanceof dorado.EntityList) {
							var it = v.iterator(true);
							while(it.hasNext()) {
								dirty = isDirty(it.next());
								if(dirty) break;
							}
						}
						if(dirty) break;
					}
				}
				return dirty;
			}
			
			return isDirty(this);
		},
		
		/**
		 * 重新装载当前实体中的数据。
		 */
		flush: function(callback) {

			function checkResult(result) {
				if ( result instanceof Array && result.length > 1) {
					throw new dorado.ResourceException("dorado.data.TooMoreResult");
				}
			}

			if (!this.dataType || !this.dataProvider) {
				throw new dorado.ResourceException("dorado.data.DataProviderUndefined");
			}

			var arg = {
				parameter : this.parameter
			}, oldSupportsEntity = this.dataProvider.supportsEntity;
			this.dataProvider.supportsEntity = false;
			try {
				if (callback) {
					this.dataProvider.getResultAsync(arg, {
						scope: this,
						callback: function(success, result) {
							if (success) this.fromJSON(result);
							$callback(callback, success, ((success) ? this : result));
						}
					});
				} else {
					var result = this.dataProvider.getResult(arg);
					this.fromJSON(result);
				}
			}
			finally {
				this.dataProvider.supportsEntity = oldSupportsEntity;
			}
		},
		
		/**
		 * 以异步方式重新装载实体中的数据。
		 * 
		 * @param {Function|dorado.Callback}
		 *            callback 回调对象。
		 */
		flushAsync: function(callback) {
			this.flush(callback || dorado._NULL_FUNCTION);
		},
		
		/**
		 * 从所属的实体集合{@link dorado.EntityList}中删除本实体对象。
		 * 如果本实体对象尚不属于任何实体集合，则此方法不会产生实际的作用。
		 * 
		 * @param {boolean}
		 *            [detach] 是否彻底断开被删除的数据实体与集合之间的关联。默认为不断开。<br>
		 *            在通常情况下，当我们从集合中删除一个数据实体时，dorado只是在内部处理中将数据实体的状态标记为已删除状态而并没有真正的将数据实体从合集中移除掉。
		 *            这样做的目的是为了便于在今后提交时能够清晰的掌握集合中的元素究竟做过哪些改变。
		 */
		remove: function(detach) {
			if (this.parent instanceof dorado.EntityList) {
				this.parent.remove(this, detach);
			}
		},
		
		toString: function() {
			var text;
			if (this.dataType) {
				var dataType = this.dataType;
				var eventArg = {
					entity : this,
					processDefault : true
				};
				if (!this.disableEvents && dataType.getListenerCount("onEntityToText")) {
					eventArg.processDefault = false;
					dataType.fireEvent("onEntityToText", dataType, eventArg);
				}
				if (eventArg.processDefault) {
					if (dataType._defaultDisplayProperty) {
						text = this.getText(dataType._defaultDisplayProperty, "never");
					}
					if (text === undefined)
						text = "Entity@" + this.entityId;
				}
			} else {
				text = "Entity@" + this.entityId;
			}
			return text;
		},
		
		clone: function(deep) {
			var newData, data = this._data;
			if (deep) {
				newData = dorado.Core.clone(data, deep);
			} else {
				newData = {};
				for(var attr in data) {
					var v = data[attr];
					if (v instanceof dorado.Entity || v instanceof dorado.EntityList) {
						continue;
					}
					newData[attr] = v;
				}
			}
			return new dorado.Entity(newData, this.dataTypeRepository, this.dataType);
		}
	});
	
	/**
	 * 实体对象的状态常量 - 无状态。
	 * 
	 * @type int
	 */
	dorado.Entity.STATE_NONE = STATE_NONE;

	/**
	 * 实体对象的状态常量 - 新增状态。
	 * 
	 * @type int
	 */
	dorado.Entity.STATE_NEW = 1;

	/**
	 * 实体对象的状态常量 - 已修改状态。
	 * 
	 * @type int
	 */
	dorado.Entity.STATE_MODIFIED = 2;

	/**
	 * 实体对象的状态常量 - 已删除状态。
	 * 
	 * @type int
	 */
	dorado.Entity.STATE_DELETED = 3;

	/**
	 * 实体对象的状态常量 - 被移动状态。 通产指该对象被从一个位置移动到了另一个位置，这包括其父对象的改变或仅仅是顺序被改变。
	 * 
	 * @type int
	 */
	dorado.Entity.STATE_MOVED = 4;

	dorado.Entity._MESSAGE_DATA_CHANGED = 3;
	dorado.Entity._MESSAGE_ENTITY_STATE_CHANGED = 4;
	dorado.Entity._MESSAGE_REFRESH_ENTITY = 5;
	
	dorado.Entity._MESSAGE_LOADING_START = 10;
	dorado.Entity._MESSAGE_LOADING_END = 11;

	dorado.Entity.ALWAYS_RETURN_VALID_ENTITY_LIST = true;

	var dummyEntityMap = {};

	dorado.Entity.getDummyEntity = function(pageNo) {
		var entity = dummyEntityMap[pageNo];
		if (!entity) {
			dummyEntityMap[pageNo] = entity = new dorado.Entity();
			entity.get = entity.set = dorado._NULL_FUNCTION;
			entity.dummy = true;
			entity.page = {
				pageNo : pageNo
			};
		}
		return entity;
	};
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @name dorado.EntityList
	 * @class 实体对象集合。
	 * @param {Object[]|Object} [data] 用作初始化集合元素的JSON数据。<br>
	 * 如果此处传入的是一个数组，那么数组中的对象会被逐一意添加到集合中; 如果传入的单个的对象，那么该对象会被作为一个元素添加到集合中。
	 * @param {dorado.DataRepository} [dataTypeRepository] 数据类型的管理器。
	 * @param {dorado.AggregationDataType} [dataType] 集合数据类型。
	 */
	dorado.EntityList = $class(/** @scope dorado.EntityList.prototype */{
		$className: "dorado.EntityList",
		
		/**
		 * @name dorado.EntityList#current
		 * @property
		 * @type dorado.Entity
		 * @description 当前的数据实体。
		 */
		/**
		 * @name dorado.EntityList#dataProvider
		 * @property
		 * @type dorado.DataProvider
		 * @description 获取为实体对象集合提供数据的数据提供者。
		 */
		/**
		 * @name dorado.EntityList#parameter
		 * @property
		 * @type Object
		 * @description 装载数据使用的附加参数。
		 * <p>
		 * 当集合需要通过DataProvider装载数据时，系统会将此处定义的参数合并到DataProvider原有的参数之上。 这里的合并可包含两种情况：
		 * 当parameter是一个JSON对象时，系统会将该JSON对象中的个属性复制到DataProvider原有的参数之上；
		 * 当parameter不是一个JSON对象时（如String、int等），系统会直接用此参数替换DataProvider原有的参数。
		 * </p>
		 */
		// =====
		
		constructor: function(data, dataTypeRepository, dataType, alwaysTransferEntity) {
			
			/**
			 * 集合中当前数据实体。
			 * @name dorado.EntityList#current
			 * @property
			 * @type dorado.Entity
			 */
			// ======
			
			this.objId = dorado.Core.getTimestamp() + '';
			
			/**
			 * 集合的时间戳。<br>
			 * 集合的元素有增减、或者有新的页被装载时，集合都会更新自己的时间戳， 因此，时间戳可以可以用来判断集合在一段时间内有没有被修改过。
			 * @type int
			 */
			this.timestamp = dorado.Core.getTimestamp();
			
			if (dataTypeRepository instanceof dorado.DataType) {
				dataType = dataTypeRepository;
				dataTypeRepository = null;
			}
			
			/**
			 * 该集合中的数据类型所属的数据类型管理器。
			 * @type dorad.DataRepository
			 */
			this.dataTypeRepository = dataTypeRepository;
			
			if (data) {
				if (dataType == null) {
					if (dataTypeRepository && data.$dataType) dataType = dataTypeRepository.get(data.$dataType);
				} else {
					data.$dataType = dataType._id;
				}
			}
			
			/**
			 * 集合数据类型。
			 * @type dorado.AggregationDataType
			 */
			this.dataType = dataType;
			
			/**
			 * 集合中元素的数据类型。
			 * @type dorado.EntityDataType
			 */
			this.elementDataType = (dataType) ? dataType.getElementDataType() : null;
			
			/**
			 * 进行分页浏览时每页的记录数。默认值为0。
			 * @type int
			 */
			this.pageSize = (dataType) ? dataType._pageSize : 0;
			
			/**
			 * 当前位置所处的页号。默认值为1。
			 * @type int
			 * @default 1
			 */
			this.pageNo = 1;
			
			/**
			 * 总的页数（包含尚未装载的页）。
			 * @type int
			 */
			this.pageCount = 0;
			
			/**
			 * 总的记录数（包含尚未装载的页中的记录数）。
			 * @type int
			 */
			this.entityCount = 0;
			
			this.alwaysTransferEntity = alwaysTransferEntity;
			
			this._pages = new dorado.util.KeyedList();
			this._keyMap = {};
			if (data != null) this.fromJSON(data);
		},
		
		_disableObserversCounter: 0,
		
		_setObserver: function(observer) {
			this._observer = observer;
			var it = this.iterator(), entity;
			while (it.hasNext()) {
				entity = it.next();
				entity._setObserver(observer);
			}
		},
		
		/**
		 * @name dorado.EntityList#disableObservers
		 * @function
		 * @description 禁止dorado.EntityList将消息发送给其观察者。
		 * <p>
		 * 该方法的主要作用是阻止与该实体对象集合关联的数据控件自动根据实体对象的变化刷新自身的显示内容，
		 * 这样做的目的一般是为了提高对实体对象集合连续进行操作时的运行效率。
		 * </p>
		 */
		disableObservers: dorado.Entity.prototype.disableObservers,
		
		/**
		 * @name dorado.EntityList#enableObservers
		 * @function
		 * @description 允许dorado.EntityList将消息发送给其观察者。
		 */
		enableObservers: dorado.Entity.prototype.enableObservers,
		
		/**
		 * @name dorado.EntityList#notifyObservers
		 * @function
		 * @description 通知dorado.EntityList的观察者刷新数据。
		 */
		notifyObservers: dorado.Entity.prototype.notifyObservers,
		
		sendMessage: function(messageCode, arg) {
			if (this._disableObserversCounter == 0 && this._observer) {
				this._observer.entityMessageReceived(messageCode, arg);
			}
		},
		
		_findPreviousEntry: function(entry, loadPage, pageNo) {
			var previous = (entry) ? entry.previous : null, pages = this._pages, pageEntry;	
			while (!(previous && previous.data.state != dorado.Entity.STATE_DELETED)) {
				if (!previous) {
					if (!pageEntry) {
						if (entry) {
							pageEntry = pages.findEntry(entry.data.page);
							pageEntry = pageEntry.previous;
						}
						else {
							pageEntry = pages.last;
						}
					}
					else {
						pageEntry = pageEntry.previous;
					}
					
					if (pageEntry) {
						previous = pageEntry.data.last;
					}
					else {
						break;
					}
				} else {
					previous = previous.previous;
				}
			}
			return previous;
		},
		
		_findNextEntry: function(entry, loadPage) {
			var next = (entry) ? entry.next : null, pages = this._pages, pageEntry;			
			while (!(next && next.data.state != dorado.Entity.STATE_DELETED)) {
				if (!next) {
					if (!pageEntry) {
						if (entry) {
							pageEntry = pages.findEntry(entry.data.page);
							pageEntry = pageEntry.next;
						}
						else {
							pageEntry = pages.first;
						}
					}
					else {
						pageEntry = pageEntry.next;
					}
					
					if (pageEntry) {
						next = pageEntry.data.first;
					}
					else {
						break;
					}
				} else {
					next = next.next;
				}
			}
			return next;
		},
		
		_throwInvalidEntity: function(entity) {
			throw new dorado.ResourceException("dorado.data.InvalidEntityToList");
		},
		
		_throwNoCurrent: function() {
			throw new dorado.ResourceException("dorado.data.NoCurrent");
		},
		
		/**
		 * 判断某一个页的数据是否已经装载。
		 * @param {int} pageNo 页号。从1开始的数字。
		 * @return {boolean} 是否已经装载。
		 */
		isPageLoaded: function(pageNo) {
			var page = this._pages.get(pageNo + '');
			return (page && page.loaded);
		},
		
		getPage: function(pageNo, loadPage, callback) {
		
			function pageLoaded() {
				var entity = this.parent;
				if (entity && entity instanceof dorado.EntityList) {
					var propertyDef = entity.getPropertyDef(this.parentProperty);
					if (propertyDef && propertyDef instanceof dorado.Reference) {
						propertyDef.fireEvent("onLoadData", propertyDef, {
							entity: entity,
							property: this.parentProperty,
							pageNo: pageNo
						});
					}
				} else if (!entity) {
					var dataSet = this._observer;
					if (dataSet && dorado.widget && dorado.widget.DataSet && dataSet instanceof dorado.widget.DataSet) {
						dataSet.fireEvent("onLoadData", dataSet, {
							pageNo: pageNo
						});
					}
				}
			}
			
			if (pageNo > 0 && pageNo <= this.pageCount) {
				var page = this._pages.get(pageNo + '');
				if (!page && loadPage) {
					page = new dorado.EntityList.Page(this, pageNo);
					if (!this._pages.size) {
						this._pages.insert(page);
					}
					else {
						var it = this._pages.iterator(), refPage, tempPage;
						it.last();
						while (it.hasPrevious()) {
							tempPage = it.previous();
							if (tempPage.page < pageNo) {
								refPage = tempPage;
								break;
							}
						}
						if (refPage) {
							this._pages.insert(page, "after", refPage);
						}
						else {
							this._pages.insert(page);
						}
					}
				}
				
				if (page && page.loaded) {
					if (callback) {
						$callback(callback, true, page);
					}
					return page;
				} else if (loadPage) {
					if (this.dataProvider) {
						var pipe = page.loadPagePipe;
						if (!pipe) {
							page.loadPagePipe = pipe = new LoadPagePipe(this, pageNo);
						}
						
						if (callback) {
							var arg = {
								entityList: this,
								pageNo: pageNo
							};
							var isNewPipe = (pipe.runningProcNum == 0);
							pipe.getAsync({
								scope: this,
								callback: function(success, result) {
									if (isNewPipe) this.sendMessage(dorado.Entity._MESSAGE_LOADING_END, arg);
									
									if (success && !page.loaded) {
										this._fillPage(page, result, false, true);
										page.loaded = true;
										pageLoaded.call(this);
									}
									$callback(callback, success, ((success) ? page : result));
								}
							});
							if (isNewPipe) this.sendMessage(dorado.Entity._MESSAGE_LOADING_START, arg);
						} else {
							var result = pipe.get();
							this._fillPage(page, result, false, true);
							page.loaded = true;
							pageLoaded.call(this);
						}
					} else {
						page.loaded = true;
					}
				}
				return page;
			} else {
				throw new dorado.ResourceException("dorado.data.InvalidPage", pageNo);
			}
		},
		
		getPageEntityCount: function(pageNo) {
			if (pageNo > 0) {
				var page = this.getPage(pageNo);
				return page ? page.entityCount : this.pageSize;
			} else {
				return this.current ? this.current.page.entityCount : 0;
			}
		},
		
		/**
		 * 将集合中的某个数据实体设置为当前数据实体。
		 * @param {dorado.Entity} current 数据实体。
		 */
		setCurrent: function(current) {
			if (this.current == current) return;
			
			if (current && (!current.page || current.page.entityList != this)) {
				this._throwInvalidEntity(current);
			}
			if (current && current.state == dorado.Entity.STATE_DELETED) {
				throw new dorado.ResourceException("dorado.data.EntityDeleted");
			}
			
			var eventArg = {
				entityList: this,
				oldCurrent: this.current,
				newCurrent: current,
				processDefault: true
			};
			
			var dataType = this.dataType, elementDataType;
			if (dataType) elementDataType = dataType.getElementDataType();
			if (elementDataType) {
				if (dorado.EntityList.duringFillPage) {
					setTimeout(function() {
						elementDataType.fireEvent("beforeCurrentChange", elementDataType, eventArg);
					}, 0);
				} else {
					elementDataType.fireEvent("beforeCurrentChange", elementDataType, eventArg);
				}
			}
			if (!eventArg.processDefault) return;
			
			this.current = current;
			this.pageNo = (current) ? current.page.pageNo : 1;
			this.timestamp = dorado.Core.getTimestamp();

			this.sendMessage(dorado.EntityList._MESSAGE_CURRENT_CHANGED, eventArg);
			if (elementDataType) {
				if (dorado.EntityList.duringFillPage) {
					setTimeout(function() {
						elementDataType.fireEvent("onCurrentChange", elementDataType, eventArg);
					}, 0);
				} else {
					elementDataType.fireEvent("onCurrentChange", elementDataType, eventArg);
				}
			}
		},
		
		/**
		 * 返回当前数据实体之前是否还存在其它数据实体。
		 * @return {boolean} 当前数据实体之前是否还存在其它数据实体。
		 */
		hasPrevious: function() {
			if (this.current) {
				var page = this.current.page;
				if (page > 1) return true;

				var entry = page.findEntry(this.current);
				entry = this._findPreviousEntry(entry, false);
				return entry != null;
			} else if (this.entityCount > 0) {
				this._throwNoCurrent();
			}
		},
		
		/**
		 * 返回当前数据实体之后是否还存在其它数据实体。
		 * @return {boolean} 当前数据实体之后是否还存在其它数据实体。
		 */
		hasNext: function() {
			if (this.current) {
				var page = this.current.page;
				if (page < this.pageCount) return true;

				var entry = page.findEntry(this.current);
				entry = this._findNextEntry(entry, false);
				return entry != null;
			} else if (this.entityCount > 0) {
				this._throwNoCurrent();
			}
		},
		
		/**
		 * 返回当前集合中的第一个数据实体。
		 * <p>注意：此方法不会导致集合的自动装载动作。</p>
		 * @return {dorado.Entity} 第一个数据实体。
		 */
		getFirst: function() {
			var entry = this._findNextEntry(null, false);
			return (entry) ? entry.data : null;
		},
		
		/**
		 * 返回当前集合中的最后一个数据实体。
		 * <p>注意：此方法不会导致集合的自动装载动作。</p>
		 * @return {dorado.Entity} 最后一个数据实体。
		 */
		getLast: function() {
			var entry = this._findPreviousEntry(null, false, this.pageCount + 1);
			return (entry) ? entry.data : null;
		},
		
		/**
		 * 将集合中的第一个数据实体设置为当前数据实体。
		 * @param [loadPage] {boolean} 如果有需要，是否自动装载尚未被加载的数据页。
		 * @return {dorado.Entity} 返回第一个数据实体。
		 */
		first: function(loadPage) {
			var entry = this._findNextEntry(null, loadPage);
			var entity = (entry) ? entry.data : null;
			this.setCurrent(entity);
			return entity;
		},
		
		/**
		 * 将当前数据实体的前一个数据实体设置为当前数据实体。
		 * @param [loadPage] {boolean} 如果有需要，是否自动装载尚未被加载的数据页。
		 * @return {dorado.Entity} 返回前一个数据实体。
		 */
		previous: function(loadPage) {
			if (this.current) {
				var page = this.current.page;
				var entry = page.findEntry(this.current);
				entry = this._findPreviousEntry(entry, loadPage);
				if (entry) {
					this.setCurrent(entry.data);
					return entry.data;
				}
				return null;
			} else if (this.entityCount > 0) {
				this._throwNoCurrent();
			}
		},
		
		/**
		 * 将当前数据实体的下一个数据实体设置为当前数据实体。
		 * @param [loadPage] {boolean} 如果有需要，是否自动装载尚未被加载的数据页。
		 * @return {dorado.Entity} 返回下一个数据实体。
		 */
		next: function(loadPage) {
			if (this.current) {
				var page = this.current.page;
				var entry = page.findEntry(this.current);
				entry = this._findNextEntry(entry, loadPage);
				if (entry) {
					this.setCurrent(entry.data);
					return entry.data;
				}
				return null;
			} else if (this.entityCount > 0) {
				this._throwNoCurrent();
			}
		},
		
		/**
		 * 将集合中的最后一个数据实体设置为当前数据实体。
		 * @param [loadPage] {boolean} 如果有需要，是否自动装载尚未被加载的数据页。
		 * @return {dorado.Entity} 返回最后一个数据实体。
		 */
		last: function(loadPage) {
			var entry = this._findPreviousEntry(null, loadPage, this.pageCount + 1);
			var entity = (entry) ? entry.data : null;
			this.setCurrent(entity);
			return entity;
		},
		
		/**
		 * 根据给定的偏移量和当前数据实体的位置，向前或向后定位到另一个数据实体并将其设置为新的当前数据实体。
		 * 例如设置offset为1，表示将当前数据实体的下一个数据实体设置为的当前数据实体。
		 * @param {int} offset 移动的步数，可以是负数。
		 */
		move: function(offset) {
			var page = this.current.page;
			var entry = page.findEntry(this.current);
			if (offset > 0) {
				for (var i = 0; i < offset; i++) {
					entry = this._findNextEntry(entry, true);
					if (!entry && this.entityCount > 0) this._throwNoCurrent();
				}
			} else if (offset < 0) {
				for (var i = 0; i > offset; i--) {
					entry = this._findPreviousEntry(entry, true);
					if (!entry && this.entityCount > 0) this._throwNoCurrent();
				}
			}
			this.setCurrent(entry.data);
			return entry.data;
		},
		
		/**
		 * 将实体集合翻到指定页中。 如果指定的页中的数据尚未装载，则将首先装载该页的数据。
		 * <p>
		 * 此方法有两种执行方式，如果不指定callback参数将按照同步模式执行，如果指定了具体的callback则按照异步模式运行。
		 * </p>
		 * @param {int} pageNo 要跳转到的页号。从1开始的数字。
		 * @param {Function|dorado.Callback} [callback] 回调对象，传入回调对象的参数即为新的页。
		 * @return {dorado.Entity} 如果是是同步模式调用的话，则返回新页中的第一个数据实体，否则返回null。
		 */
		gotoPage: function(pageNo, callback) {
			if (callback) {
				var self = this;
				this.getPage(pageNo, true, {
					callback: function(success, result) {
						if (success) {
							var entry = result.first;
							while (entry && entry.data.state == dorado.Entity.STATE_DELETED) {
								entry = entry.next;
							}
							var entity = (entry) ? entry.data : null;
							if (entity) self.setCurrent(entity);
						}
						$callback(callback, success, result);
					}
				});
			} else {
				var entry = this.getPage(pageNo, true).first;
				while (entry && entry.data.state == dorado.Entity.STATE_DELETED) {
					entry = entry.next;
				}
				var entity = (entry) ? entry.data : null;
				if (entity) this.setCurrent(entity); 
				return entity;
			}
		},
		
		/**
		 * 将实体集合翻到第一页。
		 * <p>
		 * 此方法有两种执行方式，如果不指定callback参数将按照同步模式执行，如果指定了具体的callback则按照异步模式运行。
		 * </p>
		 * @param {Function|dorado.Callback} [callback] 回调对象，传入回调对象的参数即为新的页。
		 */
		firstPage: function(callback) {
			this.gotoPage(1, callback);
		},
		
		/**
		 * 将实体集合向前翻一页。
		 * <p>
		 * 此方法有两种执行方式，如果不指定callback参数将按照同步模式执行，如果指定了具体的callback则按照异步模式运行。
		 * </p>
		 * @param {Function|dorado.Callback} [callback] 回调对象，传入回调对象的参数即为新的页。
		 */
		previousPage: function(callback) {
			if (this.pageNo <= 1) return;
			this.gotoPage(this.pageNo - 1, callback);
		},
		
		/**
		 * 将实体集合向后翻一页。
		 * <p>
		 * 此方法有两种执行方式，如果不指定callback参数将按照同步模式执行，如果指定了具体的callback则按照异步模式运行。
		 * </p>
		 * @param {Function|dorado.Callback} [callback] 回调对象，传入回调对象的参数即为新的页。
		 */
		nextPage: function(callback) {
			if (this.pageNo >= this.pageCount) return;
			this.gotoPage(this.pageNo + 1, callback);
		},
		
		/**
		 * 将实体集合翻到最后一页。
		 * <p>
		 * 此方法有两种执行方式，如果不指定callback参数将按照同步模式执行，如果指定了具体的callback则按照异步模式运行。
		 * </p>
		 * @param {Function|dorado.Callback} [callback] 回调对象，传入回调对象的参数即为新的页。
		 */
		lastPage: function(callback) {
			this.gotoPage(this.pageCount, callback);
		},
		
		changeEntityCount: function(page, num) {
			page.entityCount += num;
			this.entityCount += num;
		},
		
		/**
		 * 返回某实体集合是否为空。
		 * @return {boolean} 是否是空。
		 */
		isEmpty: function() {
			return this.entityCount == 0;
		},
		
		/*
		 * insert或remove的时候需要调用此函数,用于清空父属性的required为true,且数据类型为EntityList的propertyInfo信息
		 */
		_doEmptyParentPropertyInfo: function(entity, mode) {
			var parent = entity.parent;
			if (parent != null && parent instanceof dorado.EntityList && parent.parent!=null && parent.parent instanceof dorado.Entity){
				var parentProperty = parent.parentProperty;
				var parentPropertyDef = parent.parent.getPropertyDef(parentProperty);
				if (parentPropertyDef && parentPropertyDef._required){
					if (mode == "insert" || (mode == "remove" && parent.entityCount == 0)){
						var propertyInfoMap = parent.parent._propertyInfoMap, propertyInfo = propertyInfoMap[parentProperty];
						if (propertyInfo) propertyInfoMap[parentProperty] = propertyInfo = {};
					}
				}
			}
		},

		/**
		 * 向集合中插入一个数据实体。
		 * @param {dorado.Entity|Object} entity {optional} 要插入的数据实体或数据实体对应的JSON数据对象。
		 * 如果不指定此参数或设置其值为null，EntityList会自动根据elementDataType来创建一个新的数据实体并插入。
		 * @param {String} [insertMode] 插入方式，包含下列四种取值：
		 * <ul>
		 * <li>begin - 在集合的起始位置插入。</li>
		 * <li>before - 在refEntity参数指定的数据实体之前插入。</li>
		 * <li>after - 在refEntity参数指定的数据实体之后插入。</li>
		 * <li>end - 在集合的末尾插入。默认值。</li>
		 * </ul>
		 * @param {dorado.Entity} [refEntity] 插入位置的参照数据实体。
		 * @return 返回插入的数据实体。
		 */
		insert: function(entity, insertMode, refEntity) {
			if (entity == null) {
				entity = this.createChild(null, true);
			} else if (entity instanceof dorado.Entity) {
				if (entity.parent) {
					if (entity.parent instanceof dorado.EntityList) {
						entity.parent.remove(entity, true);
					} else {
						throw new dorado.ResourceException("dorado.data.ValueNotFree", "Entity");
					}
				}
			} else {
				entity = new dorado.Entity(entity, this.dataTypeRepository, this.elementDataType);
				child.alwaysTransferEntity = this.alwaysTransferEntity;
			}
			
			if (insertMode == "before" || insertMode == "after") {
				refEntity = refEntity || this.current;
				if (!refEntity) insertMode = (insertMode == "before") ? "begin" : "after";
			}
			var eventArg = {
				entityList: this,
				entity: entity,
				insertMode: insertMode,
				refEntity: refEntity,
				processDefault: true
			};
			
			var dataType = entity.dataType;
			if (dataType) dataType.fireEvent("beforeInsert", dataType, eventArg);
			if (!eventArg.processDefault) return;
			
			if (this.pageCount == 0 && this.pageNo == 1) this.pageCount = 1;
			var page = this.getPage(this.pageNo, true);
			page.insert(entity, insertMode, refEntity);
			if (entity.state != dorado.Entity.STATE_DELETED) this.changeEntityCount(page, 1);
			if (entity.state != dorado.Entity.STATE_MOVED) entity.setState(dorado.Entity.STATE_NEW);
			this.timestamp = dorado.Core.getTimestamp();
			this._doEmptyParentPropertyInfo(entity, "insert");
			if (this.isNull) delete this.isNull;
			
			if (dataType) dataType.fireEvent("onInsert", dataType, eventArg);
			this.sendMessage(dorado.EntityList._MESSAGE_INSERTED, eventArg);
			
			this.setCurrent(entity);
			return entity;
		},

		/**
		 * 从集合中删除一个数据实体。
		 * @param {dorado.Entity} [entity] 要删除的数据实体，如果此参数为空则表示将要删除集合中的当前数据实体。
		 * @param {boolean} [detach] 是否彻底断开被删除的数据实体与集合之间的关联。默认为不断开。<br>
		 * 在通常情况下，当我们从集合中删除一个数据实体时，dorado只是在内部处理中将数据实体的状态标记为已删除状态而并没有真正的将数据实体从合集中移除掉。
		 * 这样做的目的是为了便于在今后提交时能够清晰的掌握集合中的元素究竟做过哪些改变。
		 */
		remove: function(entity, detach) {
			if (!entity) {
				if (!this.current) this._throwNoCurrent();
				entity = this.current;
			}
			if (entity.parent != this) this._throwInvalidEntity();
			
			var eventArg = {
				entity: entity,
				entityList: this,
				processDefault: true
			};
			
			var dataType = entity.dataType, simpleDetach = (entity.state == dorado.Entity.STATE_DELETED);
			if (!simpleDetach) {
				if (dataType) dataType.fireEvent("beforeRemove", dataType, eventArg);
				if (!eventArg.processDefault) return;
			}
			
			var isCurrent = (this.current == entity);
			var newCurrent = null;
			if (isCurrent) {
				var entry = entity.page.findEntry(this.current);
				var newCurrentEntry = this._findNextEntry(entry);
				if (!newCurrentEntry) newCurrentEntry = this._findPreviousEntry(entry);
				if (newCurrentEntry) newCurrent = newCurrentEntry.data;
			}
			
			var page = entity.page;
			if (simpleDetach) {
				detach = true;
			} else {
				detach = detach || entity.state == dorado.Entity.STATE_NEW;
				if (!detach) entity.setState(dorado.Entity.STATE_DELETED);
			}
			if (detach) {
				if (entity.state != dorado.Entity.STATE_DELETED) this.changeEntityCount(page, -1);
			}
			
			this.timestamp = dorado.Core.getTimestamp();
			this._doEmptyParentPropertyInfo(entity, "remove");
			
			if (!simpleDetach) {
				if (dataType) dataType.fireEvent("onRemove", dataType, eventArg);
				this.sendMessage(dorado.EntityList._MESSAGE_DELETED, eventArg);
			}
			if (detach) page.remove(entity);
			
			if (isCurrent) this.setCurrent(newCurrent);
		},
		
		/**
		 * 创建并返回一个子实体对象。
		 * @param {Object} [data] 新创建的实体对象要封装JSON数据对象，可以不指定此参数。
		 * @param {boolean} [detached] 是否需要返回一个游离的实体对象。
		 * 默认情况下，新创建的子实体对象会直接被设置到集合中。
		 * 通过detached参数可以指定本方法不将新的子实体对象附着到本集合中。
		 * @return {dorado.Entity} 新创建的实体对象。
		 */
		createChild: function(data, detached) {
			var elementDataType = (this.dataType) ? this.dataType.getElementDataType() : null;
			if (elementDataType && !(elementDataType instanceof dorado.EntityDataType)) {
				throw new ResourceException("dorado.data.EntityPropertyExpected", property);
			}
			var child = new dorado.Entity(null, this.dataTypeRepository, elementDataType);
			child.alwaysTransferEntity = this.alwaysTransferEntity;
			if (data) child.set(data);
			if (!detached) this.insert(child);
			return child;
		},
		
		/**
		 * 根据传入的{@link dorado.Entity}的id返回匹配的数据实体对象。
		 * @param {Object} id 数据实体的id。
		 * @return {dorado.Entity} 匹配的数据实体对象。
		 */
		getById: function(id) {
			return this._keyMap[id];
		},
		
		_fillPage: function(page, jsonArray, changeCurrent, fireEvent) {
			page.entityCount = 0;
			
			if (jsonArray == null) return;
			if (!(jsonArray instanceof Array)) {
				if (jsonArray.$isWrapper) {
					var v = jsonArray.data;
					v.entityCount = jsonArray.entityCount;
					v.pageCount = jsonArray.pageCount;
					jsonArray = v;
				}
				if (!(jsonArray instanceof Array)) jsonArray = [jsonArray];
			}
			var entity, firstEntity;
			
			var dataType = this.dataType;
			if (dataType) dataType._disableObserversCounter++;
			this._disableObserversCounter++;
			dorado.EntityList.duringFillPage = (dorado.EntityList.duringFillPage || 0) + 1;
			try {
				var elementDataType = this.elementDataType, eventArg;
				if (fireEvent && elementDataType != null) eventArg = {};
				
				for (var i = 0; i < jsonArray.length; i++) {
					var json = jsonArray[i];
					if (json instanceof dorado.Entity && json.parent) {
						if (json.parent instanceof dorado.EntityList) {
							json.parent.remove(json, true);
						} else {
							throw new dorado.ResourceException("dorado.data.ValueNotFree", "Entity");
						}
					}
					
					if (elementDataType != null) {
						entity = elementDataType.parse(json);
						entity.alwaysTransferEntity = this.alwaysTransferEntity;
					} else {
						var oldProcessDefaultValue = SHOULD_PROCESS_DEFAULT_VALUE;
						SHOULD_PROCESS_DEFAULT_VALUE = false;
						try {
							entity = new dorado.Entity(json, (this.dataType) ? this.dataType.get("dataTypeRepository") : null);
							entity.alwaysTransferEntity = this.alwaysTransferEntity;
						}
						finally {
							SHOULD_PROCESS_DEFAULT_VALUE = oldProcessDefaultValue;
						}
					}
					
					page.insert(entity);
					if (entity.state != dorado.Entity.STATE_DELETED) {
						page.entityCount++;
						this.entityCount++;
						if (!firstEntity) firstEntity = entity;
						
						if (fireEvent && elementDataType != null) {
							eventArg.entity = entity;
							elementDataType.fireEvent("onEntityLoad", elementDataType, eventArg);
						}
					}
				}
				
				if (jsonArray.entityCount) this.entityCount = jsonArray.entityCount;
				if (jsonArray.pageCount) this.pageCount = jsonArray.pageCount;
				
				if (changeCurrent && firstEntity) {
					this.setCurrent(firstEntity);
				}
			}
			finally {
				dorado.EntityList.duringFillPage--;
				this._disableObserversCounter--;
				if (dataType) dataType._disableObserversCounter--;
			}
			
			if (firstEntity) {
				this.timestamp = dorado.Core.getTimestamp();
				this.sendMessage(0);
			}
		},
		
		/**
		 * 取消对当前数据实体集合的各种数据操作。
		 * @param {boolean} deep 是否执行深度撤销。即一并撤销所有子实体（包括子实体中的子实体）的修改。
		 */
		cancel: function(deep) {
			var it = this.iterator(true), changed = false;
			while (it.hasNext()) {
				var entity = it.next();
				if (entity.state != dorado.Entity.STATE_NONE && entity.state != dorado.Entity.STATE_MOVED) {
					entity.disableObservers();
					entity.cancel(deep);
					entity.enableObservers();
					changed = true;
				}
			}
			if (changed) {
				this.timestamp = dorado.Core.getTimestamp();
				this.sendMessage(0);
			}
		},
		
		/**
		 * 清空集合中的所有数据。
		 */
		clear: function() {
			this._keyMap = {};
			
			this._pages.clear();
			page = new dorado.EntityList.Page(this, 1);
			page.loaded = true;
			this._pages.insert(page);
			
			this.pageNo = 1;
			this.pageCount = 1;
			this.entityCount = 0;
			this.current = null;
			this.timestamp = dorado.Core.getTimestamp();
			this.sendMessage(0);
		},
		
		/**
		 * 清空集合中的所有数据并重新装载当前页中的数据。
		 */
		flush: function(callback) {
			function clear() {
				this._keyMap = {};				
				this._pages.clear();				
				this.timestamp = dorado.Core.getTimestamp();
			}

			clear.call(this);
			
			if (callback) {
				var self = this;
				
				this.getPage(this.pageNo, true, {
					callback: function(success, page) {
						self._disableObserversCounter++;
						try {
							if (success) {
								var entity = (page.first) ? page.first.data : null;
								self.setCurrent(entity);
								$callback(callback, true, null);
							}
						}
						finally {
							self._disableObserversCounter--;
							self.sendMessage(0);
						}
					}
				});
			} else {
				var entry = this.getPage(this.pageNo, true).first;
				var entity = (entry) ? entry.data : null;
				this._disableObserversCounter++;
				try {
					this.setCurrent(entity);
				}
				finally {
					this._disableObserversCounter--;
					this.sendMessage(0);
				}
			}
		},
		
		/**
		 * 清空集合中的所有数据并以异步方式重新装载当前页中的数据。
		 * @param {Function|dorado.Callback} callback 回调对象。
		 */
		flushAsync: function(callback) {
			this.flush(callback);
		},
		
		/**
		 * 将给定的JSON对象中的数据转换成为数据实体并添加到集合中。
		 * @param {Object[]|Object} json 要转换的JSON对象。<br>
		 * 如果此处传入的是一个数组，那么数组中的对象会被逐一意添加到集合中; 如果传入的单个的对象，那么该对象会被作为一个元素添加到集合中。
		 */
		fromJSON: function(json) {
			var jsonArray = (json.$isWrapper) ? json.data : json;
			if (json.pageNo) this.pageNo = json.pageNo;
			if (this.pageCount == 0) {
				if (json.pageCount) {
					this.pageCount = json.pageCount;
				} else if (this.pageNo == 1) {
					this.pageCount = 1;
				}
			}
			var page = this.getPage(this.pageNo, true);
			this._fillPage(page, jsonArray, true);
            if (this.entityCount > 0){
                if (this.isNull) delete this.isNull;
            }
		},
		
		/**
		 * 将实体集合转换成一个JSON数组。
		 * @param {Object} [options] 转换选项。
		 * @param {String[]} [options.properties] 属性名数组，表示只转换该数组中列举过的属性。如果不指定此属性表示转换实体对象中的所有属性。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * @param {boolean} [options.includeReferenceProperties=true] 是否转换实体对象中{@link dorado.Reference}类型的属性。默认按true进行处理。
		 * @param {String} [options.loadMode="never"] 数据装载模式，此属性仅在options.includeReferenceProperties=true为true时有效。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的延时数据。</li>
		 * <li>auto	-	如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 * <li>never	-	不会激活数据装载过程，直接返回数据的当前值。</li>
		 * </ul>
		 * @param {boolean} [options.includeUnloadPage] 是否转换{@link dorado.EntityList}中尚未装载的页中的数据。默认按true进行处理。
		 * @param {boolean} [options.includeDeletedEntity] 是否转换那些被标记为"已删除"的数据实体。
		 * @param {boolean} [options.simplePropertyOnly] 是否只生成简单类型的属性到JSON中。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * @param {boolean} [options.generateDataType] 是否在JSON对象中生成DataType信息，生成的DataType信息将被放置在名为$dataType的特殊子属性中。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * 另外，此属性的只对集合中的第一个JSON对象有效，即dorado认为集合中的所有{@link dorado.Entity}的DataType都是相同的，因此不必为每一个{@link dorado.Entity}生成DataType信息。
		 * @param {boolean} [options.generateState] 是否在JSON对象中生成实体对象的状态信息(即新增、已更改等状态)，生成的状态信息将被放置在名为$state的特殊子属性中。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * @param {boolean} [options.generateEntityId] 是否在JSON对象中生成实体对象的ID，生成的状态信息将被放置在名为$entityId的特殊子属性中。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * @param {boolean} [options.generateOldData] 是否在JSON对象中生成旧数据，生成的状态信息将被放置在名为$oldData的特殊子属性中。
		 * 此属性对于{@link dorado.EntityList}的toJSON而言是没有意义的，但是由于options参数会自动被传递到集合中{@link dorado.Entity}的toJSON方法中，
		 * 因此它会影响内部{@link dorado.Entity}的处理过程。
		 * @param {Function} [options.entityFilter] 用户自定义的数据实体过滤函数，返回true/false表示是否需要将此当前数据实体转换到JSON中。
		 * 此函数的传入参数如下：
		 * @param {dorado.Entity} [options.entityFilter.entity] 当前正被过滤的数据实体。
		 * @return {Object[]|Object} 得到的JSON数组。
		 * <p>
		 * 如果generateDataType选项为true，那么此方法有可能返回一个JSON对象而不是数组，以便于附加DataType这样的信息。
		 * </p>
		 */
		toJSON: function(options, context) {
			if (this.isNull) return null;
			
			var result = [];
			var generateDataType = (options) ? options.generateDataType : false;
			var entityFilter = (options) ? options.entityFilter : null;
			var it = this.iterator(options);
			while (it.hasNext()) {
				var entity = it.next();
				if (entity) {
					if (!entityFilter || entityFilter(entity)) {
						result.push(entity.toJSON(options, context));
					}
				} else {
					result.push(null);
				}
			}
			if (result.length == 0 && entityFilter) result = null;
			if (generateDataType && result && this.dataType) {
				result = {
					$isWrapper: true,
					$dataType: this.dataType._id,
					data: result
				};
			}
			return result;
		},
		
		/**
		 * 返回包含所有数据实体的数组。
		 * <p>
		 * 注意：返回的数组中将只包含当前已下载到客户端的数据实体。
		 * </p>
		 * @return {Object[]} 得到的Entity数组。
		 */
		toArray: function() {
			var result = [];
			this.each(function(entity) {
				result.push(entity);
			});
			return result;
		},
		
		/**
		 * 将所有数据实体转换成代理对象并放置到一个数组中。
		 * @param {Object} [options] 转换选项。
		 * @return {Object} 得到的代理对象数组。
		 * @see dorado.Entity#getWrapper
		 */
		getWrapper: function(options) {
			var result = [];
			this.each(function(entity) {
				result.push(entity.getWrapper(options));
			});
			return result;
		},
		
		/**
		 * 针对集合的每一个数据实体执行指定的函数。此方法可用于替代对集合的遍历代码。
		 * @param {Function} fn 针对每一个数据实体的函数。
		 * @param {Object} [scope] 函数脚本的宿主，即函数脚本中this的含义。如果此参数为空则表示this为集合中的某个数据实体。
		 *
		 * @example
		 * // 将每一个集合元素的name属性连接成为一个字符串
		 * var names = "";
		 * var entityList = ...
		 * entityList.each(function(entity){
		 *	 names += entity.get("name");
		 * });
		 */
		each: function(fn, scope) {
			var it = this.iterator(), entity;
			while (it.hasNext()) {
				entity = it.next();
				if (fn.call(scope || entity, entity) === false) {
					break;
				}
			}
		},
		
		/**
		 * 返回数据实体的迭代器。
		 * @param {Object|boolean} [options] 迭代选项。
		 * 此参数具有两种设定方式，当直接传入逻辑值true/false时，dorado会将此逻辑值直接认为是针对上述includeDeletedEntity子属性的值；
		 * 当传入的是一个对象时，dorado将尝试识别该对象子属性。
		 * @param {boolean} [options.includeDeletedEntity] 是否迭代被标记已删除的数据。
		 * @param {boolean} [options.includeUnloadPage] 是否迭代目前尚未下载的页中的数据。
		 * 如果选择是，那么迭代的过程将引起集合自动装载那些尚未下载页。
		 * @param {int} [options.nextIndex] 从第几个数据实体开始迭代。
		 * @param {int} [options.pageNo] 只遍历指定页号中的数据。从1开始的数字。
		 * @param {boolean} [options.currentPage] 只遍历当前页号中的数据。
		 * @param {boolean} [options.simulateUnloadPage] 是否对为未下载的页进行模拟遍历。
		 * 在模拟遍历的过程中，迭代器将返回一个虚假的dorado.Entity实例代替未下载页中的某个数据实体。
		 * 当启用此选项时，迭代器将在迭代过程中模拟出那些尚未下载的数据实体，但不会在迭代过程中引起实际的数据装载。
		 * @return {dorado.util.Iterator} 数据实体的迭代器。
		 */
		iterator: function(options) {
			return new dorado.EntityList.EntityListIterator(this, options);
		},
		
		toText: function() {
			return this.toString();
		},
		
		toString: function() {
			return "EntityList@" + this.objId + "(" + this.entityCount + ")";
		},
		
		clone: function(deep) {
			if (this.isNull) return null;
			
			var cloned = new dorado.EntityList(null, this.dataTypeRepository, this.dataType);
			cloned.alwaysTransferEntity = this.alwaysTransferEntity;
			for (var it = this.iterator(); it.hasNext();) {
				var entity = it.next();
				if (deep) entity = dorado.Core.clone(entity, deep);
				cloned.insert(entity);
			}
			return cloned;
		}
	});
	
	var Page = dorado.EntityList.Page = $extend(dorado.util.KeyedList, {
		$className: "dorado.EntityList.Page",
		
		constructor: function(entityList, pageNo) {
			$invokeSuper.call(this, [(function(entity) {
				return entity.entityId;
			})]);
			
			this.entityList = entityList;
			this.pageNo = pageNo;
			this.entityCount = entityList.pageSize;
			this.id = pageNo; // for KeyedList
		},
		
		insert: function(data, insertMode, refData) {
			$invokeSuper.call(this, [data, insertMode, refData]);
			data.page = this;
			data.parent = this.entityList;
			data._setObserver(this.entityList._observer);
			this.entityList._keyMap[data.entityId] = data;
			this.loaded = true;
		},
		
		remove: function(data) {
			$invokeSuper.call(this, [data]);
			data.parent = null;
			data.page = null;
			data._setObserver(null);
			delete this.entityList._keyMap[data.entityId];
		},
		
		each: function(fn, scope) {
			var entry = this.first, i = 0;
			while (entry != null) {
				var entity = entry.data;
				if (entity && entity.state != dorado.Entity.STATE_DELETED) {
					if (fn.call(scope || entity, entity, i++) === false) {
						break;
					}
				}
				entry = entry.next;
			}
		}
	});
	
	dorado.EntityList.EntityListIterator = $extend(dorado.util.Iterator, {
		$className: "dorado.EntityList.EntityListIterator",
		
		constructor: function(entityList, options) {
			this._entityList = entityList;
			if (options === true) {
				this._includeDeletedEntity = true;
			} else if (options instanceof Object) {
				this._includeDeletedEntity = options.includeDeletedEntity;
				this._includeUnloadPage = options.includeUnloadPage;
				this._nextIndex = options.nextIndex;
				this._fixedPageNo = options.pageNo;
				if (!this._fixedPageNo && options.currentPage) this._fixedPageNo = entityList.pageNo;
				this._simulateUnloadPage = options.simulateUnloadPage;
				if (this._simulateUnloadPage) this._includeUnloadPage = true;
			}
			this.firstOrLast();
		},
		
		firstOrLast: function(reverse) {
			var entityList = this._entityList;
			
			var it, page, pageNo = 0;
			if (!this._fixedPageNo) {
				it = entityList._pages.iterator();
				if (reverse) it.last();
			}
			else {
				pageNo = this._fixedPageNo;
			}
			
			if (this._nextIndex) {
				var skiped = 0;
				if (!this._fixedPageNo) {
					var tempPage;
					while (reverse ? it.hasPrevious() : it.hasNext()) {
						tempPage = reverse ? it.previous() : it.next();
						if (tempPage.loaded || this._includeUnloadPage) {
							skiped += tempPage.entityCount;
							if ((skiped + tempPage.entityCount) > this._nextIndex) {
								skiped -= tempPage.entityCount;
								break;
							}
						}
					}
					
					if (tempPage) {
						page = tempPage;
						pageNo = page.pageNo;
					}
				}

				if (pageNo) {
					this._previous = this._next = this._findFromPage(pageNo);
					if (this._next && skiped < this._nextIndex) {					
						for (var i = skiped; i < this._nextIndex; i++) {
							if (this.hasNext()) this.next();
							else break;
						}
					}
				}
				delete this._nextIndex;
			} else {
				if (!this._fixedPageNo) {
					var tempPage;
					while (reverse ? it.hasPrevious() : it.hasNext()) {
						tempPage = reverse ? it.previous() : it.next();
						if (tempPage.loaded || this._includeUnloadPage) {
							page = tempPage;
							pageNo = page.pageNo;
							break;
						}
					}
				}
				
				if (pageNo) {
					var result = this._findFromPage(pageNo, reverse);
					if (reverse) {
						this._previous = result;
					} else {
						this._next = result;
					}
				}
			}
		},
		
		_findFromPage: function(pageNo, reverse) {
			var result = null, entityList = this._entityList, pageCount = entityList.pageCount;
			
			// 如果simulateUnloadPage为true，那么includeUnloadPage一定也是true
			var page = entityList.getPage(pageNo, !this._simulateUnloadPage);
			
			if (page && page.loaded) {
				var entry = reverse ? page.last : page.first;
				while (entry) {
					if (this._includeDeletedEntity || entry.data.state !== dorado.Entity.STATE_DELETED) {
						result = entry;
						break;
					}
					entry = reverse ? entry.previous : entry.next;
				}
			} else {
				result = {
					data: dorado.Entity.getDummyEntity(pageNo)
				};
				var entityList = this._entityList;
				this._simulatePageSize = (pageNo == pageCount) ? (entityList.entityCount % entityList.pageSize) : entityList.pageSize;
				this._simulateIndex = (reverse) ? this._simulatePageSize : 0;
			}
			return result;
		},
		
		_findNeighbor: function(entry, pageNo, reverse) {
			if (!entry) return null;
			
			var oldEntry = entry;
			if (entry.data && !entry.data.dummy) {
				do {
					entry = reverse ? entry.previous : entry.next;
					if (entry && (this._includeDeletedEntity || entry.data.state !== dorado.Entity.STATE_DELETED)) {
						break;
					}
				}
				while (entry);
			} else {
				var inc = reverse ? -1 : 1;
				this._simulateIndex += inc;
				if (this._simulateIndex < 0 || this._simulateIndex >= this._simulatePageSize) {
					this._simulateIndex -= inc;
					entry = null;
				}
			}
			
			if (entry == null && !this._fixedPageNo) {
				if (this._includeUnloadPage) {
					pageNo += (reverse ? -1 : 1);
					if (pageNo > 0 && pageNo <= this._entityList.pageCount) {
						entry = this._findFromPage(pageNo, reverse);
					}
				}
				else {
					var entityList = this._entityList, page = oldEntry.data.page;
					var entry = entityList._pages.findEntry(page);
					if (entry) {
						entry = (reverse ? entry.previous : entry.next);
						if (entry) {
							page = entry.data;
							if (page.loaded) {
								entry = this._findFromPage(page.pageNo, reverse);
							}
						}
					}
				}
			}
			return entry;
		},
		
		_find: function(reverse) {
			var fromEntry = reverse ? this._previous : this._next;
			var result = this._findNeighbor(fromEntry, fromEntry.data.page.pageNo, reverse);
			if (reverse) {
				this._next = this._current;
				this._current = this._previous;
				this._previous = result;
			} else {
				this._previous = this._current;
				this._current = this._next;
				this._next = result;
			}
		},
		
		first: function() {
			this.firstOrLast();
		},
		
		last: function() {
			this.firstOrLast(true);
		},
		
		hasPrevious: function() {
			return !!this._previous;
		},
		
		hasNext: function() {
			return !!this._next;
		},
		
		previous: function() {
			if (!this._previous) {
				this._next = this._current;
				this._current = this._previous = null;
				return null;
			}
			var data = this._previous.data;
			this._find(true);
			return data;
		},
		
		next: function() {
			if (!this._next) {
				this._previous = this._current;
				this._current = this._next = null;
				return null;
			}
			var data = this._next.data;
			this._find(false);
			return data;
		},
		
		current: function() {
			return (this._current) ? this._current.data : null;
		},
		
		createBookmark: function() {
			return {
				previous: this._previous,
				current: this._current,
				next: this._next,
				simulateIndex: this._simulateIndex,
				simulatePageSize: this._simulatePageSize
			};
		},
		
		restoreBookmark: function(bookmark) {
			this._previous = bookmark.previous;
			this._current = bookmark.current;
			this._next = bookmark.next;
			this._simulateIndex = bookmark.simulateIndex;
			this._simulatePageSize = bookmark.simulatePageSize;
		}
	});
	
	LoadPagePipe = $extend(dorado.DataPipe, {
		shouldFireEvent: false,
		
		constructor: function(entityList, pageNo) {
			this.entityList = entityList;
			var dataType = entityList.dataType, view;
			if (dataType) {
				var dataTypeRepository = dataType.get("dataTypeRepository");
				this.dataTypeRepository = dataTypeRepository;
				view = dataTypeRepository ? dataTypeRepository._view : null;
			}
			
			this.dataProviderArg = {
				parameter: entityList.parameter,
				sysParameter: entityList.sysParameter,
				pageSize: entityList.pageSize,
				pageNo: pageNo,
				dataType: dataType,
				view: view
			};
		},
		
		doGet: function() {
			return this.invokeDataProvider(false);
		},
		
		doGetAsync: function(callback) {
			this.invokeDataProvider(true, callback);
		},
		
		invokeDataProvider: function(async, callback) {
			var dataProvider = this.entityList.dataProvider, dataProviderArg = this.dataProviderArg, oldSupportsEntity = dataProvider.supportsEntity;
			dataProvider.supportsEntity = false;
			dataProvider.shouldFireEvent = this.shouldFireEvent;
			try {
				var callbackWrapper = {
					callback: function(success, result) {
						if (callback) $callback(callback, success, result);
					}
				}
				
				if (async) {
					dataProvider.getResultAsync(dataProviderArg, callbackWrapper);
				} else {
					var result = dataProvider.getResult(dataProviderArg);
					$callback(callbackWrapper, true, result);
					return result;
				}
			}
			finally {
				dataProvider.supportsEntity = oldSupportsEntity;
			}
		}
	});
	
	dorado.EntityList._MESSAGE_CURRENT_CHANGED = 20;
	dorado.EntityList._MESSAGE_DELETED = 21;
	dorado.EntityList._MESSAGE_INSERTED = 22;
	
}());

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	var BREAK_ALL = {};
	var BREAK_LEVEL = {};
	var ENTITY_PATH_CACHE = {};

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 数据路径的处理器。
	 * <p>
	 * 数据路径表达式是用于描述如何提取、挖掘数据的表达式。其作用比较类似于XML中所使用的XPath。
	 * </p>
	 * <p>
	 * 以具有以下结构的EntityList+Entity数据为例，其中包含Department和Employee两种实体类型，其中Department支持递归嵌套:
	 * <pre class="symbol-example code">
	 * <code class="javascript">
	 * [
	 * {
	 * 	id: "D1",
	 * 	name: "XX部1",
	 * 	departments: [
	 * 		{
	 * 			id: "D11",
	 * 			name: "XX部2",
	 * 			employees: [
	 * 				{
	 * 					id: "0001",
	 * 					name: "John",
	 * 					sex: "male",
	 * 					salary: 5000
	 * 				},
	 * 				...
	 * 			]
	 * 		},
	 * 		...
	 * 	]
	 * },
	 * ...
	 * ]
	 * </code>
	 * </pre>
	 * </p>
	 * <p>
	 * 基本结构说明：属性名1(参数1,参数2,..)[逻辑表达式1,逻辑表达式2,..].属性名2(参数1,参数,..2)[逻辑表达式1,逻辑表达式2,..].属性名n..<br>
	 * 符号说明:
	 * <ul>
	 * <li>. - 用于分隔不同层级间对象的属性。例如:<code>employee.id</code>表示employee子对象的id属性。</li>
	 * <li>* - 用于表示某一层级中所有的对象，一般仅用于表示顶层集合中的对象，且可以省略。例如:<code>*.id</code>表示所有顶层对象的id属性。</li>
	 * <li>() - 用于定义一组表达式执行参数，多个参数之间以","分割。目前支持的参数包括：
	 * <ul>
	 * <li>repeat - 重复的执行当前的表达式片段直到无法找到更多的子对象为止。可简写为"R"。</li>
	 * <li>leaf - 重复的执行当前的表达式片段找出所有的叶子对象。可简写为"L"。</li>
	 * <li>数字 - 表示仅返回找到的前n个对象。</li>
	 * </ul>
	 * 例如:<code>.employees(repeat)</code>或<code>.employees(R)</code>表示所有employees属性中的对象的集合，这些对象会被提取出来被平行的放置到一个返回的数组中。
	 * </li>
	 * <li>@ - 用于逻辑表达式中，表示当前正被过滤的数据对象。</li>
	 * <li>[] - 用于定义一组逻辑表达式以对数据进行过滤，其中如果要定义多个逻辑表达式可以以","进行区隔。
	 * 例如:<code>employees[@.get("sex")=="male"]</code>表示筛选出性别为男性的员工。</li>
	 * <li>#current等 - 一种特殊的逻辑表达式，用于声明对Entity对象的过滤方式。具有如下几种取值:
	 * <ul>
	 * <li>#current - 表示集合中的当前Entity对象。</li>
	 * <li>#dirty - 表示集合中所有在客户端被改变过的（包含被删除的）Entity对象。</li>
	 * <li>#none - 表示集合中所有在客户端未被改变过的Entity对象。</li>
	 * <li>#all - 表示集合中所有状态的（包含被删除的）Entity对象。</li>
	 * <li>#new - 表示集合中所有在客户端新增的Entity对象。</li>
	 * <li>#modified - 表示集合中所有在客户端被修改过的Entity对象。</li>
	 * <li>#deleted - 表示集合中所有在客户端被标记为已删除的Entity对象。</li>
	 * <li>#move - 表示集合中所有在客户端被标记为已被移动的Entity对象。</li>
	 * </ul>
	 * 例如:<code>employees[#current]</code>表示返回employees集合中的当前Employee对象。
	 * </li>
	 * <li># - #current的简式。例如<code>#employees</code>与<code>employees[#current]</code>具有完全相同的语义。</li>
	 * <li>! - 表示后面是一段自定义的数据路径片段。例如<code>!CURRENT_NODE.children</code>中的CURRENT_NODE就是一个自定义片段。
	 * 见{@link dorado.DataPath.registerInterceptor}的说明。</li>
	 * </ul>
	 * </p>
	 * <p>
	 * 更多的表达式示例：
	 * <ul>
	 * <li>null - 相当于直接返回被查询的数据。表示顶层集合中所有的（不包含被删除的）Department。</li>
	 * <li>* - 同上。</li>
	 * <li># - 表示顶层集合中的当前Department。 </li>
	 * <li>[#current] - 同上。</li>
	 * <li>[#dirty] - 表示顶层集合中所有在客户端被改变过的（包含被删除的）Department。 </li>
	 * <li>#.employees - 表示顶层集合中当前Department中所有的Employee。</li>
	 * <li>#.#employees - 表示顶层集合中当前Department中的当前Employee。 </li>
	 * <li>#.#departments.#employees -
	 * 表示顶层集合中当前Department中的当前Department中的当前Employee。 </li>
	 * <li>*.departments - 表示所有第二层的Department。 </li>
	 * <li>.departments - 同上。 </li>
	 * <li>departments(repeat) -
	 * 表示所有Department的集合。注意：示例数据的顶层是一个集合，而在正常情况下是不能利用表达式来获取集合属性的。除非当一个具有repeat或leaf特性的表达式片段被应用于顶层集合时。引擎允许这样的特例，在此种情况下引擎会暂时忽略表达式片段中的属性名。</li>
	 * <li>.departments(R) - 表示除顶层Department外所有其它Department的集合。 </li>
	 * <li>.#departments(R) - 表示除顶层Department外所有其它各层中当前Department的集合。</li>
	 * <li>#departments(R) - 表示各层当前Department的集合。 </li>
	 * <li>#departments(leaf) -
	 * 表示最末端的当前Department。即通过不断的尝试获取当前Department中的当前Department，直到最末端那个Department。
	 * </li>
	 * <li>#departments(L) - 同上。</li>
	 * <li>#departments(L).#employees -
	 * 表示最末端的当前Department中的当前Employee。此表达式返回的结果是所有匹配Employee组成的数组。 </li>
	 * <li>.employees(R) - 表示所有employees属性中的对象的集合，即所有的Employee对象。</li>
	 * <li>.#employees(R) -
	 * 表示所有Department中的当前Employee，将以数组的形式返回这些Employee实体的集合。 </li>
	 * <li>.employees(R)[@.get("sex")=="male"] -
	 * 表示所有Department中的男性Employee，将以数组的形式返回这些Employee实体的集合。 </li>
	 * <li>.employees(R)[#dirty,@.get("sex")=="male"] -
	 * 表示所有Department中的状态为已修改的男性Employee，将以数组的形式返回这些Employee实体的集合。 </li>
	 * <li>.employees(R)[@.get("salary")>3500 && @.get("sex")=="male"] - 同上。
	 * </li>
	 * <li>.employees(R)[@.get("salary")>3500,@.get("sex")=="male"] -
	 * 表示所有Department中的薪水高于3500的男性Employee，将以数组的形式返回这些Employee实体的集合。 </li>
	 * <li>.employees(R).id - 表示返回所有Employee对象的id属性值的集合，即所有的Employee对象的id。</li>
	 * </ul>
	 * </p>
	 * @description 构造器。
	 * <p>
	 * 通常我们不建议您通过
	 * <pre class="symbol-example code">
	 * <code class="javascript">
	 * new dorado.DataPath("xxx");
	 * </code>
	 * </pre>
	 * 的方式来创建数据路径的处理器， 而应该用{@link dorado.DataPath.create}来代替。 这是因为用{@link dorado.DataPath.create}支持缓存功能，利用此方法来获得数据路径的处理器的效率往往更高。
	 * </p>
	 * @param {String} path 数据路径表达式。
	 * @see dorado.DataPath.create
	 */
	dorado.DataPath = $class(/** @scope dorado.DataPath.prototype */
	{

		$className : "dorado.DataPath",

		_VISIBLE : [{
			visibility : 0
		}],
		
		_ALL : [{
			visibility : 1
		}],

		_CURRENT : [{
			visibility : 2
		}],
		
		_REPEAT_VISIBLE : [{
			visibility : 0,
			repeat : true
		}],

		_REPEAT_ALL : [{
			visibility : 1,
			repeat : true
		}],

		constructor : function(path) {
			this.path = (path != null) ? $.trim(path) : path;
		},
		
		_throw : function(message, position) {
			var text = "DataPath syntax error";
			if(message) {
				text += (":\n" + message + "in:\n");
			} else {
				text += " in:\n";
			}

			var path = this.path;
			text += path;
			if(isFinite(position)) {
				position = parseInt(position);
				text += "\nat char " + position;
			}
			throw new SyntaxError(text);
		},
		
		/**
		 * 编译数据路径表达式。
		 * @throws {SyntaxError}
		 */
		compile : function() {

			function isUnsignedInteger(s) {
				return (s.search(/^[0-9]+$/) == 0);
			}

			var path = this.path;
			if(path == null || path == "" || path == "*") {
				this._compiledPath = this._VISIBLE;
				return;
			}
			if(path == "#" || path == "[#current]") {
				this._compiledPath = this._CURRENT;
				this._compiledPath.singleResult = true;
				return;
			}

			var _path = path.toLowerCase();
			if(_path == "(repeat)" || _path == "(r)") {
				this._compiledPath = this._REPEAT_VISIBLE;
				return;
			}

			var compiledPath = [];
			var property = "";
			var args = null;
			var arg;
			var conditions = null;
			var condition;

			var quotation = null;
			var inArgs = false;
			var afterArgs = false;
			var inCondition = false;
			var afterCondition = false;
			var escapeNext = false;

			// 对表达式的初次解析
			for(var i = 0; i < path.length; i++) {
				var c = path.charAt(i);
				if(escapeNext) {
					property += c;
					escapeNext = false;
					continue;
				}
				if(afterArgs && afterCondition && c != '.')
					this._throw(null, i);

				switch (c) {
					case '.': {
						if(!quotation && !inArgs && !inCondition) {
							compiledPath.push({
								property : property,
								args : args,
								conditions : conditions
							});
							property = "";
							args = null;
							arg = "";
							conditions = null;
							condition = "";
							c = null;
							quotation = null;
							inArgs = false;
							afterArgs = false;
							inCondition = false;
							afterCondition = false;
						}
						break;
					}
					case ',': {
						if(!inArgs && !inCondition)
							this._throw(null, i);

						if(!quotation) {
							if(inArgs) {
								args.push(arg);
								arg = "";
							} else if(inCondition) {
								conditions.push(condition);
								condition = "";
							}
							c = null;
						}
						break;
					}
					case '\'':
					case '"': {
						if(!inArgs && !inCondition)
							this._throw(null, i);

						if(!quotation) {
							quotation = c;
						} else if(quotation == c) {
							quotation = null;
						}
						break;
					}
					case '[': {
						if(inArgs || afterCondition)
							this._throw(null, i);

						if(!inCondition) {
							inCondition = true;
							conditions = [];
							condition = "";
							c = null;
						}
						break;
					}
					case ']': {
						if(inCondition) {
							if(condition.length > 0) {
								conditions.push(condition);
							}
							inCondition = false;
							afterCondition = true;
							c = null;
						} else {
							this._throw(null, i);
						}
						break;
					}
					case '(': {
						if(!inCondition) {
							if(inArgs || afterArgs)
								this._throw(null, i);
							inArgs = true;
							args = [];
							arg = "";
							c = null;
						}
						break;
					}
					case ')': {
						if(!inCondition && afterArgs)
							this._throw(null, i);

						if(inArgs) {
							if(arg.length > 0) {
								args.push(arg);
							}
							inArgs = false;
							afterArgs = true;
							c = null;
						}
						break;
					}
					case '@': {
						c = "$this";
						break;
					}
					default:
						escapeNext = (c == '\\');
				}

				if(!escapeNext && c != null) {
					if(inCondition) {
						condition += c;
					} else if(inArgs) {
						arg += c;
					} else {
						property += c;
					}
				}
			}

			if(property.length > 0 || (args && args.length > 0) || (conditions && conditions.length > 0)) {
				compiledPath.push({
					property : property,
					args : args,
					conditions : conditions
				});
			}

			// 对初次解析的结果进行整理
			var singleResult = (compiledPath.length > 0);
			for(var i = 0; i < compiledPath.length; i++) {
				var section = compiledPath[i];
				if((!section.property || section.property == '*') && !section.args && !section.conditions) {
					section = this._VISIBLE;
					compiledPath[i] = section;
					singleResult = false;
				} else {
					var property = section.property;
					if(property) {
						if(property.charAt(0) == '#') {
							section.visibility = 2;
							section.property = property = property.substring(1);
						}
						if(property.charAt(0) == '!') {
							section.visibility = 1; // all
							section.interceptor = property.substring(1);
						}
					}

					var args = section.args;
					if(args) {
						for(var j = 0; j < args.length; j++) {
							var arg = args[j].toLowerCase();
							if(arg == "r" || arg == "repeat") {
								section.repeat = true;
							} else if(arg == "l" || arg == "leaf") {
								section.repeat = true;
								section.leaf = true;
							} else if(isUnsignedInteger(arg)) {
								section.max = parseInt(arg);
							}
						}
					}

					var conditions = section.conditions;
					if(conditions) {
						for(var j = conditions.length - 1; j >= 0; j--) {
							var condition = conditions[j];
							if(condition && condition.charAt(0) == '#' && !(section.visibility > 0)) {
								if (condition == "#all") {
									section.visibility = 1;
								} else if (condition == "#current") {
									section.visibility = 2;
								} else if (condition == "#dirty") {
									section.visibility = 3;
								} else if (condition == "#new") {
									section.visibility = 4;
								} else if (condition == "#modified") {
									section.visibility = 5;
								} else if (condition == "#deleted") {
									section.visibility = 6;
								} else if (condition == "#moved") {
									section.visibility = 7;
								} else if (condition == "#none") {
									section.visibility = 8;
								} else if (condition == "#visible") {
									section.visibility = 9;
								} else {
									this._throw("Unknown token \"" + condition + "\".");
								}
								conditions.removeAt(j);
							}
						}
					}
					singleResult = (section.visibility == 2 && (section.leaf || !section.repeat));
				}
			}
			compiledPath.singleResult = singleResult;
			this._compiledPath = compiledPath;
		},
		
		_selectEntityIf : function(context, entity, isLeaf) {
			var section = context.section;
			if(!section.leaf || isLeaf) {
				var sections = context.sections;
				if(section == sections[sections.length - 1]) {
					context.addResult(entity);
				} else {
					this._evaluateSectionOnEntity(context, entity, true);
				}
			}
		},
		
		_evaluateSectionOnEntity : function(context, entity, nextSection) {
			var oldLevel = context.level;
			if(nextSection) {
				if(context.level >= (context.sections.length - 1)) {
					return;
				}
				context.setCurrentLevel(context.level + 1);
			}

			var oldLastSection = context.lastSection;
			var section = context.section;
			context.lastSection = section;
			try {
				var result;
				if(section.interceptor) {
					var interceptors = dorado.DataPath.interceptors[section.interceptor];
					if(interceptors && interceptors.dataInterceptor) {
						result = interceptors.dataInterceptor.call(this, entity, section.interceptor);
					} else {
						throw new dorado.Exception("DataPath interceptor \"" + section.interceptor + "\" not found.");
					}
				} else if(section.property) {
					if( entity instanceof dorado.Entity) {
						dorado.Entity.ALWAYS_RETURN_VALID_ENTITY_LIST = !section.leaf;
						try {
							result = entity.get(section.property, context.loadMode);
						} finally {
							dorado.Entity.ALWAYS_RETURN_VALID_ENTITY_LIST = true;
						}
					} else {
						result = entity[section.property];
					}
					if(result == null && section.leaf && section == oldLastSection) {
						this._selectEntityIf(context, entity, true);
					}
				} else {
					result = entity;
				}

				if( result instanceof dorado.EntityList || result instanceof Array) {
					this._evaluateSectionOnAggregation(context, result);
				} else if(result != null) {
					this._selectEntityIf(context, result);
					if(result != null && section.repeat) {
						this._evaluateSectionOnEntity(context, entity);
					}
				}
			} finally {
				context.lastSection = oldLastSection;
				context.setCurrentLevel(oldLevel);
			}
		},
		
		_evaluateSectionOnAggregation : function(context, entities, isRoot) {

			function selectEntityIf(entity) {
				var b = true;
				switch (section.visibility) {
					case 1:
						// all
						b = true;
						break;
					case 3:
						// dirty
						b = entity.state != dorado.Entity.STATE_NONE;
						break;
					case 4:
						// new
						b = entity.state == dorado.Entity.STATE_NEW;
						break;
					case 5:
						// modified
						b = entity.state == dorado.Entity.STATE_MODIFIED;
						break;
					case 6:
						// delete
						b = entity.state == dorado.Entity.STATE_DELETED;
						break;
					case 7:
						// moved
						b = entity.state == dorado.Entity.STATE_MOVED;
						break;
					case 8:
						// none
						b = entity.state == dorado.Entity.STATE_NONE;
						break;
					default:
						// visible
						b = entity.state != dorado.Entity.STATE_DELETED;
				}

				if(b) {
					var conditions = section.conditions;
					if(conditions) {
						var $this = entity;
						for(var i = 0; i < conditions.length; i++) {
							b = eval(conditions[i]);
							if(!b)
								break;
						}
					}
				}

				if(b) this._selectEntityIf(context, entity);
				if(section.repeat) {
					this._evaluateSectionOnEntity(context, entity);
				}
			}

			try {
				context.possibleMultiResult = true;
				var section = context.section;

				if(section.interceptor) {
					var interceptors = dorado.DataPath.interceptors[section.interceptor];
					if(interceptors && interceptors.dataInterceptor) {
						entities = interceptors.dataInterceptor.call(this, entities, section.interceptor);
						if(entities == null)
							return;
					} else {
						throw new dorado.Exception("DataPath interceptor \"" + section.interceptor + "\" not found.");
					}
				}

				if( entities instanceof dorado.EntityList || entities instanceof Array) {
					if(context.acceptAggregation && !(section.visibility > 0)/* VISIBLE */ && !section.conditions) {
						var sections = context.sections;
						if(section == sections[sections.length - 1]) {
							context.addResult(entities);
							throw BREAK_LEVEL;
						}
					}
				} else {
					entities = [entities];
				}

				if( entities instanceof dorado.EntityList) {
					if(section.visibility == 2) {// current
						if(entities.current)
							selectEntityIf.call(this, entities.current);
					} else {
						var includeDeleted = (section.visibility == 1/*all*/ || section.visibility == 3/*dirty*/ || section.visibility == 6/*delete*/);
						var it = entities.iterator(includeDeleted);
						while(it.hasNext()) {
							selectEntityIf.call(this, it.next());
						}
					}
				} else {
					for(var i = 0; i < entities.length; i++) {
						selectEntityIf.call(this, entities[i]);
					}
				}
			} catch (e) {
				if(e != BREAK_LEVEL) throw e;
			}
		},
		
		/**
		 * 针对传入的数据应用(执行)路径表达式，并返回表达式的执行结果。
		 * @param {Object} data 将被应用(执行)的数据。
		 * @param {boolean|Object} [options] 执行选项。
		 * <p>
		 * 此参数具有两种设定方式。当直接传入逻辑值true/false时，dorado会将此逻辑值直接认为是针对上述firstResultOnly子属性的值；
		 * 当传入的是一个对象时，dorado将尝试识别该对象中的其中子属性。
		 * </p>
		 * @param {boolean} [options.firstResultOnly] 是否只返回找到的第一个结果。
		 * @param {boolean} [options.acceptAggregation] 是否接受聚合型的结果对象。。
		 * 默认情况下，当DataPath的执行器得到一个聚合型的结果(即dorado.EntityList或Array类型的结)时，
		 * 会将其拆散，并将其中的结果压入DataPath的返回结果数组中。
		 * 如果指定了此属性为true，执行器将直接把得到的dorado.EntityList或Array压入DataPath的返回结果数组中。
		 * @param {String} [options.loadMode="always"] 数据装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的延时数据。</li>
		 * <li>auto	-	如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 * <li>never	-	不会激活数据装载过程，直接返回数据的当前值。</li>
		 * </ul>
		 * @return {dorado.Entity|dorado.EntityList|any} 表达式的执行结果。
		 */
		evaluate : function(data, options) {
			var firstResultOnly, acceptAggregation = false, loadMode;
			if(options === true) {
				firstResultOnly = options;
			} else if( options instanceof Object) {
				firstResultOnly = options.firstResultOnly;
				acceptAggregation = options.acceptAggregation;
				loadMode = options.loadMode;
			}
			loadMode = loadMode || "always";

			if(this._compiledPath === undefined) this.compile();
			firstResultOnly = firstResultOnly || this._compiledPath.singleResult;

			var context = new dorado.DataPathContext(this._compiledPath, firstResultOnly);
			context.acceptAggregation = acceptAggregation;
			context.loadMode = loadMode;
			context.possibleMultiResult = false;
			try {
				if(data != null) {
					if( data instanceof dorado.EntityList || data instanceof Array) {
						this._evaluateSectionOnAggregation(context, data, true);
					} else {
						this._evaluateSectionOnEntity(context, data);
					}
				}
				if(!context.possibleMultiResult && context.results) {
					if (context.results.length == 0) {
						context.results = null;
					}
					else if (context.results.length == 1) {
						context.results = context.results[0];
					}
				}
				return context.results;
			} catch (e) {
				if(e == BREAK_ALL) {
					return (firstResultOnly) ? context.result : context.results;
				} else {
					throw e;
				}
			}
		},
		
		/**
		 * 返回某数据路径所对应的子数据类型。
		 * @param {dorado.DataType} dataType 根数据类型。
		 * @param {boolean|Object} [options] 执行选项。
		 * <p>
		 * 此参数具有两种设定方式。当直接传入逻辑值true/false时，dorado会将此逻辑值直接认为是针对上述acceptAggregationDataType子属性的值；
		 * 当传入的是一个对象时，dorado将尝试识别该对象中的其中的子属性。
		 * </p>
		 * @param {boolean} [options.acceptAggregationDataType]  是否允许返回聚合类型。默认为不返回聚合类型。
		 * 如果设置为不允许返回聚合类型，那么当通过数据路径的计算最终得到一个聚合类型时，系统会尝试返回该聚合类型中聚合元素的数据类型。
		 * @param {String} [options.loadMode="always"] 数据类型装载模式。<br>
		 * 包含下列三种取值:
		 * <ul>
		 * <li>always	-	如果有需要总是装载尚未装载的延时数据。</li>
		 * <li>auto	-	如果有需要则自动启动异步的数据装载过程，但对于本次方法调用将返回数据的当前值。</li>
		 * <li>never	-	不会激活数据装载过程，直接返回数据的当前值。</li>
		 * </ul>
		 * @return {dorado.DataType} 子数据类型。
		 */
		getDataType : function(dataType, options) {
			if(!dataType) return null;

			var acceptAggregationDataType, loadMode;
			if(options === true) {
				acceptAggregationDataType = options;
			} else if( options instanceof Object) {
				acceptAggregationDataType = options.acceptAggregationDataType;
				loadMode = options.loadMode;
			}
			loadMode = loadMode || "always";

			var cache = dataType._subDataTypeCache;
			if(cache) {
				var dt = cache[this.path];
				if(dt !== undefined) {
					if(!acceptAggregationDataType && dt instanceof dorado.AggregationDataType) {
						dt = dt.getElementDataType(loadMode);
					}
					if( dt instanceof dorado.DataType)
						return dt;
				}
			} else {
				dataType._subDataTypeCache = cache = {};
			}

			if( dataType instanceof dorado.LazyLoadDataType) {
				dataType = dataType.get(loadMode);
			}

			if (this._compiledPath === undefined) {
				this.compile();
			}

			if (dataType) {
				var compiledPath = this._compiledPath;
				for (var i = 0; i < compiledPath.length; i++) {
					var section = compiledPath[i];
					
					if (section.interceptor) {
						var interceptors = dorado.DataPath.interceptors[section.interceptor];
						if (interceptors && interceptors.dataTypeInterceptor) {
							dataType = interceptors.dataTypeInterceptor.call(this, dataType, section.interceptor);
						} else {
							dataType = null;
						}
					} else if (section.property) {
						if (dataType instanceof dorado.AggregationDataType) {
							dataType = dataType.getElementDataType(loadMode);
						}
						var p = dataType.getPropertyDef(section.property);
						dataType = (p) ? p.get("dataType") : null;
					}
					if (!dataType) {
						break;
					}
				}
			}

			cache[this.path] = dataType;
			if(dataType instanceof dorado.AggregationDataType && (this._compiledPath.singleResult || !acceptAggregationDataType)) {
				dataType = dataType.getElementDataType(loadMode);
			}
			return dataType;
		},
		
		_section2Path : function(section) {
			var path = (section.visibility == 2) ? '#' : '';
			path += (section.property) ? section.property : '';

			var args = section.args;
			if(args && args.length > 0) {
				path += '(' + args.join(',') + ')';
			}

			var conditions = section.conditions;
			if(conditions && conditions.length > 0) {
				path += '[' + conditions.join(',') + ']';
			}
			return (path) ? path : '*';
		},
		
		_compiledPath2Path : function() {
			var compiledPath = this._compiledPath;
			var sections = [];
			for(var i = 0; i < compiledPath.length; i++) {
				sections.push(this._section2Path(compiledPath[i]));
			}
			return sections.join('.');
		},
		
		toString : function() {
			this.compile();
			return this._compiledPath2Path();
		}
	});

	/**
	 * 创建一个数据路径的处理器。
	 * @param {String} path 数据路径表达式。
	 * @return {dorado.DataPath} 数据路径的处理器。
	 */
	dorado.DataPath.create = function(path) {
		var key = path || "$EMPTY";
		var dataPath = ENTITY_PATH_CACHE[key];
		if(dataPath == null) ENTITY_PATH_CACHE[key] = dataPath = new dorado.DataPath(path);
		return dataPath;
	};
	
	/**
	 * 对给定数据应用(执行)路径表达式，并返回表达式的执行结果。
	 * @param {Object} data 将被应用(执行)的数据。
	 * @param {String} path 数据路径。
	 * @param {boolean|Object} [options] 执行选项。
	 * @return {dorado.Entity|dorado.EntityList|any} 表达式的执行结果。
	 * @see dorado.DataPath#evaluate
	 */
	dorado.DataPath.evaluate = function(data, path, options) {
		var dataPath = dorado.DataPath.create(path);
		return dataPath.evaluate();
	};

	dorado.DataPath.interceptors = {};

	/**
	 * 向系统中注册一个数据路径片段的拦截处理器，用以自定义某种片段的执行规则。
	 * <p>
	 * 自定义的片段在使用时须在前面加一个"!"作为标识。
	 * 例如我们注册了一个名为CURRENT_NODE的自定义片段，在实际编写数据路径时须这样使用<code>!CURRENT_NODE.children</code>。
	 * </p>
	 * @param {String} section 要拦截的片段。
	 * @param {Function} dataIntercetor 数据运算的拦截方法。
	 * 此方法支持如下两个参数：
	 * <ul>
	 * <li>data	-	{Object} 数据路径在运算时当前正在处理的数据。
	 * 例如对于#employees.!DESCRIPTION，由于在!DESCRIPTION之前的#employees的含义是当前Employee对象。
	 * 因此，当DESCRIPTION的拦截器被触发时，data参数的值就是当前Employee对象。</li>
	 * <li>section	-	{String} 当前正在处理的自定义数据路径片段。
	 * 仍以#employees.!DESCRIPTION为例，section参数的值应该是DESCRIPTION。</li>
	 * </ul>
	 * 此方法中的this关键字指向当前的dorado.DataPath实例。
	 * 此方法的返回值就是该自定义数据路径片段的执行结果。
	 * @param {Function} [dataTypeIntercetor] 数据类型运算的拦截方法。
	 * 见{@link dorado.DataPath#getDataType}的说明。
	 * 此方法支持如下两个参数：
	 * <ul>
	 * <li>dataType	-	{Object} 数据路径在运算时当前正在处理的数据类型。</li>
	 * <li>section	-	{String} 当前正在处理的自定义数据路径片段。</li>
	 * </ul>
	 * 此方法中的this关键字指向当前的dorado.DataPath实例。
	 * 此方法的返回值就是该自定义数据路径片段的执行结果。
	 *
	 * @example
	 * // 此例注册了一个自定义片段CURRENT_DIR，用于表示树状列表控件treeDir中当前选中的节点对应的数据。
	 * // 假设treeDir是一个棵用于显示文件目录的树。这样，!CURRENT_DIR.childFiles就可以表示当前选中的目录中的所有子文件的集合。
	 * dorado.DataPath.registerInterceptor("CURRENT_DIR", function() {
	 * 	var data = null, node = treeDir.get("currentNode");
	 * 	if (node) data = node.get("data");
	 * 	return data;
	 * }, function() {
	 * 	return dataTypeFile;
	 * });
	 */
	dorado.DataPath.registerInterceptor = function(section, dataInterceptor, dataTypeInterceptor) {
		dorado.DataPath.interceptors[section] = {
			dataInterceptor : dataInterceptor,
			dataTypeInterceptor : dataTypeInterceptor
		};
	};

	dorado.DataPathContext = $class({
		$className : "dorado.DataPathContext",

		constructor : function(sections, firstResultOnly) {
			this.sections = sections;
			this.firstResultOnly = firstResultOnly;
			this.level = -1;
			this.levelInfos = [];

			if(firstResultOnly) {
				this.result = null;
			} else {
				this.results = [];
			}

			this.lastSection = sections[sections.length - 1];
			this.setCurrentLevel(0);
		},
		setCurrentLevel : function(level) {
			if(level > this.level) {
				this.levelInfos[level] = this.levelInfo = {
					count : 0
				};
			} else {
				this.levelInfo = this.levelInfos[level];
			}
			this.level = level;
			this.section = this.sections[level];
		},
		addResult : function(result) {
			if(this.firstResultOnly) {
				this.result = result;
				throw BREAK_ALL;
			} else {
				var section = this.section;
				if(section.max > 0 && this.levelInfo.count >= section.max) {
					throw BREAK_LEVEL;
				}
				this.results.push(result);
				this.levelInfo.count++;
			}
		}
	});

})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 与数据处理相关的工具函数。
	 * @static
	 */
	dorado.DataUtil = {
		
		extractNameFromId: function(id) {
			
			function extractName(id) {
				if (id.indexOf("v:") == 0) {
					var i = id.indexOf('$');
					if (i > 0) {
						return id.substring(i + 1);
					}
				}
				return id;
			}
			
			var name = id;
			var subId = dorado.DataType.getSubName(id);
			if (subId) {
				var subName = this.extractNameFromId(subId);
				if (subName != subId) name = name.replace(subId, subName);
			}
			return extractName(name);
		},
		
		FIRE_ON_ENTITY_LOAD: true,
	
		/**
		 * 如果定义了明确的数据类型，则将传入的数据转换成该数据类型。
		 * <p>
		 * 此处的数据类型既可以直接通过dataType参数来指定，也可以在data参数对应的JSON对象的$dataType属性中指定。
		 * </p>
		 * @param {Object} data 要转换的数据。
		 * @param {dorado.DataRepository} [dataTypeRepository] 数据类型的管理器。
		 * @param {dorado.DataType|dorado.LazyLoadDataType|String} [dataType] 要将数据转换为什么类型。
		 * @return {Object} 转换后的数据。
		 * @see dorado.DataType
		 */
		convertIfNecessary: function(data, dataTypeRepository, dataType) {
			if (data == null) return data;

			if (dataType) {
				if (dataType instanceof dorado.LazyLoadDataType) {
					dataType = dataType.get();
				} else if (typeof dataType == "string" && dataTypeRepository) {
					dataType = dataTypeRepository.get(dataType);
				}
			}
			
			if (data instanceof dorado.Entity || data instanceof dorado.EntityList) {
				if (!dataType || data.dataType == dataType) return data;
				if (data.dataType instanceof dorado.AggregationDataType && data.dataType.get("elementDataType") == dataType) return data;
				data = data.toJSON();
			}			
			if (data.$dataType && !dataType && dataTypeRepository) {
				dataType = dataTypeRepository.get(data.$dataType);
			}
			
			if (dataType) {
				var realData = (data.$isWrapper) ? data.data : data;
				if (data.$isWrapper) {
					realData = data.data;
					realData.entityCount = data.entityCount;
					realData.pageCount = data.pageCount;
				}
				else {
					realData = data;
				}
				
				if (dataType instanceof dorado.EntityDataType && realData instanceof Array) {
					dataType = new dorado.AggregationDataType({
						elementDataType: dataType
					});
				}
				if (dataType instanceof dorado.DataType) {
					var rudeData = data;
					data = dataType.parse(data);
					
					if (this.FIRE_ON_ENTITY_LOAD) {
						var eventArg = {};
						if (data instanceof dorado.Entity) {
							if (dataType.getListenerCount("onEntityLoad")) {
								eventArg.entity = data;
								dataType.fireEvent("onEntityLoad", dataType, eventArg);
							}
						} else if (data instanceof dorado.EntityList) {
							if (rudeData.$isWrapper) {
								data.pageSize = rudeData.pageSize;
								data.pageNo = rudeData.pageNo;
							}
							
							var elementDataType = dataType.get("elementDataType");
							if (elementDataType && elementDataType.getListenerCount("onEntityLoad")) {
								for (var it = data.iterator(); it.hasNext();) {
									eventArg.entity = it.next();
									elementDataType.fireEvent("onEntityLoad", dataType, eventArg);
								}
							}
						}
					}
				}
			}
			return data;
		},
		
		/**
		 * 将给定的JSON数据装转换成dorado中的数据封装形式。
		 * @param {Object} data 要转换的数据。
		 * @param {dorado.DataRepository} [dataTypeRepository] 数据类型的管理器。
		 * @param {dorado.DataType} [dataType] 要将数据转换为什么类型。
		 * @return {Object} 转换后的数据。
		 * @see dorado.DataType
		 */
		convert: function(data, dataTypeRepository, dataType) {
			if (data == null) return data;
			var result = this.convertIfNecessary(data, dataTypeRepository, dataType);
			if (result == data) {
				if (data instanceof Array) {
					result = new dorado.EntityList(data, dataTypeRepository, dataType);
				} else if (data instanceof Object) {
					result = new dorado.Entity(data, dataTypeRepository, dataType);
				}
			}
			return result;
		},
		
		/**
		 * 判断一个owner参数代表的数据是否data参数代表的数据的宿主。即data是否是owner中的子数据。
		 * @param {dorado.Entity|dorado.EntityList} data 要判断的数据。
		 * @param {dorado.Entity|dorado.EntityList} owner 宿主数据。
		 * @return {boolean} 是否宿主。
		 */
		isOwnerOf: function(data, owner) {
			if (data == null) return false;
			while (true) {
				data = data.parent;
				if (data == null) return false;
				if (data == owner) return true;
			}
		},
		
		DEFAULT_SORT_PARAMS: [{
			desc: false
		}],
		
		/**
		 * 排序。
		 * @param {Object[]} array 要排序的数组。
		 * @param {Object|Object[]} sortParams 排序参数或排序参数的数组。
		 * @param {String} sortParams.property 要排序的属性名。
		 * @param {boolean} sortParams.desc 是否逆向排序。
		 * @param {Function} [comparator] 比较器。
		 * 比较器是一个具有三个输入参数的Function，三个参数依次为：
		 * <ul>
		 * <li>item1	-	{Object} 要比较的对象1。</li>
		 * <li>item2	-	{Object} 要比较的对象2。</li>
		 * <li>sortParams	-	{Object|Object[]} 排序参数或排序参数的数组。</li> 
		 * </ul>
		 * 比较器的返回值表示对象1和对象2的比较结果：
		 * <ul>
		 * <li>返回大于0的数字表示对象1>对象2。</li>
		 * <li>返回小于0的数字表示对象1<对象2。</li>
		 * <li>返回等于0的数字表示对象1和对象2的比较结果相等。</li>
		 * </ul>
		 * 
		 * @example
		 * // 根据salary属性的值进行逆向排序
		 * dorado.DataUtil.sort(dataArray, { property: "salary", desc: true });
		 * 
		 * @example
		 * // 根据comparator自定义排序的规则
		 * dorado.DataUtil.sort(dataArray, null, function(item1, item2, sortParams) {
		 * 	... ...
		 * });
		 */
		sort: function(array, sortParams, comparator) {			
			array.sort(function(item1, item2) {
				if (comparator) {
					return comparator(item1, item2, sortParams);
				}
				
				var result1, result2;
				if (!(sortParams instanceof Array)) sortParams = [sortParams];
				for (var i = 0; i < sortParams.length; i++) {
					var sortParam = sortParams[i], property = sortParam.property;
					var value1, value2;
					if (property) {
						value1 = (item1 instanceof dorado.Entity) ? item1.get(property) : item1[property];
						value2 = (item2 instanceof dorado.Entity) ? item2.get(property) : item2[property];
					} else {
						value1 = item1;
						value2 = item2;
					}
					if (value1 > value2) {
						return (sortParam.desc) ? -1 : 1;
					} else if (value1 < value2) {
						return (sortParam.desc) ? 1 : -1;
					}
				}
				return 0;
			});
		}
	};
	
	
	function getValueForSummary(entity, property) {
		var value;
		if (property.indexOf('.') > 0) {
			value = dorado.DataPath.create(property).evaluate(entity);
		}
		else {
			value = (entity instanceof dorado.Entity) ? entity.get(property) : entity[property];
		}
		return parseFloat(value) || 0;
	}
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 用于管理各种统计计算方法的对象。
	 * <p>
	 * 每一种统计计算方法都以属性值的方法注册在此对象中，dorado默认提供了count、sum、average等常用的统计计算方法。
	 * 默认支持的全部统计计算方法见本对象文档的Properties段落。
	 * </p>
	 * <p>
	 * 统计计算方法有两种定义形式：
	 * <ul>
	 * <li>
	 * 对于一些较简单的计算方法，可以直接以一个符合特定规范的Function来定义。
	 * <br>
	 * 例如sum（合计）的定义如下。
	 * <pre class="symbol-example code">
	 * <code class="javascript">
	 * // 此方法会在统计过程中针对每一个被统计对象执行一次。
	 * // 3个参数的含义分别是：当前统计结果（初始值为0），当前正被处理的数据实体，当前正统计的属性名。
	 * function(value, entity, property) {
	 * 	return value + parseFloat(entity[property]) || 0;
	 * }
	 * </code>
	 * </pre>
	 * </li>
	 * <li>
	 * 对于一些较复杂的计算方法，无法以一个Function来完成定义。此时可以采用一个包含3个方法的JSON对象来完成定义。
	 * <br>
	 * 例如average（平均值）的定义如下。
	 * <pre class="symbol-example code">
	 * <code class="javascript">
	 * {
	 * 	// 初始方法，用于初始化统计值。此方法只在统计开始前执行一次。
	 * 	getInitialValue: function() {
	 * 		return {
	 * 			sum: 0,
	 * 			count: 0
	 * 		};
	 * 	},
	 * 
	 * 	// 累计方法，此方法会在统计过程中针对每一个被统计对象执行一次。类似于上面提到简单定义中的那个Function。
	 * 	// 此处的value参数即是getInitialValue()返回的那个对象。
	 * 	accumulate: function(value, entity, property) {
	 * 		value.sum += getValueForSummary(entity, property);
	 * 		value.count++;
	 * 		return value;
	 * 	},
	 * 
	 * 	// 用于计算最终的统计值的方法，此方法只在统计完成前执行一次。
	 * 	getFinalValue: function(value) {
	 * 		return value.count ? value.sum / value.count : 0;
	 * 	}
	 * }
	 * </code>
	 * </pre>
	 * </li>
	 * </ul>
	 * </p>
	 * @static
	 */
	dorado.SummaryCalculators = {
		/**
		 * @name dorado.SummaryCalculators.count
		 * @property
		 * @type {Function|Object}
		 * @description "总数量"计算方法。
		 */
		
		/**
		 * @name dorado.SummaryCalculators.sum
		 * @property
		 * @type {Function|Object}
		 * @description "合计值"计算方法。
		 */
		// =====
		
		count: function(value, entity, property) {
			return value + 1;
		},
		
		sum: function(value, entity, property) {
			return value + getValueForSummary(entity, property);
		},
		
		/**
		 * "平均值"计算方法。
		 * @property
		 * @type {Function|Object}
		 */
		average: {
			getInitialValue: function() {
				return {
					sum: 0,
					count: 0
				};
			},
			accumulate: function(value, entity, property) {
				value.sum += getValueForSummary(entity, property);
				value.count++;
				return value;
			},
			getFinalValue: function(value) {
				return value.count ? value.sum / value.count : 0;
			}
		},
		
		/**
		 * "最大值"计算方法。
		 * @property
		 * @type {Function|Object}
		 */
		max: {
			getInitialValue: function() {
				return null;
			},
			accumulate: function(value, entity, property) {
				var v = getValueForSummary(entity, property);
                if (value == null) return v;
				return (v < value) ? value : v;
			},
            getFinalValue: function(value) {
                return value;
            }
		},
		
		/**
		 * "最小值"计算方法。
		 * @property
		 * @type {Function|Object}
		 */
		min: {
			getInitialValue: function() {
				return null;
			},
			accumulate: function(value, entity, property) {
				var v = getValueForSummary(entity, property);
                if (value == null) return v;
				return (v > value) ? value : v;
			},
            getFinalValue: function(value) {
                return value;
            }
		}
	};
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @name dorado.validator
 * @namespace 各种数据校验器的命名空间。
 */
dorado.validator = {};

dorado.validator.defaultOkMessage = [{
	state : "ok"
}];

dorado.Toolkits.registerTypeTranslator("validator", function(type) {
	return dorado.util.Common.getClassType("dorado.validator." + type + "Validator", true);
});
/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 数据校验器的抽象类。
 * @abstract
 * @extends dorado.AttributeSupport
 * @extends dorado.EventSupport
 */
dorado.validator.Validator = $extend([dorado.AttributeSupport, dorado.EventSupport], /** @scope dorado.validator.Validator.prototype */
{
	className : "dorado.validator.Validator",

	ATTRIBUTES : /** @scope dorado.validator.Validator.prototype */
	{
		/**
		 * 名称
		 * @type String
		 * @attribute
		 */
		name: {},

		/**
		 * 校验未通过时给出的信息的默认级别。
		 * <p>
		 * 取值范围包括：info、ok、warn、error。默认值为error。
		 * </p>
		 * @type String
		 * @attribute
		 * @default "error"
		 */
		defaultResultState : {
			defaultValue : "error"
		},
		
		/**
		 * 是否重新校验旧的数值。
		 * <p>
		 * 即当用户将某Field的数值修改回原始值时，是否要重新执行此校验器。
		 * </p>
		 * @type Boolean
		 * @attribute
		 * @default true
		 */
		revalidateOldValue: {
			defaultValue : true
		}
	},

	/**
	 * @name dorado.validator.Validator#doValidate
	 * @function
	 * @protected
	 * @param {Object} data 要验证的数据。
	 * @return {String|Object|[String]|[Object]} 验证结果。
	 * 此处的返回值可以是单独的消息文本、消息对象等。最终Validator会将各种类型的返回值自动的转换成标准的形式。
	 * @description 内部的验证数据逻辑。
	 * @see dorado.validator.Validator#validate
	 */
	// =====

	constructor : function(config) {
		$invokeSuper.call(this, [config]);
		if(config) this.set(config);
	},
	
	getListenerScope : function() {
		return (this._propertyDef) ? this._propertyDef.get("view") : dorado.widget.View.TOP;
	},
	
	/**
	 * 验证数据。
	 * @param {Object} data 要验证的数据。
	 * @param {Object} [arg] 验证参数。通常可能包含两个子属性。
	 * @param {Object} [arg.property] 当前被修改的属性名。
	 * @param {Object} [arg.entity] 当前被修改的数据实体。
	 * @return {[Object]} 验证结果。
	 * 不返回任何验证结果表示通过验证，但返回验证结果并不一定表示未通过验证。
	 * <p>
	 * 返回的验证结果应该是由0到多个验证消息构成的数组。每一个验证结果是一个JSON对象，该JSON对象包含以下属性：
	 * <ul>
	 * <li>state	-	{String} 信息级别。取值范围包括：info、ok、warn、error。默认值为error。</li>
	 * <li>text	-	{String} 信息内容。</li>
	 * </ul>
	 * </p>
	 * <p>
	 * 不过在实际的使用过程中可以根据需要以更加简洁的方式来定义验证结果。<br>
	 * 例如您只想返回一条单一的信息，那么就可以直接返回一个JSON对象而不必将其封装到数组中。<br>
	 * 甚至可以直接返回一个字符串，此时系统认为您希望返回一条单一的信息，该字符串将被视作信息的文本，
	 * 信息的级别则由{@link dorado.validator.Validator#defaultResultState}决定。
	 * </p>
	 * @see dorado.Entity#getPropertyMessages
	 */
	validate : function(data, arg) {
		var result = this.doValidate(data, arg);
		return dorado.Toolkits.trimMessages(result, this._defaultResultState) || dorado.validator.defaultOkMessage;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 远程校验器。
 * @extends dorado.validator.Validator
 * @abstract
 */
dorado.validator.RemoteValidator = $extend(dorado.validator.Validator, /** @scope dorado.validator.RemoteValidator.prototype */
{
	className : "dorado.validator.RemoteValidator",

	ATTRIBUTES : /** @scope dorado.validator.RemoteValidator.prototype */
	{
		/**
		 * 是否以异步的方式来执行验证。
		 * @type boolean
		 * @attribute
		 * @default true
		 */
		async : {
			defaultValue : true
		},

		/**
		 * 当此校验器正在执行时希望系统显示给用户的提示信息。
		 * <p>
		 * 此属性目前仅在校验器以异步模式执行时有效。
		 * </p>
		 * @type String
		 * @attribute
		 */
		executingMessage : {}
	},

	/**
	 * @name dorado.validator.RemoteValidator#doValidate
	 * @function
	 * @protected
	 * @param {Object} data 要验证的数据。
	 * @param {Object} [arg] 验证参数。通常可能包含两个子属性。
	 * @param {Object} [arg.property] 当前被修改的属性名。
	 * @param {Object} [arg.entity] 当前被修改的数据实体。
	 * @param {Function|dorado.Callback} callback 回调方法或对象。
	 * @return {String|Object|[String]|[Object]} 验证结果。
	 * <ul>
	 * <li>对于同步的验证方式，验证结果将直接通过方法的返回值返回。</li>
	 * <li>对于异步的验证方式，验证结果将通过回调方法的参数传给外界。</li>
	 * </ul>
	 * @description 内部的验证数据逻辑。
	 * @see dorado.validator.RemoteValidator#validate
	 */
	// =====

	/**
	 * @name dorado.validator.RemoteValidator.Validator#validate
	 * @function
	 * @param {Object} data 要验证的数据。
	 * @param {Object} [arg] 验证参数。通常可能包含两个子属性。
	 * @param {Object} [arg.property] 当前被修改的属性名。
	 * @param {Object} [arg.entity] 当前被修改的数据实体。
	 * @param {Function|dorado.Callback} callback 回调方法或对象。此参数对于同步或异步两种验证方式都有效。
	 * @return {[Object]} 验证结果。
	 * <ul>
	 * <li>对于同步的验证方式，验证结果将直接通过方法的返回值返回。</li>
	 * <li>对于异步的验证方式，验证结果将通过回调方法的参数传给外界。</li>
	 * </ul>
	 * @description 验证数据。
	 */
	validate : function(data, arg, callback) {
		if(this._async) {
			this.doValidate(data, arg, {
				scope : this,
				callback : function(success, result) {
					if(success) {
						result = dorado.Toolkits.trimMessages(result, this._defaultResultState);
					} else {
						result = dorado.Toolkits.trimMessages(dorado.Exception.getExceptionMessage(result), "error");
					}
					result = result || dorado.validator.defaultOkMessage;
					$callback(callback, true, result);
				}
			});
		} else {
			var result = $invokeSuper.call(this, [data, arg, callback]);
			if(callback) {
				$callback(callback, true, result);
			}
			return result;
		}
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 简单校验器的抽象类。
 * @extends dorado.validator.Validator
 * @abstract
 */
dorado.validator.BaseValidator = $extend(dorado.validator.Validator, /** @scope dorado.validator.BaseValidator.prototype */
{
	className : "dorado.validator.BaseValidator",

	ATTRIBUTES : /** @scope dorado.validator.BaseValidator.prototype */
	{

		/**
		 * 默认的验证信息内容。
		 * @type String
		 * @attribute
		 */
		resultMessage : {}
	},

	validate : function(data, arg) {
		var result = this.doValidate(data, arg);
		if(this._resultMessage && result && typeof result == "string") result = this._resultMessage;
		return dorado.Toolkits.trimMessages(result, this._defaultResultState);
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 非空校验器。
 * @shortTypeName Required
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.RequiredValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.RequiredValidator.prototype */
{
	className : "dorado.validator.RequiredValidator",

	ATTRIBUTES : /** @scope dorado.validator.RequiredValidator.prototype */
	{

		/**
		 * 是否针对trim之后的文本进行非空校验。此属性只对String类型的数值有效。
		 * @type boolean
		 * @attribute
		 * @default true
		 */
		trimBeforeValid : {
			defaultValue : true
		},

		/**
		 * 是否认为0或false是有效的数值。此属性只对数字或逻辑类型的数值有效。
		 * @type boolean
		 * @attribute
		 */
		acceptZeroOrFalse : {
			defaultValue : false
		}
	},

	doValidate: function(data, arg) {
		var valid = (data !== null && data !== undefined && data !== ""), message = '';
		if (valid) {
			if (this._trimBeforeValid && typeof data == "string") {
				valid = jQuery.trim(data) != "";
			} else if (typeof data == "number" || typeof data == "boolean") {
				valid = (!!data || this._acceptZeroOrFalse);
			}
		}
		if (!valid) {
			message = $resource("dorado.data.ErrorContentRequired");
		}
		return message;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 文本长度校验器。
 * @shortTypeName Length
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.LengthValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.LengthValidator.prototype */
{
	className : "dorado.validator.LengthValidator",

	ATTRIBUTES : /** @scope dorado.validator.LengthValidator.prototype */
	{

		/**
		 * 最小合法长度。如果设置为-1则表示忽略对于最小合法长度的校验。
		 * @type int
		 * @attribute
		 * @default -1
		 */
		minLength : {
			defaultValue : -1
		},

		/**
		 * 最大合法长度。如果设置为-1则表示忽略对于最大合法长度的校验。
		 * @type int
		 * @attribute
		 * @default -1
		 */
		maxLength : {
			defaultValue : -1
		}
	},

	doValidate: function(data, arg) {
		if (typeof data == "number") {
			data += '';
		}
		if (typeof data != "string") return;
		var invalid, message = '', len = data.length;
		if (this._minLength > 0 && len < this._minLength) {
			invalid = true;
			message += $resource("dorado.data.ErrorContentTooShort", this._minLength);
		}
		if (this._maxLength > 0 && len > this._maxLength) {
			invalid = true;
			if (message) message += '\n';
			message += $resource("dorado.data.ErrorContentTooLong", this._maxLength);
		}
		return message;
	}
});

/**
 * @author William (mailto:william.jiang@bstek.com)
 * @class 字节长度校验器。
 * @shortTypeName CharLength
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.CharLengthValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.CharLengthValidator.prototype */
{
	className : "dorado.validator.CharLengthValidator",

	ATTRIBUTES : /** @scope dorado.validator.CharLengthValidator.prototype */
	{

		/**
		 * 最小合法长度。如果设置为-1则表示忽略对于最小合法长度的校验。
		 * @type int
		 * @attribute
		 * @default -1
		 */
		minLength : {
			defaultValue : -1
		},

		/**
		 * 最大合法长度。如果设置为-1则表示忽略对于最大合法长度的校验。
		 * @type int
		 * @attribute
		 * @default -1
		 */
		maxLength : {
			defaultValue : -1
		}
	},
	
	doValidate: function(data, arg) {
		function getBytesLength(data) {    
			var str = escape(data);    
			for(var i = 0, length = 0;i < str.length; i++, length++) {    
				if(str.charAt(i) == "%") {    
					if(str.charAt(++i) == "u") {    
						i += 3;    
						length++;    
					}    
					i++;    
				}    
			}    
			return length;    
		}
		
		if (typeof data == "number") {
			data += '';
		}
		if (typeof data != "string") return;
		var invalid, message = '', len = getBytesLength(data);
		if (this._minLength > 0 && len < this._minLength) {
			invalid = true;
			message += $resource("dorado.data.ErrorContentTooShort", this._minLength);
		}
		if (this._maxLength > 0 && len > this._maxLength) {
			invalid = true;
			if (message) message += '\n';
			message += $resource("dorado.data.ErrorContentTooLong", this._maxLength);
		}
		return message;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 数值区间校验器。
 * @shortTypeName Range
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.RangeValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.RangeValidator.prototype */
{
	className : "dorado.validator.RangeValidator",

	ATTRIBUTES : /** @scope dorado.validator.RangeValidator.prototype */
	{

		/**
		 * 最小值。
		 * @type float
		 * @attribute
		 * @see dorado.validator.RangeValidator#attribute:minValueValidateMode
		 */
		minValue : {},

		/**
		 * 最小值的校验方式。
		 * <p>
		 * 目前支持如下几种取值:
		 * <ul>
		 * <li>ignore	-	忽略对于最小值的校验。</li>
		 * <li>allowEquals	-	被校验的数据必须大于或等于设定的最小值。</li>
		 * <li>notAllowEquals	-	被校验的数据必须大于设定的最小值。</li>
		 * </ul>
		 * </p>
		 * @type String
		 * @attribute
		 * @default "ignore"
		 * @see dorado.validator.RangeValidator#attribute:minValue
		 */
		minValueValidateMode : {
			defaultValue : "ignore"
		},

		/**
		 * 最大值。
		 * @type float
		 * @attribute
		 * @see dorado.validator.RangeValidator#attribute:maxValueValidateMode
		 */
		maxValue : {},

		/**
		 * 最大值的校验方式。
		 * <p>
		 * 目前支持如下几种取值:
		 * <ul>
		 * <li>ignore	-	忽略对于最大值的校验。</li>
		 * <li>allowEquals	-	被校验的数据必须小于或等于设定的最大值。</li>
		 * <li>notAllowEquals	-	被校验的数据必须小于设定的最大值。</li>
		 * </ul>
		 * </p>
		 * @type String
		 * @attribute
		 * @default "ignore"
		 * @see dorado.validator.RangeValidator#attribute:maxValue
		 */
		maxValueValidateMode : {
			defaultValue : "ignore"
		}
	},

	doValidate : function(data, arg) {
		var invalidMin, invalidMax, message = '', subMessage = '', data = ( typeof data == "number") ? data : parseFloat(data);
		if(this._minValueValidateMode != "ignore") {
			if(data == this._minValue && this._minValueValidateMode != "allowEquals") {
				invalidMin = true;
			}
			if(data < this._minValue) {
				invalidMin = true;
			}
			if (this._minValueValidateMode == "allowEquals")  {
				subMessage = $resource("dorado.data.ErrorOrEqualTo");
			} else {
				subMessage = '';
			}
			if(invalidMin) {
				message += $resource("dorado.data.ErrorNumberTooLess", subMessage, this._minValue);
			}
		}
		if(this._maxValueValidateMode != "ignore") {
			if(data == this._maxValue && this._maxValueValidateMode != "allowEquals") {
				invalidMax = true;
			}
			if(data > this._maxValue) {
				invalidMax = true;
			}
			if (this._maxValueValidateMode == "allowEquals")  {
				subMessage = $resource("dorado.data.ErrorOrEqualTo");
			} else {
				subMessage = '';
			}
			if(invalidMax) {
				if(message) message += '\n';
				message += $resource("dorado.data.ErrorNumberTooGreat", subMessage, this._maxValue);
			}
		}
		if(invalidMin || invalidMax) return message;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 枚举值校验器。
 * <p>
 * 即允许用户设置一个合法值的列表，只有处于合法值的列表中的数值才能通过此校验。
 * </p>
 * @shortTypeName Enum
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.EnumValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.EnumValidator.prototype */
{
	className : "dorado.validator.EnumValidator",

	ATTRIBUTES : /** @scope dorado.validator.EnumValidator.prototype */
	{

		/**
		 * 合法值的数组。
		 * @type Object[]
		 * @attribute
		 */
		enumValues : {}
	},

	doValidate : function(data, arg) {
		if (data == null) return;
		if(this._enumValues instanceof Array && this._enumValues.indexOf(data) < 0) {
			return $resource("dorado.data.ErrorValueOutOfEnumRange");
		}
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 正则表达式校验器。
 * @shortTypeName RegExp
 * @extends dorado.validator.BaseValidator
 */
dorado.validator.RegExpValidator = $extend(dorado.validator.BaseValidator, /** @scope dorado.validator.RegExpValidator.prototype */
{
	className : "dorado.validator.RegExpValidator",

	ATTRIBUTES : /** @scope dorado.validator.RegExpValidator.prototype */
	{

		/**
		 * 白表达式。即用于描述怎样的数值是合法值的表达式。
		 * @attribute
		 * @type String
		 */
		whiteRegExp : {},

		/**
		 * 黑表达式。即用于描述怎样的数值是非法值的表达式。
		 * @attribute
		 * @type String
		 */
		blackRegExp : {},

		/**
		 * 校验模式，此属性用于决定黑白两种表达式哪一个的优先级更高。
		 * 该属性支持两种取值:
		 * <ul>
		 * <li>whiteBlack	-	先白后黑，即首先校验白表达式，即表示最终黑表达式的优先级更高。</li>
		 * <li>blackWhite	-	先黑后白，即首先校验黑表达式，即表示最终白表达式的优先级更高。</li>
		 * </ul>
		 * @attribute
		 * @type String
		 * @default "whiteBlack"
		 */
		validateMode : {
			defaultValue : "whiteBlack"
		}
	},

	doValidate: function(data, arg) {
		function toRegExp(text) {
			var regexp = null;
			if (text) {
				regexp = (text.charAt(0) == '/') ? eval(text) : new RegExp(text);
			}
			return regexp;
		}
		
		if (typeof data != "string" || data == '') return;
		var whiteRegExp = toRegExp(this._whiteRegExp), blackRegExp = toRegExp(this._blackRegExp);
		var whiteMatch = whiteRegExp ? data.match(whiteRegExp) : false;
		var blackMatch = blackRegExp ? data.match(blackRegExp) : false;
		
		var valid;
		if (this._validateMode == "whiteBlack") {
			valid = whiteRegExp ? whiteMatch : true;
			if (valid && blackRegExp) {
				valid = !blackMatch;
			}
		} else {
			valid = blackRegExp ? !blackMatch : true;
			if (valid && whiteRegExp) {
				valid = whiteMatch;
			}
		}
		if (!valid) return $resource("dorado.data.ErrorBadFormat", data);
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 通过Ajax操作执行的远程校验器。
 * @shortTypeName Ajax
 * @extends dorado.validator.RemoteValidator
 */
dorado.validator.AjaxValidator = $extend(dorado.validator.RemoteValidator, /** @scope dorado.validator.AjaxValidator.prototype */
{
	className : "dorado.validator.AjaxValidator",

	ATTRIBUTES : /** @scope dorado.validator.AjaxValidator.prototype */
	{
		/**
		 * Dorado服务端暴露给客户端的某个服务的名称。
		 * @type String
		 * @attribute
		 */
		service : {},
		
		/**
		 * 直接绑定一个已有的AjaxAction。
		 * @type dorado.widget.AjaxAction
		 * @attribute
		 */
		ajaxAction: {
			setter: function(ajaxAction) {
				this._ajaxAction = dorado.widget.ViewElement.getComponentReference(this, "ajaxAction", ajaxAction);
			}
		}
	},
	
	EVENTS : /** @scope dorado.validator.AjaxValidator.prototype */
	{

		/**
		 * 当校验器将要发出数据校验的请求之前触发的事件。
		 * @param {Object} self 事件的发起者，即本校验器对象。
		 * @param {Object} arg 事件参数。
		 * @param {Object} arg.data 当前将要校验的数据，默认是用户在界面中刚刚编辑的数据。
		 * @param {String} arg.property 用户当前编辑的属性名。
		 * @param {dorado.Entity} arg.entity 用户当前编辑的数据实体。
		 * @param {Object} #arg.parameter 要传递给服务端的数据。
		 * <p>
		 * 此参数就是AjaxValidator稍后即将通过AjaxAction发送到服务端的信息。
		 * 默认情况parameter是一个JSON对象，其中包含一个名为data的属性，其值为用户在界面中刚刚编辑的数据。
		 * </p>
		 * <p>
		 * 如果您需要自定定义发往服务端的信息，既可以直接修改此JSON对象，也可以直接为arg.parameter赋以新值。
		 * </p>
		 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
		 * @event
		 */
		beforeExecute: {}
	},

	constructor : function(config) {
		if(!dorado.widget || !dorado.widget.AjaxAction) {
			this._disabled = true;
			throw new dorado.Exception("'dorado.validator.AjaxValidator' is disabled because the 'dorado.widget.AjaxAction' is not available.");
		}
		$invokeSuper.call(this, arguments);
	},
	
	doValidate : function(data, arg, callback) {
		var eventArg = {
			data: data,
			property: arg.property,
			entity: arg.entity,
			parameter: data
		};
		this.fireEvent("beforeExecute", this, eventArg);
		
		var ajaxAction = this._ajaxAction;
		if (!ajaxAction) {
			this._ajaxAction = ajaxAction = new dorado.widget.AjaxAction();
		}
		
		var config = {
			modal: false,
			async: this._async
		};
		if (this._executingMessage) config.executingMessage = this._executingMessage;
		if (this._service) config.service = this._service;
		config.parameter = eventArg.parameter;
		
		ajaxAction.set(config);
		var retval = ajaxAction.execute(this._async ? callback : null);
		if (retval && !this._async) {
			return ajaxAction.get("returnValue");
		}
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 用户自定义数据校验器。
 * @shortTypeName Custom
 * @extends dorado.validator.Validator
 */
dorado.validator.CustomValidator = $extend(dorado.validator.Validator, /** @scope dorado.validator.CustomValidator.prototype */
{
	className : "dorado.validator.CustomValidator",

	EVENTS : /** @scope dorado.validator.CustomValidator.prototype */
	{

		/**
		 * 当校验器执行数据校验时触发的事件。
		 * @param {Object} self 事件的发起者，即本校验器对象。
		 * @param {Object} arg 事件参数。
		 * @param {Object} arg.data 要校验的数据。
		 * @param {String} arg.property 用户当前编辑的属性名。
		 * @param {dorado.Entity} arg.entity 用户当前编辑的数据实体。
		 * @param {String|Object|[String]|[Object]} #arg.result 验证结果。
		 * 不返回任何验证结果表示通过验证，但返回验证结果并不一定表示未通过验证。
		 * <p>
		 * 标准验证结果应该是由0到多个验证消息构成的数组。每一个验证结果是一个JSON对象，该JSON对象包含以下属性：
		 * <ul>
		 * <li>state	-	{String} 信息级别。取值范围包括：info、ok、warn、error。默认值为error。</li>
		 * <li>text	-	{String} 信息内容。</li>
		 * </ul>
		 * </p>
		 * <p>
		 * 不过在实际的使用过程中可以根据需要以更加简洁的方式来定义验证结果。<br>
		 * 例如您只想返回一条单一的信息，那么就可以直接返回一个JSON对象而不必将其封装到数组中。<br>
		 * 甚至可以直接返回一个字符串，此时系统认为您希望返回一条单一的信息，该字符串将被视作信息的文本，
		 * 信息的级别则由{@link dorado.validator.Validator#defaultResultState}决定。
		 * </p>
		 * <p>
		 * 除了使用arg.result参数，您还可以以直接抛出异常的方式向外界返回验证信息，该异常的消息被视作验证信息的文本，
		 * 信息的级别则由{@link dorado.validator.Validator#defaultResultState}决定。
		 * </p>
		 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
		 * @event
		 *
		 * @example
		 * // 以抛出异常的方式返回验证结果
		 * new dorado.validator.CustomValidator({
		 * 	onValidate: function(self, arg) {
		 * 		if ((arg.data + '') === '') {
		 * 			throw new dorado.Exception("内容不能为空.");
		 * 		}
		 * 	}
		 * });
		 *
		 * @example
		 * // 以arg.result的方式返回验证结果
		 * new dorado.validator.CustomValidator({
		 * 	onValidate: function(self, arg) {
		 * 		if ((arg.data + '').length < 10) {
		 * 			arg.result = {
		 * 				text: "长度不能小于10.",
		 * 				state: "warn"
		 * 			};
		 * 		}
		 * 	}
		 * });
		 */
		onValidate : {}
	},

	doValidate : function(data, arg) {
		var result;
		try {
			var eventArg = {
				data : data,
				property: arg ? arg.property : null,
				entity: arg ? arg.entity : null
			};
			this.fireEvent("onValidate", this, eventArg);
			result = eventArg.result;
		} catch(e) {
			dorado.Exception.removeException(e);
			result = dorado.Exception.getExceptionMessage(e);
		}
		return result;
	}
});

