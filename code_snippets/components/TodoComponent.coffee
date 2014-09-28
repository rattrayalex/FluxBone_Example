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
