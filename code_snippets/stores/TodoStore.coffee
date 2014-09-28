# in stores/TodoStore.js
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
