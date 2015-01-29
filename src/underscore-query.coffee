###
Underscore Query - A lightweight query API for JavaScript collections
(c)2015 - Dave Tonge
May be freely distributed according to MIT license.

This is small library that provides a query api for JavaScript arrays similar to *mongo db*.
The aim of the project is to provide a simple, well tested, way of filtering data in JavaScript.
###

# *underscore* is the only dependency for this project.

root = this

### UTILS ###
utils = {}


# ES5 / Coffee Replacement for underscore / lodash utils
underscoreReplacement = ->
  out = {}
  ["every", "some", "filter", "reduce", "map"].forEach (key) ->
    out[key] = (array, args...) ->
      array[key].apply(array, args)

  out.keys = Object.keys
  out.isArray = Array.isArray
  out.result = (obj = {}, key) ->
    if (utils.getType(obj[key]) is "Function") then obj[key]() else obj[key]

  out.detect = (array, fn) ->
    for item in array when fn(item)
      return item
    return

  out.reject = (array, fn) ->
    (item for item in array when not fn(item))

  out.intersection = (array1, array2) ->
    (item for item in array1 when array2.indexOf(item) isnt -1)

  out.isEqual = (a,b) -> JSON.stringify(a) is JSON.stringify(b)
  out


# We assign local references to the underscore methods used.
# If underscore is not supplied we use the above ES5 methods
createUtils = (_) ->
  for key in ["every", "some", "filter", "detect", "reject", "reduce","intersection",
              "isEqual", "keys", "isArray", "result", "map"]
    utils[key] = _[key]
    throw new Error("#{key} missing. Please ensure that you first initialize
      underscore-query with either lodash or underscore") unless utils[key]
  return


# Returns a string denoting the type of object
utils.getType =  (obj) ->
  type = Object.prototype.toString.call(obj).substr(8)
  type.substr(0, (type.length - 1))

# Utility Function to turn 2 values into an object
utils.makeObj = (key, val)->
  (o = {})[key] = val
  o

# Reverses a string
utils.reverseString = (str) -> str.toLowerCase().split("").reverse().join("")

# An array of the compound modifers that can be used in queries
utils.compoundKeys = ["$and", "$not", "$or", "$nor"]

# Returns a getter function that works with dot notation and named functions
utils.makeGetter = (keys) ->
  keys = keys.split(".")
  (obj) ->
    out = obj
    for key in keys
      if out then out = utils.result(out,key)
    out

multipleConditions = (key, queries) ->
  (for type, val of queries
    utils.makeObj key, utils.makeObj(type, val))

parseParamType = (query) ->
  key = utils.keys(query)[0]
  queryParam = query[key]
  o = {key}
  if queryParam?.$boost
    o.boost = queryParam.$boost
    delete queryParam.$boost

  # If the key uses dot notation, then create a getter function
  if key.indexOf(".") isnt -1
    o.getter = utils.makeGetter(key)

  paramType = utils.getType(queryParam)
  switch paramType
  # Test for Regexs and Dates as they can be supplied without an operator
    when "RegExp", "Date"
      o.type = "$#{paramType.toLowerCase()}"
      o.value = queryParam

    when "Object"
    # If the key is one of the compound keys, then parse the param as a raw query
      if key in utils.compoundKeys
        o.type = key
        o.value = parseSubQuery queryParam
        o.key = null

      # Multiple conditions for the same key
      else if utils.keys(queryParam).length > 1
        o.type = "$and"
        o.value = parseSubQuery multipleConditions(key, queryParam)
        o.key = null

      # Otherwise extract the key and value
      else
        for own type, value of queryParam
          # Before adding the query, its value is checked to make sure it is the right type
          if testQueryValue type, value
            o.type = type
            switch type
              when "$elemMatch" then o.value = single(parseQuery(value))
              when "$endsWith" then o.value = utils.reverseString(value)
              when "$likeI", "$startsWith" then o.value = value.toLowerCase()
              when "$not", "$nor", "$or", "$and"
                o.value = parseSubQuery utils.makeObj(o.key, value)
                o.key = null
              when "$computed"
                o = parseParamType(utils.makeObj(key, value))
                o.getter = utils.makeGetter(key)
              else o.value = value
          else throw new Error("Query value (#{value}) doesn't match query type: (#{type})")
    # If the query_param is not an object or a regexp then revert to the default operator: $equal
    else
      o.type = "$equal"
      o.value = queryParam

  # For "$equal" queries with arrays or objects we need to perform a deep equal
  if (o.type is "$equal") and (paramType in ["Object","Array"])
    o.type = "$deepEqual"

  # Return the query object
  return o


# This function parses and normalizes raw queries.
parseSubQuery = (rawQuery) ->

  # Ensure that the query is an array
  if utils.isArray(rawQuery)
    queryArray = rawQuery
  else
    queryArray = (utils.makeObj(key, val) for own key, val of rawQuery)

  # Loop through all the different queries
  (parseParamType(query) for query in queryArray)


# Tests query value, to ensure that it is of the correct type
testQueryValue = (queryType, value) ->
  valueType = utils.getType(value)
  switch queryType
    when "$in","$nin","$all", "$any"  then valueType is "Array"
    when "$size"                      then valueType is "Number"
    when "$regex", "$regexp"          then valueType is "RegExp"
    when "$like", "$likeI"            then valueType is "String"
    when "$between", "$mod"           then (valueType is "Array") and (value.length is 2)
    when "$cb"                        then valueType is "Function"
    else true

# Test each attribute that is being tested to ensure that is of the correct type
testModelAttribute = (queryType, value) ->
  valueType = utils.getType(value)
  switch queryType
    when "$like", "$likeI", "$regex", "$startsWith", "$endsWith"  then valueType is "String"
    when "$contains", "$all", "$any", "$elemMatch" then valueType is "Array"
    when "$size"                      then valueType in ["String","Array"]
    when "$in", "$nin"                then value?
    else true

# Perform the actual query logic for each query and each model/attribute
performQuery = (type, value, attr, model, getter) ->
  switch type
    when "$equal"
      # If the attribute is an array then search for the query value in the array the same as Mongo
      if utils.isArray(attr) then (value in attr) else (attr is value)
    when "$deepEqual"       then utils.isEqual(attr, value)
    when "$contains"        then value in attr
    when "$ne"              then attr isnt value
    when "$lt"              then attr < value
    when "$gt"              then attr > value
    when "$lte"             then attr <= value
    when "$gte"             then attr >= value
    when "$between"         then value[0] < attr < value[1]
    when "$betweene"        then value[0] <= attr <= value[1]
    when "$in"              then attr in value
    when "$nin"             then attr not in value
    when "$all"             then utils.every value, (item) -> item in attr
    when "$any"             then utils.some attr, (item) -> item in value
    when "$size"            then attr.length is value
    when "$exists", "$has"  then attr? is value
    when "$like"            then attr.indexOf(value) isnt -1
    when "$likeI"           then attr.toLowerCase().indexOf(value) isnt -1
    when "$startsWith"      then attr.toLowerCase().indexOf(value) is 0
    when "$endsWith"        then utils.reverseString(attr).indexOf(value) is 0
    when "$type"            then typeof attr is value
    when "$regex", "$regexp" then value.test attr
    when "$cb"              then value.call model, attr
    when "$mod"             then (attr % value[0]) is value[1]
    when "$elemMatch"       then (runQuery(attr,value, null, true))
    when "$and", "$or", "$nor", "$not"
      performQuerySingle(type, value, getter, model)
    else false

# This function should accept an obj like this:
# $and: [queries], $or: [queries]
# should return false if fails
single = (queries, getter, isScore) ->
  if utils.getType(getter) is "String"
    method = getter
    getter = (obj, key) -> obj[method](key)
  if isScore
    throw new Error("score operations currently don't work on compound queries") unless queries.length is 1
    queryObj = queries[0]
    throw new Error("score operations only work on $and queries (not #{queryObj.type}") unless queryObj.type is "$and"
    (model) ->
      model._score = performQuerySingle(queryObj.type, queryObj.parsedQuery, getter, model, true)
      model
  else
    (model) ->
      for queryObj in queries
        # Early false return if any of the queries fail
        return false unless performQuerySingle(queryObj.type, queryObj.parsedQuery, getter, model, isScore)
      # All queries passes, so return true
      true



performQuerySingle = (type, query, getter, model, isScore) ->
  passes = 0
  score = 0
  scoreInc = 1 / query.length

  for q in query
    if q.getter
      attr = q.getter model, q.key
    else if getter
      attr = getter model, q.key
    else
      attr = model[q.key]
    # Check if the attribute value is the right type (some operators need a string, or an array)
    test = testModelAttribute(q.type, attr)
    # If the attribute test is true, perform the query
    if test then test = performQuery q.type, q.value, attr, model, getter
    if test
      passes++
      if isScore
        boost = q.boost ? 1
        score += (scoreInc * boost)
    switch type
      when "$and"
        # Early false return for $and queries when any test fails
        unless isScore
          return false unless test
      when "$not"
        # Early false return for $not queries when any test passes
        return false if test
      when "$or"
        # Early true return for $or queries when any test passes
        return true if test
      when "$nor"
        # Early false return for $nor queries when any test passes
        return false if test
      else
        throw new Error("Invalid compound method")

  if isScore
    score
  # For not queries, check that all tests have failed
  else if type is "$not"
    passes is 0
  # $or queries have failed as no tests have passed
  # $and queries have passed as no tests failed
  # $nor queries have passed as no tests passed
  else
    type isnt "$or"


# The main function to parse raw queries.
# Queries are split according to the compound type ($and, $or, etc.) before being parsed with parseSubQuery
parseQuery = (query) ->
  queryKeys = utils.keys(query)
  return [] unless queryKeys.length
  compoundQuery = utils.intersection utils.compoundKeys, queryKeys

  # If no compound methods are found then use the "and" iterator
  if compoundQuery.length is 0
    return [{type:"$and", parsedQuery:parseSubQuery(query)}]
  else
    # Detect if there is an implicit $and compundQuery operator
    if compoundQuery.length isnt queryKeys.length
      # Add the and compund query operator (with a sanity check that it doesn't exist)
      if "$and" not in compoundQuery
        query.$and = {}
        compoundQuery.unshift "$and"
      for own key, val of query when key not in utils.compoundKeys
        query.$and[key] = val
        delete query[key]
    return (for type in compoundQuery
      {type, parsedQuery:parseSubQuery(query[type])})


parseGetter = (getter) ->
  if utils.getType(getter) is "String"
    method = getter
    getter = (obj, key) -> obj[method](key)
  getter


class QueryBuilder
  constructor: (@items, @_getter) ->
    @theQuery = {}

  all: (items, first) ->
    if items then @items = items
    if @indexes
      items = @getIndexedItems(@items)
    else
      items = @items

    runQuery(items, @theQuery, @_getter, first)

  chain: -> _.chain(@all.apply(this, arguments))

  tester: -> makeTest(@theQuery, @_getter)

  first: (items) ->
    @all(items, true)

  getter: (@_getter) ->
    this


addToQuery = (type) ->
  (params, qVal) ->
    if qVal
      params = utils.makeObj params, qVal
    @theQuery[type] ?= []
    @theQuery[type].push params
    this

for key in utils.compoundKeys
  QueryBuilder::[key.substr(1)] = addToQuery(key)

QueryBuilder::find = QueryBuilder::query = QueryBuilder::run = QueryBuilder::all

# Build Query function for progamatically building up queries before running them.
buildQuery = (items, getter) -> new QueryBuilder(items, getter)

# Create a *test* function that checks if the object or objects match the query
makeTest = (query, getter) -> single(parseQuery(query), parseGetter(getter))

# Find one function that returns first matching result
findOne = (items, query, getter) -> runQuery(items, query, getter, true)

#Return an independent function that can be passed to array.filter etc.
queryFn = (query, getter, isScore) ->
  if getter then getter = parseGetter(getter)
  single(parseQuery(query), getter, isScore) unless (utils.getType(query) is "Function")

# The main function to be mxied into underscore that takes a collection and a raw query
runQuery = (items, query, getter, first, isScore) ->
  if arguments.length < 2
    # If no arguments or only the items are provided, then use the buildQuery interface
    return buildQuery.apply this, arguments
  if getter then getter = parseGetter(getter)
  query = single(parseQuery(query), getter, isScore) unless (utils.getType(query) is "Function")
  if isScore
    fn = utils.map
  else if first
    fn = utils.detect
  else
    fn = utils.filter
  fn items, query

score = (items, query, getter) ->
  runQuery(items, query, getter, false, true)

runQuery.build = buildQuery
runQuery.parse = parseQuery
runQuery.findOne = runQuery.first = findOne
runQuery.score = score
runQuery.tester = runQuery.testWith = makeTest
runQuery.getter = runQuery.pluckWith = utils.makeGetter

expose = (_, mixin = true) ->
  unless _
    _ = underscoreReplacement()
    mixin = false
  createUtils(_)
  if mixin then _.mixin {query:runQuery, q:runQuery, Query: queryFn}
  runQuery

# We now need to determine the environment that we are in

# underscore / lodash is exposed globally, so lets mixin for the user
if root._ then return expose(root._)

# If no globals, then lets return the expose method, so users can explicitly pass in
# their lodash or underscore reference
if exports and module?.exports
  # we're in node land
  return module.exports = expose

# assuming we're in AMD land???
return expose