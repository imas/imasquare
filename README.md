IM@Square
=====

Simple contribution platform for IM@Study.

## Getting Started

```
$ source env.sh
$ bundle install
$ bundle exec ridgepole -c database.yml --apply -f db/Schemafile
$ bundle exec rackup
```

or

```
$ source env.sh
$ docker-compose build app
$ docker-compose run app ridgepole -c config/database.yml --apply -f db/Schemafile
$ docker-compose up -d
```
