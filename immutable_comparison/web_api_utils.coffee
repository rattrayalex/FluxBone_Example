MyDispatcher = require './MyDispatcher'
$ = require 'jQuery'

WebApiUtilsDispatchToken = MyDispatcher.register (payload) ->
  switch payload.actionType
    when 'add-todo'
      $.ajax
        url: "/todo"
        method: 'POST'
        data:
          body: payload.body
          creator: payload.creator
          creationTime: transformDate(payload.creationTime)

      .then (data, status, xhr) ->
        MyDispatcher.dispatch
          actionType: 'web-success'
          itemType: 'todo'
          item: data

    when 'remove-item'
      $.ajax
        url: "/todo/#{ payload.id }"
        method: "DELETE"

      .then (data, status, xhr) ->
        MyDispatcher.dispatch
          actionType: 'web-success'
          itemType: 'todo'
          item: data

module.exports = WebApiUtilsDispatchToken
