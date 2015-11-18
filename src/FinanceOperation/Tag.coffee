_ = require 'underscore'

# could be a collection here and reference that id
# it could be enforced that lowercase is passed in 
# we could enforce a character range 
class Tag 
  # id 
  name: ""

  # Invariant: name is always lowercase
  constructor: (aName) ->
    @name = aName.toLowerCase()

  toString: -> @name 
  
  # _.isString tags and 
  # @TODO: if !string&!arr, error
  # if it has a comma, explode it, make them into an array of Tags
  @tagsFrom: (tags) ->
    if _.isArray tags 
      return Tag.uniqueAndMakeList tags
    if tags.includes ','
      stringTags = tags.split ','
      return Tag.uniqueAndMakeList stringTags
    return new Tag(tags)

  @uniqueAndMakeList: (tags) ->
    tags = _.uniq tags
    tagArray = []
    for tag in tags
      if tag instanceof Tag 
        tagArray.push tag
      else 
        tagArray.push new Tag(tag)
    tagArray

module.exports.Tag = Tag