def is_float(n):
    try:
        float(n)
        return True
    except:
        return False
        
avg_content = open("averages.txt").read()
avgs = [float(n) for n in avg_content.split('\n') if is_float(n)]

import matplotlib.pyplot as plt


for i in range(0,4):
  p=0
  x=[]
  y=[]
  for j in range(0,50):
    x.append(p)
    p=p+0.1
    y.append(avgs[4*j+i])
   

  plt.plot(x, y)
  plt.xlabel('loss probability')
  plt.ylabel('tranfer time ')
  name = 'class' + str(i+1)
  plt.title(name)
  plt.show()