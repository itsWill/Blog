title: Writing a Simple Compiler in 1K of Javascript
date: 2016-6-26
description: A  compiler for a small language written in a 1k lines of javascript using TDD.

### **Introduction**

Writing a compiler has become almost a rite of passage in the programming world  and with good reason. A full compiler is a tough and lengthy project that brings together a plethora of topics from the field of computer science. This however is what makes it one of the most rewarding things a programmer can do. Design and implementing your own language brings a feeling of understanding the computer and demistifiying programming in the same way learning about hardware and cpus for the first time does. It brings us closer to the machine.

The aim of this compiler however is not to create a full compiler for a complete language that can perform the complex computations and patterns we use today, wether they be functional or object oriented. This compiler is for a simple language that has only a couple of the usual programming constructs but goes through all the steps in the compilation process:

* Lexing
* Parsing
* Building the Symbol Table
* Type checking
* Code generation

The aim is simplicity and as such we try to keep the implementation under 1k lines of javascript. The decision to write the compiler in javascript is purely selfish and because I wanted to practice writing javascript but familiarize myself with the node environment. So here is a disclaimer that I'm a biggenner at javascript, still getting familiar with the language and its quirks. So take the code here with a healthy dosage of salt and forgive me for any bad code, I swear it was not intentional.

However a basic familiarity with the node environment and javascript is assumed so we won't go into explaining the proporties of the language and the environment to much, this is to keep the tutorial shorter.

The real value of this article will be in the discussion about the compilation ideas we implement the language, as well as in the final product. Having the developed a compiler for a language we can then extend the compiler and explore new areas of language design. I aim to give the know how and tools to do exactly that.

We will be developing the compiler using TDD and building a test suite right along the compiler, this will allow you to have more confidence when you extend the compiler that it's still working as inteded.

Oh and finally I'm moving to a new place and need to decorate the walls. I figured I would write the oldest algorithm euclid's gcd algorithm in our new language and print its ast and generated code to frame as some type of programmer compiler-nerd art.

