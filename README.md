IM@Square
=====

Simple contribution platform for IM@Study.

## Getting Started

```
$ source env.sh
$ bundle install
$ bundle exec rigepole -c database.yml --apply -f Schemafile
$ bundle exec rackup
```

or

```
$ source env.sh
$ docker-compose build app
$ docker-compose run app rigepole -c docker-database.yml --apply -f Schemafile
$ docker-compose up -d
```
