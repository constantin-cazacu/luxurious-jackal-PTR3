import pymongo
import time
import socket
import json

myclient = pymongo.MongoClient("mongodb://mongo_1:27017,mongo_2:27017,mongo_3:27017/TweetDataStream?replicaSet=rs0")
print("ceva", flush=True)
db = myclient["TweetDataStream"]

# s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# s.connect(("broker", 8082))
print("jiu?", flush=True)
conn_msg = json.dumps({"type": "connectPub", "params": {"topics": ["users", "tweets"]}})
to_send = (str(len(conn_msg)).zfill(5) + conn_msg).encode("utf-8")
# s.send(to_send)

with db.watch() as stream:
    print("hey ho", flush=True)
    while stream.alive:
        print("lets go", flush=True)
        change = stream.try_next()

        if change is not None:
            topic = change['ns']['coll']
            data = change['fullDocument']
            data.pop('_id')
            
            print("Data", data, flush=True)

            # data_msg = json.dumps({"type": "data", "params": {"topic": topic, "is_persistent": True}, "body": {"content": data}})
            # to_send = (str(len(data_msg)).zfill(5) + data_msg).encode("utf-8")
            #
            # print("yay")
            # try:
            #     # s.send(to_send)
            # except Exception as e:
            #     print(e, flush=True)