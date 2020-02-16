# Steps

Start DBs:

  docker-compose up --force-recreate --abort-on-container-exit mysql-m1 mysql-s1 mysql-s2 mysql-s3 mysql-s4

Create topology:

  setup-repl

Start binlog readers:

  docker-compose up --force-recreate --abort-on-container-exit mysql-m1-binlogreader mysql-s1-binlogreader mysql-s2-binlogreader mysql-s3-binlogreader mysql-s4-binlogreader

Start proxysql container:

  docker-compose up --force-recreate --abort-on-container-exit proxysql-1

Jump into ProxySQL container, with VS code or with docker exec.
Build proxysql:

          make (or make debug)

Launch proxysql:

          src/proxysql -f --initial -c gtid-playground/proxysql.cfg
