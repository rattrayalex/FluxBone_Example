Cortex = require 'cortex'
MyDispatcher = require './MyDispatcher'
WebAPIDispatchToken = require './web_api_utils'

data =
  dispatchToken: MyDispatcher.register(dispatchCallback)
  items: []
  user: {}

_store = new Cortex(data)

dispatchCallback = (payload) ->
  switch payload.actionType
    when 'add-item'
      _store.items.push
        item: payload.item
        creator: payload.creator
        creationTime: payload.creationTime

    when 'web-success'

      switch payload.itemType
        # I'm not really sure the right way to do this...
        # IIRC, some Flux devs were talking about this being
        # a serious problem and floated some very hacky "solutions",
        # which they themselves didn't like at all.
        # So I'm not sure if a more correct solution has emerged since.
        when 'todo'
          item_by_id = _store.items.find (store_item) ->
            payload.item.id is store_item.id?.val()

          if not item_by_id
            item = _store.items.find (store_item) ->
              payload.item.body is store_item.body.val() and
                payload.item.creator is store_item.creator.val() and
                unTransformDate(payload.item.creationTime) is
                  store_item.creationTime.val()

            item.add('id', payload.item.id)


module.exports = _store
