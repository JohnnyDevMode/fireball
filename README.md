# Fireball
> A lightweight model wrapper for DynamoDB with syntax that sucks less.

## Getting Started

Install Fireball:

```shell
npm install fireball-db --save
```

## Overview

Fireball, in its simplest form, is a wrapper around the AWS SDK DynamoDB Document Client.  The primary purpose of this library is to create model object to reflect a single DynamoDB table.  The model object provides many useful additions such as unique ID generation, cleaner parameter syntax and promise based functions.

## Usage

### Import fireball

``` coffeescript
fireball = require 'fireball-db'
```

### Creating a model object
The model object is a wrapper around the *DocumentClient* that simplify the parameter syntax to most functions and will automatically add the *TableName* parameter as needed.

``` coffeescript
User = fireball.model 'SomeDynamoTable'
```

#### Creating a model as a node module (recommended)

``` coffeescript
fireball.extend module, 'SomeDynamoTable'
```

#### Creating a model with custom extensions

``` coffeescript
User = fireball.extend module, 'SomeDynamoTable',

  find_by_email: (email) ->
    ...

User.find_by_email('test@test.com').then (users) ->
  ...
```

### Promises

All functions of the model object return Promises.

[Information on Promises](https://www.promisejs.org/)

### Querying a table

``` coffeescript
User = ...
User.query(
  expression: '#field = :value'
  names: {'#field': 'name'}
  values: {':value': 'fred'}
).then (users) ->
  ...

```

### Querying a table with specific index

``` coffeescript
User = ...
User.query(
  expression: '#field = :value'
  names: {'#field': 'name'}
  values: {':value': 'fred'}
  IndexName: 'secondary_index'
).then (users) ->
  ...

```

### Scanning a table

``` coffeescript
User = ...
User.scan(
  expression: '#field = :value'
  names: {'#field': 'name'}
  values: {':value': 'fred'}
).then (users) ->
  ...
```

### Getting an item
``` coffeescript
User = ...
key = email: 'test@email.com'
User.get(key).then (user) ->
  ...
```

### Getting an item by identifier
Wrapper around *get* that will use the managed *identifier* key.

``` coffeescript
User = ...
User.for_id('12312312321').then (user) ->
  ...
```

### Putting an item
``` coffeescript
User = ...
User.put(first: 'John', last: 'Doe', email: 'test@email.com').then (user) ->
  ...
```

### Putting an item with condition expression
``` coffeescript
User = ...
user_data = first: 'John', last: 'Doe', email: 'test@email.com'
condition = expression: '#field = :value', names: {'#field': 'name'}, values: {':value': 'fred'}

User.put(user_data, condition).then (user) ->
  ...
```

### Inserting an item
Wrapper around put that will automatically add an *identifier* field and ensure uniqueness.

``` coffeescript
User = ...
User.insert(first: 'John', last: 'Doe', email: 'test@email.com').then (user) ->
  ...
```

### Updating an item

``` coffeescript
User = ...
key = email: 'test@email.com'
User.insert(key, first: 'John', last: 'Doe').then (user) ->
  ...
```

### Deleting an item
``` coffeescript
User = ...
key = email: 'test@email.com'
User.delete(key).then (user) ->
  ...
```

### Get all items for keys (batchGet)
``` coffeescript
User = ...
keys = [
  {email: 'test@email.com'}
  {email: 'test2@email.com'}
  {email: 'test3@email.com'}
]
User.for_keys(keys).then (users) ->
  ...
```

### Get all items for identifiers
``` coffeescript
User = ...
ids = [
  '12121'
  '12122'
  '12123'
]
User.for_ids(ids).then (users) ->
  ...
```

### Putting multiple items (batchWrite)
``` coffeescript
User = ...
items = [
  {first: 'John', last: 'Doe', email: 'test@email.com'}
  {first: 'Jane', last: 'Doe', email: 'test2@email.com'}
  {first: 'Sally', last: 'Doe', email: 'test3@email.com'}
]
User.put_all(items).then (users) ->
  ...
```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality.
