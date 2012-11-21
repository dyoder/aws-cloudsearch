# Introduction

The `aws-cloudsearch` module makes it simple to index and search documents using the AWS CloudSearch service.

    Index = require "aws-cloudsearch"

    albums = new Index
      domain:
        name: "albums"
        id: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    
    albums.events.on "*.error", (error) ->
      console.log error

    id = albums.search
      query: "Led Zepplin"
      fields: "title,year"
  
    albums.events.once "aws-cloudsearch.search.#{id}.success", (results) ->
      console.log "Found #{results.hits.found} results."
      for hit in results.hits.hit
        [title] = hit.data.title
        [year] = hit.data.year
        console.log "'#{title}' - #{year}"
        
The `aws-cloudsearch` module use `node-bus` to propagate events.

# Status

This is very much a work in progress. Email me suggestions if you have any.

Among other things, I plan to put a bit more wrapper code around the queries and results.

# Installation

    npm install aws-cloudsearch