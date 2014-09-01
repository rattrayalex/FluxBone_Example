# Flux and Backbone
### How to have your cake and eat your pie, too. 

I've been following the progress of Flux, and debates surrounding its utility, with some interest. I found a lot of the original descriptions to be confusing if not merely incomplete. Having read (and re-read, and re-read) the architecture overview and a few examples, I still just wasn't sure  what Flux was all about, and what advantages it held over Backbone models. 

In fact, early on, I asked the team what was wrong with using Backbone Collections and Models with React. At the time, I had never used Backbone or React; just read documentation for both. It seemed to me that a lot of what Flux was doing was really just reinventing the wheel that Backbone had honed. 
When I finally dove into my first Backbone app (using React instead of Backbone Views), I started to see what the Flux crowd was talking about. The "complex event chains" that Code Experience Person talks about didn't take long to rear its head. 

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

But everything else – the stuff that fits in where a Store belongs in Flux – is great! It has some flaws, but Backbone is still one of the best-written libraries out there. And, I would argue, is a perfect fit for Flux.

## The Pattern: 

1. React Components as View code:
  1. Which accept Stores in their `props`.
  1. And bind to the Store's events. 
  1. And which never directly `set` or otherwise mutate the Stores. (That's against Flux!). Instead, they only `dispatch` events.
    - (Optionally, dispatch events through `actions`).
1. Stores as Backbone Models or Collections
  1. Which register callbacks with the Dispatcher.
  1. and are passed to the app as instantiated Stores
1. and a Dispatcher.

Here's that list with some quick-and-dirty examples to give you a better idea of what it looks like:

1. React Components as View code:

  1. Which accept Stores in their `props`:

    ```js
    TodoListComponent({todoStore: TodoStore})
    ```

  1. And bind to the Store's events:

      ```js
      TodoListComponent = React.createClass({
        componentDidMount: function() {
          that = this;
          this.props.todoStore.on('add remove reset', function(){that.forceUpdate()}, this);
        },
        componentWillUnmount: function() {
          // turn off all events and callbacks that have this context 
          this.props.todoStore.off(null, null, this);
        }
      })
      ```
    - (The child `TodoItemComponent`s would likely bind to their `this.props.todoItem`'s `change` events). 
  1. And which *never* directly `set` or otherwise mutate the Stores. (That's against Flux!). Instead, they only `dispatch` events: 
      ```js
      handleTodoDelete: function() {
        TodoDispatcher.dispatch({
          actionType: 'todo-delete',
          todo: this.props.todoItem
        });
      }
      ```
    - (Optionally, dispatch events through `actions`):
      ```js
      // in actions.js
      var TodoDispatcher = require('./dispatcher');
      module.exports = {
        deleteTodo: function(todoItem) {
          // ... some stuff
          TodoDispatcher.dispatch({
            actionType: 'todo-delete',
            todo: todoItem
          });
          // ... more stuff
        }
      }

      // in components.js
      var actions = require('actions');
        
        // ... in the Component ...
        handleTodoDelete: function() {
          actions.deleteTodo(this.props.todoItem);
        }
      ```
1. Stores as Backbone Models or Collections
  1. Which register callbacks with the Dispatcher: 

    ```js
    // don't access this from directly from within React. 
    TodoItem = Backbone.Model.extend({});

    TodoCollection = Backbone.Collection.extend({
      model: TodoItem,
      url: '/todo', // wow, just like that, my information saves to the server!
      
      initialize: function() {
        this.dispatchToken = TripDispatcher.register(this.dispatchCallback)
      },
      dispatchCallback: function(payload){
          that = this // man, I miss coffeescript's fat arrows!
          switch (payload.actionType) {
            case 'todo-delete':
              that.remove(payload.todo)
              break;
          }
      }
    });
    ```
  1. and are passed to the app as instantiated Stores: 

    ```js
    TodoStore = new TodoCollection()
    module.exports = TodoStore
    ```
1. and a Dispatcher: 

    ```js
    Dispatcher = require('Flux').Dispatcher
    TodoDispatcher = new Dispatcher()
    module.exports = TodoDispatcher
    // that was easy!
    ```

In summary, the rules are:

1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. 
1. Components never directly modify Stores, but do bind to their events to trigger updates.

```js
var React = require('react');
var Backbone = require('backbone');
var Dispatcher = require('Flux').Dispatcher;

// ------------------------------------------------------------------------
// Dispatcher. Ordinarily, this would go in dispatcher.js

TodoDispatcher = new Dispatcher();


// ------------------------------------------------------------------------
// Actions. Ordinarily, this would go in actions.js or an actions/ dir. 

Actions = {
  deleteTodo: function(todoItem) {
    // ... do some stuff
    TodoDispatcher.dispatch({
      actionType: 'todo-delete',
      todo: todoItem
    });
    // ... do more stuff
  }
}


// ------------------------------------------------------------------------
// Stores. Ordinarily, these would go under eg; stores/TodoStore.js

TodoItem = Backbone.Model.extend({});

TodoCollection = Backbone.Collection.extend({
  model: TodoItem,
  url: '/todo', // wow, just like that, my information saves to the server!
  
  initialize: function() {
    // Flux! register with the Dispatcher so we can handle events.
    this.dispatchToken = TripDispatcher.register(this.dispatchCallback)
  },
  dispatchCallback: function(payload){
    that = this // man, I miss coffeescript's fat arrows!
    switch (payload.actionType) {
      case 'todo-delete':
        that.remove(payload.todo)
        break;
      // ... lots of other `case`s (which is surprisingly readable)
    }
  }
});

// Voila, you have a Store!
TodoStore = new TodoCollection()


// ------------------------------------------------------------------------
// Views. This would normally go in app.js or components.js

TodoListComponent = React.createClass({
  componentDidMount: function() {
    that = this;
    // the Component binds to the Store's events
    this.props.todoStore.on('add remove reset', function(){that.forceUpdate()}, this);
  },
  componentWillUnmount: function() {
    // turn off all events and callbacks that have this context 
    this.props.todoStore.off(null, null, this);
  },
  handleTodoDelete: function() {
    // instead of removing the todo from the TodoStore directly, 
    // we use the dispatcher. #flux

    Actions.deleteTodo(this.props.todoItem)
    // ** OR: ** 
    TodoDispatcher.dispatch({
      actionType: 'todo-delete',
      todo: this.props.todoItem
    });
  },
  render: function() {
    return React.DOM.ul({}, 
      this.props.todoStore.models.map(function(todoItem){
        // TODO: TodoItemComponent
        return TodoItemComponent({todoItem: todoItem});
      })
    );
  }
});

React.renderComponent(
  TodoListComponent({todoStore: TodoStore}), 
  document.querySelector('body')
);
```


This all fits together really smoothly, in my eyes. 

In fact, once I re-architected my application to use this pattern, almost all the ugly bits disappeared. It was a little miraculous: one by one, the pieces of code that had me gnashing my teeth looking for a better way were replaced by sensible flow. 

Note that I didn't even need to use the `waitFor` that so many people are excited about (and seems like a neat idea). Just the general Flux architecture makes sense. I didn't really get how it was that different before using it. And the smoothness with which Backbone seems to integrate (when you use a subset of it in a careful way!) is remarkable: not once did I feel like I was fighting Backbone. 

(Okay, the one gripe I have is that binding and removing events isn't as pretty as it could be – I'd much rather do something like `this.binding = this.props.todoItem.on('change', function(){...})` and then `this.binding.off()`, but `this.props.todoItem.off(null, null, this)` is close enough. )

I didn't mention this above, but among my favorite aspects of using Backbone for this is `sync`: Backbone is really smart about sending data to and fetching data from the server. It works with a predictable REST API in the most predictable way I could  imagine (there may be others with better imaginations). With the single `url:` attribute on a Model or Collection, and an occasional `save()`, `sync()` or `fetch()` call (within the dispatch handler, of course), I get all my basic server interaction. 

Since saving to (and even fetching from) the server is something that Flux says frustratingly little about, I'm very happy to have this unasked (but vital) question go answered.

https://github.com/facebook/flux/blob/master/src/Dispatcher.js

