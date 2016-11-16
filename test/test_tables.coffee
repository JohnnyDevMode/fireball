_ = require 'lodash'
async = require 'async'

table_params = [
  {
    TableName: 'table_one'
    KeySchema: [
      {AttributeName: 'identifier', KeyType: 'HASH'}
    ]
    AttributeDefinitions: [
      {AttributeName: 'identifier', AttributeType: 'S'}
      {AttributeName: 'second_field', AttributeType: 'S'}
    ],
    ProvisionedThroughput:
        ReadCapacityUnits: 1
        WriteCapacityUnits: 1
    GlobalSecondaryIndexes: [
      {
        IndexName: 'second-index'
        KeySchema: [
          {AttributeName: 'second_field', KeyType: 'HASH'}
        ]
        Projection: ProjectionType: 'ALL'
        ProvisionedThroughput:
          ReadCapacityUnits: 1
          WriteCapacityUnits: 1
      }
    ]
  }
  {
    TableName: 'table_two'
    KeySchema: [
      {AttributeName: 'identifier', KeyType: 'HASH'}
      {AttributeName: 'range_key', KeyType: 'RANGE'}
    ]
    AttributeDefinitions: [
      {AttributeName: 'identifier', AttributeType: 'S'}
      {AttributeName: 'range_key', AttributeType: 'S'}
    ],
    ProvisionedThroughput:
        ReadCapacityUnits: 1
        WriteCapacityUnits: 1
  }
]

module.exports = (dynamodb, done) ->
  async.each table_params,
    (params, next) ->
      dynamodb.createTable params, next
    done
