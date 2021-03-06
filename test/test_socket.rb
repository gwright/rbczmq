# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestZmqSocket < ZmqTestCase
  def test_fd
    ctx = ZMQ::Context.new
    sock = ctx.socket(:REP)
    assert Fixnum === sock.fd
    assert_equal(-1, sock.fd)
    assert_equal sock.fd, sock.to_i
  ensure
    ctx.destroy
  end

  def test_type
    ctx = ZMQ::Context.new
    sock = ctx.socket(:REP)
    assert_equal ZMQ::REP, sock.type
  ensure
    ctx.destroy
  end

  def test_readable_p
    ctx = ZMQ::Context.new
    rep = ctx.socket(:REP)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.connect(:REQ, "tcp://127.0.0.1:#{port}")
    assert req.writable?
    req.send("m")
    sleep 0.1
    assert rep.readable?
  ensure
    ctx.destroy
  end

  def test_send_socket
    ctx = ZMQ::Context.new
    push = ctx.socket(:PUSH)
    assert_raises ZMQ::Error do
      push.recv
    end
  ensure
    ctx.destroy
  end

  def test_receive_socket
    ctx = ZMQ::Context.new
    pull = ctx.socket(:PULL)
    assert_raises ZMQ::Error do
      pull.send("message")
    end
  ensure
    ctx.destroy
  end

  def test_recv_timeout
    ctx = ZMQ::Context.new
    sock = ctx.socket(:REP)
    assert_nil sock.recv_timeout
    sock.recv_timeout = 10
    assert_equal 10, sock.recv_timeout
    assert_raises TypeError do
      sock.recv_timeout = :x
    end
  ensure
    ctx.destroy
  end

  def test_send_timeout
    ctx = ZMQ::Context.new
    sock = ctx.socket(:REP)
    assert_nil sock.send_timeout
    sock.send_timeout = 10
    assert_equal 10, sock.send_timeout
    assert_raises TypeError do
      sock.send_timeout = :x
    end
  ensure
    ctx.destroy
  end

  def test_bind
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    assert(sock.state & ZMQ::Socket::PENDING)
    port = sock.bind("tcp://127.0.0.1:*")
    assert sock.fd != -1
    assert(sock.state & ZMQ::Socket::BOUND)
    tcp_sock = nil
    assert_nothing_raised do
      tcp_sock = TCPSocket.new("127.0.0.1", port)
    end
  ensure
    ctx.destroy
    tcp_sock.close if tcp_sock
  end

  def test_connect
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    assert(req.state & ZMQ::Socket::PENDING)
    req.connect("tcp://127.0.0.1:#{port}")
    assert req.fd != -1
    assert(req.state & ZMQ::Socket::CONNECTED)
  ensure
    ctx.destroy
  end

  def test_to_s
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    assert(req.state & ZMQ::Socket::PENDING)
    req.connect("tcp://127.0.0.1:#{port}")
    assert_equal "PAIR socket", sock.to_s
    assert_equal "PAIR socket bound to tcp://127.0.0.1:*", rep.to_s
    assert_equal "PAIR socket connected to tcp://127.0.0.1:49152", req.to_s
  ensure
    ctx.destroy
  end

  def test_endpoint
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    assert_equal "tcp://127.0.0.1:*", rep.endpoint
    assert_equal "tcp://127.0.0.1:49152", req.endpoint
  ensure
    ctx.destroy
  end

  def test_close
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    port = sock.bind("tcp://127.0.0.1:*")
    assert sock.fd != -1
    other = ctx.socket(:PAIR)
    other.connect("tcp://127.0.0.1:#{port}")
    sock.send("test")
    assert_equal "test", other.recv
    sock.close
    other.close
    sleep 0.2
    assert_raises Errno::ECONNREFUSED do
      TCPSocket.new("127.0.0.1", port)
    end
  ensure
    ctx.destroy
  end

  def test_send_receive
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    assert req.send("ping")
    assert_equal "ping", rep.recv
  ensure
    ctx.destroy
  end

  def test_verbose
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    rep.verbose = true
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.verbose = true
    req.connect("tcp://127.0.0.1:#{port}")
    assert req.send("ping")
    assert_equal "ping", rep.recv
    req.send_frame(ZMQ::Frame("frame"))
    assert_equal ZMQ::Frame("frame"), rep.recv_frame
  ensure
    ctx.destroy
  end

  def test_receive_nonblock
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    assert req.send("ping")
    assert_equal nil, rep.recv_nonblock
    sleep 0.2
    assert_equal "ping", rep.recv_nonblock
  ensure
    ctx.destroy
  end

  def test_send_multi
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    assert req.sendm("batch")
    req.sendm("of")
    req.send("messages")
    assert_equal "batch", rep.recv
    assert_equal "of", rep.recv
    assert_equal "messages", rep.recv
  ensure
    ctx.destroy
  end

  def test_send_receive_frame
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    ping = ZMQ::Frame("ping")
    assert req.send_frame(ping)
    assert_equal ZMQ::Frame("ping"), rep.recv_frame
    assert rep.send_frame(ZMQ::Frame("pong"))
    assert_equal ZMQ::Frame("pong"), req.recv_frame
    assert rep.send_frame(ZMQ::Frame("pong"))
    assert_nil req.recv_frame_nonblock
    sleep 0.3
    assert_equal ZMQ::Frame("pong"), req.recv_frame_nonblock
  ensure
    ctx.destroy
  end

  def test_send_frame_more
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    5.times do |i|
      frame = ZMQ::Frame("m#{i}")
      req.send_frame(frame, ZMQ::Frame::MORE)
    end
    req.send_frame(ZMQ::Frame("m6"))
    expected, frames = %w(m0 m1 m2 m3 m4), []
    5.times do
      frames << rep.recv_frame.data
    end
    assert_equal expected, frames
  ensure
    ctx.destroy
  end

  def test_send_frame_reuse
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.connect("tcp://127.0.0.1:#{port}")
    frame = ZMQ::Frame("reused_frame")
    5.times do |i|
      req.send_frame(frame, :REUSE)
    end
    expected, frames = ( %w(reused_frame) * 5), []
    5.times do
      frames << rep.recv_frame.data
    end
    assert_equal expected, frames
  ensure
    ctx.destroy
  end

  def test_send_receive_message
    ctx = ZMQ::Context.new
    rep = ctx.socket(:PAIR)
    rep.verbose = true
    port = rep.bind("tcp://127.0.0.1:*")
    req = ctx.socket(:PAIR)
    req.verbose = true
    req.connect("tcp://127.0.0.1:#{port}")

    msg = ZMQ::Message.new
    msg.push ZMQ::Frame("header")

    assert_nil req.send_message(msg)

    recvd_msg = rep.recv_message
    assert_instance_of ZMQ::Message, recvd_msg
    assert_equal ZMQ::Frame("header"), recvd_msg.pop
  ensure
    ctx.destroy
  end

  def test_type_str
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    assert_equal "PAIR", sock.type_str
  ensure
    ctx.destroy
  end

  def test_handler
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    assert_nil sock.handler
    handler = Module.new
    sock.handler = handler
    assert_equal handler, handler
  ensure
    ctx.destroy
  end

  def test_sock_options
    ctx = ZMQ::Context.new
    sock = ctx.socket(:PAIR)
    sock.verbose = true
    assert_equal 0, sock.hwm
    sock.hwm = 1000
    assert_equal 1000, sock.hwm

    assert_equal 0, sock.swap
    sock.swap = 1000
    assert_equal 1000, sock.swap

    assert_equal 0, sock.affinity
    sock.affinity = 1
    assert_equal 1, sock.affinity

    assert_equal 40000, sock.rate
    sock.rate = 50000
    assert_equal 50000, sock.rate

    assert_equal 10, sock.recovery_ivl
    sock.recovery_ivl = 20
    assert_equal 20, sock.recovery_ivl

    assert_equal(-1, sock.recovery_ivl_msec)
    sock.recovery_ivl_msec = 20
    assert_equal 20, sock.recovery_ivl_msec

    assert_equal true, sock.mcast_loop?
    sock.mcast_loop = false
    assert !sock.mcast_loop?

    assert_equal 0, sock.sndbuf
    sock.sndbuf = 1000
    assert_equal 1000, sock.sndbuf

    assert_equal 0, sock.rcvbuf
    sock.rcvbuf = 1000
    assert_equal 1000, sock.rcvbuf

    assert_equal(-1, sock.linger)
    sock.linger = 10
    assert_equal 10, sock.linger

    assert_equal 100, sock.backlog
    sock.backlog = 200
    assert_equal 200, sock.backlog

    assert_equal 100, sock.reconnect_ivl
    sock.reconnect_ivl = 200
    assert_equal 200, sock.reconnect_ivl

    assert_equal 0, sock.reconnect_ivl_max
    sock.reconnect_ivl_max = 5
    assert_equal 5, sock.reconnect_ivl_max

    sock.identity = "anonymous"
    assert_raises ZMQ::Error do
      sock.identity = ""
    end
    assert_raises ZMQ::Error do
      sock.identity = ("*" * 256)
    end

    assert !sock.rcvmore?

    assert_equal 0, sock.events

    sub_sock = ctx.socket(:SUB)
    sub_sock.verbose = true
    sub_sock.subscribe("ruby")
    sub_sock.unsubscribe("ruby")
  ensure
    ctx.destroy
  end
end