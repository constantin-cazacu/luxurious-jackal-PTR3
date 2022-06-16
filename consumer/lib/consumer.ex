defmodule Consumer do

#  TODO Consumer workflow
'''
  I. How the consumer should connect & subscribe?
    1. Consumer connects to TCP Conn Supervisor, redirected to a tcp worker -> connection established
    2. Consumer receives a list of current topics from Topic Router (TCP Conn Worker shall request it
       once the connection is established)
    3. Consumer chooses at random one of the topics
    4. Consumer sends a message with the :subscribe keyword, chosen topic and index of message to be
       use in queue as arguments
    5. Consumer shall receive an ack

  II. Sending & Receiving
  *** Gotta think how to notify about new subscribe and how sending the messages should work *** (NOT FINALIZED)
    1. once the subscription ack has been received the Consumer shall send to the TCP Conn Worker request for message
    2. the selected Topic Worker (based on the subscribed topic from the previous section) shall receive
       a request for a message from the TCP Conn Worker (:message_request, topic, last_index)
    3. Topic Worker shall increment the index and select the message from the queue at the current
       index and send it to the TCP Conn worker which shall send it as a response to the Consumer
    4. Consumer shall receive the message with the index which shall be used to the follow-up request (will be treated
       as ack by message broker)
    5. repeat of the steps 2-5
'''

# BELOW IT IS A GENERIC IMPLEMENTATION
  def subscribe() do
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 8082)
#    TODO find ways to write commands, or user input
    {:ok, encoded_message} = Poison.encode(:subscribe_to_topic_command)
    :gen_tcp.send(socket, encoded_message)
    socket
  end

  def unsubscribe(socket) do
    {:ok, encoded_message} = Poison.encode(:unsubscribe_from_topic_command)
    :gen_tcp.send(socket, encoded_message)
  end


end
