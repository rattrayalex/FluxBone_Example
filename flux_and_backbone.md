# Flux and Backbone
## A Flux pattern that uses Backbone for Stores

I've been following the progress of Flux, and [debates](https://news.ycombinator.com/item?id=8248536) surrounding its utility, with some interest. I found a lot of the original descriptions to be confusing if not merely incomplete. Having read (and re-read, and re-read) the [architecture overview](http://facebook.github.io/react/blog/2014/05/06/flux.html) and a [few](https://github.com/facebook/flux/blob/master/src/Dispatcher.js) [examples](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js), I still just wasn't sure  what Flux was all about, and what advantages it held over Backbone models. 

In fact, early on, [I asked the team](https://news.ycombinator.com/item?id=7721292) what was wrong with using Backbone Collections and Models with React, and wasn't satisfied with the response. At the time, I had never used Backbone; just read some documentation. 

When I finally dove into my first Backbone app (using React instead of Backbone Views), I started to see what the Flux crowd was talking about. The "complex event chains" that I had [read about](http://www.code-experience.com/avoiding-event-chains-in-single-page-applications/) about didn't take long to rear its head. 

Sending events from the UI to the Models, and then from one Model to another and then back again, just felt obviously wrong, especially after reading about Flux. My code, frankly, was gross. So I took another look at the mysterious "architecture-not-a-framework". 

At the Flux githup repo, I saw the following quote: 

> Flux is more of a pattern than a framework, and does not have any hard dependencies. However, we often use EventEmitter as a basis for Stores and React for our Views. The one piece of Flux not readily available elsewhere is the Dispatcher. This module is available here to complete your Flux toolbox.

I love React for Views, and the Dispatcher really was something I was looking for. But using "EventEmitter" for Stores? What's that about? I took a peek into the provided examples... 

```javascript
var MessageStore = merge(EventEmitter.prototype, {

  emitChange: function() {
    this.emit(CHANGE_EVENT);
  },

  /**
   * @param {function} callback
   */
  addChangeListener: function(callback) {
    this.on(CHANGE_EVENT, callback);
  },

  get: function(id) {
    return _messages[id];
  },

  getAll: function() {
    return _messages;
  },
# etc...
```

Gross! I have to write all that myself, every time I want a simple Store? Which I'm supposed to sprinkle liberally everywhere?

Backbone's Models and Collections already have everything Flux's EventEmitter-based Stores seem to be doing. In the canonical Flux diagram, these event emissions are vital to closing the one-way data flow: React Components bind to the stores' change events to know when to update. 

![Flux Diagram](https://github.com/facebook/flux/raw/master/docs/img/flux-diagram-white-background.png)

The problem that Flux advocates seem to have with Backbone is that it's more than you need. They're right, of course. You don't need Backbone Views at all, and Models and Collections have a bunch of features you shouldn't use in a Flux application. 

But everything else – the stuff that fits in where a Store belongs in Flux – is great! It isn't perfect, but Backbone is still one of the best-written libraries out there. And, I would argue, is a perfect fit for Flux.

### The Backbone-Flux Pattern: 

After some experimentation, this pattern for using Backbone Collections and Models as Flux Stores has got me excited:

1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. 
2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.
3. Components do bind to query Stores and bind to their events to trigger updates.

Let's look at each piece of that in turn: 

#### 1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. 
```js
// dispatcher.js
Dispatcher = require('Flux').Dispatcher

TodoDispatcher = new Dispatcher()

module.exports = TodoDispatcher;
```

```js
// stores/TodoStore.js
var Backbone = require('backbone');
var TodoDispatcher = require('../dispatcher');

TodoItem = Backbone.Model.extend({});

TodoCollection = Backbone.Collection.extend({
  model: TodoItem,
  url: '/todo',
  
  // we register a callback with the Dispatcher on init.
  initialize: function() {
    this.dispatchToken = TodoDispatcher.register(this.dispatchCallback)
  },
  dispatchCallback: function(payload) {
    that = this; // man, I miss coffeescript's fat arrows!
    switch (payload.actionType) {
      // remove the Model instance from the Store.
      case 'todo-delete':
        that.remove(payload.todo)
        break;
      // ... lots of other `case`s 
      // (which is surprisingly readable)
    }
  }
});

// the Store is an instantiated Collection. 
// (if we were to only have one item, it would be an instantiated Model).
TodoStore = new TodoCollection()

module.exports = TodoStore

```

#### 2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.

```js
// actions.js
var TodoDispatcher = require('./dispatcher')

actionCreator = {
  deleteTodo: function(todoItem) {
    // dispatch 'todo-delete' action
    TodoDispatcher.dispatch({
      actionType: 'todo-delete',
      todo: todoItem
    });
  },
  // ... other actions ...
}

module.exports = actionCreator
```

```js
// components/TodoComponent.js
var actionCreator = require('../actions');
var React = require('react');

TodoListComponent = React.createClass({
  // ...
  handleTodoDelete: function() {
    // instead of removing the todo from the TodoStore directly,
    // we use the dispatcher. #flux
    actionCreator.deleteTodo(this.props.todoItem)
  },
  // ...
});

module.exports = TodoListComponent;
```

#### 3. Components do bind to query Stores and bind to their events to trigger updates.

```js
// components/TodoComponent.js
var React = require('react');
// ...

TodoListComponent = React.createClass({
  // ... 
  componentDidMount: function() {
    // the Component binds to the Store's events
    that = this;
    this.props.todoStore.on('add remove reset', function(){that.forceUpdate()}, this);
  },
  componentWillUnmount: function() {
    // turn off all events and callbacks that have this context
    this.props.todoStore.off(null, null, this);
  },
  // ...
  render: function() {
    return React.DOM.ul({},
      this.props.todoStore.map(function(todoItem){
        // TODO: TodoItemComponent
        return TodoItemComponent({todoItem: todoItem});
      })
    )
  }
});
```

You can see that all put together in the `example.js` file in this gist. 

This all fits together really smoothly, in my eyes. 

In fact, once I re-architected my application to use this pattern, almost all the ugly bits disappeared. It was a little miraculous: one by one, the pieces of code that had me gnashing my teeth looking for a better way were replaced by sensible flow. 

Note that I didn't even need to use `waitFor`; it may be *a* feature, but it's not the primary one. Just the general Flux architecture makes sense. I didn't really get how it was that different before using it. And the smoothness with which Backbone seems to integrate in this pattern is remarkable: not once did I feel like I was fighting Backbone. 

### Syncing with a Web API

In the original Flux diagram, you interact with the Web API through ActionCreators only. That never sat right with me; shouldn't the Store be the first to know about changes, before the server? 

I flip that part of the diagram around: the Stores interact directly with a RESTful CRUD API through Backbone's `sync()`. This is wonderfully convenient, at least if you're working with an actual RESTful CRUD API. You can even tie into the `request` and `sync` events to easily display loading icons. 

For less standard tasks, interacting via ActionCreators may make more sense.  I suspect Facebook doesn't do much "mere CRUD", in which case it's not surprising they do things that way. It may also be my youthful naivete that's causing me to interact with the web directly via Stores even for CRUD; I'm all ears to other explanations for the recommended Flux architecture.

### Next Steps

React and Flux have been criticized for not including recommendations for Routes. I'm hopeful that Backbone's Router, perhaps coupled with a Backbone-Flux `CurrentPageStore`, will provide this. 

Writing the examples for this post in Javascript was a reminder of how much I appreciate Coffeescript. I've found Coffee and Backbone get on swimmingly, and I hope to write something soon on how I pair them. 

Lastly, I'd love feedback on the above! Does this seem like a good pattern to you? Are there improvements or flaws you would suggest ammending?
