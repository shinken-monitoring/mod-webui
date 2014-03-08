from pymongo.connection import Connection

con = Connection('localhost', 27017)
db = con['logs']
app = None # app is not otherwise
if not db:
    message = "Error : Unable to connect to mongo database"
    print message
    # return {'app': app, 'eue_data': {}, 'message': message }

records=[]
for feature in db.logs.find({'type': 'HOST NOTIFICATION' }).sort("time",1).limit(100):
    date = feature["time"]

    records.append({
        "date" : int(date),
        "host" : feature['host_name'],
        "service" : feature['service_description'],
        "message" : feature['message']
    })

print records
