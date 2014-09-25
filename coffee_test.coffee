myFunc = (number) ->

  for i in [0..number]

    setTimeout ->
      console.log 'hello ' + i
    , 1000


myFunc(10)