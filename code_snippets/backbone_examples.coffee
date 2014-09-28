Backbone = require("backbone")

TodoItem = Backbone.Model.extend({})

TodoCollection = Backbone.Collection.extend(
  model: TodoItem
  url: "/todo"
  initialize: ->
    @fetch() # sends `GET /todo` and populates the models if there are any.
)

TodoList = new TodoCollection() # initialize() called. Let's assume no todos were returned.

itemOne = new TodoItem(name: "buy milk")
TodoList.add(itemOne) # this will send `POST /todo` with `name=buy milk`

itemTwo = TodoList.create({name: "take out trash"}) # shortcut for above.

TodoList.remove(itemOne) # sends `DELETE /todo/1`

itemTwo.on "change", ->
  console.log "itemTwo was changed!"

itemTwo.on "sync", ->
  console.log "itemTwo synced to server!"

itemTwo.destroy() # sends `DELETE /todo/2`.
# > itemTwo was changed!
# > itemTwo synced to server!
