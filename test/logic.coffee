# Requires
require "coffee-script"
assert = require('assert')
_ = require "underscore"
Logic = require("../src/logic")
_.query = Logic.query

_collection =  [
  {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
  {title:"About", colors:["red"], likes:2, featured: true, content: "dummy content about javascript"}
  {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
]


create = -> _.clone(_collection)

describe "Underscore Query Tests", ->

  it "Says hello", ->
    assert true

  it "Equals query", ->
    a = create()
    result = _.query a, title:"Home"
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

    result = _.query a, colors: "blue"
    assert.equal result.length, 2

    result = _.query a, colors: {$deepEquals: ["red", "blue"]}
    assert.equal result.length, 1

  it "Simple equals query (no results)", ->
    a = create()
    result = _.query a, title:"Homes"
    assert.equal result.length, 0

  it "Simple equals query (boolean)", ->
    a = create()
    result = _.query a, featured: true
    assert.equal result.length, 2


  it "Simple equals query with explicit $equal", ->
    a = create()
    result = _.query a, title: {$equal: "About"}
    assert.equal result.length, 1
    assert.equal result[0].title, "About"
#
  it "$contains operator", ->
    a = create()
    result = _.query a, colors: {$contains: "blue"}
    assert.equal result.length, 2

  it "$ne operator", ->
    a = create()
    result = _.query a, title: {$ne: "Home"}
    assert.equal result.length, 2

  it "$lt operator", ->
    a = create()
    result = _.query a, likes: {$lt: 12}
    assert.equal result.length, 1
    assert.equal result[0].title, "About"

  it "$lte operator", ->
    a = create()
    result = _.query a, likes: {$lte: 12}
    assert.equal result.length, 2

  it "$gt operator", ->
    a = create()
    result = _.query a, likes: {$gt: 12}
    assert.equal result.length, 1
    assert.equal result[0].title, "Contact"

  it "$gte operator", ->
    a = create()
    result = _.query a, likes: {$gte: 12}
    assert.equal result.length, 2

  it "$between operator", ->
    a = create()
    result = _.query a, likes: {$between: [1,5]}
    assert.equal result.length, 1
    assert.equal result[0].title, "About"

  it "$mod operator", ->
    a = create()
    result = _.query a, likes: {$mod: [3,0]}
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$in operator", ->
    a = create()
    result = _.query a, title: {$in: ["Home","About"]}
    assert.equal result.length, 2

  it "$in operator with wrong query value", ->
    a = create()
    assert.throws ->
       _.query a, title: {$in: "Home"}

  it "$nin operator", ->
    a = create()
    result = _.query a, title: {$nin: ["Home","About"]}
    assert.equal result.length, 1
    assert.equal result[0].title, "Contact"
#
  it "$all operator", ->
    a = create()
    result = _.query a, colors: {$all: ["red","blue"]}
    assert.equal result.length, 2

  it "$all operator (wrong values)", ->
    a = create()
    result = _.query a, title: {$all: ["red","blue"]}
    assert.equal result.length, 0

    assert.throws ->
      _.query a, colors: {$all: "red"}

  it "$any operator", ->
    a = create()
    result = _.query a, colors: {$any: ["red","blue"]}
    assert.equal result.length, 3

    result = _.query a, colors: {$any: ["yellow","blue"]}
    assert.equal result.length, 2

  it "$size operator", ->
    a = create()
    result = _.query a, colors: {$size: 3}
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$exists operator", ->
    a = create()
    result = _.query a, featured: {$exists: true}
    assert.equal result.length, 2

  it "$has operator", ->
    a = create()
    result = _.query a, featured: {$exists: false}
    assert.equal result.length, 1
    assert.equal result[0].title, "Contact"

  it "$like operator", ->
    a = create()
    result = _.query a, content: {$like: "javascript"}
    assert.equal result.length, 1
    assert.equal result[0].title, "About"

  it "$like operator 2", ->
    a = create()
    result = _.query a, content: {$like: "content"}
    assert.equal result.length, 3

  it "$likeI operator", ->
    a = create()
    result = _.query a, content: {$likeI: "dummy"}
    assert.equal result.length, 3
    result = _.query a, content: {$like: "dummy"}
    assert.equal result.length, 1

  it "$startsWith operator", ->
    a = create()
    result = _.query a, title: {$startsWith: "Ho"}
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$endsWith operator", ->
    a = create()
    result = _.query a, title: {$endsWith: "me"}
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"


  it "$regex", ->
    a = create()
    result = _.query a, content: {$regex: /javascript/gi}
    assert.equal result.length, 1
    assert.equal result[0].title, "About"

  it "$regex2", ->
    a = create()
    result = _.query a, content: {$regex: /dummy/}
    assert.equal result.length, 1

  it "$regex3", ->
    a = create()
    result = _.query a, content: {$regex: /dummy/i}
    assert.equal result.length, 3

  it "$regex4", ->
    a = create()
    result = _.query a, content: /javascript/i
    assert.equal result.length, 1

  it "$cb - callback", ->
    a = create()
    fn = (attr) ->
      attr.charAt(0).toLowerCase() is "c"
    result = _.query a,
      title: $cb: fn

    assert.equal result.length, 1
    assert.equal result[0].title, "Contact"

#  it "$cb - callback - checking 'this' is the model", ->
#    a = create()
#    result = _.query a, title:
#      $cb: (attr) -> @title is "Home"
#    assert.equal result.length, 1
#    assert.equal result[0].title, "Home"
#
  it "$and operator", ->
    a = create()
    result = _.query a, likes: {$gt: 5}, colors: {$contains: "yellow"}
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$and operator (object)", ->
    a = create()
    result = _.query a, $and: [{likes: {$gt: 5}}, {colors: {$contains: "yellow"}}]
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$and operator (explicit)", ->
    a = create()
    result = _.query a, $and: [{likes: {$gt: 5}}, {colors: {$contains: "yellow"}}]
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

  it "$or operator", ->
    a = create()
    result = _.query a, $or: [{likes: {$gt: 5}}, {colors: {$contains: "yellow"}}]
    assert.equal result.length, 2

  it "$or2 operator", ->
    a = create()
    result = _.query a, $or: [{likes: {$gt: 5}}, {featured: true}]
    assert.equal result.length, 3

  it "$nor operator", ->
    a = create()
    result = _.query a, $nor: [{likes: {$gt: 5}}, {colors: {$contains: "yellow"}}]
    assert.equal result.length, 1
    assert.equal result[0].title, "About"

  it "Compound Queries", ->
    a = create()
    result = _.query a, $and: {likes: {$gt: 5}}, $or: {content: {$like: "PHP"},  colors: {$contains: "yellow"}}
    assert.equal result.length, 2

    result = _.query a,
      $and:
        likes: $lt: 15
      $or:
        content:
          $like: "Dummy"
        featured:
          $exists:true
      $not:
        colors: $contains: "yellow"
    assert.equal result.length, 1
    assert.equal result[0].title, "About"


  it "$not operator", ->
    a = create()
    result = _.query a, {$not: {likes:  {$lt: 12}}}
    assert.equal result.length, 2

  #These tests fail, but would pass if it $not worked parallel to MongoDB
  it "$not operator", ->
    a = create()
    result = _.query a, {likes:  {$not: {$lt: 12}}}
    assert.equal result.length, 2

  it "$not operator", ->
    a = create()
    result = _.query a, likes: {$not:  12}
    assert.equal result.length, 2

  it "$not $equal operator", ->
    a = create()
    result = _.query a, likes: {$not:  {$equal: 12}}
    assert.equal result.length, 2

  it "$not $equal operator", ->
    a = create()
    result = _.query a, likes: {$not:  {$ne: 12}}
    assert.equal result.length, 1



  it "$elemMatch", ->
    a = [
      {title: "Home", comments:[
        {text:"I like this post"}
        {text:"I love this post"}
        {text:"I hate this post"}
      ]}
      {title: "About", comments:[
        {text:"I like this page"}
        {text:"I love this page"}
        {text:"I really like this page"}
      ]}
    ]

    b = [
      {foo: [
        {shape: "square", color: "purple", thick: false}
        {shape: "circle", color: "red", thick: true}
      ]}
      {foo: [
        {shape: "square", color: "red", thick: true}
        {shape: "circle", color: "purple", thick: false}
      ]}
    ]

    console.log("=========================================")
    text_search = {$likeI: "love"}

    result = _.query a, $or:
      comments:
        $elemMatch:
          text: text_search
      title: text_search
    assert.equal result.length, 2

    result = _.query a, $or:
      comments:
        $elemMatch:
          text: /post/
    assert.equal result.length, 1

    result = _.query a, $or:
      comments:
        $elemMatch:
          text: /post/
      title: /about/i
    assert.equal result.length, 2

    result = _.query a, $or:
      comments:
        $elemMatch:
          text: /really/
    assert.equal result.length, 1

    result = _.query b,
      foo:
        $elemMatch:
          shape:"square"
          color:"purple"

    assert.equal result.length, 1
    assert.equal result[0].foo[0].shape, "square"
    assert.equal result[0].foo[0].color, "purple"
    assert.equal result[0].foo[0].thick, false


  it "$any and $all", ->
    a = name: "test", tags1: ["red","yellow"], tags2: ["orange", "green", "red", "blue"]
    b = name: "test1", tags1: ["purple","blue"], tags2: ["orange", "red", "blue"]
    c = name: "test2", tags1: ["black","yellow"], tags2: ["green", "orange", "blue"]
    d = name: "test3", tags1: ["red","yellow","blue"], tags2: ["green"]
    e = [a,b,c,d]

    result = _.query e,
      tags1: $any: ["red","purple"] # should match a, b, d
      tags2: $all: ["orange","green"] # should match a, c

    assert.equal result.length, 1
    assert.equal result[0].name, "test"

  it "$elemMatch - compound queries", ->
    a = [
      {title: "Home", comments:[
        {text:"I like this post"}
        {text:"I love this post"}
        {text:"I hate this post"}
      ]}
      {title: "About", comments:[
        {text:"I like this page"}
        {text:"I love this page"}
        {text:"I really like this page"}
      ]}
    ]

    result = _.query a,
      comments:
        $elemMatch:
          $not:
            text:/page/

    assert.equal result.length, 1


  # Test from RobW - https://github.com/Rob--W
  it "Explicit $and combined with matching $or must return the correct number of items", ->
    Col = [
      {equ:'ok', same: 'ok'},
      {equ:'ok', same: 'ok'}
    ]
    result = _.query Col,
      $and:
        equ: 'ok'         # Matches both items
        $or:
          same: 'ok'      # Matches both items
    assert.equal result.length, 2

  # Test from RobW - https://github.com/Rob--W
  it "Implicit $and consisting of non-matching subquery and $or must return empty list", ->
    Col = [
      {equ:'ok', same: 'ok'},
      {equ:'ok', same: 'ok'}
    ]
    result = _.query Col,
      equ: 'bogus'        # Matches nothing
      $or:
        same: 'ok'        # Matches all items, but due to implicit $and, this subquery should not affect the result
    assert.equal result.length, 0

  it "Testing nested compound operators", ->
    a = create()
    result = _.query a,
      $and:
        colors: $contains: "blue" # Matches 1,3
        $or:
          featured:true # Matches 1,2
          likes:12 # Matches 1
      # And only matches 1

      $or:[
        {content:$like:"dummy"} # Matches 2
        {content:$like:"Dummy"} # Matches 1,3
      ]
    # Or matches 3
    assert.equal result.length, 1

    result = _.query a,
      $and:
        colors: $contains: "blue" # Matches 1,3
        $or:
          featured:true # Matches 1,2
          likes:20 # Matches 3
      # And only matches 2

      $or:[
        {content:$like:"dummy"} # Matches 2
        {content:$like:"Dummy"} # Matches 1,3
      ]
    # Or matches 3
    assert.equal result.length, 2

  it "works with queries supplied as arrays", ->
    a = create()
    result = _.query a,
      $or: [
        {title:"Home"}
        {title:"About"}
      ]
    assert.equal result.length, 2
    assert.equal result[0].title, "Home"
    assert.equal result[1].title, "About"

#  it "works with underscore chain", ->
#    a = create()
#    q =
#      $or: [
#        {title:"Home"}
#        {title:"About"}
#      ]
#    result = _.chain(a).query(q).pluck("title").value()
#
#    assert.equal result.length, 2
#    assert.equal result[0], "Home"
#    assert.equal result[1], "About"
##
  it "works with a getter property", ->
    Backbone = require "backbone"
    a = new Backbone.Collection [
      {id:1, title:"test"}
      {id:2, title:"about"}
    ]
    result = _.query a.models, {title:"about"}, "get"
    assert.equal result.length, 1
    assert.equal result[0].get("title"), "about"


  it "works with a getter function", ->
    Backbone = require "backbone"

    getter = (obj,key) -> obj[key]* 2.5

    a = create()
    result = _.query a, likes: 30, getter
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"


  it "can be mixed into backbone collections", ->
    Backbone = require "backbone"
    class Collection extends Backbone.Collection
      query: (params) -> _.query @models, params, "get"
      whereBy: (params) -> new @constructor @query(params)
      buildQuery: -> _.query.build @models, "get"

    a = new Collection [
      {id:1, title:"test"}
      {id:2, title:"about"}
    ]
    result = a.query {title:"about"}
    assert.equal result.length, 1
    assert.equal result[0].get("title"), "about"


    result2 = a.whereBy {title:"about"}
    assert.equal result2.length, 1
    assert.equal result2.at(0).get("title"), "about"
    assert.equal result2.pluck("title")[0], "about"

#    result3 = a.buildQuery().not(title:"test").run()
#    assert.equal result3.length, 1
#    assert.equal result3[0].get("title"), "about"



#  it "can be used for live collections", ->
#    Backbone = require "backbone"
#    class Collection extends Backbone.Collection
#      query: (params) ->
#        if params
#          _.query @models, params, "get"
#        else
#          _.query.build @models, "get"
#      whereBy: (params) -> new @constructor @query(params)
#      setFilter: (parent, query) ->
#
#        check = _.query.tester(query, "get")
#
#        @listenTo parent,
#          add: (model) -> if check(model) then @add(model)
#          remove: @remove
#          change: (model) ->
#            if check(model) then @add(model) else @remove(model)
#
#        @add _.query(parent.models, query, "get")
#
#    parent = new Collection [
#      {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
#      {title:"About", colors:["red"], likes:2, featured:true, content: "dummy content about javascript"}
#      {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
#    ]
#    live = new Collection
#    live.setFilter parent, {likes:$gt:15}
#
#    assert.equal parent.length, 3
#    assert.equal live.length, 1
#
#    # Change Events
#    parent.at(0).set("likes",16)
#    assert.equal live.length, 2
#    parent.at(2).set("likes",2)
#    assert.equal live.length, 1
#
#    # Add to Parent
#    parent.add [{title:"New", likes:21}, {title:"New2", likes:3}]
#    assert.equal live.length, 2
#    assert.equal parent.length, 5
#
#    # Remove from Parent
#    parent.pop()
#    parent.pop()
#    assert.equal live.length, 1
#
#  it "buildQuery works in oo fashion", ->
#    a = create()
#    query = _.query.build(a)
#      .and({likes: {$gt: 5}})
#      .or({content: {$like: "PHP"}})
#      .or({colors: {$contains: "yellow"}})
#
#    result = query.run()
#
#    assert.equal result.length, 2
#
#    result = _.query.build()
#      .and(likes: $lt: 15)
#      .or(content: $like: "Dummy")
#      .or(featured: $exists: true)
#      .not(colors: $contains: "yellow")
#      .run(a)
#
#    assert.equal result.length, 1
#    assert.equal result[0].title, "About"
#
#
#
#  it "works with dot notation", ->
#    collection =  [
#      {title:"Home", stats:{likes:10, views:{a:{b:500}}}}
#      {title:"About", stats:{likes:5, views:{a:{b:234}}}}
#      {title:"Code", stats:{likes:25, views:{a:{b:796}}}}
#    ]
#
#    result = _.query collection, {"stats.likes":5}
#    assert.equal result.length, 1
#    assert.equal result[0].title, "About"
#
#    result = _.query collection, {"stats.views.a.b":796}
#    assert.equal result.length, 1
#    assert.equal result[0].title, "Code"
#
#  it "works with seperate query args", ->
#    collection =  [
#      {title:"Home", stats:{likes:10, views:{a:{b:500}}}}
#      {title:"About", stats:{likes:5, views:{a:{b:234}}}}
#      {title:"Code", stats:{likes:25, views:{a:{b:796}}}}
#    ]
#    query = _.query.build(collection)
#      .and("title", "Home")
#    result = query.run()
#
#    assert.equal result.length, 1
#    assert.equal result[0].title, "Home"
#
#  it "$computed", ->
#    Backbone = require "backbone"
#    class testModel extends Backbone.Model
#      full_name: -> "#{@get 'first_name'} #{@get 'last_name'}"
#
#    a = new testModel
#      first_name: "Dave"
#      last_name: "Tonge"
#    b = new testModel
#      first_name: "John"
#      last_name: "Smith"
#    c = [a,b]
#
#    result = _.query c,
#      full_name: $computed: "Dave Tonge"
#
#    assert.equal result.length, 1
#    assert.equal result[0].get("first_name"), "Dave"
#
#    result = _.query c,
#      full_name: $computed: $likeI: "n sm"
#    assert.equal result.length, 1
#    assert.equal result[0].get("first_name"), "John"
#
  it "Handles multiple inequalities", ->
    a = create()
    result = _.query a, likes: {  $gt: 2, $lt: 20  }
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

    result = _.query a, likes: {  $gte: 2, $lt: 20  }
    assert.equal result.length, 2
    assert.equal result[0].title, "Home"
    assert.equal result[1].title, "About"

    result = _.query a, likes: {  $gt: 2, $lte: 20  }
    assert.equal result.length, 2
    assert.equal result[0].title, "Home"
    assert.equal result[1].title, "Contact"

    result = _.query a, likes: {  $gte: 2, $lte: 20  }
    assert.equal result.length, 3
    assert.equal result[0].title, "Home"
    assert.equal result[1].title, "About"
    assert.equal result[2].title, "Contact"

    result = _.query a, likes: {  $gte: 2, $lte: 20, $ne: 12  }
    assert.equal result.length, 2
    assert.equal result[0].title, "About"
    assert.equal result[1].title, "Contact"

  it "Handles nested multiple inequalities", ->
    a = create()
    result = _.query a, $and: [likes: {  $gt: 2, $lt: 20  }]
    assert.equal result.length, 1
    assert.equal result[0].title, "Home"

#  it "has a score method", ->
#    collection = [
#      { name:'dress',  color:'red',   price:100 }
#      { name:'shoes',  color:'black', price:120 }
#      { name:'jacket', color:'blue',  price:150 }
#    ]
#
#    results = _.query.score( collection, { price: {$lt:140}, color: {$in:['red', 'blue'] }})
#
#    assert.equal _.findWhere(results, {name:'dress'})._score, 1
#    assert.equal _.findWhere(results, {name:'shoes'})._score, 0.5
#
#  it "has a score method with a $boost operator", ->
#    collection = [
#      { name:'dress',  color:'red',   price:100 }
#      { name:'shoes',  color:'black', price:120 }
#      { name:'jacket', color:'blue',  price:150 }
#    ]
#
#    results = _.query.score( collection, { price: 100, color: {$in:['black'], $boost:3 }})
#
#    assert.equal _.findWhere(results, {name:'dress'})._score, 0.5
#    assert.equal _.findWhere(results, {name:'shoes'})._score, 1.5
#
#  it "has a score method with a $boost operator - 2", ->
#    collection = [
#      { name:'dress',  color:'red',   price:100 }
#      { name:'shoes',  color:'black', price:120 }
#      { name:'jacket', color:'blue',  price:150 }
#    ]
#
#    results = _.query.score( collection, { name: {$like:'dre', $boost:5}, color: {$in:['black'], $boost:2 }})
#
#    assert.equal _.findWhere(results, {name:'dress'})._score, 2.5
#    assert.equal _.findWhere(results, {name:'shoes'})._score, 1
#
#  it "score method throws if compound query", ->
#    collection = [
#      { name:'dress',  color:'red',   price:100 }
#      { name:'shoes',  color:'black', price:120 }
#      { name:'jacket', color:'blue',  price:150 }
#    ]
#
#    assert.throws ->
#      _.query.score collection,
#        $and: price: 100
#        $or: [
#          {color: 'red'}
#          {color: 'blue'}
#        ]
#
#  it "score method throws if non $and query", ->
#    collection = [
#      { name:'dress',  color:'red',   price:100 }
#      { name:'shoes',  color:'black', price:120 }
#      { name:'jacket', color:'blue',  price:150 }
#    ]
#
#    assert.throws ->
#      _.query.score collection,
#        $or: [
#          {color: 'red'}
#          {color: 'blue'}
#        ]

  # not parallel to MongoDB
  it "$not operator", ->
    a = create()
    result = _.query a, {$not: {likes:  {$lt: 12}}}
    assert.equal result.length, 2

  # This is parallel to MongoDB
  it "$not operator - mongo style", ->
    a = create()
    result = _.query a, {likes:  {$not: {$lt: 12}}}
    assert.equal result.length, 2

  # This is parallel to MongoDB
  it "$not operator - mongo style", ->
    a = create()
    result = _.query a, {likes:  {$not: 12}}
    assert.equal result.length, 2

  it "combination of $gt and $lt - mongo style", ->
    a = create()
    result = _.query a, {likes: { $gt: 2, $lt: 20}}
    assert.equal result.length, 1

  it "$not combination of $gt and $lt  - mongo style", ->
    a = create()
    result = _.query a, {likes: {$not: { $gt: 2, $lt: 20}}}
    assert.equal result.length, 2

  it "$nor combination of $gt and $lt  - expressions ", ->
    a = create()
    result = _.query a, {$nor: [{likes: { $gt: 2}}, {likes: { $lt: 20}}]}
    assert.equal result.length, 0

#  This query is not a valid MongoDB query, but if it were one would expect it to yield an empty set
  it "$nor combination of $gt and $lt  - values", ->
    a = create()
    result = _.query a, {likes: {$nor: [{ $gt: 2}, {$lt: 20}]}}
    assert.equal result.length, 0

  it "combination of $gt  and $not", ->
    a = create()
    result = _.query a, {likes: { $not: 2, $lt: 20}}
    assert.equal result.length, 1

  it "$type operator", ->
    a = create()
    result = _.query a, {likes: { $type: 'number'}}
    assert.equal result.length, 3
    result = _.query a, {likes: { $type: 'string'}}
    assert.equal result.length, 0
    result = _.query a, {colors: { $type: 'object'}}
    assert.equal result.length, 3
    result = _.query a, {title: { $type: 'string'}}
    assert.equal result.length, 3


  it "returns Query function", ->
    a = create()
    fn = Logic.Query {likes: 12}
    result = a.filter fn
    assert.equal result.length, 1
    assert.equal result[0].likes, 12


  it "$or operator", ->
    a = create()

    # This is standard MongoDB syntax, and the test passes
    result = _.query a, {$or: [{likes: {$gt:1, $lte:2}}, {likes: {$gt:11, $lte:12}}]}
    assert.equal result.length, 2


  it "$or operator", ->
    a = create()

    #  This is standard MongoDB syntax, and the test passes
    result = _.query a, {title: "About", $or: [{likes: {$gt:1, $lte:2}}, {likes: {$gt:11, $lte:12}}]}
    assert.equal result.length, 1

    # This is not standard MongoDB syntax but I would like it to work
    result = _.query a, {likes:{ $or: [{$gt:1, $lte:2}, {$gt:11, $lte:12}]}}
    assert.equal result.length, 2
    console.log result
#

it "Handles nested multiple inequalities: value and $and", ->
  a = create()
  result = _.query a, $and: [{likes: {  $gt: 2, $lt: 20  }}]
  assert.equal result.length, 1
  assert.equal result[0].title, "Home"

  a = create()
  query = $and: [{likes: {  $gt: 2}}, {likes: {$lt: 20  }}]
  result = _.query a, query
  assert.equal result.length, 1
  assert.equal result[0].title, "Home"

it "Handles inverted $and queries", ->
  a = create()
  query = likes: {$and: [{  $gt: 2, $lt: 20  }]}
  result = _.query a, query
  assert.equal result.length, 1
  assert.equal result[0].title, "Home"

  a = create()
  query = likes: {$and: [{  $gt: 2}, {$lt: 20  }]}
  result = _.query a, query
  assert.equal result.length, 1
  assert.equal result[0].title, "Home"

it "Handles nested multiple inequalities: two ands", ->
  a = create()
  result = _.query a, $and: [{likes: {  $gt: 2}}, {likes: {$lt: 20  }} ]
  assert.equal result.length, 1
  assert.equal result[0].title, "Home"

it "Handles nested multiple inequalities: two ors", ->
  a = create()
  result = _.query a, $or: [{likes: {  $lte: 2}}, {likes: {$gte: 20 }} ]
  console.log result
  assert.equal result.length, 2

  assert.equal result[0].title, "About"
  assert.equal result[1].title, "Contact"

# http://docs.mongodb.org/manual/reference/operator/query/and/
it "Handles $or nested within $and", ->

  q = { $and : [
    { $or : [ { likes :2 }, { likes : 20 } ] },
    { $or : [ { title : "Contact" }, { title: "About" } ] }
  ]}
  a = create()
  result = _.query a,q

  assert.equal result.length, 2


it "Handes $where function", ->
  a = create()
  result = _.query a,  $where: -> @likes == 12
  assert.equal result.length,1


it "Handes $where string", ->
  a = create()
  result = _.query a,  $where: " return this.likes >= 12"
  assert.equal result.length,2
