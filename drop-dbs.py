import rethinkdb as r
import os
conn = r.connect(host=os.environ['RETHINKDB_HOST'],
                 port=os.environ['RETHINKDB_PORT'])


dbs = r.db_list().run(conn)
for db in dbs:
    if db == 'rethinkdb':
        continue
    print 'dropping: ' + db
    r.db_drop(db).run(conn)
