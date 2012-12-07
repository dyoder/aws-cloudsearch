{merge} = require "fairmont"
request = require "request"
Bus = require "node-bus"

awsURL = (options) ->
  {prefix,domain,region,path} = options
  {name,id} = domain
  domain = "cloudsearch.amazonaws.com"
  date = "2011-02-01"
  "http://#{prefix}-#{name}-#{id}.#{region}.#{domain}/#{date}/#{path}"

# 32-bit timestamps -- get rid of ms
timestamp = -> Math.round (Date.now()/1000)

makeRequest = (options) ->
  {url,operation,id,content,query,events} = options
  options = url: url, timeout: 30 * 1000 # 30 seconds
  options.qs = query if query?
  options.body = (JSON.stringify content) if content?
  method = if operation is "search" then "GET" else "POST"
  request options, (error,response,data) ->
    unless error?
      if response.statusCode is 200
        events.event "aws-cloudsearch.#{operation}.#{id}.success", JSON.parse data
      else
        events.event "aws-cloudsearch.#{operation}.#{id}.error", response.body
    else
      events.event "aws-cloudsearch.#{operation}.#{id}.error", error
        
  
class Client
  
  constructor: (options) ->
    
    {@domain,@region,@events} = merge options, region: "us-east-1"
        
    @_docURL =  awsURL 
      prefix: "doc"
      domain: @domain
      region: @region
      path: "documents/batch"
      
    @_searchURL =  awsURL 
      prefix: "search"
      domain: @domain
      region: @region
      path: "search"
   
    @events ?= new Bus
    
    @counter = 0
    
  index: (object) ->
    
    @events.event "aws-cloudsearch.index.#{object.id}.start"

    makeRequest
      events: @events
      operation: "index"
      id: object.id
      url: @_docURL
      content: [
        type: "add"
        version: timestamp()
        lang: "en"
        id: object.id
        fields: object
      ]

    object.id
    
  search: (options) ->
    
    {term,fields} = options
    
    @events.event "aws-cloudsearch.search.#{@counter++}.start"

    # TODO: add support for other search parameters
    makeRequest
      events: @events
      operation: "search"
      id: @counter
      url: @_searchURL
      query: 
        bq: term
        "return-fields": fields

    @counter

  delete: (id) ->

    @events.event "aws-cloudsearch.delete.#{id}.start"

    makeRequest
      events: @events
      operation: "delete"
      id: id
      url: @_docURL
      content: [
        type: "delete"
        version: timestamp()
        id: id
      ]
      
    id
    
module.exports = Client