The full code for the compiler can be found [here](https://github.com/itsWill/minilangjs). And in fact the best way to follow the walkthrough is to have the full code open to reference it as we go through the steps in building the compiler.

Let's get started then.

### **The Phases of Compilation**

#### **Lexing**

If you look at a program you will see that it's text is composed of various units. Integers, floats, variable names, strings, operators, keywords etc... Lexing is the process by which given a program we extract from the text it's constituent units called tokens.

#### **Parsing**

The lexer which will extract the tokens will feed them to the parser. The parser's responsibility is to make sure that the program is syntatically valid. Specifically we mean that given a grammar for a language the program is a valid member of that grammar. We will get more into the meaning of this when we dwelve into the parser section.

As the parser checks that a program is syntatically valid it will also build a tree where the syntax of the program is represented called the abstract syntax tree. The abstract syntax tree is the data structure that the compiler will then use to analyze our program.

#### **Symbol Table**

One of the analysis it will perform comes when it builds the symbol table, which handles the declaration of symbols and scoping. The symbol table will store all the variable names that we declare and any realated information including in which scope they belong too.

#### **Type Checker**

Using the symbol table the compiler will type check, meaning it will make sure that all the typing rules we defined i.e ints can be added to strings but we can't subtract an int from string, a integer comparison results in a bool, and so on are being followed. It will also make sure that any of the variables that we are using have been properly declared within the scope.

#### **Code Generation**

After a program is checked and is valid the compiler will traverse the ast generating the *target* code. The target code is just what language the compiler compiles too, wether that's C or assembly, or any other representation like a QR Code, or even a picture like the [insert language here]. In this case our target code is javascript.

### Setup

Before we get started on discussing and implementing a lexer we need to get our development setup ready.

Lets create our project directory: `mkdir minilang && cd minilang`

Then make sure that you have [node](https://nodejs.org/en/) installed. Copy the following `package.json` file.

``` json
{
  "name": "minilang-compiler",
  "version": "0.1.0",
  "devDependencies": {
    "browserify": "^13.0.1",
    "jasmine-core": "^2.4.1",
    "jshint": "^2.9.2",
    "karma": "^0.13.22",
    "karma-browserify": "^5.0.5",
    "karma-jasmine": "^1.0.2",
    "karma-jshint-preprocessor": "0.0.6",
    "karma-phantomjs-launcher": "^1.0.0",
    "phantomjs-prebuilt": "^2.1.7",
    "watchify": "^3.7.0"
  },
  "scripts": {
    "lint": "jshint src",
    "test": "karma start"
  },
  "dependencies": {
    "jquery": "^2.2.4"
  }
}
```

Run the command `npm install`. This should create a `npm_modules` directory and install the required modules:

* `browserify` for modules.
* `karma` as our test runner
* `jshint` as our linter and `karma` preprocessor
* `jasmine` as our testing framework
* `phantom-js` as the browser to run the tests in
* `watchify` to automatically run our tests on file change

The following shortcuts where also created: `npm test` and `npm lint`, these will start our test suite and lint the program respectively.

The `karma.conf.js` file used to setup our test suite is the following:

``` javascript
module.exports = function(config) {
  config.set({
    frameworks: ['browserify', 'jasmine'],
    files: [
      'src/**/*.js',
      'test/**/*_spec.js'
    ],
    preprocessors: {
      'test/**/*.js': ['jshint', 'browserify'],
      'src/**/*.js': ['jshint', 'browserify']
    },
    browsers: ['PhantomJS'],
    browserify: {
      debug: true,
    }
  });
};
```

notice how the files are specified in the test and src direcotries. Lets go ahead and created them.

This particular configuration was stolen verbatim from the excellent book [build your own angular js](http://teropa.info/build-your-own-angular/).

Now that we are ready to start developing lets discuss the specification of our language.

### **MiniLang**

The minilang specification is to be simple and possible to implement in 1k lines of javascript.

We will support variable declarations of the form: `var i:int = 3 + 5`

Assignment statements `i = 42`

A print statement `print result`

Boolean and regular expressions with strings, ints, floats, and bools.

We will support the following operators: `*, -, %, /, +` with the usual precedence.

And the following boolean operators: `!=, ==, <, >, ||, &&`.

While statements and if-else statements with block scoping.

```
var i:int = 0;
var j:bool = false;
while i < 10 do
  if j = true do
    print j;
    j = false;
  else
    print j;
    j = true;
  end
  i = i + 1;
end
```

Finally our language will ignore whitespace.

Euclids algorithm would like this in minilang:

```
var t:int = 0;
var u:int = 561;
var v:int = 11;
while 0 < v do
  t = u;
  u = v;
  v = t % v;
end
if u < 0 do
  print 0-u;
else
  print u;
end
```
### *The Lexer: That Token Friend*

The theory of lexers is rooted in DFA's and Automata. Think of the way that we can specify an integer and float. An integer is a sequence of numbers, a float is a sequence of numbers followed by a dot then followed by a sequence of numbers. Consider the DFA for a floating point number pictured bellow:
![floating point dfa]()
And in fact a lexer can be implemented simply by translating the regular expressions that form the tokens into the implementation of the corresponding DFA. However note that not all constructs are regular and can be specified by regular expressions like C style comments. To match these we would need to do some extra work inside the lexer.

We would like our lexer to return an array of tokens, the parser can use to iterate through. So lets write our first test.

``` javascript
(function(){'use strict';}());

var Lexer = require('../src/lexer');

describe('Lexer', function(){
  var lexer = new Lexer();

  it('lexes the empty program', function(){
    var tokens = lexer.lex("");
    expect(tokens).toEqual([]);
  });
});
```

We note here that we want a lexer object with the lex function that will return an array of tokens. Let's implement this.

``` javascript
(function(){'use strict;'}());

function Lexer(){
}

Lexer.prototype.lex = function(input){
  var tokens = []
  this.index = 0; //stores the position of the lexer in the input
  while(this.index < input){
    //do lexing work
  }
  return tokens;
}

module.exports = Lexer;
```

The test should pass now.

A token should be an object storing it's token type and value. Let's write a test for that, seeing if we can lex a simple number.

``` javascript
  it('lexes literal numbers', function(){
    var tokens = lexer.lex('2012');
    expect(tokens[0]).toEqual({type: Lexer.TOK_INT, value: '2012'});
  });
```

The regular expression for an integer is: `/\d+/` meaning at least one digit followed by any number of digits. The code therefore should read characters from the input while the characters are numbers and emit a token with the integer type and the value of the read characters. Lets write two functions for this and register the token type.

``` javascript
(function(){'use strict;'}());

function Lexer(){
}

Lexer.TOK_INT = 1;

Lexer.prototype.lex = function(input){
  var tokens = []
  this.index = 0; //stores the position of the lexer in the input
  while(this.index < input){
    var ch = input.charAt(this.index);
    if(this.isNumber(ch)){
      var num = this.readNumber(input);
      tokens.push({type: Lexer.TOK_INT, value: num});
      this.index--; //read one token too far in readNumber
    }
    this.index++;
  }
  return tokens;
}

Lexer.prototype.isNumber = function(n){
  return  !isNaN(parseFloat(n) && isFinite(n));
}

Lexer.prototype.readNumber = function(input){
  num = '';
  while(this.isNumber(input.charAt(this.index))){
    num += input.charAt(this.index);
    this.index++;
  }
  return num;
}

module.exports = Lexer;
```

The next step is to be able to match floating point numbers. Let's take a similiar strategy and think about the regular expression for a floating point number. A floating point number is a sequence of one or more digits followed by a decimal point followed by zero or more digits i.e \d+.\d*

Note that therefore in minilang we don't allow floating point numbers to start with a decimal point. Lets write the tests to match floating point numbers and disallow numbers that start with a decimal point or that are inproperly formatted.

``` javascript
it('lexes floating point numbers', function(){
  var tokens = lexer.lex('20.12');
  expect(tokens[0]).toEqual({type: Lexer.TOK_FLOAT, value: '20.12'});
});

it("throws an exception if floats don't start with a digit", function(){
  expect(function(){lexer.lex('.14');}).toThrow();
});

it('throws an exception on incorrectly formatted float', function(){
  expect(function(){lexer.lex('20..12');}).toThrow();
});
```


Let's write the code to match the regular expresssion and satisfy the tests.

``` javascript
Lexer.TOK_INT = 1;
Lexer.TOK_FLOAT = 2;

Lexer.prototype.lex = function(input){
  var tokens = []
  this.index = 0;
  while(this.index < input){
    var ch = input.charAt(this.index);
    if(this.isNumber(ch)){
      var num = this.readNumber(input);
      if(input[this.index] === '.'){ // now expecting a floating point number
        num += '.';
        this.index++;
        num += this.readNumber(input);
        tokens.push({type: Lexer.TOK_FLOAT, var: num});
      }else
        tokens.push({type: Lexer.TOK_INT, value: num});
      this.index--;
    }
    this.index++;
  }
  return tokens;
}
```

For an identifier we follow the same process we think of the regular expression, write the tests that match and don't match our regex and then finally write the code to match the regular expression.

Our regular expression is  a sequence of one or more letter or underscore characters followed by a sequence of zero or more digits or characters i.e \w(\d|\w)*

Our tests are:

``` javascript
it('lexes an identifier', function(){
  var tokens = lexer.lex('tiger2012');
  expect(tokens[0]).toEqual({type: Lexer.TOK_ID, value: 'tiger2012'});
});

it('doensn\'t let identifiers start with a number', function(){
    var tokens = lexer.lex('2012tiger');
    expect(tokens[0]).toEqual({type: Lexer.TOK_INT, value: '2012'});
    expect(tokens[1]).toEqual({type: Lexer.TOK_ID, value: 'tiger'});
});

it('accepts identifiers with a number in the middle', function(){
  var tokens = lexer.lex('tiger2012tiger');
  expect(tokens[0]).toEqual({type: Lexer.TOK_ID, value: 'tiger2012tiger'});
});

it('throws an exception if identifier has an invalid character', function(){
  expect(function(){lexer.lex('tiger@tiger');}).toThrow();
});

it('allows identifiers to use an underscore in any position', function(){
  var tokens = lexer.lex('_tiger_tiger_');
  expect(tokens[0]).toEqual({ type: Lexer.TOK_ID, value: '_tiger_tiger_'});
});
```

The code to math the regular expresssion uses two auxiliary functions:

* `isIdent` which tells us if a character is a valid identifier
* `readIdent` which functions like `readNumber` and reads characters until they no longer are a valid identifier character

The code to match the regular expression then becomes:

``` javascript

Lexer.TOK_ID = 3;

  // previous code
  ...

  else if(this.isIdent(ch)){
    id = this.readIdent(input);
    tokens.push({ type: Lexer.TOK_ID, value: id});
    this.index--;
  }
  return tokens;
}

Lexer.prototype.isIdent = function(ch){
  return /[a-z0-9_]/i.test(ch);
};

Lexer.prototype.readIdent = function(input){
  var id = '';
  while(this.isNumber(input.charAt(this.index)) || this.isIdent(input.charAt(this.index))){
    id += input.charAt(this.index);
    this.index++;
  }
  return id;
};
```

Some identifiers are special however and are reserved keywords. These are identifiers like `while`, `var`, `if`, `string`, `bool`, `true`, etc.. Therefore when we read an indentifier we check wether it's a reserved keyword if it is we add the token corresponding to the keyword else we just add an identifier token.

The data structure that we use to store the keywords is then a global map from their identifier value to the corresponding token object.

``` javascript
var KEYWORDS =  {
  'while' : { type: Lexer.TOK_WHILE,  value: 'while'},
  'for'   : { type: Lexer.TOK_FOR,    value: 'for'},
  'end'   : { type: Lexer.TOK_END,    value: 'end'},
  'do'    : { type: Lexer.TOK_DO,     value: 'do'},
  'int'   : { type: Lexer.TOK_TYPE,   value: 'int'},
  'float' : { type: Lexer.TOK_TYPE,   value: 'float'},
  'string': { type: Lexer.TOK_TYPE,   value: 'string'},
  'bool'  : { type: Lexer.TOK_TYPE,   value: 'bool'},
  'if'    : { type: Lexer.TOK_IF,     value: 'if'},
  'else'  : { type: Lexer.TOK_ELSE,   value: 'else'},
  'true'  : { type: Lexer.TOK_BOOL,   value: 'true'},
  'false' : { type: Lexer.TOK_BOOL,   value: 'false'},
  'var'   : { type: Lexer.TOK_VAR,    value: 'var'},
  'func'  : { type: Lexer.TOK_FUNC,   value: 'func'},
  'print' : { type: Lexer.TOK_PRINT,  value: 'print'}
};

```

Lets write the test that ensure that we properly lex reserved keywords:

``` javascript
it('properly lexes identifiers that are key words', function(){
  var tokens = lexer.lex('while');
  expect(tokens[0]).toEqual({ type: Lexer.TOK_WHILE, value : 'while'});
});

```

Finally we modify the identifier code:

``` javascript
else if(this.isIdent(ch)){
  id = this.readIdent(input);
  if(KEYWORDS.hasOwnProperty(id)) //check if identifier is a key word
    tokens.push({ type: KEYWORDS[id].type, value: KEYWORDS[id].value});
  else
    tokens.push({ type: Lexer.TOK_ID, value: id});
  this.index--;
}
```

We can add the following tests to ensure robustness of our identifiers when we extend the compiler.

``` javascript
it('doensn\'t let identifiers start with a number', function(){
  var tokens = lexer.lex('2012tiger');
  expect(tokens[0]).toEqual({type: Lexer.TOK_INT, value: '2012'});
  expect(tokens[1]).toEqual({type: Lexer.TOK_ID, value: 'tiger'});
});

it('accepts identifiers with a number in the middle', function(){
  var tokens = lexer.lex('tiger2012tiger');
  expect(tokens[0]).toEqual({type: Lexer.TOK_ID, value: 'tiger2012tiger'});
});

it('throws an exception if identifier has an invalid character', function(){
  expect(function(){lexer.lex('tiger@tiger');}).toThrow();
});

it('allows identifiers to use an underscore in any position', function(){
  var tokens = lexer.lex('_tiger_tiger_');
  expect(tokens[0]).toEqual({ type: Lexer.TOK_ID, value: '_tiger_tiger_'});
});
```

After identifiers the next logical question is what about strings? We take the usual approach and build a simple string lexer by considering first the regular expression that would match a string.
In this case the regex is quite simple being a quote followed by any number of characters followed by a closing quote. We keep strings in our language simple and don't consider string escaping though it isn't particularly challenging and would be a useful exercise.

We implement the following tests to ensure that we lex strings:

``` javascript
it('lexes string literals with double quotes', function(){
  var tokens = lexer.lex('"tiger"');
  expect(tokens[0]).toEqual({ type: Lexer.TOK_STRING, value: "'tiger'"});
});

it('lexes string literals with single quotes', function(){
  var tokens = lexer.lex("'tiger'");
  expect(tokens[0]).toEqual({ type: Lexer.TOK_STRING, value: "'tiger'"});
});

it('can lex strings with special characters in them', function(){
  var tokens = lexer.lex("'$hell@ ^there *world*!'");
  expect(tokens[0]).toEqual({type: Lexer.TOK_STRING, value: "'$hell@ ^there *world*!'"});
});
```

What happens if we have a mismatched quote? If we detect such a situation we throw an exception and stop the lexing process, lets add the test.

``` javascript
it('throws error on a strings mismatched quotes', function(){
  expect(function(){lexer.lex("tiger'");}).toThrow();
});
```

The implementation is similiar to read ident except we have to keep track of the quotes. When we see a quote we advance the token and start reading the string, this is equivalent to a going from one state to another in a DFA that matches strings. Then we need to read the string until we hit the matching quote, when we hit the matching quote we return the string if no matching quote is found then we throw and exception, this is the equivalent of the DFA accepting or rejecting an input respectively. The implementation looks like this:

``` javascript
Lexer.TOK_STRING

Lexer.prototype.lex = function(e){
  // previous code
  ...
  else if(ch === '"' || ch === "'"){
    var quote = ch;
    this.index++;
    id = this.readString(input, quote);
    if(input.charAt(this.index) === quote)
      tokens.push({ type: Lexer.TOK_STRING, value: "'" + id + "'"});
    else
      throw new Error("Unmatched quote");
  }
}
```
The `readString` function is similar to the `readIdent` function, and it's equivalent to a DFA that says match anything until we run out of input or hit a matching quote. Let's implement it:

``` javascript
Lexer.prototype.readString = function(input, quote){
  var string = '';
  while(input.charAt(this.index) !== quote && this.index < input.length){
    string += input.charAt(this.index);
    this.index++;
  }
  return string;
}
```

Finally all we have to do is check if the final quote matches and push the token or reject and throw an error.
