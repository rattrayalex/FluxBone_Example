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
