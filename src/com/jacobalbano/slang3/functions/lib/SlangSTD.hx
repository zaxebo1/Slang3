package com.jacobalbano.slang3.functions.lib;
import com.jacobalbano.slang3.functions.NativeFunction;
import com.jacobalbano.slang3.functions.SlangFunction;
import com.jacobalbano.slang3.Literal;
import com.jacobalbano.slang3.Scope;
import com.jacobalbano.slang3.ScriptEngine;
import com.jacobalbano.slang3.ScriptVariable;
import com.jacobalbano.slang3.SlangArray;

/**
 * ...
 * @author Jake Albano
 */
class SlangSTD
{
	public static function bindSTD(scope:Scope):Void
	{
		scope.functions.set("print", new NativeFunction(print, 1, FunctionType.Procedure));
		scope.functions.set("set", new NativeFunction(__set, 2, FunctionType.Function, [0]));
		scope.functions.set("if", new NativeFunction(__if, 2, FunctionType.Procedure));
		scope.functions.set("ifelse", new NativeFunction(__ifelse, 3, FunctionType.Procedure));
	}
	
	private static function __set(variable:ScriptVariable, value:Dynamic):Dynamic
	{
		variable.value = value;
		return value;
	}
	
	private static function print(p:Dynamic):Void
	{
		trace(Std.string(p));
	}
	
	private static function __if(condition:Bool, scope:Scope):Void
	{
		if (condition)
		{
			scope.execute();
		}
	}
	
	private static function __ifelse(condition:Bool, scopeTrue:Scope, scopeFalse:Scope):Void
	{
		condition ? scopeTrue.execute() : scopeFalse.execute();
	}
}