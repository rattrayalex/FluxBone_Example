# Flux + Backbone = Fluxbone
## A practical introduction to using Backbone for Flux Stores

---

I've been following the progress of Flux, and [debates](https://news.ycombinator.com/item?id=8248536) surrounding its utility, with some interest. I found a lot of the original descriptions to be confusing if not merely incomplete. Having read (and re-read, and re-read) the [architecture overview](http://facebook.github.io/react/blog/2014/05/06/flux.html) and a [few](https://github.com/facebook/flux/blob/master/src/Dispatcher.js) [examples](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js), I still just wasn't sure  what Flux was all about, and what advantages it held over Backbone models. 

As it turns out, I think Flux and Backbone play wonderfully together. Or rather, part of Backbone does a great job serving as part of Flux.

### A quick overview of Backbone, and it's shortcomings

I started my journey* by using React with Backbone's Models and Collections, without a Flux architecture. 

\* (Actually, before *that*, I tried using Bacon.js in a [Functional Reactive Programming](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754) pattern, which had me excited but left me frustrated).

In general, it was very nice, and the pieces fit together okay. Here's what Backbone does, and then what it did wrong:

#### Backbone 101

(If you're already well-versed in Backbone, you can skip this - though your corrections would be valued!)

Backbone is an excellent ~little library that includes Views, Models, Collections, and Routes. React replaces Backbone's Views, and let's save Routes for another day. Models are simple places to store data and optionally sync them with the server using a typical REST API. Collections are just places to store a group of model instances. 

Both Models and Collections emit helpful events. For example, a model emits `"change"` when it's been modified, a collection emits `"add"` when a new instance has been added, and they all emit `"request"` when you start to push a change to the server (done with or `.sync()`) and `"sync"` once it's gone through.

You get attributes with `my_instance.get('attribute')` and set as you would expect: `my_instance.set({'attribute': 'value'})`. 

By including `model` and `url` attributes on a Collection, you get all the basic CRUD operations via a REST API for free, via `.add()`, `.fetch()`, `.save()`, and `.destroy()`. You can guess which does which. 

... Now you know all the Backbone you need to know for Fluxbone! But just to make it concrete, here's a quick example: 

```js
var Backbone = require('backbone');

var TodoItem = Backbone.Model.extends({
  // you don't actually need to put anything here.
  // It's that easy!
});

var TodoCollection = Backbone.Collection.extend({
  model: TodoItem,
  url: '/todo',
  initialize: function(){
    this.fetch(); // sends `GET /todo` and populates the models if there are any. 
  }
});

var TodoList = new TodoCollection(); // initialize() called. Let's assume no todos were returned. 

var itemOne = new TodoItem({name: 'buy milk'});
TodoList.add(itemOne); // this will send `POST /todo` to with `name=buy milk`
var itemTwo = TodoList.create({name: 'take out trash'}); // same as above.

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

Sending events from the UI to the Models, and then from one Model to another and then back again, just felt obviously wrong, especially after reading about Flux. My code, frankly, was gross. It took forever to find who was changing who, in what order, and why. 

So I took another look at the mysterious "architecture-not-a-framework". 

### A less quick Overview of Flux, and it's missing piece

(If you're already well-versed in Flux, you can skip this - though your corrections would be valued!)

Flux's slogan is "one-way data flow" (err, they say "unidirectional"). Here's what that flow looks like: 

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

#### React

I won't discuss React here, since so much has been written about it, other than to say that I vastly prefer it to Angular. I almost never feel *confused* when writing React code, unlike Angular. I've written and erased about twenty versions of "I love React it's great software really wow" so I'll just leave it at that. 

#### The Dispatcher

The Flux Dispatcher is a single place where all events events that modify your Stores are handled. To use it, you have each Store `register` a single callback to handle all events. Then, whenever you want to modify a Store, you `dispatch` an event. 

Like React, the Dispatcher strikes me as a Good Idea, Implemented Well. Here's a quick and dirty example: 

```js

// in MyDispatcher.js
var Dispatcher = require('flux').Dispatcher;
var MyDispatcher = new Dispatcher(); // tah-dah! Really, that's all it takes. 
module.exports = MyDispatcher;

// in MyStore.js
var MyDispatcher = require('./MyDispatcher');

MyStore = {}; 
MyStore.dispatchCallback = function(payload) {
  switch (payload.actionType) {
    case 'add-item':
      MyStore.push(payload.item);
      break;
    case 'delete-last-item':
      // we're not actually using this, 
      // but it gives you an idea of what a dispatchCallback looks like.
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
  - A: grep (or rather, use Sublime Text's find-across-files) for that actionType. 

This is much easier than looking for, eg; `MyModel.set` AND `MyModel.save` AND `MyCollection.add` etc. Tracking down the answers to these basic questions got really hard really fast. 

The Dispatcher also allows you to have callbacks run sequentially in a simple, synchronous fashion, using `waitFor`. Eg;

```js
// in MyMessageStore.js

// this isn't actually how you're supposed to set up a store... 
// but it gives you the right idea. 
// We'll see the FluxBone way later. 
MessageStore = {items: []}; 

MessageStore.dispatchCallback = function(payload) {
  switch (payload.actionType) {
    case 'add-item': 
      
      // We only want to tell the user an item was added 
      // once it's done being added to MyStore.
      // yay synchronous event flow!
      MyDispatcher.waitFor([MyStore.dispatchToken]);  // <------ the important line!
      
      // This will be displayed by the MessageComponent in React.
      MessageStore.items.push('You added an item! It was: ' + payload.item); 
      
      // hide the message three seconds later.
      // (tbh, I'm not sure how kosher this is...)
      setTimeout(function(){
        MyDispatcher.dispatch({
          actionType: 'hide-message',
        })
      }, 3000);
      break;
    case 'hide-message': 
      // delete first item in MessageStore.
      MessageStore.items.shift(); 
      break;
  }
} 

```

In practice, I was shocked to see how much cleaner my code was when using this approach to modify my Stores (err, Models & Collections) compared with straight Backbone, even without using `waitFor`.

#### Stores

So data flows *into* Stores through the Dispatcher. Got it. But how does data flow from the Stores to the Views (React)?

> [The] view listens for events that are broadcast by the stores that it depends on.

Okay, great. Just like we registered callbacks with our Stores, we register callbacks with our Views (which are React Components). We tell React to re-`render` whenever a change occurs in the Store which was passed in through its `props`. (Or, rather, for each Store passed in).

For example: 

```js
// in MyComponent.js

MyComponent = React.createClass({
  componentDidMount: function() {
    // register a callback on MyStore
    // to tell this component to forceUpdate
    // whenever it triggers a "change" event.
    this.props.MyStore.addChangeListener(function(){
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

Gross! I have to write all that myself, every time I want a simple Store? Which I'm supposed to use every time I have a piece of information I want to display?? Do you think I have unlimited numbers of Facebook Engineers or something??!!11! (okay, I can think of *one* place that's true...) 

### Flux Stores: the Missing Piece

Backbone's Models and Collections already have everything Flux's EventEmitter-based Stores seem to be doing. 

By telling you to use raw EventEmitter, Flux is recommending that you recreate maybe 50-75% of Backbone's Models & Collections every time you create a Store. Using "EventEmitter" for your stores is like using "Node.js" for your server. Okay, I'll do that, but I'll do it through Express.js or equivalent: a well-built microframework that's taken care of all the basics and boilerplate. 

Just like Express.js is built on Node.js, Backbone's Models and Collections are built on EventEmitter. And it's taken care of all the basics and boilerplate: Backbone emits `"change"` events and has query methods and getters and setters and everything. Plus, [jashkenas](https://github.com/jashkenas) and his army of [230 contributors](https://github.com/jashkenas/backbone/graphs/contributors) did a much better job on all of those things than I or you ever will.

As an example, I converted [the MessageStore example](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js) from above to [a "FluxBone" version](#file-messagestore-fluxbone-js). (Note that it's incomplete (ie; I only converted that file) and is untested).

It's objectively less code (no need to duplicate work) and is subjectively more clear/concise (eg; `this.add(message)` instead of `_messages[message.id] = message`).

So let's use Backbone for Stores! 

### The FluxBone Pattern &copy; 

After some experimentation, this pattern for using Backbone Collections and Models as Flux Stores has got me excited:

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

// the Store is an instantiated Collection. aka a singleton.
// (if we were to only ever have one item, 
//  it would be an instantiated Model instead).
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
    actionCreator.deleteTodo(this.props.todoItem);
    // ** OR: **
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
        // TODO: TodoItemComponent (which would bind to the )
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

I flip that part of the diagram around: the Stores interact directly with a RESTful CRUD API through Backbone's `sync()`. This is wonderfully convenient, at least if you're working with an actual RESTful CRUD API. You can even tie into the `request` and `sync` events to easily display loading icons (kinda like [this](https://news.ycombinator.com/item?id=7721867)). 

For less standard tasks, interacting via ActionCreators may make more sense.  I suspect Facebook doesn't do much "mere CRUD", in which case it's not surprising they do things that way. 

It may also be my youthful naivete that's causing me to interact with the web directly via Stores even for CRUD; I'm all ears to other explanations for the recommended Flux architecture, and why this might not be a good idea. 

### Next Steps

React and Flux have been criticized for not including Routes. I'm hopeful that Backbone's Router, perhaps coupled with a FluxBone `CurrentPageStore`, will provide this. 

Writing the examples for this post in JavaScript was a reminder of how much I appreciate CoffeeScript. I've found Coffee and React/FluxBone get on swimmingly, and I hope to write something soon on how I pair them. 

Lastly, I'd love feedback on the above! Does this seem like a good pattern to you? Are there improvements or flaws you would suggest ammending?
  