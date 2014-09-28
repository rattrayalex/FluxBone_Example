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