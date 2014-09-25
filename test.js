#!/usr/bin/env node

function myFunc(number) {

  for (var i = 0; i < number; i++) {
    setTimeout(function(){
      console.log('hello ' + i);
    }, 1000)
  }

}

myFunc(10);