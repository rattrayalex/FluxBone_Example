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
