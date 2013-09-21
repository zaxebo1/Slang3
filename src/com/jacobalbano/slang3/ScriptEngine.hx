package com.jacobalbano.slang3;
import flash.display.DisplayObjectContainer;
import flash.display.GraphicsStroke;
import flash.display.InteractiveObject;
import flash.system.System;
import haxe.remoting.SocketConnection;

/**
 * ...
 * @author Jake Albano
 */

private enum Token
{
	ModuleBegin;
	ModuleEnd;
	
	Define;
	
	LiteralNumber;
	LiteralBool;
	LiteralString;
	Identifier;
	
	ScopeBegin;
	ScopeEnd;
	
	ArrayBegin;
	ArrayEnd;
	
	TupleBegin;
	TupleEnd;
}

private typedef Literal = {
	var value:Dynamic;
	var type:Token;
}

private typedef Read = {
	var length:Int;
	var contents:Array<Dynamic>;
};

private typedef Keyword = {
	/**
	 * asdasdasd
	 */
	var token:Token;
	var interrupt:Bool;
};

class ScriptEngine
{
	private var tokens:Map<String, Keyword>;
	
	public function new() 
	{
		tokens = new Map<String, Keyword>();
		tokens.set("def", 	{ token : Token.Define,		interrupt : false, });
		tokens.set("{", 	{ token : Token.ScopeBegin,	interrupt : true, });
		tokens.set("}", 	{ token : Token.ScopeEnd,	interrupt : true, });
		tokens.set("[", 	{ token : Token.ArrayBegin,	interrupt : true, });
		tokens.set("]", 	{ token : Token.ArrayEnd,	interrupt : true, });
		tokens.set("(", 	{ token : Token.TupleBegin,	interrupt : true, });
		tokens.set(")", 	{ token : Token.TupleEnd,	interrupt : true, });
	}
	
	public function parse(source:String):Void
	{
		source = source + "\n";	//	append a newline for super clean symbolification
		var symbols = new Array<String>();
		var stringbuilder = new StringBuf();
		var cursor = 0;
		var inString = false;
		var escape = false;
		
		function newSym(sym = null)
		{
			sym = (sym == null) ? stringbuilder.toString() : sym;
			if (sym.length != 0)
			{
				symbols.push(sym);
			}
			
			stringbuilder = new StringBuf();
		}
		
		while (cursor < source.length)
		{
			var char = source.charAt(cursor);
			cursor++;
			
			if (char == '"')
			{
				if (!(inString = !inString))
				{
					stringbuilder.add(char);
					newSym();
					continue;
				}
			}
			
			if (inString)
			{
				stringbuilder.add(char);
			}
			else
			{
				if (StringTools.isSpace(char, 0))
				{
					newSym();
				}
				else
				{
					if (tokens[char] != null)
					{
						newSym();
						newSym(char);
						continue;
					}
					else
					{
						//	continue appending to the current symbol
						stringbuilder.add(char);
					}
					
					//	if the symbol matches a reserved word or token, add it immediately without waiting for whitespace
					var token = tokens[stringbuilder.toString()];
					if (token != null && token.interrupt)
					{
						newSym();
					}
				}
			}
		}
		
		
		var processedSymbols = new Array<Dynamic>();
		processedSymbols.push(Token.ModuleBegin);
		
		for (symbol in symbols) 
		{
			var t = tokens[symbol];
			if (t == null)
			{
				processedSymbols.push(getLiteral(symbol));
			}
			else
			{
				processedSymbols.push(t.token);
			}
		}
		
		processedSymbols.push(Token.ModuleEnd);
		
		compile(processedSymbols);
	}
	
	private function compile(symbols:Array<Dynamic>) 
	{
		var collapsed = collapse(symbols);
		for (s in collapsed)
		{
			trace(s);
		}
	}
	
	private static function getLiteral(string:String):Literal
	{
		var type = Token.Identifier;
		if (string == "true" || string == "false")
		{
			type = Token.LiteralBool;
		}
		
		if (!Math.isNaN(Std.parseFloat(string)))
		{
			type = Token.LiteralNumber;
		}
		
		if (StringTools.startsWith(string, '"') && StringTools.endsWith(string, '"'))
		{
			type = Token.LiteralString;
		}
		
		var value:Dynamic = switch(type)
		{
			case Token.LiteralBool:
				(string == "true");
			case Token.LiteralNumber:
				Std.parseFloat(string);
			case Token.LiteralString:
				string.substr(1, string.length - 2);	//	trip quotation marks
			case Token.Identifier:
				string;
			default:
				throw "oh noooooo";
		}
		
		return { value : value, type : type };
	}
	
	
	private static function collapse(symbols:Array<Dynamic>):Array<Dynamic>
	{
		var read = readAhead(symbols, 0, Token.ModuleEnd);
		return read.contents;
	}
	
	private static function readAhead(symbols:Array<Dynamic>, start:Int, seek:Token):Read
	{
		var i = start + 1;
		var result:Array<Dynamic> = [];
		
		while (i < symbols.length)
		{
			var symbol:Dynamic = symbols[i];
			
			if (symbol == seek)
			{
				break;
			}
			else
			{
				function err(token)
				{
					throw "Unexpected token " + Std.string(token);
				}
				
				var found = true;
				
				if (Std.is(symbol, Token))
				{
					var token:Token = cast symbol;
					switch (token)
					{
						case Token.ArrayEnd:	err(Token.ArrayEnd);
						case Token.ScopeEnd:	err(Token.ScopeEnd);
						case Token.TupleEnd:	err(Token.TupleEnd);
						
						case Token.ArrayBegin:
							var read = readAhead(symbols, i, Token.ArrayEnd);
							i += read.length;
							result.push(new SlangArray(read.contents));
						case Token.ScopeBegin:
							var read = readAhead(symbols, i, Token.ScopeEnd);
							i += read.length;
							result.push(new Scope(read.contents));
						case Token.TupleBegin:
							var read = readAhead(symbols, i, Token.TupleEnd);
							i += read.length;
							result.push(new Tuple([]));
						default:
							result.push(token);
					}
				}
				else
				{
					result.push(symbol);
				}
				
				++i;
			}
		}
		
		return {
			contents : result,
			length : i - start
		};
	}
}