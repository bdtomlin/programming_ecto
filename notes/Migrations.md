# Migrations

Run the first 3 pending migrations
```
mix ecto.migrate -n 3
```

Roll back the 3 most resent migrations
```
mix ecto.rollback -n 3
```

Run pending migrations up to and including 20210629141224
```
mix ecto.migrate -v 20210629141224
```

Roll back most recent migrations down to and including 20210629141224
```
mix ecto.rollback -v 20210629141224
```

It's ok to rollback and edit a migration until it has been committed to source control.

Foreign keys to not create an index. If the fk references a pk on another record that will cover you for that side of the relationship, but if you expect to query in the opposite direction, you may need to add an index to the fk.

Ecto queues up migrations and then runs them. That can cause an issue when later migrations depend on previous migrations. This can be remedied with the flush function.
