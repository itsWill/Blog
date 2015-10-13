title: Notes on Working With TCP Sockets
date: 2015-10-12
description: Notes taken while reading Working  With TCP Sockets by Jesse Storimer


The book is available at: [Working with TCP Sockets](http://www.jstorimer.com/products/working-with-tcp-sockets)

## Preface

I chose this book after seeing an engineering talk by Jesse at Shopify, the place where I interned during summer. I had an itch to write a webserver and got the book [TCP / IP Sockets in C](http://cs.baylor.edu/~donahoo/practical/CSockets/), however I felt like I spent most of the time wrestling with the C programming rather than the concepts. Jesse's book hit the right balance between theory and practice and I was able to immediately get started exploring Ruby's elegant socket API.

The book shines with it's descriptions of the networkig architecture patterns. They're clear, concise, and the links to the open source projects that implement the patterns provide a neat insight into how these are applied in real life.

The the first part focuses on introducing networking concepts and the socket API, while the second part applies the theory and explores different networking patterns through implementing a subset of a FTP server.

The book would benefit from more practical implementations of the networking patterns, so the video that one can purchase as an expansion of the book is a welcome addition.

Overall this is a solid &#9733; &#9733; &#9733; &#9733; book. Would highly recommend it to the intermediate ruby programmer with little to no knowledge of networking.

## **Sockets and the Ruby Socket API**

#### _**Beginning Sockets**_

Use Ruby's 'socket' library which is part of the standard library

``` ruby
require 'socket'

socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
```

`Socket::AF_INET` and `Socket::SOCK_STREAM` mean initialize a socket in the IPv4 family and create a TCP socket respectively. We can simplify this by using the symbols `:INET` and `:STREAM` instead of the constants i.e: creating a IPv6 UDP socket.

``` ruby
require 'socket'

socket = Socket.new(:INET6, :DGRAM)
 ```

#### _**Servers**_

A server socket is used for listening to connections. It's life-cycle is as follows:

1. **create**
2. **bind**
3. **listen**
4. **accept**
5. **close**

Servers bind to a port of a given host (IP address).

The 'localhost' IP address usually 127.0.0.1 is the one associated with the loopback interface.

``` ruby
socket = Socket.new(:INET, :STREAM)

addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')

socket.bind(addr)
```

Once a socket is bound to a port of a particular host no other sockets can do that. Doing so results in a `Errno::EADDRINUSE` error.

| Port Range | Use |
| ---------- | --- |
| **0-1024** |  'Well known ports' reserved for system use |
| **1025-48,999** |  Free ports to connect too |
| **49,000-65,535** |  Ephemeral ports used by temporary sockets |

Binding to 0.0.0.0 listens on all available interfaces including the loopback interface.

Binding to an unknown address will result in a `Errno::EADDRNOTAVAIL` exception.

After binding to a port a socket needs to listen for incoming connections.

``` ruby
require 'socket'

socket = Socket.new(:INET, :STREAM)
addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
socket.bind(addr)

socket.listen(Socket::SOMAXCONN)
```

`Socket::SOMAXCONN` is the maximum number of socket connections allowed in the listen queue.

If the number of connections exceeds the argument passed to the listen function a `Errno::ECONNREFUSED` exception will be raised.

The socket then needs to accept connections

``` ruby
require 'socket'

server = Socket.new(:INET, :STREAM)
addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
server.bind(addr)
server.listen(Socket::SOMAXCONN)

loop do
  connection, _ = server.accept
  connection.close
end
```

`accept` returns a array, where the first element is the connection and the second is an `Addrinfo` object with information about the address of the connection. The connection is popped off the listen queue if there are none then the call to accept will block until one arrives.

The connection is a new instance of the `Socket` class with a different file descriptor. For every TCP connection the remote host, remote port, local host, and local port grouping has to be unique.

After a connection has been processed it needs to be close with `close` as opposed to waiting for the program to exit. This is for resource usage and too stay away from the open file limit (max number of file descriptors per process).

It's possible to only close a single channel of communication with `connection.close_read` or `connection.close_write`. Using one of these methods calls the `shutdown` system call that also shuts down communication between copies of that socket instance. The resources are not reclaimed however to that `close` still needs to be called on every socket instance.

``` ruby
server = Socket.new(:INET, :STREAM)
addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
server.bind(addr)
server.listen(128)
connection, _ = server.accept

# makes a copy of the connection
copy = connection.dup

# shuts down communication on previous copy
connection.shutdown

# resources of original connection reclaimed when closed
# copy resources will be reclaimed when collected by the GC
connection.close
```

#### _**Ruby Wrappers**_

The create-bind-listen code can be abstracted into a single object:

``` ruby
require 'socket'

server = TCPServer.new(4481)
```

The max number of connections is defaulted to 5 but it can be increased by calling `TCPServer#listen` after the fact.

``` ruby
require 'socket'

servers = Socket.tcp_server_sockets(4481)
```

Will return an array with two sockets one reachable by IPv4 and the other by IPv6.

Instead of using a loop to handle sockets one can use an accept loop.

``` ruby
require 'socket'

servers = Socket.tcp_server_sockets(4481)

# the accept_loop can take any number of listening sockets
Socket.accept_loop(servers) do |connection|
  # process something
  connection.close
end
```

That can be further shortened into:

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  # do something
  connection.close
end
```

#### _**The Client**_

The client sockets is responsible for initializing the connection between itself and the server.
It has a similar life-cycle to the servers:

1. **create**
2. **bind**
3. **connect**
4. **close**


Clients can bind but rarely do, since they don't need to be associated with a specific port like servers. If a call to bind is omitted then a random port in the ephemeral range is assigned to the client.

``` ruby
require 'socket'

socket = Socket.new(:INET, :STREAM)
remote_addr = Socket.pack_sockaddr_in(80, 'google.com')
socket.connect(remote_addr)
```

The call to connect returns successfully if the remote server accepts the connect otherwise the call will result in a `Errno::ETIMEDOUT`

A simpler way to write a client socket is as:

``` ruby
require 'socket'

socket = TCPSocket.new('google.com', 80)
```

Or we can pass in a block like so:

``` ruby
require 'socket'

Socket.tcp('google.com', 80) do |connection|
  connection.write "GET / HTTP/1.1\r\n"
  connection.close
end

client = Socket.tcp('google.com', 80)
```
#### _**Exchanging Data**_

We can abstract of TCP as a series of tubes through which data flows. A TCP socket deals with a stream of data and is specified using the `:STREAM` symbol. The stream receives data in chunks, and has not concept of when a message has begun or ended, only the chunks of data.

To read data from a socket the simplest way is to use the read method.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  puts connection.read
  connecton.close
end
```

The read function will block while the client hasn't indicated it finished sending data by sending a EOF signal. A number of bytes can be passed to the read function to indicate the number of bytes to read before returning. i.e the following will print data in kilobyte chunks.

``` ruby
require 'socket'

Socekt.tcp_server_loop(4481) do |connection|
  while data = connection.read(1024)
    puts data
  end

  connection.close
end
```

This method can still cause a deadlock if the client send over less than 1kb of data and then waits. Read however will immediately return once an EOF event is sent, to do this you just have to close the connection.  You can use `readpartial` to perform a non blocking read. The argument passed to `readpartial` specificies the maximum amount of data it will read before it returns. If less data is passed then `readpartial` will return immediately.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  begin
    while data = connection.readpartial(1024) do
      puts data
    end
  # unlike read readpartial will raise a EOF exception when the EOF event is sent
  rescue EOFError
  end

  connection.close
end
```

To write to a socket simply use the `write` method.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  connection.write("Welcome!")
  connection.close
end
```

When data is written and the call to `write` has returned without error, this does not guarantee that the client socket received the data. The data is first written to a write buffer which then the OS Kernel is responsible for delivering to the client socket.

Similarly data is read into a read buffer, and first those buffers are checked and read from if there is data when a socket is told to read. Buffering is done for performance reasons allowing the OS Kernel to optimize pending operations and send them in batches to avoid flooding the network.

When writing the best performance is attained by _"writting all you have to in one go"_.

When reading a common readlength is 16kb.

An annotated version of the CloudHash example follows to demonstrate reading and writing.

``` ruby
require 'socket'

module CloudHash
  class Server
    def initialize(port)
      # A server is initialized on a specified port
      @server = TCPServer.new(port)
      puts "listening on port #{@server.local_address.ip_port}"
      @storage = {}
    end

    def start
      # The start command initiates the server accept loop
      # initializing a bind-listen-accept on the @server socket
      Socket.accept_loop(@server) do |connection|
        handle(connection)
        # close the connection after the connection has been processed
        connection.close
      end
    end

    def handle(connection)
      # perform a blocking read until the EOF state event is sent
      request = connection.read

      # write back to the client the processed request
      connection.write process(request)
    end

    # hash setting-getting methods
    def process(request)
      command, key, value = request.split

      case command.upcase
      when 'GET'
        @storage[key]

      when 'SET'
        @storage[key] = value
      end
    end
  end
end

server = CloudHash::Server.new(4481)
server.start
```

An the annotated client

``` ruby
require 'socket'

module CloudHash
  class Client
    class << self
      attr_accessor :host, :port
    end

    def self.get(key)
      # takes care of making a request to the remote server
      request "GET #{key}"
    end

    def self.set(key, value)
      request "SET #{key} #{value}"
    end

    def self.request(string)
      # initialize a connection for every request
      @client = TCPSocket.new(host, port)
      @client.write(string)

      # send an EOF event after writing to the server
      @client.close_write

      # read the response
      @client.read
    end
  end
end

CloudHash::Client.host = 'localhost'
CloudHash::Client.port = 4481
puts CloudHash::Client.set 'prez', 'obama'
puts CloudHash::Client.get 'prez'
puts CloudHash::Client.get 'vp'
```

Socket options are a low level way of configuring socket behavior.

``` ruby
require 'socket'

socket = TCPSocket.new('google.com', 80)

# get a Socket::Option object representing the type of the socket
opt = socket.getsockopt(:SOCKET, :TYPE)

# compare the integer representation of the socket
opt.int == Socket::SOCK_STREAM # => true
opt.int == Socket::SOCK_DGRAM # => false
```

The `TIME_WAIT` state can occur once a socket has been closed but data still exists in the buffer layer. In that case kernel will keep the connection open long enough after close to transmit the data to the socket. If you try to bind a new socket to that address in this time period a `Errno::EADDRINUSE` exception will be raised.

`SO_REUSE_ADDR` option allows to circumvent this problem by allowing sockets to bing to the same address if a socket at that address already exists in the `TIME_WAIT` state. This option is set by default when using `TCPServer.new` and `Socket.tcp_server_loop`.

``` ruby
require 'socket'

server = TCPServer.new('localhost', 4481)
# set option to true
server.setsockopt(:SOCKET, :REUSEADDR, true)

server.getsockopt(:SOCKET, :REUSEADDR) # => true
```

#### **_Non-Blocking IO_**

A call to `readpartial` will still block if there is no data to be sent, for truly non-blocking reads use `read_bonblock`. Like `readpartial` it takes a maximum number of bytes to read but if no data is ready to be sent it will raise a `Errno::EAGAIN` exception as opposed to waiting.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  loop do
    begin
      puts connection.read_nonblock(4096)
    rescue Errno::EAGAIN
      # select will block until one of the sockets in the array is readable
      IO.select([connection])
      retry
    # like
    rescue EOFError
      break
    end
  end

  connection.close
end
```

With `IO.select` we can monitor multiple sockets and check for readability while doing other processing.

The counterpart for writing is the `write_nonblock` method. While the `write` method writes all the data at once, the `write_nonblock` will return with an integer indicating the amount of data it was able to write.

``` ruby
require 'socket'

client = TCPSocket.new('localhost', 4481)
payload = 'Lorem ipsum' * 10_000

begin
  loop do
    bytes = client.write_nonblock(payload)

    break if bytes >= payload.size
    payload.slice!(0, bytes)
    # we wait till a socket is writable then try again
    # if we didn't it would raise a EAGAIN exception
    IO.select(nil, [client])
  end

rescue Errno::EAGAIN
  IO.select(nil, [client])
  retry
end
```

A write will block when the other site has either no yet acknowledged the receipt of pending data or when the receiving end can't handle more data.

A call to accept will also block if theres is no connection in the listen queue. `accept_nonblock` will raise an exception if that's the case.

``` ruby
require 'socket'

server = TCPServer(4481)

loop do
  begin
    connection = server.accept_nonblock
  rescue
    # do things
    retry
  end
end
```

The `connect_nonblock` operation behaves differently than the other non-blocking operations. If it has to block it raises a `Errno::EINPROGRESS` exception and attempts to connect in the background.

``` ruby
require 'socket'

socket = Socket.new(:INET, :STREAM)
remote_addr = Socket.pack_sockaddr_in(80, 'google.com')

begin
  socket.connect_nonblock( remote_addr )
rescue Errno::EINPROGRESS
  # Operation is in progress
rescue Errno::EALREADY
  # previous non-blocking connection is in progress
rescue Errno::ECONNREFUSED
  # remote host rejected the connection
end
```

#### _**Multiplexing Connections**_

`IO.select` takes three array of IO arguments `IO.select(for_reading, for_writing, for_reading)`. The third argument is for `IO` Objects you are interested in exceptional conditions. `IO.select` will return with an `IO` object or nested array corresponding to its arguments once an object(s) changes it status. You can also specify a timeout as a fourth argument, which once that expires select will return `nil`.

If a socket receives an EOF event or an incoming connection it will be returned in the readable sockets array.

Using `IO.select` to check if a background connect has terminated.

``` ruby
require 'socket'

socket = Socket.new(:INET, :STREAM)
remote_addr = Socket.pack_sockaddr_in(80, 'google.com')

begin
  # start a non-blocking connection
  socket.connect_nonblock(remote_addr)
rescue Errno::EINPROGRESS
  IO.select(nil, [socket])

  begin
    # try again to see if a socket is connected
    socket.connect_nonblock(remote_addr)
  rescue Errno::EISCONN
    # connected
  rescue Errno::ECONNREFUSED
    # connection refused
  end
end
```

Using a similar logic we can implement a simple port scanner.

``` ruby
require 'socket'

PORT_RANGE = 1..128
HOST = 'archive.org'
TIME_TO_WAIT = 5 # in seconds

sockets = PORT_RANGE.map do |port|
  socket = Socket.new(:INET, :STREAM)
  remote_addr = Socket.sockaddr_in(port, 'archive.org')

  begin
    # perform a non blocking connect
    socket.connect_nonblock(remote_addr)
  rescue Errno::EINPROGRESS
  end

  # return socket at the port the socket may not be connected yet
  # it could still be attempting in the background
  socket
end

expiration = Time.now + TIME_TO_WAIT

loop do
  _, writable, _ = IO.select(nil, sockets, nil, expiration - Time.now)
  break unless writable # if the timeout expires and no socket is connected

  writable.each do |socket|
    begin
      socket.connect_nonblock(socket.remote_address)
    rescue Errno::EISCONN
      # the socket is connected
      puts "#{HOST}:#{socket.remote_address.ip_port} accepts connections..."
      sockets.delete(socket) # remove it so it doesn't keep being selected
    rescue Errno::EINVAL
      sockets.delete(socket) # there was an error the socket was refused
    end
  end
end
```

`IO.select` is not always the most efficient way for multiplexing different OS come with different methods and `IO.select` is usually capped at a maximum of 1024 objects. A solution exists within the `nio4r` ruby gem which tries to favor the most performant option in your system.

Nagles algorithm as described in the book is:

After a program writes to a socket there are three possible outcomes:

1. If there's sufficient data in the local buffers to comprise an entire TCP packet then send it all immediately.
2. If there's no pending data in the local buffers and no pending acknowledgment of receipt from the receiving end, then send it immediately.
3. If there's a pending acknowledgment of receipt from the other end and not enough data to comprise an entire TCP packet, then put the data into the local buffer.

We can disable this algorithm with socket options.

``` ruby
require 'socket'

server = TCPServer.new(4481)

server.setsockopt(Scoket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
```

#### _**Framing Messages**_

Instead of keeping creating a new connection per data item we want to send we can keep the connection open and frame the messages.

If the client and the server will be running on the same OS messages can be easily framed using newlines. We can rewrite the CloudHash example using newlines.

Fort the server:

``` ruby
def handle(connection)
  loop do
    request = connection.gets
    # remove trailing new line from request for easier string comparison
    request.strip!

    # exit the connection so it can be closed once the exit request is sent
    break if request == 'exit'

    connection.puts process(request)
  end
end
```

For the client:

``` ruby
def initialize(host, port)
  @connection = TCPSocket.new(host, port)
end

def get(key)
  request "GET #{key}"
end

def set(key, value)
  request "SET #{key} {value}"
end

def request(string)
  @connection.puts(string)

  @connection.gets
end
```

Another way to frame messages is to send over the content length, the receiver reads the content length first, and then reads the number of bytes specified by the content length.

``` ruby
# get the size of a fixed-width-integer
SIZE_OF_INT = [9].pack('i')

def handle(connection)

  # read in the bytes corresponding to the fixed-width int
  packed_msg_length = connection.read(SIZE_OF_INT)
  msg_length = packed_msg_length.unpack('i').first

  # read the bytes as specified by the msg_length
  request = connection.read(msg_length)
  connetion.write process(request)
end
```

And the client:

``` ruby
payload = 'SET Prez obama'

# pack message length into fixed-width int
msg_length = payload.size
packed_msg_length = [msg_length].pack('i')

# write message length then the message
connection.write(packed_msg_length)
connection.write(payload)
```

We use the a fixed-width integer so that any integer is packed into the same number of bytes.


#### _**Time Outs**_

We can use `IO.select` to control timeouts.

``` ruby
require 'socket'
require 'timeout'

timeout = 5 # in seconds

Socket.tcp_server_loop(4481) do |connection|

  begin
    # initialize a non-blocking call to read, this avoids
    # an initial select call and returns any data available to read
    connection.read_nonblock(4096)

  rescue Errno::EAGAIN
    # IO.select will return nil if the timeout expires
    if IO.select([connection], nil, nil, timeout)
      retry
    else
      # required 'timeout' to have access to this error
      raise Timeout::Error
    end
  end

    connection.close
end
```
Timeouts on `accept` work the same way as for `read`.

``` ruby
server = TCPServer.new(4481)
timeout = 5

begin
  server.accept_nonblock
rescue
  if IO.select([server], nil, nil)
    retry
  else
    raise Timeout::Error
  end
end
```

The timeout on `connect` is works similar to the previous examples but we need to take into account when the `connect` call goes into the background.

``` ruby
require 'socekt'
require 'timeout'

socket = Socket.new(:INET, :STREAM)
remote_addr = Socket.pack_sockaddr_in(80, 'google.com')
timeout = 5

begin
  # attempt a non blocking connection to google.com
  socket.connect_nonblock(remote_addr)

rescue Errno::EINPROGRESS
  # the connect call has moved to the background

  # when the socket becomes writable before the timeout expires
  # it will fall through to the rescue Errno::EISCONN block on retry
  if IO.select(nil, [socket], nil, timeout)
    retry
  else
    raise Timeout::Error
  end

rescue Errno::EISCONN
  # successfully connected
end

socket.write("ohai")
socket.close
```

#### _**DNS Lookups**_

``` ruby
require 'socket'

socket = TCPSocket.new('google.com', 80)
```

In the above example since we use a hostname as opposed to a direct ip address a DNS lookup has to be performed. If the lookup is slow that will block the process until it completes, since the GIL will not be released for a DNS lookup.

The 'resolv' has its own API that allows the GIL to be released when DNS lookups take too long. The 'resolv-replace' library will monkey patch the `Socket` classes to use resolve, in a multithreaded environment these libraries are a big plus.

#### _**SSL Sockets**_

SSL sockets provide secure data exchange by using public key cryptography. SSL socket communication happens on port 443 by default. Both the receiver and sender socket will be doing SSL communication. In Ruby SSL sockets using the 'openssl' librabry.

Below follows an implementation of SSL communication using a self signed certificate. In production you would buy a SSL certificate and use that instead of generating a self signed one.

``` ruby
require 'socket'
require 'openssl'

def main
  # insecure TCP server
  server = TCPServer.new(4481)

  # create the SSL context
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.cert, ctx.key = create_self_signed_cert(
    1024,
    [['CN', 'localhost']],
    "Generated by Ruby/OpenSSL"
  )

  # only allowed verified SSL certificates
  ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER

  # build SSL wrapper around the TCP server
  ssl_server = OpenSSL::SSL::SSLServer.new(server, ctx)

  # connections are only accepted on the SSL socket
  connection = ssl_server.accept

  # can treat it like a regular socket
  connection.write("ohai")
  connection.close
end

# The code is taken from webrick/ssl. Generates a self signed certificate.
def create_self_signed_cert(bits, cn, comment)
  rsa = OpenSSL::PKey::RSA.new(bits){|p, n|
    case p
    when 0; $stderr.putc "."  # BN_generate_prime
    when 1; $stderr.putc "+"  # BN_generate_prime
    when 2; $stderr.putc "*"  # searching good prime,
                              # n = #of try,
                              # but also data from BN_generate_prime
    when 3; $stderr.putc "\n" # found good prime, n==0 - p, n==1 - q,
                              # but also data from BN_generate_prime
    else;   $stderr.putc "*"  # BN_generate_prime
    end
  }
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 1
  name = OpenSSL::X509::Name.new(cn)
  cert.subject = name
  cert.issuer = name
  cert.not_before = Time.now
  cert.not_after = Time.now + (365*24*60*60)
  cert.public_key = rsa.public_key

  ef = OpenSSL::X509::ExtensionFactory.new(nil,cert)
  ef.issuer_certificate = cert
  cert.extensions = [
    ef.create_extension("basicConstraints","CA:FALSE"),
    ef.create_extension("keyUsage", "keyEncipherment"),
    ef.create_extension("subjectKeyIdentifier", "hash"),
    ef.create_extension("extendedKeyUsage", "serverAuth"),
    ef.create_extension("nsComment", comment),
  ]
  aki = ef.create_extension("authorityKeyIdentifier",
                            "keyid:always,issuer:always")
  cert.add_extension(aki)
  cert.sign(rsa, OpenSSL::Digest::SHA1.new)

  return [ cert, rsa ]
end

main
```
And the client

``` ruby
require 'socket'
require 'openssl'

socket = TCPSocket.new('0.0.0.0', 4481)

ssl_socket = OpenSSL::SSL::SSLSocket.new(socket)
ssl_socket.connect

ssl_socket.read
```
If a client tries to connect with a regular TCP socket the server will crash with a `OpenSSL::SSL::SSL::Error`.

#### _**Urgent Data**_

The data stream of a TCP socket can be thought of as a queue where packets are sent in order and arrive in order. It's possible however to push urgent data (also called out of band data) to the front of the queue. This is done with the `Socket.send` method which is without any extra arguments besides the message to send defaults to behaving exactly like  `write`. If we pass in the `Socket::MSG_OOB` flag (OOB stands for Out of Bound) we tell the socket to put the data at the front of the queue.

``` ruby
require 'socket'

socket = TCPSocket.new 'localhost', 4481

# send ordered stream
socket.write 'first'
socket.write 'second'

# send urgent data
socket.send '!', Socket::MSG_OOB
```
For a socket to receive urgent data it has to use the `Socket#recv` method as opposed to `Socket#read`.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
  # read urgent data first
  urgent_data = connection.recv(1, Socket::MSG_OOB)

  data = connectoin.readpartial(1024)
end
```

The `recv` command will raise a `Errno::EINVAL` exception if there is no pending urgent data. Only one byte of urgent data can be sent if more are sent only the last byte will be considered urgent the others will be delivered in their ordered place in the queue.

We can use `IO.Select` to monitor for urgent data. The third element in the array returned by `IO.Select` are the sockets that received urgent data. However `IO.select` will continue to say urgent data is available after it has been consumed as such care needs to be taken with extra error handling to avoid being stuck in a loop.

The `SO_OOBINLINE` socket option will cause the receiver socket to treat urgent data as regular data. Handling it in the order it was sent relative to the other writes.

``` ruby
require 'socket'

Socket.tcp_server_loop(4481) do |connection|
 connection.setsockopt :SOCKET, :OOBLINE, true

 connection.read(1024) # => foo
 connection.readpartial(1024) # => !
end
```

## **Network Architecture Patterns**

This part of the book covers common design patterns when architecting networked programs. While the previous part provided a overview of the concepts and behavior behind the Ruby socket's API.

To understand the networking patterns the book implements a FTP server and explores the different architecture styles. The `CommandHandler` class handles commands sent to the FTP server.

``` ruby
module FTP
  class CommandHandler
    CRLF = "\r\n"

    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def pwd
      @pwd || Dir.pwd
    end

    def handle(data)
      cmd = data[0..3].strip.upcase
      options = data[4..-1].strip

      case cmd
      when 'USER'
        "230 Logged in anonymously"

      when 'SYST'
        "215 UNIX Working With FTP"

      when 'CWD'
        if File.directory?(options)
          @pwd = options
          "250 directory changed to #{pwd}"
        else
          "550 directory not found"
        end

      when 'PWD'
        "257 \"#{pwd}\" is the current directory"

      when 'PORT'
        parts = options.split(',')
        ip_address = parts[0..3].join('.')
        port = Integer(parts[4]) * 256 + Integer(parts(5))

        @data_socket = TCPSocket.new(ip_address, port)
        "200 Active connection established"

      when 'RETR'
        file = File.open(File.join(pwd, options), 'r')

        # connection objects will implement a respond command
        # The connection handles communication of command arguments
        # and messages between the client and the server
        #
        # Another socket is created when a file transfer happens
        # This allows for concurrency between these operations.
        conection.respond "125 Data transfer starting #{file.size} bytes"

        bytes = IO.copy_stream(file, @data_socket)
        @data_socket.close

        "226 Closing data connection, sent #{bytes} bytes"

      when 'LIST'
        connection.respond "125 Opening data connection for file list"

        result = Dir.entries(pwd).join(CRLF)
        @data_socket.write(results)
        @data_socket.close

        "226 Closing data connection, sent #{result.size} bytes"

      when 'QUIT'
        "221 Ciao"

      else
        "502 Don't know how to respond to #{cmd}"
      end
    end
  end
end
```
#### _**Serial**_

In the serial architecture clients are handled serially, there's no concurrency and so multiple clients can't be served simultaneously.

The flow is:

1. Client connects
2. Client/server exchange requests and responses
3. Client disconnects.
4. Back to step #1

``` ruby
require 'socket'
require_relative '../command_handler'

module FTP
  CRLF = "\r\n"

  class Serial
    def initialize(port = 21)
      @control_socket = TCPServer.new(port)
      trap(:INT) { exit }
    end

    # gets will read till the carriage return and line feed
    def gets
      @client.gets(CRLF)
    end

    # writes a formatted FTP response
    def respond(message)
      @client.write(message)
      @client.write(CRLF)
    end

    def run
      loop do
        @client = @control_socket.accept
        respond "220 OHAI"

        handler = CommandHandler.new(self)

        loop do
          request = gets

          # feed the request to the handler
          if request
            respond handler.handle(request)
          else
            @client.close
            break
          end
        end
      end
    end
  end
end

server = FTP::Serial.new(4481)
server.run
```

The main advantages of the serial pattern are it's simplicity and the efficiency of resources since there is only one connection to be maintained.

#### _**Process Per Connection**_

In this pattern we `fork` a new process for every incoming connection. That process then deals with the processing of that connection.

1. A connection comes in to the server
2. The main server process accepts the connection
3. It forks the new child process which is an exact copy of the parent
4. The child process continues to handle its connection in parallel while the server process goes back to step #1

``` ruby
require 'socket'
require_relative '../command_handler'

module FTP
  class ProcessPerConnection
    CRLF = "\r\n"

    def initialize(port = 21)
      @control_socket = TCPServer.new(port)
      trap(:INT) {exit}
    end

    def gets
      @client.gets(CRLF)
    end

    def respond(message)
      @client.write(message)
      @client.write(CRLF)
    end

    def run
      loop do
        @client = @control_socket.accept

        # fork a process and pass in a block of code for the child process
        # the block is executed while the parent (server process) goes back
        # to acception connections
        pid = fork do
          respond "220 OHAI"

          handler = CommandHandler.new(self)

          loop do
            request = gets

            if request
              respond handler.handle(request)
            else
              @client.close
              break
            end
          end
        end

        # cleanup the process before the parent asks for the exit status
        Process.detach(pid)
      end
    end
  end
end

server  = FTP::ProcessPerConnection.new(4481)
server.run
```

The main advantage here is the simplicity in adding parallel processing to the server.
Since `fork` creates an exact copy of the parent process, there is no shared memory, race conditions, or deadlocks.

The disadvantages are that if there are many connections there will be a process for each of them, this consumes a lot of resources and can cause the system to quickly fail. The `fork` call is only available in Unix like systems.

#### _**Thread per Connection**_

This pattern is similar to the process per connection the difference is that we spawn a thread instead of a process.

``` ruby
require 'socket'
require 'thread'
require_relative '../command_handler.rb'

module FTP
  # encapsulate connection object in a struct
  Connection = Struct.new(:client) do
    CRLF = "\r\n"

    def gets
      client.gets(CRLF)
    end

    def respond(message)
      client.write(message)
      client.write(CRLF)
    end

    def close
      client.close
    end
  end

  class ThreadPerConnection
    def initialize(port = 21)
      @control_socket = TCPServer.new(port)
      trap(:INT) { exit }
    end

    def run
      Thread.abort_on_exception = true

      loop do
        # each thread gets its own connection instance
        # this is particularly important in multithreaded programming
        # since threads share memory unlike processes
        conn = Connection.new(@control_socket.accept)
        Thread.new do
          conn.respond "220 OHAI"

          handler = FTP::CommandHandler.new(conn)

          loop do
            request = conn.gets

            if request
              conn.respond handler.handle(request)
            else
              conn.close
              break
            end
          end
        end
      end
    end
  end
end

server = FTP::ThreadPerConnection
server.run
```

The main advantages of this pattern is that it's still simple to implement. And since threads are cheaper resource wise than processes this pattern allows you to service more clients. The MRI GIL may prevent that however. There are also no issues with synchronization and locking here since each thread receives its own instance of the connection.

The same downside applies as before that as connections increase the system could become overwhelmed. Ultimately the best way to test a pattern is to try it out.

#### _**Preforking**_

Preforking is similar to the process per connection patten we saw before. However here the instead of forking a process per connection it forks a bunch of child processes when the server starts up. The flow is as follows:

1. Main server process creates a listening socket
2. Main server process forks a horde of child processes
3. Each child process accepts connections on the shared socket and handles them independently
4. Main server process keeps an eye on the child processes.

``` ruby
require 'socket'
require_relative '../command_handler'

module FTP
  class Preforking
    CRLF = "\r\n"
    CONCURRENCY  = 4 # number of processes to spawn before starting

    def initialize(port = 21)
      @controll_socket = TCPServer.new(port)
      trap(:INT) { exit }
    end

    def gets
      @client.gets(CRLF)
    end

    def respond(message)
      @client.write(message)
      @client.write(CRLF)
    end

    def run
      child_pids = []

      # spawn processes when server is first run
      CONCURRENCY.times do
        child_pids << spawn_child
      end

      # parent passes on the INT signal to the child processes.
      trap(:INT) {
        child_pids.each do |cpid|
          begin
            Process.kill(:INT, cpid)
          rescue Errno::ESRCH
          end
        end

        exit
      }

      loop do
        # Process.wait will block until the child objects exit
        # since a child process should never exit we treat this
        # as an anomaly and fork a new child.
        pid = Process.wait
        $stderr.puts "Process #{pid} quit unexpectedly"

        child_pids.delete(pid)
        child_pids << spawn_child
      end
    end


    # spawns  a child process which accepts connections and handles requests
    def spawn_child
      fork do
        loop do
          @client = @control_socket.accept
          respond "220 OHAI"

          handler = CommandHandler.new(self)

          loop do
            request = gets

            if request
              respond handler.handle(request)
            else
              @client.close
              break
            end
          end
        end
      end
    end
  end
end

server = FTP::Preforking.new(4481)
server.run
```

With this pattern the forking occurs when the server starts as opposed to a per connection basis which means there is a lower overhead in resources. The processes are also fully parallel so a failure in one process doesn't affect another process.

The memory consumption remains a big disadvantage since child processes are a complete copy.


#### _**Thread Pool**_

The thread pool pattern is similar to the preforking pattern but instead of using processes we use threads.

``` ruby
require 'socket'
require 'thread'
require_relative '../command_handler'

module FTP
  # want to give each thread a different instance of a connection
  Connection = Struct.new(:client) do
    CRLF = "\r\n"

    def gets
      client.gets(CRLF)
    end

    def respond(message)
      client.write(message)
      client.write(CRLF)
    end

    def close
      client.close
    end
  end

  class ThreadPool
    CONCURRENCY = 25

    def initialize(port = 21)
      @control_socket = TCPServer.new(port)
      trap(:INT) { exit }
    end

    def run
      Thread.abort_on_exception = true
      threads = ThreadGroup.new

      CONCURRENCY.times do
        threads.add spawn_thread
      end

      # sleep to prevent main thread exiting
      # but could theoretically continue doing work
      sleep
    end

    def spawn_thread
      Thread.new do
        loop do
          conn = Connection.new(@control_socket.accept)
          conn.respond "220 OHAI"

          handler = CommandHandler.new(conn)

          loop do
            request = conn.gets

            if request
              conn.respond handler.handle(request)
            else
              conn.close
              break
            end
          end
        end
      end
    end
  end
end

server = FTP::ThreadPool.new(4481)
server.run
```

This pattern is very similiar to the pre forking pattern but notice the concurrency number is higher since threads are lighter weight. The MRI GIL however will mitigate some of the gain in using threads.


#### _**Evented (Reactor)**_

The evented pattern is single process and single threaded yet affords levels of concurrency similar to the previous patterns. A connection multiplexer (aka Reactor core) monitors active connections and dispatches the relevant code for an event. An event is a stage in a connections lifecyle: accept, read, write, close.

1. The server monitors the listening socket for incoming connections.
2. Upon receiving a new connection it adds it to the list of sockets to monitor
3. The server now monitors the active connection as well as the listening socket
4. Upon being notified that the active connection is readable the server reads a chunk of data from that connection and dispatches the relevant callback
5. Upon being notified that the active connection is still readable the server reads another chunk and dispatches the relevant callback again.
6. The server receives another new connection; it adds that to the list of sockets to monitor.
7. The server is notified that the first connection is ready for writing, so the response is written out to that connection

``` ruby
require 'socket'
require_relative '../command_handler'

module FTP
  class Evented
    CHUNK_SIZE = 1024 * 16

    # even though the evented/reactor pattern is single threaded, the connections are encapsulated in
    # a individual object to allow for the interleaved handling of the connection.
    class Connection
      CRLF = "\r\n"
      attr_reader :client

      def initialize(io)
        @client = io
        @request, @response = "", ""
        @handler = CommandHandler.new(self)

        respond "220 OHAI"
        on_writable
      end

      # checks to see if a complete request has been formed then pass to the handler to deal with
      # the request
      def on_data(data)
        @request << data

        if @request.end_with?(CRLF)
          respond @handler.handle(@request)
          @request = ""
        end
      end

      def respond(message)
        @response << message + CRLF

        # write what can be written immediately retrying when the socket
        # is next writable
        on_writable
      end

      def on_writable
        bytes = client.write_nonblock(@response)
        @respones.slice!(0, bytes)
      end

      # in this case we are always interesting in reading from the sockets.
      def monitor_for_reading?
        true
      end

      # write if there is a response to write
      def monitor_for_writing?
        !(@response.empty?)
      end
    end

    def initialize(port = 21)
      @control_socket = TCPServer.new(port)
      trap(:INT) { exit}
    end


    def run
      @handles = {}

      loop do
        to_read = @handles.values.select(&:monitor_for_reading?).map(&:client)
        to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)


        readables, writables = IO.select(to_read + [@control_socket], to_write)

        readables.each do |socket|
          # control socket is ready to read then it's ready to accept the connection
          if socket == @control_socket
            io = @control_socket.accept
            connection = Connection.new(io)
            @handles[io.fileno] = connection

          else
            connection = @handles[socket.fileno]

            begin
              data = socket.read_nonblock(CHUNK_SIZE)
              connection.on_data(data)
            rescue Errno::EAGAIN
            rescue EOFError
              # if a client disconnects remove it from the monitor array so they can be
              # garbage collected.
              @handles.delete(socket.fileno)
            end
          end
        end

        # trigger the on writable method for writable sockets
        writables.each do |socket|
          connection = @handles[socket.fileno]
          connection.on_writable
        end
      end
    end
  end
end

server = FTP::Evented.new(4481)
server.run
```

The main advantage of this pattern is that it can handle many more concurrent connections than you could using the preforking or thread pool pattern. The main disadvantage is that you can't block the reactor so if you use a third party library that does blocking IO you negate the concurrency advantages.
