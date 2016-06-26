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

Oh and finally I'm moving to a new place and need to decorate the walls. I figured I would write the oldest algorithm euclid's gcd algorithm in our new language and print its ast and generated code as some type of programmer compiler-nerd art.

The full code for the compiler can be found [here]()

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

Then make sure that you have [node]() installed. Copy the following `package.json` file.

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

This particular configuration was stolen verbatim from the excellent book [build your own angular js]().

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

The theory of lexers is rooted in DFA's and Automata. Think of the way that we can specify an integer and float. An integer is a sequence of numbers, a float is a sequence of numbers followed by a dot then followed by a sequence of numbers. And in fact a lexer can be implemented simply by translating the regular expressions that form the tokens into the implementation of the corresponding DFA. However note that not all constructs are regular and can be specified by regular expressions like C style comments. To match these we would need to do some extra work inside the lexer.

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

The next step is to be able to match floating point numbers.