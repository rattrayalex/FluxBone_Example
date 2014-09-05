var ChatAppDispatcher = require('../dispatcher/ChatAppDispatcher');
var ChatConstants = require('../constants/ChatConstants');
var ChatMessageUtils = require('../utils/ChatMessageUtils');
var EventEmitter = require('events').EventEmitter;
var ThreadStore = require('../stores/ThreadStore');
var merge = require('react/lib/merge');

var ActionTypes = ChatConstants.ActionTypes;
var CHANGE_EVENT = 'change';


// FluxBone!
var Backbone = require('backbone');


// now, that wasn't so painful, was it?
var Message = Backbone.Model.extends({

  // same as before
  getCreatedMessageData: function(text) {
    var timestamp = Date.now();
    return {
      id: 'm_' + timestamp,
      threadID: ThreadStore.getCurrentID(),
      authorName: 'Bill', // hard coded for the example
      date: new Date(timestamp),
      text: text,
      isRead: true
    };
  }

});

var MessageCollection = Backbone.Collection.extends({
  model: Message,

  // emitChange not needed, already implemented.

  // addChangeListener not needed,
  // use MessageStore.on('change', callback) instead.
  // (since "change" is in the Backbone library,
  // you don't have to put it in a CONSTANT)

  // get() not needed, already implemented as get()

  // getAll() not needed, use `.models` or `.where()` or `.forEach()`


  getAllForThread: function(threadId) {
    // now isn't that readable! who needs a for loop?
    var threadMessages = this.where({threadId: threadId});

    // not really sure what this is, so just copied it in.
    // only change is using the Backbone getter.
    threadMessages.sort(function(a, b) {
      if (a.get('date') < b.get('date')) {
        return -1;
      } else if (a.get('date') > b.get('date')) {
        return 1;
      }
      return 0;
    });

    return threadMessages;
  },

  // copied verbatim.
  getAllForCurrentThread: function() {
    return this.getAllForThread(ThreadStore.getCurrentID());
  },

  addMessages: function(rawMessages) {
    rawMessages.forEach(function(message) {
      // don't need to check for existence first, Backbone handles that.
      this.add( ChatMessageUtils.convertRawMessage(
        message,
        ThreadStore.getCurrentID()
      ) );
    }.bind(this))
  },

  markAllInThreadRead: function(threadId) {
    // wow, look! querying!
    // and no need to emit a change event ourselves!
    this.where( {threadId: threadId} ).forEach( function(message){
      message.set( {isRead: true} );
    });
  },

  initialize: function () {
    this.dispatchToken = ChatAppDispatcher.register(this.dispatchCallback);
  },

  dispatchCallback: function (payload) {
    var action = payload.action;
    switch(action.type) {

      case ActionTypes.CLICK_THREAD:
        ChatAppDispatcher.waitFor([ThreadStore.dispatchToken]);
        this.markAllInThreadRead( ThreadStore.getCurrentID() );
        // don't need to emit a change event!
        break;

      case ActionTypes.CREATE_MESSAGE:
        var message = Message.getCreatedMessageData(action.text);
        // wow, check that syntax! so clear! so terse!
        this.add(message);
        // don't need to emit a change event ourselves.
        break;

      case ActionTypes.RECEIVE_RAW_MESSAGES:
        this.addMessages(action.rawMessages);
        ChatAppDispatcher.waitFor([ThreadStore.dispatchToken]);
        this.markAllInThreadRead(ThreadStore.getCurrentID());
        // don't need to emit a change event!
        break;

      default:
        // do nothing
    }
  }.bind(this)
});

// tadah, we have a Store!
var MessageStore = new MessageCollection();

module.exports = MessageStore;