# in FluxBoneMixin.coffee
module.exports = (propName) ->
  componentDidMount: ->
    @props[propName].on "all", =>
      @forceUpdate()
    , @

  componentWillUnmount: ->
    @props[propName].off "all", =>
      @forceUpdate()
    , @
