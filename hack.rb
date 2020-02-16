require 'bundler/setup'
require 'mysql2'
require 'pry'

class Hack
  BASE_CONN = {host: '127.0.0.1', username: 'root', flags: "SESSION_TRACK", database: "test"}
  MYSQL_WRITER = BASE_CONN.merge({port: '22101'})
  MYSQL_READER = BASE_CONN.merge({port: '22201'})

  PROXY_WRITER = BASE_CONN.merge({port: '33306', username: 'app_writer'})
  PROXY_READER = BASE_CONN.merge({port: '33306', username: 'app_reader'})

  def call(writer, reader, break_replication:)
    prepare_db

    writer_conn = Mysql2::Client.new(writer)
    writer_conn.query("SET SESSION session_track_gtids=OWN_GTID")

    on_every_slave('STOP SLAVE') if break_replication

    writer_conn.query("INSERT INTO test VALUES (1)")
    gtid = writer_conn.session_track(Mysql2::Client::SESSION_TRACK_GTIDS)[0]

    puts gtid

    reader_conn = Mysql2::Client.new(reader)
    reader_conn.query("/* min_gtid=#{gtid} */ SELECT * FROM test")
  ensure
    on_every_slave('START SLAVE') if break_replication
  end

  def on_every_slave(cmd)
    [22201, 22202, 22203, 22204].each do |port|
      exec_cmd(cmd, db: nil, backend: MYSQL_READER.merge(port: port))
    end
  end

  def prepare_db
    exec_cmd('create database IF NOT EXISTS test', db: nil, backend: MYSQL_WRITER)
    exec_cmd('create table IF NOT EXISTS test (id INT)', backend: MYSQL_WRITER)
  end

  def exec_cmd(cmd, backend:, db: 'test')
    base = "mysql -u root -h #{backend[:host]} -P #{backend[:port]} -v  "
    `#{base} #{db} -e '#{cmd}'`
  end
end

# Hack.new.call(Hack::MYSQL_WRITER, Hack::MYSQL_READER)
# Hack.new.call(Hack::PROXY_WRITER, Hack::PROXY_READER, break_replication: true)
Hack.new.call(Hack::PROXY_WRITER, Hack::PROXY_READER, break_replication: false)
