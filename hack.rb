require 'bundler/setup'
require 'mysql2'
require 'pry'
class Hack
  BASE_CONN = {host: '127.0.0.1', username: 'root', :flags => "SESSION_TRACK", :database => "test"}
  MYSQL_WRITER = BASE_CONN.merge({port: '22101'})
  MYSQL_READER = BASE_CONN.merge({port: '22201'})

  # def call_proxy
  #   c = Mysql2::Client.new(MYSQL_WRITER.merge(port: '33306'))
  #   c.query("SELECT 1")
  #   binding.pry
  # end
  def call(writer, reader)
    prepare_db

    c = Mysql2::Client.new(writer)
    c.query("SET SESSION session_track_gtids=OWN_GTID")
    c.query("INSERT INTO test VALUES (1)")
    gtid = c.session_track(Mysql2::Client::SESSION_TRACK_GTIDS)[0]

    puts gtid.inspect

    reader_conn = Mysql2::Client.new(reader)
    # reader_conn.query("SELECT WAIT_FOR_EXECUTED_GTID_SET('#{gtid}')")
    # waits forever, by default, probably not what people want
    reader_conn.query("SELECT * FROM test")
    reader_conn.query("/* min_gtid=#{gtid} */ SELECT * FROM test")

    binding.pry
  end

  def prepare_db
    cmd = "mysql -u root -h #{BASE_CONN[:host]} -P #{MYSQL_WRITER[:port]} -v  "
    `#{cmd} -e 'create database IF NOT EXISTS test'`
    `#{cmd} test -e 'create table IF NOT EXISTS test (id INT)'`
  end
end

# Hack.new.call(Hack::MYSQL_WRITER, Hack::MYSQL_READER)
Hack.new.call(Hack::MYSQL_WRITER.merge(port: '33306'), Hack::MYSQL_WRITER.merge(port: '33306'))
