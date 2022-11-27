
import numpy as np
import scipy.stats as st

def is_float(n):
    try:
        float(n)
        return True
    except:
        return False
def is_int(n):
    try:
        int(n)
        return True
    except:
        return False

file_content = open("out.txt").read()
strs = [str(n) for n in file_content.split('\n') ]

f = open("averages.txt", "a")

for g in strs:
  gfg_data=[float(n) for n in g.split(' ') if is_float(n) or is_int(n)]
  gfg_data=gfg_data[1:]
  avg=0.0
  if len(gfg_data)==0:
    break
  for i in gfg_data:
    avg=avg+i
  avg=avg/len(gfg_data)
  f.write(str(avg))
  f.write("\n")
  print(st.t.interval(alpha=0.95,      df=len(gfg_data)-1,              loc=np.mean(gfg_data),scale=st.sem(gfg_data)))

