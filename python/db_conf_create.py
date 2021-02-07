# coding: utf-8
import sys, os, pickle, argparse



# get passed arguments
parser = argparse.ArgumentParser(add_help = False)
parser.add_argument('-user',      help = 'User name')
parser.add_argument('-pwd',       help = 'Password')
parser.add_argument('-host',      help = 'Host')
parser.add_argument('--sid',      help = 'SID')         # provide SID or service
parser.add_argument('--service',  help = 'Service')
#
args = vars(parser.parse_args())
args = {key: args[key] for key in args if args[key] != None}  # remove empty values



# store settings related to database into unreadable pickle
file = os.path.dirname(os.path.realpath(__file__)) + '/db.conf'
with open(file, 'wb') as f:
  pickle.dump(args, f, protocol = pickle.HIGHEST_PROTOCOL)



# check file
with open(file, 'rb') as f:
  args = pickle.load(f)
  #
  print('--')
  args['file'] = file
  for key, value in args.items():
    print('{:>8} = {}'.format(key, value))
  print()
  print()

