# Flux + Backbone = FluxBone
## A proposal for using Backbone for Flux Stores

[React.js](http://facebook.github.io/react/) is an incredible library. Sometimes it feels like the best thing since sliced Python. When the React devs [started talking about Flux](http://facebook.github.io/react/blog/2014/05/06/flux.html), an architecture that React fits into, I was excited, but a bit befuddled. After looking through their recent [docs](https://github.com/facebook/flux) and [examples](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js), I realized there was still something missing with Flux "Stores". FluxBone is the pattern I use that fills the gaps I found, using Backbone's Models and Collections to underlie Stores. 

The result has felt as simple and pleasant to use as React. 

In short, the recommended Flux architecture makes you to do too much legwork for Stores to be funcitonal. Backbone provides everything Stores are supposed to be able to do, so with a few specific patterns, we can just use that. In the future, Facebook may release a library they use for this internally, but until then, Backbone's bloat only totals 6.5kb minified/gzipped.

I have used the pattern in two projects so far, one highly standard CRUD app, and one highly irregular, frontend-only application. I hope to open-source both and link them back here as examples. 

### A quick overview of Backbone, and it's shortcomings

I started my journey by using React with Backbone's Models and Collections, without a Flux architecture. 

In general, it was very nice, and the pieces fit together okay. Here's what Backbone does, and then what it did wrong:

#### Backbone 101

(If you're already well-versed in Backbone, you can skip this).

[Backbone](http://backbonejs.org) is an excellent ~little library that includes Views, Models, Collections, and Routes. Models are simple places to store data and optionally sync them with the server using a typical REST API. Collections are just places to store multiple model instances; think a SQL table. (React replaces Backbone's Views, and let's save Routes for another day.)

Both Models and Collections emit helpful events. For example, a model emits `"change"` when it's been modified, a collection emits `"add"` when a new instance has been added, and they all emit `"request"` when you start to push a change to the server and `"sync"` once it's gone through.

By including `model` and `url` attributes on a Collection, you get all the basic CRUD operations via a REST API for free, via `.save()`, `.fetch()`, and `.destroy()`. You can guess which does which. 

Here's a quick example: 

```js
var Backbone = require('backbone');

var TodoItem = Backbone.Model.extend({});

var TodoCollection = Backbone.Collection.extend({
  model: TodoItem,
  url: '/todo',
  initialize: function(){
    this.fetch(); // sends `GET /todo` and populates the models if there are any. 
  }
});

var TodoList = new TodoCollection(); // initialize() called. Let's assume no todos were returned. 

var itemOne = new TodoItem({name: 'buy milk'});
TodoList.add(itemOne); // this will send `POST /todo` with `name=buy milk`
var itemTwo = TodoList.create({name: 'take out trash'}); // shortcut for above.

TodoList.remove(itemOne); // sends `DELETE /todo/1`

itemTwo.on('change', function(){
  console.log('itemTwo was changed!');
});
itemTwo.on('sync', function(){
  console.log('itemTwo synced to server!');
});

itemTwo.destroy(); // sends `DELETE /todo/2`. 
// > itemTwo was changed!
// > itemTwo synced to server!
```


#### Backbone's shortcomings

Unfortunately, leaning on Backbone alone to handle the entire application flow outside of React's Views wasn't quite working for me. The "complex event chains" that I had [read about](http://www.code-experience.com/avoiding-event-chains-in-single-page-applications/) about didn't take long to rear their hydra-like heads. 

Sending events from the UI to the Models, and then from one Model to another and then back again, just felt obviously wrong, especially after reading about Flux. It took forever to find who was changing who, in what order, and why. 

So I took another look at the mysterious "architecture-not-a-framework". 

### An Overview of Flux, and it's missing piece

(If you're already well-versed in Flux, you can skip this).

Flux's slogan is "unidirectional data flow". Here's what that flow looks like: 

![Flux Diagram](https://github.com/facebook/flux/raw/master/docs/img/flux-diagram-white-background.png)

The important bit is that stuff flows from `React --> Dispatcher --> Stores --> React`. 

Let's look at what each of the main components are and how they connect:

From [the Flux docs](http://facebook.github.io/react/blog/2014/07/30/flux-actions-and-the-dispatcher.html):

> Flux is more of a pattern than a framework, and does not have any hard dependencies. However, we often use EventEmitter as a basis for Stores and React for our Views. The one piece of Flux not readily available elsewhere is the Dispatcher. This module is available here to complete your Flux toolbox.

So Flux has three components: 

1. Views (`React = require('react')`)
2. Dispatcher (`Dispatcher = require('Flux').Dispatcher`)
3. Stores (`EventEmitter = require('EventEmitter')`) 
  - (or, as we'll soon see, `Backbone = require('backbone')`)  

#### The Views

I won't discuss React here, since so much has been written about it, other than to say that I vastly prefer it to Angular. I almost never feel *confused* when writing React code, unlike Angular. I've written and erased about twenty versions of "I love React it's great software really wow" so I'll just leave it at that. 

#### The Dispatcher

The Flux Dispatcher is a single place where all events that modify your Stores are handled. To use it, you have each Store `register` a single callback to handle all events. Then, whenever you want to modify a Store, you `dispatch` an event. 

Like React, the Dispatcher strikes me as a Good Idea, Implemented Well. Here's a quick and dirty example: 

```js

// in MyDispatcher.js
var Dispatcher = require('flux').Dispatcher;
var MyDispatcher = new Dispatcher(); // tah-dah! Really, that's all it takes. 
module.exports = MyDispatcher;

// in MyStore.js
var MyDispatcher = require('./MyDispatcher');

MyStore = []; 
MyStore.dispatchCallback = function(payload) {
  switch (payload.actionType) {
    case 'add-item':
      MyStore.push(payload.item);
      break;
    case 'delete-last-item':
      MyStore.pop();
      break;
  }
}
MyStore.dispatchToken = MyDispatcher.registerCallback(MyStore.dispatchCallback);
module.exports = MyStore;

// in MyComponent.js
var MyDispatcher = require('./MyDispatcher');

MyComponent = React.createClass({
  handleAddItem: function() {
    // note: you're NOT just pushing directly to the store!
    // (the restriction of moving through the dispatcher 
    // makes everything much more modular and maintainable)
    MyDispatcher.dispatch({
      actionType: 'add-item',
      item: 'hello world'
    })
  },
  render: function() {
    return React.DOM.button(
      {onClick: this.handleAddItem}, 
      'Add an Item!'
    );
  }
});

```

This makes it really easy to answer two questions: 

1. Q: What are all the events that modify MyStore? 
  - A: You go to MyStore.dispatchCallback, and browse through the `case` statements. This is surprisingly readable.
2. Q: What are all possible sources of that event?
  - A: grep for that actionType. 

This is much easier than looking for, eg; `MyModel.set` AND `MyModel.save` AND `MyCollection.add` etc. Tracking down the answers to these basic questions got really hard really fast. 

The Dispatcher also allows you to have callbacks run sequentially in a simple, synchronous fashion, using `waitFor`. Eg;

```js
// in MyMessageStore.js

var MyDispatcher = require('./MyDispatcher');
var MyStore = require('./MyStore');


// We'll see the FluxBone way later. 
MessageStore = {items: []}; 

MessageStore.dispatchCallback = function(payload) {
  switch (payload.actionType) {
    case 'add-item': 

      // synchronous event flow!
      MyDispatcher.waitFor([MyStore.dispatchToken]);

      MessageStore.items.push('You added an item! It was: ' + payload.item); 
  }
} 

```

In practice, I was shocked to see how much cleaner my code was when using this approach to modify my Stores, even without using `waitFor`.

#### Stores

So data flows *into* Stores through the Dispatcher. Got it. But how does data flow from the Stores to the Views (React)?

> [The] view listens for events that are broadcast by the stores that it depends on.

Okay, great. Just like we registered callbacks with our Stores, we register callbacks with our Views (which are React Components). We tell React to re-`render` whenever a change occurs in the Store which was passed in through its `props`. 

For example: 

```js
// in MyComponent.js
var React = require('react');

MyComponent = React.createClass({
  componentDidMount: function() {
    this.props.MyStore.addEventListener("change", function(){
      this.forceUpdate();
    }.bind(this));
  },
  componentWillUnmount: function() {
    // remove the callback
  },
  render: function() {
    // show the items in a list.
    return React.DOM.ul({}, 
      this.props.MyStore.items.map(function(item){
        React.DOM.li({}, item)
      })
    );
  }
});
```

Awesome! 

So how do we emit that `"change"` event? Well, Flux recommends using `EventEmitter`. From an [official example](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js):

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
// etc...
```

Gross! I have to write all that myself, every time I want a simple Store? Which I'm supposed to use every time I have a piece of information I want to display?? Do you think I have unlimited numbers of Facebook Engineers or something? (okay, I can think of *one* place that's true...) 

### Flux Stores: the Missing Piece

Backbone's Models and Collections already have everything Flux's EventEmitter-based Stores seem to be doing. 

By telling you to use raw EventEmitter, Flux is recommending that you recreate maybe 50-75% of Backbone's Models & Collections every time you create a Store. Using "EventEmitter" for your stores is like using "Node.js" for your server. Okay, I'll do that, but I'll do it through Express.js or equivalent: a well-built microframework that's taken care of all the basics and boilerplate. 

Just like Express.js is built on Node.js, Backbone's Models and Collections are built on EventEmitter. And it has all the stuff you pretty much always need: Backbone emits `"change"` events and has query methods and getters and setters and everything. Plus, [jashkenas](https://github.com/jashkenas) and his army of [230 contributors](https://github.com/jashkenas/backbone/graphs/contributors) did a much better job on all of those things than I ever will.

As an example, I converted [the MessageStore example](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js) from above to [a "FluxBone" version](#file-messagestore-fluxbone-js). (Note that it's incomplete (ie; I only converted that file) and is untested).

It's objectively less code (no need to duplicate work) and is subjectively more clear/concise (eg; `this.add(message)` instead of `_messages[message.id] = message`).

So let's use Backbone for Stores! 

### The FluxBone Pattern &copy; 

1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. Typically, this means they are singletons. 
2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.
3. Components query Stores and bind to their events to trigger updates.

Let's look at each piece of that in turn: 

#### 1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. 
```js
// dispatcher.js
Dispatcher = require('Flux').Dispatcher

TodoDispatcher = new Dispatcher();  // yep, it's that easy!

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
    switch (payload.actionType) {
      // remove the Model instance from the Store.
      case 'todo-delete':
        this.remove(payload.todo);
        break;
      case 'todo-add': 
        this.add(payload.todo);
        break;
      case 'todo-update': 
        // do stuff...
        this.add(payload.todo, {'merge': true});
        break;
      // ... etc
    }
  }.bind(this)
});

// the Store is an instantiated Collection; a singleton.
TodoStore = new TodoCollection()

module.exports = TodoStore

```

#### 2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.

```js
// components/TodoComponent.js
var React = require('react');

TodoListComponent = React.createClass({
  // ...
  handleTodoDelete: function() {
    // instead of removing the todo from the TodoStore directly,
    // we use the dispatcher. #flux
    TodoDispatcher.dispatch({
      actionType: 'todo-delete',
      todo: this.props.todoItem
    });
  },
  // ...
});

module.exports = TodoListComponent;
```

#### 3. Components query Stores and bind to their events to trigger updates.

```js
// components/TodoComponent.js
var React = require('react');
// ...

TodoListComponent = React.createClass({
  // ... 
  componentDidMount: function() {
    // the Component binds to the Store's events
    this.props.todoStore.on('add remove reset', function(){
      this.forceUpdate()
    }.bind(this), this);
  },
  componentWillUnmount: function() {
    // turn off all events and callbacks that have this context
    this.props.todoStore.off(null, null, this);
  },
  // ...
  render: function() {
    return React.DOM.ul({},
      this.props.todoStore.map(function(todoItem){
        // TODO: TodoItemComponent, which would bind to 
        // `this.props.todoItem.on('change')`
        return TodoItemComponent({todoItem: todoItem});
      })
    )
  }
});
```



In fact, once I re-architected my application to use this pattern, almost all the ugly bits disappeared. It was a little miraculous: one by one, the pieces of code that had me gnashing my teeth looking for a better way were replaced by sensible flow. And the smoothness with which Backbone seems to integrate in this pattern is remarkable: I don't feel like I'm fighting Backbone, Flux, or React in order to fit them together. 

### Example Mixin

Writing the `this.on(...)` and `this.off(...)` code every time you add a FluxBone Store to a component can get a bit old (at least when you're spoiled enough to not have to write any EventEmitter code yourself).

Here's an example React Mixin that, while extremely naiive, would certainly make iterating quickly even easier: 

```js
// in FluxBoneMixin.js
module.exports = function(propName) {
  return {
    componentDidMount: function() {
      this.props[propName].on('all', function(){
        this.forceUpdate();
      }.bind(this), this);
    },
    componentWillUnmount: function() {
      this.props[propName].off('all', function(){
        this.forceUpdate();
      }.bind(this), this);
    }
  };
};

// in MyComponent.js
var React = require('react');
var FluxBoneMixin = require('./FluxBoneMixin');
var UserStore = require('./UserStore');
var TodoStore = require('./TodoStore');

var MyComponent = React.createClass({
  mixins: [FluxBoneMixin('UserStore'), FluxBoneMixin('TodoStore')],
  render: function(){
    return React.DOM.div({},
      'Hello, ' + this.props.UserStore.get('name') +
      ', you have ' + this.props.TodoStore.length + 
      'things to do.'
    )
  }
});

React.renderComponent(
  MyComponent({
    MyStore: MyStore, 
    TodoStore: TodoStore
  }),
  document.body.querySelector('.main')
);

```

### Syncing with a Web API

In the original Flux diagram, you interact with the Web API through ActionCreators only. That never sat right with me; shouldn't the Store be the first to know about changes, before the server? 

I flip that part of the diagram around: the Stores interact directly with a RESTful CRUD API through Backbone's `sync()`. This is wonderfully convenient, at least if you're working with an actual RESTful CRUD API. 

This is great for data integrity. When you `.set()` a new property, the `change` event triggers a React re-render, optimistically displaying the new data. When you try to `.save()` it to the server, the `request` event lets you know to display a loading icon. When things go through, the `sync` event lets you know to remove the loading icon, or the `error` event lets you know to turn things red. You can see inspiration [here](https://news.ycombinator.com/item?id=7721867). 

There's also validation (and a corresponding `invalid` event) for a first layer of defense, and a `.fetch()` method to pull new information from the server. 

For less standard tasks, interacting via ActionCreators may make more sense.  I suspect Facebook doesn't do much "mere CRUD", in which case it's not surprising they don't put Stores first. 

### Next Steps

- React and Flux have been criticized for not including Routes. I'm hopeful that Backbone's Router, perhaps coupled with a FluxBone `CurrentPageStore`, will provide this. 

- Lastly, I'd love feedback on the above! Does this seem like a good pattern to you? Are there improvements or flaws you would suggest ammending?
  