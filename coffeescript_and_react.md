
# Who needs JSX when you can have Whitespace?
## CoffeeScript + React = (y)

# Note to people reviewing the other piece: this one isn't done yet. You're more than welcome to look it over if you like, but really don't have to!

I went back and forth a number of times in the great debate between Angular.js and React.js for client-side rendering. I ultimately landed firmly on the side of React: Angular.js, I found, was a disappointingly leaky abstraction with unfortunately high cognitive overhead. In contrast, React handles its self-appointed task with completeness, elegance, and pragmatism. I have almost never been *confused* when writing React code.

But there was one thing I couldn't stand about React: JSX. It was the #1 thing keeping me from using the framework. As a full-stack designer/developer, I had long since gotten fed up with editing HTML: pointless angle brackets and closing tags always felt like they were getting in the way. [Jade](http://jade-lang.com/) (well, actually [pyjade](https://github.com/SyrusAkbary/pyjade)) became my templating language of choice, and suddenly designs become much easier to write, read, and edit. 

Once you stop writing closing angle brackets, you never want to go back. 

For example, take this snippet of code from [the bootstrap docs](http://getbootstrap.com/css/#forms): 

```html
<form role="form">
  <div class="form-group">
    <label for="exampleInputEmail1">Email address</label>
    <input type="email" class="form-control" id="exampleInputEmail1" placeholder="Enter email">
  </div>
  <div class="form-group">
    <label for="exampleInputPassword1">Password</label>
    <input type="password" class="form-control" id="exampleInputPassword1" placeholder="Password">
  </div>
  <div class="form-group">
    <label for="exampleInputFile">File input</label>
    <input type="file" id="exampleInputFile">
    <p class="help-block">Example block-level help text here.</p>
  </div>
  <div class="checkbox">
    <label>
      <input type="checkbox"> Check me out
    </label>
  </div>
  <button type="submit" class="btn btn-default">Submit</button>
</form>
```

In Jade, that'd be: 

```jade
form(role='form')
  .form-group
    label(for='exampleInputEmail1') Email address
    input#exampleInputEmail1.form-control(
      type='email'
      placeholder='Enter email')
  .form-group
    label(for='exampleInputPassword1') Password
    input#exampleInputPassword1.form-control(
      type='password'
      placeholder='Password')
  .form-group
    label(for='exampleInputFile') File input
    input#exampleInputFile(type='file')
    p.help-block Example block-level help text here.
  .checkbox
    label
      input(type='checkbox')
      | Check me out
  button.btn.btn-default(type='submit') Submit
```

Ah, so much more readable! And about 2/3 the line count. Less typing, less distraction from the meat of what's going on. 

So suffice it to say I wasn't looking forward to having to write JSX:

```jsx
<Container>{window.isLoggedIn ? <Nav /> : <Login />}</Container>;
```

The muddling of pseudo-html with javascript (neither of them pretty in their own right) just wasn't going to do it for me. 

I searched near and far for a way to use my beloved Jade with React. It wasn't looking good. Until I stumbled accross [this post](TODO: FIND!) which demonstrated how you can use pure coffeescript to achieve almost the same effect.

Here's what that form would look like:

```coffee
React = require('react')  # thanks, browserify!

{div, p, form, label, input, button} = React.DOM

MyComponent = React.createClass
  render: ->
    form {role: 'form'},
      div {className: 'form-group'},
        label {for: 'exampleInputEmail1'}, "Email address"
        input {
          id: 'exampleInputEmail1'
          className: 'form-control'
          type: 'email'
          placeholder: 'Enter email'
        }
      div {className: 'form-group'},
        label {for: 'exampleInputPassword1'}, "Password"
        input {
          id: 'exampleInputPassword1'
          className: 'form-control'
          type: 'password'
          placeholder: 'Password'
        }
      div {className: 'form-group'},
        label {for: 'exampleInputFile'}, "File input"
        input {
          id: 'exampleInputFile'
          type: 'file'
        }
        p {className: 'help-block'}, 
          "Example block-level help text here."
      div {className: 'checkbox'},
        label {},
          input {type: 'checkbox'},
            "Check me out"
      button {
        className: 'btn btn-default'
        type: 'submit'
      }, "Submit"
```

This is so similar to Jade that it was almost a pure copy/paste. 

But it's better: it's *just pure coffeescript*. Where JSX involves inserting pseudo-html into javascript and then javascript into *that*, this is just coffeescript in coffeescript. I can have if statements, for loops, list comprehensions, and it's one seamless templating language that doesn't even require a templating language. 

Eg; 
```coffee
# ...
render: ->
  if @props.user.isLoggedIn()
    for todo in @props.user.todos
      TodoItem {todo}
  else
    p {},
      "You should Log in! here's why:"
    ul {}, 
      [li({}, reason) for reason in @props.reasons_to_log_in]  
    
```

Now, there are a few things to be careful of. I sure do have fun with coffeescript's whitespace, but it can give you a sharp kick from time to time. For example, you *need to remember* the trailing comma after the attributes. Actually, that's the only one that I've run into. 

### The Tooling

I feel a little silly writing about the tooling needed for this setup. There basically isn't any: I just use [browserify](http://browserify.org/) by way of [coffeeify](https://www.npmjs.org/package/gulp-coffeeify). This is the meat of my gulpfile: 

```js
gulp.task('scripts', function() {
  gulp.src('coffee/app.coffee')
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
    .pipe(coffeeify())
    .pipe(gulp.dest('js'))
    .pipe(refresh(livereload_server))
    ;
});
gulp.task('watch', function() {
  gulp.watch('coffee/**/*.coffee', ['scripts']);
});
```

You'll notice that I watch all files in my `coffee` dir, but only compile `app.coffee`; everything else is imported via `require()`.

Having run `npm install reactify --save-dev`, I can also import npm modules that lean on jsx, like [react-bootstrap](https://www.npmjs.org/package/react-bootstrap). 

<<< TALK ABOUT HOW COMPONENTS MAKE BIG TEMPLATE FILES UNNECESSARY >>> 

----

### CoffeeScript Saves Lives

Okay, that's an exaggeration. But, if you play fast and loose with philosophy, not much of one. 

JavaScript and JSX waste my life away. (Melodramatic, but true). When I'm writing in them, I spend a much higher percentage of my time on keystrokes that do not add value. 

When I write `var myFunc = function (arg) {};` instead of `myFunc = (arg) ->`, I am writing 14 keystrokes that I did not need to. When I write `<div></div>` instead of `div {},`, it's an extra 4 (If that was "MyComponent" instead of "div", it'd be an extra 11!). 

What's 10 keystrokes in the grand scheme of things? Aren't you going a little overboard here?

I don't think so. At least, not if you're an engineer. When I code, I code *a lot*. In a given week, I might spend 40 hours writing code (out of 60 hours working). Those 14 keystrokes just to define a function? That might be seven seconds. 

It doesn't sound like a lot until you realize that you're defining functions (+14ks), if statements (+5ks), variables (+5ks), and inserting React components (x+1ks) *all day long*. All day long! 

Let's say coding in CoffeeScript takes 25% fewer keystrokes than coding with JavaScript/JSX. (I'd love to run a benchmark but don't know how to do so objectively). If you spend 4 hours a day physically writing code, that's a whole hour you just gained. 

If you're an engineer, you're spending a significant portion of *your life* coding. Why waste it on literally mindless tasks like "type out the word function and then some curly braces and then a semicolon"? 

The only response I can think of to this is "it doesn't take that long to type a semicolon". Right. A piece of paper isn't that thick, but when you're Dunder Mifflin, you need a whole warehouse to deal with the total thickness of all the paper you're producing. 

Of course, we also spend a lot of time reading and editing code. I personally find CoffeeScript much more readable than JavaScript+JSX. Of course, I *can* read JavaScript and JSX, without noticeable difficulty, but it does take longer. Since the eye has less to look at, it only spends time looking at meaningful code. With Javascript, you can't help looking at the boilerplate. 

Editing takes much longer because I need to move *two* noncontinuous lines whenever I change the position of a code block or component (that pesky closing `}` or `</div>`). 

Because of semicolons alone, you're spending an extra keystroke practically *every single line*. 























