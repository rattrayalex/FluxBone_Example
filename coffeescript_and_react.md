
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

