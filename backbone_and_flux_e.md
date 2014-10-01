# Straightforward Databinding for React
## Introducing FluxBone, a proposal for using Backbone for Flux Stores

[React.js](http://facebook.github.io/react/) is an incredible library. Sometimes it feels like the best thing since sliced Python. React is only one part of a frontend application stack, however; it doesn't have much to say about how you should manage data and state. 

Facebook, the makers of React, have [offered some guidance](http://facebook.github.io/react/docs/flux-overview.html) there in the form of [Flux](https://github.com/facebook/flux). Flux is an "Application Architecture" (not a framework) built around one-way data flow, using React Views, an Action Dispatcher, and Stores. 

The Flux pattern solves some major problems by embodying important principles of event control, which makes applications much easier to reason about (read: easier to maintain and develop). 

Here, I'll introduce basic Flux control flow, discuss what's missing for Stores, and how to use Backbone Models and Collections to fill the gap in a "Flux-compliant" way. 

(Note: the following examples are in CoffeeScript for convenience, and can be treated as pseudocode by non-CoffeeScript developers). 

## Intro to Flux

### First, why do we need Flux? What's wrong with plain Backbone?

[Backbone](http://backbonejs.org) is an excellent ~little library that includes Views, Models, Collections, and Routes. It's the de facto standard library for structured frontend applications, and it's been paired with React since the latter was introduced. Most discussions of React outside of Facebook so far have have included mentiones of Backbone being used in tandem. 

Unfortunately, leaning on Backbone alone to handle the entire application flow outside of React's Views presents unfortunate complications. The "complex event chains" that I had [read about](http://www.code-experience.com/avoiding-event-chains-in-single-page-applications/) about didn't take long to rear their hydra-like heads. Sending events from the UI to the Models, and then from one Model to another and then back again, makes it hard to find who was changing who, in what order, and why. 

The Flux pattern handles these problems with impressive ease and simplicity. 

### An Overview of Flux

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

```coffee
# in TodoDispatcher.coffee
Dispatcher = require("flux").Dispatcher

TodoDispatcher = new Dispatcher() # tah-dah! Really, that's all it takes.

module.exports = TodoDispatcher
```

```coffee
# in TodoStore.coffee
TodoDispatcher = require("./TodoDispatcher")

# we'll do this the FluxBone way later.
TodoStore = {items: []}

TodoStore.dispatchCallback = (payload) ->
  switch payload.actionType
    when "add-item"
      TodoStore.items.push payload.item
    when "delete-last-item"
      TodoStore.items.pop()

TodoStore.dispatchToken = TodoDispatcher.registerCallback(TodoStore.dispatchCallback)

module.exports = TodoStore

```

```coffee
# in ItemAddComponent.coffee
TodoDispatcher = require("./TodoDispatcher")

ItemAddComponent = React.createClass
  handleAddItem: ->
    # note: you're NOT just pushing directly to the store!
    # (the restriction of moving through the dispatcher
    # makes everything much more modular and maintainable)
    TodoDispatcher.dispatch
      actionType: "add-item"
      item: "hello world"

  render: ->
    React.DOM.button {
      onClick: @handleAddItem
    },
      "Add an Item!"

```

This makes it really easy to answer two questions: 

1. Q: What are all the events that modify MyStore? 
  - A: You go to MyStore.dispatchCallback, and browse through the `case` statements. This is surprisingly readable.
2. Q: What are all possible sources of that event?
  - A: grep for that actionType. 

This is much easier than looking for, eg; `MyModel.set` AND `MyModel.save` AND `MyCollection.add` etc. Tracking down the answers to these basic questions got really hard really fast. 

The Dispatcher also allows you to have callbacks run sequentially in a simple, synchronous fashion, using `waitFor`. Eg;

```coffee
# in MessageStore.coffee
MyDispatcher = require("./MyDispatcher")
TodoStore = require("./TodoStore")

# We'll see the FluxBone way later.
MessageStore = {items: []}

MessageStore.dispatchCallback = (payload) ->
  switch payload.actionType
    when "add-item"
      # synchronous event flow!
      MyDispatcher.waitFor [TodoStore.dispatchToken]

      MessageStore.items.push "You added an item! It was: " + payload.item

module.exports = MessageStore

```

In practice, I was shocked to see how much cleaner my code was when using this approach to modify my Stores, even without using `waitFor`.

#### Stores

So data flows *into* Stores through the Dispatcher. Got it. But how does data flow from the Stores to the Views (React)?

> [The] view listens for events that are broadcast by the stores that it depends on.

Okay, great. Just like we registered callbacks with our Stores, we register callbacks with our Views (which are React Components). We tell React to re-`render` whenever a change occurs in the Store which was passed in through its `props`. 

For example: 

```coffee
# in TodoListComponent.coffee
React = require("react")

TodoListComponent = React.createClass
  componentDidMount: ->
    @props.TodoStore.addEventListener "change", =>
      @forceUpdate()
    , @

  componentWillUnmount: ->
    # remove the callback

  render: ->
    # show the items in a list.
    React.DOM.ul {}, @props.TodoStore.items.map (item) ->
      React.DOM.li {}, item

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

## Flux Stores: the Missing Piece

Backbone's Models and Collections already have everything Flux's EventEmitter-based Stores seem to be doing. 

By telling you to use raw EventEmitter, Flux is recommending that you recreate maybe 50-75% of Backbone's Models & Collections every time you create a Store. Using "EventEmitter" for your stores is like using "Node.js" for your server. Okay, I'll do that, but I'll do it through Express.js or equivalent: a well-built microframework that's taken care of all the basics and boilerplate. 

Just like Express.js is built on Node.js, Backbone's Models and Collections are built on EventEmitter. And it has all the stuff you pretty much always need: Backbone emits `"change"` events and has query methods and getters and setters and everything. Plus, [jashkenas](https://github.com/jashkenas) and his army of [230 contributors](https://github.com/jashkenas/backbone/graphs/contributors) did a much better job on all of those things than I ever will.

As an example, I converted [the MessageStore example](https://github.com/facebook/flux/blob/master/examples/flux-chat/js/stores/MessageStore.js) from above to [a "FluxBone" version](#file-messagestore-fluxbone-js). (Note that it's incomplete (ie; I only converted that file) and is untested).

It's objectively less code (no need to duplicate work) and is subjectively more clear/concise (eg; `this.add(message)` instead of `_messages[message.id] = message`).

So let's use Backbone for Stores! 

## The FluxBone Pattern &copy;: Flux Stores by Backbone.

1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. Typically, this means they are singletons. 
2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.
3. Components query Stores and bind to their events to trigger updates.

Let's look at each piece of that in turn: 

#### 1. Stores are instantiated Backbone Models or Collections, which have registered a callback with the Dispatcher. 

```coffee
# in TodoDispatcher.coffee
Dispatcher = require("flux").Dispatcher

TodoDispatcher = new Dispatcher() # tah-dah! Really, that's all it takes.

module.exports = TodoDispatcher

```

```coffee
# in stores/TodoStore.coffee
Backbone = require("backbone")
TodoDispatcher = require("../dispatcher")

TodoItem = Backbone.Model.extend({})

TodoCollection = Backbone.Collection.extend
  model: TodoItem
  url: "/todo"

  # we register a callback with the Dispatcher on init.
  initialize: ->
    @dispatchToken = TodoDispatcher.register(@dispatchCallback)

  dispatchCallback: (payload) =>
    switch payload.actionType
      # remove the Model instance from the Store.
      when "todo-delete"
        @remove payload.todo
      when "todo-add"
        @add payload.todo
      when "todo-update"
        # do stuff...
        @add payload.todo,
          merge: true
      # ... etc


# the Store is an instantiated Collection; a singleton.
TodoStore = new TodoCollection()
module.exports = TodoStore

```

#### 2. Components *never* directly modify Stores (eg; no `.set()`). Instead, components dispatch Actions to the Dispatcher.

```coffee
# components/TodoComponent.coffee
React = require("react")

TodoListComponent = React.createClass
  handleTodoDelete: ->
    # instead of removing the todo from the TodoStore directly,
    # we use the dispatcher. #flux
    TodoDispatcher.dispatch
      actionType: "todo-delete"
      todo: @props.todoItem
  # ... (see below) ...

module.exports = TodoListComponent

```

#### 3. Components query Stores and bind to their events to trigger updates.

```coffee
# components/TodoComponent.coffee
React = require("react")

TodoListComponent = React.createClass
  handleTodoDelete: ->
    # instead of removing the todo from the TodoStore directly,
    # we use the dispatcher. #flux
    TodoDispatcher.dispatch
      actionType: "todo-delete"
      todo: @props.todoItem
  # ...
  componentDidMount: ->
    # the Component binds to the Store's events
    @props.TodoStore.on "add remove reset", =>
      @forceUpdate()
    , @
  componentWillUnmount: ->
    # turn off all events and callbacks that have this context
    @props.TodoStore.off null, null, this
  render: ->
    React.DOM.ul {},
      @props.TodoStore.items.map (todoItem) ->
        # TODO: TodoItemComponent, which would bind to
        # `this.props.todoItem.on('change')`
        TodoItemComponent {
          todoItem: todoItem
        }

module.exports = TodoListComponent

```

In fact, once I re-architected my application to use this pattern, almost all the ugly bits disappeared. It was a little miraculous: one by one, the pieces of code that had me gnashing my teeth looking for a better way were replaced by sensible flow. And the smoothness with which Backbone seems to integrate in this pattern is remarkable: I don't feel like I'm fighting Backbone, Flux, or React in order to fit them together. 

### Example Mixin

Writing the `this.on(...)` and `this.off(...)` code every time you add a FluxBone Store to a component can get a bit old (at least when you're spoiled enough to not have to write any EventEmitter code yourself).

Here's an example React Mixin that, while extremely naiive, would certainly make iterating quickly even easier: 

```coffee
# in FluxBoneMixin.coffee
module.exports = (propName) ->
  componentDidMount: ->
    @props[propName].on "all", =>
      @forceUpdate()
    , @

  componentWillUnmount: ->
    @props[propName].off "all", =>
      @forceUpdate()
    , @

```

```coffee
# in HelloComponent.coffee
React = require("react")

UserStore = require("./stores/UserStore")
TodoStore = require("./stores/TodoStore")

FluxBoneMixin = require("./FluxBoneMixin")


MyComponent = React.createClass
  mixins: [
    FluxBoneMixin("UserStore"),
    FluxBoneMixin("TodoStore"),
  ]
  render: ->
    React.DOM.div {},
      "Hello, #{ @props.UserStore.get('name') },
      you have #{ @props.TodoStore.length }
      things to do."

React.renderComponent(
  MyComponent {
    UserStore: UserStore
    TodoStore: TodoStore
  }
  , document.body.querySelector(".main")
)
```

### Syncing with a Web API

In the original Flux diagram, you interact with the Web API through ActionCreators only. That never sat right with me; shouldn't the Store be the first to know about changes, before the server? 

I flip that part of the diagram around: the Stores interact directly with a RESTful CRUD API through Backbone's `sync()`. This is wonderfully convenient, at least if you're working with an actual RESTful CRUD API. 

This is great for data integrity. When you `.set()` a new property, the `change` event triggers a React re-render, optimistically displaying the new data. When you try to `.save()` it to the server, the `request` event lets you know to display a loading icon. When things go through, the `sync` event lets you know to remove the loading icon, or the `error` event lets you know to turn things red. You can see inspiration [here](https://news.ycombinator.com/item?id=7721867). 

There's also validation (and a corresponding `invalid` event) for a first layer of defense, and a `.fetch()` method to pull new information from the server. 

For less standard tasks, interacting via ActionCreators may make more sense.  I suspect Facebook doesn't do much "mere CRUD", in which case it's not surprising they don't put Stores first. 

## Conclusion

The Engineering teams at Facebook and Instagram have done remarkable work to push the frontend web forward with React, and the introduction of Flux gives a peek into a broader architecture that truly scales: not just in terms of technology, but engineering as well. Clever and careful use of Backbone can fill the gaps in Flux, making it amazingly easy for anyone from one-person indie shops to large companies to create and maintain impressive applications.

### Next Steps

- React and Flux have been criticized for not including Routes. I'm hopeful that Backbone's Router, perhaps coupled with a FluxBone `CurrentPageStore`, will provide this. 

- Lastly, I'd love feedback on the above! Does this seem like a good pattern to you? Are there improvements or flaws you would suggest ammending?
  