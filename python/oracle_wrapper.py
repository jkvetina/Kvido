# coding: utf-8
import os, collections
import cx_Oracle



class Oracle:

  def __init__(self, tns):
    self.conn = None    # recent connection link
    self.curs = None    # recent cursor
    self.cols = []      # recent columns mapping (name to position) to avoid associative arrays
    self.desc = {}      # recent columns description (name, type, display_size, internal_size, precision, scale, null_ok)
    self.tns = {
      'user'    : '',
      'pwd'     : '',
      'host'    : '',
      'port'    : 1521,
      'sid'     : None,
      'service' : None,
      'lang'    : '.AL32UTF8',
    }
    self.tns.update(tns)
    self.connect()



  def connect(self):
    os.environ['NLS_LANG'] = self.tns['lang']
    self.tns['dsn'] = cx_Oracle.makedsn(self.tns['host'], self.tns['port'], service_name = self.tns['service']) \
      if self.tns['service'] else cx_Oracle.makedsn(self.tns['host'], self.tns['port'], sid = self.tns['sid'])
    self.conn = cx_Oracle.connect(self.tns['user'], self.tns['pwd'], self.tns['dsn'])



  def get_binds(self, query, autobind):
    out = {}
    try:
      binds = autobind._asdict()
    except:
      binds = autobind
    #
    for key in binds:  # convert namedtuple to dict
      if ':' + key in query:
         out[key] = binds[key] if key in binds else ''
    return out



  def execute(self, query, autobind = None, **binds):
    if autobind and len(autobind):
      binds = self.get_binds(query, autobind)
    #
    self.curs = self.conn.cursor()
    return self.curs.execute(query.strip(), **binds)



  def executemany(self, query, binds):
    self.curs = self.conn.cursor()
    return self.curs.executemany(query.strip(), binds)



  def fetch(self, query, limit = 0, autobind = None, **binds):
    if autobind and len(autobind):
      binds = self.get_binds(query, autobind)
    #
    self.curs = self.conn.cursor()
    if limit > 0:
      self.curs.arraysize = limit
      data = self.curs.execute(query.strip(), **binds).fetchmany(limit)
    else:
      self.curs.arraysize = 5000
      data = self.curs.execute(query.strip(), **binds).fetchall()
    #
    self.cols = [row[0].lower() for row in self.curs.description]
    self.desc = {}
    for row in self.curs.description:
      self.desc[row[0].lower()] = row
    #
    return data



  def fetch_assoc(self, query, limit = 0, autobind = None, **binds):
    if autobind and len(autobind):
      binds = self.get_binds(query, autobind)
    #
    self.curs = self.conn.cursor()
    h = self.curs.execute(query.strip(), **binds)
    self.cols = [row[0].lower() for row in self.curs.description]
    self.desc = {}
    for row in self.curs.description:
      self.desc[row[0].lower()] = row
    #
    self.curs.rowfactory = collections.namedtuple('ROW', [d[0].lower() for d in self.curs.description])
    #
    if limit > 0:
      self.curs.arraysize = limit
      return h.fetchmany(limit)
    #
    self.curs.arraysize = 5000
    return h.fetchall()



  def get_output(self, query):
    out   = []
    curs  = self.conn.cursor()
    #
    curs.callproc('DBMS_OUTPUT.ENABLE')
    curs.execute(query)
    #
    status  = curs.var(cx_Oracle.NUMBER)
    line    = curs.var(cx_Oracle.STRING)
    #
    while True:
      curs.callproc('DBMS_OUTPUT.GET_LINE', (line, status))  # it freezes when selecting from a view with ORDER BY
      if status.getvalue() != 0:
        break
      out.append(line.getvalue())
    #
    return out



  def commit(self):
    try: self.conn.commit()
    except:
      return



  def rollback(self):
    try: self.conn.rollback()
    except:
      return

