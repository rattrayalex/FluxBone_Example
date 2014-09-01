var React = require('react');
var Backbone = require('backbone');
var Dispatcher = require('Flux').Dispatcher;

// ------------------------------------------------------------------------
// Dispatcher. Ordinarily, this would go in dispatcher.js

TodoDispatcher = new Dispatcher();


// ------------------------------------------------------------------------
// Actions. Ordinarily, this would go in actions.js or an actions/ dir.

actionCreator = {
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
    this.dispatchToken = TodoDispatcher.register(this.dispatchCallback)
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

    actionCreator.deleteTodo(this.props.todoItem)
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
