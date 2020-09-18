# Sequel + MSSQL Default String Schema Issue

By default, Sequel's schema modification engine converts Ruby `String` type to MSSQL `VARCHAR`. However, the default query mode translates `#where` filter strings into unicode (`NVARCHAR`) types: `N'strings'`.

This causes additional overhead where SQL Server needs to convert datatypes from unicode to not-unicode, but more importantly, prohibits indexes from being used(!!!).

This project acts as a demonstration of the issue with a benchmark

# Running

Docker and compose should be available.

```sh
docker-compose build
docker-compose run app rake db:benchmark
```

Alternatively you can modify the `db/config.rb` to represent some local sqlserver and run:

```sh
bundle
rake db:benchmark
```

# Overview

To demonstrate the performance impacts, a table is created that includes a Ruby `String`, and is indexed.

_db/migrations/1_create_things.rb:_

```rb
    create_table(:things) do
      primary_key :id
      String :name, null: false, index: true
    end
```

The current Sequel behaviour is to execute this (generally) as

```sql
CREATE TABLE [things] (
  id IDENTITY(1,1),
  name VARCHAR(255)   --<-- Notice this is not the unicode enabled NVARCHAR.
)

```

This table is loaded with 1,000,000 values of unique names.

A query specified as:

```rb
DB[:things].where(name: '12345').all
```

is executed (generally) as 

```sql
SELECT * FROM [things] WHERE [name] = N'12345'  --<-- Notice this string is preceded by `*N*'12345'`.
```

### Typical Results:

```
▶ docker-compose run app rake db:benchmark
Starting sequel_sqlserver_nvarchar_db_1 ... done
Waiting for SQL Server to be available.
Ready.
DB `example_db` already existed.
Migrated `example_db` to 1
Rehearsal --------------------------------------------------------------------------------
where name = N'12345' (unicode)                0.000000   0.005109   0.005109 (  0.877117)
where name = '12345' (not unicode)             0.002260   0.000753   0.003013 (  0.007707)
Sequel .where uses N'' strings by default      0.004795   0.004822   0.009617 (  0.887310)
Sequel .where without N'' strings              0.005605   0.000678   0.006283 (  0.009490)
Sequel .where without N'' via dataset method   0.002512   0.003688   0.006200 (  0.008548)
----------------------------------------------------------------------- total: 0.030222sec

                                                   user     system      total        real
where name = N'12345' (unicode)                0.002830   0.002579   0.005409 (  0.872671)
where name = '12345' (not unicode)             0.001121   0.001951   0.003072 (  0.007673)
Sequel .where uses N'' strings by default      0.008258   0.002383   0.010641 (  0.894937)
Sequel .where without N'' strings              0.001418   0.001144   0.002562 (  0.005272)
Sequel .where without N'' via dataset method   0.001701   0.001982   0.003683 (  0.006207)
```

# Workarounds

Ideally this inconsistency will get resolved so that the defaults work in concert. Until then:

There is a setting you can call to quote strings without the `N''` identifier:

```rb
DB.mssql_unicode_strings = false
```

You can also set this at the dataset level:

```rb
DB[:things].where(name: '12345').with_mssql_unicode_strings(false).all
```

Alternatively, when creating the migration, you can specify 'nvarchar' as the datatype:

```rb
    create_table(:things) do
      primary_key :id
      'nvarchar(255)' :name, null: false, index: true
    end
````

# One more note about advocating for updating the Sequel MSSQL adapter

SQL Server is [deprecating the `TEXT` datatype](https://docs.microsoft.com/en-us/sql/t-sql/data-types/ntext-text-and-image-transact-sql?view=sql-server-ver15) in favor of `NVARCHAR(MAX)`. Many functions do not work on TEXT columns. This is also a good reason to override the current defaults.