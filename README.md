# README

This repository contains a Blacklight instance that uses the Harvard LibraryCloud Item API as a backend in place of
the standard Solr backend. It also allows adding items to the LibraryCloud collections using the 
Collections API.

Demo site: http://dcp-dev2.lib.harvard.edu:8080/

# Dependencies

    Ruby 2.2+
    Bundler
    Rails 5.1+
    mySQL

# Installation

* Clone the Repository

```sh
git clone https://github.com/harvard-library/STLee-blacklight.git
```

* Install Gemfile dependencies

```sh
cd STLee-blacklight/
bundle install
```

* Create mysql users and database
```sh
mysql;
mysql> CREATE DATABASE <my-database-name>;
mysql> CREATE USER '<my-user-name>'@'localhost' IDENTIFIED BY '<my-password>';
mysql> GRANT ALL PRIVILEGES ON <my-database-name>.* TO '<my-user-name>'@'localhost';
mysql> FLUSH PRIVILEGES;
mysql> exit;
```

* Configure the database connection

Edit `config/database.yml` with credentials that match the Postgres user and database that you are using. For example, change the 'development' section as follows, to add `username` and `password` configuration keys:

```yml
default: &default
  adapter: mysql2
  user: <my-user-name>
  password: <my-password>

development:
  <<: *default
  host: localhost
  database: <my-database-name>
```

* Initialize the database

```
bundle exec rake db:migrate
```

* Start the application

```
rails server
```

## Documentation of Code Changes

Custom modifications to Blacklight code are documented in the [code-changes.md](docs/code-changes.md)

## Known Issues

Known issues to the custom modifications are documented in [known-issues.md](docs/known-issues.md)